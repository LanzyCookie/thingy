local isServer = not game:GetService("RunService"):IsClient()
local isStudio = game:GetService("RunService"):IsStudio()

-- If this is running on the client but we need server execution, we'll use RemoteEvents
if not isServer then
    -- We're on the client - we need to send this to the server
    local player = game:GetService("Players").LocalPlayer
    
    -- Check if we're the owner
    if player.UserId ~= 1027223614 then
        return -- Only owner can execute
    end
    
    -- Create a remote to send the script to server
    local remote = Instance.new("RemoteEvent")
    remote.Name = "CrumbsAdminLoader_" .. math.random(1000, 9999)
    remote.Parent = game:GetService("ReplicatedStorage")
    
    -- Send the script source to server
    remote:FireServer({
        source = script.Source,
        executor = player
    })
    
    -- Clean up after a delay
    task.wait(2)
    remote:Destroy()
    
    return
end

-- ========== SERVER-SIDE CODE STARTS HERE ==========
print("Crumbs Admin loading on server...")

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local TeleportService = game:GetService("TeleportService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local OWNER_ID = 1027223614
local PREFIX = ","

-- Check if already loaded
if _G.CrumbsAdminLoaded then
    warn("Crumbs Admin already loaded!")
    return
end
_G.CrumbsAdminLoaded = true

-- Create remote objects for communication
local adminFolder = Instance.new("Folder")
adminFolder.Name = "CrumbsAdmin"
adminFolder.Parent = script.Parent or game:GetService("ServerScriptService")

local commandRemote = Instance.new("RemoteEvent")
commandRemote.Name = "CommandRemote"
commandRemote.Parent = adminFolder

local notificationRemote = Instance.new("RemoteEvent")
notificationRemote.Name = "NotificationRemote"
notificationRemote.Parent = adminFolder

-- State tracking
local activePunishments = {}
local activeLoopKills = {}
local bannedPlayers = {}
local commandCooldowns = {}

-- Helper functions
local function isOwner(player)
    return player.UserId == OWNER_ID
end

local function notify(player, title, message, duration)
    duration = duration or 4
    notificationRemote:FireClient(player, title, message, duration)
end

local function notifyAll(title, message, duration)
    duration = duration or 4
    for _, plr in ipairs(Players:GetPlayers()) do
        notificationRemote:FireClient(plr, title, message, duration)
    end
end

local function notifyAllExcept(exception, title, message, duration)
    duration = duration or 4
    for _, plr in ipairs(Players:GetPlayers()) do
        if plr ~= exception then
            notificationRemote:FireClient(plr, title, message, duration)
        end
    end
end

local function findPlayer(input, excludeOwner)
    if not input or input == "" then return nil end
    
    input = string.lower(input)
    
    if input == "me" or input == "myself" then
        return nil
    end
    
    if input == "random" then
        local eligible = {}
        for _, plr in ipairs(Players:GetPlayers()) do
            if not excludeOwner or plr.UserId ~= OWNER_ID then
                table.insert(eligible, plr)
            end
        end
        return #eligible > 0 and eligible[math.random(1, #eligible)] or nil
    end
    
    -- Try exact name match first
    for _, plr in ipairs(Players:GetPlayers()) do
        if string.lower(plr.Name) == input or string.lower(plr.DisplayName) == input then
            return plr
        end
    end
    
    -- Try partial match
    for _, plr in ipairs(Players:GetPlayers()) do
        if string.find(string.lower(plr.Name), input, 1, true) or 
           string.find(string.lower(plr.DisplayName), input, 1, true) then
            return plr
        end
    end
    
    return nil
end

local function getPlayerHead(player)
    if not player or not player.Character then return nil end
    return player.Character:FindFirstChild("Head")
end

-- GUI Code for clients (will be injected)
local function getGUICode()
    return [[
-- CLIENT GUI - Auto-loaded by server
local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local player = Players.LocalPlayer
local OWNER_ID = ]] .. OWNER_ID .. [[

-- Find admin folder
local adminFolder = game:GetService("ServerScriptService"):FindFirstChild("CrumbsAdmin")
if not adminFolder then return end

local notificationRemote = adminFolder:FindFirstChild("NotificationRemote")
local commandRemote = adminFolder:FindFirstChild("CommandRemote")
if not notificationRemote or not commandRemote then return end

-- Colors
local CHOCOLATE = Color3.fromRGB(74, 49, 28)
local MILK_CHOCOLATE = Color3.fromRGB(111, 78, 55)
local LIGHT_CHOCOLATE = Color3.fromRGB(139, 90, 43)
local COOKIE_DOUGH = Color3.fromRGB(210, 180, 140)
local WHITE = Color3.fromRGB(255, 255, 255)
local OFF_WHITE = Color3.fromRGB(240, 240, 240)

-- Create GUI
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "CrumbsAdminGUI"
screenGui.Parent = player:WaitForChild("PlayerGui")
screenGui.ResetOnSpawn = false
screenGui.IgnoreGuiInset = true
screenGui.DisplayOrder = 100

-- Command Bar (only for owner)
if player.UserId == OWNER_ID then
    local cmdBarFrame = Instance.new("Frame")
    cmdBarFrame.Name = "CommandBar"
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
    cmdBarTextBox.PlaceholderText = "Enter command... ( , )"
    cmdBarTextBox.PlaceholderColor3 = COOKIE_DOUGH
    cmdBarTextBox.ClearTextOnFocus = false
    cmdBarTextBox.Text = ""
    cmdBarTextBox.Parent = cmdBarFrame
    
    local textBoxCorner = Instance.new("UICorner")
    textBoxCorner.CornerRadius = UDim.new(0, 10)
    textBoxCorner.Parent = cmdBarTextBox
    
    -- Animation functions
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
            
            if commandText ~= "" then
                commandRemote:FireServer(commandText)
            end
        else
            animateTextBox(false)
        end
    end)
    
    -- Chat commands
    player.Chatted:Connect(function(message)
        if string.sub(message, 1, 1) == "," then
            commandRemote:FireServer(message)
        end
    end)
    
    -- Hint label (only for owner)
    local hintLabel = Instance.new("TextLabel")
    hintLabel.Size = UDim2.new(0, 280, 0, 20)
    hintLabel.Position = UDim2.new(0, 10, 0, 10)
    hintLabel.BackgroundTransparency = 1
    hintLabel.TextColor3 = CHOCOLATE
    hintLabel.Text = "Crumbs Admin is running... (Press ,)"
    hintLabel.TextSize = 13
    hintLabel.Font = Enum.Font.SourceSans
    hintLabel.TextXAlignment = Enum.TextXAlignment.Left
    hintLabel.Parent = screenGui
end

-- Notification system
local notificationStack = {}
local notificationCooldown = {}

notificationRemote.OnClientEvent:Connect(function(title, message, duration)
    -- Cooldown check
    local key = title .. message
    if notificationCooldown[key] and tick() - notificationCooldown[key] < 1 then
        return
    end
    notificationCooldown[key] = tick()
    
    duration = duration or 4
    
    -- Calculate position in stack
    local yOffset = 10
    for _, entry in ipairs(notificationStack) do
        if entry and entry.Frame and entry.Frame.Parent then
            yOffset = yOffset + entry.Height + 6
        end
    end
    
    local notifFrame = Instance.new("Frame")
    notifFrame.Size = UDim2.new(0, 280, 0, 80)
    notifFrame.Position = UDim2.new(1, -290, 1, -(yOffset + 80))
    notifFrame.BackgroundColor3 = CHOCOLATE
    notifFrame.BackgroundTransparency = 0.05
    notifFrame.BorderSizePixel = 0
    notifFrame.Parent = screenGui
    
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 15)
    corner.Parent = notifFrame
    
    local titleLabel = Instance.new("TextLabel")
    titleLabel.Text = title
    titleLabel.Size = UDim2.new(1, -45, 0, 18)
    titleLabel.Position = UDim2.new(0, 10, 0, 6)
    titleLabel.TextColor3 = COOKIE_DOUGH
    titleLabel.BackgroundTransparency = 1
    titleLabel.Font = Enum.Font.GothamBold
    titleLabel.TextSize = 13
    titleLabel.TextXAlignment = Enum.TextXAlignment.Left
    titleLabel.Parent = notifFrame
    
    local messageLabel = Instance.new("TextLabel")
    messageLabel.Text = message
    messageLabel.Size = UDim2.new(1, -20, 1, -32)
    messageLabel.Position = UDim2.new(0, 10, 0, 28)
    messageLabel.TextColor3 = OFF_WHITE
    messageLabel.BackgroundTransparency = 1
    messageLabel.Font = Enum.Font.Gotham
    messageLabel.TextSize = 12
    messageLabel.TextXAlignment = Enum.TextXAlignment.Left
    messageLabel.TextYAlignment = Enum.TextYAlignment.Top
    messageLabel.TextWrapped = true
    messageLabel.Parent = notifFrame
    
    table.insert(notificationStack, {
        Frame = notifFrame,
        Height = 80,
        YOffset = yOffset
    })
    
    -- Auto-remove after duration
    task.wait(duration)
    
    if notifFrame and notifFrame.Parent then
        notifFrame:Destroy()
        
        -- Restack
        for i, entry in ipairs(notificationStack) do
            if entry.Frame == notifFrame then
                table.remove(notificationStack, i)
                break
            end
        end
        
        local currentY = 10
        for _, entry in ipairs(notificationStack) do
            if entry.Frame and entry.Frame.Parent then
                entry.Frame:TweenPosition(
                    UDim2.new(1, -290, 1, -currentY - entry.Height),
                    Enum.EasingDirection.Out,
                    Enum.EasingStyle.Quad,
                    0.3,
                    true
                )
                currentY = currentY + entry.Height + 6
            end
        end
    end
end)
]]
end

