-- Crumbs Admin - Complete Server-Side Version
-- Place this in ServerScriptService

local Players = game:GetService("Players")
local ServerScriptService = game:GetService("ServerScriptService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TeleportService = game:GetService("TeleportService")
local RunService = game:GetService("RunService")
local TextChatService = game:GetService("TextChatService")

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

-- Colors (for GUI)
local COLORS = {
    CHOCOLATE = Color3.fromRGB(74, 49, 28),
    MILK_CHOCOLATE = Color3.fromRGB(111, 78, 55),
    LIGHT_CHOCOLATE = Color3.fromRGB(139, 90, 43),
    COOKIE_DOUGH = Color3.fromRGB(210, 180, 140),
    WHITE = Color3.fromRGB(255, 255, 255),
    OFF_WHITE = Color3.fromRGB(240, 240, 240)
}

-- Module Storage
local AdminModule = {}

-- Data Stores
local PlayerRanks = {}
local PlayerData = {}
local PunishStatus = {}
local LoopKillStatus = {}
local BanStatus = {}

-- Services
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
        guiInstances = {}
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

-- GUI Creation Functions (Server pushes to client)
local function createNotificationGui(player, title, message, duration)
    local playerGui = player:FindFirstChild("PlayerGui")
    if not playerGui then return end
    
    -- Create ScreenGui
    local screenGui = Instance.new("ScreenGui")
    screenGui.Name = "CrumbsNotif_" .. tick()
    screenGui.ResetOnSpawn = false
    screenGui.Parent = playerGui
    
    -- Main frame
    local frame = Instance.new("Frame")
    frame.Name = "NotificationFrame"
    frame.Size = UDim2.new(0, 280, 0, 80)
    frame.Position = UDim2.new(1, -290, 1, -90)
    frame.BackgroundColor3 = COLORS.CHOCOLATE
    frame.BackgroundTransparency = 0.05
    frame.BorderSizePixel = 0
    frame.Parent = screenGui
    
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
    
    -- Store in player data
    table.insert(PlayerData[player].guiInstances, screenGui)
    
    -- Close function
    local function close()
        screenGui:Destroy()
        for i, gui in ipairs(PlayerData[player].guiInstances) do
            if gui == screenGui then
                table.remove(PlayerData[player].guiInstances, i)
                break
            end
        end
    end
    
    closeBtn.MouseButton1Click:Connect(close)
    
    -- Auto close after duration
    task.wait(duration or 4)
    close()
end

local function createDashboardGui(player, defaultTab)
    local playerGui = player:FindFirstChild("PlayerGui")
    if not playerGui then return end
    
    -- Clean up old dashboard
    if PlayerData[player].currentDashboard then
        PlayerData[player].currentDashboard:Destroy()
        PlayerData[player].currentDashboard = nil
    end
    
    -- Create ScreenGui
    local screenGui = Instance.new("ScreenGui")
    screenGui.Name = "CrumbsDashboard"
    screenGui.ResetOnSpawn = false
    screenGui.Parent = playerGui
    PlayerData[player].currentDashboard = screenGui
    table.insert(PlayerData[player].guiInstances, screenGui)
    
    -- Main frame
    local mainFrame = Instance.new("Frame")
    mainFrame.Name = "MainFrame"
    mainFrame.Size = UDim2.new(0, 750, 0, 420)
    mainFrame.Position = UDim2.new(0.5, -375, 0.5, -210)
    mainFrame.BackgroundColor3 = COLORS.CHOCOLATE
    mainFrame.BackgroundTransparency = 0.05
    mainFrame.BorderSizePixel = 2
    mainFrame.BorderColor3 = COLORS.LIGHT_CHOCOLATE
    mainFrame.Parent = screenGui
    
    local mainCorner = Instance.new("UICorner")
    mainCorner.CornerRadius = UDim.new(0, 12)
    mainCorner.Parent = mainFrame
    
    -- Top bar
    local topBar = Instance.new("Frame")
    topBar.Size = UDim2.new(1, 0, 0, 38)
    topBar.BackgroundColor3 = COLORS.MILK_CHOCOLATE
    topBar.BackgroundTransparency = 0.1
    topBar.BorderSizePixel = 0
    topBar.Parent = mainFrame
    
    local topBarCorner = Instance.new("UICorner")
    topBarCorner.CornerRadius = UDim.new(0, 12)
    topBarCorner.Parent = topBar
    
    local title = Instance.new("TextLabel")
    title.Size = UDim2.new(0, 200, 0, 38)
    title.Position = UDim2.new(0.36, 0, 0, 0)
    title.BackgroundTransparency = 1
    title.Text = "Crumbs Admin"
    title.TextColor3 = COLORS.OFF_WHITE
    title.TextSize = 22
    title.Font = Enum.Font.GothamBold
    title.Parent = topBar
    
    local closeBtn = Instance.new("TextButton")
    closeBtn.Size = UDim2.new(0, 32, 0, 32)
    closeBtn.Position = UDim2.new(1, -37, 0, 3)
    closeBtn.BackgroundTransparency = 1
    closeBtn.Text = "X"
    closeBtn.TextColor3 = COLORS.OFF_WHITE
    closeBtn.TextSize = 18
    closeBtn.Font = Enum.Font.GothamBold
    closeBtn.Parent = topBar
    
    -- Tab bar
    local tabBar = Instance.new("Frame")
    tabBar.Size = UDim2.new(1, -16, 0, 42)
    tabBar.Position = UDim2.new(0, 8, 0, 46)
    tabBar.BackgroundColor3 = COLORS.MILK_CHOCOLATE
    tabBar.BackgroundTransparency = 0.2
    tabBar.BorderSizePixel = 1
    tabBar.BorderColor3 = COLORS.LIGHT_CHOCOLATE
    tabBar.Parent = mainFrame
    
    local tabBarCorner = Instance.new("UICorner")
    tabBarCorner.CornerRadius = UDim.new(0, 8)
    tabBarCorner.Parent = tabBar
    
    local commandsTab = Instance.new("TextButton")
    commandsTab.Size = UDim2.new(0.5, -5, 0, 36)
    commandsTab.Position = UDim2.new(0, 4, 0, 3)
    commandsTab.BackgroundColor3 = COLORS.COOKIE_DOUGH
    commandsTab.BackgroundTransparency = 0.1
    commandsTab.BorderSizePixel = 1
    commandsTab.BorderColor3 = COLORS.LIGHT_CHOCOLATE
    commandsTab.Text = "Commands"
    commandsTab.TextColor3 = COLORS.CHOCOLATE
    commandsTab.TextSize = 16
    commandsTab.Font = Enum.Font.GothamBold
    commandsTab.Parent = tabBar
    
    local creditsTab = Instance.new("TextButton")
    creditsTab.Size = UDim2.new(0.5, -5, 0, 36)
    creditsTab.Position = UDim2.new(0.5, 1, 0, 3)
    creditsTab.BackgroundColor3 = COLORS.MILK_CHOCOLATE
    creditsTab.BackgroundTransparency = 0.3
    creditsTab.BorderSizePixel = 1
    creditsTab.BorderColor3 = COLORS.LIGHT_CHOCOLATE
    creditsTab.Text = "Info"
    creditsTab.TextColor3 = COLORS.OFF_WHITE
    creditsTab.TextSize = 16
    creditsTab.Font = Enum.Font.GothamBold
    creditsTab.Parent = tabBar
    
    -- Content frame
    local contentFrame = Instance.new("Frame")
    contentFrame.Size = UDim2.new(1, -16, 1, -104)
    contentFrame.Position = UDim2.new(0, 8, 0, 96)
    contentFrame.BackgroundColor3 = COLORS.MILK_CHOCOLATE
    contentFrame.BackgroundTransparency = 0.3
    contentFrame.BorderSizePixel = 1
    contentFrame.BorderColor3 = COLORS.LIGHT_CHOCOLATE
    contentFrame.Parent = mainFrame
    
    local contentCorner = Instance.new("UICorner")
    contentCorner.CornerRadius = UDim.new(0, 8)
    contentCorner.Parent = contentFrame
    
    -- Commands content
    local commandsContent = Instance.new("ScrollingFrame")
    commandsContent.Size = UDim2.new(1, 0, 1, 0)
    commandsContent.BackgroundColor3 = COLORS.MILK_CHOCOLATE
    commandsContent.BackgroundTransparency = 0
    commandsContent.BorderSizePixel = 0
    commandsContent.ScrollBarThickness = 6
    commandsContent.ScrollBarImageColor3 = COLORS.COOKIE_DOUGH
    commandsContent.Visible = (defaultTab == "Commands")
    commandsContent.Parent = contentFrame
    
    local commandsLayout = Instance.new("UIListLayout")
    commandsLayout.Parent = commandsContent
    commandsLayout.SortOrder = Enum.SortOrder.LayoutOrder
    commandsLayout.Padding = UDim.new(0, 5)
    
    -- Rank info
    local rankInfo = Instance.new("TextLabel")
    rankInfo.Size = UDim2.new(1, -20, 0, 40)
    rankInfo.Position = UDim2.new(0, 10, 0, 10)
    rankInfo.BackgroundTransparency = 1
    rankInfo.Text = "Your Rank: " .. (PlayerRanks[player] or "Customer")
    rankInfo.TextColor3 = COLORS.COOKIE_DOUGH
    rankInfo.TextSize = 24
    rankInfo.Font = Enum.Font.GothamBold
    rankInfo.Parent = commandsContent
    
    -- Credits content
    local creditsContent = Instance.new("ScrollingFrame")
    creditsContent.Size = UDim2.new(1, 0, 1, 0)
    creditsContent.BackgroundColor3 = COLORS.MILK_CHOCOLATE
    creditsContent.BackgroundTransparency = 0
    creditsContent.BorderSizePixel = 0
    creditsContent.ScrollBarThickness = 6
    creditsContent.ScrollBarImageColor3 = COLORS.COOKIE_DOUGH
    creditsContent.Visible = (defaultTab ~= "Commands")
    creditsContent.Parent = contentFrame
    
    local creditsLayout = Instance.new("UIListLayout")
    creditsLayout.Parent = creditsContent
    creditsLayout.SortOrder = Enum.SortOrder.LayoutOrder
    creditsLayout.Padding = UDim.new(0, 10)
    creditsLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
    
    local creditTitle = Instance.new("TextLabel")
    creditTitle.Size = UDim2.new(1, -20, 0, 40)
    creditTitle.BackgroundTransparency = 1
    creditTitle.Text = "Crumbs Admin"
    creditTitle.TextColor3 = COLORS.COOKIE_DOUGH
    creditTitle.TextSize = 28
    creditTitle.Font = Enum.Font.GothamBold
    creditTitle.Parent = creditsContent
    
    local versionLabel = Instance.new("TextLabel")
    versionLabel.Size = UDim2.new(1, -20, 0, 30)
    versionLabel.BackgroundTransparency = 1
    versionLabel.Text = "Version 2.0 - Server-Side"
    versionLabel.TextColor3 = COLORS.OFF_WHITE
    versionLabel.TextSize = 16
    versionLabel.Font = Enum.Font.Gotham
    versionLabel.Parent = creditsContent
    
    -- Tab switching
    local function switchTab(tab)
        if tab == "Commands" then
            commandsTab.BackgroundColor3 = COLORS.COOKIE_DOUGH
            commandsTab.TextColor3 = COLORS.CHOCOLATE
            creditsTab.BackgroundColor3 = COLORS.MILK_CHOCOLATE
            creditsTab.TextColor3 = COLORS.OFF_WHITE
            commandsContent.Visible = true
            creditsContent.Visible = false
        else
            commandsTab.BackgroundColor3 = COLORS.MILK_CHOCOLATE
            commandsTab.TextColor3 = COLORS.OFF_WHITE
            creditsTab.BackgroundColor3 = COLORS.COOKIE_DOUGH
            creditsTab.TextColor3 = COLORS.CHOCOLATE
            commandsContent.Visible = false
            creditsContent.Visible = true
        end
    end
    
    commandsTab.MouseButton1Click:Connect(function() switchTab("Commands") end)
    creditsTab.MouseButton1Click:Connect(function() switchTab("Credits") end)
    closeBtn.MouseButton1Click:Connect(function() screenGui:Destroy() PlayerData[player].currentDashboard = nil end)
    
    -- Dragging
    local dragging = false
    local dragStart, startPos
    
    topBar.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging = true
            dragStart = input.Position
            startPos = mainFrame.Position
        end
    end)
    
    game:GetService("UserInputService").InputChanged:Connect(function(input)
        if dragging and input.UserInputType == Enum.UserInputType.MouseMovement then
            local delta = input.Position - dragStart
            mainFrame.Position = UDim2.new(
                startPos.X.Scale,
                startPos.X.Offset + delta.X,
                startPos.Y.Scale,
                startPos.Y.Offset + delta.Y
            )
        end
    end)
    
    game:GetService("UserInputService").InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging = false
        end
    end)
