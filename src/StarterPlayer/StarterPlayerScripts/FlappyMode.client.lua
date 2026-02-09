local player = game.Players.LocalPlayer
local workspace = game:GetService("Workspace")
local runService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local lastStartIn, lastBreakIn = false, false

-- Utility function: are we inside any part in the list?
local function isInsideAnyZoneParts(pos, parts)
	for _, part in ipairs(parts) do
		if part:IsA("BasePart") then
			local cf, sz = part.CFrame, part.Size
			if math.abs(pos.X - cf.Position.X) <= sz.X/2
				and math.abs(pos.Y - cf.Position.Y) <= sz.Y/2
				and math.abs(pos.Z - cf.Position.Z) <= sz.Z/2 then
				return true
			end
		end
	end
	return false
end

local function connectZoneDetection(char)
	-- Ensure FlappyMode exists on character
	local flappy = char:FindFirstChild("FlappyMode")
	if not flappy then
		flappy = Instance.new("BoolValue")
		flappy.Name = "FlappyMode"
		flappy.Value = false
		flappy.Parent = char
	else
		flappy.Value = false
	end

	-- Cache zones once instead of every frame
	local function getZones()
		local startZones, breakZones = {}, {}
		for _, obj in ipairs(workspace:GetDescendants()) do
			if obj:IsA("BasePart") and obj.Name == "StartZone" then
				table.insert(startZones, obj)
			elseif obj:IsA("BasePart") and obj.Name == "BreakZone" then
				table.insert(breakZones, obj)
			end
		end
		return startZones, breakZones
	end

	local startZones, breakZones = getZones()

	-- Update cache if new zones are added
	workspace.DescendantAdded:Connect(function(obj)
		if obj:IsA("BasePart") then
			if obj.Name == "StartZone" then
				table.insert(startZones, obj)
			elseif obj.Name == "BreakZone" then
				table.insert(breakZones, obj)
			end
		end
	end)

	workspace.DescendantRemoving:Connect(function(obj)
		if obj:IsA("BasePart") then
			if obj.Name == "StartZone" then
				local idx = table.find(startZones, obj)
				if idx then table.remove(startZones, idx) end
			elseif obj.Name == "BreakZone" then
				local idx = table.find(breakZones, obj)
				if idx then table.remove(breakZones, idx) end
			end
		end
	end)

	runService.RenderStepped:Connect(function()
		local hrp = char:FindFirstChild("HumanoidRootPart")
		if not hrp then return end

		local pos = hrp.Position

		-- START ZONE
		local inStart = isInsideAnyZoneParts(pos, startZones)
		if inStart and not lastStartIn then
			if not flappy.Value then
				flappy.Value = true
				print("FlappyMode ENABLED by StartZone!")
			end
		end
		lastStartIn = inStart

		-- BREAK ZONE
		local inBreak = isInsideAnyZoneParts(pos, breakZones)
		if inBreak and not lastBreakIn then
			if flappy.Value then
				flappy.Value = false
				print("FlappyMode DISABLED by BreakZone!")
			end
		end
		lastBreakIn = inBreak
	end)
end

-- Dev helper: press F to enable FlappyMode on your current character (for testing)
local function toggleFlappyForPlayer()
	local char = player.Character
	if not char then return end
	local flappy = char:FindFirstChild("FlappyMode")
	if not flappy then
		flappy = Instance.new("BoolValue")
		flappy.Name = "FlappyMode"
		flappy.Value = true
		flappy.Parent = char
		print("FlappyMode ENABLED (dev key)")
		return
	end

	flappy.Value = not flappy.Value
	if flappy.Value then
		print("FlappyMode ENABLED (dev key)")
	else
		print("FlappyMode DISABLED (dev key)")
	end
end

-- Developer check: allow only certain user IDs to use the dev key.
local function isDeveloper()
	-- Look for a ModuleScript in ReplicatedStorage named 'DevList' or 'DevConfig' that returns a table of userIds
	local mod = ReplicatedStorage:FindFirstChild("DevList") or ReplicatedStorage:FindFirstChild("DevConfig")
	if mod and mod:IsA("ModuleScript") then
		local ok, list = pcall(require, mod)
		if ok and type(list) == "table" then
			-- support both array or map formats
			if list[player.UserId] then return true end
			for _, id in ipairs(list) do
				if id == player.UserId then return true end
			end
		end
	end

	-- Only allow developers listed in the DevList ModuleScript
	return false
end

local IS_DEV = isDeveloper()
if IS_DEV then
	UserInputService.InputBegan:Connect(function(input, gameProcessed)
		if gameProcessed then return end
		if input.UserInputType == Enum.UserInputType.Keyboard and input.KeyCode == Enum.KeyCode.F then
			toggleFlappyForPlayer()
		end
	end)
end

player.CharacterAdded:Connect(function(char)
	char:WaitForChild("HumanoidRootPart")
	connectZoneDetection(char)
end)

if player.Character then
	connectZoneDetection(player.Character)
end
