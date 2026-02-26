-- Crumbs Admin - ULTIMATE UNIVERSAL VERSION
-- Works in: Console, ServerScriptService, anywhere!

-- Detect execution environment
local isServer = not game:GetService("RunService"):IsClient()
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local TeleportService = game:GetService("TeleportService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local TextChatService = game:GetService("TextChatService")
local StarterGui = game:GetService("StarterGui")
local CoreGui = game:GetService("CoreGui")

-- Global storage for persistence
_G.CrumbsAdmin = _G.CrumbsAdmin or {}
local admin = _G.CrumbsAdmin

-- Configuration
admin.config = admin.config or {
    prefix = ",",
    colors = {
        CHOCOLATE = Color3.fromRGB(74, 49, 28),
        MILK_CHOCOLATE = Color3.fromRGB(111, 78, 55),
        LIGHT_CHOCOLATE = Color3.fromRGB(139, 90, 43),
        COOKIE_DOUGH = Color3.fromRGB(210, 180, 140),
        WHITE = Color3.fromRGB(255, 255, 255),
        OFF_WHITE = Color3.fromRGB(240, 240, 240)
    }
}

-- Data storage
admin.ranks = admin.ranks or {}
admin.tempRanks = admin.tempRanks or {}
admin.muted = admin.muted or {}
admin.frozen = admin.frozen or {}
admin.invisible = admin.invisible or {}
admin.loopKill = admin.loopKill or {}
admin.loopPunish = admin.loopPunish or {}
admin.godMode = admin.godMode or {}
admin.flyMode = admin.flyMode or {}
admin.savedLocations = admin.savedLocations or {}
admin.bannedPlayers = admin.bannedPlayers or {}
admin.notificationStack = admin.notificationStack or {}
admin.currentDashboard = nil
admin.running = true

-- Rank definitions
admin.rankNames = {
    [0] = "User",
    [1] = "Customer",
    [2] = "Cashier", 
    [3] = "Baker",
    [4] = "Manager"
}

-- Auto-whitelist (modify as needed)
admin.autoWhitelist = admin.autoWhitelist or {
    ["xXRblxGamerRblxXx"] = 4
}

-- Colors for GUI
local CHOCOLATE = admin.config.colors.CHOCOLATE
local MILK_CHOCOLATE = admin.config.colors.MILK_CHOCOLATE
local LIGHT_CHOCOLATE = admin.config.colors.LIGHT_CHOCOLATE
local COOKIE_DOUGH = admin.config.colors.COOKIE_DOUGH
local WHITE = admin.config.colors.WHITE
local OFF_WHITE = admin.config.colors.OFF_WHITE
local PREFIX = admin.config.prefix

-- Helper Functions
local function getRank(player)
    if not player then return 0 end
    local userId = player.UserId
    if admin.tempRanks[userId] then return admin.tempRanks[userId] end
    if admin.ranks[userId] then return admin.ranks[userId] end
    if admin.autoWhitelist[player.Name] then return admin.autoWhitelist[player.Name] end
    return 0
end

local function getPlayerHead(player)
    if not player or not player.Character then return nil end
    return player.Character:FindFirstChild("Head") or player.Character:FindFirstChild("HumanoidRootPart")
end

local function getPlayerHumanoid(player)
    if not player or not player.Character then return nil end
    return player.Character:FindFirstChildOfClass("Humanoid")
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

local function getGuiParent()
    if isServer then
        -- Server-side: use PlayerGui
        local player = Players.LocalPlayer
        if player then
            return player:FindFirstChild("PlayerGui") or player:WaitForChild("PlayerGui")
        end
    else
        -- Console/client-side: try CoreGui first
        local success, result = pcall(function()
            if CoreGui then return CoreGui end
        end)
        if success and result then return result end
        
        -- Fallback to PlayerGui
        local player = Players.LocalPlayer
        if player then
            return player:FindFirstChild("PlayerGui") or player:WaitForChild("PlayerGui")
        end
    end
    return Instance.new("ScreenGui") -- Ultimate fallback
end

-- Notification system
local notificationCooldown = {}

local function notify(player, title, message, duration)
    if not player then return end
    
    local key = title .. message
    if notificationCooldown[key] and tick() - notificationCooldown[key] < 1 then
        return
    end
    notificationCooldown[key] = tick()
    
    duration = duration or 4
    
    -- If we're on server but want to notify a specific player, we need RemoteEvent
    if isServer then
        -- Try to use RemoteEvent if available
        local remote = ReplicatedStorage:FindFirstChild("CrumbsAdminNotification")
        if remote then
            remote:FireClient(player, title, message, duration)
            return
        end
    end
    
    -- Direct client-side notification
    coroutine.wrap(function()
        local PlayerGui = player:FindFirstChild("PlayerGui")
        if not PlayerGui then return end
        
        -- Calculate text size for dynamic height
        local TextService = game:GetService("TextService")
        local frameWidth = 280
        local messagePadding = 20
        local textWidth = frameWidth - messagePadding
        
        local textSize = TextService:GetTextSize(
            message or "",
            12,
            Enum.Font.Gotham,
            Vector2.new(textWidth, 9999)
        )
        
        local titleAreaHeight = 38
        local verticalPadding = 10
        local dynamicHeight = math.max(titleAreaHeight + textSize.Y + verticalPadding, 72)
        
        -- Clean up dead notifications
        for i = #admin.notificationStack, 1, -1 do
            if not admin.notificationStack[i] or not admin.notificationStack[i].gui or not admin.notificationStack[i].gui.Parent then
                table.remove(admin.notificationStack, i)
            end
        end

        -- Calculate position
        local yOffset = 10
        for _, entry in ipairs(admin.notificationStack) do
            yOffset = yOffset + entry.height + 6
        end
        
        -- Create notification GUI
        local ScreenGui = Instance.new("ScreenGui")
        ScreenGui.Name = "CrumbsNotification_" .. tick()
        ScreenGui.ResetOnSpawn = false
        ScreenGui.Parent = PlayerGui
        ScreenGui.IgnoreGuiInset = true
        ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
        
        local NotifFrame = Instance.new("Frame")
        NotifFrame.Name = "NotificationFrame"
        NotifFrame.Size = UDim2.new(0, frameWidth, 0, dynamicHeight)
        NotifFrame.Position = UDim2.new(1, -290, 1, -(yOffset + dynamicHeight))
        NotifFrame.BackgroundColor3 = CHOCOLATE
        NotifFrame.BackgroundTransparency = 1
        NotifFrame.BorderSizePixel = 0
        NotifFrame.Parent = ScreenGui
        
        local Corner = Instance.new("UICorner")
        Corner.CornerRadius = UDim.new(0, 15)
        Corner.Parent = NotifFrame
        
        local TitleLabel = Instance.new("TextLabel")
        TitleLabel.Name = "Title"
        TitleLabel.Text = title or "Crumbs Admin"
        TitleLabel.Size = UDim2.new(1, -45, 0, 18)
        TitleLabel.Position = UDim2.new(0, 10, 0, 6)
        TitleLabel.TextColor3 = COOKIE_DOUGH
        TitleLabel.TextTransparency = 1
        TitleLabel.BackgroundTransparency = 1
        TitleLabel.Font = Enum.Font.GothamBold
        TitleLabel.TextSize = 13
        TitleLabel.TextXAlignment = Enum.TextXAlignment.Left
        TitleLabel.TextYAlignment = Enum.TextYAlignment.Top
        TitleLabel.Parent = NotifFrame
        
        local WhiteLine = Instance.new("Frame")
        WhiteLine.Name = "WhiteLine"
        WhiteLine.Size = UDim2.new(1, -18, 0, 1)
        WhiteLine.Position = UDim2.new(0, 9, 0, 27)
        WhiteLine.BackgroundColor3 = MILK_CHOCOLATE
        WhiteLine.BackgroundTransparency = 1
        WhiteLine.BorderSizePixel = 0
        WhiteLine.Parent = NotifFrame
        
        local CloseButton = Instance.new("TextButton")
        CloseButton.Name = "CloseButton"
        CloseButton.Size = UDim2.new(0, 24, 0, 24)
        CloseButton.Position = UDim2.new(1, -30, 0, 5)
        CloseButton.Text = "X"
        CloseButton.TextColor3 = COOKIE_DOUGH
        CloseButton.TextTransparency = 1
        CloseButton.BackgroundTransparency = 1
        CloseButton.BorderSizePixel = 0
        CloseButton.Font = Enum.Font.GothamBold
        CloseButton.TextSize = 15
        CloseButton.Parent = NotifFrame
        
        local MessageLabel = Instance.new("TextLabel")
        MessageLabel.Name = "Message"
        MessageLabel.Text = message or ""
        MessageLabel.Size = UDim2.new(1, -20, 1, -38)
        MessageLabel.Position = UDim2.new(0, 10, 0, 32)
        MessageLabel.TextColor3 = OFF_WHITE
        MessageLabel.TextTransparency = 1
        MessageLabel.BackgroundTransparency = 1
        MessageLabel.Font = Enum.Font.Gotham
        MessageLabel.TextSize = 12
        MessageLabel.TextXAlignment = Enum.TextXAlignment.Left
        MessageLabel.TextYAlignment = Enum.TextYAlignment.Top
        MessageLabel.TextWrapped = true
        MessageLabel.Parent = NotifFrame
        
        local stackEntry = {
            gui = ScreenGui,
            frame = NotifFrame,
            height = dynamicHeight,
            yOffset = yOffset
        }
        table.insert(admin.notificationStack, stackEntry)
        
        local closed = false
        
        local function restack()
            local runningOffset = 10
            for _, entry in ipairs(admin.notificationStack) do
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
            
            for i, entry in ipairs(admin.notificationStack) do
                if entry.gui == ScreenGui then
                    table.remove(admin.notificationStack, i)
                    break
                end
            end
            
            local fadeOut1 = TweenService:Create(NotifFrame, TweenInfo.new(0.4, Enum.EasingStyle.Sine), {BackgroundTransparency = 1})
            local fadeOut2 = TweenService:Create(TitleLabel, TweenInfo.new(0.4, Enum.EasingStyle.Sine), {TextTransparency = 1})
            local fadeOut3 = TweenService:Create(WhiteLine, TweenInfo.new(0.4, Enum.EasingStyle.Sine), {BackgroundTransparency = 1})
            local fadeOut4 = TweenService:Create(CloseButton, TweenInfo.new(0.4, Enum.EasingStyle.Sine), {TextTransparency = 1})
            local fadeOut5 = TweenService:Create(MessageLabel, TweenInfo.new(0.4, Enum.EasingStyle.Sine), {TextTransparency = 1})
            
            fadeOut1:Play()
            fadeOut2:Play()
            fadeOut3:Play()
            fadeOut4:Play()
            fadeOut5:Play()
            
            restack()
            
            fadeOut1.Completed:Connect(function()
                if ScreenGui and ScreenGui.Parent then
                    ScreenGui:Destroy()
                end
            end)
        end
        
        CloseButton.MouseButton1Click:Connect(closeNotif)
        
        -- Animate in
        local fadeIn1 = TweenService:Create(NotifFrame, TweenInfo.new(0.5, Enum.EasingStyle.Sine), {BackgroundTransparency = 0.05})
        local fadeIn2 = TweenService:Create(TitleLabel, TweenInfo.new(0.5, Enum.EasingStyle.Sine), {TextTransparency = 0})
        local fadeIn3 = TweenService:Create(WhiteLine, TweenInfo.new(0.5, Enum.EasingStyle.Sine), {BackgroundTransparency = 0.2})
        local fadeIn4 = TweenService:Create(CloseButton, TweenInfo.new(0.5, Enum.EasingStyle.Sine), {TextTransparency = 0})
        local fadeIn5 = TweenService:Create(MessageLabel, TweenInfo.new(0.5, Enum.EasingStyle.Sine), {TextTransparency = 0})
        
        fadeIn1:Play()
        fadeIn2:Play()
        fadeIn3:Play()
        fadeIn4:Play()
        fadeIn5:Play()
        
        task.wait(duration)
        closeNotif()
    end)()
end

local function notifyAll(title, message, duration)
    for _, player in ipairs(Players:GetPlayers()) do
        notify(player, title, message, duration)
    end
end

local function notifyStaff(title, message, duration)
    for _, player in ipairs(Players:GetPlayers()) do
        if getRank(player) >= 1 then
            notify(player, title, message, duration)
        end
    end
end

-- Dashboard
local function openDashboard(player, defaultTab)
    defaultTab = defaultTab or "Commands"
    
    local PlayerGui = player:FindFirstChild("PlayerGui")
    if not PlayerGui then return end
    
    -- Close existing dashboard
    if admin.currentDashboard and admin.currentDashboard.Parent then
        admin.currentDashboard:Destroy()
        admin.currentDashboard = nil
    end
    
    -- Create dashboard
    local dashboardGui = Instance.new("ScreenGui")
    dashboardGui.Name = "CrumbsDashboard"
    dashboardGui.ResetOnSpawn = false
    dashboardGui.Parent = PlayerGui
    dashboardGui.IgnoreGuiInset = true
    dashboardGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    admin.currentDashboard = dashboardGui
    
    local mainFrame = Instance.new("Frame")
    mainFrame.Name = "MainFrame"
    mainFrame.Size = UDim2.new(0, 750, 0, 420)
    mainFrame.Position = UDim2.new(0.5, -375, 0.5, -210)
    mainFrame.BackgroundColor3 = CHOCOLATE
    mainFrame.BackgroundTransparency = 0.05
    mainFrame.BorderSizePixel = 2
    mainFrame.BorderColor3 = LIGHT_CHOCOLATE
    mainFrame.Parent = dashboardGui
    
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
    commandsContent.BackgroundColor3 = MILK_CHOCOLATE
    commandsContent.BackgroundTransparency = 0
    commandsContent.BorderSizePixel = 0
    commandsContent.ScrollBarThickness = 6
    commandsContent.ScrollBarImageColor3 = COOKIE_DOUGH
    commandsContent.Visible = (defaultTab == "Commands")
    commandsContent.Parent = contentFrame
    
    local commandsLayout = Instance.new("UIListLayout")
    commandsLayout.Parent = commandsContent
    commandsLayout.SortOrder = Enum.SortOrder.LayoutOrder
    commandsLayout.Padding = UDim.new(0, 5)
    
    local commandsPadding = Instance.new("UIPadding")
    commandsPadding.Parent = commandsContent
    commandsPadding.PaddingTop = UDim.new(0, 5)
    commandsPadding.PaddingLeft = UDim.new(0, 5)
    commandsPadding.PaddingRight = UDim.new(0, 5)
    
    local creditsContent = Instance.new("ScrollingFrame")
    creditsContent.Name = "CreditsContent"
    creditsContent.Size = UDim2.new(1, 0, 1, 0)
    creditsContent.BackgroundColor3 = MILK_CHOCOLATE
    creditsContent.BackgroundTransparency = 1
    creditsContent.BorderSizePixel = 0
    creditsContent.ScrollBarThickness = 6
    creditsContent.ScrollBarImageColor3 = COOKIE_DOUGH
    creditsContent.Visible = (defaultTab == "Credits")
    creditsContent.Parent = contentFrame
    
    local creditsLayout = Instance.new("UIListLayout")
    creditsLayout.Parent = creditsContent
    creditsLayout.SortOrder = Enum.SortOrder.LayoutOrder
    creditsLayout.Padding = UDim.new(0, 10)
    creditsLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
    
    local creditsPadding = Instance.new("UIPadding")
    creditsPadding.Parent = creditsContent
    creditsPadding.PaddingTop = UDim.new(0, 10)
    creditsPadding.PaddingLeft = UDim.new(0, 10)
    creditsPadding.PaddingRight = UDim.new(0, 10)
    
    -- Credits content
    local creditTitle = Instance.new("TextLabel")
    creditTitle.Size = UDim2.new(1, -20, 0, 40)
    creditTitle.BackgroundTransparency = 1
    creditTitle.Text = "CREDITS"
    creditTitle.TextColor3 = COOKIE_DOUGH
    creditTitle.TextSize = 28
    creditTitle.Font = Enum.Font.GothamBold
    creditTitle.Parent = creditsContent
    
    local creditDivider = Instance.new("Frame")
    creditDivider.Size = UDim2.new(0.8, 0, 0, 2)
    creditDivider.Position = UDim2.new(0.1, 0, 0, 55)
    creditDivider.BackgroundColor3 = COOKIE_DOUGH
    creditDivider.BorderSizePixel = 0
    creditDivider.Parent = creditsContent
    
    local credits = {
        {role = "Developer", name = "Crumbs Admin Team", desc = "Universal admin system"},
        {role = "Version", name = "Crumbs Admin v4.0", desc = "Works in console OR server"},
        {role = "Features", name = "40+ Commands", desc = "Complete admin toolkit"},
        {role = "GUI", name = "Enhanced Interface", desc = "Smooth animations"},
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
    specialThanks.Text = "Crumbs Admin v4.0 - Universal Edition"
    specialThanks.TextColor3 = COOKIE_DOUGH
    specialThanks.TextSize = 14
    specialThanks.Font = Enum.Font.GothamBold
    specialThanks.TextWrapped = true
    specialThanks.Parent = creditsContent
    
    yPos = yPos + 60
    creditsContent.CanvasSize = UDim2.new(0, 0, 0, yPos + 20)
    
    -- Commands list
    local sampleCommands = {
        {name = "help", rank = 0, desc = "Open this menu"},
        {name = "players", rank = 0, desc = "List all players"},
        {name = "staff", rank = 0, desc = "List online staff"},
        {name = "rj", rank = 0, desc = "Rejoin server"},
        {name = "kill", rank = 1, desc = "Kill player"},
        {name = "punish", rank = 1, desc = "Delete character"},
        {name = "freeze", rank = 1, desc = "Freeze player"},
        {name = "noclip", rank = 1, desc = "Disable collision"},
        {name = "void", rank = 1, desc = "Send to void"},
        {name = "tp", rank = 1, desc = "Teleport player"},
        {name = "bring", rank = 1, desc = "Bring player"},
        {name = "invisible", rank = 1, desc = "Make invisible"},
        {name = "mute", rank = 1, desc = "Mute player"},
        {name = "loopkill", rank = 2, desc = "Repeatedly kill"},
        {name = "looppunish", rank = 2, desc = "Repeatedly punish"},
        {name = "god", rank = 2, desc = "God mode"},
        {name = "fly", rank = 2, desc = "Flight mode"},
        {name = "kick", rank = 3, desc = "Kick player"},
        {name = "ban", rank = 3, desc = "Ban player"},
        {name = "clear", rank = 3, desc = "Clear workspace"},
        {name = "announce", rank = 3, desc = "Make announcement"},
        {name = "rank", rank = 4, desc = "Set player rank"},
        {name = "save", rank = 4, desc = "Save location"},
        {name = "shutdown", rank = 4, desc = "Shutdown server"},
    }
    
    for counter, cmd in ipairs(sampleCommands) do
        local commandFrame = Instance.new("Frame")
        commandFrame.Name = "Command_" .. cmd.name
        commandFrame.Size = UDim2.new(1, 0, 0, 60)
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
        commandLabel.Text = counter .. " | " .. PREFIX .. cmd.name
        commandLabel.TextColor3 = OFF_WHITE
        commandLabel.TextSize = 15
        commandLabel.Font = Enum.Font.GothamBold
        commandLabel.TextXAlignment = Enum.TextXAlignment.Left
        commandLabel.Parent = commandFrame
    
        local descLabel = Instance.new("TextLabel")
        descLabel.Size = UDim2.new(1, -12, 0, 22)
        descLabel.Position = UDim2.new(0, 6, 0, 22)
        descLabel.BackgroundTransparency = 1
        descLabel.Text = "Rank: " .. admin.rankNames[cmd.rank] .. " (" .. cmd.rank .. ") - " .. cmd.desc
        descLabel.TextColor3 = OFF_WHITE
        descLabel.TextSize = 12
        descLabel.Font = Enum.Font.Gotham
        descLabel.TextXAlignment = Enum.TextXAlignment.Left
        descLabel.TextWrapped = true
        descLabel.Parent = commandFrame
        
        local usageLabel = Instance.new("TextLabel")
        usageLabel.Size = UDim2.new(1, -12, 0, 10)
        usageLabel.Position = UDim2.new(0, 6, 0, 48)
        usageLabel.BackgroundTransparency = 1
        usageLabel.Text = "Usage: " .. PREFIX .. cmd.name .. " <player>"
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
    
    -- Tab switching
    local function switchTab(tabName)
        if tabName == "Commands" then
            TweenService:Create(commandsTab, TweenInfo.new(0.3), {
                BackgroundColor3 = COOKIE_DOUGH,
                BackgroundTransparency = 0.1,
                TextColor3 = CHOCOLATE
            }):Play()
            TweenService:Create(creditsTab, TweenInfo.new(0.3), {
                BackgroundColor3 = MILK_CHOCOLATE,
                BackgroundTransparency = 0.3,
                TextColor3 = OFF_WHITE
            }):Play()
            commandsContent.Visible = true
            creditsContent.Visible = false
        else
            TweenService:Create(creditsTab, TweenInfo.new(0.3), {
                BackgroundColor3 = COOKIE_DOUGH,
                BackgroundTransparency = 0.1,
                TextColor3 = CHOCOLATE
            }):Play()
            TweenService:Create(commandsTab, TweenInfo.new(0.3), {
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
    
    -- Dragging
    local dragging = false
    local dragStart = nil
    local startPos = nil
    local dragTween = nil
    
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
            local newPos = UDim2.new(
                startPos.X.Scale,
                startPos.X.Offset + delta.X,
                startPos.Y.Scale,
                startPos.Y.Offset + delta.Y
            )
            
            if dragTween then dragTween:Cancel() end
            dragTween = TweenService:Create(mainFrame, TweenInfo.new(0.08), {Position = newPos})
            dragTween:Play()
        end
    end)
    
    topBar.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging = false
        end
    end)
    
    closeButton.MouseButton1Click:Connect(function()
        TweenService:Create(mainFrame, TweenInfo.new(0.3), {BackgroundTransparency = 1}):Play()
        TweenService:Create(topBar, TweenInfo.new(0.3), {BackgroundTransparency = 1}):Play()
        TweenService:Create(title, TweenInfo.new(0.3), {TextTransparency = 1}):Play()
        TweenService:Create(closeButton, TweenInfo.new(0.3), {TextTransparency = 1}):Play()
        task.wait(0.15)
        dashboardGui:Destroy()
        admin.currentDashboard = nil
    end)
end

-- Command bar
local function createCommandBar()
    local player = Players.LocalPlayer
    if not player then return end
    
    local PlayerGui = player:FindFirstChild("PlayerGui")
    if not PlayerGui then return end
    
    local screenGui = Instance.new("ScreenGui")
    screenGui.Name = "CmdBarGui"
    screenGui.Parent = PlayerGui
    screenGui.ResetOnSpawn = false
    screenGui.IgnoreGuiInset = true
    screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling

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
    cmdBarTextBox.TextColor3 = WHITE
    cmdBarTextBox.TextSize = 18
    cmdBarTextBox.Font = Enum.Font.SourceSans
    cmdBarTextBox.PlaceholderText = "Enter command... (" .. PREFIX .. ")"
    cmdBarTextBox.PlaceholderColor3 = COOKIE_DOUGH
    cmdBarTextBox.ClearTextOnFocus = false
    cmdBarTextBox.Text = ""
    cmdBarTextBox.Parent = cmdBarFrame

    local textBoxCorner = Instance.new("UICorner")
    textBoxCorner.CornerRadius = UDim.new(0, 10)
    textBoxCorner.Parent = cmdBarTextBox
    
    local watermark = Instance.new("Frame")
    watermark.Size = UDim2.new(0, 200, 0, 30)
    watermark.Position = UDim2.new(0, 10, 0, 10)
    watermark.BackgroundColor3 = CHOCOLATE
    watermark.BackgroundTransparency = 0.1
    watermark.BorderSizePixel = 0
    watermark.Parent = screenGui
    
    local watermarkCorner = Instance.new("UICorner")
    watermarkCorner.CornerRadius = UDim.new(0, 8)
    watermarkCorner.Parent = watermark
    
    local watermarkText = Instance.new("TextLabel")
    watermarkText.Size = UDim2.new(1, -10, 1, 0)
    watermarkText.Position = UDim2.new(0, 5, 0, 0)
    watermarkText.BackgroundTransparency = 1
    watermarkText.Text = "Crumbs Admin"
    watermarkText.TextColor3 = COOKIE_DOUGH
    watermarkText.TextSize = 14
    watermarkText.Font = Enum.Font.GothamBold
    watermarkText.TextXAlignment = Enum.TextXAlignment.Left
    watermarkText.Parent = watermark
    
    local function animateTextBox(show)
        if show then
            cmdBarFrame.Visible = true
            cmdBarFrame.Position = UDim2.new(0.25, 0, 1.2, 0)
            cmdBarTextBox:CaptureFocus()
            
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

    UserInputService.InputBegan:Connect(function(input, gameProcessed)
        if not gameProcessed and input.UserInputType == Enum.UserInputType.Keyboard and input.KeyCode == Enum.KeyCode.Comma then
            if cmdBarFrame.Visible then
                animateTextBox(false)
            else
                animateTextBox(true)
            end
        end
    end)

    cmdBarTextBox.FocusLost:Connect(function(enterPressed)
        if enterPressed then
            local commandText = cmdBarTextBox.Text
            cmdBarTextBox.Text = ""
            animateTextBox(false)
            if commandText ~= "" then
                issueCommand(commandText, player)
            end
        else
            animateTextBox(false)
        end
    end)
end

-- Player finding
local function findPlayer(input, caller)
    if not input or input == "" then return nil end
    
    input = string.lower(input)
    
    if input == "me" then
        return caller
    end
    
    if input == "all" then
        return Players:GetPlayers()
    end
    
    if input == "others" then
        local others = {}
        for _, plr in ipairs(Players:GetPlayers()) do
            if plr ~= caller then
                table.insert(others, plr)
            end
        end
        return others
    end
    
    if input == "random" then
        local eligible = Players:GetPlayers()
        return #eligible > 0 and {eligible[math.random(1, #eligible)]} or {}
    end
    
    if input == "admins" or input == "staff" then
        local staff = {}
        for _, plr in ipairs(Players:GetPlayers()) do
            if getRank(plr) >= 1 then
                table.insert(staff, plr)
            end
        end
        return staff
    end
    
    -- Find by name
    local results = {}
    for _, player in ipairs(Players:GetPlayers()) do
        if string.find(string.lower(player.Name), input, 1, true) or 
           string.find(string.lower(player.DisplayName), input, 1, true) then
            table.insert(results, player)
        end
    end
    
    return #results > 0 and results or nil
end

-- COMMANDS
local commands = {}
local commandAliases = {}

local function AddCommand(name, desc, args, minRank, onCalled, aliases)
    local cmd = {
        name = name,
        desc = desc,
        args = args,
        minRank = minRank,
        func = onCalled
    }
    commands[name] = cmd
    
    if aliases then
        for _, alias in ipairs(aliases) do
            commandAliases[alias] = name
        end
    end
end

-- Rank 0
AddCommand("help", "Open command menu", {}, 0, function(caller, ...)
    openDashboard(caller, "Commands")
end, {"cmds", "commands", "menu"})

AddCommand("players", "List all players", {}, 0, function(caller, ...)
    local list = {}
    for _, player in ipairs(Players:GetPlayers()) do
        table.insert(list, player.Name)
    end
    notify(caller, "Crumbs Admin", "Players (" .. #list .. "): " .. table.concat(list, ", "), 5)
end, {"list"})

AddCommand("staff", "List online staff", {}, 0, function(caller, ...)
    local list = {}
    for _, player in ipairs(Players:GetPlayers()) do
        local rank = getRank(player)
        if rank > 0 then
            table.insert(list, player.Name .. " (" .. admin.rankNames[rank] .. ")")
        end
    end
    if #list > 0 then
        notify(caller, "Crumbs Admin", "Online staff: " .. table.concat(list, ", "), 5)
    else
        notify(caller, "Crumbs Admin", "No staff online.", 3)
    end
end, {"admins"})

AddCommand("rj", "Rejoin the server", {}, 0, function(caller, ...)
    notify(caller, "Crumbs Admin", "Rejoining...", 2)
    task.wait(1)
    if #Players:GetPlayers() <= 1 then
        caller:Kick("Rejoining...")
        task.wait()
        TeleportService:Teleport(game.PlaceId, caller)
    else
        TeleportService:TeleportToPlaceInstance(game.PlaceId, game.JobId, caller)
    end
end, {"rejoin", "reconnect"})

-- Rank 1
AddCommand("kill", "Kill a player", {"<player>"}, 1, function(caller, target)
    local targets = findPlayer(target, caller)
    if not targets then notify(caller, "Crumbs Admin", "Player not found.", 3) return end
    
    local count = 0
    for _, player in ipairs(targets) do
        local head = getPlayerHead(player)
        if head then
            head:Destroy()
            count = count + 1
        end
    end
    notify(caller, "Crumbs Admin", "Killed " .. count .. " player(s).", 3)
end, {"k", "slay"})

AddCommand("punish", "Delete player's character", {"<player>"}, 1, function(caller, target)
    local targets = findPlayer(target, caller)
    if not targets then notify(caller, "Crumbs Admin", "Player not found.", 3) return end
    
    local count = 0
    for _, player in ipairs(targets) do
        if player.Character then
            player.Character:Destroy()
            count = count + 1
        end
    end
    notify(caller, "Crumbs Admin", "Punished " .. count .. " player(s).", 3)
end, {"p", "deletechar"})

AddCommand("freeze", "Freeze a player", {"<player>"}, 1, function(caller, target)
    local targets = findPlayer(target, caller)
    if not targets then notify(caller, "Crumbs Admin", "Player not found.", 3) return end
    
    local count = 0
    for _, player in ipairs(targets) do
        if player.Character then
            for _, part in ipairs(getPlayerParts(player)) do
                part.Anchored = true
            end
            count = count + 1
        end
    end
    notify(caller, "Crumbs Admin", "Frozen " .. count .. " player(s).", 3)
end, {"fz", "anchor"})

AddCommand("unfreeze", "Unfreeze a player", {"<player>"}, 1, function(caller, target)
    local targets = findPlayer(target, caller)
    if not targets then notify(caller, "Crumbs Admin", "Player not found.", 3) return end
    
    local count = 0
    for _, player in ipairs(targets) do
        if player.Character then
            for _, part in ipairs(getPlayerParts(player)) do
                part.Anchored = false
            end
            count = count + 1
        end
    end
    notify(caller, "Crumbs Admin", "Unfrozen " .. count .. " player(s).", 3)
end, {"ufz", "unanchor"})

AddCommand("noclip", "Disable collision", {"<player>"}, 1, function(caller, target)
    local targets = findPlayer(target, caller)
    if not targets then notify(caller, "Crumbs Admin", "Player not found.", 3) return end
    
    local count = 0
    for _, player in ipairs(targets) do
        if player.Character then
            for _, part in ipairs(getPlayerParts(player)) do
                part.CanCollide = false
            end
            count = count + 1
        end
    end
    notify(caller, "Crumbs Admin", "Noclip enabled for " .. count .. " player(s).", 3)
end, {"nc", "ghost"})

AddCommand("clip", "Enable collision", {"<player>"}, 1, function(caller, target)
    local targets = findPlayer(target, caller)
    if not targets then notify(caller, "Crumbs Admin", "Player not found.", 3) return end
    
    local count = 0
    for _, player in ipairs(targets) do
        if player.Character then
            for _, part in ipairs(getPlayerParts(player)) do
                part.CanCollide = true
            end
            count = count + 1
        end
    end
    notify(caller, "Crumbs Admin", "Clip enabled for " .. count .. " player(s).", 3)
end, {"c", "collide"})

AddCommand("void", "Send to void", {"<player>"}, 1, function(caller, target)
    local targets = findPlayer(target, caller)
    if not targets then notify(caller, "Crumbs Admin", "Player not found.", 3) return end
    
    local count = 0
    for _, player in ipairs(targets) do
        if player.Character and player.Character:FindFirstChild("HumanoidRootPart") then
            player.Character.HumanoidRootPart.CFrame = CFrame.new(0, -5000, 0)
            count = count + 1
        end
    end
    notify(caller, "Crumbs Admin", "Sent " .. count .. " player(s) to void.", 3)
end, {"v", "underworld"})

AddCommand("tp", "Teleport player", {"<player>", "<destination>"}, 1, function(caller, target, dest)
    local destPlayer = findPlayer(dest, caller)
    if not destPlayer then notify(caller, "Crumbs Admin", "Destination not found.", 3) return end
    destPlayer = destPlayer[1]
    
    if not destPlayer.Character or not destPlayer.Character:FindFirstChild("HumanoidRootPart") then
        notify(caller, "Crumbs Admin", "Destination has no character.", 3)
        return
    end
    
    local destPos = destPlayer.Character.HumanoidRootPart.CFrame * CFrame.new(0, 0, -5)
    local targets = findPlayer(target, caller)
    if not targets then notify(caller, "Crumbs Admin", "Target not found.", 3) return end
    
    local count = 0
    for _, player in ipairs(targets) do
        if player.Character and player.Character:FindFirstChild("HumanoidRootPart") then
            player.Character.HumanoidRootPart.CFrame = destPos
            count = count + 1
        end
    end
    notify(caller, "Crumbs Admin", "Teleported " .. count .. " player(s) to " .. destPlayer.Name, 3)
end, {"teleport", "goto"})

AddCommand("bring", "Bring player to you", {"<player>"}, 1, function(caller, target)
    if not caller.Character or not caller.Character:FindFirstChild("HumanoidRootPart") then
        notify(caller, "Crumbs Admin", "You have no character.", 3)
        return
    end
    
    local myPos = caller.Character.HumanoidRootPart.CFrame * CFrame.new(0, 0, -5)
    local targets = findPlayer(target, caller)
    if not targets then notify(caller, "Crumbs Admin", "Player not found.", 3) return end
    
    local count = 0
    for _, player in ipairs(targets) do
        if player ~= caller and player.Character and player.Character:FindFirstChild("HumanoidRootPart") then
            player.Character.HumanoidRootPart.CFrame = myPos
            count = count + 1
        end
    end
    notify(caller, "Crumbs Admin", "Brought " .. count .. " player(s) to you.", 3)
end, {"b", "fetch"})

AddCommand("invisible", "Make player invisible", {"<player>"}, 1, function(caller, target)
    local targets = findPlayer(target, caller)
    if not targets then notify(caller, "Crumbs Admin", "Player not found.", 3) return end
    
    local count = 0
    for _, player in ipairs(targets) do
        if player.Character then
            for _, part in ipairs(getPlayerParts(player)) do
                part.Transparency = 1
                for _, child in ipairs(part:GetChildren()) do
                    if child:IsA("Decal") or child:IsA("Texture") then
                        child.Transparency = 1
                    end
                end
            end
            count = count + 1
        end
    end
    notify(caller, "Crumbs Admin", "Made " .. count .. " player(s) invisible.", 3)
end, {"inv", "hide"})

AddCommand("visible", "Make player visible", {"<player>"}, 1, function(caller, target)
    local targets = findPlayer(target, caller)
    if not targets then notify(caller, "Crumbs Admin", "Player not found.", 3) return end
    
    local count = 0
    for _, player in ipairs(targets) do
        if player.Character then
            for _, part in ipairs(getPlayerParts(player)) do
                part.Transparency = 0
                for _, child in iparts of part:GetChildren()) do
                    if child:IsA("Decal") or child:IsA("Texture") then
                        child.Transparency = 0
                    end
                end
            end
            count = count + 1
        end
    end
    notify(caller, "Crumbs Admin", "Made " .. count .. " player(s) visible.", 3)
end, {"vis", "show"})

AddCommand("mute", "Mute a player", {"<player>"}, 1, function(caller, target)
    local targets = findPlayer(target, caller)
    if not targets then notify(caller, "Crumbs Admin", "Player not found.", 3) return end
    
    for _, player in ipairs(targets) do
        admin.muted[player.UserId] = true
        notify(player, "Crumbs Admin", "You have been muted by " .. caller.Name, 3)
    end
    notify(caller, "Crumbs Admin", "Muted " .. #targets .. " player(s).", 3)
end, {"silence"})

AddCommand("unmute", "Unmute a player", {"<player>"}, 1, function(caller, target)
    if target:lower() == "all" then
        admin.muted = {}
        notify(caller, "Crumbs Admin", "Unmuted all players.", 3)
        return
    end
    
    local targets = findPlayer(target, caller)
    if not targets then notify(caller, "Crumbs Admin", "Player not found.", 3) return end
    
    for _, player in ipairs(targets) do
        admin.muted[player.UserId] = nil
        notify(player, "Crumbs Admin", "You have been unmuted.", 3)
    end
    notify(caller, "Crumbs Admin", "Unmuted " .. #targets .. " player(s).", 3)
end, {"unsilence"})

-- Rank 2
AddCommand("loopkill", "Repeatedly kill player", {"<player>"}, 2, function(caller, target)
    local targets = findPlayer(target, caller)
    if not targets then notify(caller, "Crumbs Admin", "Player not found.", 3) return end
    
    for _, player in ipairs(targets) do
        admin.loopKill[player.UserId] = true
    end
    notify(caller, "Crumbs Admin", "Loop kill started for " .. #targets .. " player(s).", 3)
end, {"lk", "autokill"})

AddCommand("unloopkill", "Stop loop kill", {"<player>"}, 2, function(caller, target)
    if target:lower() == "all" then
        admin.loopKill = {}
        notify(caller, "Crumbs Admin", "Stopped all loop kills.", 3)
        return
    end
    
    local targets = findPlayer(target, caller)
    if not targets then notify(caller, "Crumbs Admin", "Player not found.", 3) return end
    
    local count = 0
    for _, player in ipairs(targets) do
        if admin.loopKill[player.UserId] then
            admin.loopKill[player.UserId] = nil
            count = count + 1
        end
    end
    notify(caller, "Crumbs Admin", "Stopped loop kill for " .. count .. " player(s).", 3)
end, {"unlk", "stopkill"})

AddCommand("looppunish", "Repeatedly punish player", {"<player>"}, 2, function(caller, target)
    local targets = findPlayer(target, caller)
    if not targets then notify(caller, "Crumbs Admin", "Player not found.", 3) return end
    
    for _, player in ipairs(targets) do
        admin.loopPunish[player.UserId] = true
    end
    notify(caller, "Crumbs Admin", "Loop punish started for " .. #targets .. " player(s).", 3)
end, {"lp", "autopunish"})

AddCommand("unlooppunish", "Stop loop punish", {"<player>"}, 2, function(caller, target)
    if target:lower() == "all" then
        admin.loopPunish = {}
        notify(caller, "Crumbs Admin", "Stopped all loop punishes.", 3)
        return
    end
    
    local targets = findPlayer(target, caller)
    if not targets then notify(caller, "Crumbs Admin", "Player not found.", 3) return end
    
    local count = 0
    for _, player in ipairs(targets) do
        if admin.loopPunish[player.UserId] then
            admin.loopPunish[player.UserId] = nil
            count = count + 1
        end
    end
    notify(caller, "Crumbs Admin", "Stopped loop punish for " .. count .. " player(s).", 3)
end, {"unlp", "stoppunish"})

AddCommand("god", "Toggle god mode", {"<player>"}, 2, function(caller, target)
    local targets = findPlayer(target, caller)
    if not targets then notify(caller, "Crumbs Admin", "Player not found.", 3) return end
    
    for _, player in ipairs(targets) do
        admin.godMode[player.UserId] = not admin.godMode[player.UserId]
        local status = admin.godMode[player.UserId] and "ENABLED" or "DISABLED"
        notify(player, "Crumbs Admin", "God mode " .. status, 3)
    end
    notify(caller, "Crumbs Admin", "Toggled god mode for " .. #targets .. " player(s).", 3)
end, {"godmode", "invincible"})

AddCommand("fly", "Toggle flight mode", {"<player>"}, 2, function(caller, target)
    local targets = findPlayer(target, caller)
    if not targets then notify(caller, "Crumbs Admin", "Player not found.", 3) return end
    
    for _, player in ipairs(targets) do
        admin.flyMode[player.UserId] = not admin.flyMode[player.UserId]
        local status = admin.flyMode[player.UserId] and "ENABLED (use space)" or "DISABLED"
        notify(player, "Crumbs Admin", "Flight mode " .. status, 3)
    end
    notify(caller, "Crumbs Admin", "Toggled flight for " .. #targets .. " player(s).", 3)
end, {"flight"})

-- Rank 3
AddCommand("kick", "Kick a player", {"<player>", "[reason]"}, 3, function(caller, target, ...)
    local reason = #args > 1 and table.concat({...}, " ") or "No reason"
    local targets = findPlayer(target, caller)
    if not targets then notify(caller, "Crumbs Admin", "Player not found.", 3) return end
    
    local count = 0
    for _, player in ipairs(targets) do
        if player ~= caller then
            notifyAll("Crumbs Admin", player.Name .. " was kicked by " .. caller.Name .. " (" .. reason .. ")", 5)
            player:Kick("Kicked by " .. caller.Name .. ": " .. reason)
            count = count + 1
        end
    end
    notify(caller, "Crumbs Admin", "Kicked " .. count .. " player(s).", 3)
end, {"kck"})

AddCommand("ban", "Ban a player", {"<player>", "[duration]", "[reason]"}, 3, function(caller, target, duration, ...)
    local reason = #args > 2 and table.concat({...}, " ") or "No reason"
    local banDuration = duration and tonumber(duration) or nil
    local targets = findPlayer(target, caller)
    if not targets then notify(caller, "Crumbs Admin", "Player not found.", 3) return end
    
    for _, player in ipairs(targets) do
        if player ~= caller then
            local banData = {
                reason = reason,
                admin = caller.Name,
                timestamp = os.time(),
                expiry = banDuration and (os.time() + banDuration) or nil
            }
            admin.bannedPlayers[player.UserId] = banData
            local durationText = banDuration and (" for " .. banDuration .. " seconds") or " permanently"
            notifyAll("Crumbs Admin", player.Name .. " was banned by " .. caller.Name .. durationText, 5)
            player:Kick("Banned by " .. caller.Name .. durationText .. ": " .. reason)
        end
    end
    notify(caller, "Crumbs Admin", "Banned " .. #targets .. " player(s).", 3)
end, {"b"})

AddCommand("unban", "Unban a player", {"<player>"}, 3, function(caller, target)
    local targets = findPlayer(target, caller)
    if targets and targets[1] and admin.bannedPlayers[targets[1].UserId] then
        admin.bannedPlayers[targets[1].UserId] = nil
        notify(caller, "Crumbs Admin", "Unbanned " .. targets[1].Name, 3)
        notifyAll("Crumbs Admin", targets[1].Name .. " was unbanned by " .. caller.Name, 5)
    else
        notify(caller, "Crumbs Admin", "Player not found or not banned.", 3)
    end
end, {"ub", "pardon"})

AddCommand("clear", "Clear workspace parts", {}, 3, function(caller, ...)
    local count = 0
    for _, obj in ipairs(workspace:GetDescendants()) do
        if obj:IsA("BasePart") and not obj:IsDescendantOf(Players) and obj.Name ~= "Baseplate" and not obj:IsA("Terrain") then
            obj:Destroy()
            count = count + 1
        end
    end
    notify(caller, "Crumbs Admin", "Cleared " .. count .. " parts.", 3)
end, {"clean", "wipe"})

AddCommand("announce", "Make announcement", {"<message>"}, 3, function(caller, ...)
    local message = table.concat({...}, " ")
    notifyAll("📢 ANNOUNCEMENT", caller.Name .. ": " .. message, 8)
end, {"say", "broadcast"})

-- Rank 4
AddCommand("rank", "Set player rank", {"<player>", "<rank>"}, 4, function(caller, target, rankNum)
    local targets = findPlayer(target, caller)
    if not targets then notify(caller, "Crumbs Admin", "Player not found.", 3) return end
    
    local newRank = tonumber(rankNum) or 0
    if newRank < 0 or newRank > 4 then
        notify(caller, "Crumbs Admin", "Rank must be 0-4.", 3)
        return
    end
    
    local player = targets[1]
    admin.tempRanks[player.UserId] = newRank
    notify(caller, "Crumbs Admin", "Set " .. player.Name .. "'s rank to " .. admin.rankNames[newRank], 3)
    notify(player, "Crumbs Admin", "Your rank is now " .. admin.rankNames[newRank], 3)
end, {"setrank"})

AddCommand("save", "Save location", {"<name>"}, 4, function(caller, ...)
    if not caller.Character or not caller.Character:FindFirstChild("HumanoidRootPart") then
        notify(caller, "Crumbs Admin", "You have no character.", 3)
        return
    end
    
    local name = table.concat({...}, " ")
    admin.savedLocations[name] = {
        cframe = caller.Character.HumanoidRootPart.CFrame,
        savedBy = caller.Name,
        time = os.time()
    }
    notify(caller, "Crumbs Admin", "Saved location: " .. name, 3)
end, {"saveloc"})

AddCommand("load", "Load location", {"<name>"}, 4, function(caller, ...)
    local name = table.concat({...}, " ")
    if not admin.savedLocations[name] then
        notify(caller, "Crumbs Admin", "Location not found.", 3)
        return
    end
    
    if not caller.Character or not caller.Character:FindFirstChild("HumanoidRootPart") then
        notify(caller, "Crumbs Admin", "You have no character.", 3)
        return
    end
    
    caller.Character.HumanoidRootPart.CFrame = admin.savedLocations[name].cframe
    notify(caller, "Crumbs Admin", "Loaded location: " .. name, 3)
end, {"loadloc"})

AddCommand("locations", "List saved locations", {}, 4, function(caller, ...)
    local list = {}
    for name, _ in pairs(admin.savedLocations) do
        table.insert(list, name)
    end
    if #list == 0 then
        notify(caller, "Crumbs Admin", "No saved locations.", 3)
    else
        notify(caller, "Crumbs Admin", "Locations: " .. table.concat(list, ", "), 5)
    end
end, {"locs"})

AddCommand("shutdown", "Shutdown server", {"[seconds]"}, 4, function(caller, seconds)
    local time = tonumber(seconds) or 30
    if time < 5 then time = 5 end
    if time > 60 then time = 60 end
    
    notifyAll("⚠️ SHUTDOWN", "Server shutting down in " .. time .. " seconds!", 8)
    
    for i = time, 1, -1 do
        if i <= 10 or i % 10 == 0 then
            notifyAll("⚠️ SHUTDOWN", "Shutting down in " .. i .. " seconds!", 3)
        end
        task.wait(1)
    end
    
    for _, player in ipairs(Players:GetPlayers()) do
        player:Kick("Server is shutting down.")
    end
    task.wait(1)
    game:Shutdown()
end, {"sd", "restart"})

AddCommand("eject", "Unload Crumbs Admin", {}, 4, function(caller, ...)
    notifyAll("Crumbs Admin", "Shutting down...", 3)
    task.wait(1)
    
    -- Clear all data
    admin.loopKill = {}
    admin.loopPunish = {}
    admin.godMode = {}
    admin.flyMode = {}
    admin.muted = {}
    admin.frozen = {}
    admin.invisible = {}
    admin.running = false
    
    -- Clear GUI
    if admin.currentDashboard and admin.currentDashboard.Parent then
        admin.currentDashboard:Destroy()
        admin.currentDashboard = nil
    end
    
    -- Remove from global
    _G.CrumbsAdmin = nil
    
    -- Destroy script
    script:Destroy()
end, {"unload", "exit", "quit"})

-- Command parser
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

local function issueCommand(commandText, caller)
    if not caller then caller = Players.LocalPlayer end
    if not caller then return end
    
    local cmd, args = parseCommand(commandText)
    if not cmd then return end
    
    -- Check if banned
    if admin.bannedPlayers[caller.UserId] then
        return
    end
    
    -- Handle aliases
    local realCmd = commandAliases[cmd] or cmd
    local command = commands[realCmd]
    
    if not command then
        if cmd ~= "" then
            notify(caller, "Crumbs Admin", "Unknown command. Type " .. PREFIX .. "help", 3)
        end
        return
    end
    
    -- Check rank
    local rank = getRank(caller)
    if rank < command.minRank then
        notify(caller, "Crumbs Admin", "You need " .. admin.rankNames[command.minRank] .. " rank.", 3)
        return
    end
    
    -- Execute command
    local success, err = pcall(command.func, caller, unpack(args))
    if not success then
        warn("Command error:", err)
        notify(caller, "Crumbs Admin", "Command failed: " .. tostring(err), 5)
    end
end

-- Chat handler
local function setupChatHandler()
    local player = Players.LocalPlayer
    if not player then return end
    
    if TextChatService.ChatVersion == Enum.ChatVersion.TextChatService then
        TextChatService.OnIncomingMessage = function(message)
            if message.TextSource and message.TextSource.UserId == player.UserId then
                if string.sub(message.Text, 1, 1) == PREFIX then
                    issueCommand(message.Text, player)
                    return Enum.IncomingMessageResponse.Cancel
                end
            end
            
            -- Check if sender is muted
            local sender = Players:GetPlayerByUserId(message.TextSource.UserId)
            if sender and admin.muted[sender.UserId] then
                return Enum.IncomingMessageResponse.Cancel
            end
            return Enum.IncomingMessageResponse.Default
        end
    else
        player.Chatted:Connect(function(message)
            if string.sub(message, 1, 1) == PREFIX then
                issueCommand(message, player)
            end
        end)
        
        for _, p in ipairs(Players:GetPlayers()) do
            if p ~= player then
                p.Chatted:Connect(function(msg)
                    if admin.muted[p.UserId] then
                        return true -- Block message
                    end
                end)
            end
        end
        
        Players.PlayerAdded:Connect(function(p)
            p.Chatted:Connect(function(msg)
                if admin.muted[p.UserId] then
                    return true
                end
            end)
        end)
    end
end

-- Loop handlers
task.spawn(function()
    while admin.running do
        task.wait(0.5)
        
        -- Loop kill
        for userId, enabled in pairs(admin.loopKill) do
            if enabled then
                local player = Players:GetPlayerByUserId(userId)
                if player and player.Character then
                    local head = getPlayerHead(player)
                    if head then head:Destroy() end
                end
            end
        end
        
        -- Loop punish
        for userId, enabled in pairs(admin.loopPunish) do
            if enabled then
                local player = Players:GetPlayerByUserId(userId)
                if player and player.Character then
                    player.Character:Destroy()
                end
            end
        end
        
        -- God mode
        for userId, enabled in pairs(admin.godMode) do
            if enabled then
                local player = Players:GetPlayerByUserId(userId)
                if player and player.Character then
                    local humanoid = getPlayerHumanoid(player)
                    if humanoid then
                        humanoid.MaxHealth = math.huge
                        humanoid.Health = humanoid.MaxHealth
                    end
                end
            end
        end
        
        -- Fly mode
        for userId, enabled in pairs(admin.flyMode) do
            if enabled then
                local player = Players:GetPlayerByUserId(userId)
                if player and player.Character and player.Character:FindFirstChild("HumanoidRootPart") then
                    local root = player.Character.HumanoidRootPart
                    local humanoid = getPlayerHumanoid(player)
                    if humanoid then
                        humanoid.PlatformStand = true
                        local moveDir = humanoid.MoveDirection
                        if moveDir.Magnitude > 0 then
                            root.Velocity = moveDir * 50
                        else
                            root.Velocity = Vector3.new(0, 0, 0)
                        end
                    end
                end
            end
        end
        
        -- Ban expiration
        local now = os.time()
        for userId, banData in pairs(admin.bannedPlayers) do
            if banData.expiry and now > banData.expiry then
                admin.bannedPlayers[userId] = nil
            end
        end
    end
end)

-- Initialize
local function initialize()
    local player = Players.LocalPlayer
    if not player then return end
    
    -- Create GUI
    pcall(createCommandBar)
    
    -- Setup chat
    pcall(setupChatHandler)
    
    -- Welcome message
    task.wait(1)
    notify(player, "Crumbs Admin", "Welcome " .. player.DisplayName .. "! Your rank: " .. admin.rankNames[getRank(player)], 4)
    notify(player, "Crumbs Admin", "Press , for command bar | Type " .. PREFIX .. "help", 4)
    
    print("=== Crumbs Admin v4.0 ===")
    print("Prefix: " .. PREFIX)
    print("Your rank: " .. admin.rankNames[getRank(player)])
    print("Environment: " .. (isServer and "Server" or "Console"))
    print("========================")
end

-- Run initialization
if Players.LocalPlayer then
    initialize()
end

Players.PlayerAdded:Connect(function(player)
    task.wait(1)
    if player == Players.LocalPlayer then
        initialize()
    else
        -- For other players in server context
        if getRank(player) > 0 then
            notify(player, "Crumbs Admin", "Your rank: " .. admin.rankNames[getRank(player)], 3)
        end
    end
end)
