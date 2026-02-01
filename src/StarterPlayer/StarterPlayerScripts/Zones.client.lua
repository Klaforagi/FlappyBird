local player = game.Players.LocalPlayer
local workspace = game:GetService("Workspace")
local runService = game:GetService("RunService")

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

	runService.RenderStepped:Connect(function()
		local hrp = char:FindFirstChild("HumanoidRootPart")
		if not hrp then return end

		-- Get all current StartZones/BreakZones every frame (handles streaming, respawn, dynamic parts)
		local startZones, breakZones = {}, {}
		for _, obj in ipairs(workspace:GetDescendants()) do
			if obj:IsA("BasePart") and obj.Name == "StartZone" then
				table.insert(startZones, obj)
			elseif obj:IsA("BasePart") and obj.Name == "BreakZone" then
				table.insert(breakZones, obj)
			end
		end

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

player.CharacterAdded:Connect(function(char)
	char:WaitForChild("HumanoidRootPart")
	connectZoneDetection(char)
end)

if player.Character then
	connectZoneDetection(player.Character)
end
