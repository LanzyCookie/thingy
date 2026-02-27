-- Crumbs Admin - Complete Server-Side Version
-- Place this in ServerScriptService

local Players = game:GetService("Players")
local ServerScriptService = game:GetService("ServerScriptService")
local TeleportService = game:GetService("TeleportService")
local TextChatService = game:GetService("TextChatService")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")

-- Whitelist Configuration
local AUTO_RANKED_USERS = {
    [1027223614] = "Manager" -- This user gets auto-ranked to Manager
}

-- Rank Definitions
local RANKS = {
    ["Customer"] = {
        level = 0,
        commands = {"rejoin", "rj", "cmds", "commands", "help", "menu"}
    },
    ["Cashier"] = {
        level = 1,
        commands = {"rejoin", "rj", "cmds", "commands", "help", "menu", "kill", "punish", "tp", "bring", 
                   "void", "freeze", "unfreeze", "invisible", "visible", "paint", "removehats", 
                   "removearms", "removelegs", "removelimbs", "noclip", "clip", "ws"}
    },
    ["Baker"] = {
        level = 2,
        commands = {"rejoin", "rj", "cmds", "commands", "help", "menu", "kill", "punish", "tp", "bring", 
                   "void", "freeze", "unfreeze", "invisible", "visible", "paint", "removehats", 
                   "removearms", "removelegs", "removelimbs", "noclip", "clip", "ws", "kick", "ban", 
                   "unban", "clear", "clr", "reset", "looppunish", "unlooppunish", "loopkill", "unloopkill"}
    },
    ["Manager"] = {
        level = 3,
        commands = {"rejoin", "rj", "cmds", "commands", "help", "menu", "kill", "punish", "tp", "bring", 
                   "void", "freeze", "unfreeze", "invisible", "visible", "paint", "removehats", 
                   "removearms", "removelegs", "removelimbs", "noclip", "clip", "ws", "kick", "ban", 
                   "unban", "clear", "clr", "reset", "looppunish", "unlooppunish", "loopkill", "unloopkill",
                   "shutdown", "sd", "eject", "rank", "unrank"}
    }
}

-- Colors
local COLORS = {
    CHOCOLATE = Color3.fromRGB(74, 49, 28),
    MILK_CHOCOLATE = Color3.fromRGB(111, 78, 55),
    LIGHT_CHOCOLATE = Color3.fromRGB(139, 90, 43),
    COOKIE_DOUGH = Color3.fromRGB(210, 180, 140),
    WHITE = Color3.fromRGB(255, 255, 255),
    OFF_WHITE = Color3.fromRGB(240, 240, 240)
}

-- Data Stores
local PlayerRanks = {}
local PlayerData = {}
local PunishStatus = {}
local LoopKillStatus = {}
local BanStatus = {}
local commandAliases = {}
local commands = {}

-- DataStore
local DataStoreService = game:GetService("DataStoreService")
local rankStore = DataStoreService:GetDataStore("CrumbsAdminRanks")

-- Initialize Player Rank
local function loadPlayerRank(player)
    local success, data = pcall(function()
        return rankStore:GetAsync("rank_" .. player.UserId)
    end)
    
    if success and data then
        PlayerRanks[player] = data
    else
        -- Check whitelist for auto-rank
        if AUTO_RANKED_USERS[player.UserId] then
            PlayerRanks[player] = AUTO_RANKED_USERS[player.UserId]
            pcall(function()
                rankStore:SetAsync("rank_" .. player.UserId, AUTO_RANKED_USERS[player.UserId])
            end)
        else
            PlayerRanks[player] = "Customer"
        end
    end
    
    PlayerData[player] = {
        isBanned = false,
        banConnections = {},
        guiInstances = {},
        cmdBarVisible = false,
        currentDashboard = nil,
        notificationStack = {}
    }
end

-- Save Player Rank
local function savePlayerRank(player)
    if PlayerRanks[player] then
        pcall(function()
            rankStore:SetAsync("rank_" .. player.UserId, PlayerRanks[player])
        end)
    end
end

-- Check Command Permission
local function hasPermission(player, commandName)
    local rank = PlayerRanks[player] or "Customer"
    local rankInfo = RANKS[rank]
    
    if not rankInfo then return false end
    
    for _, cmd in ipairs(rankInfo.commands) do
        if cmd == commandName then
            return true
        end
    end
    
    return false
end

-- Get Rank Level
local function getRankLevel(player)
    local rank = PlayerRanks[player] or "Customer"
    return RANKS[rank].level
end

