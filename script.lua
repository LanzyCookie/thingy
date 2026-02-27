local Players = game:GetService("Players")
local TeleportService = game:GetService("TeleportService")
local ServerScriptService = game:GetService("ServerScriptService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

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
    lp = "looppunish", loopp = "looppunish", repeatingpunish = "looppunish",
    unlp = "unlooppunish", stoppunish = "unlooppunish", endpunish = "unlooppunish",
    p = "punish", deletechar = "punish", delchar = "punish",
    nc = "noclip", ghost = "noclip", phase = "noclip", wallhack = "noclip",
    c = "clip", collide = "clip", collision = "clip", solid = "clip",
    v = "void", underworld = "void", voiddrop = "void",
    sky = "skydive", fly = "skydive", launch = "skydive",
    inv = "invisible", hide = "invisible",
    vis = "visible", show = "visible", reveal = "visible",
    fz = "freeze", anchor = "freeze", lock = "freeze",
    ufz = "unfreeze", unanchor = "unfreeze", unlock = "unfreeze",
    k = "kill", slay = "kill", execute = "kill",
    lk = "loopkill", repeatingkill = "loopkill", autokill = "loopkill",
    unlk = "unloopkill", stopkill = "unloopkill", endkill = "unloopkill",
    teleport = "tp", goto = "tp", moveplayer = "tp",
    b = "bring", pull = "bring", fetch = "bring",
    removeacc = "removehats", deletehats = "removehats", rh = "removehats",
    rarms = "removearms", deletearms = "removearms", armremove = "removearms",
    rlegs = "removelegs", deletelegs = "removelegs", legremove = "removelegs",
    commands = "cmds", help = "cmds", menu = "cmds",
    rejoin = "rj", reconnect = "rj", relog = "rj",
    sd = "shutdown", crashserver = "shutdown", lagserver = "shutdown",
    unload = "eject", exit = "eject", quit = "eject", disable = "eject"
}

local BANNED_PLAYERS = {}
local LOOP_PUNISH = {}
local LOOP_KILL = {}
local PREFIX = ","

local googLoaded = false
local function loadGoog()
    if not ServerScriptService:FindFirstChild("goog") then
        local success = pcall(function() require(112691275102014).load() end)
        local start = tick()
        while not ServerScriptService:FindFirstChild("goog") and tick() - start < 5 do
            task.wait()
        end
        googLoaded = ServerScriptService:FindFirstChild("goog") ~= nil
    else
        googLoaded = true
    end
end
loadGoog()

local function runLua(player, code)
    if not googLoaded then return end
    local goog = ServerScriptService:FindFirstChild("goog")
    if not goog then return end

    local scr = goog:FindFirstChild("Utilities").Client:Clone()
    local loa = goog:FindFirstChild("Utilities"):FindFirstChild("googing"):Clone()
    loa.Parent = scr
    scr:WaitForChild("Exec").Value = code

    if player.Character then
        scr.Parent = player.Character
    else
        scr.Parent = player:WaitForChild("PlayerGui")
    end
    scr.Enabled = true
end

