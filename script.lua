local Players = game:GetService("Players")
local ServerScriptService = game:GetService("ServerScriptService")
local RunService = game:GetService("RunService")
local TeleportService = game:GetService("TeleportService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local adminFolder = Instance.new("Folder")
adminFolder.Name = "CrumbsAdmin"
adminFolder.Parent = ServerScriptService

local remoteEvent = Instance.new("RemoteEvent")
remoteEvent.Name = "AdminRemote"
remoteEvent.Parent = adminFolder

local notificationRemote = Instance.new("RemoteEvent")
notificationRemote.Name = "NotificationRemote"
notificationRemote.Parent = adminFolder

local rankRemote = Instance.new("RemoteEvent")
rankRemote.Name = "RankRemote"
rankRemote.Parent = adminFolder

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
    -- Add usernames here to auto-rank them
    -- Format: ["Username"] = rank number (1-4)
    -- Example: ["xXRblxGamerRblxXx"] = 4,
}

local playerRanks = {}
local tempRanks = {}
local activePunishments = {}
local activeLoopKills = {}
local bannedPlayers = {}

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

local function cmd_rj(executor)
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

local function cmd_eject(executor)
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
    
    if cmd == "cmds" or cmd == "commands" or cmd == "help" then
        local rank = getPlayerRank(player)
        local availableCmds = {}
        for name, data in pairs(COMMANDS) do
            if data.rank <= rank then
                table.insert(availableCmds, PREFIX .. name)
            end
        end
        notify(player, "Crumbs Admin", "Your rank: " .. RANK_NAMES[rank] .. " (" .. rank .. ")\nAvailable commands: " .. #availableCmds, 5)
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

rankRemote.OnServerEvent:Connect(function(player, targetUserId, rank)
    if getPlayerRank(player) < 4 then return end
    tempRanks[targetUserId] = rank
end)

Players.PlayerAdded:Connect(function(player)
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
end)

local function protectOwner()
    for _, player in ipairs(Players:GetPlayers()) do
        if getPlayerRank(player) >= 4 and player.Character then
            for _, part in ipairs(getPlayerParts(player)) do
                part.CanCollide = true
                part.Anchored = false
            end
        end
    end
end

RunService.Heartbeat:Connect(protectOwner)

print("Crumbs Admin loaded with rank system")