-- Find Player
local function findPlayer(input, executor)
    if not input or input == "" then return nil end
    
    if input:lower() == "me" or input:lower() == "myself" then
        return executor
    end
    
    if input:lower() == "random" then
        local players = Players:GetPlayers()
        if #players == 0 then return nil end
        return players[math.random(1, #players)]
    end
    
    if input:lower() == "all" then
        return "all"
    end
    
    if input:lower() == "others" then
        return "others"
    end
    
    local inputLower = string.lower(input)
    
    for _, player in ipairs(Players:GetPlayers()) do
        if string.lower(player.Name) == inputLower or string.lower(player.DisplayName) == inputLower then
            return player
        end
    end
    
    for _, player in ipairs(Players:GetPlayers()) do
        if string.find(string.lower(player.Name), inputLower, 1, true) or 
           string.find(string.lower(player.DisplayName), inputLower, 1, true) then
            return player
        end
    end
    
    return nil
end

-- GUI Creation Functions
local function createNotificationGui(player, title, message, duration)
    local playerGui = player:FindFirstChild("PlayerGui")
    if not playerGui then return end
    
    -- Calculate stack position
    local yOffset = 10
    for _, entry in ipairs(PlayerData[player].notificationStack) do
        yOffset = yOffset + 80 + 6
    end
    
    -- Create ScreenGui
    local screenGui = Instance.new("ScreenGui")
    screenGui.Name = "CrumbsNotif_" .. tick()
    screenGui.ResetOnSpawn = false
    screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    screenGui.Parent = playerGui
    
    -- Main frame
    local frame = Instance.new("Frame")
    frame.Name = "NotificationFrame"
    frame.Size = UDim2.new(0, 280, 0, 80)
    frame.Position = UDim2.new(1, -290, 1, -(yOffset + 80))
    frame.BackgroundColor3 = COLORS.CHOCOLATE
    frame.BackgroundTransparency = 0.05
    frame.BorderSizePixel = 0
    frame.Parent = screenGui
    
    -- Add stroke for visibility
    local stroke = Instance.new("UIStroke")
    stroke.Color = COLORS.LIGHT_CHOCOLATE
    stroke.Thickness = 2
    stroke.Parent = frame
    
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 15)
    corner.Parent = frame
    
    -- Title
    local titleLabel = Instance.new("TextLabel")
    titleLabel.Text = title
    titleLabel.Size = UDim2.new(1, -45, 0, 18)
    titleLabel.Position = UDim2.new(0, 10, 0, 6)
    titleLabel.TextColor3 = COLORS.COOKIE_DOUGH
    titleLabel.BackgroundTransparency = 1
    titleLabel.Font = Enum.Font.GothamBold
    titleLabel.TextSize = 13
    titleLabel.TextXAlignment = Enum.TextXAlignment.Left
    titleLabel.TextYAlignment = Enum.TextYAlignment.Top
    titleLabel.Parent = frame
    
    -- Line
    local line = Instance.new("Frame")
    line.Size = UDim2.new(1, -18, 0, 1)
    line.Position = UDim2.new(0, 9, 0, 27)
    line.BackgroundColor3 = COLORS.MILK_CHOCOLATE
    line.BackgroundTransparency = 0.2
    line.BorderSizePixel = 0
    line.Parent = frame
    
    -- Message
    local messageLabel = Instance.new("TextLabel")
    messageLabel.Text = message
    messageLabel.Size = UDim2.new(1, -20, 1, -38)
    messageLabel.Position = UDim2.new(0, 10, 0, 32)
    messageLabel.TextColor3 = COLORS.OFF_WHITE
    messageLabel.BackgroundTransparency = 1
    messageLabel.Font = Enum.Font.Gotham
    messageLabel.TextSize = 12
    messageLabel.TextXAlignment = Enum.TextXAlignment.Left
    messageLabel.TextYAlignment = Enum.TextYAlignment.Top
    messageLabel.TextWrapped = true
    messageLabel.Parent = frame
    
    -- Close button
    local closeBtn = Instance.new("TextButton")
    closeBtn.Size = UDim2.new(0, 24, 0, 24)
    closeBtn.Position = UDim2.new(1, -30, 0, 5)
    closeBtn.Text = "X"
    closeBtn.TextColor3 = COLORS.COOKIE_DOUGH
    closeBtn.BackgroundTransparency = 1
    closeBtn.Font = Enum.Font.GothamBold
    closeBtn.TextSize = 15
    closeBtn.Parent = frame
    
    -- Add to stack
    local stackEntry = {
        gui = screenGui,
        frame = frame,
        height = 80,
        yOffset = yOffset
    }
    table.insert(PlayerData[player].notificationStack, stackEntry)
    
    -- Restack function
    local function restack()
        local runningOffset = 10
        for _, entry in ipairs(PlayerData[player].notificationStack) do
            if entry.gui and entry.gui.Parent then
                local targetY = -(runningOffset + entry.height)
                TweenService:Create(entry.frame, TweenInfo.new(0.25, Enum.EasingStyle.Quint), {
                    Position = UDim2.new(1, -290, 1, targetY)
                }):Play()
                runningOffset = runningOffset + entry.height + 6
            end
        end
    end
    
    -- Close function
    local function close()
        -- Remove from stack
        for i, entry in ipairs(PlayerData[player].notificationStack) do
            if entry.gui == screenGui then
                table.remove(PlayerData[player].notificationStack, i)
                break
            end
        end
        
        -- Fade out animations
        TweenService:Create(frame, TweenInfo.new(0.4), {BackgroundTransparency = 1}):Play()
        TweenService:Create(titleLabel, TweenInfo.new(0.4), {TextTransparency = 1}):Play()
        TweenService:Create(messageLabel, TweenInfo.new(0.4), {TextTransparency = 1}):Play()
        TweenService:Create(line, TweenInfo.new(0.4), {BackgroundTransparency = 1}):Play()
        TweenService:Create(closeBtn, TweenInfo.new(0.4), {TextTransparency = 1}):Play()
        
        restack()
        
        task.wait(0.4)
        if screenGui and screenGui.Parent then
            screenGui:Destroy()
        end
    end
    
    closeBtn.MouseButton1Click:Connect(close)
    
    -- Hover effect
    closeBtn.MouseEnter:Connect(function()
        TweenService:Create(closeBtn, TweenInfo.new(0.2), {
            TextColor3 = COLORS.LIGHT_CHOCOLATE,
            TextSize = 17
        }):Play()
    end)
    
    closeBtn.MouseLeave:Connect(function()
        TweenService:Create(closeBtn, TweenInfo.new(0.2), {
            TextColor3 = COLORS.COOKIE_DOUGH,
            TextSize = 15
        }):Play()
    end)
    
    -- Auto close after duration
    task.wait(duration or 4)
    close()
end

local function createDashboardGui(player, defaultTab)
    local playerGui = player:FindFirstChild("PlayerGui")
    if not playerGui then return end
    
    -- If dashboard exists, close it with animation
    if PlayerData[player].currentDashboard then
        local oldDashboard = PlayerData[player].currentDashboard
        local mainFrame = oldDashboard:FindFirstChild("MainFrame")
        
        if mainFrame then
            -- Fade out animations
            TweenService:Create(mainFrame, TweenInfo.new(0.3), {BackgroundTransparency = 1}):Play()
            
            for _, v in ipairs(mainFrame:GetDescendants()) do
                if v:IsA("TextLabel") or v:IsA("TextButton") then
                    TweenService:Create(v, TweenInfo.new(0.3), {TextTransparency = 1}):Play()
                elseif v:IsA("Frame") or v:IsA("ScrollingFrame") then
                    TweenService:Create(v, TweenInfo.new(0.3), {BackgroundTransparency = 1}):Play()
                end
            end
            
            task.wait(0.15)
        end
        
        oldDashboard:Destroy()
        PlayerData[player].currentDashboard = nil
    end
    
    -- Create ScreenGui
    local screenGui = Instance.new("ScreenGui")
    screenGui.Name = "CrumbsDashboard"
    screenGui.ResetOnSpawn = false
    screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    screenGui.Parent = playerGui
    PlayerData[player].currentDashboard = screenGui
    table.insert(PlayerData[player].guiInstances, screenGui)
    
    -- Main frame
    local mainFrame = Instance.new("Frame")
    mainFrame.Name = "MainFrame"
    mainFrame.Size = UDim2.new(0, 750, 0, 420)
    mainFrame.Position = UDim2.new(0.5, -375, 0.5, -210)
    mainFrame.BackgroundColor3 = COLORS.CHOCOLATE
    mainFrame.BackgroundTransparency = 1
    mainFrame.BorderSizePixel = 2
    mainFrame.BorderColor3 = COLORS.LIGHT_CHOCOLATE
    mainFrame.Parent = screenGui
    
    local mainCorner = Instance.new("UICorner")
    mainCorner.CornerRadius = UDim.new(0, 12)
    mainCorner.Parent = mainFrame
    
    -- Top bar
    local topBar = Instance.new("Frame")
    topBar.Name = "TopBar"
    topBar.Size = UDim2.new(1, 0, 0, 38)
    topBar.BackgroundColor3 = COLORS.MILK_CHOCOLATE
    topBar.BackgroundTransparency = 1
    topBar.BorderSizePixel = 0
    topBar.Parent = mainFrame
    
    local topBarCorner = Instance.new("UICorner")
    topBarCorner.CornerRadius = UDim.new(0, 12)
    topBarCorner.Parent = topBar
    
    local title = Instance.new("TextLabel")
    title.Name = "Title"
    title.Size = UDim2.new(0, 200, 0, 38)
    title.Position = UDim2.new(0.36, 0, 0, 0)
    title.BackgroundTransparency = 1
    title.Text = "Crumbs Admin"
    title.TextColor3 = COLORS.OFF_WHITE
    title.TextTransparency = 1
    title.TextSize = 22
    title.Font = Enum.Font.GothamBold
    title.Parent = topBar
    
    local closeBtn = Instance.new("TextButton")
    closeBtn.Name = "CloseButton"
    closeBtn.Size = UDim2.new(0, 32, 0, 32)
    closeBtn.Position = UDim2.new(1, -37, 0, 3)
    closeBtn.BackgroundTransparency = 1
    closeBtn.Text = "X"
    closeBtn.TextColor3 = COLORS.OFF_WHITE
    closeBtn.TextTransparency = 1
    closeBtn.TextSize = 18
    closeBtn.Font = Enum.Font.GothamBold
    closeBtn.Parent = topBar
    
    -- Tab bar
    local tabBar = Instance.new("Frame")
    tabBar.Name = "TabBar"
    tabBar.Size = UDim2.new(1, -16, 0, 42)
    tabBar.Position = UDim2.new(0, 8, 0, 46)
    tabBar.BackgroundColor3 = COLORS.MILK_CHOCOLATE
    tabBar.BackgroundTransparency = 1
    tabBar.BorderSizePixel = 1
    tabBar.BorderColor3 = COLORS.LIGHT_CHOCOLATE
    tabBar.Parent = mainFrame
    
    local tabBarCorner = Instance.new("UICorner")
    tabBarCorner.CornerRadius = UDim.new(0, 8)
    tabBarCorner.Parent = tabBar
    
    local commandsTab = Instance.new("TextButton")
    commandsTab.Name = "CommandsTab"
    commandsTab.Size = UDim2.new(0.5, -5, 0, 36)
    commandsTab.Position = UDim2.new(0, 4, 0, 3)
    commandsTab.BackgroundColor3 = COLORS.COOKIE_DOUGH
    commandsTab.BackgroundTransparency = 1
    commandsTab.BorderSizePixel = 1
    commandsTab.BorderColor3 = COLORS.LIGHT_CHOCOLATE
    commandsTab.Text = "Commands"
    commandsTab.TextColor3 = COLORS.CHOCOLATE
    commandsTab.TextTransparency = 1
    commandsTab.TextSize = 16
    commandsTab.Font = Enum.Font.GothamBold
    commandsTab.Parent = tabBar
    
    local creditsTab = Instance.new("TextButton")
    creditsTab.Name = "CreditsTab"
    creditsTab.Size = UDim2.new(0.5, -5, 0, 36)
    creditsTab.Position = UDim2.new(0.5, 1, 0, 3)
    creditsTab.BackgroundColor3 = COLORS.MILK_CHOCOLATE
    creditsTab.BackgroundTransparency = 1
    creditsTab.BorderSizePixel = 1
    creditsTab.BorderColor3 = COLORS.LIGHT_CHOCOLATE
    creditsTab.Text = "Info"
    creditsTab.TextColor3 = COLORS.OFF_WHITE
    creditsTab.TextTransparency = 1
    creditsTab.TextSize = 16
    creditsTab.Font = Enum.Font.GothamBold
    creditsTab.Parent = tabBar
    
    -- Content frame
    local contentFrame = Instance.new("Frame")
    contentFrame.Name = "ContentFrame"
    contentFrame.Size = UDim2.new(1, -16, 1, -104)
    contentFrame.Position = UDim2.new(0, 8, 0, 96)
    contentFrame.BackgroundColor3 = COLORS.MILK_CHOCOLATE
    contentFrame.BackgroundTransparency = 1
    contentFrame.BorderSizePixel = 1
    contentFrame.BorderColor3 = COLORS.LIGHT_CHOCOLATE
    contentFrame.Parent = mainFrame
    
    local contentCorner = Instance.new("UICorner")
    contentCorner.CornerRadius = UDim.new(0, 8)
    contentCorner.Parent = contentFrame
    
    -- Commands content
    local commandsContent = Instance.new("ScrollingFrame")
    commandsContent.Name = "CommandsContent"
    commandsContent.Size = UDim2.new(1, 0, 1, 0)
    commandsContent.BackgroundColor3 = COLORS.MILK_CHOCOLATE
    commandsContent.BackgroundTransparency = 1
    commandsContent.BorderSizePixel = 0
    commandsContent.ScrollBarThickness = 6
    commandsContent.ScrollBarImageColor3 = COLORS.COOKIE_DOUGH
    commandsContent.Visible = (defaultTab == "Commands")
    commandsContent.Parent = contentFrame
    commandsContent.CanvasSize = UDim2.new(0, 0, 0, 0)
    
    local commandsLayout = Instance.new("UIListLayout")
    commandsLayout.Parent = commandsContent
    commandsLayout.SortOrder = Enum.SortOrder.LayoutOrder
    commandsLayout.Padding = UDim.new(0, 5)
    
    commandsLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
        commandsContent.CanvasSize = UDim2.new(0, 0, 0, commandsLayout.AbsoluteContentSize.Y + 10)
    end)
    
    -- Rank info
    local rankInfo = Instance.new("TextLabel")
    rankInfo.Name = "RankInfo"
    rankInfo.Size = UDim2.new(1, -20, 0, 40)
    rankInfo.Position = UDim2.new(0, 10, 0, 10)
    rankInfo.BackgroundTransparency = 1
    rankInfo.Text = "Your Rank: " .. (PlayerRanks[player] or "Customer")
    rankInfo.TextColor3 = COLORS.COOKIE_DOUGH
    rankInfo.TextTransparency = 1
    rankInfo.TextSize = 24
    rankInfo.Font = Enum.Font.GothamBold
    rankInfo.Parent = commandsContent
    
    -- Credits content
    local creditsContent = Instance.new("ScrollingFrame")
    creditsContent.Name = "CreditsContent"
    creditsContent.Size = UDim2.new(1, 0, 1, 0)
    creditsContent.BackgroundColor3 = COLORS.MILK_CHOCOLATE
    creditsContent.BackgroundTransparency = 1
    creditsContent.BorderSizePixel = 0
    creditsContent.ScrollBarThickness = 6
    creditsContent.ScrollBarImageColor3 = COLORS.COOKIE_DOUGH
    creditsContent.Visible = (defaultTab ~= "Commands")
    creditsContent.Parent = contentFrame
    creditsContent.CanvasSize = UDim2.new(0, 0, 0, 200)
    
    local creditsLayout = Instance.new("UIListLayout")
    creditsLayout.Parent = creditsContent
    creditsLayout.SortOrder = Enum.SortOrder.LayoutOrder
    creditsLayout.Padding = UDim.new(0, 10)
    creditsLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
    
    local creditTitle = Instance.new("TextLabel")
    creditTitle.Size = UDim2.new(1, -20, 0, 40)
    creditTitle.Position = UDim2.new(0, 10, 0, 10)
    creditTitle.BackgroundTransparency = 1
    creditTitle.Text = "Crumbs Admin"
    creditTitle.TextColor3 = COLORS.COOKIE_DOUGH
    creditTitle.TextTransparency = 1
    creditTitle.TextSize = 28
    creditTitle.Font = Enum.Font.GothamBold
    creditTitle.Parent = creditsContent
    
    local versionLabel = Instance.new("TextLabel")
    versionLabel.Size = UDim2.new(1, -20, 0, 30)
    versionLabel.BackgroundTransparency = 1
    versionLabel.Text = "Version 2.0 - Server-Side"
    versionLabel.TextColor3 = COLORS.OFF_WHITE
    versionLabel.TextTransparency = 1
    versionLabel.TextSize = 16
    versionLabel.Font = Enum.Font.Gotham
    versionLabel.Parent = creditsContent
    
    -- Tab switching
    local function switchTab(tab)
        if tab == "Commands" then
            TweenService:Create(commandsTab, TweenInfo.new(0.3), {
                BackgroundColor3 = COLORS.COOKIE_DOUGH,
                BackgroundTransparency = 0.1,
                TextColor3 = COLORS.CHOCOLATE
            }):Play()
            
            TweenService:Create(creditsTab, TweenInfo.new(0.3), {
                BackgroundColor3 = COLORS.MILK_CHOCOLATE,
                BackgroundTransparency = 0.3,
                TextColor3 = COLORS.OFF_WHITE
            }):Play()
            
            commandsContent.Visible = true
            creditsContent.Visible = false
        else
            TweenService:Create(creditsTab, TweenInfo.new(0.3), {
                BackgroundColor3 = COLORS.COOKIE_DOUGH,
                BackgroundTransparency = 0.1,
                TextColor3 = COLORS.CHOCOLATE
            }):Play()
            
            TweenService:Create(commandsTab, TweenInfo.new(0.3), {
                BackgroundColor3 = COLORS.MILK_CHOCOLATE,
                BackgroundTransparency = 0.3,
                TextColor3 = COLORS.OFF_WHITE
            }):Play()
            
            commandsContent.Visible = false
            creditsContent.Visible = true
        end
    end
    
    commandsTab.MouseButton1Click:Connect(function() switchTab("Commands") end)
    creditsTab.MouseButton1Click:Connect(function() switchTab("Credits") end)
    
    -- Close button with animation
    closeBtn.MouseButton1Click:Connect(function()
        -- Fade out animations
        TweenService:Create(mainFrame, TweenInfo.new(0.3), {BackgroundTransparency = 1}):Play()
        TweenService:Create(topBar, TweenInfo.new(0.3), {BackgroundTransparency = 1}):Play()
        TweenService:Create(title, TweenInfo.new(0.3), {TextTransparency = 1}):Play()
        TweenService:Create(closeBtn, TweenInfo.new(0.3), {TextTransparency = 1}):Play()
        TweenService:Create(tabBar, TweenInfo.new(0.3), {BackgroundTransparency = 1}):Play()
        TweenService:Create(commandsTab, TweenInfo.new(0.3), {BackgroundTransparency = 1, TextTransparency = 1}):Play()
        TweenService:Create(creditsTab, TweenInfo.new(0.3), {BackgroundTransparency = 1, TextTransparency = 1}):Play()
        TweenService:Create(contentFrame, TweenInfo.new(0.3), {BackgroundTransparency = 1}):Play()
        
        for _, v in ipairs(contentFrame:GetDescendants()) do
            if v:IsA("TextLabel") or v:IsA("TextButton") then
                TweenService:Create(v, TweenInfo.new(0.3), {TextTransparency = 1}):Play()
            elseif v:IsA("Frame") or v:IsA("ScrollingFrame") then
                TweenService:Create(v, TweenInfo.new(0.3), {BackgroundTransparency = 1}):Play()
            end
        end
        
        task.wait(0.15)
        screenGui:Destroy()
        PlayerData[player].currentDashboard = nil
    end)
    
    -- Dragging
    local dragging = false
    local dragStart, startPos
    local dragTween = nil
    
    local function updateDrag(input)
        if dragging and dragStart and startPos then
            local delta = input.Position - dragStart
            local newPos = UDim2.new(
                startPos.X.Scale, 
                startPos.X.Offset + delta.X,
                startPos.Y.Scale,
                startPos.Y.Offset + delta.Y
            )
            
            if dragTween then
                dragTween:Cancel()
            end
            
            dragTween = TweenService:Create(mainFrame, TweenInfo.new(0.08, Enum.EasingStyle.Quad), {
                Position = newPos
            })
            dragTween:Play()
        end
    end
    
    topBar.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging = true
            dragStart = input.Position
            startPos = mainFrame.Position
        end
    end)
    
    local uis = game:GetService("UserInputService")
    
    local conn1 = uis.InputChanged:Connect(function(input)
        if dragging and input.UserInputType == Enum.UserInputType.MouseMovement then
            updateDrag(input)
        end
    end)
    
    local conn2 = uis.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging = false
            if dragTween then
                dragTween:Cancel()
                dragTween = nil
            end
        end
    end)
    
    screenGui.Destroying:Connect(function()
        conn1:Disconnect()
        conn2:Disconnect()
    end)
    
    -- Fade in animations
    task.wait(0.1)
    
    TweenService:Create(mainFrame, TweenInfo.new(0.5), {BackgroundTransparency = 0.05}):Play()
    TweenService:Create(topBar, TweenInfo.new(0.5), {BackgroundTransparency = 0.1}):Play()
    TweenService:Create(title, TweenInfo.new(0.5), {TextTransparency = 0}):Play()
    TweenService:Create(closeBtn, TweenInfo.new(0.5), {TextTransparency = 0}):Play()
    TweenService:Create(tabBar, TweenInfo.new(0.5), {BackgroundTransparency = 0.2}):Play()
    TweenService:Create(contentFrame, TweenInfo.new(0.5), {BackgroundTransparency = 0.3}):Play()
    
    if defaultTab == "Commands" then
        TweenService:Create(commandsTab, TweenInfo.new(0.5), {BackgroundTransparency = 0.1, TextTransparency = 0}):Play()
        TweenService:Create(creditsTab, TweenInfo.new(0.5), {BackgroundTransparency = 0.3, TextTransparency = 0}):Play()
    else
        TweenService:Create(commandsTab, TweenInfo.new(0.5), {BackgroundTransparency = 0.3, TextTransparency = 0}):Play()
        TweenService:Create(creditsTab, TweenInfo.new(0.5), {BackgroundTransparency = 0.1, TextTransparency = 0}):Play()
    end
    
    task.wait(0.1)
    
    TweenService:Create(rankInfo, TweenInfo.new(0.4), {TextTransparency = 0}):Play()
    TweenService:Create(creditTitle, TweenInfo.new(0.4), {TextTransparency = 0}):Play()
    TweenService:Create(versionLabel, TweenInfo.new(0.4), {TextTransparency = 0}):Play()