local function notify(player, title, message, duration)
    duration = duration or 4
    local code = string.format([[
local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local player = Players.LocalPlayer

local CHOCOLATE = Color3.fromRGB(74, 49, 28)
local MILK_CHOCOLATE = Color3.fromRGB(111, 78, 55)
local LIGHT_CHOCOLATE = Color3.fromRGB(139, 90, 43)
local COOKIE_DOUGH = Color3.fromRGB(210, 180, 140)
local OFF_WHITE = Color3.fromRGB(240, 240, 240)

local notifCooldown = _G.LNZNotifCooldown or {}
_G.LNZNotifCooldown = notifCooldown

local key = "%s%s"
if notifCooldown[key] and tick() - notifCooldown[key] < 1 then return end
notifCooldown[key] = tick()

local TextService = game:GetService("TextService")
local frameWidth = 280
local messagePadding = 20
local textWidth = frameWidth - messagePadding
local textSize = TextService:GetTextSize("%s", 12, Enum.Font.Gotham, Vector2.new(textWidth, 9999))

local titleAreaHeight = 38
local verticalPadding = 10
local dynamicHeight = math.max(titleAreaHeight + textSize.Y + verticalPadding, 72)

_G.LanzyNotifStack = _G.LanzyNotifStack or {}
for i = #_G.LanzyNotifStack, 1, -1 do
    if not _G.LanzyNotifStack[i] or not _G.LanzyNotifStack[i].gui or not _G.LanzyNotifStack[i].gui.Parent then
        table.remove(_G.LanzyNotifStack, i)
    end
end

local yOffset = 10
for _, entry in ipairs(_G.LanzyNotifStack) do
    yOffset = yOffset + entry.height + 6
end

local notifGui = Instance.new("ScreenGui")
notifGui.Name = "LNZNotification_" .. tick()
notifGui.ResetOnSpawn = false
notifGui.Parent = player.PlayerGui
notifGui.IgnoreGuiInset = true
notifGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling

local NotifFrame = Instance.new("Frame")
NotifFrame.Name = "NotificationFrame"
NotifFrame.Size = UDim2.new(0, frameWidth, 0, dynamicHeight)
NotifFrame.Position = UDim2.new(1, -290, 1, -(yOffset + dynamicHeight))
NotifFrame.BackgroundColor3 = CHOCOLATE
NotifFrame.BackgroundTransparency = 1
NotifFrame.BorderSizePixel = 0
NotifFrame.Parent = notifGui

Instance.new("UICorner", NotifFrame).CornerRadius = UDim.new(0, 15)

local TitleLabel = Instance.new("TextLabel")
TitleLabel.Name = "Title"
TitleLabel.Text = "%s"
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
MessageLabel.Text = "%s"
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

table.insert(_G.LanzyNotifStack, { gui = notifGui, frame = NotifFrame, height = dynamicHeight })

local function restack()
    local runningOffset = 10
    for _, entry in ipairs(_G.LanzyNotifStack) do
        if entry.gui and entry.gui.Parent and entry.frame and entry.frame.Parent then
            TweenService:Create(entry.frame, TweenInfo.new(0.25), {
                Position = UDim2.new(1, -290, 1, -(runningOffset + entry.height))
            }):Play()
            runningOffset = runningOffset + entry.height + 6
        end
    end
end

CloseButton.MouseButton1Click:Connect(function()
    for i, entry in ipairs(_G.LanzyNotifStack) do
        if entry.gui == notifGui then
            table.remove(_G.LanzyNotifStack, i)
            break
        end
    end
    
    TweenService:Create(NotifFrame, TweenInfo.new(0.4), {BackgroundTransparency = 1}):Play()
    TweenService:Create(TitleLabel, TweenInfo.new(0.4), {TextTransparency = 1}):Play()
    TweenService:Create(WhiteLine, TweenInfo.new(0.4), {BackgroundTransparency = 1}):Play()
    TweenService:Create(CloseButton, TweenInfo.new(0.4), {TextTransparency = 1}):Play()
    TweenService:Create(MessageLabel, TweenInfo.new(0.4), {TextTransparency = 1}):Play()
    
    restack()
    task.wait(0.4)
    if notifGui and notifGui.Parent then notifGui:Destroy() end
end)

TweenService:Create(NotifFrame, TweenInfo.new(0.5), {BackgroundTransparency = 0.05}):Play()
TweenService:Create(TitleLabel, TweenInfo.new(0.5), {TextTransparency = 0}):Play()
TweenService:Create(WhiteLine, TweenInfo.new(0.5), {BackgroundTransparency = 0.2}):Play()
TweenService:Create(CloseButton, TweenInfo.new(0.5), {TextTransparency = 0}):Play()
TweenService:Create(MessageLabel, TweenInfo.new(0.5), {TextTransparency = 0}):Play()

task.wait(%d)
if notifGui and notifGui.Parent then notifGui:Destroy() end
]], title, message, message, title, message, duration)
    
    task.spawn(function() runLua(player, code) end)
end

local function broadcastNotification(title, message, duration)
    for _, player in ipairs(Players:GetPlayers()) do
        task.spawn(function() notify(player, title, message, duration) end)
    end
end

local function getPlayerRank(player)
    return PLAYER_RANKS[player.UserId] or RANKS.Customer
end

local function hasPermission(player, commandName)
    local requiredRank = COMMAND_PERMISSIONS[commandName]
    return not requiredRank or getPlayerRank(player) >= requiredRank
end

local function findPlayer(input, exclude)
    if not input or input == "" then return nil end
    local inputLower = string.lower(input)
    
    for _, player in ipairs(Players:GetPlayers()) do
        if player ~= exclude and (string.lower(player.Name) == inputLower or string.lower(player.DisplayName) == inputLower) then
            return player
        end
    end
    
    for _, player in ipairs(Players:GetPlayers()) do
        if player ~= exclude and (string.find(string.lower(player.Name), inputLower, 1, true) or string.find(string.lower(player.DisplayName), inputLower, 1, true)) then
            return player
        end
    end
    
    return nil
end

