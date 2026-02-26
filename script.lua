-- Crumbs Admin - Universal Version (Works in Console or ServerScriptService)
-- Combines server-side functionality with the enhanced GUI from your reference

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local ServerScriptService = game:GetService("ServerScriptService")
local TeleportService = game:GetService("TeleportService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local TextChatService = game:GetService("TextChatService")
local CoreGui = game:GetService("CoreGui")
local StarterGui = game:GetService("StarterGui")

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
admin.savedLocations = admin.savedLocations or {}
admin.antiCrash = admin.antiCrash or {}
admin.notificationStack = admin.notificationStack or {}
admin.currentDashboard = nil

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

-- Helper Functions
local function getRank(player)
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
    -- Try different GUI parents for maximum compatibility
    local success, result = pcall(function()
        -- Try CoreGui first (console/exploit)
        if CoreGui then
            return CoreGui
        end
    end)
    if success and result then return result end
    
    -- Fallback to PlayerGui
    local player = Players.LocalPlayer
    if player then
        return player:FindFirstChild("PlayerGui") or player:WaitForChild("PlayerGui")
    end
    
    -- Ultimate fallback
    return Instance.new("ScreenGui")
end

-- Enhanced Notification System (from your reference)
local notificationCooldown = {}

local function notify(plr, title, message, duration)
    if not plr then return end
    
    local key = title .. message
    if notificationCooldown[key] and tick() - notificationCooldown[key] < 1 then
        return
    end
    notificationCooldown[key] = tick()
    
    coroutine.wrap(function()
        local PlayerGui = plr:FindFirstChild("PlayerGui")
        if not PlayerGui then return end
        
        duration = duration or 4
        
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
        
        CloseButton.MouseEnter:Connect(function()
            TweenService:Create(CloseButton, TweenInfo.new(0.2), {
                TextColor3 = LIGHT_CHOCOLATE,
                TextSize = 17
            }):Play()
        end)
        
        CloseButton.MouseLeave:Connect(function()
            TweenService:Create(CloseButton, TweenInfo.new(0.2), {
                TextColor3 = COOKIE_DOUGH,
                TextSize = 15
            }):Play()
        end)
        
        CloseButton.MouseButton1Click:Connect(closeNotif)
        
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

-- Enhanced Dashboard (from your reference)
local function openDashboard(defaultTab, player)
    defaultTab = defaultTab or "Commands"
    player = player or (Players.LocalPlayer or Players:GetPlayers()[1])
    
    if not player then return end
    
    local PlayerGui = player:FindFirstChild("PlayerGui")
    if not PlayerGui then return end
    
    -- Close existing dashboard
    if admin.currentDashboard and admin.currentDashboard.Parent then
        local mainFrame = admin.currentDashboard:FindFirstChild("MainFrame")
        if mainFrame then
            local fadeOut = TweenService:Create(mainFrame, TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
                BackgroundTransparency = 1
            })
            fadeOut:Play()
            
            for _, v in ipairs(mainFrame:GetDescendants()) do
                if v:IsA("TextLabel") or v:IsA("TextButton") then
                    local tween = TweenService:Create(v, TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
                        TextTransparency = 1
                    })
                    tween:Play()
                elseif v:IsA("Frame") or v:IsA("ScrollingFrame") then
                    local tween = TweenService:Create(v, TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
                        BackgroundTransparency = 1
                    })
                    tween:Play()
                end
            end
            
            task.wait(0.15)
        end
        admin.currentDashboard:Destroy()
        admin.currentDashboard = nil
    end
    
    -- Create new dashboard
    local ScreenGui = Instance.new("ScreenGui")
    ScreenGui.Name = "CrumbsDashboard"
    ScreenGui.ResetOnSpawn = false
    ScreenGui.Parent = PlayerGui
    ScreenGui.IgnoreGuiInset = true
    ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    admin.currentDashboard = ScreenGui
    
    local MainFrame = Instance.new("Frame")
    MainFrame.Name = "MainFrame"
    MainFrame.Size = UDim2.new(0, 750, 0, 420)
    MainFrame.Position = UDim2.new(0.5, -375, 0.5, -210)
    MainFrame.BackgroundColor3 = CHOCOLATE
    MainFrame.BackgroundTransparency = 1
    MainFrame.BorderSizePixel = 2
    MainFrame.BorderColor3 = LIGHT_CHOCOLATE
    MainFrame.Parent = ScreenGui
    
    local MainCorner = Instance.new("UICorner")
    MainCorner.CornerRadius = UDim.new(0, 12)
    MainCorner.Parent = MainFrame
    
    local TopBar = Instance.new("Frame")
    TopBar.Name = "TopBar"
    TopBar.Size = UDim2.new(1, 0, 0, 38)
    TopBar.BackgroundColor3 = MILK_CHOCOLATE
    TopBar.BackgroundTransparency = 1
    TopBar.BorderSizePixel = 0
    TopBar.Parent = MainFrame
    
    local TopBarCorner = Instance.new("UICorner")
    TopBarCorner.CornerRadius = UDim.new(0, 12)
    TopBarCorner.Parent = TopBar
    
    local Title = Instance.new("TextLabel")
    Title.Name = "Title"
    Title.Size = UDim2.new(0, 200, 0, 38)
    Title.Position = UDim2.new(0.36, 0, 0, 0)
    Title.BackgroundTransparency = 1
    Title.Text = "Crumbs Admin"
    Title.TextColor3 = OFF_WHITE
    Title.TextTransparency = 1
    Title.TextSize = 22
    Title.Font = Enum.Font.GothamBold
    Title.Parent = TopBar
    
    local CloseButton = Instance.new("TextButton")
    CloseButton.Name = "CloseButton"
    CloseButton.Size = UDim2.new(0, 32, 0, 32)
    CloseButton.Position = UDim2.new(1, -37, 0, 3)
    CloseButton.BackgroundTransparency = 1
    CloseButton.Text = "X"
    CloseButton.TextColor3 = OFF_WHITE
    CloseButton.TextTransparency = 1
    CloseButton.TextSize = 18
    CloseButton.Font = Enum.Font.GothamBold
    CloseButton.Parent = TopBar
    
    local TabBar = Instance.new("Frame")
    TabBar.Name = "TabBar"
    TabBar.Size = UDim2.new(1, -16, 0, 42)
    TabBar.Position = UDim2.new(0, 8, 0, 46)
    TabBar.BackgroundColor3 = MILK_CHOCOLATE
    TabBar.BackgroundTransparency = 1
    TabBar.BorderSizePixel = 1
    TabBar.BorderColor3 = LIGHT_CHOCOLATE
    TabBar.Parent = MainFrame
    
    local TabBarCorner = Instance.new("UICorner")
    TabBarCorner.CornerRadius = UDim.new(0, 8)
    TabBarCorner.Parent = TabBar
    
    local CommandsTab = Instance.new("TextButton")
    CommandsTab.Name = "CommandsTab"
    CommandsTab.Size = UDim2.new(0.5, -5, 0, 36)
    CommandsTab.Position = UDim2.new(0, 4, 0, 3)
    CommandsTab.BackgroundColor3 = COOKIE_DOUGH
    CommandsTab.BackgroundTransparency = 1
    CommandsTab.BorderSizePixel = 1
    CommandsTab.BorderColor3 = LIGHT_CHOCOLATE
    CommandsTab.Text = "Commands"
    CommandsTab.TextColor3 = CHOCOLATE
    CommandsTab.TextTransparency = 1
    CommandsTab.TextSize = 16
    CommandsTab.Font = Enum.Font.GothamBold
    CommandsTab.Parent = TabBar
    
    local CommandsTabCorner = Instance.new("UICorner")
    CommandsTabCorner.CornerRadius = UDim.new(0, 6)
    CommandsTabCorner.Parent = CommandsTab
    
    local CreditsTab = Instance.new("TextButton")
    CreditsTab.Name = "CreditsTab"
    CreditsTab.Size = UDim2.new(0.5, -5, 0, 36)
    CreditsTab.Position = UDim2.new(0.5, 1, 0, 3)
    CreditsTab.BackgroundColor3 = MILK_CHOCOLATE
    CreditsTab.BackgroundTransparency = 1
    CreditsTab.BorderSizePixel = 1
    CreditsTab.BorderColor3 = LIGHT_CHOCOLATE
    CreditsTab.Text = "Credits"
    CreditsTab.TextColor3 = OFF_WHITE
    CreditsTab.TextTransparency = 1
    CreditsTab.TextSize = 16
    CreditsTab.Font = Enum.Font.GothamBold
    CreditsTab.Parent = TabBar
    
    local CreditsTabCorner = Instance.new("UICorner")
    CreditsTabCorner.CornerRadius = UDim.new(0, 6)
    CreditsTabCorner.Parent = CreditsTab
    
    local ContentFrame = Instance.new("Frame")
    ContentFrame.Name = "ContentFrame"
    ContentFrame.Size = UDim2.new(1, -16, 1, -104)
    ContentFrame.Position = UDim2.new(0, 8, 0, 96)
    ContentFrame.BackgroundColor3 = MILK_CHOCOLATE
    ContentFrame.BackgroundTransparency = 1
    ContentFrame.BorderSizePixel = 1
    ContentFrame.BorderColor3 = LIGHT_CHOCOLATE
    ContentFrame.Parent = MainFrame
    
    local ContentCorner = Instance.new("UICorner")
    ContentCorner.CornerRadius = UDim.new(0, 8)
    ContentCorner.Parent = ContentFrame
    
    local CommandsContent = Instance.new("ScrollingFrame")
    CommandsContent.Name = "CommandsContent"
    CommandsContent.Size = UDim2.new(1, 0, 1, 0)
    CommandsContent.Position = UDim2.new(0, 0, 0, 0)
    CommandsContent.BackgroundColor3 = MILK_CHOCOLATE
    CommandsContent.BackgroundTransparency = 0
    CommandsContent.BorderSizePixel = 0
    CommandsContent.BorderColor3 = LIGHT_CHOCOLATE
    CommandsContent.ScrollBarThickness = 6
    CommandsContent.ScrollBarImageColor3 = COOKIE_DOUGH
    CommandsContent.Visible = (defaultTab == "Commands")
    CommandsContent.Parent = ContentFrame
    
    local CommandsLayout = Instance.new("UIListLayout")
    CommandsLayout.Parent = CommandsContent
    CommandsLayout.SortOrder = Enum.SortOrder.LayoutOrder
    CommandsLayout.Padding = UDim.new(0, 5)
    
    local CommandsPadding = Instance.new("UIPadding")
    CommandsPadding.Parent = CommandsContent
    CommandsPadding.PaddingTop = UDim.new(0, 5)
    CommandsPadding.PaddingLeft = UDim.new(0, 5)
    CommandsPadding.PaddingRight = UDim.new(0, 5)
    
    local CreditsContent = Instance.new("ScrollingFrame")
    CreditsContent.Name = "CreditsContent"
    CreditsContent.Size = UDim2.new(1, 0, 1, 0)
    CreditsContent.Position = UDim2.new(0, 0, 0, 0)
    CreditsContent.BackgroundColor3 = MILK_CHOCOLATE
    CreditsContent.BackgroundTransparency = 1
    CreditsContent.BorderSizePixel = 0
    CreditsContent.BorderColor3 = LIGHT_CHOCOLATE
    CreditsContent.ScrollBarThickness = 6
    CreditsContent.ScrollBarImageColor3 = COOKIE_DOUGH
    CreditsContent.Visible = (defaultTab == "Credits")
    CreditsContent.Parent = ContentFrame
    
    local CreditsLayout = Instance.new("UIListLayout")
    CreditsLayout.Parent = CreditsContent
    CreditsLayout.SortOrder = Enum.SortOrder.LayoutOrder
    CreditsLayout.Padding = UDim.new(0, 10)
    CreditsLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
    
    local CreditsPadding = Instance.new("UIPadding")
    CreditsPadding.Parent = CreditsContent
    CreditsPadding.PaddingTop = UDim.new(0, 10)
    CreditsPadding.PaddingLeft = UDim.new(0, 10)
    CreditsPadding.PaddingRight = UDim.new(0, 10)
    
    -- Credits content
    local CreditTitle = Instance.new("TextLabel")
    CreditTitle.Size = UDim2.new(1, -20, 0, 40)
    CreditTitle.BackgroundTransparency = 1
    CreditTitle.Text = "CREDITS"
    CreditTitle.TextColor3 = COOKIE_DOUGH
    CreditTitle.TextTransparency = 1
    CreditTitle.TextSize = 28
    CreditTitle.Font = Enum.Font.GothamBold
    CreditTitle.Parent = CreditsContent
    
    local CreditDivider = Instance.new("Frame")
    CreditDivider.Size = UDim2.new(0.8, 0, 0, 2)
    CreditDivider.Position = UDim2.new(0.1, 0, 0, 55)
    CreditDivider.BackgroundColor3 = COOKIE_DOUGH
    CreditDivider.BackgroundTransparency = 1
    CreditDivider.BorderSizePixel = 0
    CreditDivider.Parent = CreditsContent
    
    local Credits = {
        {role = "Developer", name = "Crumbs Admin Team", desc = "Server-side admin system v3.0"},
        {role = "GUI Designer", name = "Enhanced Interface", desc = "Smooth animations and notifications"},
        {role = "Version", name = "Crumbs Admin SS v3.0", desc = "Universal - Works in console or server"},
        {role = "Features", name = "Complete Command Set", desc = "40+ commands with rank system"},
    }
    
    local yPos = 70
    for _, credit in ipairs(Credits) do
        local CreditFrame = Instance.new("Frame")
        CreditFrame.Size = UDim2.new(0.9, 0, 0, 80)
        CreditFrame.Position = UDim2.new(0.05, 0, 0, yPos)
        CreditFrame.BackgroundColor3 = LIGHT_CHOCOLATE
        CreditFrame.BackgroundTransparency = 1
        CreditFrame.BorderSizePixel = 1
        CreditFrame.BorderColor3 = COOKIE_DOUGH
        CreditFrame.Parent = CreditsContent
        
        local CreditFrameCorner = Instance.new("UICorner")
        CreditFrameCorner.CornerRadius = UDim.new(0, 8)
        CreditFrameCorner.Parent = CreditFrame
        
        local RoleLabel = Instance.new("TextLabel")
        RoleLabel.Size = UDim2.new(1, -20, 0, 20)
        RoleLabel.Position = UDim2.new(0, 10, 0, 8)
        RoleLabel.BackgroundTransparency = 1
        RoleLabel.Text = credit.role
        RoleLabel.TextColor3 = COOKIE_DOUGH
        RoleLabel.TextTransparency = 1
        RoleLabel.TextSize = 16
        RoleLabel.Font = Enum.Font.GothamBold
        RoleLabel.TextXAlignment = Enum.TextXAlignment.Left
        RoleLabel.Parent = CreditFrame
        
        local NameLabel = Instance.new("TextLabel")
        NameLabel.Size = UDim2.new(1, -20, 0, 22)
        NameLabel.Position = UDim2.new(0, 10, 0, 28)
        NameLabel.BackgroundTransparency = 1
        NameLabel.Text = credit.name
        NameLabel.TextColor3 = OFF_WHITE
        NameLabel.TextTransparency = 1
        NameLabel.TextSize = 18
        NameLabel.Font = Enum.Font.GothamBold
        NameLabel.TextXAlignment = Enum.TextXAlignment.Left
        NameLabel.Parent = CreditFrame
        
        local DescLabel = Instance.new("TextLabel")
        DescLabel.Size = UDim2.new(1, -20, 0, 16)
        DescLabel.Position = UDim2.new(0, 10, 0, 52)
        DescLabel.BackgroundTransparency = 1
        DescLabel.Text = credit.desc
        DescLabel.TextColor3 = CHOCOLATE
        DescLabel.TextTransparency = 1
        DescLabel.TextSize = 12
        DescLabel.Font = Enum.Font.Gotham
        DescLabel.TextXAlignment = Enum.TextXAlignment.Left
        DescLabel.TextWrapped = true
        DescLabel.Parent = CreditFrame
        
        yPos = yPos + 90
    end
    
    local SpecialThanks = Instance.new("TextLabel")
    SpecialThanks.Size = UDim2.new(0.9, 0, 0, 40)
    SpecialThanks.Position = UDim2.new(0.05, 0, 0, yPos + 10)
    SpecialThanks.BackgroundTransparency = 1
    SpecialThanks.Text = "Crumbs Admin v3.0 - Now with enhanced GUI!"
    SpecialThanks.TextColor3 = COOKIE_DOUGH
    SpecialThanks.TextTransparency = 1
    SpecialThanks.TextSize = 14
    SpecialThanks.Font = Enum.Font.GothamBold
    SpecialThanks.TextWrapped = true
    SpecialThanks.Parent = CreditsContent
    
    yPos = yPos + 60
    CreditsContent.CanvasSize = UDim2.new(0, 0, 0, yPos + 20)
    
    -- Commands list
    local sampleCommands = {
        {name = "help", rank = 0, desc = "Show command list"},
        {name = "players", rank = 0, desc = "List all players"},
        {name = "staff", rank = 0, desc = "List online staff"},
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
        local CommandFrame = Instance.new("Frame")
        CommandFrame.Name = "Command_" .. cmd.name
        CommandFrame.Size = UDim2.new(1, 0, 0, 60)
        CommandFrame.BackgroundColor3 = LIGHT_CHOCOLATE
        CommandFrame.BackgroundTransparency = 1
        CommandFrame.BorderSizePixel = 1
        CommandFrame.BorderColor3 = COOKIE_DOUGH
        CommandFrame.Parent = CommandsContent
    
        local CmdCorner = Instance.new("UICorner")
        CmdCorner.CornerRadius = UDim.new(0, 6)
        CmdCorner.Parent = CommandFrame
    
        local CommandLabel = Instance.new("TextLabel")
        CommandLabel.Size = UDim2.new(0.5, 0, 0, 16)
        CommandLabel.Position = UDim2.new(0, 6, 0, 3)
        CommandLabel.BackgroundTransparency = 1
        CommandLabel.Text = counter .. " | " .. admin.config.prefix .. cmd.name
        CommandLabel.TextColor3 = OFF_WHITE
        CommandLabel.TextTransparency = 1
        CommandLabel.TextSize = 15
        CommandLabel.Font = Enum.Font.GothamBold
        CommandLabel.TextXAlignment = Enum.TextXAlignment.Left
        CommandLabel.Parent = CommandFrame
    
        local DescLabel = Instance.new("TextLabel")
        DescLabel.Size = UDim2.new(1, -12, 0, 22)
        DescLabel.Position = UDim2.new(0, 6, 0, 22)
        DescLabel.BackgroundTransparency = 1
        DescLabel.Text = "Rank required: " .. admin.rankNames[cmd.rank] .. " (" .. cmd.rank .. ") - " .. cmd.desc
        DescLabel.TextColor3 = OFF_WHITE
        DescLabel.TextTransparency = 1
        DescLabel.TextSize = 12
        DescLabel.Font = Enum.Font.Gotham
        DescLabel.TextXAlignment = Enum.TextXAlignment.Left
        DescLabel.TextWrapped = true
        DescLabel.Parent = CommandFrame
        
        local UsageLabel = Instance.new("TextLabel")
        UsageLabel.Size = UDim2.new(1, -12, 0, 10)
        UsageLabel.Position = UDim2.new(0, 6, 0, 48)
        UsageLabel.BackgroundTransparency = 1
        UsageLabel.Text = "Usage: " .. admin.config.prefix .. cmd.name .. " <player>"
        UsageLabel.TextColor3 = COOKIE_DOUGH
        UsageLabel.TextTransparency = 1
        UsageLabel.TextSize = 10
        UsageLabel.Font = Enum.Font.Gotham
        UsageLabel.TextXAlignment = Enum.TextXAlignment.Left
        UsageLabel.Parent = CommandFrame
    end
    
    CommandsLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
        CommandsContent.CanvasSize = UDim2.new(0, 0, 0, CommandsLayout.AbsoluteContentSize.Y + 10)
    end)
    CommandsContent.CanvasSize = UDim2.new(0, 0, 0, CommandsLayout.AbsoluteContentSize.Y + 10)
    
    local function switchTab(tabName)
        if tabName == "Commands" then
            TweenService:Create(CommandsTab, TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
                BackgroundColor3 = COOKIE_DOUGH,
                BackgroundTransparency = 0.1,
                TextColor3 = CHOCOLATE
            }):Play()
            
            TweenService:Create(CreditsTab, TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
                BackgroundColor3 = MILK_CHOCOLATE,
                BackgroundTransparency = 0.3,
                TextColor3 = OFF_WHITE
            }):Play()
            
            CommandsContent.Visible = true
            CreditsContent.Visible = false
        else
            TweenService:Create(CreditsTab, TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
                BackgroundColor3 = COOKIE_DOUGH,
                BackgroundTransparency = 0.1,
                TextColor3 = CHOCOLATE
            }):Play()
            
            TweenService:Create(CommandsTab, TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
                BackgroundColor3 = MILK_CHOCOLATE,
                BackgroundTransparency = 0.3,
                TextColor3 = OFF_WHITE
            }):Play()
            
            CommandsContent.Visible = false
            CreditsContent.Visible = true
        end
    end
    
    CommandsTab.MouseButton1Click:Connect(function()
        switchTab("Commands")
    end)
    
    CreditsTab.MouseButton1Click:Connect(function()
        switchTab("Credits")
    end)
    
    -- Dragging functionality
    local dragging = false
    local dragStart = nil
    local startPos = nil
    local dragTween = nil
    local connectionMove = nil
    local connectionEnd = nil
    
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
            
            dragTween = TweenService:Create(MainFrame, TweenInfo.new(0.08, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
                Position = newPos
            })
            dragTween:Play()
        end
    end
    
    TopBar.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = true
            dragStart = input.Position
            startPos = MainFrame.Position
            
            if dragTween then
                dragTween:Cancel()
            end
            
            connectionMove = input.Changed:Connect(function()
                if input.UserInputState == Enum.UserInputState.End then
                    dragging = false
                    if connectionMove then
                        connectionMove:Disconnect()
                        connectionMove = nil
                    end
                end
            end)
            
            connectionEnd = UserInputService.InputChanged:Connect(function(input)
                if (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) and dragging then
                    updateDrag(input)
                end
            end)
        end
    end)
    
    TopBar.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = false
            if connectionMove then
                connectionMove:Disconnect()
                connectionMove = nil
            end
            if connectionEnd then
                connectionEnd:Disconnect()
                connectionEnd = nil
            end
        end
    end)
    
    local function cleanup()
        dragging = false
        if connectionMove then
            connectionMove:Disconnect()
            connectionMove = nil
        end
        if connectionEnd then
            connectionEnd:Disconnect()
            connectionEnd = nil
        end
        if dragTween then
            dragTween:Cancel()
            dragTween = nil
        end
    end
    
    ScreenGui.Destroying:Connect(cleanup)
    
    CloseButton.MouseButton1Click:Connect(function()
        local fadeOut1 = TweenService:Create(MainFrame, TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
            BackgroundTransparency = 1
        })
        local fadeOut2 = TweenService:Create(TopBar, TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
            BackgroundTransparency = 1
        })
        local fadeOut3 = TweenService:Create(Title, TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
            TextTransparency = 1
        })
        local fadeOut4 = TweenService:Create(CloseButton, TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
            TextTransparency = 1
        })
        local fadeOut5 = TweenService:Create(TabBar, TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
            BackgroundTransparency = 1
        })
        local fadeOut6 = TweenService:Create(CommandsTab, TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
            BackgroundTransparency = 1,
            TextTransparency = 1
        })
        local fadeOut7 = TweenService:Create(CreditsTab, TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
            BackgroundTransparency = 1,
            TextTransparency = 1
        })
        
        local fadeOut8 = TweenService:Create(ContentFrame, TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
            BackgroundTransparency = 1
        })
        fadeOut8:Play()
        
        local contentFades = {}
        for _, v in ipairs(ContentFrame:GetDescendants()) do
            if v:IsA("TextLabel") or v:IsA("TextButton") then
                local tween = TweenService:Create(v, TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
                    TextTransparency = 1
                })
                table.insert(contentFades, tween)
                tween:Play()
            elseif v:IsA("Frame") or v:IsA("ScrollingFrame") then
                local tween = TweenService:Create(v, TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
                    BackgroundTransparency = 1
                })
                table.insert(contentFades, tween)
                tween:Play()
            end
        end
        
        fadeOut1:Play()
        fadeOut2:Play()
        fadeOut3:Play()
        fadeOut4:Play()
        fadeOut5:Play()
        fadeOut6:Play()
        fadeOut7:Play()
        
        task.wait(0.15)
        ScreenGui:Destroy()
        admin.currentDashboard = nil
    end)
    
    -- Initial fade in animations
    CommandsContent.BackgroundTransparency = 1
    for _, v in ipairs(CommandsContent:GetDescendants()) do
        if v:IsA("TextLabel") or v:IsA("TextButton") then
            v.TextTransparency = 1
        elseif v:IsA("Frame") then
            v.BackgroundTransparency = 1
        end
    end
    
    CreditsContent.BackgroundTransparency = 1
    for _, v in ipairs(CreditsContent:GetDescendants()) do
        if v:IsA("TextLabel") or v:IsA("TextButton") then
            v.TextTransparency = 1
        elseif v:IsA("Frame") then
            v.BackgroundTransparency = 1
        end
    end
    
    task.wait(0.1)
    
    local fadeIn1 = TweenService:Create(MainFrame, TweenInfo.new(0.5, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
        BackgroundTransparency = 0.05
    })
    local fadeIn2 = TweenService:Create(TopBar, TweenInfo.new(0.5, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
        BackgroundTransparency = 0.1
    })
    local fadeIn3 = TweenService:Create(Title, TweenInfo.new(0.5, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
        TextTransparency = 0
    })
    local fadeIn4 = TweenService:Create(CloseButton, TweenInfo.new(0.5, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
        TextTransparency = 0
    })
    local fadeIn5 = TweenService:Create(TabBar, TweenInfo.new(0.5, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
        BackgroundTransparency = 0.2
    })
    
    fadeIn1:Play()
    fadeIn2:Play()
    fadeIn3:Play()
    fadeIn4:Play()
    fadeIn5:Play()
    
    local fadeIn6 = TweenService:Create(CommandsTab, TweenInfo.new(0.5, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
        BackgroundTransparency = (defaultTab == "Commands" and 0.1 or 0.3),
        TextTransparency = 0
    })
    local fadeIn7 = TweenService:Create(CreditsTab, TweenInfo.new(0.5, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
        BackgroundTransparency = (defaultTab == "Credits" and 0.1 or 0.3),
        TextTransparency = 0
    })
    
    fadeIn6:Play()
    fadeIn7:Play()
    
    local fadeIn8 = TweenService:Create(ContentFrame, TweenInfo.new(0.5, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
        BackgroundTransparency = 0.3
    })
    fadeIn8:Play()
    
    if defaultTab == "Commands" then
        CommandsTab.BackgroundColor3 = COOKIE_DOUGH
        CreditsTab.BackgroundColor3 = MILK_CHOCOLATE
    else
        CommandsTab.BackgroundColor3 = MILK_CHOCOLATE
        CreditsTab.BackgroundColor3 = COOKIE_DOUGH
    end
    
    task.wait(0.1)
    for _, cmdFrame in ipairs(CommandsContent:GetChildren()) do
        if cmdFrame:IsA("Frame") then
            local frameFade = TweenService:Create(cmdFrame, TweenInfo.new(0.4, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
                BackgroundTransparency = 0.3
            })
            frameFade:Play()
            
            for _, v in ipairs(cmdFrame:GetDescendants()) do
                if v:IsA("TextLabel") then
                    local textFade = TweenService:Create(v, TweenInfo.new(0.4, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
                        TextTransparency = 0
                    })
                    textFade:Play()
                end
            end
            task.wait(0.03)
        end
    end
    
    task.wait(0.1)
    for _, v in ipairs(CreditsContent:GetDescendants()) do
        if v:IsA("TextLabel") then
            local textFade = TweenService:Create(v, TweenInfo.new(0.4, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
                TextTransparency = 0
            })
            textFade:Play()
        elseif v:IsA("Frame") and v ~= CreditsContent then
            local frameFade = TweenService:Create(v, TweenInfo.new(0.4, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
                BackgroundTransparency = 0.3
            })
            frameFade:Play()
        end
        task.wait(0.02)
    end