end

local function createCmdBarGui(player)
    local playerGui = player:FindFirstChild("PlayerGui")
    if not playerGui then return end
    
    local screenGui = Instance.new("ScreenGui")
    screenGui.Name = "CrumbsCmdBar"
    screenGui.ResetOnSpawn = false
    screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    screenGui.Parent = playerGui
    table.insert(PlayerData[player].guiInstances, screenGui)
    
    -- Command Bar Frame
    local cmdBarFrame = Instance.new("Frame")
    cmdBarFrame.Name = "CmdBarFrame"
    cmdBarFrame.Size = UDim2.new(0.5, 0, 0.08, 0)
    cmdBarFrame.Position = UDim2.new(0.25, 0, 1.2, 0)
    cmdBarFrame.BackgroundTransparency = 1
    cmdBarFrame.Visible = false
    cmdBarFrame.Parent = screenGui
    
    local cmdBarTextBox = Instance.new("TextBox")
    cmdBarTextBox.Name = "CmdBarTextBox"
    cmdBarTextBox.Size = UDim2.new(1, -4, 1, -4)
    cmdBarTextBox.Position = UDim2.new(0, 2, 0, 2)
    cmdBarTextBox.BackgroundColor3 = COLORS.MILK_CHOCOLATE
    cmdBarTextBox.TextColor3 = COLORS.WHITE
    cmdBarTextBox.TextSize = 18
    cmdBarTextBox.Font = Enum.Font.SourceSans
    cmdBarTextBox.PlaceholderText = "Enter command... ( , )"
    cmdBarTextBox.PlaceholderColor3 = COLORS.COOKIE_DOUGH
    cmdBarTextBox.ClearTextOnFocus = false
    cmdBarTextBox.Text = ""
    cmdBarTextBox.Parent = cmdBarFrame
    
    local textBoxCorner = Instance.new("UICorner")
    textBoxCorner.CornerRadius = UDim.new(0, 10)
    textBoxCorner.Parent = cmdBarTextBox
    
    local textBoxStroke = Instance.new("UIStroke")
    textBoxStroke.Color = COLORS.LIGHT_CHOCOLATE
    textBoxStroke.Thickness = 2
    textBoxStroke.Parent = cmdBarTextBox
    
    -- Rank indicator
    local rankIndicator = Instance.new("TextLabel")
    rankIndicator.Name = "RankIndicator"
    rankIndicator.Size = UDim2.new(0, 150, 0, 30)
    rankIndicator.Position = UDim2.new(1, -160, 0, 10)
    rankIndicator.BackgroundColor3 = COLORS.CHOCOLATE
    rankIndicator.BackgroundTransparency = 0
    rankIndicator.TextColor3 = COLORS.COOKIE_DOUGH
    rankIndicator.Text = "Rank: " .. (PlayerRanks[player] or "Customer")
    rankIndicator.TextSize = 14
    rankIndicator.Font = Enum.Font.GothamBold
    rankIndicator.Parent = screenGui
    
    local rankCorner = Instance.new("UICorner")
    rankCorner.CornerRadius = UDim.new(0, 8)
    rankCorner.Parent = rankIndicator
    
    local rankStroke = Instance.new("UIStroke")
    rankStroke.Color = COLORS.LIGHT_CHOCOLATE
    rankStroke.Thickness = 2
    rankStroke.Parent = rankIndicator
    
    -- Store references
    PlayerData[player].cmdBar = {
        frame = cmdBarFrame,
        textBox = cmdBarTextBox,
        rankIndicator = rankIndicator,
        visible = false
    }
    
    -- Command handling
    cmdBarTextBox.FocusLost:Connect(function(enterPressed, inputObject)
        if enterPressed then
            local commandText = cmdBarTextBox.Text
            cmdBarTextBox.Text = ""
            toggleCmdBar(player, false)
            
            if commandText ~= "" and commandText ~= "" then
                handleCommand(player, commandText)
            end
        else
            toggleCmdBar(player, false)
        end
    end)