end

local function createCmdBarGui(player)
    local playerGui = player:FindFirstChild("PlayerGui")
    if not playerGui then return end
    
    local screenGui = Instance.new("ScreenGui")
    screenGui.Name = "CrumbsCmdBar"
    screenGui.ResetOnSpawn = false
    screenGui.Parent = playerGui
    table.insert(PlayerData[player].guiInstances, screenGui)
    
    local cmdBarFrame = Instance.new("Frame")
    cmdBarFrame.Name = "CmdBarFrame"
    cmdBarFrame.Size = UDim2.new(0.5, 0, 0.08, 0)
    cmdBarFrame.Position = UDim2.new(0.25, 0, 1.2, 0)
    cmdBarFrame.BackgroundTransparency = 1
    cmdBarFrame.Visible = false
    cmdBarFrame.Parent = screenGui
    
    local cmdBarTextBox = Instance.new("TextBox")
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
    
    -- Rank indicator
    local rankIndicator = Instance.new("TextLabel")
    rankIndicator.Size = UDim2.new(0, 150, 0, 30)
    rankIndicator.Position = UDim2.new(1, -160, 0, 10)
    rankIndicator.BackgroundColor3 = COLORS.CHOCOLATE
    rankIndicator.BackgroundTransparency = 0.2
    rankIndicator.TextColor3 = COLORS.COOKIE_DOUGH
    rankIndicator.Text = "Rank: " .. (PlayerRanks[player] or "Customer")
    rankIndicator.TextSize = 14
    rankIndicator.Font = Enum.Font.GothamBold
    rankIndicator.Parent = screenGui
    
    local rankCorner = Instance.new("UICorner")
    rankCorner.CornerRadius = UDim.new(0, 8)
    rankCorner.Parent = rankIndicator
    
    -- Store in player data for toggling
    PlayerData[player].cmdBar = {
        frame = cmdBarFrame,
        textBox = cmdBarTextBox,
        rankIndicator = rankIndicator
    }
    
    -- Command handling
    cmdBarTextBox.FocusLost:Connect(function(enterPressed)
        if enterPressed then
            local commandText = cmdBarTextBox.Text
            cmdBarTextBox.Text = ""
            toggleCmdBar(player, false)
            
            if commandText ~= "" then
                handleCommand(player, commandText)
            end
        else
            toggleCmdBar(player, false)
        end
    end)
    
    -- Input handling for comma key
    game:GetService("UserInputService").InputBegan:Connect(function(input, gameProcessed)
        if player == Players.LocalPlayer and not gameProcessed and input.KeyCode == Enum.KeyCode.Comma then
            toggleCmdBar(player)
        end
    end)
