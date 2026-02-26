-- Crumbs Admin - FULLY SERVER-SIDE VERSION
-- Run this in ServerScriptService ONLY
-- All players will see GUIs and notifications

local Players = game:GetService("Players")
local ServerScriptService = game:GetService("ServerScriptService")
local RunService = game:GetService("RunService")
local TeleportService = game:GetService("TeleportService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local TextChatService = game:GetService("TextChatService")

-- Create RemoteEvents for client communication
local adminFolder = Instance.new("Folder")
adminFolder.Name = "CrumbsAdmin"
adminFolder.Parent = ReplicatedStorage

local commandRemote = Instance.new("RemoteEvent")
commandRemote.Name = "CommandRemote"
commandRemote.Parent = adminFolder

local notificationRemote = Instance.new("RemoteEvent")
notificationRemote.Name = "NotificationRemote"
notificationRemote.Parent = adminFolder

local dashboardRemote = Instance.new("RemoteEvent")
dashboardRemote.Name = "DashboardRemote"
dashboardRemote.Parent = adminFolder

local guiRemote = Instance.new("RemoteEvent")
guiRemote.Name = "GUIRemote"
guiRemote.Parent = adminFolder

-- Color definitions (will be sent to clients)
local COLORS = {
    CHOCOLATE = {74, 49, 28},
    MILK_CHOCOLATE = {111, 78, 55},
    LIGHT_CHOCOLATE = {139, 90, 43},
    COOKIE_DOUGH = {210, 180, 140},
    WHITE = {255, 255, 255},
    OFF_WHITE = {240, 240, 240}
}

-- Configuration
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

-- Data storage (server-side only)
local AUTO_WHITELIST = {
    ["xXRblxGamerRblxXx"] = 4  -- Add usernames here for auto-rank
}

local playerRanks = {}
local tempRanks = {}
local activePunishments = {}
local activeLoopKills = {}
local bannedPlayers = {}
local mutedPlayers = {}
local godModePlayers = {}
local flyModePlayers = {}
local savedLocations = {}
local adminLogs = {}

-- Helper Functions
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
    return player.Character:FindFirstChild("Head") or player.Character:FindFirstChild("HumanoidRootPart")
end

local function getPlayerHumanoid(player)
    if not player or not player.Character then return nil end
    return player.Character:FindFirstChildOfClass("Humanoid")
end

-- Notification Functions (server to client)
local function notify(player, title, message, duration)
    duration = duration or 4
    notificationRemote:FireClient(player, title, message, duration, COLORS)
end

local function notifyAll(title, message, duration)
    duration = duration or 4
    for _, player in ipairs(Players:GetPlayers()) do
        notificationRemote:FireClient(player, title, message, duration, COLORS)
    end
end

local function notifyStaff(title, message, duration)
    duration = duration or 4
    for _, player in ipairs(Players:GetPlayers()) do
        if getPlayerRank(player) >= 1 then
            notificationRemote:FireClient(player, title, message, duration, COLORS)
        end
    end
end

-- Dashboard function (opens GUI for specific player)
local function openDashboard(player, defaultTab)
    defaultTab = defaultTab or "Commands"
    dashboardRemote:FireClient(player, "Open", defaultTab, COLORS, RANK_NAMES, PREFIX)
end

-- Player finding function
local function findPlayer(input, executor)
    if not input or input == "" then return nil end
    
    input = string.lower(input)
    
    if input == "me" then
        return executor
    end
    
    if input == "all" then
        return Players:GetPlayers()
    end
    
    if input == "others" then
        local others = {}
        for _, plr in ipairs(Players:GetPlayers()) do
            if plr ~= executor then
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
    
    if input == "admins" or input == "staff" then
        local staff = {}
        for _, plr in ipairs(Players:GetPlayers()) do
            if getPlayerRank(plr) >= 1 then
                table.insert(staff, plr)
            end
        end
        return staff
    end
    
    if input == "nonadmins" then
        local users = {}
        for _, plr in ipairs(Players:GetPlayers()) do
            if getPlayerRank(plr) == 0 then
                table.insert(users, plr)
            end
        end
        return users
    end
    
    -- Find by exact name
    for _, plr in ipairs(Players:GetPlayers()) do
        if string.lower(plr.Name) == input or string.lower(plr.DisplayName) == input then
            return {plr}
        end
    end
    
    -- Find by partial name
    local results = {}
    for _, plr in ipairs(Players:GetPlayers()) do
        if string.find(string.lower(plr.Name), input, 1, true) or 
           string.find(string.lower(plr.DisplayName), input, 1, true) then
            table.insert(results, plr)
        end
    end
    
    return #results > 0 and results or nil
end

-- Log admin actions
local function logAdminAction(admin, action, target, details)
    local logEntry = {
        timestamp = os.time(),
        admin = admin.Name,
        action = action,
        target = target and target.Name or "N/A",
        details = details or ""
    }
    table.insert(adminLogs, logEntry)
    if #adminLogs > 100 then table.remove(adminLogs, 1) end
    print(string.format("[ADMIN] %s - %s %s: %s", admin.Name, action, target and target.Name or "", details))
end

-- COMMAND FUNCTIONS
local function cmd_rj(executor, args)
    notify(executor, "Crumbs Admin", "Rejoining...", 2)
    logAdminAction(executor, "REJOIN", executor, "Player rejoined server")
    task.wait(1)
    TeleportService:TeleportToPlaceInstance(game.PlaceId, game.JobId, executor)
end

local function cmd_punish(executor, args)
    if not args[1] then 
        notify(executor, "Crumbs Admin", "Usage: ,punish <player>", 3)
        return 
    end
    
    local targets = findPlayer(args[1], executor)
    if not targets then
        notify(executor, "Crumbs Admin", "Player not found.", 3)
        return
    end
    
    local count = 0
    for _, target in ipairs(targets) do
        if target.Character then
            target.Character:Destroy()
            count = count + 1
        end
    end
    
    notify(executor, "Crumbs Admin", "Punished " .. count .. " player(s).", 3)
    if count > 0 then
        notifyStaff("Crumbs Admin", executor.Name .. " punished " .. count .. " player(s)", 3)
    end
    logAdminAction(executor, "PUNISH", targets[1], "Punished " .. count .. " players")
end

local function cmd_kill(executor, args)
    if not args[1] then 
        notify(executor, "Crumbs Admin", "Usage: ,kill <player>", 3)
        return 
    end
    
    local targets = findPlayer(args[1], executor)
    if not targets then
        notify(executor, "Crumbs Admin", "Player not found.", 3)
        return
    end
    
    local count = 0
    for _, target in ipairs(targets) do
        local head = getPlayerHead(target)
        if head then
            head:Destroy()
            count = count + 1
        end
    end
    
    notify(executor, "Crumbs Admin", "Killed " .. count .. " player(s).", 3)
    logAdminAction(executor, "KILL", targets[1], "Killed " .. count .. " players")
end

local function cmd_freeze(executor, args)
    if not args[1] then 
        notify(executor, "Crumbs Admin", "Usage: ,freeze <player>", 3)
        return 
    end
    
    local targets = findPlayer(args[1], executor)
    if not targets then
        notify(executor, "Crumbs Admin", "Player not found.", 3)
        return
    end
    
    local count = 0
    for _, target in ipairs(targets) do
        if target.Character then
            for _, part in ipairs(getPlayerParts(target)) do
                part.Anchored = true
            end
            count = count + 1
        end
    end
    
    notify(executor, "Crumbs Admin", "Frozen " .. count .. " player(s).", 3)
    logAdminAction(executor, "FREEZE", targets[1], "Frozen " .. count .. " players")
end

local function cmd_unfreeze(executor, args)
    if not args[1] then 
        notify(executor, "Crumbs Admin", "Usage: ,unfreeze <player>", 3)
        return 
    end
    
    local targets = findPlayer(args[1], executor)
    if not targets then
        notify(executor, "Crumbs Admin", "Player not found.", 3)
        return
    end
    
    local count = 0
    for _, target in ipairs(targets) do
        if target.Character then
            for _, part in ipairs(getPlayerParts(target)) do
                part.Anchored = false
            end
            count = count + 1
        end
    end
    
    notify(executor, "Crumbs Admin", "Unfrozen " .. count .. " player(s).", 3)
end

local function cmd_noclip(executor, args)
    if not args[1] then 
        notify(executor, "Crumbs Admin", "Usage: ,noclip <player>", 3)
        return 
    end
    
    local targets = findPlayer(args[1], executor)
    if not targets then
        notify(executor, "Crumbs Admin", "Player not found.", 3)
        return
    end
    
    local count = 0
    for _, target in ipairs(targets) do
        if target.Character then
            for _, part in ipairs(getPlayerParts(target)) do
                part.CanCollide = false
            end
            count = count + 1
        end
    end
    
    notify(executor, "Crumbs Admin", "Noclip enabled for " .. count .. " player(s).", 3)
end

local function cmd_clip(executor, args)
    if not args[1] then 
        notify(executor, "Crumbs Admin", "Usage: ,clip <player>", 3)
        return 
    end
    
    local targets = findPlayer(args[1], executor)
    if not targets then
        notify(executor, "Crumbs Admin", "Player not found.", 3)
        return
    end
    
    local count = 0
    for _, target in ipairs(targets) do
        if target.Character then
            for _, part in ipairs(getPlayerParts(target)) do
                part.CanCollide = true
            end
            count = count + 1
        end
    end
    
    notify(executor, "Crumbs Admin", "Clip enabled for " .. count .. " player(s).", 3)
end

local function cmd_void(executor, args)
    if not args[1] then 
        notify(executor, "Crumbs Admin", "Usage: ,void <player>", 3)
        return 
    end
    
    local targets = findPlayer(args[1], executor)
    if not targets then
        notify(executor, "Crumbs Admin", "Player not found.", 3)
        return
    end
    
    local count = 0
    for _, target in ipairs(targets) do
        if target.Character and target.Character:FindFirstChild("HumanoidRootPart") then
            target.Character.HumanoidRootPart.CFrame = CFrame.new(0, -5000, 0)
            count = count + 1
        end
    end
    
    notify(executor, "Crumbs Admin", "Sent " .. count .. " player(s) to the void.", 3)
end

local function cmd_skydive(executor, args)
    if #args < 1 then 
        notify(executor, "Crumbs Admin", "Usage: ,skydive <player> [height]", 3)
        return 
    end
    
    local height = tonumber(args[2]) or 1000
    if height < 1000 then height = 1000 end
    
    local targets = findPlayer(args[1], executor)
    if not targets then
        notify(executor, "Crumbs Admin", "Player not found.", 3)
        return
    end
    
    local count = 0
    for _, target in ipairs(targets) do
        if target.Character and target.Character:FindFirstChild("HumanoidRootPart") then
            local pos = target.Character.HumanoidRootPart.Position
            target.Character.HumanoidRootPart.CFrame = CFrame.new(pos.X, pos.Y + height, pos.Z)
            count = count + 1
        end
    end
    
    notify(executor, "Crumbs Admin", "Launched " .. count .. " player(s) " .. height .. " studs.", 3)
end

local function cmd_tp(executor, args)
    if #args < 2 then 
        notify(executor, "Crumbs Admin", "Usage: ,tp <player> <destination>", 3)
        return 
    end
    
    local destPlayers = findPlayer(args[2], executor)
    if not destPlayers then
        notify(executor, "Crumbs Admin", "Destination not found.", 3)
        return
    end
    local dest = destPlayers[1]
    
    if not dest.Character or not dest.Character:FindFirstChild("HumanoidRootPart") then
        notify(executor, "Crumbs Admin", "Destination has no character.", 3)
        return
    end
    
    local destPos = dest.Character.HumanoidRootPart.CFrame * CFrame.new(0, 0, -5)
    
    local targets = findPlayer(args[1], executor)
    if not targets then
        notify(executor, "Crumbs Admin", "Target not found.", 3)
        return
    end
    
    local count = 0
    for _, target in ipairs(targets) do
        if target.Character and target.Character:FindFirstChild("HumanoidRootPart") then
            target.Character.HumanoidRootPart.CFrame = destPos
            count = count + 1
        end
    end
    
    notify(executor, "Crumbs Admin", "Teleported " .. count .. " player(s) to " .. dest.Name, 3)
end

local function cmd_bring(executor, args)
    if #args < 1 then 
        notify(executor, "Crumbs Admin", "Usage: ,bring <player>", 3)
        return 
    end
    
    if not executor.Character or not executor.Character:FindFirstChild("HumanoidRootPart") then
        notify(executor, "Crumbs Admin", "You have no character.", 3)
        return
    end
    
    local myPos = executor.Character.HumanoidRootPart.CFrame * CFrame.new(0, 0, -5)
    
    local targets = findPlayer(args[1], executor)
    if not targets then
        notify(executor, "Crumbs Admin", "Player not found.", 3)
        return
    end
    
    local count = 0
    for _, target in ipairs(targets) do
        if target ~= executor and target.Character and target.Character:FindFirstChild("HumanoidRootPart") then
            target.Character.HumanoidRootPart.CFrame = myPos
            count = count + 1
        end
    end
    
    notify(executor, "Crumbs Admin", "Brought " .. count .. " player(s) to you.", 3)
end

local function cmd_invisible(executor, args)
    if #args < 1 then 
        notify(executor, "Crumbs Admin", "Usage: ,invisible <player>", 3)
        return 
    end
    
    local targets = findPlayer(args[1], executor)
    if not targets then
        notify(executor, "Crumbs Admin", "Player not found.", 3)
        return
    end
    
    local count = 0
    for _, target in ipairs(targets) do
        if target.Character then
            for _, part in ipairs(getPlayerParts(target)) do
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
    
    notify(executor, "Crumbs Admin", "Made " .. count .. " player(s) invisible.", 3)
end

local function cmd_visible(executor, args)
    if #args < 1 then 
        notify(executor, "Crumbs Admin", "Usage: ,visible <player>", 3)
        return 
    end
    
    local targets = findPlayer(args[1], executor)
    if not targets then
        notify(executor, "Crumbs Admin", "Player not found.", 3)
        return
    end
    
    local count = 0
    for _, target in ipairs(targets) do
        if target.Character then
            for _, part in ipairs(getPlayerParts(target)) do
                part.Transparency = 0
                for _, child in ipairs(part:GetChildren()) do
                    if child:IsA("Decal") or child:IsA("Texture") then
                        child.Transparency = 0
                    end
                end
            end
            count = count + 1
        end
    end
    
    notify(executor, "Crumbs Admin", "Made " .. count .. " player(s) visible.", 3)
end

local function cmd_loopkill(executor, args)
    if #args < 1 then 
        notify(executor, "Crumbs Admin", "Usage: ,loopkill <player>", 3)
        return 
    end
    
    local targets = findPlayer(args[1], executor)
    if not targets then
        notify(executor, "Crumbs Admin", "Player not found.", 3)
        return
    end
    
    for _, target in ipairs(targets) do
        if target ~= executor then
            activeLoopKills[target.UserId] = true
            
            -- Setup respawn connection
            local connection
            connection = target.CharacterAdded:Connect(function()
                task.wait(0.1)
                if activeLoopKills[target.UserId] then
                    local head = getPlayerHead(target)
                    if head then head:Destroy() end
                end
            end)
            activeLoopKills[target.UserId .. "_conn"] = connection
        end
    end
    
    notify(executor, "Crumbs Admin", "Loop kill started for " .. #targets .. " player(s).", 3)
    logAdminAction(executor, "LOOPKILL", targets[1], "Started loop kill")
end

local function cmd_unloopkill(executor, args)
    if #args < 1 then 
        notify(executor, "Crumbs Admin", "Usage: ,unloopkill <player/all>", 3)
        return 
    end
    
    if args[1]:lower() == "all" then
        for userId, _ in pairs(activeLoopKills) do
            activeLoopKills[userId] = nil
            if activeLoopKills[userId .. "_conn"] then
                activeLoopKills[userId .. "_conn"]:Disconnect()
                activeLoopKills[userId .. "_conn"] = nil
            end
        end
        notify(executor, "Crumbs Admin", "Stopped all loop kills.", 3)
        return
    end
    
    local targets = findPlayer(args[1], executor)
    if not targets then
        notify(executor, "Crumbs Admin", "Player not found.", 3)
        return
    end
    
    local count = 0
    for _, target in ipairs(targets) do
        if activeLoopKills[target.UserId] then
            activeLoopKills[target.UserId] = nil
            if activeLoopKills[target.UserId .. "_conn"] then
                activeLoopKills[target.UserId .. "_conn"]:Disconnect()
                activeLoopKills[target.UserId .. "_conn"] = nil
            end
            count = count + 1
        end
    end
    
    notify(executor, "Crumbs Admin", "Stopped loop kill for " .. count .. " player(s).", 3)
end

local function cmd_looppunish(executor, args)
    if #args < 1 then 
        notify(executor, "Crumbs Admin", "Usage: ,looppunish <player>", 3)
        return 
    end
    
    local targets = findPlayer(args[1], executor)
    if not targets then
        notify(executor, "Crumbs Admin", "Player not found.", 3)
        return
    end
    
    for _, target in ipairs(targets) do
        if target ~= executor then
            activePunishments[target.UserId] = true
            
            -- Setup respawn connection
            local connection
            connection = target.CharacterAdded:Connect(function()
                task.wait(0.1)
                if activePunishments[target.UserId] then
                    target.Character:Destroy()
                end
            end)
            activePunishments[target.UserId .. "_conn"] = connection
        end
    end
    
    notify(executor, "Crumbs Admin", "Loop punish started for " .. #targets .. " player(s).", 3)
    logAdminAction(executor, "LOOPPUNISH", targets[1], "Started loop punish")
end

local function cmd_unlooppunish(executor, args)
    if #args < 1 then 
        notify(executor, "Crumbs Admin", "Usage: ,unlooppunish <player/all>", 3)
        return 
    end
    
    if args[1]:lower() == "all" then
        for userId, _ in pairs(activePunishments) do
            activePunishments[userId] = nil
            if activePunishments[userId .. "_conn"] then
                activePunishments[userId .. "_conn"]:Disconnect()
                activePunishments[userId .. "_conn"] = nil
            end
        end
        notify(executor, "Crumbs Admin", "Stopped all loop punishes.", 3)
        return
    end
    
    local targets = findPlayer(args[1], executor)
    if not targets then
        notify(executor, "Crumbs Admin", "Player not found.", 3)
        return
    end
    
    local count = 0
    for _, target in ipairs(targets) do
        if activePunishments[target.UserId] then
            activePunishments[target.UserId] = nil
            if activePunishments[target.UserId .. "_conn"] then
                activePunishments[target.UserId .. "_conn"]:Disconnect()
                activePunishments[target.UserId .. "_conn"] = nil
            end
            count = count + 1
        end
    end
    
    notify(executor, "Crumbs Admin", "Stopped loop punish for " .. count .. " player(s).", 3)
end

local function cmd_mute(executor, args)
    if #args < 1 then 
        notify(executor, "Crumbs Admin", "Usage: ,mute <player>", 3)
        return 
    end
    
    local targets = findPlayer(args[1], executor)
    if not targets then
        notify(executor, "Crumbs Admin", "Player not found.", 3)
        return
    end
    
    for _, target in ipairs(targets) do
        mutedPlayers[target.UserId] = true
        notify(target, "Crumbs Admin", "You have been muted by " .. executor.Name, 3)
    end
    
    notify(executor, "Crumbs Admin", "Muted " .. #targets .. " player(s).", 3)
end

local function cmd_unmute(executor, args)
    if #args < 1 then 
        notify(executor, "Crumbs Admin", "Usage: ,unmute <player/all>", 3)
        return 
    end
    
    if args[1]:lower() == "all" then
        mutedPlayers = {}
        notify(executor, "Crumbs Admin", "Unmuted all players.", 3)
        return
    end
    
    local targets = findPlayer(args[1], executor)
    if not targets then
        notify(executor, "Crumbs Admin", "Player not found.", 3)
        return
    end
    
    for _, target in ipairs(targets) do
        mutedPlayers[target.UserId] = nil
        notify(target, "Crumbs Admin", "You have been unmuted.", 3)
    end
    
    notify(executor, "Crumbs Admin", "Unmuted " .. #targets .. " player(s).", 3)
end

local function cmd_god(executor, args)
    if #args < 1 then 
        notify(executor, "Crumbs Admin", "Usage: ,god <player>", 3)
        return 
    end
    
    local targets = findPlayer(args[1], executor)
    if not targets then
        notify(executor, "Crumbs Admin", "Player not found.", 3)
        return
    end
    
    for _, target in ipairs(targets) do
        godModePlayers[target.UserId] = not godModePlayers[target.UserId]
        local status = godModePlayers[target.UserId] and "ENABLED" or "DISABLED"
        notify(target, "Crumbs Admin", "God mode " .. status, 3)
    end
    
    notify(executor, "Crumbs Admin", "Toggled god mode for " .. #targets .. " player(s).", 3)
end

local function cmd_fly(executor, args)
    if #args < 1 then 
        notify(executor, "Crumbs Admin", "Usage: ,fly <player>", 3)
        return 
    end
    
    local targets = findPlayer(args[1], executor)
    if not targets then
        notify(executor, "Crumbs Admin", "Player not found.", 3)
        return
    end
    
    for _, target in ipairs(targets) do
        flyModePlayers[target.UserId] = not flyModePlayers[target.UserId]
        local status = flyModePlayers[target.UserId] and "ENABLED" (use space)" or "DISABLED"
        notify(target, "Crumbs Admin", "Flight mode " .. status, 3)
        
        if flyModePlayers[target.UserId] then
            local humanoid = getPlayerHumanoid(target)
            if humanoid then
                humanoid.PlatformStand = true
            end
        else
            local humanoid = getPlayerHumanoid(target)
            if humanoid then
                humanoid.PlatformStand = false
            end
        end
    end
    
    notify(executor, "Crumbs Admin", "Toggled flight for " .. #targets .. " player(s).", 3)
end

local function cmd_kick(executor, args)
    if getPlayerRank(executor) < 3 then
        notify(executor, "Crumbs Admin", "You need Baker rank (3) to kick.", 3)
        return
    end
    
    if #args < 1 then 
        notify(executor, "Crumbs Admin", "Usage: ,kick <player> [reason]", 3)
        return 
    end
    
    local reason = #args > 1 and table.concat(args, " ", 2) or "No reason provided"
    local targets = findPlayer(args[1], executor)
    
    if not targets then
        notify(executor, "Crumbs Admin", "Player not found.", 3)
        return
    end
    
    local count = 0
    for _, target in ipairs(targets) do
        if target ~= executor then
            notifyAll("Crumbs Admin", target.Name .. " was kicked by " .. executor.Name .. " (" .. reason .. ")", 5)
            target:Kick("Kicked by " .. executor.Name .. ": " .. reason)
            count = count + 1
        end
    end
    
    notify(executor, "Crumbs Admin", "Kicked " .. count .. " player(s).", 3)
    logAdminAction(executor, "KICK", targets[1], "Reason: " .. reason)
end

local function cmd_ban(executor, args)
    if getPlayerRank(executor) < 3 then
        notify(executor, "Crumbs Admin", "You need Baker rank (3) to ban.", 3)
        return
    end
    
    if #args < 1 then 
        notify(executor, "Crumbs Admin", "Usage: ,ban <player> [duration] [reason]", 3)
        return 
    end
    
    local targetName = args[1]
    local duration = nil
    local reason = ""
    
    if args[2] and tonumber(args[2]) then
        duration = tonumber(args[2])
        reason = #args > 2 and table.concat(args, " ", 3) or "No reason provided"
    else
        reason = #args > 1 and table.concat(args, " ", 2) or "No reason provided"
    end
    
    local targets = findPlayer(args[1], executor)
    if not targets then
        notify(executor, "Crumbs Admin", "Player not found.", 3)
        return
    end
    
    for _, target in ipairs(targets) do
        if target ~= executor then
            local banData = {
                reason = reason,
                admin = executor.Name,
                timestamp = os.time(),
                expiry = duration and (os.time() + duration) or nil
            }
            
            bannedPlayers[target.UserId] = banData
            activePunishments[target.UserId] = true
            
            local durationText = duration and (" for " .. duration .. " seconds") or " permanently"
            notifyAll("Crumbs Admin", target.Name .. " was banned by " .. executor.Name .. durationText .. "\nReason: " .. reason, 5)
            
            target:Kick("Banned by " .. executor.Name .. durationText .. ": " .. reason)
        end
    end
    
    notify(executor, "Crumbs Admin", "Banned " .. #targets .. " player(s).", 3)
    logAdminAction(executor, "BAN", targets[1], "Duration: " .. (duration or "permanent") .. " Reason: " .. reason)
end

local function cmd_unban(executor, args)
    if getPlayerRank(executor) < 3 then
        notify(executor, "Crumbs Admin", "You need Baker rank (3) to unban.", 3)
        return
    end
    
    if #args < 1 then 
        notify(executor, "Crumbs Admin", "Usage: ,unban <player/userid>", 3)
        return 
    end
    
    if tonumber(args[1]) then
        local userId = tonumber(args[1])
        if bannedPlayers[userId] then
            bannedPlayers[userId] = nil
            activePunishments[userId] = nil
            notify(executor, "Crumbs Admin", "Unbanned user ID: " .. userId, 3)
            notifyAll("Crumbs Admin", "User " .. userId .. " was unbanned by " .. executor.Name, 5)
            return
        end
    end
    
    local targets = findPlayer(args[1], executor)
    if targets and targets[1] and bannedPlayers[targets[1].UserId] then
        local target = targets[1]
        bannedPlayers[target.UserId] = nil
        activePunishments[target.UserId] = nil
        notify(executor, "Crumbs Admin", "Unbanned " .. target.Name, 3)
        notifyAll("Crumbs Admin", target.Name .. " was unbanned by " .. executor.Name, 5)
    else
        notify(executor, "Crumbs Admin", "Player not found or not banned.", 3)
    end
end

local function cmd_clear(executor, args)
    if getPlayerRank(executor) < 3 then
        notify(executor, "Crumbs Admin", "You need Baker rank (3) to clear workspace.", 3)
        return
    end
    
    local count = 0
    for _, obj in ipairs(workspace:GetDescendants()) do
        if obj:IsA("BasePart") and not obj:IsDescendantOf(Players) and obj.Name ~= "Baseplate" and not obj:IsA("Terrain") then
            obj:Destroy()
            count = count + 1
        end
    end
    
    notify(executor, "Crumbs Admin", "Cleared " .. count .. " parts from workspace.", 3)
    logAdminAction(executor, "CLEAR", nil, "Cleared " .. count .. " parts")
end

local function cmd_announce(executor, args)
    if getPlayerRank(executor) < 3 then
        notify(executor, "Crumbs Admin", "You need Baker rank (3) to announce.", 3)
        return
    end
    
    if #args < 1 then 
        notify(executor, "Crumbs Admin", "Usage: ,announce <message>", 3)
        return 
    end
    
    local message = table.concat(args, " ")
    notifyAll("📢 ANNOUNCEMENT", executor.Name .. ": " .. message, 8)
    logAdminAction(executor, "ANNOUNCE", nil, "Message: " .. message)
end

local function cmd_players(executor, args)
    local list = {}
    for _, player in ipairs(Players:GetPlayers()) do
        table.insert(list, player.Name)
    end
    notify(executor, "Crumbs Admin", "Players (" .. #list .. "): " .. table.concat(list, ", "), 5)
end

local function cmd_staff(executor, args)
    local list = {}
    for _, player in ipairs(Players:GetPlayers()) do
        local rank = getPlayerRank(player)
        if rank > 0 then
            table.insert(list, player.Name .. " (" .. RANK_NAMES[rank] .. ")")
        end
    end
    
    if #list > 0 then
        notify(executor, "Crumbs Admin", "Online staff: " .. table.concat(list, ", "), 5)
    else
        notify(executor, "Crumbs Admin", "No staff online.", 3)
    end
end

local function cmd_serverinfo(executor, args)
    local info = string.format(
        "Server Info:\nPlayers: %d/%d\nPlace ID: %d\nJob ID: %s\nUptime: %.1f minutes",
        #Players:GetPlayers(),
        Players.MaxPlayers,
        game.PlaceId,
        game.JobId:sub(1, 8),
        (os.time() - (admin.startTime or os.time())) / 60
    )
    notify(executor, "Crumbs Admin", info, 8)
end

local function cmd_save(executor, args)
    if getPlayerRank(executor) < 4 then
        notify(executor, "Crumbs Admin", "You need Manager rank (4) to save locations.", 3)
        return
    end
    
    if #args < 1 then 
        notify(executor, "Crumbs Admin", "Usage: ,save <location name>", 3)
        return 
    end
    
    if not executor.Character or not executor.Character:FindFirstChild("HumanoidRootPart") then
        notify(executor, "Crumbs Admin", "You have no character.", 3)
        return
    end
    
    local name = table.concat(args, " ")
    savedLocations[name] = {
        cframe = executor.Character.HumanoidRootPart.CFrame,
        savedBy = executor.Name,
        time = os.time()
    }
    
    notify(executor, "Crumbs Admin", "Saved location: " .. name, 3)
end

local function cmd_load(executor, args)
    if getPlayerRank(executor) < 4 then
        notify(executor, "Crumbs Admin", "You need Manager rank (4) to load locations.", 3)
        return
    end
    
    if #args < 1 then 
        notify(executor, "Crumbs Admin", "Usage: ,load <location name>", 3)
        return 
    end
    
    local name = table.concat(args, " ")
    
    if not savedLocations[name] then
        notify(executor, "Crumbs Admin", "Location not found: " .. name, 3)
        return
    end
    
    if not executor.Character or not executor.Character:FindFirstChild("HumanoidRootPart") then
        notify(executor, "Crumbs Admin", "You have no character.", 3)
        return
    end
    
    executor.Character.HumanoidRootPart.CFrame = savedLocations[name].cframe
    notify(executor, "Crumbs Admin", "Loaded location: " .. name, 3)
end

local function cmd_locations(executor, args)
    if getPlayerRank(executor) < 4 then
        notify(executor, "Crumbs Admin", "You need Manager rank (4) to view locations.", 3)
        return
    end
    
    local list = {}
    for name, _ in pairs(savedLocations) do
        table.insert(list, name)
    end
    
    if #list == 0 then
        notify(executor, "Crumbs Admin", "No saved locations.", 3)
    else
        notify(executor, "Crumbs Admin", "Saved locations: " .. table.concat(list, ", "), 5)
    end
end

local function cmd_removelocation(executor, args)
    if getPlayerRank(executor) < 4 then
        notify(executor, "Crumbs Admin", "You need Manager rank (4) to remove locations.", 3)
        return
    end
    
    if #args < 1 then 
        notify(executor, "Crumbs Admin", "Usage: ,removelocation <name>", 3)
        return 
    end
    
    local name = table.concat(args, " ")
    
    if not savedLocations[name] then
        notify(executor, "Crumbs Admin", "Location not found: " .. name, 3)
        return
    end
    
    savedLocations[name] = nil
    notify(executor, "Crumbs Admin", "Removed location: " .. name, 3)
end

local function cmd_rank(executor, args)
    if getPlayerRank(executor) < 4 then
        notify(executor, "Crumbs Admin", "You need Manager rank (4) to set ranks.", 3)
        return
    end
    
    if #args < 2 then 
        notify(executor, "Crumbs Admin", "Usage: ,rank <player> <rank (0-4)>", 3)
        return 
    end
    
    local targets = findPlayer(args[1], executor)
    if not targets then
        notify(executor, "Crumbs Admin", "Player not found.", 3)
        return
    end
    
    local target = targets[1]
    local newRank = tonumber(args[2]) or 0
    
    if newRank < 0 or newRank > 4 then
        notify(executor, "Crumbs Admin", "Rank must be between 0 and 4.", 3)
        return
    end
    
    tempRanks[target.UserId] = newRank
    notify(executor, "Crumbs Admin", "Set " .. target.Name .. "'s rank to " .. RANK_NAMES[newRank], 3)
    notify(target, "Crumbs Admin", "Your rank has been set to " .. RANK_NAMES[newRank], 3)
    logAdminAction(executor, "RANK", target, "Set rank to " .. RANK_NAMES[newRank])
end

local function cmd_shutdown(executor, args)
    if getPlayerRank(executor) < 4 then
        notify(executor, "Crumbs Admin", "You need Manager rank (4) to shutdown.", 3)
        return
    end
    
    local seconds = args[1] and tonumber(args[1]) or 30
    if seconds < 5 then seconds = 5 end
    if seconds > 60 then seconds = 60 end
    
    notifyAll("⚠️ SERVER SHUTDOWN", "Server shutting down in " .. seconds .. " seconds!", 8)
    logAdminAction(executor, "SHUTDOWN", nil, "Initiating shutdown in " .. seconds .. "s")
    
    for i = seconds, 1, -1 do
        if i <= 10 or i % 10 == 0 then
            notifyAll("⚠️ SERVER SHUTDOWN", "Shutting down in " .. i .. " seconds!", 3)
        end
        task.wait(1)
    end
    
    for _, player in ipairs(Players:GetPlayers()) do
        player:Kick("Server is shutting down.")
    end
    
    task.wait(1)
    game:Shutdown()
end

local function cmd_eject(executor, args)
    if getPlayerRank(executor) < 4 then
        notify(executor, "Crumbs Admin", "You need Manager rank (4) to eject.", 3)
        return
    end
    
    notifyAll("Crumbs Admin", "Crumbs Admin is shutting down...", 3)
    task.wait(1)
    
    -- Clean up connections
    for userId, _ in pairs(activePunishments) do
        if activePunishments[userId .. "_conn"] then
            activePunishments[userId .. "_conn"]:Disconnect()
        end
    end
    
    for userId, _ in pairs(activeLoopKills) do
        if activeLoopKills[userId .. "_conn"] then
            activeLoopKills[userId .. "_conn"]:Disconnect()
        end
    end
    
    -- Destroy the script
    script:Destroy()
end

local function cmd_logs(executor, args)
    if getPlayerRank(executor) < 3 then
        notify(executor, "Crumbs Admin", "You need Baker rank (3) to view logs.", 3)
        return
    end
    
    local count = args[1] and tonumber(args[1]) or 10
    if count > 50 then count = 50 end
    
    local logText = "Recent admin logs:\n"
    local startIdx = math.max(1, #adminLogs - count + 1)
    
    for i = startIdx, #adminLogs do
        local log = adminLogs[i]
        local timeStr = os.date("%H:%M:%S", log.timestamp)
        logText = logText .. string.format("[%s] %s: %s\n", timeStr, log.admin, log.action)
    end
    
    notify(executor, "Crumbs Admin", logText, 10)
end

local function cmd_help(executor, args)
    openDashboard(executor, "Commands")
end

-- Command definitions with rank requirements
local COMMANDS = {
    -- Rank 0 (Everyone)
    help = {func = cmd_help, rank = 0, aliases = {"cmds", "commands", "menu"}, minArgs = 0},
    players = {func = cmd_players, rank = 0, aliases = {"list"}, minArgs = 0},
    staff = {func = cmd_staff, rank = 0, aliases = {"admins"}, minArgs = 0},
    serverinfo = {func = cmd_serverinfo, rank = 0, aliases = {"info", "si"}, minArgs = 0},
    rj = {func = cmd_rj, rank = 0, aliases = {"rejoin", "reconnect"}, minArgs = 0},
    
    -- Rank 1 (Customer)
    punish = {func = cmd_punish, rank = 1, aliases = {"p", "deletechar"}, minArgs = 1},
    kill = {func = cmd_kill, rank = 1, aliases = {"k", "slay"}, minArgs = 1},
    freeze = {func = cmd_freeze, rank = 1, aliases = {"fz", "anchor"}, minArgs = 1},
    unfreeze = {func = cmd_unfreeze, rank = 1, aliases = {"ufz", "unanchor"}, minArgs = 1},
    noclip = {func = cmd_noclip, rank = 1, aliases = {"nc", "ghost"}, minArgs = 1},
    clip = {func = cmd_clip, rank = 1, aliases = {"c", "collide"}, minArgs = 1},
    void = {func = cmd_void, rank = 1, aliases = {"v", "underworld"}, minArgs = 1},
    skydive = {func = cmd_skydive, rank = 1, aliases = {"sky", "launch"}, minArgs = 1},
    tp = {func = cmd_tp, rank = 1, aliases = {"teleport", "goto"}, minArgs = 2},
    bring = {func = cmd_bring, rank = 1, aliases = {"b", "fetch"}, minArgs = 1},
    invisible = {func = cmd_invisible, rank = 1, aliases = {"inv", "hide"}, minArgs = 1},
    visible = {func = cmd_visible, rank = 1, aliases = {"vis", "show"}, minArgs = 1},
    mute = {func = cmd_mute, rank = 1, aliases = {"silence"}, minArgs = 1},
    unmute = {func = cmd_unmute, rank = 1, aliases = {"unsilence"}, minArgs = 1},
    
    -- Rank 2 (Cashier)
    loopkill = {func = cmd_loopkill, rank = 2, aliases = {"lk", "autokill"}, minArgs = 1},
    unloopkill = {func = cmd_unloopkill, rank = 2, aliases = {"unlk", "stopkill"}, minArgs = 1},
    looppunish = {func = cmd_looppunish, rank = 2, aliases = {"lp", "autopunish"}, minArgs = 1},
    unlooppunish = {func = cmd_unlooppunish, rank = 2, aliases = {"unlp", "stoppunish"}, minArgs = 1},
    god = {func = cmd_god, rank = 2, aliases = {"godmode"}, minArgs = 1},
    fly = {func = cmd_fly, rank = 2, aliases = {"flight"}, minArgs = 1},
    
    -- Rank 3 (Baker)
    kick = {func = cmd_kick, rank = 3, aliases = {"kck"}, minArgs = 1},
    ban = {func = cmd_ban, rank = 3, aliases = {"b"}, minArgs = 1},
    unban = {func = cmd_unban, rank = 3, aliases = {"ub", "pardon"}, minArgs = 1},
    clear = {func = cmd_clear, rank = 3, aliases = {"clean", "wipe"}, minArgs = 0},
    announce = {func = cmd_announce, rank = 3, aliases = {"say", "broadcast"}, minArgs = 1},
    logs = {func = cmd_logs, rank = 3, aliases = {"adminlogs"}, minArgs = 0},
    
    -- Rank 4 (Manager)
    rank = {func = cmd_rank, rank = 4, aliases = {"setrank"}, minArgs = 2},
    save = {func = cmd_save, rank = 4, aliases = {"saveloc"}, minArgs = 1},
    load = {func = cmd_load, rank = 4, aliases = {"loadloc"}, minArgs = 1},
    locations = {func = cmd_locations, rank = 4, aliases = {"locs"}, minArgs = 0},
    removelocation = {func = cmd_removelocation, rank = 4, aliases = {"delloc"}, minArgs = 1},
    shutdown = {func = cmd_shutdown, rank = 4, aliases = {"restart"}, minArgs = 0},
    eject = {func = cmd_eject, rank = 4, aliases = {"unload", "exit"}, minArgs = 0},
}

-- Build alias map
local ALIAS_MAP = {}
for cmdName, cmdData in pairs(COMMANDS) do
    ALIAS_MAP[cmdName] = cmdName
    for _, alias in ipairs(cmdData.aliases) do
        ALIAS_MAP[alias] = cmdName
    end
end

-- Parse command function
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

-- Handle commands from client
commandRemote.OnServerEvent:Connect(function(player, commandText)
    local cmd, args = parseCommand(commandText)
    if not cmd then return end
    
    -- Check if player is banned
    if bannedPlayers[player.UserId] then
        local banData = bannedPlayers[player.UserId]
        if banData.expiry and os.time() > banData.expiry then
            bannedPlayers[player.UserId] = nil
        else
            notify(player, "Crumbs Admin", "You are banned from using admin commands.", 3)
            return
        end
    end
    
    -- Check if player is muted
    if mutedPlayers[player.UserId] and cmd ~= "unmute" then
        return -- Silently block commands
    end
    
    local realCmd = ALIAS_MAP[cmd]
    if not realCmd then
        notify(player, "Crumbs Admin", "Unknown command. Type " .. PREFIX .. "help", 3)
        return
    end
    
    local cmdData = COMMANDS[realCmd]
    local playerRank = getPlayerRank(player)
    
    if playerRank < cmdData.rank then
        notify(player, "Crumbs Admin", "You need " .. RANK_NAMES[cmdData.rank] .. " rank (" .. cmdData.rank .. ") to use this command.", 3)
        return
    end
    
    if #args < cmdData.minArgs then
        notify(player, "Crumbs Admin", "Usage: " .. PREFIX .. realCmd .. " <required args>", 3)
        return
    end
    
    local success, err = pcall(cmdData.func, player, args)
    if not success then
        warn("Command error from", player.Name, ":", err)
        notify(player, "Crumbs Admin", "Command failed: " .. tostring(err), 5)
    end
end)

-- Client GUI script (sent to each player)
local clientScript = [[
local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TextChatService = game:GetService("TextChatService")
local RunService = game:GetService("RunService")

local player = Players.LocalPlayer

-- Wait for admin folder
local adminFolder = ReplicatedStorage:WaitForChild("CrumbsAdmin")
local commandRemote = adminFolder:WaitForChild("CommandRemote")
local notificationRemote = adminFolder:WaitForChild("NotificationRemote")
local dashboardRemote = adminFolder:WaitForChild("DashboardRemote")
local guiRemote = adminFolder:WaitForChild("GUIRemote")

-- State
local notificationStack = {}
local cmdBarVisible = false
local currentDashboard = nil
local flyEnabled = false
local flyConnection = nil
local colors = {}

-- Color conversion function
local function rgb(colorTable)
    return Color3.fromRGB(colorTable[1], colorTable[2], colorTable[3])
end

-- Create main GUI
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "CrumbsAdminGUI"
screenGui.Parent = player:WaitForChild("PlayerGui")
screenGui.ResetOnSpawn = false
screenGui.IgnoreGuiInset = true
screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling

-- Command Bar
local cmdBarFrame = Instance.new("Frame")
cmdBarFrame.Size = UDim2.new(0.5, 0, 0.08, 0)
cmdBarFrame.Position = UDim2.new(0.25, 0, 1.2, 0)
cmdBarFrame.BackgroundTransparency = 1
cmdBarFrame.Visible = false
cmdBarFrame.Parent = screenGui

local cmdBarTextBox = Instance.new("TextBox")
cmdBarTextBox.Size = UDim2.new(1, -4, 1, -4)
cmdBarTextBox.Position = UDim2.new(0, 2, 0, 2)
cmdBarTextBox.BackgroundColor3 = Color3.new(0.4, 0.3, 0.2) -- Will be updated from server
cmdBarTextBox.TextColor3 = Color3.new(1, 1, 1)
cmdBarTextBox.TextSize = 18
cmdBarTextBox.Font = Enum.Font.SourceSans
cmdBarTextBox.PlaceholderText = "Enter command... ( , )"
cmdBarTextBox.PlaceholderColor3 = Color3.new(0.8, 0.7, 0.5)
cmdBarTextBox.ClearTextOnFocus = false
cmdBarTextBox.Text = ""
cmdBarTextBox.Parent = cmdBarFrame

local textBoxCorner = Instance.new("UICorner")
textBoxCorner.CornerRadius = UDim.new(0, 10)
textBoxCorner.Parent = cmdBarTextBox

-- Watermark
local watermark = Instance.new("Frame")
watermark.Size = UDim2.new(0, 200, 0, 30)
watermark.Position = UDim2.new(0, 10, 0, 10)
watermark.BackgroundColor3 = Color3.new(0.3, 0.2, 0.1)
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
watermarkText.TextColor3 = Color3.new(0.8, 0.7, 0.5)
watermarkText.TextSize = 14
watermarkText.Font = Enum.Font.GothamBold
watermarkText.TextXAlignment = Enum.TextXAlignment.Left
watermarkText.Parent = watermark

-- Command bar animation
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

-- Input handling
UserInputService.InputBegan:Connect(function(input, gameProcessed)
    if not gameProcessed and input.UserInputType == Enum.UserInputType.Keyboard and input.KeyCode == Enum.KeyCode.Comma then
        cmdBarVisible = not cmdBarVisible
        animateTextBox(cmdBarVisible)
    end
end)

cmdBarTextBox.FocusLost:Connect(function(enterPressed)
    if enterPressed then
        local commandText = cmdBarTextBox.Text
        cmdBarTextBox.Text = ""
        cmdBarVisible = false
        animateTextBox(false)
        commandRemote:FireServer(commandText)
    else
        cmdBarVisible = false
        animateTextBox(false)
    end
end)

-- Chat command handling
if TextChatService.ChatVersion == Enum.ChatVersion.TextChatService then
    TextChatService.OnIncomingMessage = function(message)
        if message.TextSource and message.TextSource.UserId == player.UserId then
            if string.sub(message.Text, 1, 1) == "," then
                commandRemote:FireServer(message.Text)
                return Enum.IncomingMessageResponse.Cancel
            end
        end
        return Enum.IncomingMessageResponse.Default
    end
else
    player.Chatted:Connect(function(message)
        if string.sub(message, 1, 1) == "," then
            commandRemote:FireServer(message)
        end
    end)
end

-- Notification system
notificationRemote.OnClientEvent:Connect(function(title, message, duration, colorTable)
    colors = colorTable or colors
    duration = duration or 4
    
    local CHOCOLATE = rgb(colors.CHOCOLATE or {74,49,28})
    local MILK_CHOCOLATE = rgb(colors.MILK_CHOCOLATE or {111,78,55})
    local LIGHT_CHOCOLATE = rgb(colors.LIGHT_CHOCOLATE or {139,90,43})
    local COOKIE_DOUGH = rgb(colors.COOKIE_DOUGH or {210,180,140})
    local OFF_WHITE = rgb(colors.OFF_WHITE or {240,240,240})
    
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
    for i = #notificationStack, 1, -1 do
        if not notificationStack[i] or not notificationStack[i].gui or not notificationStack[i].gui.Parent then
            table.remove(notificationStack, i)
        end
    end

    -- Calculate position
    local yOffset = 10
    for _, entry in ipairs(notificationStack) do
        yOffset = yOffset + entry.height + 6
    end
    
    -- Create notification
    local notifGui = Instance.new("ScreenGui")
    notifGui.Name = "Notification_" .. tick()
    notifGui.ResetOnSpawn = false
    notifGui.Parent = player.PlayerGui
    notifGui.IgnoreGuiInset = true
    notifGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    
    local notifFrame = Instance.new("Frame")
    notifFrame.Name = "NotificationFrame"
    notifFrame.Size = UDim2.new(0, frameWidth, 0, dynamicHeight)
    notifFrame.Position = UDim2.new(1, -290, 1, -(yOffset + dynamicHeight))
    notifFrame.BackgroundColor3 = CHOCOLATE
    notifFrame.BackgroundTransparency = 1
    notifFrame.BorderSizePixel = 0
    notifFrame.Parent = notifGui
    
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
        gui = notifGui,
        frame = notifFrame,
        height = dynamicHeight,
        yOffset = yOffset
    }
    table.insert(notificationStack, stackEntry)
    
    local closed = false
    
    local function restack()
        local runningOffset = 10
        for _, entry in ipairs(notificationStack) do
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
        
        for i, entry in ipairs(notificationStack) do
            if entry.gui == notifGui then
                table.remove(notificationStack, i)
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
            if notifGui and notifGui.Parent then
                notifGui:Destroy()
            end
        end)
    end
    
    closeButton.MouseButton1Click:Connect(closeNotif)
    
    -- Animate in
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
end)

-- Dashboard system
dashboardRemote.OnClientEvent:Connect(function(action, defaultTab, colorTable, rankNames, prefix)
    colors = colorTable or colors
    local CHOCOLATE = rgb(colors.CHOCOLATE or {74,49,28})
    local MILK_CHOCOLATE = rgb(colors.MILK_CHOCOLATE or {111,78,55})
    local LIGHT_CHOCOLATE = rgb(colors.LIGHT_CHOCOLATE or {139,90,43})
    local COOKIE_DOUGH = rgb(colors.COOKIE_DOUGH or {210,180,140})
    local OFF_WHITE = rgb(colors.OFF_WHITE or {240,240,240})
    
    if action ~= "Open" then return end
    
    -- Close existing dashboard
    if currentDashboard and currentDashboard.Parent then
        currentDashboard:Destroy()
        currentDashboard = nil
    end
    
    -- Create dashboard
    local dashboardGui = Instance.new("ScreenGui")
    dashboardGui.Name = "CrumbsDashboard"
    dashboardGui.ResetOnSpawn = false
    dashboardGui.Parent = player.PlayerGui
    dashboardGui.IgnoreGuiInset = true
    dashboardGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    currentDashboard = dashboardGui
    
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
        {role = "Developer", name = "Crumbs Admin Team", desc = "Server-side admin system v3.0"},
        {role = "GUI Designer", name = "Enhanced Interface", desc = "Smooth animations and notifications"},
        {role = "Version", name = "Crumbs Admin SS v3.0", desc = "Full server-side with client GUI"},
        {role = "Features", name = "40+ Commands", desc = "Complete admin toolkit"},
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
    specialThanks.Text = "Crumbs Admin v3.0 - Full Server-Side"
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
        commandLabel.Text = counter .. " | " .. prefix .. cmd.name
        commandLabel.TextColor3 = OFF_WHITE
        commandLabel.TextSize = 15
        commandLabel.Font = Enum.Font.GothamBold
        commandLabel.TextXAlignment = Enum.TextXAlignment.Left
        commandLabel.Parent = commandFrame
    
        local descLabel = Instance.new("TextLabel")
        descLabel.Size = UDim2.new(1, -12, 0, 22)
        descLabel.Position = UDim2.new(0, 6, 0, 22)
        descLabel.BackgroundTransparency = 1
        descLabel.Text = "Rank: " .. (rankNames[cmd.rank] or "User") .. " (" .. cmd.rank .. ") - " .. cmd.desc
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
        usageLabel.Text = "Usage: " .. prefix .. cmd.name .. " <player>"
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
        currentDashboard = nil
    end)
end)

-- Welcome message
task.wait(1)
notificationRemote:FireServer("ClientLoaded")
]]

-- Send client script to players
local function setupClient(player)
    -- Check if player is banned
    if bannedPlayers[player.UserId] then
        local banData = bannedPlayers[player.UserId]
        if banData.expiry and os.time() > banData.expiry then
            bannedPlayers[player.UserId] = nil
        else
            local durationText = banData.expiry and " for " .. math.floor((banData.expiry - os.time()) / 60) .. " minutes" or " permanently"
            player:Kick("You are banned" .. durationText .. "\nReason: " .. banData.reason)
            return
        end
    end
    
    -- Create and parent client script
    local module = Instance.new("LocalScript")
    module.Name = "CrumbsClient"
    module.Source = clientScript
    module.Parent = player:WaitForChild("PlayerGui")
    
    -- Send welcome notification
    task.wait(1)
    notify(player, "Crumbs Admin", "Welcome! Your rank: " .. RANK_NAMES[getPlayerRank(player)], 4)
end

-- Player connection handling
Players.PlayerAdded:Connect(setupClient)

for _, player in ipairs(Players:GetPlayers()) do
    task.spawn(function()
        setupClient(player)
    end)
end

Players.PlayerRemoving:Connect(function(player)
    -- Clean up data
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

-- Loop handlers
task.spawn(function()
    admin.startTime = os.time()
    while true do
        task.wait(0.5)
        
        -- Loop kill handler
        for userId, enabled in pairs(activeLoopKills) do
            if enabled then
                local player = Players:GetPlayerByUserId(userId)
                if player and player.Character then
                    local head = getPlayerHead(player)
                    if head then head:Destroy() end
                end
            end
        end
        
        -- Loop punish handler
        for userId, enabled in pairs(activePunishments) do
            if enabled then
                local player = Players:GetPlayerByUserId(userId)
                if player and player.Character then
                    player.Character:Destroy()
                end
            end
        end
        
        -- God mode handler
        for userId, enabled in pairs(godModePlayers) do
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
        
        -- Fly mode handler
        for userId, enabled in pairs(flyModePlayers) do
            if enabled then
                local player = Players:GetPlayerByUserId(userId)
                if player and player.Character and player.Character:FindFirstChild("HumanoidRootPart") then
                    local root = player.Character.HumanoidRootPart
                    local humanoid = getPlayerHumanoid(player)
                    
                    if humanoid then
                        humanoid.PlatformStand = true
                        local moveDirection = humanoid.MoveDirection
                        if moveDirection.Magnitude > 0 then
                            root.Velocity = moveDirection * 50
                        else
                            root.Velocity = Vector3.new(0, 0, 0)
                        end
                    end
                end
            end
        end
        
        -- Ban expiration checker
        local now = os.time()
        for userId, banData in pairs(bannedPlayers) do
            if banData.expiry and now > banData.expiry then
                bannedPlayers[userId] = nil
                activePunishments[userId] = nil
            end
        end
    end
end)

-- Mute chat filter (optional)
if TextChatService.ChatVersion == Enum.ChatVersion.TextChatService then
    TextChatService.OnIncomingMessage = function(message)
        local player = Players:GetPlayerByUserId(message.TextSource.UserId)
        if player and mutedPlayers[player.UserId] then
            return Enum.IncomingMessageResponse.Cancel
        end
        return Enum.IncomingMessageResponse.Default
    end
else
    for _, player in ipairs(Players:GetPlayers()) do
        player.Chatted:Connect(function(msg)
            if mutedPlayers[player.UserId] then
                return true -- Block message
            end
        end)
    end
    
    Players.PlayerAdded:Connect(function(player)
        player.Chatted:Connect(function(msg)
            if mutedPlayers[player.UserId] then
                return true -- Block message
            end
        end)
    end)
end

-- Initialize
notifyAll("Crumbs Admin", "Crumbs Admin v3.0 has loaded!\nType " .. PREFIX .. "help for commands", 5)

print("=== Crumbs Admin v3.0 ===")
print("Type: FULLY SERVER-SIDE")
print("Prefix: " .. PREFIX)
print("Players online: " .. #Players:GetPlayers())
print("=========================")