end

local function toggleCmdBar(player, show)
    if not PlayerData[player] or not PlayerData[player].cmdBar then return end
    
    local cmdBar = PlayerData[player].cmdBar
    local frame = cmdBar.frame
    local textBox = cmdBar.textBox
    
    if show == nil then
        show = not cmdBar.visible
    end
    
    if show then
        cmdBar.visible = true
        frame.Visible = true
        frame.Position = UDim2.new(0.25, 0, 1.2, 0)
        
        TweenService:Create(frame, TweenInfo.new(0.5, Enum.EasingStyle.Quad), {
            Position = UDim2.new(0.25, 0, 0.85, 0)
        }):Play()
        
        task.wait(0.1)
        textBox:CaptureFocus()
    else
        cmdBar.visible = false
        
        TweenService:Create(frame, TweenInfo.new(0.3, Enum.EasingStyle.Quad), {
            Position = UDim2.new(0.25, 0, 1.2, 0)
        }):Play()
        
        task.wait(0.3)
        frame.Visible = false
    end
end

-- Notification wrapper
local function notify(player, title, message, duration)
    createNotificationGui(player, title, message, duration or 4)
end

local function notifyAll(title, message, duration)
    for _, player in ipairs(Players:GetPlayers()) do
        notify(player, title, message, duration)
    end
