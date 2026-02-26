local Players = game:GetService("Players")
local TeleportService = game:GetService("TeleportService")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local TextChatService = game:GetService("TextChatService")
local RunService = game:GetService("RunService")

local AUTHOR_USER_ID = 1027223614

local RANKS = {
    Customer = 0,
    Cashier = 1,
    Baker = 2,
    Manager = 3
}

local PLAYER_RANKS = {
    [1027223614] = RANKS.Manager
}

local COMMAND_PERMISSIONS = {
    rj = RANKS.Customer,
    punish = RANKS.Cashier,
    kill = RANKS.Cashier,
    freeze = RANKS.Cashier,
    noclip = RANKS.Cashier,
    clip = RANKS.Cashier,
    void = RANKS.Cashier,
    skydive = RANKS.Cashier,
    tp = RANKS.Cashier,
    bring = RANKS.Cashier,
    removehats = RANKS.Cashier,
    removearms = RANKS.Cashier,
    removelegs = RANKS.Cashier,
    invisible = RANKS.Cashier,
    visible = RANKS.Cashier,
    loopkill = RANKS.Baker,
    looppunish = RANKS.Baker,
    unloopkill = RANKS.Baker,
    unlooppunish = RANKS.Baker,
    kick = RANKS.Manager,
    ban = RANKS.Manager,
    unban = RANKS.Manager,
    clear = RANKS.Manager,
    shutdown = RANKS.Manager,
    eject = RANKS.Manager,
    rank = RANKS.Manager
}

local COMMAND_ALIASES = {
    lp = "looppunish",
    loopp = "looppunish",
    repeatingpunish = "looppunish",
    unlp = "unlooppunish",
    stoppunish = "unlooppunish",
    endpunish = "unlooppunish",
    p = "punish",
    deletechar = "punish",
    delchar = "punish",
    nc = "noclip",
    ghost = "noclip",
    phase = "noclip",
    wallhack = "noclip",
    c = "clip",
    collide = "clip",
    collision = "clip",
    solid = "clip",
    v = "void",
    underworld = "void",
    voiddrop = "void",
    sky = "skydive",
    fly = "skydive",
    launch = "skydive",
    inv = "invisible",
    hide = "invisible",
    vis = "visible",
    show = "visible",
    reveal = "visible",
    fz = "freeze",
    anchor = "freeze",
    lock = "freeze",
    ufz = "unfreeze",
    unanchor = "unfreeze",
    unlock = "unfreeze",
    k = "kill",
    slay = "kill",
    execute = "kill",
    lk = "loopkill",
    repeatingkill = "loopkill",
    autokill = "loopkill",
    unlk = "unloopkill",
    stopkill = "unloopkill",
    endkill = "unloopkill",
    teleport = "tp",
    goto = "tp",
    moveplayer = "tp",
    b = "bring",
    pull = "bring",
    fetch = "bring",
    removeacc = "removehats",
    deletehats = "removehats",
    rh = "removehats",
    rarms = "removearms",
    deletearms = "removearms",
    armremove = "removearms",
    rlegs = "removelegs",
    deletelegs = "removelegs",
    legremove = "removelegs",
    commands = "cmds",
    help = "cmds",
    menu = "cmds",
    rejoin = "rj",
    reconnect = "rj",
    relog = "rj",
    sd = "shutdown",
    crashserver = "shutdown",
    lagserver = "shutdown",
    unload = "eject",
    exit = "eject",
    quit = "eject",
    disable = "eject"
}

local BANNED_PLAYERS = {}
local LOOP_PUNISH = {}
local LOOP_KILL = {}

local PREFIX = ","

local CHOCOLATE = Color3.fromRGB(74, 49, 28)
local MILK_CHOCOLATE = Color3.fromRGB(111, 78, 55)
local LIGHT_CHOCOLATE = Color3.fromRGB(139, 90, 43)
local COOKIE_DOUGH = Color3.fromRGB(210, 180, 140)
local WHITE = Color3.fromRGB(255, 255, 255)
local OFF_WHITE = Color3.fromRGB(240, 240, 240)

local function getPlayerRank(player)
    if PLAYER_RANKS[player.UserId] then
        return PLAYER_RANKS[player.UserId]
    end
    return RANKS.Customer
end

local function hasPermission(player, commandName)
    local requiredRank = COMMAND_PERMISSIONS[commandName]
    if not requiredRank then return true end
    return getPlayerRank(player) >= requiredRank
end

local function findPlayer(input)
    if not input or input == "" then return nil end
    
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

