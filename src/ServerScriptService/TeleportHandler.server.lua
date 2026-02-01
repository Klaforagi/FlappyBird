local teleportPadsFolder = workspace:WaitForChild("TeleportPads")
local checkpointsFolder = workspace:WaitForChild("Checkpoints")
local Players = game:GetService("Players")

-- Recursively get all BaseParts in folder or model
local function getAllPads(parent)
	local pads = {}
	for _, obj in ipairs(parent:GetChildren()) do
		if obj:IsA("BasePart") then
			table.insert(pads, obj)
		elseif obj:IsA("Model") or obj:IsA("Folder") then
			-- Search inside models/folders recursively
			for _, pad in ipairs(getAllPads(obj)) do
				table.insert(pads, pad)
			end
		end
	end
	return pads
end

local function getCheckpointPart(targetValue)
	for _, part in ipairs(checkpointsFolder:GetChildren()) do
		if part:IsA("BasePart") and part:GetAttribute("Value") == targetValue then
			return part
		end
	end
	return nil
end

-- Attach touch event to every pad found (even inside groups)
for _, pad in ipairs(getAllPads(teleportPadsFolder)) do
	pad.Touched:Connect(function(hit)
		local character = hit and hit.Parent
		local humanoid = character and character:FindFirstChildWhichIsA("Humanoid")
		if not (character and humanoid and humanoid.Health > 0) then return end

		local player = Players:GetPlayerFromCharacter(character)
		if not player then return end

		local targetValue = pad:GetAttribute("TargetValue")
		if not targetValue then return end

		local checkpoint = getCheckpointPart(targetValue)
		if checkpoint then
			local hrp = character:FindFirstChild("HumanoidRootPart")
			if hrp then
				hrp.CFrame = checkpoint.CFrame + Vector3.new(0, 4, 0)
				print(player.Name .. " teleported to checkpoint with value " .. tostring(targetValue))
			end
		end
	end)
end