end

-- Dashboard wrapper
local function openDashboard(player, defaultTab)
    createDashboardGui(player, defaultTab or "Commands")
end

-- Command Registration
local function AddCommand(name, desc, args, minRank, onCalled, aliases)
    local cmdInfo = {
        name = name,
        description = desc,
        arguments = args,
        minRank = minRank,
        callback = onCalled,
        aliases = aliases or {}
    }
    
    commands[name] = cmdInfo
    
    if aliases then
        for _, alias in ipairs(aliases) do
            commandAliases[alias] = name
        end
    end
end

-- Command Handler
local function handleCommand(player, commandText)
    if string.sub(commandText, 1, 1) == "," then
        commandText = string.sub(commandText, 2)
    end
    
    if commandText:lower() == "cmds" or commandText:lower() == "commands" or 
       commandText:lower() == "help" or commandText:lower() == "menu" then
        openDashboard(player, "Commands")
        return
    end
    
    -- Parse command and arguments
    local parts = {}
    for word in string.gmatch(commandText, "%S+") do
        table.insert(parts, word)
    end
    
    if #parts == 0 then return end
    
    local cmdName = string.lower(parts[1])
    table.remove(parts, 1)
    
    -- Check aliases
    if commandAliases[cmdName] then
        cmdName = commandAliases[cmdName]
    end
    
    local cmd = commands[cmdName]
    if not cmd then
        notify(player, "Crumbs Admin", "Unknown command: " .. cmdName, 3)
        return
    end
    
    -- Check permission
    if not hasPermission(player, cmdName) then
        notify(player, "Crumbs Admin", "You don't have permission to use this command.", 3)
        return
    end
    
    -- Execute command
    local success, err = pcall(function()
        cmd.callback(player, unpack(parts))
    end)
    
    if not success then
        warn("Command error from", player.Name, ":", err)
        notify(player, "Crumbs Admin", "Command execution failed.", 3)
    end
end

-- Initialize Chat Handler
local function setupChatHandler()
    if TextChatService.ChatVersion == Enum.ChatVersion.TextChatService then
        -- Create commands folder if it doesn't exist
        local textChatCommands = TextChatService:FindFirstChild("TextChatCommands")
        if not textChatCommands then
            textChatCommands = Instance.new("Folder")
            textChatCommands.Name = "TextChatCommands"
            textChatCommands.Parent = TextChatService
        end
        
        -- Create command trigger
        local cmdTrigger = Instance.new("TextChatCommand")
        cmdTrigger.Name = "CrumbsAdminCmd"
        cmdTrigger.TriggerTexts = {","}
        cmdTrigger.Parent = textChatCommands
        
        cmdTrigger.Callbacked:Connect(function(sender, messageText)
            if sender and string.sub(messageText, 1, 1) == "," then
                handleCommand(sender, messageText)
            end
        end)
    end
    
    -- Legacy chat handler
    Players.PlayerAdded:Connect(function(player)
        player.Chatted:Connect(function(message)
            if string.sub(message, 1, 1) == "," then
                handleCommand(player, message)
            end
        end)
    end)
