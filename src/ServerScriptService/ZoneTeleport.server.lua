local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

-- Ensure RemoteEvent exists
local teleportEvent = ReplicatedStorage:FindFirstChild("ZoneTeleportEvent")
if not teleportEvent then
	teleportEvent = Instance.new("RemoteEvent")
	teleportEvent.Name = "ZoneTeleportEvent"
	teleportEvent.Parent = ReplicatedStorage
end

-- Zones (match client)
local Zones = {
	{ name = "Green Meadows", xMin = nil,        xMax = 1360.450 },
	{ name = "Sunny Beach",   xMin = 1360.451,   xMax = 2982.672 },
	{ name = "Sakura Fields", xMin = 2982.673,   xMax = 4648.372 },
	{ name = "Snowland",      xMin = 4648.373,   xMax = 6309.000 },
	{ name = "Haunted Woods", xMin = 6309.001,   xMax = 7971.000 },
}

local ReplicatedStorage = ReplicatedStorage

-- Simple dev check: ReplicatedStorage.DevList (ModuleScript) OR Studio
local function isDeveloper(player)
	local mod = ReplicatedStorage:FindFirstChild("DevList") or ReplicatedStorage:FindFirstChild("DevConfig")
	if mod and mod:IsA("ModuleScript") then
		local ok, list = pcall(require, mod)
		if ok and type(list) == "table" then
			if list[player.UserId] then return true end
			for _, id in ipairs(list) do
				if id == player.UserId then return true end
			end
		end
	end
	if RunService:IsStudio() then return true end
	return false
end

local function getZoneByName(name)
	for _, z in ipairs(Zones) do
		if z.name == name then return z end
	end
	return nil
end

teleportEvent.OnServerEvent:Connect(function(player, zoneName)
	-- Only allow devs or Studio testing
	if not isDeveloper(player) then
		return
	end

	local z = getZoneByName(zoneName)
	if not z then return end

	-- Try to find a BreakZone part whose X position falls inside the zone range
	local Workspace = game:GetService("Workspace")
	local function findBreakZonePartForZone(zone)
		for _, obj in ipairs(Workspace:GetDescendants()) do
			if obj:IsA("BasePart") and obj.Name == "BreakZone" then
				local px = obj.Position.X
				local minOk = (not zone.xMin) or (px >= zone.xMin)
				local maxOk = (not zone.xMax) or (px <= zone.xMax)
				if minOk and maxOk then
					return obj
				end
			end
		end
		return nil
	end

	local targetPart = findBreakZonePartForZone(z)
	local character = player.Character
	if not character then return end
	local hrp = character:FindFirstChild("HumanoidRootPart")
	if not hrp then return end

	if targetPart then
		-- Teleport to center of the found BreakZone (slightly above)
		hrp.CFrame = targetPart.CFrame + Vector3.new(0, 4, 0)
		return
	end

	-- Fallback: compute mid X and teleport there
	local xMin = z.xMin or (z.xMax and (z.xMax - 2000) ) or 0
	local xMax = z.xMax or (z.xMin and (z.xMin + 2000)) or 0
	local midX = ( (xMin ~= nil and xMin or 0) + (xMax ~= nil and xMax or 0) ) / 2
	local targetY = 10
	local targetZ = hrp.Position.Z
	hrp.CFrame = CFrame.new(midX, targetY, targetZ)
end)
