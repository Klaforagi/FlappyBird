local Players = game:GetService("Players")
local checkpointsFolder = workspace:WaitForChild("Checkpoints")

-- Collect all checkpoint parts with their values
local function getCheckpointParts()
	local list = {}
	for _, obj in ipairs(checkpointsFolder:GetChildren()) do
		if obj:IsA("BasePart") then
			local v = obj:GetAttribute("Value")
			if v and type(v) == "number" then
				table.insert(list, {Value = v, Part = obj})
			end
		end
	end
	table.sort(list, function(a, b) return a.Value < b.Value end)
	return list
end

-- Find highest checkpoint <= given stage
local function getRespawnCheckpoint(stageValue, checkpointParts)
	local best = nil
	for _, data in ipairs(checkpointParts) do
		if data.Value <= stageValue then
			best = data
		end
	end
	return best
end

Players.PlayerAdded:Connect(function(player)
	player.CharacterAdded:Connect(function(char)
		local hrp = char:WaitForChild("HumanoidRootPart")
		-- Wait for leaderstats to exist and get Stage value
		local leaderstats = player:FindFirstChild("leaderstats") or player:WaitForChild("leaderstats")
		local stageVal = leaderstats:FindFirstChild("Stage")
		local currentStage = (stageVal and stageVal.Value) or 0

		-- Always re-get checkpoints in case they changed
		local checkpointParts = getCheckpointParts()
		local checkpointData = getRespawnCheckpoint(currentStage, checkpointParts)
		if checkpointData and hrp then
			hrp.CFrame = checkpointData.Part.CFrame + Vector3.new(0, 4, 0)
			-- Set Stage value to checkpoint value after respawn
			if stageVal then
				stageVal.Value = checkpointData.Value
			end
		end
	end)
end)
