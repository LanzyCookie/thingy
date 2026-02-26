local Players = game:GetService("Players")
local ServerScriptService = game:GetService("ServerScriptService")
local RunService = game:GetService("RunService")
local TeleportService = game:GetService("TeleportService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local TextChatService = game:GetService("TextChatService")

local PREFIX = ","

local RANKS = {
    Customer = 1,
    Cashier = 2,
    Baker = 3,
    Manager = 4
}

local RANK_NAMES = {
    [0] = "User",
    [1] = "Customer",
    [2] = "Cashier",
    [3] = "Baker",
    [4] = "Manager"
}

local AUTO_WHITELIST = {
    --["Username"] = 4,
}

local playerRanks = {}
local tempRanks = {}
local activePunishments = {}
local activeLoopKills = {}
local bannedPlayers = {}
local commandCooldowns = {}
local playerGuis = {}
local notificationStacks = {}

local CHOCOLATE = Color3.fromRGB(74, 49, 28)
local MILK_CHOCOLATE = Color3.fromRGB(111, 78, 55)
local LIGHT_CHOCOLATE = Color3.fromRGB(139, 90, 43)
local COOKIE_DOUGH = Color3.fromRGB(210, 180, 140)
local WHITE = Color3.fromRGB(255, 255, 255)
local OFF_WHITE = Color3.fromRGB(240, 240, 240)

local function getPlayerRank(player)
    if tempRanks[player.UserId] then
        return tempRanks[player.UserId]
    end
    if playerRanks[player.UserId] then
        return playerRanks[player.UserId]
    end
    if AUTO_WHITELIST[player.Name] then
        return AUTO_WHITELIST[player.Name]
    end
    return 0
end

local function hasRank(player, requiredRank)
    return getPlayerRank(player) >= requiredRank
end

local function findPlayer(input)
    if not input or input == "" then return nil end
    
    input = string.lower(input)
    
    if input == "me" then
        return nil
    end
    
    if input == "random" then
        local eligible = {}
        for _, plr in ipairs(Players:GetPlayers()) do
            table.insert(eligible, plr)
        end
        return #eligible > 0 and eligible[math.random(1, #eligible)] or nil
    end
    
    for _, plr in ipairs(Players:GetPlayers()) do
        if string.lower(plr.Name) == input or string.lower(plr.DisplayName) == input then
            return plr
        end
    end
    
    for _, plr in ipairs(Players:GetPlayers()) do
        if string.find(string.lower(plr.Name), input, 1, true) or 
           string.find(string.lower(plr.DisplayName), input, 1, true) then
            return plr
        end
    end
    
    return nil
end

local function getPlayerParts(player)
    if not player or not player.Character then return {} end
    local parts = {}
    for _, descendant in ipairs(player.Character:GetDescendants()) do
        if descendant:IsA("BasePart") then
            table.insert(parts, descendant)
        end
    end
    return parts
end

local function getPlayerHead(player)
    if not player or not player.Character then return nil end
    return player.Character:FindFirstChild("Head")
end

local function createNotificationGui(player, title, message, duration)
    duration = duration or 4
    
    local screenGui = Instance.new("ScreenGui")
    screenGui.Name = "LNZNotification_" .. tick()
    screenGui.ResetOnSpawn = false
    screenGui.Parent = player:WaitForChild("PlayerGui")
    
    local frameWidth = 280
    local messagePadding = 20
    local titleAreaHeight = 38
    local verticalPadding = 10
    local dynamicHeight = math.max(titleAreaHeight + 70, 72)
    
    if not notificationStacks[player] then
        notificationStacks[player] = {}
    end
    
    for i = #notificationStacks[player], 1, -1 do
        if not notificationStacks[player][i] or not notificationStacks[player][i].gui or not notificationStacks[player][i].gui.Parent then
            table.remove(notificationStacks[player], i)
        end
    end

    local yOffset = 10
    for _, entry in ipairs(notificationStacks[player]) do
        yOffset = yOffset + entry.height + 6
    end
    
    local notifFrame = Instance.new("Frame")
    notifFrame.Name = "NotificationFrame"
    notifFrame.Size = UDim2.new(0, frameWidth, 0, dynamicHeight)
    notifFrame.Position = UDim2.new(1, -290, 1, -(yOffset + dynamicHeight))
    notifFrame.BackgroundColor3 = CHOCOLATE
    notifFrame.BackgroundTransparency = 1
    notifFrame.BorderSizePixel = 0
    notifFrame.Parent = screenGui
    
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 15)
    corner.Parent = notifFrame
    
    local titleLabel = Instance.new("TextLabel")
    titleLabel.Name = "Title"
    titleLabel.Text = title or "Crumbs Admin"
    titleLabel.Size = UDim2.new(1, -45, 0, 18)
    titleLabel.Position = UDim2.new(0, 10, 0, 6)
    titleLabel.TextColor3 = COOKIE_DOUGH
    titleLabel.TextTransparency = 1
    titleLabel.BackgroundTransparency = 1
    titleLabel.Font = Enum.Font.GothamBold
    titleLabel.TextSize = 13
    titleLabel.TextXAlignment = Enum.TextXAlignment.Left
    titleLabel.TextYAlignment = Enum.TextYAlignment.Top
    titleLabel.Parent = notifFrame
    
    local whiteLine = Instance.new("Frame")
    whiteLine.Name = "WhiteLine"
    whiteLine.Size = UDim2.new(1, -18, 0, 1)
    whiteLine.Position = UDim2.new(0, 9, 0, 27)
    whiteLine.BackgroundColor3 = MILK_CHOCOLATE
    whiteLine.BackgroundTransparency = 1
    whiteLine.BorderSizePixel = 0
    whiteLine.Parent = notifFrame
    
    local closeButton = Instance.new("TextButton")
    closeButton.Name = "CloseButton"
    closeButton.Size = UDim2.new(0, 24, 0, 24)
    closeButton.Position = UDim2.new(1, -30, 0, 5)
    closeButton.Text = "X"
    closeButton.TextColor3 = COOKIE_DOUGH
    closeButton.TextTransparency = 1
    closeButton.BackgroundTransparency = 1
    closeButton.BorderSizePixel = 0
    closeButton.Font = Enum.Font.GothamBold
    closeButton.TextSize = 15
    closeButton.Parent = notifFrame
    
    local messageLabel = Instance.new("TextLabel")
    messageLabel.Name = "Message"
    messageLabel.Text = message or ""
    messageLabel.Size = UDim2.new(1, -20, 1, -38)
    messageLabel.Position = UDim2.new(0, 10, 0, 32)
    messageLabel.TextColor3 = OFF_WHITE
    messageLabel.TextTransparency = 1
    messageLabel.BackgroundTransparency = 1
    messageLabel.Font = Enum.Font.Gotham
    messageLabel.TextSize = 12
    messageLabel.TextXAlignment = Enum.TextXAlignment.Left
    messageLabel.TextYAlignment = Enum.TextYAlignment.Top
    messageLabel.TextWrapped = true
    messageLabel.Parent = notifFrame
    
    local stackEntry = {
        gui = screenGui,
        frame = notifFrame,
        height = dynamicHeight,
        yOffset = yOffset
    }
    table.insert(notificationStacks[player], stackEntry)
    
    local closed = false
    
    local function restack()
        local runningOffset = 10
        for _, entry in ipairs(notificationStacks[player]) do
            if entry.gui and entry.gui.Parent and entry.frame and entry.frame.Parent then
                local targetY = -(runningOffset + entry.height)
                TweenService:Create(entry.frame, TweenInfo.new(0.25, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {
                    Position = UDim2.new(1, -290, 1, targetY)
                }):Play()
                entry.yOffset = runningOffset
                runningOffset = runningOffset + entry.height + 6
            end
        end
    end
    
    local function closeNotif()
        if closed then return end
        closed = true
        
        for i, entry in ipairs(notificationStacks[player]) do
            if entry.gui == screenGui then
                table.remove(notificationStacks[player], i)
                break
            end
        end
        
        local fadeOut1 = TweenService:Create(notifFrame, TweenInfo.new(0.4, Enum.EasingStyle.Sine), {BackgroundTransparency = 1})
        local fadeOut2 = TweenService:Create(titleLabel, TweenInfo.new(0.4, Enum.EasingStyle.Sine), {TextTransparency = 1})
        local fadeOut3 = TweenService:Create(whiteLine, TweenInfo.new(0.4, Enum.EasingStyle.Sine), {BackgroundTransparency = 1})
        local fadeOut4 = TweenService:Create(closeButton, TweenInfo.new(0.4, Enum.EasingStyle.Sine), {TextTransparency = 1})
        local fadeOut5 = TweenService:Create(messageLabel, TweenInfo.new(0.4, Enum.EasingStyle.Sine), {TextTransparency = 1})
        
        fadeOut1:Play()
        fadeOut2:Play()
        fadeOut3:Play()
        fadeOut4:Play()
        fadeOut5:Play()
        
        restack()
        
        fadeOut1.Completed:Connect(function()
            if screenGui and screenGui.Parent then
                screenGui:Destroy()
            end
        end)
    end
    
    closeButton.MouseButton1Click:Connect(closeNotif)
    
    local fadeIn1 = TweenService:Create(notifFrame, TweenInfo.new(0.5, Enum.EasingStyle.Sine), {BackgroundTransparency = 0.05})
    local fadeIn2 = TweenService:Create(titleLabel, TweenInfo.new(0.5, Enum.EasingStyle.Sine), {TextTransparency = 0})
    local fadeIn3 = TweenService:Create(whiteLine, TweenInfo.new(0.5, Enum.EasingStyle.Sine), {BackgroundTransparency = 0.2})
    local fadeIn4 = TweenService:Create(closeButton, TweenInfo.new(0.5, Enum.EasingStyle.Sine), {TextTransparency = 0})
    local fadeIn5 = TweenService:Create(messageLabel, TweenInfo.new(0.5, Enum.EasingStyle.Sine), {TextTransparency = 0})
    
    fadeIn1:Play()
    fadeIn2:Play()
    fadeIn3:Play()
    fadeIn4:Play()
    fadeIn5:Play()
    
    task.wait(duration)
    closeNotif()
end

local function notify(player, title, message, duration)
    createNotificationGui(player, title, message, duration)
end

local function notifyAll(title, message, duration)
    for _, plr in ipairs(Players:GetPlayers()) do
        createNotificationGui(plr, title, message, duration)
    end
end

local function createCmdBar(player)
    if playerGuis[player] then return end
    
    local screenGui = Instance.new("ScreenGui")
    screenGui.Name = "CmdBarGui"
    screenGui.Parent = player:WaitForChild("PlayerGui")
    screenGui.ResetOnSpawn = false
    screenGui.IgnoreGuiInset = true
    
    local cmdBarFrame = Instance.new("Frame")
    cmdBarFrame.Size = UDim2.new(0.5, 0, 0.08, 0)
    cmdBarFrame.Position = UDim2.new(0.25, 0, 1.2, 0)
    cmdBarFrame.BackgroundTransparency = 1
    cmdBarFrame.Visible = false
    cmdBarFrame.Parent = screenGui
    
    local cmdBarTextBox = Instance.new("TextBox")
    cmdBarTextBox.Size = UDim2.new(1, -4, 1, -4)
    cmdBarTextBox.Position = UDim2.new(0, 2, 0, 2)
    cmdBarTextBox.BackgroundColor3 = MILK_CHOCOLATE
    cmdBarTextBox.BackgroundTransparency = 0
    cmdBarTextBox.TextColor3 = WHITE
    cmdBarTextBox.TextSize = 18
    cmdBarTextBox.Font = Enum.Font.SourceSans
    cmdBarTextBox.PlaceholderText = "Enter command... ( , )"
    cmdBarTextBox.PlaceholderColor3 = COOKIE_DOUGH
    cmdBarTextBox.ClearTextOnFocus = false
    cmdBarTextBox.Text = ""
    cmdBarTextBox.Parent = cmdBarFrame
    
    local textBoxCorner = Instance.new("UICorner")
    textBoxCorner.CornerRadius = UDim.new(0, 10)
    textBoxCorner.Parent = cmdBarTextBox
    
    local hintLabel = Instance.new("TextLabel")
    hintLabel.Size = UDim2.new(0, 280, 0, 20)
    hintLabel.Position = UDim2.new(0, 10, 0, 10)
    hintLabel.BackgroundTransparency = 1
    hintLabel.TextColor3 = CHOCOLATE
    hintLabel.Text = "Crumbs Admin is running... (" .. PREFIX .. "cmds for help)"
    hintLabel.TextSize = 13
    hintLabel.Font = Enum.Font.SourceSans
    hintLabel.TextXAlignment = Enum.TextXAlignment.Left
    hintLabel.Parent = screenGui
    
    playerGuis[player] = {
        screen = screenGui,
        frame = cmdBarFrame,
        textBox = cmdBarTextBox,
        hint = hintLabel
    }
    
    local function animateTextBox(show)
        if show then
            cmdBarFrame.Visible = true
            cmdBarFrame.Position = UDim2.new(0.25, 0, 1.2, 0)
            
            local tween = TweenService:Create(cmdBarFrame, TweenInfo.new(0.8, Enum.EasingStyle.Quad, Enum.EasingDirection.InOut), {
                Position = UDim2.new(0.25, 0, 0.85, 0)
            })
            tween:Play()
        else
            local tween = TweenService:Create(cmdBarFrame, TweenInfo.new(0.5, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {
                Position = UDim2.new(0.25, 0, 1.2, 0)
            })
            tween:Play()
            
            tween.Completed:Connect(function()
                cmdBarFrame.Visible = false
            end)
        end
    end
    
    cmdBarTextBox.FocusLost:Connect(function(enterPressed)
        if enterPressed then
            local commandText = cmdBarTextBox.Text
            cmdBarTextBox.Text = ""
            
            animateTextBox(false)
            
            task.spawn(function()
                remoteEvent:FireServer(commandText)
            end)
        else
            animateTextBox(false)
        end
    end)
end

local function createDashboard(player, defaultTab)
    defaultTab = defaultTab or "Commands"
    
    local screenGui = Instance.new("ScreenGui")
    screenGui.Name = "LanzyDashboard"
    screenGui.ResetOnSpawn = false
    screenGui.Parent = player:WaitForChild("PlayerGui")
    
    if playerGuis[player] and playerGuis[player].dashboard then
        playerGuis[player].dashboard:Destroy()
    end
    
    local mainFrame = Instance.new("Frame")
    mainFrame.Name = "MainFrame"
    mainFrame.Size = UDim2.new(0, 750, 0, 420)
    mainFrame.Position = UDim2.new(0.5, -375, 0.5, -210)
    mainFrame.BackgroundColor3 = CHOCOLATE
    mainFrame.BackgroundTransparency = 0.05
    mainFrame.BorderSizePixel = 2
    mainFrame.BorderColor3 = LIGHT_CHOCOLATE
    mainFrame.Parent = screenGui
    
    local mainCorner = Instance.new("UICorner")
    mainCorner.CornerRadius = UDim.new(0, 12)
    mainCorner.Parent = mainFrame
    
    local topBar = Instance.new("Frame")
    topBar.Name = "TopBar"
    topBar.Size = UDim2.new(1, 0, 0, 38)
    topBar.BackgroundColor3 = MILK_CHOCOLATE
    topBar.BackgroundTransparency = 0.1
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
    title.TextColor3 = OFF_WHITE
    title.TextSize = 22
    title.Font = Enum.Font.GothamBold
    title.Parent = topBar
    
    local closeButton = Instance.new("TextButton")
    closeButton.Name = "CloseButton"
    closeButton.Size = UDim2.new(0, 32, 0, 32)
    closeButton.Position = UDim2.new(1, -37, 0, 3)
    closeButton.BackgroundTransparency = 1
    closeButton.Text = "X"
    closeButton.TextColor3 = OFF_WHITE
    closeButton.TextSize = 18
    closeButton.Font = Enum.Font.GothamBold
    closeButton.Parent = topBar
    
    local tabBar = Instance.new("Frame")
    tabBar.Name = "TabBar"
    tabBar.Size = UDim2.new(1, -16, 0, 42)
    tabBar.Position = UDim2.new(0, 8, 0, 46)
    tabBar.BackgroundColor3 = MILK_CHOCOLATE
    tabBar.BackgroundTransparency = 0.2
    tabBar.BorderSizePixel = 1
    tabBar.BorderColor3 = LIGHT_CHOCOLATE
    tabBar.Parent = mainFrame
    
    local tabBarCorner = Instance.new("UICorner")
    tabBarCorner.CornerRadius = UDim.new(0, 8)
    tabBarCorner.Parent = tabBar
    
    local commandsTab = Instance.new("TextButton")
    commandsTab.Name = "CommandsTab"
    commandsTab.Size = UDim2.new(0.5, -5, 0, 36)
    commandsTab.Position = UDim2.new(0, 4, 0, 3)
    commandsTab.BackgroundColor3 = defaultTab == "Commands" and COOKIE_DOUGH or MILK_CHOCOLATE
    commandsTab.BackgroundTransparency = defaultTab == "Commands" and 0.1 or 0.3
    commandsTab.BorderSizePixel = 1
    commandsTab.BorderColor3 = LIGHT_CHOCOLATE
    commandsTab.Text = "Commands"
    commandsTab.TextColor3 = defaultTab == "Commands" and CHOCOLATE or OFF_WHITE
    commandsTab.TextSize = 16
    commandsTab.Font = Enum.Font.GothamBold
    commandsTab.Parent = tabBar
    
    local commandsTabCorner = Instance.new("UICorner")
    commandsTabCorner.CornerRadius = UDim.new(0, 6)
    commandsTabCorner.Parent = commandsTab
    
    local creditsTab = Instance.new("TextButton")
    creditsTab.Name = "CreditsTab"
    creditsTab.Size = UDim2.new(0.5, -5, 0, 36)
    creditsTab.Position = UDim2.new(0.5, 1, 0, 3)
    creditsTab.BackgroundColor3 = defaultTab == "Credits" and COOKIE_DOUGH or MILK_CHOCOLATE
    creditsTab.BackgroundTransparency = defaultTab == "Credits" and 0.1 or 0.3
    creditsTab.BorderSizePixel = 1
    creditsTab.BorderColor3 = LIGHT_CHOCOLATE
    creditsTab.Text = "Credits"
    creditsTab.TextColor3 = defaultTab == "Credits" and CHOCOLATE or OFF_WHITE
    creditsTab.TextSize = 16
    creditsTab.Font = Enum.Font.GothamBold
    creditsTab.Parent = tabBar
    
    local creditsTabCorner = Instance.new("UICorner")
    creditsTabCorner.CornerRadius = UDim.new(0, 6)
    creditsTabCorner.Parent = creditsTab
    
    local contentFrame = Instance.new("Frame")
    contentFrame.Name = "ContentFrame"
    contentFrame.Size = UDim2.new(1, -16, 1, -104)
    contentFrame.Position = UDim2.new(0, 8, 0, 96)
    contentFrame.BackgroundColor3 = MILK_CHOCOLATE
    contentFrame.BackgroundTransparency = 0.3
    contentFrame.BorderSizePixel = 1
    contentFrame.BorderColor3 = LIGHT_CHOCOLATE
    contentFrame.Parent = mainFrame
    
    local contentCorner = Instance.new("UICorner")
    contentCorner.CornerRadius = UDim.new(0, 8)
    contentCorner.Parent = contentFrame
    
    local commandsContent = Instance.new("ScrollingFrame")
    commandsContent.Name = "CommandsContent"
    commandsContent.Size = UDim2.new(1, 0, 1, 0)
    commandsContent.Position = UDim2.new(0, 0, 0, 0)
    commandsContent.BackgroundColor3 = MILK_CHOCOLATE
    commandsContent.BackgroundTransparency = 0
    commandsContent.BorderSizePixel = 0
    commandsContent.ScrollBarThickness = 6
    commandsContent.ScrollBarImageColor3 = COOKIE_DOUGH
    commandsContent.Visible = (defaultTab == "Commands")
    commandsContent.Parent = contentFrame
    
    local commandsContentCorner = Instance.new("UICorner")
    commandsContentCorner.CornerRadius = UDim.new(0, 8)
    commandsContentCorner.Parent = commandsContent
    
    local commandsLayout = Instance.new("UIListLayout")
    commandsLayout.Parent = commandsContent
    commandsLayout.SortOrder = Enum.SortOrder.LayoutOrder
    commandsLayout.Padding = UDim.new(0, 5)
    
    local creditsContent = Instance.new("ScrollingFrame")
    creditsContent.Name = "CreditsContent"
    creditsContent.Size = UDim2.new(1, 0, 1, 0)
    creditsContent.Position = UDim2.new(0, 0, 0, 0)
    creditsContent.BackgroundColor3 = MILK_CHOCOLATE
    creditsContent.BackgroundTransparency = 1
    creditsContent.BorderSizePixel = 0
    creditsContent.ScrollBarThickness = 6
    creditsContent.ScrollBarImageColor3 = COOKIE_DOUGH
    creditsContent.Visible = (defaultTab == "Credits")
    creditsContent.Parent = contentFrame
    
    local creditsContentCorner = Instance.new("UICorner")
    creditsContentCorner.CornerRadius = UDim.new(0, 8)
    creditsContentCorner.Parent = creditsContent
    
    local creditsLayout = Instance.new("UIListLayout")
    creditsLayout.Parent = creditsContent
    creditsLayout.SortOrder = Enum.SortOrder.LayoutOrder
    creditsLayout.Padding = UDim.new(0, 10)
    creditsLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
    
    local creditTitle = Instance.new("TextLabel")
    creditTitle.Size = UDim2.new(1, -20, 0, 40)
    creditTitle.Position = UDim2.new(0, 10, 0, 10)
    creditTitle.BackgroundTransparency = 1
    creditTitle.Text = "CREDITS"
    creditTitle.TextColor3 = COOKIE_DOUGH
    creditTitle.TextSize = 28
    creditTitle.Font = Enum.Font.GothamBold
    creditTitle.TextWrapped = true
    creditTitle.Parent = creditsContent
    
    local creditDivider = Instance.new("Frame")
    creditDivider.Size = UDim2.new(0.8, 0, 0, 2)
    creditDivider.Position = UDim2.new(0.1, 0, 0, 55)
    creditDivider.BackgroundColor3 = COOKIE_DOUGH
    creditDivider.BackgroundTransparency = 0
    creditDivider.BorderSizePixel = 0
    creditDivider.Parent = creditsContent
    
    local credits = {
        {role = "Creator", name = "Crumbs Admin", desc = "Made with love"},
        {role = "Version", name = "Crumbs Admin v2.0", desc = "Full server-side admin system"},
    }
    
    local yPos = 70
    for _, credit in ipairs(credits) do
        local creditFrame = Instance.new("Frame")
        creditFrame.Size = UDim2.new(0.9, 0, 0, 80)
        creditFrame.Position = UDim2.new(0.05, 0, 0, yPos)
        creditFrame.BackgroundColor3 = LIGHT_CHOCOLATE
        creditFrame.BackgroundTransparency = 0.3
        creditFrame.BorderSizePixel = 1
        creditFrame.BorderColor3 = COOKIE_DOUGH
        creditFrame.Parent = creditsContent
        
        local creditFrameCorner = Instance.new("UICorner")
        creditFrameCorner.CornerRadius = UDim.new(0, 8)
        creditFrameCorner.Parent = creditFrame
        
        local roleLabel = Instance.new("TextLabel")
        roleLabel.Size = UDim2.new(1, -20, 0, 20)
        roleLabel.Position = UDim2.new(0, 10, 0, 8)
        roleLabel.BackgroundTransparency = 1
        roleLabel.Text = credit.role
        roleLabel.TextColor3 = COOKIE_DOUGH
        roleLabel.TextSize = 16
        roleLabel.Font = Enum.Font.GothamBold
        roleLabel.TextXAlignment = Enum.TextXAlignment.Left
        roleLabel.Parent = creditFrame
        
        local nameLabel = Instance.new("TextLabel")
        nameLabel.Size = UDim2.new(1, -20, 0, 22)
        nameLabel.Position = UDim2.new(0, 10, 0, 28)
        nameLabel.BackgroundTransparency = 1
        nameLabel.Text = credit.name
        nameLabel.TextColor3 = OFF_WHITE
        nameLabel.TextSize = 18
        nameLabel.Font = Enum.Font.GothamBold
        nameLabel.TextXAlignment = Enum.TextXAlignment.Left
        nameLabel.Parent = creditFrame
        
        local descLabel = Instance.new("TextLabel")
        descLabel.Size = UDim2.new(1, -20, 0, 16)
        descLabel.Position = UDim2.new(0, 10, 0, 52)
        descLabel.BackgroundTransparency = 1
        descLabel.Text = credit.desc
        descLabel.TextColor3 = CHOCOLATE
        descLabel.TextSize = 12
        descLabel.Font = Enum.Font.Gotham
        descLabel.TextXAlignment = Enum.TextXAlignment.Left
        descLabel.TextWrapped = true
        descLabel.Parent = creditFrame
        
        yPos = yPos + 90
    end
    
    local specialThanks = Instance.new("TextLabel")
    specialThanks.Size = UDim2.new(0.9, 0, 0, 40)
    specialThanks.Position = UDim2.new(0.05, 0, 0, yPos + 10)
    specialThanks.BackgroundTransparency = 1
    specialThanks.Text = "Your rank: " .. RANK_NAMES[getPlayerRank(player)] .. " (" .. getPlayerRank(player) .. ")"
    specialThanks.TextColor3 = COOKIE_DOUGH
    specialThanks.TextSize = 14
    specialThanks.Font = Enum.Font.GothamBold
    specialThanks.TextWrapped = true
    specialThanks.Parent = creditsContent
    
    yPos = yPos + 60
    creditsContent.CanvasSize = UDim2.new(0, 0, 0, yPos + 20)
    
    local availableCommands = {}
    for cmdName, cmdData in pairs(COMMANDS) do
        if cmdData.rank <= getPlayerRank(player) then
            table.insert(availableCommands, {name = cmdName, data = cmdData})
        end
    end
    
    table.sort(availableCommands, function(a, b)
        return a.name < b.name
    end)
    
    for counter, cmdEntry in ipairs(availableCommands) do
        local cmdData = cmdEntry.data
    
        local commandFrame = Instance.new("Frame")
        commandFrame.Name = "Command_" .. cmdEntry.name
        commandFrame.Size = UDim2.new(1, -12, 0, 60)
        commandFrame.BackgroundColor3 = LIGHT_CHOCOLATE
        commandFrame.BackgroundTransparency = 0.3
        commandFrame.BorderSizePixel = 1
        commandFrame.BorderColor3 = COOKIE_DOUGH
        commandFrame.Parent = commandsContent
    
        local cmdCorner = Instance.new("UICorner")
        cmdCorner.CornerRadius = UDim.new(0, 6)
        cmdCorner.Parent = commandFrame
    
        local commandLabel = Instance.new("TextLabel")
        commandLabel.Size = UDim2.new(0.5, 0, 0, 16)
        commandLabel.Position = UDim2.new(0, 6, 0, 3)
        commandLabel.BackgroundTransparency = 1
        commandLabel.Text = counter .. " | " .. PREFIX .. cmdEntry.name
        commandLabel.TextColor3 = OFF_WHITE
        commandLabel.TextSize = 15
        commandLabel.Font = Enum.Font.GothamBold
        commandLabel.TextXAlignment = Enum.TextXAlignment.Left
        commandLabel.Parent = commandFrame
    
        local aliasText = "Aliases: None"
        if cmdData.aliases and #cmdData.aliases > 0 then
            aliasText = "Aliases: {" .. table.concat(cmdData.aliases, ", ") .. "}"
        end
    
        local commandAlias = Instance.new("TextLabel")
        commandAlias.Size = UDim2.new(1, -12, 0, 12)
        commandAlias.Position = UDim2.new(0, 6, 0, 20)
        commandAlias.BackgroundTransparency = 1
        commandAlias.Text = aliasText
        commandAlias.TextColor3 = COOKIE_DOUGH
        commandAlias.TextSize = 10
        commandAlias.Font = Enum.Font.Gotham
        commandAlias.TextXAlignment = Enum.TextXAlignment.Left
        commandAlias.Parent = commandFrame
    
        local descLabel = Instance.new("TextLabel")
        descLabel.Size = UDim2.new(1, -12, 0, 11)
        descLabel.Position = UDim2.new(0, 6, 0, 33)
        descLabel.BackgroundTransparency = 1
        descLabel.Text = "Rank required: " .. RANK_NAMES[cmdData.rank] .. " (" .. cmdData.rank .. ")"
        descLabel.TextColor3 = OFF_WHITE
        descLabel.TextSize = 11
        descLabel.Font = Enum.Font.Gotham
        descLabel.TextXAlignment = Enum.TextXAlignment.Left
        descLabel.Parent = commandFrame
    
        local usageLabel = Instance.new("TextLabel")
        usageLabel.Size = UDim2.new(1, -12, 0, 10)
        usageLabel.Position = UDim2.new(0, 6, 0, 48)
        usageLabel.BackgroundTransparency = 1
        usageLabel.Text = "Usage: " .. PREFIX .. cmdEntry.name .. (cmdData.minArgs > 0 and " <args>" or "")
        usageLabel.TextColor3 = COOKIE_DOUGH
        usageLabel.TextSize = 10
        usageLabel.Font = Enum.Font.Gotham
        usageLabel.TextXAlignment = Enum.TextXAlignment.Left
        usageLabel.Parent = commandFrame
    end
    
    commandsLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
        commandsContent.CanvasSize = UDim2.new(0, 0, 0, commandsLayout.AbsoluteContentSize.Y + 10)
    end)
    commandsContent.CanvasSize = UDim2.new(0, 0, 0, commandsLayout.AbsoluteContentSize.Y + 10)
    
    local function switchTab(tabName)
        if tabName == "Commands" then
            TweenService:Create(commandsTab, TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
                BackgroundColor3 = COOKIE_DOUGH,
                BackgroundTransparency = 0.1,
                TextColor3 = CHOCOLATE
            }):Play()
            
            TweenService:Create(creditsTab, TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
                BackgroundColor3 = MILK_CHOCOLATE,
                BackgroundTransparency = 0.3,
                TextColor3 = OFF_WHITE
            }):Play()
            
            commandsContent.Visible = true
            creditsContent.Visible = false
        else
            TweenService:Create(creditsTab, TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
                BackgroundColor3 = COOKIE_DOUGH,
                BackgroundTransparency = 0.1,
                TextColor3 = CHOCOLATE
            }):Play()
            
            TweenService:Create(commandsTab, TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
                BackgroundColor3 = MILK_CHOCOLATE,
                BackgroundTransparency = 0.3,
                TextColor3 = OFF_WHITE
            }):Play()
            
            commandsContent.Visible = false
            creditsContent.Visible = true
        end
    end
    
    commandsTab.MouseButton1Click:Connect(function()
        switchTab("Commands")
    end)
    
    creditsTab.MouseButton1Click:Connect(function()
        switchTab("Credits")
    end)
    
    local dragging = false
    local dragStart = nil
    local startPos = nil
    
    topBar.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging = true
            dragStart = input.Position
            startPos = mainFrame.Position
        end
    end)
    
    topBar.InputChanged:Connect(function(input)
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
    
    topBar.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging = false
        end
    end)
    
    closeButton.MouseButton1Click:Connect(function()
        TweenService:Create(mainFrame, TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
            BackgroundTransparency = 1
        }):Play()
        TweenService:Create(topBar, TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
            BackgroundTransparency = 1
        }):Play()
        TweenService:Create(title, TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
            TextTransparency = 1
        }):Play()
        TweenService:Create(closeButton, TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
            TextTransparency = 1
        }):Play()
        
        task.wait(0.15)
        screenGui:Destroy()
    end)
    
    if playerGuis[player] then
        playerGuis[player].dashboard = screenGui
    end