end

-- Command bar GUI
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
    cmdBarTextBox.BackgroundTransparency = 0
    cmdBarTextBox.TextColor3 = WHITE
    cmdBarTextBox.TextSize = 18
    cmdBarTextBox.Font = Enum.Font.SourceSans
    cmdBarTextBox.PlaceholderText = "Enter command... ( " .. admin.config.prefix .. " )"
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
    hintLabel.Text = "Crumbs Admin is running..."
    hintLabel.TextSize = 13
    hintLabel.Font = Enum.Font.SourceSans
    hintLabel.TextXAlignment = Enum.TextXAlignment.Left
    hintLabel.Parent = screenGui
    
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
            
            -- Process command (will be handled by command handler)
            if commandText ~= "" then
                issueCommand(commandText, player)
            end
        else
            animateTextBox(false)
        end
    end)
end

-- Command handling
local commands = {}
local commandAliases = {}
local commandInfo = {}

local function AddCommand(name, desc, args, minRank, onCalled, aliases)
    local tmpTbl = {
        ["Name"] = name,
        ["Description"] = desc,
        ["Arguments"] = args,
        ["MinRank"] = minRank,
        ["OnCalled"] = onCalled
    }
    table.insert(commands, tmpTbl)
    
    commandInfo[name] = {
        name = name,
        aliases = aliases or {},
        desc = desc,
        minRank = minRank,
        usage = admin.config.prefix .. name .. (args and #args > 0 and " " .. table.concat(args, " ") or ""),
    }
    
    if aliases then
        for _, alias in ipairs(aliases) do
            commandAliases[alias] = name
        end
    end
end

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
        local eligible = {}
        for _, plr in ipairs(Players:GetPlayers()) do
            table.insert(eligible, plr)
        end
        return #eligible > 0 and {eligible[math.random(1, #eligible)]} or {}
    end
    
    if input == "admins" then
        local admins = {}
        for _, plr in ipairs(Players:GetPlayers()) do
            if getRank(plr) >= 1 then
                table.insert(admins, plr)
            end
        end
        return admins
    end
    
    if input == "nonadmins" then
        local users = {}
        for _, plr in ipairs(Players:GetPlayers()) do
            if getRank(plr) == 0 then
                table.insert(users, plr)
            end
        end
        return users
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

local function issueCommand(commandText, caller)
    if not caller then caller = Players.LocalPlayer end
    if not caller then return end
    
    if string.sub(commandText, 1, 1) == admin.config.prefix then
        commandText = string.sub(commandText, 2)
    end

    if commandText:lower() == "cmds" or commandText:lower() == "commands" or commandText:lower() == "help" or commandText:lower() == "menu" then
        openDashboard("Commands", caller)
        return
    end

    local commandFound = false
    local commandSplit = string.split(commandText, " ")
    local cmdName = string.lower(table.remove(commandSplit, 1))
    
    local realCommandName = commandAliases[cmdName]
    if realCommandName then
        cmdName = realCommandName
    end

    local callerRank = getRank(caller)

    for _, cmd in ipairs(commands) do
        if cmdName == cmd.Name then
            commandFound = true
            
            if callerRank < cmd.MinRank then
                notify(caller, "Crumbs Admin", "You need rank " .. admin.rankNames[cmd.MinRank] .. " (" .. cmd.MinRank .. ") to use this command.", 3)
                return
            end
            
            -- Handle multi-target with commas
            if #commandSplit > 0 and string.find(commandSplit[1], ",") then
                local targetsString = table.remove(commandSplit, 1)
                local targetNames = string.split(targetsString, ",")
                
                for _, name in ipairs(targetNames) do
                    name = name:gsub("^%s+", ""):gsub("%s+$", "")
                    local targets = findPlayer(name, caller)
                    
                    if targets then
                        if type(targets) ~= "table" then targets = {targets} end
                        for _, target in ipairs(targets) do
                            local args = {target.Name, unpack(commandSplit)}
                            local success, err = pcall(cmd.OnCalled, caller, unpack(args))
                            if not success then
                                notify(caller, "Crumbs Admin", "Command error: " .. tostring(err), 5)
                            end
                        end
                    end
                    task.wait(0.05)
                end
            else
                local success, err = pcall(cmd.OnCalled, caller, unpack(commandSplit))
                if not success then
                    notify(caller, "Crumbs Admin", "Command error: " .. tostring(err), 5)
                end
            end
            break
        end
    end
    
    if not commandFound and commandText ~= "" then
        notify(caller, "Crumbs Admin", "Unknown command: " .. cmdName .. ". Type " .. admin.config.prefix .. "help for commands.", 3)
    end
end

-- Setup chat handler
local function setupCommandHandler()
    local player = Players.LocalPlayer
    if not player then return end
    
    if TextChatService.ChatVersion == Enum.ChatVersion.TextChatService then
        local textChatCommands = TextChatService:FindFirstChild("TextChatCommands")
        if not textChatCommands then
            textChatCommands = Instance.new("Folder")
            textChatCommands.Name = "TextChatCommands"
            textChatCommands.Parent = TextChatService
        end
        
        local cmdTrigger = textChatCommands:FindFirstChild("CmdTrigger")
        if cmdTrigger then cmdTrigger:Destroy() end
        
        cmdTrigger = Instance.new("TextChatCommand")
        cmdTrigger.Name = "CmdTrigger"
        cmdTrigger.TriggerTexts = {admin.config.prefix}
        cmdTrigger.Parent = textChatCommands
        
        cmdTrigger.Callbacked:Connect(function(_, messageText)
            if string.sub(messageText, 1, 1) == admin.config.prefix then
                issueCommand(messageText, player)
            end
        end)
        
        TextChatService.OnIncomingMessage = function(message)
            if message.TextSource and message.TextSource.UserId == player.UserId then
                if string.sub(message.Text, 1, 1) == admin.config.prefix then
                    return Enum.IncomingMessageResponse.Cancel
                end
            end
            return Enum.IncomingMessageResponse.Default
        end
    else
        player.Chatted:Connect(function(message)
            if string.sub(message, 1, 1) == admin.config.prefix then
                issueCommand(message, player)
            end
        end)
    end
end

-- COMMAND DEFINITIONS
-- Rank 0 Commands
AddCommand("help", "Show command list", {}, 0, function(caller)
    openDashboard("Commands", caller)
end, {"commands", "cmds", "menu"})

AddCommand("players", "List all players", {}, 0, function(caller)
    local list = {}
    for _, player in ipairs(Players:GetPlayers()) do
        table.insert(list, player.Name)
    end
    notify(caller, "Crumbs Admin", "Players (" .. #list .. "): " .. table.concat(list, ", "), 5)
end, {"list", "online"})

AddCommand("staff", "List online staff", {}, 0, function(caller)
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

AddCommand("serverinfo", "Show server information", {}, 0, function(caller)
    local info = string.format(
        "Server Info:\nPlayers: %d/%d\nPlace ID: %d\nJob ID: %s",
        #Players:GetPlayers(),
        Players.MaxPlayers,
        game.PlaceId,
        game.JobId:sub(1, 8)
    )
    notify(caller, "Crumbs Admin", info, 5)
end, {"info", "si"})

AddCommand("rj", "Rejoin the server", {}, 0, function(caller)
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

-- Rank 1 Commands
AddCommand("kill", "Kill a player", {"<player>"}, 1, function(caller, target)
    local targets = findPlayer(target, caller)
    if not targets then notify(caller, "Crumbs Admin", "Player not found.", 3) return end
    
    if type(targets) ~= "table" then targets = {targets} end
    
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

AddCommand("punish", "Delete a player's character", {"<player>"}, 1, function(caller, target)
    local targets = findPlayer(target, caller)
    if not targets then notify(caller, "Crumbs Admin", "Player not found.", 3) return end
    
    if type(targets) ~= "table" then targets = {targets} end
    
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
    
    if type(targets) ~= "table" then targets = {targets} end
    
    local count = 0
    for _, player in ipairs(targets) do
        if player.Character then
            for _, part in ipairs(getPlayerParts(player)) do
                part.Anchored = true
            end
            admin.frozen[player.UserId] = true
            count = count + 1
        end
    end
    
    notify(caller, "Crumbs Admin", "Frozen " .. count .. " player(s).", 3)
end, {"fz", "anchor"})

AddCommand("unfreeze", "Unfreeze a player", {"<player>"}, 1, function(caller, target)
    local targets = findPlayer(target, caller)
    if not targets then notify(caller, "Crumbs Admin", "Player not found.", 3) return end
    
    if type(targets) ~= "table" then targets = {targets} end
    
    local count = 0
    for _, player in ipairs(targets) do
        if player.Character then
            for _, part in ipairs(getPlayerParts(player)) do
                part.Anchored = false
            end
            admin.frozen[player.UserId] = nil
            count = count + 1
        end
    end
    
    notify(caller, "Crumbs Admin", "Unfrozen " .. count .. " player(s).", 3)
end, {"ufz", "unanchor"})

AddCommand("noclip", "Disable collision for a player", {"<player>"}, 1, function(caller, target)
    local targets = findPlayer(target, caller)
    if not targets then notify(caller, "Crumbs Admin", "Player not found.", 3) return end
    
    if type(targets) ~= "table" then targets = {targets} end
    
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

AddCommand("clip", "Enable collision for a player", {"<player>"}, 1, function(caller, target)
    local targets = findPlayer(target, caller)
    if not targets then notify(caller, "Crumbs Admin", "Player not found.", 3) return end
    
    if type(targets) ~= "table" then targets = {targets} end
    
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

AddCommand("void", "Send a player to the void", {"<player>"}, 1, function(caller, target)
    local targets = findPlayer(target, caller)
    if not targets then notify(caller, "Crumbs Admin", "Player not found.", 3) return end
    
    if type(targets) ~= "table" then targets = {targets} end
    
    local count = 0
    for _, player in ipairs(targets) do
        if player.Character and player.Character:FindFirstChild("HumanoidRootPart") then
            player.Character.HumanoidRootPart.CFrame = CFrame.new(0, -5000, 0)
            count = count + 1
        end
    end
    
    notify(caller, "Crumbs Admin", "Sent " .. count .. " player(s) to the void.", 3)
end, {"v", "underworld"})

AddCommand("skydive", "Launch a player into the sky", {"<player>", "[height]"}, 1, function(caller, target, height)
    local targets = findPlayer(target, caller)
    if not targets then notify(caller, "Crumbs Admin", "Player not found.", 3) return end
    
    local launchHeight = tonumber(height) or 1000
    if launchHeight < 1000 then launchHeight = 1000 end
    
    if type(targets) ~= "table" then targets = {targets} end
    
    local count = 0
    for _, player in ipairs(targets) do
        if player.Character and player.Character:FindFirstChild("HumanoidRootPart") then
            local pos = player.Character.HumanoidRootPart.Position
            player.Character.HumanoidRootPart.CFrame = CFrame.new(pos.X, pos.Y + launchHeight, pos.Z)
            count = count + 1
        end
    end
    
    notify(caller, "Crumbs Admin", "Launched " .. count .. " player(s) " .. launchHeight .. " studs.", 3)
end, {"sky", "launch"})

AddCommand("tp", "Teleport a player to another player", {"<player>", "<destination>"}, 1, function(caller, target, destination)
    local destPlayer = findPlayer(destination, caller)
    if not destPlayer then notify(caller, "Crumbs Admin", "Destination not found.", 3) return end
    if type(destPlayer) == "table" then destPlayer = destPlayer[1] end
    
    if not destPlayer.Character or not destPlayer.Character:FindFirstChild("HumanoidRootPart") then
        notify(caller, "Crumbs Admin", "Destination has no character.", 3)
        return
    end
    
    local destPos = destPlayer.Character.HumanoidRootPart.CFrame * CFrame.new(0, 0, -5)
    
    local targets = findPlayer(target, caller)
    if not targets then notify(caller, "Crumbs Admin", "Target not found.", 3) return end
    
    if type(targets) ~= "table" then targets = {targets} end
    
    local count = 0
    for _, player in ipairs(targets) do
        if player.Character and player.Character:FindFirstChild("HumanoidRootPart") then
            player.Character.HumanoidRootPart.CFrame = destPos
            count = count + 1
        end
    end
    
    notify(caller, "Crumbs Admin", "Teleported " .. count .. " player(s) to " .. destPlayer.Name, 3)
end, {"teleport", "goto"})

AddCommand("bring", "Bring a player to you", {"<player>"}, 1, function(caller, target)
    if not caller.Character or not caller.Character:FindFirstChild("HumanoidRootPart") then
        notify(caller, "Crumbs Admin", "You have no character.", 3)
        return
    end
    
    local myPos = caller.Character.HumanoidRootPart.CFrame * CFrame.new(0, 0, -5)
    
    local targets = findPlayer(target, caller)
    if not targets then notify(caller, "Crumbs Admin", "Player not found.", 3) return end
    
    if type(targets) ~= "table" then targets = {targets} end
    
    local count = 0
    for _, player in ipairs(targets) do
        if player ~= caller and player.Character and player.Character:FindFirstChild("HumanoidRootPart") then
            player.Character.HumanoidRootPart.CFrame = myPos
            count = count + 1
        end
    end
    
    notify(caller, "Crumbs Admin", "Brought " .. count .. " player(s) to you.", 3)
end, {"b", "fetch"})

AddCommand("invisible", "Make a player invisible", {"<player>"}, 1, function(caller, target)
    local targets = findPlayer(target, caller)
    if not targets then notify(caller, "Crumbs Admin", "Player not found.", 3) return end
    
    if type(targets) ~= "table" then targets = {targets} end
    
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
            admin.invisible[player.UserId] = true
            count = count + 1
        end
    end
    
    notify(caller, "Crumbs Admin", "Made " .. count .. " player(s) invisible.", 3)
end, {"inv", "hide"})

AddCommand("visible", "Make a player visible", {"<player>"}, 1, function(caller, target)
    local targets = findPlayer(target, caller)
    if not targets then notify(caller, "Crumbs Admin", "Player not found.", 3) return end
    
    if type(targets) ~= "table" then targets = {targets} end
    
    local count = 0
    for _, player in ipairs(targets) do
        if player.Character then
            for _, part in ipairs(getPlayerParts(player)) do
                part.Transparency = 0
                for _, child in ipairs(part:GetChildren()) do
                    if child:IsA("Decal") or child:IsA("Texture") then
                        child.Transparency = 0
                    end
                end
            end
            admin.invisible[player.UserId] = nil
            count = count + 1
        end
    end
    
    notify(caller, "Crumbs Admin", "Made " .. count .. " player(s) visible.", 3)
end, {"vis", "show"})

AddCommand("mute", "Mute a player", {"<player>"}, 1, function(caller, target)
    local targets = findPlayer(target, caller)
    if not targets then notify(caller, "Crumbs Admin", "Player not found.", 3) return end
    
    if type(targets) ~= "table" then targets = {targets} end
    
    for _, player in ipairs(targets) do
        admin.muted[player.UserId] = true
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
    
    if type(targets) ~= "table" then targets = {targets} end
    
    for _, player in ipairs(targets) do
        admin.muted[player.UserId] = nil
    end
    
    notify(caller, "Crumbs Admin", "Unmuted " .. #targets .. " player(s).", 3)
end, {"unsilence"})

-- Rank 2 Commands
AddCommand("loopkill", "Repeatedly kill a player", {"<player>"}, 2, function(caller, target)
    local targets = findPlayer(target, caller)
    if not targets then notify(caller, "Crumbs Admin", "Player not found.", 3) return end
    
    if type(targets) ~= "table" then targets = {targets} end
    
    for _, player in ipairs(targets) do
        if player ~= caller then
            admin.loopKill[player.UserId] = true
        end
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
    
    if type(targets) ~= "table" then targets = {targets} end
    
    local count = 0
    for _, player in ipairs(targets) do
        if admin.loopKill[player.UserId] then
            admin.loopKill[player.UserId] = nil
            count = count + 1
        end
    end
    
    notify(caller, "Crumbs Admin", "Stopped loop kill for " .. count .. " player(s).", 3)
end, {"unlk", "stopkill"})

AddCommand("looppunish", "Repeatedly punish a player", {"<player>"}, 2, function(caller, target)
    local targets = findPlayer(target, caller)
    if not targets then notify(caller, "Crumbs Admin", "Player not found.", 3) return end
    
    if type(targets) ~= "table" then targets = {targets} end
    
    for _, player in ipairs(targets) do
        if player ~= caller then
            admin.loopPunish[player.UserId] = true
        end
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
    
    if type(targets) ~= "table" then targets = {targets} end
    
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
    
    if type(targets) ~= "table" then targets = {targets} end
    
    for _, player in ipairs(targets) do
        admin.godMode = admin.godMode or {}
        admin.godMode[player.UserId] = not admin.godMode[player.UserId]
        notify(player, "Crumbs Admin", "God mode: " .. (admin.godMode[player.UserId] and "ON" or "OFF"), 3)
    end
    
    notify(caller, "Crumbs Admin", "Toggled god mode for " .. #targets .. " player(s).", 3)
end, {"godmode", "invincible"})

-- Rank 3 Commands
AddCommand("kick", "Kick a player", {"<player>", "[reason]"}, 3, function(caller, target, ...)
    local reason = table.concat({...}, " ") or "No reason provided"
    local targets = findPlayer(target, caller)
    
    if not targets then notify(caller, "Crumbs Admin", "Player not found.", 3) return end
    if type(targets) ~= "table" then targets = {targets} end
    
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

AddCommand("clear", "Clear workspace parts", {}, 3, function(caller)
    local count = 0
    for _, obj in ipairs(workspace:GetDescendants()) do
        if obj:IsA("BasePart") and not obj:IsDescendantOf(Players) and obj.Name ~= "Baseplate" and not obj:IsA("Terrain") then
            obj:Destroy()
            count = count + 1
        end
    end
    notify(caller, "Crumbs Admin", "Cleared " .. count .. " parts from workspace.", 3)
end, {"clean", "wipe"})

AddCommand("announce", "Make an announcement", {"<message>"}, 3, function(caller, ...)
    local message = table.concat({...}, " ")
    if message == "" then return end
    notifyAll("📢 ANNOUNCEMENT", caller.Name .. ": " .. message, 8)
end, {"say", "broadcast"})

-- Rank 4 Commands
AddCommand("rank", "Set a player's rank", {"<player>", "<rank>"}, 4, function(caller, target, rankNum)
    local targets = findPlayer(target, caller)
    if not targets then notify(caller, "Crumbs Admin", "Player not found.", 3) return end
    
    if type(targets) == "table" then targets = targets[1] end
    
    local newRank = tonumber(rankNum) or 0
    if newRank < 0 or newRank > 4 then
        notify(caller, "Crumbs Admin", "Rank must be between 0 and 4.", 3)
        return
    end
    
    admin.tempRanks[targets.UserId] = newRank
    notify(caller, "Crumbs Admin", "Set " .. targets.Name .. "'s rank to " .. admin.rankNames[newRank], 3)
    notify(targets, "Crumbs Admin", "Your rank has been set to " .. admin.rankNames[newRank], 3)
end, {"setrank"})

AddCommand("save", "Save current location", {"<name>"}, 4, function(caller, ...)
    if not caller.Character or not caller.Character:FindFirstChild("HumanoidRootPart") then
        notify(caller, "Crumbs Admin", "You have no character.", 3)
        return
    end
    
    local name = table.concat({...}, " ")
    if name == "" then return end
    
    admin.savedLocations[name] = {
        cframe = caller.Character.HumanoidRootPart.CFrame,
        savedBy = caller.Name,
        time = os.time()
    }
    
    notify(caller, "Crumbs Admin", "Saved location: " .. name, 3)
end, {"saveloc"})

AddCommand("load", "Load a saved location", {"<name>"}, 4, function(caller, ...)
    local name = table.concat({...}, " ")
    if name == "" then return end
    
    if not admin.savedLocations[name] then
        notify(caller, "Crumbs Admin", "Location not found: " .. name, 3)
        return
    end
    
    if not caller.Character or not caller.Character:FindFirstChild("HumanoidRootPart") then
        notify(caller, "Crumbs Admin", "You have no character.", 3)
        return
    end
    
    caller.Character.HumanoidRootPart.CFrame = admin.savedLocations[name].cframe
    notify(caller, "Crumbs Admin", "Loaded location: " .. name, 3)
end, {"loadloc"})

AddCommand("locations", "List saved locations", {}, 4, function(caller)
    local list = {}
    for name, _ in pairs(admin.savedLocations) do
        table.insert(list, name)
    end
    
    if #list == 0 then
        notify(caller, "Crumbs Admin", "No saved locations.", 3)
    else
        notify(caller, "Crumbs Admin", "Saved locations: " .. table.concat(list, ", "), 5)
    end
end, {"locs"})

AddCommand("shutdown", "Shutdown the server", {"[seconds]"}, 4, function(caller, time)
    local seconds = tonumber(time) or 30
    if seconds < 5 then seconds = 5 end
    if seconds > 60 then seconds = 60 end
    
    notifyAll("⚠️ SERVER SHUTDOWN", "Server shutting down in " .. seconds .. " seconds!", 5)
    
    for i = seconds, 1, -1 do
        if i <= 10 or i % 10 == 0 then
            notifyAll("⚠️ SERVER SHUTDOWN", "Server shutting down in " .. i .. " seconds!", 3)
        end
        task.wait(1)
    end
    
    for _, player in ipairs(Players:GetPlayers()) do
        player:Kick("Server is shutting down.")
    end
    
    task.wait(1)
    game:Shutdown()
end, {"restart", "sd"})

AddCommand("eject", "Unload Crumbs Admin", {}, 4, function(caller)
    notifyAll("Crumbs Admin", "Crumbs Admin shutting down...", 3)
    task.wait(1)
    
    -- Clear all data
    admin.loopKill = {}
    admin.loopPunish = {}
    admin.frozen = {}
    admin.invisible = {}
    admin.muted = {}
    admin.godMode = {}
    admin.running = false
    
    -- Clear GUI
    if admin.currentDashboard and admin.currentDashboard.Parent then
        admin.currentDashboard:Destroy()
        admin.currentDashboard = nil
    end
    
    -- Clear notifications
    for i = #admin.notificationStack, 1, -1 do
        local entry = admin.notificationStack[i]
        if entry and entry.gui and entry.gui.Parent then
            entry.gui:Destroy()
        end
    end
    admin.notificationStack = {}
    
    -- Clear command bar
    local player = Players.LocalPlayer
    if player and player.PlayerGui then
        local cmdBar = player.PlayerGui:FindFirstChild("CmdBarGui")
        if cmdBar then cmdBar:Destroy() end
    end
    
    notify(caller, "Crumbs Admin", "Successfully ejected. Goodbye!", 3)
    task.wait(3)
    
    -- Remove from global
    _G.CrumbsAdmin = nil
end, {"unload", "exit", "quit"})

-- Loop handlers
task.spawn(function()
    admin.running = true
    while admin.running do
        task.wait(0.5)
        
        -- Loop kill handler
        for userId, enabled in pairs(admin.loopKill) do
            if enabled then
                local player = Players:GetPlayerByUserId(userId)
                if player and player.Character then
                    local head = getPlayerHead(player)
                    if head then head:Destroy() end
                end
            end
        end
        
        -- Loop punish handler
        for userId, enabled in pairs(admin.loopPunish) do
            if enabled then
                local player = Players:GetPlayerByUserId(userId)
                if player and player.Character then
                    player.Character:Destroy()
                end
            end
        end
        
        -- God mode handler
        if admin.godMode then
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
        end
    end
end)

-- Initialize
local function initialize()
    local player = Players.LocalPlayer
    if player then
        -- Create GUI
        pcall(createCommandBar)
        
        -- Setup command handler
        pcall(setupCommandHandler)
        
        -- Welcome message
        task.wait(1)
        notify(player, "Crumbs Admin", "Welcome to Crumbs Admin, " .. player.DisplayName .. "!", 5)
        notify(player, "Crumbs Admin", "Press , for command bar | Type " .. admin.config.prefix .. "help for commands", 5)
        
        print("=== Crumbs Admin v3.0 Loaded ===")
        print("Prefix: " .. admin.config.prefix)
        print("Your rank: " .. admin.rankNames[getRank(player)])
        print("================================")
    end
end

-- Handle player added (for server-side)
Players.PlayerAdded:Connect(function(player)
    task.wait(1)
    if player == Players.LocalPlayer then
        initialize()
    else
        -- For other players in server context
        task.spawn(function()
            if getRank(player) > 0 then
                notify(player, "Crumbs Admin", "Welcome! Your rank: " .. admin.rankNames[getRank(player)], 3)
            end
        end)
    end
end)

-- Initialize if we have a local player
if Players.LocalPlayer then
    initialize()
end

-- For server context, also initialize for all current players
for _, player in ipairs(Players:GetPlayers()) do
    if player == Players.LocalPlayer then
        initialize()
    else
        task.spawn(function()
            if getRank(player) > 0 then
                notify(player, "Crumbs Admin", "Crumbs Admin loaded! Your rank: " .. admin.rankNames[getRank(player)], 3)
            end
        end)
    end
end

print("Crumbs Admin v3.0 - Universal Version Loaded")
print("Works in console OR ServerScriptService!")