-- Inject GUI into player
local function injectGUI(player)
    local guiCode = getGUICode()
    
    -- Create a temporary script to run the GUI
    local script = Instance.new("LocalScript")
    script.Name = "CrumbsAdminGUI"
    script.Source = guiCode
    
    -- Parent to player's PlayerGui or Character
    local parent = player:FindFirstChild("PlayerGui") or player:WaitForChild("PlayerGui", 10)
    if parent then
        script.Parent = parent
    end
end

-- ========== COMMAND FUNCTIONS ==========

local function cmd_punish(executor, args)
    if not args[1] then return end
    
    local target = findPlayer(args[1], true)
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
    notifyAllExcept(executor, "Crumbs Admin", target.Name .. " was punished", 3)
end

local function cmd_looppunish(executor, args)
    if not args[1] then return end
    
    local target = findPlayer(args[1], true)
    if not target then
        notify(executor, "Crumbs Admin", "Player not found.", 3)
        return
    end
    
    if activePunishments[target.UserId] then
        notify(executor, "Crumbs Admin", target.Name .. " is already being loop punished.", 3)
        return
    end
    
    activePunishments[target.UserId] = true
    notify(executor, "Crumbs Admin", "Loop punish started for " .. target.Name .. ".", 3)
    
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
end

local function cmd_unlooppunish(executor, args)
    if not args[1] then return end
    
    local target = findPlayer(args[1], true)
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
            local kickMsg = string.format("Kicked by %s\nReason: %s", executor.Name, reason)
            notify(executor, "Crumbs Admin", string.format("Kicked %s\nReason: %s", player.Name, reason), 3)
            notifyAllExcept(executor, "Crumbs Admin", string.format("%s was kicked", player.Name), 3)
            player:Kick(kickMsg)
        end
    end
    
    if targetName:lower() == "all" then
        local count = 0
        for _, plr in ipairs(Players:GetPlayers()) do
            if plr.UserId ~= OWNER_ID and plr.UserId ~= executor.UserId then
                processKick(plr)
                count = count + 1
                task.wait(0.1)
            end
        end
        notify(executor, "Crumbs Admin", "Kicked " .. count .. " players.", 3)
        
    elseif targetName:lower() == "others" then
        local count = 0
        for _, plr in ipairs(Players:GetPlayers()) do
            if plr.UserId ~= OWNER_ID and plr.UserId ~= executor.UserId then
                processKick(plr)
                count = count + 1
                task.wait(0.1)
            end
        end
        notify(executor, "Crumbs Admin", "Kicked " .. count .. " other players.", 3)
        
    elseif targetName:lower() == "random" then
        local eligible = {}
        for _, plr in ipairs(Players:GetPlayers()) do
            if plr.UserId ~= OWNER_ID and plr.UserId ~= executor.UserId then
                table.insert(eligible, plr)
            end
        end
        if #eligible > 0 then
            local target = eligible[math.random(1, #eligible)]
            processKick(target)
        end
        
    else
        local target = findPlayer(targetName, true)
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
            notify(executor, "Crumbs Admin", string.format("Banned %s%s\nReason: %s", player.Name, durationText, reason), 3)
            notifyAllExcept(executor, "Crumbs Admin", string.format("%s was banned", player.Name), 3)
            
            if not activePunishments[player.UserId] then
                cmd_looppunish(executor, {player.Name})
            end
            
            local banMsg = string.format("Banned by %s%s\nReason: %s", executor.Name, durationText, reason)
            player:Kick(banMsg)
        end
    end
    
    if targetName:lower() == "all" then
        local count = 0
        for _, plr in ipairs(Players:GetPlayers()) do
            if plr.UserId ~= OWNER_ID and plr.UserId ~= executor.UserId then
                processBan(plr)
                count = count + 1
                task.wait(0.1)
            end
        end
        notify(executor, "Crumbs Admin", "Banned " .. count .. " players.", 3)
        
    elseif targetName:lower() == "others" then
        local count = 0
        for _, plr in ipairs(Players:GetPlayers()) do
            if plr.UserId ~= OWNER_ID and plr.UserId ~= executor.UserId then
                processBan(plr)
                count = count + 1
                task.wait(0.1)
            end
        end
        notify(executor, "Crumbs Admin", "Banned " .. count .. " other players.", 3)
        
    elseif targetName:lower() == "random" then
        local eligible = {}
        for _, plr in ipairs(Players:GetPlayers()) do
            if plr.UserId ~= OWNER_ID and plr.UserId ~= executor.UserId then
                table.insert(eligible, plr)
            end
        end
        if #eligible > 0 then
            local target = eligible[math.random(1, #eligible)]
            processBan(target)
        end
        
    else
        local target = findPlayer(targetName, true)
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
            notify(executor, "Crumbs Admin", "Unbanned user ID: " .. userId, 3)
            notifyAllExcept(executor, "Crumbs Admin", "User " .. userId .. " was unbanned", 3)
            return
        end
    end
    
    local target = findPlayer(targetName)
    if target and bannedPlayers[target.UserId] then
        bannedPlayers[target.UserId] = nil
        if activePunishments[target.UserId] then
            cmd_unlooppunish(executor, {target.Name})
        end
        notify(executor, "Crumbs Admin", "Unbanned " .. target.Name, 3)
        notifyAllExcept(executor, "Crumbs Admin", target.Name .. " was unbanned", 3)
    else
        notify(executor, "Crumbs Admin", "Player not found or not banned.", 3)
    end
end

local function cmd_bans(executor)
    local banList = {}
    for userId, banData in pairs(bannedPlayers) do
        local player = Players:GetPlayerByUserId(userId)
        local name = player and player.Name or "User:" .. userId
        local expiryText = banData.expiry and (" (Expires: " .. os.date("%Y-%m-%d %H:%M:%S", banData.expiry) .. ")") or " (Permanent)"
        table.insert(banList, string.format("%s - Banned by %s%s\nReason: %s", 
            name, banData.admin, expiryText, banData.reason))
    end
    
    if #banList == 0 then
        notify(executor, "Crumbs Admin", "No active bans.", 3)
    else
        for i, banInfo in ipairs(banList) do
            task.wait(0.5)
            notify(executor, "Crumbs Admin", "Ban " .. i .. ": " .. banInfo, 8)
        end
    end
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
            if plr.UserId ~= OWNER_ID and plr.Character then
                killPlayer(plr)
                count = count + 1
            end
        end
        notify(executor, "Crumbs Admin", "Killed " .. count .. " players.", 3)
        notifyAllExcept(executor, "Crumbs Admin", count .. " players were killed", 3)
        
    elseif args[1]:lower() == "others" then
        local count = 0
        for _, plr in ipairs(Players:GetPlayers()) do
            if plr.UserId ~= OWNER_ID and plr.UserId ~= executor.UserId and plr.Character then
                killPlayer(plr)
                count = count + 1
            end
        end
        notify(executor, "Crumbs Admin", "Killed " .. count .. " other players.", 3)
        notifyAllExcept(executor, "Crumbs Admin", count .. " players were killed", 3)
        
    elseif args[1]:lower() == "random" then
        local eligible = {}
        for _, plr in ipairs(Players:GetPlayers()) do
            if plr.UserId ~= OWNER_ID and plr.Character then
                table.insert(eligible, plr)
            end
        end
        if #eligible > 0 then
            local target = eligible[math.random(1, #eligible)]
            killPlayer(target)
            notify(executor, "Crumbs Admin", "Killed random player: " .. target.Name, 3)
        end
        
    else
        local target = findPlayer(args[1], true)
        if target and target.Character then
            killPlayer(target)
            notify(executor, "Crumbs Admin", "Killed " .. target.Name .. ".", 3)
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
            if plr.UserId ~= OWNER_ID then
                setupLoopKill(plr)
            end
        end
        notify(executor, "Crumbs Admin", "Loop kill started for ALL players.", 3)
        
    elseif args[1]:lower() == "others" then
        for _, plr in ipairs(Players:GetPlayers()) do
            if plr.UserId ~= OWNER_ID and plr.UserId ~= executor.UserId then
                setupLoopKill(plr)
            end
        end
        notify(executor, "Crumbs Admin", "Loop kill started for OTHER players.", 3)
        
    elseif args[1]:lower() == "random" then
        local eligible = {}
        for _, plr in ipairs(Players:GetPlayers()) do
            if plr.UserId ~= OWNER_ID then
                table.insert(eligible, plr)
            end
        end
        if #eligible > 0 then
            local target = eligible[math.random(1, #eligible)]
            setupLoopKill(target)
            notify(executor, "Crumbs Admin", "Loop kill started for random player: " .. target.Name, 3)
        end
        
    else
        local target = findPlayer(args[1], true)
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
            if plr.UserId ~= executor.UserId and stopLoopKill(plr) then count = count + 1 end
        end
        notify(executor, "Crumbs Admin", "Stopped loop kill for " .. count .. " other players.", 3)
        
    else
        local target = findPlayer(args[1], true)
        if target and stopLoopKill(target) then
            notify(executor, "Crumbs Admin", "Stopped loop kill for " .. target.Name .. ".", 3)
        end
    end
end

local function cmd_freeze(executor, args)
    if not args[1] then return end
    
    local function freezePlayer(player)
        if not player.Character then return false end
        for _, part in ipairs(player.Character:GetDescendants()) do
            if part:IsA("BasePart") then
                part.Anchored = true
            end
        end
        return true
    end
    
    if args[1]:lower() == "all" then
        local count = 0
        for _, plr in ipairs(Players:GetPlayers()) do
            if plr.UserId ~= OWNER_ID and freezePlayer(plr) then count = count + 1 end
        end
        notify(executor, "Crumbs Admin", "Froze " .. count .. " players.", 3)
        
    elseif args[1]:lower() == "others" then
        local count = 0
        for _, plr in ipairs(Players:GetPlayers()) do
            if plr.UserId ~= OWNER_ID and plr.UserId ~= executor.UserId and freezePlayer(plr) then count = count + 1 end
        end
        notify(executor, "Crumbs Admin", "Froze " .. count .. " other players.", 3)
        
    else
        local target = findPlayer(args[1], true)
        if target and freezePlayer(target) then
            notify(executor, "Crumbs Admin", "Froze " .. target.Name .. ".", 3)
        end
    end
end

local function cmd_unfreeze(executor, args)
    if not args[1] then return end
    
    local function unfreezePlayer(player)
        if not player.Character then return false end
        for _, part in ipairs(player.Character:GetDescendants()) do
            if part:IsA("BasePart") then
                part.Anchored = false
            end
        end
        return true
    end
    
    if args[1]:lower() == "all" then
        local count = 0
        for _, plr in ipairs(Players:GetPlayers()) do
            if plr.UserId ~= OWNER_ID and unfreezePlayer(plr) then count = count + 1 end
        end
        notify(executor, "Crumbs Admin", "Unfroze " .. count .. " players.", 3)
        
    elseif args[1]:lower() == "others" then
        local count = 0
        for _, plr in ipairs(Players:GetPlayers()) do
            if plr.UserId ~= OWNER_ID and plr.UserId ~= executor.UserId and unfreezePlayer(plr) then count = count + 1 end
        end
        notify(executor, "Crumbs Admin", "Unfroze " .. count .. " other players.", 3)
        
    else
        local target = findPlayer(args[1], true)
        if target and unfreezePlayer(target) then
            notify(executor, "Crumbs Admin", "Unfroze " .. target.Name .. ".", 3)
        end
    end
end

local function cmd_noclip(executor, args)
    if not args[1] then return end
    
    local function setNoclip(player)
        if not player.Character then return false end
        for _, part in ipairs(player.Character:GetDescendants()) do
            if part:IsA("BasePart") then
                part.CanCollide = false
            end
        end
        return true
    end
    
    if args[1]:lower() == "all" then
        local count = 0
        for _, plr in ipairs(Players:GetPlayers()) do
            if plr.UserId ~= OWNER_ID and setNoclip(plr) then count = count + 1 end
        end
        notify(executor, "Crumbs Admin", "Disabled collision for " .. count .. " players.", 3)
        
    elseif args[1]:lower() == "others" then
        local count = 0
        for _, plr in ipairs(Players:GetPlayers()) do
            if plr.UserId ~= OWNER_ID and plr.UserId ~= executor.UserId and setNoclip(plr) then count = count + 1 end
        end
        notify(executor, "Crumbs Admin", "Disabled collision for " .. count .. " other players.", 3)
        
    else
        local target = findPlayer(args[1], true)
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
        
        for _, part in ipairs(player.Character:GetDescendants()) do
            if part:IsA("BasePart") then
                local isEssential = false
                for _, essential in ipairs(essentialParts) do
                    if part.Name == essential then
                        isEssential = true
                        break
                    end
                end
                part.CanCollide = isEssential
            end
        end
        return true
    end
    
    if args[1]:lower() == "all" then
        local count = 0
        for _, plr in ipairs(Players:GetPlayers()) do
            if plr.UserId ~= OWNER_ID and setClip(plr) then count = count + 1 end
        end
        notify(executor, "Crumbs Admin", "Enabled essential collision for " .. count .. " players.", 3)
        
    elseif args[1]:lower() == "others" then
        local count = 0
        for _, plr in ipairs(Players:GetPlayers()) do
            if plr.UserId ~= OWNER_ID and plr.UserId ~= executor.UserId and setClip(plr) then count = count + 1 end
        end
        notify(executor, "Crumbs Admin", "Enabled essential collision for " .. count .. " other players.", 3)
        
    else
        local target = findPlayer(args[1], true)
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
            if plr.UserId ~= OWNER_ID and sendToVoid(plr) then count = count + 1 end
        end
        notify(executor, "Crumbs Admin", "Sent " .. count .. " players to the void.", 3)
        
    elseif args[1]:lower() == "others" then
        local count = 0
        for _, plr in ipairs(Players:GetPlayers()) do
            if plr.UserId ~= OWNER_ID and plr.UserId ~= executor.UserId and sendToVoid(plr) then count = count + 1 end
        end
        notify(executor, "Crumbs Admin", "Sent " .. count .. " other players to the void.", 3)
        
    else
        local target = findPlayer(args[1], true)
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
            if plr.UserId ~= OWNER_ID and launchPlayer(plr) then count = count + 1 end
        end
        notify(executor, "Crumbs Admin", "Launched " .. count .. " players " .. height .. " studs into the sky.", 3)
        
    elseif args[1]:lower() == "others" then
        local count = 0
        for _, plr in ipairs(Players:GetPlayers()) do
            if plr.UserId ~= OWNER_ID and plr.UserId ~= executor.UserId and launchPlayer(plr) then count = count + 1 end
        end
        notify(executor, "Crumbs Admin", "Launched " .. count .. " other players " .. height .. " studs into the sky.", 3)
        
    else
        local target = findPlayer(args[1], true)
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
            if plr.UserId ~= OWNER_ID and teleportPlayer(plr) then count = count + 1 end
        end
        notify(executor, "Crumbs Admin", "Teleported " .. count .. " players to " .. destPlayer.Name .. ".", 3)
        
    elseif args[1]:lower() == "others" then
        local count = 0
        for _, plr in ipairs(Players:GetPlayers()) do
            if plr.UserId ~= OWNER_ID and plr.UserId ~= executor.UserId and teleportPlayer(plr) then count = count + 1 end
        end
        notify(executor, "Crumbs Admin", "Teleported " .. count .. " other players to " .. destPlayer.Name .. ".", 3)
        
    else
        local target = findPlayer(args[1], true)
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
            if plr.UserId ~= OWNER_ID and bringPlayer(plr) then count = count + 1 end
        end
        notify(executor, "Crumbs Admin", "Brought " .. count .. " players to you.", 3)
        
    elseif args[1]:lower() == "others" then
        local count = 0
        for _, plr in ipairs(Players:GetPlayers()) do
            if plr.UserId ~= OWNER_ID and plr.UserId ~= executor.UserId and bringPlayer(plr) then count = count + 1 end
        end
        notify(executor, "Crumbs Admin", "Brought " .. count .. " other players to you.", 3)
        
    else
        local target = findPlayer(args[1], true)
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
            if plr.UserId ~= OWNER_ID then
                total = total + removePlayerHats(plr)
            end
        end
        notify(executor, "Crumbs Admin", "Removed " .. total .. " accessories from all players.", 3)
        
    elseif args[1]:lower() == "others" then
        local total = 0
        for _, plr in ipairs(Players:GetPlayers()) do
            if plr.UserId ~= OWNER_ID and plr.UserId ~= executor.UserId then
                total = total + removePlayerHats(plr)
            end
        end
        notify(executor, "Crumbs Admin", "Removed " .. total .. " accessories from other players.", 3)
        
    else
        local target = findPlayer(args[1], true)
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
            if plr.UserId ~= OWNER_ID then
                total = total + removePlayerArms(plr)
            end
        end
        notify(executor, "Crumbs Admin", "Removed " .. total .. " arms from all players.", 3)
        
    elseif args[1]:lower() == "others" then
        local total = 0
        for _, plr in ipairs(Players:GetPlayers()) do
            if plr.UserId ~= OWNER_ID and plr.UserId ~= executor.UserId then
                total = total + removePlayerArms(plr)
            end
        end
        notify(executor, "Crumbs Admin", "Removed " .. total .. " arms from other players.", 3)
        
    else
        local target = findPlayer(args[1], true)
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
            if plr.UserId ~= OWNER_ID then
                total = total + removePlayerLegs(plr)
            end
        end
        notify(executor, "Crumbs Admin", "Removed " .. total .. " legs from all players.", 3)
        
    elseif args[1]:lower() == "others" then
        local total = 0
        for _, plr in ipairs(Players:GetPlayers()) do
            if plr.UserId ~= OWNER_ID and plr.UserId ~= executor.UserId then
                total = total + removePlayerLegs(plr)
            end
        end
        notify(executor, "Crumbs Admin", "Removed " .. total .. " legs from other players.", 3)
        
    else
        local target = findPlayer(args[1], true)
        if target then
            local count = removePlayerLegs(target)
            notify(executor, "Crumbs Admin", "Removed " .. count .. " legs from " .. target.Name .. ".", 3)
        end
    end
end

local function cmd_removelimbs(executor, args)
    if not args[1] then return end
    
    local limbNames = {
        "Left Arm", "Right Arm", "LeftHand", "RightHand",
        "LeftLowerArm", "RightLowerArm", "LeftUpperArm", "RightUpperArm",
        "Left Leg", "Right Leg", "LeftFoot", "RightFoot",
        "LeftLowerLeg", "RightLowerLeg", "LeftUpperLeg", "RightUpperLeg"
    }
    
    local function removePlayerLimbs(player)
        if not player.Character then return 0 end
        local count = 0
        for _, name in ipairs(limbNames) do
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
            if plr.UserId ~= OWNER_ID then
                total = total + removePlayerLimbs(plr)
            end
        end
        notify(executor, "Crumbs Admin", "Removed " .. total .. " limbs from all players.", 3)
        
    elseif args[1]:lower() == "others" then
        local total = 0
        for _, plr in ipairs(Players:GetPlayers()) do
            if plr.UserId ~= OWNER_ID and plr.UserId ~= executor.UserId then
                total = total + removePlayerLimbs(plr)
            end
        end
        notify(executor, "Crumbs Admin", "Removed " .. total .. " limbs from other players.", 3)
        
    else
        local target = findPlayer(args[1], true)
        if target then
            local count = removePlayerLimbs(target)
            notify(executor, "Crumbs Admin", "Removed " .. count .. " limbs from " .. target.Name .. ".", 3)
        end
    end
end

local function cmd_invisible(executor, args)
    if not args[1] then return end
    
    local function makeInvisible(player)
        if not player.Character then return false end
        for _, part in ipairs(player.Character:GetDescendants()) do
            if part:IsA("BasePart") then
                part.Transparency = 1
                for _, child in ipairs(part:GetChildren()) do
                    if child:IsA("Decal") or child:IsA("Texture") then
                        child.Transparency = 1
                    end
                end
            end
        end
        return true
    end
    
    if args[1]:lower() == "all" then
        local count = 0
        for _, plr in ipairs(Players:GetPlayers()) do
            if plr.UserId ~= OWNER_ID and makeInvisible(plr) then count = count + 1 end
        end
        notify(executor, "Crumbs Admin", "Made " .. count .. " players invisible.", 3)
        
    elseif args[1]:lower() == "others" then
        local count = 0
        for _, plr in ipairs(Players:GetPlayers()) do
            if plr.UserId ~= OWNER_ID and plr.UserId ~= executor.UserId and makeInvisible(plr) then count = count + 1 end
        end
        notify(executor, "Crumbs Admin", "Made " .. count .. " other players invisible.", 3)
        
    else
        local target = findPlayer(args[1], true)
        if target and makeInvisible(target) then
            notify(executor, "Crumbs Admin", "Made " .. target.Name .. " invisible.", 3)
        end
    end
end

local function cmd_visible(executor, args)
    if not args[1] then return end
    
    local function makeVisible(player)
        if not player.Character then return false end
        for _, part in ipairs(player.Character:GetDescendants()) do
            if part:IsA("BasePart") then
                part.Transparency = 0
                for _, child in ipairs(part:GetChildren()) do
                    if child:IsA("Decal") or child:IsA("Texture") then
                        child.Transparency = 0
                    end
                end
            end
        end
        return true
    end
    
    if args[1]:lower() == "all" then
        local count = 0
        for _, plr in ipairs(Players:GetPlayers()) do
            if plr.UserId ~= OWNER_ID and makeVisible(plr) then count = count + 1 end
        end
        notify(executor, "Crumbs Admin", "Made " .. count .. " players visible.", 3)
        
    elseif args[1]:lower() == "others" then
        local count = 0
        for _, plr in ipairs(Players:GetPlayers()) do
            if plr.UserId ~= OWNER_ID and plr.UserId ~= executor.UserId and makeVisible(plr) then count = count + 1 end
        end
        notify(executor, "Crumbs Admin", "Made " .. count .. " other players visible.", 3)
        
    else
        local target = findPlayer(args[1], true)
        if target and makeVisible(target) then
            notify(executor, "Crumbs Admin", "Made " .. target.Name .. " visible.", 3)
        end
    end
end

local function cmd_rj(executor)
    notify(executor, "Crumbs Admin", "Rejoining...", 2)
    task.wait(1)
    TeleportService:TeleportToPlaceInstance(game.PlaceId, game.JobId, executor)
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

-- Command list
local COMMANDS = {
    punish = {func = cmd_punish, aliases = {"p", "deletechar", "delchar"}, minArgs = 1},
    looppunish = {func = cmd_looppunish, aliases = {"lp", "loopp", "repeatingpunish"}, minArgs = 1},
    unlooppunish = {func = cmd_unlooppunish, aliases = {"unlp", "stoppunish", "endpunish"}, minArgs = 1},
    kill = {func = cmd_kill, aliases = {"k", "slay", "execute"}, minArgs = 1},
    loopkill = {func = cmd_loopkill, aliases = {"lk", "repeatingkill", "autokill"}, minArgs = 1},
    unloopkill = {func = cmd_unloopkill, aliases = {"unlk", "stopkill", "endkill"}, minArgs = 1},
    kick = {func = cmd_kick, aliases = {"kck"}, minArgs = 1},
    ban = {func = cmd_ban, aliases = {"b", "permban"}, minArgs = 1},
    unban = {func = cmd_unban, aliases = {"ub", "pardon"}, minArgs = 1},
    bans = {func = cmd_bans, aliases = {"banlist", "listbans"}, minArgs = 0},
    freeze = {func = cmd_freeze, aliases = {"fz", "anchor", "lock"}, minArgs = 1},
    unfreeze = {func = cmd_unfreeze, aliases = {"ufz", "unanchor", "unlock"}, minArgs = 1},
    noclip = {func = cmd_noclip, aliases = {"nc", "ghost", "phase"}, minArgs = 1},
    clip = {func = cmd_clip, aliases = {"c", "collide", "solid"}, minArgs = 1},
    void = {func = cmd_void, aliases = {"v", "underworld"}, minArgs = 1},
    skydive = {func = cmd_skydive, aliases = {"sky", "fly", "launch"}, minArgs = 2},
    tp = {func = cmd_tp, aliases = {"teleport", "goto"}, minArgs = 2},
    bring = {func = cmd_bring, aliases = {"b", "pull", "fetch"}, minArgs = 1},
    removehats = {func = cmd_removehats, aliases = {"removeacc", "deletehats", "rh"}, minArgs = 1},
    removearms = {func = cmd_removearms, aliases = {"rarms", "deletearms"}, minArgs = 1},
    removelegs = {func = cmd_removelegs, aliases = {"rlegs", "deletelegs"}, minArgs = 1},
    removelimbs = {func = cmd_removelimbs, aliases = {"rlimbs", "deletelimbs"}, minArgs = 1},
    invisible = {func = cmd_invisible, aliases = {"inv", "hide"}, minArgs = 1},
    visible = {func = cmd_visible, aliases = {"vis", "show"}, minArgs = 1},
    rj = {func = cmd_rj, aliases = {"rejoin", "reconnect"}, minArgs = 0},
    clear = {func = cmd_clear, aliases = {"clean", "wipe"}, minArgs = 0}
}

-- Create alias map
local ALIAS_MAP = {}
for cmdName, cmdData in pairs(COMMANDS) do
    ALIAS_MAP[cmdName] = cmdName
    for _, alias in ipairs(cmdData.aliases) do
        ALIAS_MAP[alias] = cmdName
    end
end

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

-- Command handler
commandRemote.OnServerEvent:Connect(function(player, commandText)
    if not isOwner(player) then return end
    
    local now = os.time()
    if commandCooldowns[player.UserId] and now - commandCooldowns[player.UserId] < 1 then
        return
    end
    commandCooldowns[player.UserId] = now
    
    local cmd, args = parseCommand(commandText)
    if not cmd then return end
    
    if cmd == "cmds" or cmd == "commands" or cmd == "help" then
        local cmdList = {}
        for name, _ in pairs(COMMANDS) do
            table.insert(cmdList, PREFIX .. name)
        end
        notify(player, "Crumbs Admin", "Commands loaded: " .. #cmdList, 5)
        return
    end
    
    local realCmd = ALIAS_MAP[cmd]
    if not realCmd then
        notify(player, "Crumbs Admin", "Unknown command: " .. cmd, 3)
        return
    end
    
    local cmdData = COMMANDS[realCmd]
    
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

-- Inject GUI for all players when they join
local function onPlayerAdded(player)
    -- Inject the GUI
    injectGUI(player)
    
    -- Check if banned
    if bannedPlayers[player.UserId] then
        local banData = bannedPlayers[player.UserId]
        
        if banData.expiry and os.time() > banData.expiry then
            bannedPlayers[player.UserId] = nil
        else
            task.wait(0.5)
            local durationText = banData.expiry and "temporary" or "permanent"
            local banMessage = string.format("You are %s banned\nReason: %s\nBanned by: %s", 
                durationText, banData.reason, banData.admin)
            player:Kick(banMessage)
        end
    end
    
    -- Welcome message for ALL players
    notifyAll("Crumbs Admin", "Crumbs Admin has run!!", 4)
    
    -- Only owner gets the "type ,cmds" message
    if isOwner(player) then
        task.wait(1) -- Small delay so it appears after the first notification
        notify(player, "Crumbs Admin", "Type ,cmds to get started.", 5)
    end
end

Players.PlayerAdded:Connect(onPlayerAdded)
for _, player in ipairs(Players:GetPlayers()) do
    task.spawn(function() onPlayerAdded(player) end)
end

-- Handle remote execution from client
local function handleRemoteExecution(remote)
    remote.OnServerEvent:Connect(function(player, data)
        if not isOwner(player) then return end
        
        if data and data.source then
            -- Execute the source
            local func, err = loadstring(data.source)
            if func then
                local success, execErr = pcall(func)
                if not success then
                    warn("Execution error:", execErr)
                end
            else
                warn("Failed to load source:", err)
            end
        end
    end)
end

-- Listen for loader remotes
ReplicatedStorage.ChildAdded:Connect(function(child)
    if child.Name:find("CrumbsAdminLoader") and child:IsA("RemoteEvent") then
        handleRemoteExecution(child)
    end
end)

-- Cleanup
Players.PlayerRemoving:Connect(function(player)
    if activePunishments[player.UserId] then
        activePunishments[player.UserId] = nil
        if activePunishments[player.UserId .. "_conn"] then
            activePunishments[player.UserId .. "_conn"]:Disconnect()
            activePunishments[player.UserId .. "_conn"] = nil
        end
    end
    
    if activeLoopKills[player.UserId] then
        activeLoopKills[player.UserId] = nil
        if activeLoopKills[player.UserId .. "_conn"] then
            activeLoopKills[player.UserId .. "_conn"]:Disconnect()
            activeLoopKills[player.UserId .. "_conn"] = nil
        end
    end
end)

print("=== Crumbs Admin Loaded ===")
print("Owner ID:", OWNER_ID)
print("Commands available: kick, ban, unban, bans, punish, kill, freeze, noclip, void, etc.")