end

local function cmd_rj(executor, args)
    notify(executor, "Crumbs Admin", "Rejoining...", 2)
    task.wait(1)
    TeleportService:TeleportToPlaceInstance(game.PlaceId, game.JobId, executor)
end

local function cmd_punish(executor, args)
    if not args[1] then return end
    
    local target = findPlayer(args[1])
    if not target then
        notify(executor, "Crumbs Admin", "Player not found.", 3)
        return
    end
    
    if not target.Character then
        notify(executor, "Crumbs Admin", "Player has no character.", 3)
        return
    end
    
    target.Character:Destroy()
    notify(executor, "Crumbs Admin", "Punished " .. target.Name .. ".", 3)
end

local function cmd_kill(executor, args)
    if not args[1] then return end
    
    local function killPlayer(player)
        local head = getPlayerHead(player)
        if head then
            head:Destroy()
        end
    end
    
    if args[1]:lower() == "all" then
        local count = 0
        for _, plr in ipairs(Players:GetPlayers()) do
            if plr.Character then
                killPlayer(plr)
                count = count + 1
            end
        end
        notify(executor, "Crumbs Admin", "Killed " .. count .. " players.", 3)
        
    elseif args[1]:lower() == "others" then
        local count = 0
        for _, plr in ipairs(Players:GetPlayers()) do
            if plr ~= executor and plr.Character then
                killPlayer(plr)
                count = count + 1
            end
        end
        notify(executor, "Crumbs Admin", "Killed " .. count .. " other players.", 3)
        
    elseif args[1]:lower() == "random" then
        local eligible = {}
        for _, plr in ipairs(Players:GetPlayers()) do
            if plr.Character then
                table.insert(eligible, plr)
            end
        end
        if #eligible > 0 then
            local target = eligible[math.random(1, #eligible)]
            killPlayer(target)
            notify(executor, "Crumbs Admin", "Killed random player: " .. target.Name, 3)
        end
        
    else
        local target = findPlayer(args[1])
        if target and target.Character then
            killPlayer(target)
            notify(executor, "Crumbs Admin", "Killed " .. target.Name .. ".", 3)
        end
    end
end

local function cmd_freeze(executor, args)
    if not args[1] then return end
    
    local function freezePlayer(player)
        if not player.Character then return false end
        for _, part in ipairs(getPlayerParts(player)) do
            part.Anchored = true
        end
        return true
    end
    
    if args[1]:lower() == "all" then
        local count = 0
        for _, plr in ipairs(Players:GetPlayers()) do
            if freezePlayer(plr) then count = count + 1 end
        end
        notify(executor, "Crumbs Admin", "Froze " .. count .. " players.", 3)
        
    elseif args[1]:lower() == "others" then
        local count = 0
        for _, plr in ipairs(Players:GetPlayers()) do
            if plr ~= executor and freezePlayer(plr) then count = count + 1 end
        end
        notify(executor, "Crumbs Admin", "Froze " .. count .. " other players.", 3)
        
    else
        local target = findPlayer(args[1])
        if target and freezePlayer(target) then
            notify(executor, "Crumbs Admin", "Froze " .. target.Name .. ".", 3)
        end
    end
end

local function cmd_unfreeze(executor, args)
    if not args[1] then return end
    
    local function unfreezePlayer(player)
        if not player.Character then return false end
        for _, part in ipairs(getPlayerParts(player)) do
            part.Anchored = false
        end
        return true
    end
    
    if args[1]:lower() == "all" then
        local count = 0
        for _, plr in ipairs(Players:GetPlayers()) do
            if unfreezePlayer(plr) then count = count + 1 end
        end
        notify(executor, "Crumbs Admin", "Unfroze " .. count .. " players.", 3)
        
    elseif args[1]:lower() == "others" then
        local count = 0
        for _, plr in ipairs(Players:GetPlayers()) do
            if plr ~= executor and unfreezePlayer(plr) then count = count + 1 end
        end
        notify(executor, "Crumbs Admin", "Unfroze " .. count .. " other players.", 3)
        
    else
        local target = findPlayer(args[1])
        if target and unfreezePlayer(target) then
            notify(executor, "Crumbs Admin", "Unfroze " .. target.Name .. ".", 3)
        end
    end
end

local function cmd_noclip(executor, args)
    if not args[1] then return end
    
    local function setNoclip(player)
        if not player.Character then return false end
        for _, part in ipairs(getPlayerParts(player)) do
            part.CanCollide = false
        end
        return true
    end
    
    if args[1]:lower() == "all" then
        local count = 0
        for _, plr in ipairs(Players:GetPlayers()) do
            if setNoclip(plr) then count = count + 1 end
        end
        notify(executor, "Crumbs Admin", "Disabled collision for " .. count .. " players.", 3)
        
    elseif args[1]:lower() == "others" then
        local count = 0
        for _, plr in ipairs(Players:GetPlayers()) do
            if plr ~= executor and setNoclip(plr) then count = count + 1 end
        end
        notify(executor, "Crumbs Admin", "Disabled collision for " .. count .. " other players.", 3)
        
    else
        local target = findPlayer(args[1])
        if target and setNoclip(target) then
            notify(executor, "Crumbs Admin", "Disabled collision for " .. target.Name .. ".", 3)
        end
    end
end

local function cmd_clip(executor, args)
    if not args[1] then return end
    
    local function setClip(player)
        if not player.Character then return false end
        
        local essentialParts = {
            "Head", "Torso", "HumanoidRootPart", "UpperTorso", "LowerTorso"
        }
        
        for _, part in ipairs(getPlayerParts(player)) do
            local isEssential = false
            for _, essential in ipairs(essentialParts) do
                if part.Name == essential then
                    isEssential = true
                    break
                end
            end
            part.CanCollide = isEssential
        end
        return true
    end
    
    if args[1]:lower() == "all" then
        local count = 0
        for _, plr in ipairs(Players:GetPlayers()) do
            if setClip(plr) then count = count + 1 end
        end
        notify(executor, "Crumbs Admin", "Enabled essential collision for " .. count .. " players.", 3)
        
    elseif args[1]:lower() == "others" then
        local count = 0
        for _, plr in ipairs(Players:GetPlayers()) do
            if plr ~= executor and setClip(plr) then count = count + 1 end
        end
        notify(executor, "Crumbs Admin", "Enabled essential collision for " .. count .. " other players.", 3)
        
    else
        local target = findPlayer(args[1])
        if target and setClip(target) then
            notify(executor, "Crumbs Admin", "Enabled essential collision for " .. target.Name .. ".", 3)
        end
    end
end

local function cmd_void(executor, args)
    if not args[1] then return end
    
    local function sendToVoid(player)
        if not player.Character or not player.Character:FindFirstChild("HumanoidRootPart") then return false end
        local root = player.Character.HumanoidRootPart
        root.CFrame = CFrame.new(root.Position.X, -5000, root.Position.Z)
        return true
    end
    
    if args[1]:lower() == "all" then
        local count = 0
        for _, plr in ipairs(Players:GetPlayers()) do
            if sendToVoid(plr) then count = count + 1 end
        end
        notify(executor, "Crumbs Admin", "Sent " .. count .. " players to the void.", 3)
        
    elseif args[1]:lower() == "others" then
        local count = 0
        for _, plr in ipairs(Players:GetPlayers()) do
            if plr ~= executor and sendToVoid(plr) then count = count + 1 end
        end
        notify(executor, "Crumbs Admin", "Sent " .. count .. " other players to the void.", 3)
        
    else
        local target = findPlayer(args[1])
        if target and sendToVoid(target) then
            notify(executor, "Crumbs Admin", "Sent " .. target.Name .. " to the void.", 3)
        end
    end
end

local function cmd_skydive(executor, args)
    if not args[1] then return end
    
    local height = tonumber(args[2]) or 1000
    if height < 1000 then height = 1000 end
    
    local function launchPlayer(player)
        if not player.Character or not player.Character:FindFirstChild("HumanoidRootPart") then return false end
        local root = player.Character.HumanoidRootPart
        root.CFrame = CFrame.new(root.Position.X, root.Position.Y + height, root.Position.Z)
        return true
    end
    
    if args[1]:lower() == "all" then
        local count = 0
        for _, plr in ipairs(Players:GetPlayers()) do
            if launchPlayer(plr) then count = count + 1 end
        end
        notify(executor, "Crumbs Admin", "Launched " .. count .. " players " .. height .. " studs into the sky.", 3)
        
    elseif args[1]:lower() == "others" then
        local count = 0
        for _, plr in ipairs(Players:GetPlayers()) do
            if plr ~= executor and launchPlayer(plr) then count = count + 1 end
        end
        notify(executor, "Crumbs Admin", "Launched " .. count .. " other players " .. height .. " studs into the sky.", 3)
        
    else
        local target = findPlayer(args[1])
        if target and launchPlayer(target) then
            notify(executor, "Crumbs Admin", "Launched " .. target.Name .. " " .. height .. " studs into the sky.", 3)
        end
    end
end

local function cmd_tp(executor, args)
    if not args[1] or not args[2] then return end
    
    local destPlayer
    if args[2]:lower() == "me" then
        destPlayer = executor
    else
        destPlayer = findPlayer(args[2])
    end
    
    if not destPlayer or not destPlayer.Character or not destPlayer.Character:FindFirstChild("HumanoidRootPart") then
        notify(executor, "Crumbs Admin", "Destination player not valid.", 3)
        return
    end
    
    local destPos = destPlayer.Character.HumanoidRootPart.CFrame * CFrame.new(0, 0, -5)
    
    local function teleportPlayer(player)
        if not player.Character or not player.Character:FindFirstChild("HumanoidRootPart") then return false end
        player.Character.HumanoidRootPart.CFrame = destPos
        return true
    end
    
    if args[1]:lower() == "all" then
        local count = 0
        for _, plr in ipairs(Players:GetPlayers()) do
            if teleportPlayer(plr) then count = count + 1 end
        end
        notify(executor, "Crumbs Admin", "Teleported " .. count .. " players to " .. destPlayer.Name .. ".", 3)
        
    elseif args[1]:lower() == "others" then
        local count = 0
        for _, plr in ipairs(Players:GetPlayers()) do
            if plr ~= executor and teleportPlayer(plr) then count = count + 1 end
        end
        notify(executor, "Crumbs Admin", "Teleported " .. count .. " other players to " .. destPlayer.Name .. ".", 3)
        
    else
        local target = findPlayer(args[1])
        if target and teleportPlayer(target) then
            notify(executor, "Crumbs Admin", "Teleported " .. target.Name .. " to " .. destPlayer.Name .. ".", 3)
        end
    end
end

local function cmd_bring(executor, args)
    if not args[1] then return end
    
    if not executor.Character or not executor.Character:FindFirstChild("HumanoidRootPart") then
        notify(executor, "Crumbs Admin", "You don't have a valid character.", 3)
        return
    end
    
    local myPos = executor.Character.HumanoidRootPart.CFrame * CFrame.new(0, 0, -5)
    
    local function bringPlayer(player)
        if not player.Character or not player.Character:FindFirstChild("HumanoidRootPart") then return false end
        player.Character.HumanoidRootPart.CFrame = myPos
        return true
    end
    
    if args[1]:lower() == "all" then
        local count = 0
        for _, plr in ipairs(Players:GetPlayers()) do
            if bringPlayer(plr) then count = count + 1 end
        end
        notify(executor, "Crumbs Admin", "Brought " .. count .. " players to you.", 3)
        
    elseif args[1]:lower() == "others" then
        local count = 0
        for _, plr in ipairs(Players:GetPlayers()) do
            if plr ~= executor and bringPlayer(plr) then count = count + 1 end
        end
        notify(executor, "Crumbs Admin", "Brought " .. count .. " other players to you.", 3)
        
    else
        local target = findPlayer(args[1])
        if target and bringPlayer(target) then
            notify(executor, "Crumbs Admin", "Brought " .. target.Name .. " to you.", 3)
        end
    end
end

local function cmd_removehats(executor, args)
    if not args[1] then return end
    
    local function removePlayerHats(player)
        if not player.Character then return 0 end
        local count = 0
        for _, descendant in ipairs(player.Character:GetDescendants()) do
            if descendant:IsA("Accessory") then
                descendant:Destroy()
                count = count + 1
            end
        end
        return count
    end
    
    if args[1]:lower() == "all" then
        local total = 0
        for _, plr in ipairs(Players:GetPlayers()) do
            total = total + removePlayerHats(plr)
        end
        notify(executor, "Crumbs Admin", "Removed " .. total .. " accessories from all players.", 3)
        
    elseif args[1]:lower() == "others" then
        local total = 0
        for _, plr in ipairs(Players:GetPlayers()) do
            if plr ~= executor then
                total = total + removePlayerHats(plr)
            end
        end
        notify(executor, "Crumbs Admin", "Removed " .. total .. " accessories from other players.", 3)
        
    else
        local target = findPlayer(args[1])
        if target then
            local count = removePlayerHats(target)
            notify(executor, "Crumbs Admin", "Removed " .. count .. " accessories from " .. target.Name .. ".", 3)
        end
    end
end

local function cmd_removearms(executor, args)
    if not args[1] then return end
    
    local armNames = {
        "Left Arm", "Right Arm", "LeftHand", "RightHand",
        "LeftLowerArm", "RightLowerArm", "LeftUpperArm", "RightUpperArm"
    }
    
    local function removePlayerArms(player)
        if not player.Character then return 0 end
        local count = 0
        for _, name in ipairs(armNames) do
            local part = player.Character:FindFirstChild(name)
            if part and part:IsA("BasePart") then
                part:Destroy()
                count = count + 1
            end
        end
        return count
    end
    
    if args[1]:lower() == "all" then
        local total = 0
        for _, plr in ipairs(Players:GetPlayers()) do
            total = total + removePlayerArms(plr)
        end
        notify(executor, "Crumbs Admin", "Removed " .. total .. " arms from all players.", 3)
        
    elseif args[1]:lower() == "others" then
        local total = 0
        for _, plr in ipairs(Players:GetPlayers()) do
            if plr ~= executor then
                total = total + removePlayerArms(plr)
            end
        end
        notify(executor, "Crumbs Admin", "Removed " .. total .. " arms from other players.", 3)
        
    else
        local target = findPlayer(args[1])
        if target then
            local count = removePlayerArms(target)
            notify(executor, "Crumbs Admin", "Removed " .. count .. " arms from " .. target.Name .. ".", 3)
        end
    end
end

local function cmd_removelegs(executor, args)
    if not args[1] then return end
    
    local legNames = {
        "Left Leg", "Right Leg", "LeftFoot", "RightFoot",
        "LeftLowerLeg", "RightLowerLeg", "LeftUpperLeg", "RightUpperLeg"
    }
    
    local function removePlayerLegs(player)
        if not player.Character then return 0 end
        local count = 0
        for _, name in ipairs(legNames) do
            local part = player.Character:FindFirstChild(name)
            if part and part:IsA("BasePart") then
                part:Destroy()
                count = count + 1
            end
        end
        return count
    end
    
    if args[1]:lower() == "all" then
        local total = 0
        for _, plr in ipairs(Players:GetPlayers()) do
            total = total + removePlayerLegs(plr)
        end
        notify(executor, "Crumbs Admin", "Removed " .. total .. " legs from all players.", 3)
        
    elseif args[1]:lower() == "others" then
        local total = 0
        for _, plr in ipairs(Players:GetPlayers()) do
            if plr ~= executor then
                total = total + removePlayerLegs(plr)
            end
        end
        notify(executor, "Crumbs Admin", "Removed " .. total .. " legs from other players.", 3)
        
    else
        local target = findPlayer(args[1])
        if target then
            local count = removePlayerLegs(target)
            notify(executor, "Crumbs Admin", "Removed " .. count .. " legs from " .. target.Name .. ".", 3)
        end
    end
end

local function cmd_invisible(executor, args)
    if not args[1] then return end
    
    local function makeInvisible(player)
        if not player.Character then return false end
        for _, part in ipairs(getPlayerParts(player)) do
            part.Transparency = 1
            for _, child in ipairs(part:GetChildren()) do
                if child:IsA("Decal") or child:IsA("Texture") then
                    child.Transparency = 1
                end
            end
        end
        return true
    end
    
    if args[1]:lower() == "all" then
        local count = 0
        for _, plr in ipairs(Players:GetPlayers()) do
            if makeInvisible(plr) then count = count + 1 end
        end
        notify(executor, "Crumbs Admin", "Made " .. count .. " players invisible.", 3)
        
    elseif args[1]:lower() == "others" then
        local count = 0
        for _, plr in ipairs(Players:GetPlayers()) do
            if plr ~= executor and makeInvisible(plr) then count = count + 1 end
        end
        notify(executor, "Crumbs Admin", "Made " .. count .. " other players invisible.", 3)
        
    else
        local target = findPlayer(args[1])
        if target and makeInvisible(target) then
            notify(executor, "Crumbs Admin", "Made " .. target.Name .. " invisible.", 3)
        end
    end
end

local function cmd_visible(executor, args)
    if not args[1] then return end
    
    local function makeVisible(player)
        if not player.Character then return false end
        for _, part in ipairs(getPlayerParts(player)) do
            part.Transparency = 0
            for _, child in ipairs(part:GetChildren()) do
                if child:IsA("Decal") or child:IsA("Texture") then
                    child.Transparency = 0
                end
            end
        end
        return true
    end
    
    if args[1]:lower() == "all" then
        local count = 0
        for _, plr in ipairs(Players:GetPlayers()) do
            if makeVisible(plr) then count = count + 1 end
        end
        notify(executor, "Crumbs Admin", "Made " .. count .. " players visible.", 3)
        
    elseif args[1]:lower() == "others" then
        local count = 0
        for _, plr in ipairs(Players:GetPlayers()) do
            if plr ~= executor and makeVisible(plr) then count = count + 1 end
        end
        notify(executor, "Crumbs Admin", "Made " .. count .. " other players visible.", 3)
        
    else
        local target = findPlayer(args[1])
        if target and makeVisible(target) then
            notify(executor, "Crumbs Admin", "Made " .. target.Name .. " visible.", 3)
        end
    end
end

local function cmd_loopkill(executor, args)
    if not args[1] then return end
    
    local function setupLoopKill(target)
        if activeLoopKills[target.UserId] then return end
        
        activeLoopKills[target.UserId] = true
        
        local function killCharacter()
            if activeLoopKills[target.UserId] and target.Character then
                local head = getPlayerHead(target)
                if head then head:Destroy() end
            end
        end
        
        killCharacter()
        
        local connection
        connection = target.CharacterAdded:Connect(function()
            task.wait(0.1)
            if activeLoopKills[target.UserId] then
                local head = getPlayerHead(target)
                if head then head:Destroy() end
            end
        end)
        
        activeLoopKills[target.UserId .. "_conn"] = connection
        
        task.spawn(function()
            while activeLoopKills[target.UserId] do
                task.wait(0.5)
                if target.Character then
                    local head = getPlayerHead(target)
                    if head then head:Destroy() end
                end
            end
        end)
    end
    
    if args[1]:lower() == "all" then
        for _, plr in ipairs(Players:GetPlayers()) do
            setupLoopKill(plr)
        end
        notify(executor, "Crumbs Admin", "Loop kill started for ALL players.", 3)
        
    elseif args[1]:lower() == "others" then
        for _, plr in ipairs(Players:GetPlayers()) do
            if plr ~= executor then
                setupLoopKill(plr)
            end
        end
        notify(executor, "Crumbs Admin", "Loop kill started for OTHER players.", 3)
        
    elseif args[1]:lower() == "random" then
        local eligible = {}
        for _, plr in ipairs(Players:GetPlayers()) do
            table.insert(eligible, plr)
        end
        if #eligible > 0 then
            local target = eligible[math.random(1, #eligible)]
            setupLoopKill(target)
            notify(executor, "Crumbs Admin", "Loop kill started for random player: " .. target.Name, 3)
        end
        
    else
        local target = findPlayer(args[1])
        if target then
            setupLoopKill(target)
            notify(executor, "Crumbs Admin", "Loop kill started for " .. target.Name .. ".", 3)
        end
    end
end

local function cmd_unloopkill(executor, args)
    if not args[1] then return end
    
    local function stopLoopKill(target)
        if activeLoopKills[target.UserId] then
            activeLoopKills[target.UserId] = nil
            if activeLoopKills[target.UserId .. "_conn"] then
                activeLoopKills[target.UserId .. "_conn"]:Disconnect()
                activeLoopKills[target.UserId .. "_conn"] = nil
            end
            return true
        end
        return false
    end
    
    if args[1]:lower() == "all" then
        local count = 0
        for _, plr in ipairs(Players:GetPlayers()) do
            if stopLoopKill(plr) then count = count + 1 end
        end
        notify(executor, "Crumbs Admin", "Stopped loop kill for " .. count .. " players.", 3)
        
    elseif args[1]:lower() == "others" then
        local count = 0
        for _, plr in ipairs(Players:GetPlayers()) do
            if plr ~= executor and stopLoopKill(plr) then count = count + 1 end
        end
        notify(executor, "Crumbs Admin", "Stopped loop kill for " .. count .. " other players.", 3)
        
    else
        local target = findPlayer(args[1])
        if target and stopLoopKill(target) then
            notify(executor, "Crumbs Admin", "Stopped loop kill for " .. target.Name .. ".", 3)
        end
    end
end

local function cmd_looppunish(executor, args)
    if not args[1] then return end
    
    local target = findPlayer(args[1])
    if not target then
        notify(executor, "Crumbs Admin", "Player not found.", 3)
        return
    end
    
    if activePunishments[target.UserId] then
        notify(executor, "Crumbs Admin", target.Name .. " is already being loop punished.", 3)
        return
    end
    
    activePunishments[target.UserId] = true
    
    local function punishCharacter()
        if activePunishments[target.UserId] and target.Character then
            target.Character:Destroy()
        end
    end
    
    punishCharacter()
    
    local connection
    connection = target.CharacterAdded:Connect(function()
        task.wait(0.1)
        if activePunishments[target.UserId] then
            target.Character:Destroy()
        end
    end)
    
    activePunishments[target.UserId .. "_conn"] = connection
    
    task.spawn(function()
        while activePunishments[target.UserId] do
            task.wait(0.5)
            if target.Character then
                target.Character:Destroy()
            end
        end
    end)
    
    notify(executor, "Crumbs Admin", "Loop punish started for " .. target.Name .. ".", 3)
end

local function cmd_unlooppunish(executor, args)
    if not args[1] then return end
    
    local target = findPlayer(args[1])
    if not target then
        notify(executor, "Crumbs Admin", "Player not found.", 3)
        return
    end
    
    if not activePunishments[target.UserId] then
        notify(executor, "Crumbs Admin", target.Name .. " is not being loop punished.", 3)
        return
    end
    
    activePunishments[target.UserId] = nil
    if activePunishments[target.UserId .. "_conn"] then
        activePunishments[target.UserId .. "_conn"]:Disconnect()
        activePunishments[target.UserId .. "_conn"] = nil
    end
    
    notify(executor, "Crumbs Admin", "Loop punish stopped for " .. target.Name .. ".", 3)
end

local function cmd_kick(executor, args)
    if not args[1] then return end
    
    local targetName = args[1]
    local reason = #args > 1 and table.concat(args, " ", 2) or "No reason provided"
    
    local function processKick(player)
        if player then
            local kickMessage = string.format("You have been kicked by %s\nReason: %s", executor.Name, reason)
            notifyAll("Crumbs Admin", string.format("%s was kicked by %s\nReason: %s", player.Name, executor.Name, reason), 5)
            player:Kick(kickMessage)
        end
    end
    
    if targetName:lower() == "all" then
        local count = 0
        for _, plr in ipairs(Players:GetPlayers()) do
            if plr ~= executor then
                processKick(plr)
                count = count + 1
                task.wait(0.1)
            end
        end
        notify(executor, "Crumbs Admin", "Kicked " .. count .. " players.", 3)
        
    elseif targetName:lower() == "others" then
        local count = 0
        for _, plr in ipairs(Players:GetPlayers()) do
            if plr ~= executor then
                processKick(plr)
                count = count + 1
                task.wait(0.1)
            end
        end
        notify(executor, "Crumbs Admin", "Kicked " .. count .. " other players.", 3)
        
    elseif targetName:lower() == "random" then
        local eligible = {}
        for _, plr in ipairs(Players:GetPlayers()) do
            if plr ~= executor then
                table.insert(eligible, plr)
            end
        end
        if #eligible > 0 then
            local target = eligible[math.random(1, #eligible)]
            processKick(target)
            notify(executor, "Crumbs Admin", "Kicked random player: " .. target.Name, 3)
        end
        
    else
        local target = findPlayer(targetName)
        if target then
            processKick(target)
        end
    end
end

local function cmd_ban(executor, args)
    if not args[1] then return end
    
    local targetName = args[1]
    local duration = nil
    local reason = ""
    
    if args[2] and tonumber(args[2]) then
        duration = tonumber(args[2])
        reason = #args > 2 and table.concat(args, " ", 3) or "No reason provided"
    else
        reason = #args > 1 and table.concat(args, " ", 2) or "No reason provided"
    end
    
    local function processBan(player)
        if player then
            local banData = {
                reason = reason,
                admin = executor.Name,
                timestamp = os.time(),
                expiry = duration and (os.time() + duration) or nil
            }
            
            bannedPlayers[player.UserId] = banData
            
            local durationText = duration and (" for " .. duration .. " seconds") or " permanently"
            local banMessage = string.format("You have been banned by %s%s\nReason: %s", executor.Name, durationText, reason)
            
            notifyAll("Crumbs Admin", string.format("%s was banned by %s%s\nReason: %s", player.Name, executor.Name, durationText, reason), 5)
            
            if not activePunishments[player.UserId] then
                activePunishments[player.UserId] = true
                
                local connection
                connection = player.CharacterAdded:Connect(function()
                    task.wait(0.1)
                    if activePunishments[player.UserId] then
                        player.Character:Destroy()
                    end
                end)
                
                activePunishments[player.UserId .. "_conn"] = connection
                
                task.spawn(function()
                    while activePunishments[player.UserId] do
                        task.wait(0.5)
                        if player.Character then
                            player.Character:Destroy()
                        end
                    end
                end)
            end
            
            player:Kick(banMessage)
        end
    end
    
    if targetName:lower() == "all" then
        local count = 0
        for _, plr in ipairs(Players:GetPlayers()) do
            if plr ~= executor then
                processBan(plr)
                count = count + 1
                task.wait(0.1)
            end
        end
        notify(executor, "Crumbs Admin", "Banned " .. count .. " players.", 3)
        
    elseif targetName:lower() == "others" then
        local count = 0
        for _, plr in ipairs(Players:GetPlayers()) do
            if plr ~= executor then
                processBan(plr)
                count = count + 1
                task.wait(0.1)
            end
        end
        notify(executor, "Crumbs Admin", "Banned " .. count .. " other players.", 3)
        
    elseif targetName:lower() == "random" then
        local eligible = {}
        for _, plr in ipairs(Players:GetPlayers()) do
            if plr ~= executor then
                table.insert(eligible, plr)
            end
        end
        if #eligible > 0 then
            local target = eligible[math.random(1, #eligible)]
            processBan(target)
            notify(executor, "Crumbs Admin", "Banned random player: " .. target.Name, 3)
        end
        
    else
        local target = findPlayer(targetName)
        if target then
            processBan(target)
        end
    end
end

local function cmd_unban(executor, args)
    if not args[1] then return end
    
    local targetName = args[1]
    
    if tonumber(targetName) then
        local userId = tonumber(targetName)
        if bannedPlayers[userId] then
            bannedPlayers[userId] = nil
            if activePunishments[userId] then
                activePunishments[userId] = nil
                if activePunishments[userId .. "_conn"] then
                    activePunishments[userId .. "_conn"]:Disconnect()
                    activePunishments[userId .. "_conn"] = nil
                end
            end
            notify(executor, "Crumbs Admin", "Unbanned user ID: " .. userId, 3)
            notifyAll("Crumbs Admin", "User " .. userId .. " was unbanned by " .. executor.Name, 5)
            return
        end
    end
    
    local target = findPlayer(targetName)
    if target and bannedPlayers[target.UserId] then
        bannedPlayers[target.UserId] = nil
        if activePunishments[target.UserId] then
            activePunishments[target.UserId] = nil
            if activePunishments[target.UserId .. "_conn"] then
                activePunishments[target.UserId .. "_conn"]:Disconnect()
                activePunishments[target.UserId .. "_conn"] = nil
            end
        end
        notify(executor, "Crumbs Admin", "Unbanned " .. target.Name .. ".", 3)
        notifyAll("Crumbs Admin", target.Name .. " was unbanned by " .. executor.Name, 5)
    else
        notify(executor, "Crumbs Admin", "Player not found or not banned.", 3)
    end
end

local function cmd_clear(executor)
    local count = 0
    for _, obj in ipairs(workspace:GetDescendants()) do
        if obj:IsA("BasePart") and not obj:IsDescendantOf(Players) and obj.Name ~= "Baseplate" then
            obj:Destroy()
            count = count + 1
        end
    end
    notify(executor, "Crumbs Admin", "Cleared " .. count .. " parts from workspace.", 3)
end

local function cmd_rank(executor, args)
    if getPlayerRank(executor) < 4 then
        notify(executor, "Crumbs Admin", "You need to be Manager (rank 4) to use this command.", 3)
        return
    end
    
    if not args[1] or not args[2] then
        notify(executor, "Crumbs Admin", "Usage: ,rank player <rank name/number>", 3)
        return
    end
    
    local target = findPlayer(args[1])
    if not target then
        notify(executor, "Crumbs Admin", "Player not found.", 3)
        return
    end
    
    local rankInput = args[2]:lower()
    local newRank = 0
    
    if tonumber(rankInput) then
        newRank = tonumber(rankInput)
        if newRank < 0 or newRank > 4 then
            notify(executor, "Crumbs Admin", "Rank must be between 0 and 4.", 3)
            return
        end
    else
        if rankInput == "customer" then
            newRank = 1
        elseif rankInput == "cashier" then
            newRank = 2
        elseif rankInput == "baker" then
            newRank = 3
        elseif rankInput == "manager" then
            newRank = 4
        else
            notify(executor, "Crumbs Admin", "Invalid rank name. Use: customer, cashier, baker, manager", 3)
            return
        end
    end
    
    tempRanks[target.UserId] = newRank
    
    local rankName = RANK_NAMES[newRank] or "User"
    notify(executor, "Crumbs Admin", "Set " .. target.Name .. "'s rank to " .. rankName .. " (" .. newRank .. ")", 3)
    notify(target, "Crumbs Admin", "Your rank has been set to " .. rankName .. " (" .. newRank .. ")", 3)
end

local function cmd_eject(executor, args)
    if getPlayerRank(executor) < 4 then
        notify(executor, "Crumbs Admin", "You need to be Manager (rank 4) to use this command.", 3)
        return
    end
    
    notifyAll("Crumbs Admin", "Crumbs Admin is shutting down...", 3)
    task.wait(1)
    
    for userId, _ in pairs(activePunishments) do
        activePunishments[userId] = nil
        if activePunishments[userId .. "_conn"] then
            activePunishments[userId .. "_conn"]:Disconnect()
        end
    end
    
    for userId, _ in pairs(activeLoopKills) do
        activeLoopKills[userId] = nil
        if activeLoopKills[userId .. "_conn"] then
            activeLoopKills[userId .. "_conn"]:Disconnect()
        end
    end
    
    local script = script
    script:Destroy()
end

local COMMANDS = {
    rj = {func = cmd_rj, rank = 0, aliases = {"rejoin", "reconnect"}, minArgs = 0},
    
    punish = {func = cmd_punish, rank = 1, aliases = {"p", "deletechar", "delchar"}, minArgs = 1},
    kill = {func = cmd_kill, rank = 1, aliases = {"k", "slay", "execute"}, minArgs = 1},
    freeze = {func = cmd_freeze, rank = 1, aliases = {"fz", "anchor", "lock"}, minArgs = 1},
    unfreeze = {func = cmd_unfreeze, rank = 1, aliases = {"ufz", "unanchor", "unlock"}, minArgs = 1},
    noclip = {func = cmd_noclip, rank = 1, aliases = {"nc", "ghost", "phase"}, minArgs = 1},
    clip = {func = cmd_clip, rank = 1, aliases = {"c", "collide", "solid"}, minArgs = 1},
    void = {func = cmd_void, rank = 1, aliases = {"v", "underworld"}, minArgs = 1},
    skydive = {func = cmd_skydive, rank = 1, aliases = {"sky", "fly", "launch"}, minArgs = 2},
    tp = {func = cmd_tp, rank = 1, aliases = {"teleport", "goto"}, minArgs = 2},
    bring = {func = cmd_bring, rank = 1, aliases = {"b", "pull", "fetch"}, minArgs = 1},
    removehats = {func = cmd_removehats, rank = 1, aliases = {"removeacc", "deletehats", "rh"}, minArgs = 1},
    removearms = {func = cmd_removearms, rank = 1, aliases = {"rarms", "deletearms"}, minArgs = 1},
    removelegs = {func = cmd_removelegs, rank = 1, aliases = {"rlegs", "deletelegs"}, minArgs = 1},
    invisible = {func = cmd_invisible, rank = 1, aliases = {"inv", "hide"}, minArgs = 1},
    visible = {func = cmd_visible, rank = 1, aliases = {"vis", "show"}, minArgs = 1},
    
    loopkill = {func = cmd_loopkill, rank = 2, aliases = {"lk", "repeatingkill", "autokill"}, minArgs = 1},
    unloopkill = {func = cmd_unloopkill, rank = 2, aliases = {"unlk", "stopkill", "endkill"}, minArgs = 1},
    looppunish = {func = cmd_looppunish, rank = 2, aliases = {"lp", "loopp", "repeatingpunish"}, minArgs = 1},
    unlooppunish = {func = cmd_unlooppunish, rank = 2, aliases = {"unlp", "stoppunish", "endpunish"}, minArgs = 1},
    
    kick = {func = cmd_kick, rank = 3, aliases = {"kck"}, minArgs = 1},
    ban = {func = cmd_ban, rank = 3, aliases = {"b", "permban"}, minArgs = 1},
    unban = {func = cmd_unban, rank = 3, aliases = {"ub", "pardon"}, minArgs = 1},
    clear = {func = cmd_clear, rank = 3, aliases = {"clean", "wipe"}, minArgs = 0},
    eject = {func = cmd_eject, rank = 3, aliases = {"unload", "exit", "quit", "disable"}, minArgs = 0},
    
    rank = {func = cmd_rank, rank = 4, aliases = {"setrank"}, minArgs = 2},
}

local ALIAS_MAP = {}
for cmdName, cmdData in pairs(COMMANDS) do
    ALIAS_MAP[cmdName] = cmdName
    for _, alias in ipairs(cmdData.aliases) do
        ALIAS_MAP[alias] = cmdName
    end
end

local function parseCommand(input)
    input = input:gsub("^" .. PREFIX, ""):gsub("^%s+", ""):gsub("%s+$", "")
    if input == "" then return nil end
    
    local parts = {}
    for part in input:gmatch("%S+") do
        table.insert(parts, part)
    end
    
    local cmd = parts[1]:lower()
    table.remove(parts, 1)
    
    return cmd, parts
end

remoteEvent.OnServerEvent:Connect(function(player, commandText)
    local cmd, args = parseCommand(commandText)
    if not cmd then return end
    
    if cmd == "cmds" or cmd == "commands" or cmd == "help" or cmd == "menu" then
        createDashboard(player, "Commands")
        return
    end
    
    local realCmd = ALIAS_MAP[cmd]
    if not realCmd then
        notify(player, "Crumbs Admin", "Unknown command: " .. cmd, 3)
        return
    end
    
    local cmdData = COMMANDS[realCmd]
    
    local playerRank = getPlayerRank(player)
    if playerRank < cmdData.rank then
        notify(player, "Crumbs Admin", "You need rank " .. RANK_NAMES[cmdData.rank] .. " (" .. cmdData.rank .. ") to use this command. Your rank: " .. RANK_NAMES[playerRank] .. " (" .. playerRank .. ")", 3)
        return
    end
    
    if #args < cmdData.minArgs then
        notify(player, "Crumbs Admin", "Usage: " .. PREFIX .. realCmd .. " <required args>", 3)
        return
    end
    
    local success, err = pcall(cmdData.func, player, args)
    if not success then
        warn("Command error:", err)
        notify(player, "Crumbs Admin", "Command execution failed.", 3)
    end
end)

Players.PlayerAdded:Connect(function(player)
    task.wait(1)
    createCmdBar(player)
    notify(player, "Crumbs Admin", "Welcome " .. player.Name .. "! Your rank: " .. RANK_NAMES[getPlayerRank(player)] .. " (" .. getPlayerRank(player) .. ")\nType " .. PREFIX .. "cmds for help", 5)
    
    if bannedPlayers[player.UserId] then
        local banData = bannedPlayers[player.UserId]
        if banData.expiry and os.time() > banData.expiry then
            bannedPlayers[player.UserId] = nil
        else
            task.wait(0.5)
            local durationText = banData.expiry and "temporary" or "permanent"
            local banMessage = string.format("You are %s banned\nReason: %s\nBanned by: %s", durationText, banData.reason, banData.admin)
            player:Kick(banMessage)
        end
    end
end)

Players.PlayerRemoving:Connect(function(player)
    if activePunishments[player.UserId] then
        activePunishments[player.UserId] = nil
        if activePunishments[player.UserId .. "_conn"] then
            activePunishments[player.UserId .. "_conn"]:Disconnect()
        end
    end
    
    if activeLoopKills[player.UserId] then
        activeLoopKills[player.UserId] = nil
        if activeLoopKills[player.UserId .. "_conn"] then
            activeLoopKills[player.UserId .. "_conn"]:Disconnect()
        end
    end
    
    if notificationStacks[player] then
        notificationStacks[player] = nil
    end
    
    if playerGuis[player] then
        playerGuis[player] = nil
    end
end)

local function protectManagers()
    for _, player in ipairs(Players:GetPlayers()) do
        if getPlayerRank(player) >= 4 and player.Character then
            for _, part in ipairs(getPlayerParts(player)) do
                part.CanCollide = true
                part.Anchored = false
            end
        end
    end
end

RunService.Heartbeat:Connect(protectManagers)

notify(player, "Crumbs Admin", "Crumbs Admin (SS) has loaded in!", 3)