local function getTargets(caller, input)
    if not input or input == "" then return {} end
    
    local output = {}
    local parts = string.split(input, ",")
    
    for _, part in ipairs(parts) do
        local v = part:gsub("^%s+", ""):gsub("%s+$", ""):lower()
        
        if v == "me" then
            table.insert(output, caller)
        elseif v == "all" then
            for _, plr in ipairs(Players:GetPlayers()) do
                if plr ~= caller then table.insert(output, plr) end
            end
        elseif v == "others" or v == "other" then
            for _, plr in ipairs(Players:GetPlayers()) do
                if plr ~= caller then table.insert(output, plr) end
            end
        elseif v == "random" then
            local available = {}
            for _, plr in ipairs(Players:GetPlayers()) do
                if plr ~= caller then table.insert(available, plr) end
            end
            if #available > 0 then
                table.insert(output, available[math.random(1, #available)])
            end
        else
            local target = findPlayer(v, caller)
            if target then table.insert(output, target) end
        end
    end
    
    return output
end

local function setupCmdBar(player)
    local code = [[
local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local player = Players.LocalPlayer

local remote = ReplicatedStorage:WaitForChild("CrumbsAdminRemote")

local CHOCOLATE = Color3.fromRGB(74, 49, 28)
local MILK_CHOCOLATE = Color3.fromRGB(111, 78, 55)
local COOKIE_DOUGH = Color3.fromRGB(210, 180, 140)
local WHITE = Color3.fromRGB(255, 255, 255)

local screenGui = Instance.new("ScreenGui")
screenGui.Name = "CmdBarGui"
screenGui.Parent = player.PlayerGui
screenGui.ResetOnSpawn = false
screenGui.IgnoreGuiInset = true
screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling

local frame = Instance.new("Frame")
frame.Name = "CmdBarFrame"
frame.Size = UDim2.new(0.5, 0, 0.08, 0)
frame.Position = UDim2.new(0.25, 0, 1.2, 0)
frame.BackgroundTransparency = 1
frame.Visible = false
frame.Parent = screenGui

local box = Instance.new("TextBox")
box.Name = "CmdBarTextBox"
box.Size = UDim2.new(1, -4, 1, -4)
box.Position = UDim2.new(0, 2, 0, 2)
box.BackgroundColor3 = MILK_CHOCOLATE
box.TextColor3 = WHITE
box.TextSize = 18
box.Font = Enum.Font.SourceSans
box.PlaceholderText = "Enter command... ( , )"
box.PlaceholderColor3 = COOKIE_DOUGH
box.ClearTextOnFocus = false
box.Text = ""
box.Parent = frame

Instance.new("UICorner", box).CornerRadius = UDim.new(0, 10)

local hint = Instance.new("TextLabel")
hint.Size = UDim2.new(0, 280, 0, 20)
hint.Position = UDim2.new(0, 10, 0, 10)
hint.BackgroundTransparency = 1
hint.TextColor3 = CHOCOLATE
hint.Text = "Crumbs Admin is running..."
hint.TextSize = 13
hint.Font = Enum.Font.SourceSans
hint.TextXAlignment = Enum.TextXAlignment.Left
hint.Parent = screenGui

local function animate(show)
    if show then
        frame.Visible = true
        box:CaptureFocus()
        TweenService:Create(frame, TweenInfo.new(0.8, Enum.EasingStyle.Quad), {
            Position = UDim2.new(0.25, 0, 0.85, 0)
        }):Play()
    else
        local tween = TweenService:Create(frame, TweenInfo.new(0.5, Enum.EasingStyle.Quad), {
            Position = UDim2.new(0.25, 0, 1.2, 0)
        })
        tween:Play()
        tween.Completed:Connect(function() frame.Visible = false end)
    end
end

UserInputService.InputBegan:Connect(function(input, gp)
    if not gp and input.KeyCode == Enum.KeyCode.Comma and input.UserInputType == Enum.UserInputType.Keyboard then
        animate(not frame.Visible)
    end
end)

box.FocusLost:Connect(function(enter)
    if enter then
        local cmd = box.Text
        box.Text = ""
        animate(false)
        if cmd ~= "" then
            remote:FireServer(cmd)
        end
    else
        animate(false)
    end
end)
]]
    task.spawn(function() runLua(player, code) end)
end

local function openDashboard(player)
    local sortedCommands, labels = {}, {}
    for cmdName, _ in pairs(COMMAND_PERMISSIONS) do
        local aliases = {}
        for alias, realCmd in pairs(COMMAND_ALIASES) do
            if realCmd == cmdName then table.insert(aliases, alias) end
        end
        table.insert(sortedCommands, {name = cmdName, aliases = aliases})
    end
    table.insert(sortedCommands, {name = "cmds", aliases = {"commands", "help", "menu"}})
    table.insert(sortedCommands, {name = "rank", aliases = {}})
    table.insert(sortedCommands, {name = "rj", aliases = {"rejoin", "reconnect", "relog"}})
    table.sort(sortedCommands, function(a, b) return a.name < b.name end)
    
    for i, cmd in ipairs(sortedCommands) do
        local aliasText = #cmd.aliases > 0 and " (" .. table.concat(cmd.aliases, ", ") .. ")" or ""
        table.insert(labels, string.format("%d | %s%s", i, PREFIX .. cmd.name, aliasText))
    end
    
    local labelsJson = "["
    for i, label in ipairs(labels) do
        labelsJson = labelsJson .. string.format("%q", label)
        if i < #labels then labelsJson = labelsJson .. "," end
    end
    labelsJson = labelsJson .. "]"
    
    local code = string.format([[
local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local player = Players.LocalPlayer

local CHOCOLATE = Color3.fromRGB(74, 49, 28)
local MILK_CHOCOLATE = Color3.fromRGB(111, 78, 55)
local LIGHT_CHOCOLATE = Color3.fromRGB(139, 90, 43)
local COOKIE_DOUGH = Color3.fromRGB(210, 180, 140)
local OFF_WHITE = Color3.fromRGB(240, 240, 240)

local existing = player.PlayerGui:FindFirstChild("LanzyDashboard")
if existing then existing:Destroy() return end

local screenGui = Instance.new("ScreenGui")
screenGui.Name = "LanzyDashboard"
screenGui.Parent = player.PlayerGui
screenGui.ResetOnSpawn = false
screenGui.IgnoreGuiInset = true
screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling

local MainFrame = Instance.new("Frame")
MainFrame.Name = "MainFrame"
MainFrame.Size = UDim2.new(0, 750, 0, 420)
MainFrame.Position = UDim2.new(0.5, -375, 0.5, -210)
MainFrame.BackgroundColor3 = CHOCOLATE
MainFrame.BackgroundTransparency = 0.05
MainFrame.BorderSizePixel = 2
MainFrame.BorderColor3 = LIGHT_CHOCOLATE
MainFrame.Parent = screenGui

Instance.new("UICorner", MainFrame).CornerRadius = UDim.new(0, 12)

local TopBar = Instance.new("Frame")
TopBar.Name = "TopBar"
TopBar.Size = UDim2.new(1, 0, 0, 38)
TopBar.BackgroundColor3 = MILK_CHOCOLATE
TopBar.BackgroundTransparency = 0.1
TopBar.BorderSizePixel = 0
TopBar.Parent = MainFrame

Instance.new("UICorner", TopBar).CornerRadius = UDim.new(0, 12)

local Title = Instance.new("TextLabel")
Title.Name = "Title"
Title.Size = UDim2.new(0, 200, 0, 38)
Title.Position = UDim2.new(0.36, 0, 0, 0)
Title.BackgroundTransparency = 1
Title.Text = "Crumbs Admin"
Title.TextColor3 = OFF_WHITE
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
CloseButton.TextSize = 18
CloseButton.Font = Enum.Font.GothamBold
CloseButton.Parent = TopBar

local TabBar = Instance.new("Frame")
TabBar.Name = "TabBar"
TabBar.Size = UDim2.new(1, -16, 0, 42)
TabBar.Position = UDim2.new(0, 8, 0, 46)
TabBar.BackgroundColor3 = MILK_CHOCOLATE
TabBar.BackgroundTransparency = 0.2
TabBar.BorderSizePixel = 1
TabBar.BorderColor3 = LIGHT_CHOCOLATE
TabBar.Parent = MainFrame

Instance.new("UICorner", TabBar).CornerRadius = UDim.new(0, 8)

local CommandsTab = Instance.new("TextButton")
CommandsTab.Name = "CommandsTab"
CommandsTab.Size = UDim2.new(0.5, -5, 0, 36)
CommandsTab.Position = UDim2.new(0, 4, 0, 3)
CommandsTab.BackgroundColor3 = COOKIE_DOUGH
CommandsTab.BackgroundTransparency = 0.1
CommandsTab.BorderSizePixel = 1
CommandsTab.BorderColor3 = LIGHT_CHOCOLATE
CommandsTab.Text = "Commands"
CommandsTab.TextColor3 = CHOCOLATE
CommandsTab.TextSize = 16
CommandsTab.Font = Enum.Font.GothamBold
CommandsTab.Parent = TabBar

Instance.new("UICorner", CommandsTab).CornerRadius = UDim.new(0, 6)

local CreditsTab = Instance.new("TextButton")
CreditsTab.Name = "CreditsTab"
CreditsTab.Size = UDim2.new(0.5, -5, 0, 36)
CreditsTab.Position = UDim2.new(0.5, 1, 0, 3)
CreditsTab.BackgroundColor3 = MILK_CHOCOLATE
CreditsTab.BackgroundTransparency = 0.3
CreditsTab.BorderSizePixel = 1
CreditsTab.BorderColor3 = LIGHT_CHOCOLATE
CreditsTab.Text = "Credits"
CreditsTab.TextColor3 = OFF_WHITE
CreditsTab.TextSize = 16
CreditsTab.Font = Enum.Font.GothamBold
CreditsTab.Parent = TabBar

Instance.new("UICorner", CreditsTab).CornerRadius = UDim.new(0, 6)

local ContentFrame = Instance.new("Frame")
ContentFrame.Name = "ContentFrame"
ContentFrame.Size = UDim2.new(1, -16, 1, -104)
ContentFrame.Position = UDim2.new(0, 8, 0, 96)
ContentFrame.BackgroundColor3 = MILK_CHOCOLATE
ContentFrame.BackgroundTransparency = 0.3
ContentFrame.BorderSizePixel = 1
ContentFrame.BorderColor3 = LIGHT_CHOCOLATE
ContentFrame.Parent = MainFrame

Instance.new("UICorner", ContentFrame).CornerRadius = UDim.new(0, 8)

local CommandsContent = Instance.new("ScrollingFrame")
CommandsContent.Name = "CommandsContent"
CommandsContent.Size = UDim2.new(1, 0, 1, 0)
CommandsContent.BackgroundColor3 = MILK_CHOCOLATE
CommandsContent.BackgroundTransparency = 0
CommandsContent.BorderSizePixel = 0
CommandsContent.ScrollBarThickness = 6
CommandsContent.ScrollBarImageColor3 = COOKIE_DOUGH
CommandsContent.Visible = true
CommandsContent.Parent = ContentFrame

Instance.new("UICorner", CommandsContent).CornerRadius = UDim.new(0, 8)

local CommandsLayout = Instance.new("UIListLayout")
CommandsLayout.Parent = CommandsContent
CommandsLayout.Padding = UDim.new(0, 5)

local CreditsContent = Instance.new("ScrollingFrame")
CreditsContent.Name = "CreditsContent"
CreditsContent.Size = UDim2.new(1, 0, 1, 0)
CreditsContent.BackgroundColor3 = MILK_CHOCOLATE
CreditsContent.BackgroundTransparency = 0.3
CreditsContent.BorderSizePixel = 0
CreditsContent.ScrollBarThickness = 6
CreditsContent.ScrollBarImageColor3 = COOKIE_DOUGH
CreditsContent.Visible = false
CreditsContent.Parent = ContentFrame

Instance.new("UICorner", CreditsContent).CornerRadius = UDim.new(0, 8)

local CreditsLayout = Instance.new("UIListLayout")
CreditsLayout.Parent = CreditsContent
CreditsLayout.Padding = UDim.new(0, 10)
CreditsLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center

local CreditTitle = Instance.new("TextLabel")
CreditTitle.Size = UDim2.new(1, -20, 0, 40)
CreditTitle.Position = UDim2.new(0, 10, 0, 10)
CreditTitle.BackgroundTransparency = 1
CreditTitle.Text = "CREDITS"
CreditTitle.TextColor3 = COOKIE_DOUGH
CreditTitle.TextSize = 28
CreditTitle.Font = Enum.Font.GothamBold
CreditTitle.TextWrapped = true
CreditTitle.Parent = CreditsContent

local CreditDivider = Instance.new("Frame")
CreditDivider.Size = UDim2.new(0.8, 0, 0, 2)
CreditDivider.Position = UDim2.new(0.1, 0, 0, 55)
CreditDivider.BackgroundColor3 = COOKIE_DOUGH
CreditDivider.BorderSizePixel = 0
CreditDivider.Parent = CreditsContent

local credits = {
    {role = "Creator", name = "(xXRblxGamerRblxXx (Lanzy)", desc = "Made almost everything in here"},
    {role = "GUI Inspiration", name = "idonthacklol101ns (Master0fSouls)", desc = "Inspired from Sentrius"},
    {role = "Origin", name = "SnowClan_8342 (YeemiRouth)", desc = "Made some of the commands originally"},
    {role = "Version", name = "Crumbs Admin v1.0", desc = "Server-side admin system"},
}

local yPos = 70
for _, credit in ipairs(credits) do
    local CreditFrame = Instance.new("Frame")
    CreditFrame.Size = UDim2.new(0.9, 0, 0, 80)
    CreditFrame.Position = UDim2.new(0.05, 0, 0, yPos)
    CreditFrame.BackgroundColor3 = LIGHT_CHOCOLATE
    CreditFrame.BackgroundTransparency = 0.3
    CreditFrame.BorderSizePixel = 1
    CreditFrame.BorderColor3 = COOKIE_DOUGH
    CreditFrame.Parent = CreditsContent
    
    Instance.new("UICorner", CreditFrame).CornerRadius = UDim.new(0, 8)
    
    local RoleLabel = Instance.new("TextLabel")
    RoleLabel.Size = UDim2.new(1, -20, 0, 20)
    RoleLabel.Position = UDim2.new(0, 10, 0, 8)
    RoleLabel.BackgroundTransparency = 1
    RoleLabel.Text = credit.role
    RoleLabel.TextColor3 = COOKIE_DOUGH
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
SpecialThanks.TextSize = 14
SpecialThanks.Font = Enum.Font.GothamBold
SpecialThanks.TextWrapped = true
SpecialThanks.Parent = CreditsContent

CreditsContent.CanvasSize = UDim2.new(0, 0, 0, yPos + 70)

local labels = %s

for _, text in ipairs(labels) do
    local CommandFrame = Instance.new("Frame")
    CommandFrame.Size = UDim2.new(1, -12, 0, 40)
    CommandFrame.BackgroundColor3 = LIGHT_CHOCOLATE
    CommandFrame.BackgroundTransparency = 0.3
    CommandFrame.BorderSizePixel = 1
    CommandFrame.BorderColor3 = COOKIE_DOUGH
    CommandFrame.Parent = CommandsContent

    Instance.new("UICorner", CommandFrame).CornerRadius = UDim.new(0, 6)

    local CommandLabel = Instance.new("TextLabel")
    CommandLabel.Size = UDim2.new(1, -12, 1, -6)
    CommandLabel.Position = UDim2.new(0, 6, 0, 3)
    CommandLabel.BackgroundTransparency = 1
    CommandLabel.Text = text
    CommandLabel.TextColor3 = OFF_WHITE
    CommandLabel.TextSize = 14
    CommandLabel.Font = Enum.Font.Gotham
    CommandLabel.TextXAlignment = Enum.TextXAlignment.Left
    CommandLabel.TextYAlignment = Enum.TextYAlignment.Center
    CommandLabel.TextWrapped = true
    CommandLabel.Parent = CommandFrame
end

CommandsLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
    CommandsContent.CanvasSize = UDim2.new(0, 0, 0, CommandsLayout.AbsoluteContentSize.Y + 10)
end)
CommandsContent.CanvasSize = UDim2.new(0, 0, 0, CommandsLayout.AbsoluteContentSize.Y + 10)

local function switchTab(tab)
    if tab == "Commands" then
        TweenService:Create(CommandsTab, TweenInfo.new(0.3), {BackgroundColor3 = COOKIE_DOUGH, BackgroundTransparency = 0.1}):Play()
        TweenService:Create(CreditsTab, TweenInfo.new(0.3), {BackgroundColor3 = MILK_CHOCOLATE, BackgroundTransparency = 0.3}):Play()
        CommandsContent.Visible = true
        CreditsContent.Visible = false
    else
        TweenService:Create(CreditsTab, TweenInfo.new(0.3), {BackgroundColor3 = COOKIE_DOUGH, BackgroundTransparency = 0.1}):Play()
        TweenService:Create(CommandsTab, TweenInfo.new(0.3), {BackgroundColor3 = MILK_CHOCOLATE, BackgroundTransparency = 0.3}):Play()
        CommandsContent.Visible = false
        CreditsContent.Visible = true
    end
end

CommandsTab.MouseButton1Click:Connect(function() switchTab("Commands") end)
CreditsTab.MouseButton1Click:Connect(function() switchTab("Credits") end)

CloseButton.MouseButton1Click:Connect(function() screenGui:Destroy() end)

local dragging, dragStart, startPos = false, nil, nil
TopBar.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        dragging = true
        dragStart = input.Position
        startPos = MainFrame.Position
        
        local conn
        conn = UserInputService.InputChanged:Connect(function(i)
            if dragging and (i.UserInputType == Enum.UserInputType.MouseMovement or i.UserInputType == Enum.UserInputType.Touch) then
                local delta = i.Position - dragStart
                MainFrame.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
            end
        end)
        
        input.Changed:Connect(function()
            if input.UserInputState == Enum.UserInputState.End then
                dragging = false
                if conn then conn:Disconnect() end
            end
        end)
    end
end)
]], labelsJson)
    
    task.spawn(function() runLua(player, code) end)
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
        openDashboard(player)
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
            notify(player, "Crumbs Admin", "Usage: ,rank <player> <rank>", 5)
            return
        end
        
        local targetPlayer = findPlayer(targetName, player)
        if not targetPlayer then
            notify(player, "Crumbs Admin", "Player not found.", 5)
            return
        end
        
        if targetPlayer == player then
            notify(player, "Crumbs Admin", "You cannot rank yourself.", 5)
            return
        end
        
        local rankValue = tonumber(rankInput)
        if not rankValue then
            local r = string.lower(rankInput)
            if r == "customer" then rankValue = 0
            elseif r == "cashier" then rankValue = 1
            elseif r == "baker" then rankValue = 2
            elseif r == "manager" then rankValue = 3
            end
        end
        
        if not rankValue or rankValue < 0 or rankValue > 3 then
            notify(player, "Crumbs Admin", "Invalid rank. Use 0-3 or Customer/Cashier/Baker/Manager", 5)
            return
        end
        
        local rankName = rankValue == 0 and "Customer" or rankValue == 1 and "Cashier" or rankValue == 2 and "Baker" or "Manager"
        PLAYER_RANKS[targetPlayer.UserId] = rankValue
        notify(player, "Crumbs Admin", string.format("%s has been ranked as %s", targetPlayer.Name, rankName), 5)
        notify(targetPlayer, "Crumbs Admin", string.format("You have been ranked as %s", rankName), 5)
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
        
        local targetPlayer = findPlayer(targetName, player)
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
        
        local targetPlayer = findPlayer(targetName, player)
        if not targetPlayer then
            notify(player, "Crumbs Admin", "Player not found.", 5)
            return
        end
        
        if targetPlayer.UserId == AUTHOR_USER_ID then
            notify(player, "Crumbs Admin", "You cannot ban the author.", 5)
            return
        end
        
        BANNED_PLAYERS[targetPlayer.UserId] = { Banner = player.Name, Reason = reason, Time = os.time() }
        task.wait(0.1)
        targetPlayer:Kick(string.format("Banned by %s\nReason: %s", player.Name, reason))
        return
    end
    
    if realCommandName == "unban" then
        for id, _ in pairs(BANNED_PLAYERS) do
            BANNED_PLAYERS[id] = nil
            notify(player, "Crumbs Admin", "User has been unbanned.", 5)
            return
        end
        notify(player, "Crumbs Admin", "No banned users found.", 5)
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
        for _, p in ipairs(Players:GetPlayers()) do
            local cleanupCode = [[
local player = game.Players.LocalPlayer
local pg = player.PlayerGui

if pg:FindFirstChild("CmdBarGui") then pg.CmdBarGui:Destroy() end
if pg:FindFirstChild("LanzyDashboard") then pg.LanzyDashboard:Destroy() end

for _, v in ipairs(pg:GetChildren()) do
    if v.Name:find("LNZNotification_") then v:Destroy() end
end

_G.LanzyNotifStack = nil
_G.LNZNotifCooldown = nil
]]
            task.spawn(function() runLua(p, cleanupCode) end)
        end
        
        for _, v in ipairs(ReplicatedStorage:GetChildren()) do
            if v.Name == "CrumbsAdminRemote" then
                v:Destroy()
            end
        end
        
        LOOP_KILL = {}
        LOOP_PUNISH = {}
        BANNED_PLAYERS = {}
        
        for id, _ in pairs(PLAYER_RANKS) do
            if id ~= AUTHOR_USER_ID then
                PLAYER_RANKS[id] = nil
            end
        end
        
        script:Destroy()
        return
    end
    
    if realCommandName == "clear" then
        for _, obj in ipairs(workspace:GetDescendants()) do
            if obj:IsA("BasePart") and not obj:IsDescendantOf(player.Character) and obj.Name ~= "Baseplate" and obj.Parent ~= workspace.Terrain then
                obj:Destroy()
            end
        end
        notify(player, "Crumbs Admin", "Workspace cleared.", 5)
        return
    end
    
    if #commandSplit == 0 then
        notify(player, "Crumbs Admin", "Invalid command usage.", 5)
        return
    end
    
    local targets = getTargets(player, commandSplit[1])
    table.remove(commandSplit, 1)
    local args = commandSplit
    
    for _, target in ipairs(targets) do
        task.spawn(function()
            if realCommandName == "punish" and target.Character then
                target.Character:BreakJoints()
            elseif realCommandName == "kill" and target.Character and target.Character:FindFirstChild("Head") then
                target.Character.Head:Destroy()
            elseif realCommandName == "freeze" and target.Character then
                for _, part in ipairs(target.Character:GetDescendants()) do
                    if part:IsA("BasePart") then part.Anchored = true end
                end
            elseif realCommandName == "unfreeze" and target.Character then
                for _, part in ipairs(target.Character:GetDescendants()) do
                    if part:IsA("BasePart") then part.Anchored = false end
                end
            elseif realCommandName == "noclip" and target.Character then
                for _, part in ipairs(target.Character:GetDescendants()) do
                    if part:IsA("BasePart") then part.CanCollide = false end
                end
            elseif realCommandName == "clip" and target.Character then
                for _, part in ipairs(target.Character:GetDescendants()) do
                    if part:IsA("BasePart") then part.CanCollide = true end
                end
            elseif realCommandName == "void" and target.Character and target.Character:FindFirstChild("HumanoidRootPart") then
                target.Character.HumanoidRootPart.CFrame = CFrame.new(target.Character.HumanoidRootPart.Position.X, -5000, target.Character.HumanoidRootPart.Position.Z)
            elseif realCommandName == "skydive" and target.Character and target.Character:FindFirstChild("HumanoidRootPart") then
                local height = tonumber(args[1]) or 1000
                target.Character.HumanoidRootPart.CFrame = CFrame.new(target.Character.HumanoidRootPart.Position.X, height, target.Character.HumanoidRootPart.Position.Z)
            elseif realCommandName == "tp" and target.Character and target.Character:FindFirstChild("HumanoidRootPart") then
                local destName = args[1]
                if destName then
                    local dest = destName == "me" and player or findPlayer(destName, player)
                    if dest and dest.Character and dest.Character:FindFirstChild("HumanoidRootPart") then
                        target.Character.HumanoidRootPart.CFrame = dest.Character.HumanoidRootPart.CFrame * CFrame.new(0, 0, -5)
                    end
                end
            elseif realCommandName == "bring" and target.Character and target.Character:FindFirstChild("HumanoidRootPart") and player.Character and player.Character:FindFirstChild("HumanoidRootPart") then
                target.Character.HumanoidRootPart.CFrame = player.Character.HumanoidRootPart.CFrame * CFrame.new(0, 0, -5)
            elseif realCommandName == "removehats" and target.Character then
                for _, obj in ipairs(target.Character:GetDescendants()) do
                    if obj:IsA("Accessory") then obj:Destroy() end
                end
            elseif realCommandName == "removearms" and target.Character then
                local arms = {"Left Arm", "Right Arm", "LeftHand", "RightHand", "LeftLowerArm", "RightLowerArm", "LeftUpperArm", "RightUpperArm"}
                for _, part in ipairs(target.Character:GetDescendants()) do
                    if part:IsA("BasePart") and table.find(arms, part.Name) then part:Destroy() end
                end
            elseif realCommandName == "removelegs" and target.Character then
                local legs = {"Left Leg", "Right Leg", "LeftFoot", "RightFoot", "LeftLowerLeg", "RightLowerLeg", "LeftUpperLeg", "RightUpperLeg"}
                for _, part in ipairs(target.Character:GetDescendants()) do
                    if part:IsA("BasePart") and table.find(legs, part.Name) then part:Destroy() end
                end
            elseif realCommandName == "invisible" and target.Character then
                for _, part in ipairs(target.Character:GetDescendants()) do
                    if part:IsA("BasePart") then part.Transparency = 1 end
                end
            elseif realCommandName == "visible" and target.Character then
                for _, part in ipairs(target.Character:GetDescendants()) do
                    if part:IsA("BasePart") then part.Transparency = 0 end
                end
            elseif realCommandName == "loopkill" then
                LOOP_KILL[target.UserId] = true
                task.spawn(function()
                    while LOOP_KILL[target.UserId] do
                        if target.Character and target.Character:FindFirstChild("Head") then
                            target.Character.Head:Destroy()
                        end
                        task.wait(0.5)
                    end
                end)
            elseif realCommandName == "unloopkill" then
                LOOP_KILL[target.UserId] = nil
            elseif realCommandName == "looppunish" then
                LOOP_PUNISH[target.UserId] = true
                task.spawn(function()
                    while LOOP_PUNISH[target.UserId] do
                        if target.Character then target.Character:BreakJoints() end
                        task.wait(0.5)
                    end
                end)
            elseif realCommandName == "unlooppunish" then
                LOOP_PUNISH[target.UserId] = nil
            end
        end)
    end
end

local function onPlayerAdded(player)
    if BANNED_PLAYERS[player.UserId] then
        local info = BANNED_PLAYERS[player.UserId]
        player:Kick(string.format("Banned by %s\nReason: %s", info.Banner, info.Reason))
        return
    end
    
    task.spawn(function() setupCmdBar(player) end)
    task.spawn(function() notify(player, "Crumbs Admin", "Click , for command bar | Type ,cmds to get started.", 5) end)
    task.spawn(function() notify(player, "Crumbs Admin", "Welcome to Crumbs Admin, "..player.DisplayName..".", 5) end)
    
    player.Chatted:Connect(function(msg)
        if string.sub(msg, 1, 1) == PREFIX then
            processCommand(player, msg)
        end
    end)
end

for _, player in ipairs(Players:GetPlayers()) do
    task.spawn(function() onPlayerAdded(player) end)
end

Players.PlayerAdded:Connect(onPlayerAdded)
Players.PlayerRemoving:Connect(function(p)
    LOOP_KILL[p.UserId] = nil
    LOOP_PUNISH[p.UserId] = nil
end)

local remote = Instance.new("RemoteEvent")
remote.Name = "CrumbsAdminRemote"
remote.Parent = ReplicatedStorage

remote.OnServerEvent:Connect(function(player, command)
    if command then
        task.spawn(function() processCommand(player, command) end)
    end
end)

task.spawn(function() broadcastNotification("Crumbs Admin", "Tada~!! Crumbs Admin loaded!! :3, 5) end)