local function notify(player, title, message, duration)
    local args = {
        [1] = "Notify",
        [2] = {
            Title = title,
            Message = message,
            Duration = duration or 4
        }
    }
    
    local remote = Instance.new("RemoteEvent")
    remote.Name = "NotificationEvent_" .. math.random(1000, 9999)
    remote.Parent = player:FindFirstChild("PlayerGui") or player:WaitForChild("PlayerGui")
    
    local connection
    connection = remote.OnClientEvent:Connect(function()
        remote:Destroy()
        connection:Disconnect()
    end)
    
    remote:FireClient(player, args[2])
end

local function broadcastNotification(title, message, duration)
    for _, player in ipairs(Players:GetPlayers()) do
        notify(player, title, message, duration)
    end
end

local function setupClientGUI(player)
    local screenGui = Instance.new("ScreenGui")
    screenGui.Name = "CmdBarGui"
    screenGui.Parent = player:WaitForChild("PlayerGui")
    screenGui.ResetOnSpawn = false
    screenGui.IgnoreGuiInset = true
    
    local notificationCooldown = {}
    
    local function createNotification(plr, title, message, duration)
        local key = title .. message
        if notificationCooldown[key] and tick() - notificationCooldown[key] < 1 then
            return
        end
        notificationCooldown[key] = tick()
        
        coroutine.wrap(function()
            local PlayerGui = plr:FindFirstChild("PlayerGui")
            if not PlayerGui then return end
            
            duration = duration or 4
            
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
            
            if not _G.LanzyNotifStack then
                _G.LanzyNotifStack = {}
            end
            
            for i = #_G.LanzyNotifStack, 1, -1 do
                if not _G.LanzyNotifStack[i] or not _G.LanzyNotifStack[i].gui or not _G.LanzyNotifStack[i].gui.Parent then
                    table.remove(_G.LanzyNotifStack, i)
                end
            end

            local yOffset = 10
            for _, entry in ipairs(_G.LanzyNotifStack) do
                yOffset = yOffset + entry.height + 6
            end
            
            local ScreenGui = Instance.new("ScreenGui")
            ScreenGui.Name = "LNZNotification_" .. tick()
            ScreenGui.ResetOnSpawn = false
            ScreenGui.Parent = PlayerGui
            
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
            table.insert(_G.LanzyNotifStack, stackEntry)
            
            local closed = false
            
            local function restack()
                local runningOffset = 10
                for _, entry in ipairs(_G.LanzyNotifStack) do
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
                
                for i, entry in ipairs(_G.LanzyNotifStack) do
                    if entry.gui == ScreenGui then
                        table.remove(_G.LanzyNotifStack, i)
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
            
            wait(duration)
            closeNotif()
        end)()
    end

    local commandInfo = {}
    local currentDashboard = nil
    local dragTween = nil

    local function openDashboard(plr, defaultTab)
        defaultTab = defaultTab or "Commands"
        
        local PlayerGui = plr:FindFirstChild("PlayerGui")
        if not PlayerGui then return end
        
        if currentDashboard and currentDashboard.Parent then 
            local mainFrame = currentDashboard:FindFirstChild("MainFrame")
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
            currentDashboard:Destroy()
            currentDashboard = nil
            return
        end
        
        local ScreenGui = Instance.new("ScreenGui")
        ScreenGui.Name = "LanzyDashboard"
        ScreenGui.ResetOnSpawn = false
        ScreenGui.Parent = PlayerGui
        currentDashboard = ScreenGui
        
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
        
        local CommandsContentCorner = Instance.new("UICorner")
        CommandsContentCorner.CornerRadius = UDim.new(0, 8)
        CommandsContentCorner.Parent = CommandsContent
        
        local CommandsLayout = Instance.new("UIListLayout")
        CommandsLayout.Parent = CommandsContent
        CommandsLayout.SortOrder = Enum.SortOrder.LayoutOrder
        CommandsLayout.Padding = UDim.new(0, 5)
        
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
        
        local CreditsContentCorner = Instance.new("UICorner")
        CreditsContentCorner.CornerRadius = UDim.new(0, 8)
        CreditsContentCorner.Parent = CreditsContent
        
        local CreditsLayout = Instance.new("UIListLayout")
        CreditsLayout.Parent = CreditsContent
        CreditsLayout.SortOrder = Enum.SortOrder.LayoutOrder
        CreditsLayout.Padding = UDim.new(0, 10)
        CreditsLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
        
        local CreditTitle = Instance.new("TextLabel")
        CreditTitle.Size = UDim2.new(1, -20, 0, 40)
        CreditTitle.Position = UDim2.new(0, 10, 0, 10)
        CreditTitle.BackgroundTransparency = 1
        CreditTitle.Text = "CREDITS"
        CreditTitle.TextColor3 = COOKIE_DOUGH
        CreditTitle.TextTransparency = 1
        CreditTitle.TextSize = 28
        CreditTitle.Font = Enum.Font.GothamBold
        CreditTitle.TextWrapped = true
        CreditTitle.Parent = CreditsContent
        
        local CreditDivider = Instance.new("Frame")
        CreditDivider.Size = UDim2.new(0.8, 0, 0, 2)
        CreditDivider.Position = UDim2.new(0.1, 0, 0, 55)
        CreditDivider.BackgroundColor3 = COOKIE_DOUGH
        CreditDivider.BackgroundTransparency = 1
        CreditDivider.BorderSizePixel = 0
        CreditDivider.Parent = CreditsContent
        
        local Credits = {
            {role = "Creator", name = "(xXRblxGamerRblxXx (Lanzy)", desc = "Made almost everything in here"},
            {role = "GUI Inspiration", name = "idonthacklol101ns (Master0fSouls)", desc = "Inspired from Sentrius"},
            {role = "Origin", name = "SnowClan_8342 (YeemiRouth)", desc = "Made some of the commands originally"},
            {role = "Version", name = "Crumbs Admin v1.0", desc = "Server-side admin system"},
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
        SpecialThanks.Text = "Enjoy using Crumbs Admin"
        SpecialThanks.TextColor3 = COOKIE_DOUGH
        SpecialThanks.TextTransparency = 1
        SpecialThanks.TextSize = 14
        SpecialThanks.Font = Enum.Font.GothamBold
        SpecialThanks.TextWrapped = true
        SpecialThanks.Parent = CreditsContent
        
        yPos = yPos + 60
        CreditsContent.CanvasSize = UDim2.new(0, 0, 0, yPos + 20)
        
        local sortedCommands = {}
        for cmdName, cmdData in pairs(commandInfo) do
            table.insert(sortedCommands, {name = cmdName, data = cmdData})
        end
        
        table.sort(sortedCommands, function(a, b)
            return a.name < b.name
        end)
        
        for counter, cmdEntry in ipairs(sortedCommands) do
            local cmdData = cmdEntry.data
        
            local CommandFrame = Instance.new("Frame")
            CommandFrame.Name = "Command_" .. cmdData.name
            CommandFrame.Size = UDim2.new(1, -12, 0, 60)
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
            CommandLabel.Text = counter .. " | " .. PREFIX .. cmdData.name
            CommandLabel.TextColor3 = OFF_WHITE
            CommandLabel.TextTransparency = 1
            CommandLabel.TextSize = 15
            CommandLabel.Font = Enum.Font.GothamBold
            CommandLabel.TextXAlignment = Enum.TextXAlignment.Left
            CommandLabel.Parent = CommandFrame
        
            local AliasText = "Aliases: None"
            if cmdData.aliases and #cmdData.aliases > 0 then
                AliasText = "Aliases: {" .. table.concat(cmdData.aliases, ", ") .. "}"
            end
        
            local CommandAlias = Instance.new("TextLabel")
            CommandAlias.Size = UDim2.new(1, -12, 0, 12)
            CommandAlias.Position = UDim2.new(0, 6, 0, 20)
            CommandAlias.BackgroundTransparency = 1
            CommandAlias.Text = AliasText
            CommandAlias.TextColor3 = COOKIE_DOUGH
            CommandAlias.TextTransparency = 1
            CommandAlias.TextSize = 10
            CommandAlias.Font = Enum.Font.Gotham
            CommandAlias.TextXAlignment = Enum.TextXAlignment.Left
            CommandAlias.Parent = CommandFrame
        
            local DescLabel = Instance.new("TextLabel")
            DescLabel.Size = UDim2.new(1, -12, 0, 11)
            DescLabel.Position = UDim2.new(0, 6, 0, 33)
            DescLabel.BackgroundTransparency = 1
            DescLabel.Text = cmdData.desc
            DescLabel.TextColor3 = OFF_WHITE
            DescLabel.TextTransparency = 1
            DescLabel.TextSize = 11
            DescLabel.Font = Enum.Font.Gotham
            DescLabel.TextXAlignment = Enum.TextXAlignment.Left
            DescLabel.Parent = CommandFrame
        
            local UsageLabel = Instance.new("TextLabel")
            UsageLabel.Size = UDim2.new(1, -12, 0, 10)
            UsageLabel.Position = UDim2.new(0, 6, 0, 48)
            UsageLabel.BackgroundTransparency = 1
            UsageLabel.Text = "Usage: " .. cmdData.usage
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
        
        local dragging = false
        local dragStart = nil
        local startPos = nil
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
            
            for _, v in ipairs(ContentFrame:GetDescendants()) do
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
            
            fadeOut1:Play()
            fadeOut2:Play()
            fadeOut3:Play()
            fadeOut4:Play()
            fadeOut5:Play()
            fadeOut6:Play()
            fadeOut7:Play()
            
            task.wait(0.15)
            ScreenGui:Destroy()
            currentDashboard = nil
        end)
        
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
        for _, cmdEntry in ipairs(sortedCommands) do
            local cmdFrame = CommandsContent:FindFirstChild("Command_" .. cmdEntry.data.name)
            if cmdFrame then
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
            end
            task.wait(0.03)
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

    local function toggleTextBox()
        if cmdBarFrame.Visible then
            animateTextBox(false)
        else
            animateTextBox(true)
        end
    end

    UserInputService.InputBegan:Connect(function(input, gameProcessed)
        if not gameProcessed and input.UserInputType == Enum.UserInputType.Keyboard and input.KeyCode == Enum.KeyCode.Comma then
            toggleTextBox()
        end
    end)

    cmdBarTextBox.FocusLost:Connect(function(enterPressed)
        if enterPressed then
            local commandText = cmdBarTextBox.Text
            cmdBarTextBox.Text = ""
            animateTextBox(false)
            
            local remoteEvent = Instance.new("RemoteEvent")
            remoteEvent.Name = "CommandEvent_" .. math.random(1000, 9999)
            remoteEvent.Parent = player:FindFirstChild("PlayerGui") or player.PlayerGui
            
            local connection
            connection = remoteEvent.OnClientEvent:Connect(function()
                remoteEvent:Destroy()
                connection:Disconnect()
            end)
            
            remoteEvent:FireServer(commandText)
        else
            animateTextBox(false)
        end
    end)

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

    createNotification(player, "Crumbs Admin", "Click , for command bar | Type ,cmds to get started.", 5)
    createNotification(player, "Crumbs Admin", "Welcome to Crumbs Admin, "..player.DisplayName..".", 5)

    for cmdName, cmdData in pairs(COMMAND_PERMISSIONS) do
        local rankName = "Customer"
        if cmdData == 1 then rankName = "Cashier"
        elseif cmdData == 2 then rankName = "Baker"
        elseif cmdData == 3 then rankName = "Manager"
        end
        
        local aliases = {}
        for alias, realCmd in pairs(COMMAND_ALIASES) do
            if realCmd == cmdName then
                table.insert(aliases, alias)
            end
        end
        
        commandInfo[cmdName] = {
            name = cmdName,
            aliases = aliases,
            desc = "Requires rank: " .. rankName,
            usage = PREFIX .. cmdName .. " <player>"
        }
    end

    commandInfo["cmds"] = {
        name = "cmds",
        aliases = {"commands", "help", "menu"},
        desc = "Open the commands menu",
        usage = PREFIX .. "cmds"
    }

    commandInfo["rank"] = {
        name = "rank",
        aliases = {},
        desc = "Rank a player (Manager only)",
        usage = PREFIX .. "rank <player> <rank>"
    }

    commandInfo["rj"] = {
        name = "rj",
        aliases = {"rejoin", "reconnect", "relog"},
        desc = "Rejoin the server",
        usage = PREFIX .. "rj"
    }

    local remoteEvent = Instance.new("RemoteEvent")
    remoteEvent.Name = "CommandProcessor"
    remoteEvent.Parent = player:FindFirstChild("PlayerGui") or player.PlayerGui
    
    remoteEvent.OnClientEvent:Connect(function(commandText)
        processCommand(player, commandText)
    end)