end

local function toggleCmdBar(player, show)
    local cmdBar = PlayerData[player].cmdBar
    if not cmdBar then return end
    
    local frame = cmdBar.frame
    local textBox = cmdBar.textBox
    
    if show == nil then
        show = not frame.Visible
    end
    
    if show then
        frame.Visible = true
        frame.Position = UDim2.new(0.25, 0, 1.2, 0)
        
        -- Focus the text box (requires client focus, but we'll let the client handle this)
        -- In practice, the client would need to handle this, but for server-pushed GUI,
        -- we're relying on the fact that the text box exists on the client
        
        -- Animate in
        local tween = game:GetService("TweenService"):Create(frame, 
            TweenInfo.new(0.5, Enum.EasingStyle.Quad), 
            {Position = UDim2.new(0.25, 0, 0.85, 0)}
        )
        tween:Play()
    else
        -- Animate out
        local tween = game:GetService("TweenService"):Create(frame, 
            TweenInfo.new(0.3, Enum.EasingStyle.Quad), 
            {Position = UDim2.new(0.25, 0, 1.2, 0)}
        )
        tween:Play()
        
        tween.Completed:Connect(function()
            frame.Visible = false
        end)
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
local commands = {}
local commandAliases = {}

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
    
    local args = {}
    for word in string.gmatch(commandText, "%S+") do
        table.insert(args, word)
    end
    
    if #args == 0 then return end
    
    local cmdName = string.lower(args[1])
    table.remove(args, 1)
    
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
    local playerRankLevel = getRankLevel(player)
    if playerRankLevel < cmd.minRank then
        notify(player, "Crumbs Admin", "You don't have permission to use this command.", 3)
        return
    end
    
    -- Execute command
    local success, err = pcall(function()
        cmd.callback(player, unpack(args))
    end)
    
    if not success then
        warn("Command error:", err)
        notify(player, "Crumbs Admin", "Command execution failed.", 3)
    end
end

-- Initialize Chat Handler
local function setupChatHandler()
    if TextChatService.ChatVersion == Enum.ChatVersion.TextChatService then
        local textChatCommands = TextChatService:FindFirstChild("TextChatCommands")
        if not textChatCommands then
            textChatCommands = Instance.new("Folder")
            textChatCommands.Name = "TextChatCommands"
            textChatCommands.Parent = TextChatService
        end
        
        local cmdTrigger = Instance.new("TextChatCommand")
        cmdTrigger.Name = "CrumbsAdminCmd"
        cmdTrigger.TriggerTexts = {","}
        cmdTrigger.Parent = textChatCommands
        
        cmdTrigger.Callbacked:Connect(function(sender, messageText)
            if sender and string.sub(messageText, 1, 1) == "," then
                handleCommand(sender, messageText)
            end
        end)
    else
        -- Legacy chat
        Players.PlayerAdded:Connect(function(player)
            player.Chatted:Connect(function(message)
                if string.sub(message, 1, 1) == "," then
                    handleCommand(player, message)
                end
            end)
        end)
    end
end

-- Ban System
local function banPlayer(executor, target)
    if not target then return end
    
    BanStatus[target] = true
    
    -- Kick the player
    target:Kick("You have been banned by " .. executor.Name)
    
    -- Set up rejoin detection
    local connection
    connection = Players.PlayerAdded:Connect(function(player)
        if player == target then
            task.wait(0.5)
            if BanStatus[target] then
                player:Kick("You are banned from this server.")
            end
            connection:Disconnect()
        end
    end)
    
    PlayerData[executor].banConnections = PlayerData[executor].banConnections or {}
    table.insert(PlayerData[executor].banConnections, connection)
    
    -- Only notify executor, not all players
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
    -- Notify all players
    for _, player in ipairs(Players:GetPlayers()) do
        notify(player, "Crumbs Admin", "Server shutting down in 5 seconds...", 5)
    end
    
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
    if PlayerData[target].cmdBar and PlayerData[target].cmdBar.rankIndicator then
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
    if PlayerData[target].cmdBar and PlayerData[target].cmdBar.rankIndicator then
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
            if target.Character then
                target.Character:BreakJoints()
            end
            task.wait(0.5)
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
            if target.Character and target.Character:FindFirstChild("Head") then
                target.Character.Head:Destroy()
            end
            task.wait(0.5)
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

-- Handle multiple targets
local function handleTargets(executor, targetString, callback)
    if not targetString then return end
    
    local targets = {}
    if string.find(targetString, ",") then
        for name in string.gmatch(targetString, "([^,]+)") do
            name = name:gsub("^%s+", ""):gsub("%s+$", "")
            table.insert(targets, name)
        end
    else
        table.insert(targets, targetString)
    end
    
    for _, name in ipairs(targets) do
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
            if player then
                callback(player)
            end
        end
        task.wait(0.05)
    end
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

AddCommand("tp", "Teleport to a player", {"<target> <destination>"}, 1, function(player, target, destination)
    local destPlayer = findPlayer(destination, player)
    if not destPlayer or not destPlayer.Character then return end
    
    handleTargets(player, target, function(targetPlayer)
        if targetPlayer.Character and destPlayer.Character then
            targetPlayer.Character:SetPrimaryPartCFrame(
                destPlayer.Character:GetPrimaryPartCFrame() * CFrame.new(0, 0, -5)
            )
        end
    end)
end, {"teleport"})

AddCommand("bring", "Bring a player to you", {"<player>"}, 1, function(player, target)
    if not player.Character then return end
    
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
    local colorMap = {
        red = BrickColor.new("Bright red").Color,
        blue = BrickColor.new("Bright blue").Color,
        green = BrickColor.new("Bright green").Color,
        yellow = BrickColor.new("Bright yellow").Color,
        black = BrickColor.new("Black").Color,
        white = BrickColor.new("White").Color
    }
    
    local targetColor = colorMap[color:lower()] or BrickColor.new(color).Color
    
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
    -- Simplified clear for server-side
    notify(player, "Crumbs Admin", "Clear command simplified for server-side", 3)
end, {"clr"})

AddCommand("reset", "Reset objects", {"<target>"}, 2, function(player, target)
    -- Simplified reset
    notify(player, "Crumbs Admin", "Reset command simplified for server-side", 3)
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
    -- This would require a more complex implementation to actually unload
    notifyAll("Crumbs Admin", "Eject command not fully implemented in server version", 3)
end, {"unload"})

AddCommand("rank", "Rank a player", {"<player> <rank>"}, 3, function(player, target, rankName)
    local targetPlayer = findPlayer(target, player)
    if targetPlayer then
        rankPlayer(player, targetPlayer, rankName)
    end
end, {})

AddCommand("unrank", "Unrank a player", {"<player>"}, 3, function(player, target)
    local targetPlayer = findPlayer(target, player)
    if targetPlayer then
        unrankPlayer(player, targetPlayer)
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
    task.wait(1)
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

-- Initialize chat handler
setupChatHandler()

notifyAll("Crumbs Admin", "Tadaa~!! Crumbs Admin (SS) is loaded!! :3", 3)