end

-- Handle multiple targets
local function handleTargets(executor, targetString, callback)
    if not targetString then return end
    
    -- Check if it's a comma-separated list
    if string.find(targetString, ",") then
        local names = {}
        for name in string.gmatch(targetString, "([^,]+)") do
            name = name:gsub("^%s+", ""):gsub("%s+$", "")
            table.insert(names, name)
        end
        
        for _, name in ipairs(names) do
            if name:lower() == "all" then
                for _, player in ipairs(Players:GetPlayers()) do
                    if player ~= executor then
                        callback(player)
                    end
                end
            elseif name:lower() == "others" then
                for _, player in ipairs(Players:GetPlayers()) do
                    if player ~= executor then
                        callback(player)
                    end
                end
            elseif name:lower() == "me" then
                callback(executor)
            elseif name:lower() == "random" then
                local players = {}
                for _, player in ipairs(Players:GetPlayers()) do
                    if player ~= executor then
                        table.insert(players, player)
                    end
                end
                if #players > 0 then
                    callback(players[math.random(1, #players)])
                end
            else
                local player = findPlayer(name, executor)
                if player and player ~= executor then
                    callback(player)
                end
            end
        end
    else
        -- Single target
        if targetString:lower() == "all" then
            for _, player in ipairs(Players:GetPlayers()) do
                if player ~= executor then
                    callback(player)
                end
            end
        elseif targetString:lower() == "others" then
            for _, player in ipairs(Players:GetPlayers()) do
                if player ~= executor then
                    callback(player)
                end
            end
        elseif targetString:lower() == "me" then
            callback(executor)
        elseif targetString:lower() == "random" then
            local players = {}
            for _, player in ipairs(Players:GetPlayers()) do
                if player ~= executor then
                    table.insert(players, player)
                end
            end
            if #players > 0 then
                callback(players[math.random(1, #players)])
            end
        else
            local player = findPlayer(targetString, executor)
            if player then
                callback(player)
            end
        end
    end
end

-- Ban System
local function banPlayer(executor, target)
    if not target then return end
    
    BanStatus[target] = true
    
    -- Kick the player
    target:Kick("You have been banned by " .. executor.Name)
    
    -- Set up rejoin detection
    local connection = Players.PlayerAdded:Connect(function(player)
        if player == target then
            task.wait(0.5)
            if BanStatus[target] then
                player:Kick("You are banned from this server.")
            end
        end
    end)
    
    if not PlayerData[executor].banConnections then
        PlayerData[executor].banConnections = {}
    end
    table.insert(PlayerData[executor].banConnections, connection)
    
    notify(executor, "Crumbs Admin", "Banned " .. target.Name, 3)
end

local function unbanPlayer(executor, target)
    if not target then return end
    
    BanStatus[target] = nil
    
    if PlayerData[executor].banConnections then
        for _, conn in ipairs(PlayerData[executor].banConnections) do
            conn:Disconnect()
        end
        PlayerData[executor].banConnections = {}
    end
    
    notify(executor, "Crumbs Admin", "Unbanned " .. target.Name, 3)
end

-- Shutdown System
local function shutdownServer(executor)
    notifyAll("Crumbs Admin", "Server shutting down in 5 seconds...", 5)
    
    task.wait(5)
    
    for _, player in ipairs(Players:GetPlayers()) do
        if player ~= executor then
            player:Kick("Server is shutting down.")
        end
    end
    
    task.wait(1)
    game:Shutdown()
end

-- Rank System
local function rankPlayer(executor, target, rankName)
    if not target then return end
    
    -- Normalize rank name
    local normalizedRank = nil
    for rank, info in pairs(RANKS) do
        if string.lower(rank) == string.lower(rankName) then
            normalizedRank = rank
            break
        end
    end
    
    -- Also check numeric levels
    if not normalizedRank then
        local level = tonumber(rankName)
        if level then
            for rank, info in pairs(RANKS) do
                if info.level == level then
                    normalizedRank = rank
                    break
                end
            end
        end
    end
    
    if not normalizedRank then
        notify(executor, "Crumbs Admin", "Invalid rank. Use: Customer, Cashier, Baker, Manager", 3)
        return
    end
    
    -- Check if executor has higher rank than target
    if getRankLevel(executor) <= getRankLevel(target) and executor ~= target then
        notify(executor, "Crumbs Admin", "You cannot rank someone with equal or higher rank.", 3)
        return
    end
    
    PlayerRanks[target] = normalizedRank
    savePlayerRank(target)
    
    -- Update rank indicator for target
    if PlayerData[target] and PlayerData[target].cmdBar and PlayerData[target].cmdBar.rankIndicator then
        PlayerData[target].cmdBar.rankIndicator.Text = "Rank: " .. normalizedRank
    end
    
    notify(executor, "Crumbs Admin", "Ranked " .. target.Name .. " as " .. normalizedRank, 3)
    notify(target, "Crumbs Admin", "You have been ranked as " .. normalizedRank .. " by " .. executor.Name, 3)
end

local function unrankPlayer(executor, target)
    if not target then return end
    
    if getRankLevel(executor) <= getRankLevel(target) and executor ~= target then
        notify(executor, "Crumbs Admin", "You cannot unrank someone with equal or higher rank.", 3)
        return
    end
    
    PlayerRanks[target] = "Customer"
    savePlayerRank(target)
    
    -- Update rank indicator for target
    if PlayerData[target] and PlayerData[target].cmdBar and PlayerData[target].cmdBar.rankIndicator then
        PlayerData[target].cmdBar.rankIndicator.Text = "Rank: Customer"
    end
    
    notify(executor, "Crumbs Admin", "Unranked " .. target.Name, 3)
    notify(target, "Crumbs Admin", "You have been unranked by " .. executor.Name, 3)
end

-- Loop Punish System
local function startLoopPunish(executor, target)
    if PunishStatus[target] then return end
    
    PunishStatus[target] = true
    
    local function punishCharacter()
        if target.Character then
            target.Character:BreakJoints()
        end
    end
    
    punishCharacter()
    
    local connection = target.CharacterAdded:Connect(function()
        task.wait(0.1)
        if PunishStatus[target] then
            target.Character:BreakJoints()
        end
    end)
    
    PunishStatus[target .. "_conn"] = connection
    
    task.spawn(function()
        while PunishStatus[target] do
            task.wait(0.5)
            if target.Character then
                target.Character:BreakJoints()
            end
        end
    end)
    
    notify(executor, "Crumbs Admin", "Started loop punish on " .. target.Name, 3)
end

local function stopLoopPunish(executor, target)
    PunishStatus[target] = nil
    if PunishStatus[target .. "_conn"] then
        PunishStatus[target .. "_conn"]:Disconnect()
        PunishStatus[target .. "_conn"] = nil
    end
    notify(executor, "Crumbs Admin", "Stopped loop punish on " .. target.Name, 3)
end

-- Loop Kill System
local function startLoopKill(executor, target)
    if LoopKillStatus[target] then return end
    
    LoopKillStatus[target] = true
    
    local function killCharacter()
        if target.Character and target.Character:FindFirstChild("Head") then
            target.Character.Head:Destroy()
        end
    end
    
    killCharacter()
    
    local connection = target.CharacterAdded:Connect(function()
        task.wait(0.1)
        if LoopKillStatus[target] and target.Character:FindFirstChild("Head") then
            target.Character.Head:Destroy()
        end
    end)
    
    LoopKillStatus[target .. "_conn"] = connection
    
    task.spawn(function()
        while LoopKillStatus[target] do
            task.wait(0.5)
            if target.Character and target.Character:FindFirstChild("Head") then
                target.Character.Head:Destroy()
            end
        end
    end)
    
    notify(executor, "Crumbs Admin", "Started loop kill on " .. target.Name, 3)
end

local function stopLoopKill(executor, target)
    LoopKillStatus[target] = nil
    if LoopKillStatus[target .. "_conn"] then
        LoopKillStatus[target .. "_conn"]:Disconnect()
        LoopKillStatus[target .. "_conn"] = nil
    end
    notify(executor, "Crumbs Admin", "Stopped loop kill on " .. target.Name, 3)
end

-- Register Commands
-- Rank 0 Commands (Customer)
AddCommand("rejoin", "Rejoin the server", {}, 0, function(player)
    TeleportService:Teleport(game.PlaceId, player)
end, {"rj"})

-- Rank 1 Commands (Cashier)
AddCommand("kill", "Kill a player", {"<player>"}, 1, function(player, target)
    handleTargets(player, target, function(targetPlayer)
        if targetPlayer.Character and targetPlayer.Character:FindFirstChild("Head") then
            targetPlayer.Character.Head:Destroy()
        end
    end)
end, {"k"})

AddCommand("punish", "Delete a player's character", {"<player>"}, 1, function(player, target)
    handleTargets(player, target, function(targetPlayer)
        if targetPlayer.Character then
            targetPlayer.Character:BreakJoints()
        end
    end)
end, {"p"})

AddCommand("tp", "Teleport a player to another player", {"<target> <destination>"}, 1, function(player, target, destination)
    if not destination then
        notify(player, "Crumbs Admin", "Usage: ,tp <target> <destination>", 3)
        return
    end
    
    local destPlayer = findPlayer(destination, player)
    if not destPlayer or not destPlayer.Character then 
        notify(player, "Crumbs Admin", "Destination player not found or has no character", 3)
        return 
    end
    
    handleTargets(player, target, function(targetPlayer)
        if targetPlayer.Character and destPlayer.Character then
            targetPlayer.Character:SetPrimaryPartCFrame(
                destPlayer.Character:GetPrimaryPartCFrame() * CFrame.new(0, 0, -5)
            )
        end
    end)
end, {"teleport"})

AddCommand("bring", "Bring a player to you", {"<player>"}, 1, function(player, target)
    if not player.Character then 
        notify(player, "Crumbs Admin", "You don't have a character", 3)
        return 
    end
    
    handleTargets(player, target, function(targetPlayer)
        if targetPlayer.Character then
            targetPlayer.Character:SetPrimaryPartCFrame(
                player.Character:GetPrimaryPartCFrame() * CFrame.new(0, 0, -5)
            )
        end
    end)
end, {"b"})

AddCommand("void", "Send player to the void", {"<player>"}, 1, function(player, target)
    handleTargets(player, target, function(targetPlayer)
        if targetPlayer.Character then
            local root = targetPlayer.Character:FindFirstChild("HumanoidRootPart")
            if root then
                root.CFrame = CFrame.new(root.Position.X, -500, root.Position.Z)
            end
        end
    end)
end, {"v"})

AddCommand("freeze", "Freeze a player", {"<player>"}, 1, function(player, target)
    handleTargets(player, target, function(targetPlayer)
        if targetPlayer.Character then
            for _, part in ipairs(targetPlayer.Character:GetDescendants()) do
                if part:IsA("BasePart") then
                    part.Anchored = true
                end
            end
        end
    end)
end, {"fz"})

AddCommand("unfreeze", "Unfreeze a player", {"<player>"}, 1, function(player, target)
    handleTargets(player, target, function(targetPlayer)
        if targetPlayer.Character then
            for _, part in ipairs(targetPlayer.Character:GetDescendants()) do
                if part:IsA("BasePart") then
                    part.Anchored = false
                end
            end
        end
    end)
end, {"ufz"})

AddCommand("invisible", "Make player invisible", {"<player>"}, 1, function(player, target)
    handleTargets(player, target, function(targetPlayer)
        if targetPlayer.Character then
            for _, part in ipairs(targetPlayer.Character:GetDescendants()) do
                if part:IsA("BasePart") then
                    part.Transparency = 1
                elseif part:IsA("Decal") or part:IsA("Texture") then
                    part.Transparency = 1
                end
            end
        end
    end)
end, {"inv"})

AddCommand("visible", "Make player visible", {"<player>"}, 1, function(player, target)
    handleTargets(player, target, function(targetPlayer)
        if targetPlayer.Character then
            for _, part in ipairs(targetPlayer.Character:GetDescendants()) do
                if part:IsA("BasePart") then
                    part.Transparency = 0
                elseif part:IsA("Decal") or part:IsA("Texture") then
                    part.Transparency = 0
                end
            end
        end
    end)
end, {"vis"})

AddCommand("paint", "Paint a player", {"<player> <color>"}, 1, function(player, target, color)
    if not color then
        notify(player, "Crumbs Admin", "Usage: ,paint <player> <color>", 3)
        return
    end
    
    local colorMap = {
        red = BrickColor.new("Bright red").Color,
        blue = BrickColor.new("Bright blue").Color,
        green = BrickColor.new("Bright green").Color,
        yellow = BrickColor.new("Bright yellow").Color,
        black = BrickColor.new("Black").Color,
        white = BrickColor.new("White").Color,
        orange = BrickColor.new("Bright orange").Color,
        purple = BrickColor.new("Bright violet").Color,
        pink = BrickColor.new("Hot pink").Color,
        brown = BrickColor.new("Brown").Color
    }
    
    local targetColor = colorMap[color:lower()]
    if not targetColor then
        targetColor = BrickColor.new(color).Color
    end
    
    handleTargets(player, target, function(targetPlayer)
        if targetPlayer.Character then
            for _, part in ipairs(targetPlayer.Character:GetDescendants()) do
                if part:IsA("BasePart") then
                    part.Color = targetColor
                end
            end
        end
    end)
end, {"color"})

AddCommand("removehats", "Remove player's hats", {"<player>"}, 1, function(player, target)
    handleTargets(player, target, function(targetPlayer)
        if targetPlayer.Character then
            for _, child in ipairs(targetPlayer.Character:GetChildren()) do
                if child:IsA("Accessory") then
                    child:Destroy()
                end
            end
        end
    end)
end, {"rh"})

AddCommand("removearms", "Remove player's arms", {"<player>"}, 1, function(player, target)
    handleTargets(player, target, function(targetPlayer)
        if targetPlayer.Character then
            local armNames = {"Left Arm", "Right Arm", "LeftHand", "RightHand", 
                            "LeftLowerArm", "RightLowerArm", "LeftUpperArm", "RightUpperArm"}
            for _, name in ipairs(armNames) do
                local part = targetPlayer.Character:FindFirstChild(name)
                if part then part:Destroy() end
            end
        end
    end)
end, {"rarms"})

AddCommand("removelegs", "Remove player's legs", {"<player>"}, 1, function(player, target)
    handleTargets(player, target, function(targetPlayer)
        if targetPlayer.Character then
            local legNames = {"Left Leg", "Right Leg", "LeftFoot", "RightFoot",
                            "LeftLowerLeg", "RightLowerLeg", "LeftUpperLeg", "RightUpperLeg"}
            for _, name in ipairs(legNames) do
                local part = targetPlayer.Character:FindFirstChild(name)
                if part then part:Destroy() end
            end
        end
    end)
end, {"rlegs"})

AddCommand("removelimbs", "Remove player's limbs", {"<player>"}, 1, function(player, target)
    handleTargets(player, target, function(targetPlayer)
        if targetPlayer.Character then
            for _, part in ipairs(targetPlayer.Character:GetDescendants()) do
                if part:IsA("BasePart") and part.Name ~= "Head" and part.Name ~= "Torso" and 
                   part.Name ~= "HumanoidRootPart" and part.Name ~= "UpperTorso" and 
                   part.Name ~= "LowerTorso" then
                    part:Destroy()
                end
            end
        end
    end)
end, {"rlimbs"})

AddCommand("noclip", "Make player noclip", {"<player>"}, 1, function(player, target)
    handleTargets(player, target, function(targetPlayer)
        if targetPlayer.Character then
            for _, part in ipairs(targetPlayer.Character:GetDescendants()) do
                if part:IsA("BasePart") then
                    part.CanCollide = false
                end
            end
        end
    end)
end, {"nc"})

AddCommand("clip", "Make player clip", {"<player>"}, 1, function(player, target)
    handleTargets(player, target, function(targetPlayer)
        if targetPlayer.Character then
            for _, part in ipairs(targetPlayer.Character:GetDescendants()) do
                if part:IsA("BasePart") then
                    part.CanCollide = true
                end
            end
        end
    end)
end, {"c"})

AddCommand("ws", "Unlock workspace", {}, 1, function()
    for _, part in ipairs(workspace:GetDescendants()) do
        if part:IsA("BasePart") then
            part.Locked = false
        end
    end
end, {"unlock"})

-- Rank 2 Commands (Baker)
AddCommand("kick", "Kick a player", {"<player>"}, 2, function(player, target)
    handleTargets(player, target, function(targetPlayer)
        if targetPlayer ~= player then
            targetPlayer:Kick("Kicked by " .. player.Name)
        end
    end)
end, {"k"})

AddCommand("ban", "Ban a player", {"<player>"}, 2, function(player, target)
    handleTargets(player, target, function(targetPlayer)
        if targetPlayer ~= player then
            banPlayer(player, targetPlayer)
        end
    end)
end, {"b"})

AddCommand("unban", "Unban a player", {"<player>"}, 2, function(player, target)
    handleTargets(player, target, function(targetPlayer)
        unbanPlayer(player, targetPlayer)
    end)
end, {"ub"})

AddCommand("clear", "Clear objects", {"<pads/house/building/obby>"}, 2, function(player, target)
    notify(player, "Crumbs Admin", "Clear command: " .. target, 3)
end, {"clr"})

AddCommand("reset", "Reset objects", {"<target>"}, 2, function(player, target)
    notify(player, "Crumbs Admin", "Reset command: " .. target, 3)
end, {"r"})

AddCommand("looppunish", "Continuously punish a player", {"<player>"}, 2, function(player, target)
    handleTargets(player, target, function(targetPlayer)
        if targetPlayer ~= player then
            startLoopPunish(player, targetPlayer)
        end
    end)
end, {"lp"})

AddCommand("unlooppunish", "Stop looping punish", {"<player>"}, 2, function(player, target)
    handleTargets(player, target, function(targetPlayer)
        stopLoopPunish(player, targetPlayer)
    end)
end, {"unlp"})

AddCommand("loopkill", "Continuously kill a player", {"<player>"}, 2, function(player, target)
    handleTargets(player, target, function(targetPlayer)
        if targetPlayer ~= player then
            startLoopKill(player, targetPlayer)
        end
    end)
end, {"lk"})

AddCommand("unloopkill", "Stop looping kill", {"<player>"}, 2, function(player, target)
    handleTargets(player, target, function(targetPlayer)
        stopLoopKill(player, targetPlayer)
    end)
end, {"unlk"})

-- Rank 3 Commands (Manager)
AddCommand("shutdown", "Shutdown the server", {}, 3, function(player)
    shutdownServer(player)
end, {"sd"})

AddCommand("eject", "Unload the admin system", {}, 3, function()
    notifyAll("Crumbs Admin", "Eject command not fully implemented in server version", 3)
end, {"unload"})

AddCommand("rank", "Rank a player", {"<player> <rank>"}, 3, function(player, target, rankName)
    if not target or not rankName then
        notify(player, "Crumbs Admin", "Usage: ,rank <player> <rank>", 3)
        return
    end
    
    local targetPlayer = findPlayer(target, player)
    if targetPlayer then
        rankPlayer(player, targetPlayer, rankName)
    else
        notify(player, "Crumbs Admin", "Player not found", 3)
    end
end, {})

AddCommand("unrank", "Unrank a player", {"<player>"}, 3, function(player, target)
    if not target then
        notify(player, "Crumbs Admin", "Usage: ,unrank <player>", 3)
        return
    end
    
    local targetPlayer = findPlayer(target, player)
    if targetPlayer then
        unrankPlayer(player, targetPlayer)
    else
        notify(player, "Crumbs Admin", "Player not found", 3)
    end
end, {})

-- Player Added Handler
Players.PlayerAdded:Connect(function(player)
    loadPlayerRank(player)
    
    -- Wait for PlayerGui
    local playerGui = player:WaitForChild("PlayerGui")
    
    -- Create GUI elements
    createCmdBarGui(player)
    
    -- Welcome notifications (only for this player)
    task.wait(2)
    notify(player, "Crumbs Admin", "Welcome " .. player.DisplayName .. "! Your rank: " .. (PlayerRanks[player] or "Customer"), 5)
    notify(player, "Crumbs Admin", "Press , for command bar | Type ,cmds for commands", 5)
end)

-- Player Removed Handler
Players.PlayerRemoving:Connect(function(player)
    -- Clean up
    PunishStatus[player] = nil
    LoopKillStatus[player] = nil
    PlayerRanks[player] = nil
    
    -- Clean up GUI instances
    if PlayerData[player] then
        for _, gui in ipairs(PlayerData[player].guiInstances) do
            pcall(function() gui:Destroy() end)
        end
        PlayerData[player] = nil
    end
end)

-- Input handler for comma key (needs to be on client, but we'll handle it through the GUI)
-- The text box will capture focus when clicked

-- Initialize chat handler
setupChatHandler()

-- Server start notification
task.wait(0.5) -- Wait for players to load
for _, player in ipairs(Players:GetPlayers()) do
    notify(player, "Crumbs Admin", "Tada~!! Crumbs Admin loaded successfully!! :3", 5)
end
print("Crumbs Admin loaded successfully!") -- Keep console print too