end

local function getPlayerRank(player)
    if PLAYER_RANKS[player.UserId] then
        return PLAYER_RANKS[player.UserId]
    end
    return RANKS.Customer
end

local function hasPermission(player, commandName)
    local requiredRank = COMMAND_PERMISSIONS[commandName]
    if not requiredRank then return true end
    return getPlayerRank(player) >= requiredRank
end

local function findPlayer(input)
    if not input or input == "" then return nil end
    
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

local function notify(player, title, message, duration)
    local args = {
        Title = title,
        Message = message,
        Duration = duration or 4
    }
    
    local remote = Instance.new("RemoteEvent")
    remote.Name = "NotificationEvent_" .. math.random(1000, 9999)
    remote.Parent = player:FindFirstChild("PlayerGui") or player:WaitForChild("PlayerGui")
    
    local connection
    connection = remote.OnClientEvent:Connect(function()
        remote:Destroy()
        connection:Disconnect()
    end)
    
    remote:FireClient(player, args)
end

local function broadcastNotification(title, message, duration)
    for _, player in ipairs(Players:GetPlayers()) do
        notify(player, title, message, duration)
    end
end

local function processCommand(player, commandText)
    if string.sub(commandText, 1, 1) == PREFIX then
        commandText = string.sub(commandText, 2)
    end
    
    if commandText == "" then return end
    
    local commandSplit = string.split(commandText, " ")
    local cmdName = string.lower(table.remove(commandSplit, 1))
    
    local realCommandName = COMMAND_ALIASES[cmdName] or cmdName
    
    if not COMMAND_PERMISSIONS[realCommandName] and realCommandName ~= "cmds" and realCommandName ~= "rank" then
        return
    end
    
    if not hasPermission(player, realCommandName) and realCommandName ~= "cmds" and realCommandName ~= "rank" then
        notify(player, "Crumbs Admin", "You don't have permission to use this command.", 5)
        return
    end
    
    if realCommandName == "cmds" then
        setupClientGUI(player)
        return
    end
    
    if realCommandName == "rank" then
        if not hasPermission(player, "rank") then
            notify(player, "Crumbs Admin", "You don't have permission to rank players.", 5)
            return
        end
        
        local targetName = commandSplit[1]
        local rankInput = commandSplit[2]
        
        if not targetName or not rankInput then
            notify(player, "Crumbs Admin", "Usage: ,rank <player> <rank number or name>", 5)
            return
        end
        
        local targetPlayer = findPlayer(targetName)
        if not targetPlayer then
            notify(player, "Crumbs Admin", "Player not found.", 5)
            return
        end
        
        local rankValue = tonumber(rankInput)
        if not rankValue then
            local rankLower = string.lower(rankInput)
            if rankLower == "customer" then rankValue = 0
            elseif rankLower == "cashier" then rankValue = 1
            elseif rankLower == "baker" then rankValue = 2
            elseif rankLower == "manager" then rankValue = 3
            else
                notify(player, "Crumbs Admin", "Invalid rank. Use 0-3 or Customer/Cashier/Baker/Manager", 5)
                return
            end
        end
        
        if rankValue < 0 or rankValue > 3 then
            notify(player, "Crumbs Admin", "Rank must be between 0 and 3.", 5)
            return
        end
        
        PLAYER_RANKS[targetPlayer.UserId] = rankValue
        notify(player, "Crumbs Admin", string.format("%s has been ranked as %s", targetPlayer.Name, 
               (rankValue == 0 and "Customer" or rankValue == 1 and "Cashier" or rankValue == 2 and "Baker" or "Manager")), 5)
        notify(targetPlayer, "Crumbs Admin", string.format("You have been ranked as %s", 
               (rankValue == 0 and "Customer" or rankValue == 1 and "Cashier" or rankValue == 2 and "Baker" or "Manager")), 5)
        return
    end
    
    if realCommandName == "rj" then
        task.wait(0.5)
        TeleportService:TeleportToPlaceInstance(game.PlaceId, game.JobId, player)
        return
    end
    
    if realCommandName == "kick" then
        local targetName = commandSplit[1]
        table.remove(commandSplit, 1)
        local reason = table.concat(commandSplit, " ")
        if reason == "" then reason = "No reason provided" end
        
        if not targetName then
            notify(player, "Crumbs Admin", "Usage: ,kick <player> [reason]", 5)
            return
        end
        
        local targetPlayer = findPlayer(targetName)
        if not targetPlayer then
            notify(player, "Crumbs Admin", "Player not found.", 5)
            return
        end
        
        if targetPlayer.UserId == AUTHOR_USER_ID then
            notify(player, "Crumbs Admin", "You cannot kick the author.", 5)
            return
        end
        
        task.wait(0.1)
        targetPlayer:Kick(string.format("Kicked by %s\nReason: %s", player.Name, reason))
        return
    end
    
    if realCommandName == "ban" then
        local targetName = commandSplit[1]
        table.remove(commandSplit, 1)
        local reason = table.concat(commandSplit, " ")
        if reason == "" then reason = "No reason provided" end
        
        if not targetName then
            notify(player, "Crumbs Admin", "Usage: ,ban <player> [reason]", 5)
            return
        end
        
        local targetPlayer = findPlayer(targetName)
        if not targetPlayer then
            notify(player, "Crumbs Admin", "Player not found.", 5)
            return
        end
        
        if targetPlayer.UserId == AUTHOR_USER_ID then
            notify(player, "Crumbs Admin", "You cannot ban the author.", 5)
            return
        end
        
        BANNED_PLAYERS[targetPlayer.UserId] = {
            Banner = player.Name,
            Reason = reason,
            Time = os.time()
        }
        
        task.wait(0.1)
        targetPlayer:Kick(string.format("Banned by %s\nReason: %s", player.Name, reason))
        return
    end
    
    if realCommandName == "unban" then
        local targetName = commandSplit[1]
        
        if not targetName then
            notify(player, "Crumbs Admin", "Usage: ,unban <username>", 5)
            return
        end
        
        local userId = nil
        for id, _ in pairs(BANNED_PLAYERS) do
            userId = id
            break
        end
        
        if userId then
            BANNED_PLAYERS[userId] = nil
            notify(player, "Crumbs Admin", "User has been unbanned.", 5)
        else
            notify(player, "Crumbs Admin", "No banned users found.", 5)
        end
        return
    end
    
    if realCommandName == "shutdown" then
        broadcastNotification("Crumbs Admin", "Server shutting down...", 5)
        task.wait(5)
        for _, p in ipairs(Players:GetPlayers()) do
            p:Kick("Server shutdown by " .. player.Name)
        end
        return
    end
    
    if realCommandName == "eject" then
        script:Destroy()
        return
    end
    
    local function getTargets(input)
        if input == "all" then
            local targets = {}
            for _, p in ipairs(Players:GetPlayers()) do
                if p ~= player then
                    table.insert(targets, p)
                end
            end
            return targets
        elseif input == "others" then
            local targets = {}
            for _, p in ipairs(Players:GetPlayers()) do
                if p ~= player then
                    table.insert(targets, p)
                end
            end
            return targets
        elseif input == "random" then
            local available = {}
            for _, p in ipairs(Players:GetPlayers()) do
                if p ~= player then
                    table.insert(available, p)
                end
            end
            if #available > 0 then
                return {available[math.random(1, #available)]}
            end
            return {}
        else
            local target = findPlayer(input)
            return target and {target} or {}
        end
    end
    
    if string.find(commandText, ",") then
        local targetsString = commandSplit[1]
        table.remove(commandSplit, 1)
        local args = commandSplit
        
        local targetNames = string.split(targetsString, ",")
        for _, name in ipairs(targetNames) do
            name = name:gsub("^%s+", ""):gsub("%s+$", "")
            local targets = getTargets(name)
            for _, targetPlayer in ipairs(targets) do
                pcall(function()
                    if realCommandName == "punish" and targetPlayer.Character then
                        targetPlayer.Character:BreakJoints()
                    elseif realCommandName == "kill" and targetPlayer.Character and targetPlayer.Character:FindFirstChild("Head") then
                        targetPlayer.Character.Head:Destroy()
                    elseif realCommandName == "freeze" and targetPlayer.Character then
                        for _, part in ipairs(targetPlayer.Character:GetDescendants()) do
                            if part:IsA("BasePart") then
                                part.Anchored = true
                            end
                        end
                    elseif realCommandName == "unfreeze" and targetPlayer.Character then
                        for _, part in ipairs(targetPlayer.Character:GetDescendants()) do
                            if part:IsA("BasePart") then
                                part.Anchored = false
                            end
                        end
                    elseif realCommandName == "noclip" and targetPlayer.Character then
                        for _, part in ipairs(targetPlayer.Character:GetDescendants()) do
                            if part:IsA("BasePart") then
                                part.CanCollide = false
                            end
                        end
                    elseif realCommandName == "clip" and targetPlayer.Character then
                        for _, part in ipairs(targetPlayer.Character:GetDescendants()) do
                            if part:IsA("BasePart") then
                                part.CanCollide = true
                            end
                        end
                    elseif realCommandName == "void" and targetPlayer.Character and targetPlayer.Character:FindFirstChild("HumanoidRootPart") then
                        targetPlayer.Character.HumanoidRootPart.CFrame = CFrame.new(targetPlayer.Character.HumanoidRootPart.Position.X, -5000, targetPlayer.Character.HumanoidRootPart.Position.Z)
                    elseif realCommandName == "skydive" and targetPlayer.Character and targetPlayer.Character:FindFirstChild("HumanoidRootPart") then
                        local height = tonumber(args[2]) or 1000
                        targetPlayer.Character.HumanoidRootPart.CFrame = CFrame.new(targetPlayer.Character.HumanoidRootPart.Position.X, height, targetPlayer.Character.HumanoidRootPart.Position.Z)
                    elseif realCommandName == "tp" and targetPlayer.Character and targetPlayer.Character:FindFirstChild("HumanoidRootPart") then
                        local destName = args[2]
                        if not destName then return end
                        local destPlayer = destName == "me" and player or findPlayer(destName)
                        if destPlayer and destPlayer.Character and destPlayer.Character:FindFirstChild("HumanoidRootPart") then
                            targetPlayer.Character.HumanoidRootPart.CFrame = destPlayer.Character.HumanoidRootPart.CFrame * CFrame.new(0, 0, -5)
                        end
                    elseif realCommandName == "bring" and targetPlayer.Character and targetPlayer.Character:FindFirstChild("HumanoidRootPart") and player.Character and player.Character:FindFirstChild("HumanoidRootPart") then
                        targetPlayer.Character.HumanoidRootPart.CFrame = player.Character.HumanoidRootPart.CFrame * CFrame.new(0, 0, -5)
                    elseif realCommandName == "removehats" and targetPlayer.Character then
                        for _, obj in ipairs(targetPlayer.Character:GetDescendants()) do
                            if obj:IsA("Accessory") then
                                obj:Destroy()
                            end
                        end
                    elseif realCommandName == "removearms" and targetPlayer.Character then
                        local armNames = {"Left Arm", "Right Arm", "LeftHand", "RightHand", "LeftLowerArm", "RightLowerArm", "LeftUpperArm", "RightUpperArm"}
                        for _, part in ipairs(targetPlayer.Character:GetDescendants()) do
                            if part:IsA("BasePart") and table.find(armNames, part.Name) then
                                part:Destroy()
                            end
                        end
                    elseif realCommandName == "removelegs" and targetPlayer.Character then
                        local legNames = {"Left Leg", "Right Leg", "LeftFoot", "RightFoot", "LeftLowerLeg", "RightLowerLeg", "LeftUpperLeg", "RightUpperLeg"}
                        for _, part in ipairs(targetPlayer.Character:GetDescendants()) do
                            if part:IsA("BasePart") and table.find(legNames, part.Name) then
                                part:Destroy()
                            end
                        end
                    elseif realCommandName == "invisible" and targetPlayer.Character then
                        for _, part in ipairs(targetPlayer.Character:GetDescendants()) do
                            if part:IsA("BasePart") then
                                part.Transparency = 1
                            end
                        end
                    elseif realCommandName == "visible" and targetPlayer.Character then
                        for _, part in ipairs(targetPlayer.Character:GetDescendants()) do
                            if part:IsA("BasePart") then
                                part.Transparency = 0
                            end
                        end
                    elseif realCommandName == "loopkill" then
                        LOOP_KILL[targetPlayer.UserId] = true
                        task.spawn(function()
                            while LOOP_KILL[targetPlayer.UserId] do
                                if targetPlayer.Character and targetPlayer.Character:FindFirstChild("Head") then
                                    targetPlayer.Character.Head:Destroy()
                                end
                                task.wait(0.5)
                            end
                        end)
                    elseif realCommandName == "unloopkill" then
                        LOOP_KILL[targetPlayer.UserId] = nil
                    elseif realCommandName == "looppunish" then
                        LOOP_PUNISH[targetPlayer.UserId] = true
                        task.spawn(function()
                            while LOOP_PUNISH[targetPlayer.UserId] do
                                if targetPlayer.Character then
                                    targetPlayer.Character:BreakJoints()
                                end
                                task.wait(0.5)
                            end
                        end)
                    elseif realCommandName == "unlooppunish" then
                        LOOP_PUNISH[targetPlayer.UserId] = nil
                    end
                end)
                task.wait(0.05)
            end
        end
    else
        if #commandSplit == 0 then
            notify(player, "Crumbs Admin", "Invalid command usage.", 5)
            return
        end
        
        local targetName = commandSplit[1]
        local targets = getTargets(targetName)
        
        for _, targetPlayer in ipairs(targets) do
            pcall(function()
                if realCommandName == "punish" and targetPlayer.Character then
                    targetPlayer.Character:BreakJoints()
                elseif realCommandName == "kill" and targetPlayer.Character and targetPlayer.Character:FindFirstChild("Head") then
                    targetPlayer.Character.Head:Destroy()
                elseif realCommandName == "freeze" and targetPlayer.Character then
                    for _, part in ipairs(targetPlayer.Character:GetDescendants()) do
                        if part:IsA("BasePart") then
                            part.Anchored = true
                        end
                    end
                elseif realCommandName == "unfreeze" and targetPlayer.Character then
                    for _, part in ipairs(targetPlayer.Character:GetDescendants()) do
                        if part:IsA("BasePart") then
                            part.Anchored = false
                        end
                    end
                elseif realCommandName == "noclip" and targetPlayer.Character then
                    for _, part in ipairs(targetPlayer.Character:GetDescendants()) do
                        if part:IsA("BasePart") then
                            part.CanCollide = false
                        end
                    end
                elseif realCommandName == "clip" and targetPlayer.Character then
                    for _, part in ipairs(targetPlayer.Character:GetDescendants()) do
                        if part:IsA("BasePart") then
                            part.CanCollide = true
                        end
                    end
                elseif realCommandName == "void" and targetPlayer.Character and targetPlayer.Character:FindFirstChild("HumanoidRootPart") then
                    targetPlayer.Character.HumanoidRootPart.CFrame = CFrame.new(targetPlayer.Character.HumanoidRootPart.Position.X, -5000, targetPlayer.Character.HumanoidRootPart.Position.Z)
                elseif realCommandName == "skydive" and targetPlayer.Character and targetPlayer.Character:FindFirstChild("HumanoidRootPart") then
                    local height = tonumber(commandSplit[2]) or 1000
                    targetPlayer.Character.HumanoidRootPart.CFrame = CFrame.new(targetPlayer.Character.HumanoidRootPart.Position.X, height, targetPlayer.Character.HumanoidRootPart.Position.Z)
                elseif realCommandName == "invisible" and targetPlayer.Character then
                    for _, part in ipairs(targetPlayer.Character:GetDescendants()) do
                        if part:IsA("BasePart") then
                            part.Transparency = 1
                        end
                    end
                elseif realCommandName == "visible" and targetPlayer.Character then
                    for _, part in ipairs(targetPlayer.Character:GetDescendants()) do
                        if part:IsA("BasePart") then
                            part.Transparency = 0
                        end
                    end
                elseif realCommandName == "removehats" and targetPlayer.Character then
                    for _, obj in ipairs(targetPlayer.Character:GetDescendants()) do
                        if obj:IsA("Accessory") then
                            obj:Destroy()
                        end
                    end
                elseif realCommandName == "removearms" and targetPlayer.Character then
                    local armNames = {"Left Arm", "Right Arm", "LeftHand", "RightHand", "LeftLowerArm", "RightLowerArm", "LeftUpperArm", "RightUpperArm"}
                    for _, part in ipairs(targetPlayer.Character:GetDescendants()) do
                        if part:IsA("BasePart") and table.find(armNames, part.Name) then
                            part:Destroy()
                        end
                    end
                elseif realCommandName == "removelegs" and targetPlayer.Character then
                    local legNames = {"Left Leg", "Right Leg", "LeftFoot", "RightFoot", "LeftLowerLeg", "RightLowerLeg", "LeftUpperLeg", "RightUpperLeg"}
                    for _, part in ipairs(targetPlayer.Character:GetDescendants()) do
                        if part:IsA("BasePart") and table.find(legNames, part.Name) then
                            part:Destroy()
                        end
                    end
                elseif realCommandName == "loopkill" then
                    LOOP_KILL[targetPlayer.UserId] = true
                    task.spawn(function()
                        while LOOP_KILL[targetPlayer.UserId] do
                            if targetPlayer.Character and targetPlayer.Character:FindFirstChild("Head") then
                                targetPlayer.Character.Head:Destroy()
                            end
                            task.wait(0.5)
                        end
                    end)
                elseif realCommandName == "unloopkill" then
                    LOOP_KILL[targetPlayer.UserId] = nil
                elseif realCommandName == "looppunish" then
                    LOOP_PUNISH[targetPlayer.UserId] = true
                    task.spawn(function()
                        while LOOP_PUNISH[targetPlayer.UserId] do
                            if targetPlayer.Character then
                                targetPlayer.Character:BreakJoints()
                            end
                            task.wait(0.5)
                        end
                    end)
                elseif realCommandName == "unlooppunish" then
                    LOOP_PUNISH[targetPlayer.UserId] = nil
                end
            end)
        end
        
        if realCommandName == "clear" then
            for _, obj in ipairs(workspace:GetDescendants()) do
                if obj:IsA("BasePart") and obj.Parent ~= player.Character then
                    obj:Destroy()
                end
            end
            notify(player, "Crumbs Admin", "Workspace cleared.", 5)
        end
    end
end

local function onPlayerAdded(player)
    if BANNED_PLAYERS[player.UserId] then
        local banInfo = BANNED_PLAYERS[player.UserId]
        player:Kick(string.format("You are banned.\nBanned by: %s\nReason: %s", banInfo.Banner, banInfo.Reason))
        return
    end
    
    local remoteEvent = Instance.new("RemoteEvent")
    remoteEvent.Name = "CommandProcessor"
    remoteEvent.Parent = player:WaitForChild("PlayerGui")
    
    remoteEvent.OnServerEvent:Connect(function(plr, commandText)
        if plr ~= player then return end
        processCommand(plr, commandText)
    end)
    
    player.Chatted:Connect(function(message)
        if string.sub(message, 1, 1) == PREFIX then
            processCommand(player, message)
        end
    end)
end

for _, player in ipairs(Players:GetPlayers()) do
    onPlayerAdded(player)
end

Players.PlayerAdded:Connect(onPlayerAdded)

Players.PlayerRemoving:Connect(function(player)
    LOOP_KILL[player.UserId] = nil
    LOOP_PUNISH[player.UserId] = nil
end)

broadcastNotification("Crumbs Admin", "Tadaaa!! /nCrumbs Admin has loaded successfully!! :3", 5)
