local Players = game:GetService("Players")
local DataStoreService = game:GetService("DataStoreService")
local highScoreStore = DataStoreService:GetDataStore("FlappyHighScores")

-- Recursive function to collect all parts that are stages
-- Safely find the ModuleScript named "CoinHandler" (avoid requiring a plain Script)
local CoinHandler = nil
for _, child in ipairs(game:GetService("ServerScriptService"):GetChildren()) do
	if child.Name == "CoinHandler" and child.ClassName == "ModuleScript" then
		CoinHandler = require(child)
		break
	end
end
if not CoinHandler then
	warn("[StageHandler] Could not find ModuleScript 'CoinHandler' in ServerScriptService")
end
-- recentTouches[player][stagePart] = last touch time (debounce)
local recentTouches = {}
local function getAllStages(parent)
	local stages = {}
	for _, obj in ipairs(parent:GetChildren()) do
		if obj:IsA("BasePart") then
			table.insert(stages, obj)
		elseif obj:IsA("Folder") or obj:IsA("Model") then
			for _, st in ipairs(getAllStages(obj)) do
				table.insert(stages, st)
			end
		end
	end
	return stages
end

local stages = getAllStages(workspace:WaitForChild("Stages"))
print("[StageHandler] Found " .. #stages .. " stage parts")

local function isAliveCharacter(part)
	local character = part.Parent
	if not character then return nil end

	local humanoid = character:FindFirstChildWhichIsA("Humanoid")
	if not humanoid then return nil end
	if humanoid.Health <= 0 then return nil end

	local player = Players:GetPlayerFromCharacter(character)
	if not player then return nil end

	return player
end

local function onStageTouched(otherPart, stagePart)
	-- Only count touches from the HumanoidRootPart to avoid multiple body-part triggers
	if not otherPart or otherPart.Name ~= "HumanoidRootPart" then
		return
	end

	local player = isAliveCharacter(otherPart)
	if not player then return end

	local stageValue = stagePart:GetAttribute("Value")
	if not stageValue then 
		warn("[StageHandler] Stage part", stagePart.Name, "has no Value attribute!")
		return 
	end

	local stage = player.leaderstats:FindFirstChild("Stage")
	local highScore = player.leaderstats:FindFirstChild("HighScore")
	if not (stage and highScore) then return end

	print("[StageHandler]", player.Name, "touched stage", stageValue)
	
	-- Update current stage
	stage.Value = stageValue

	-- Update high score if this is a new record
	if stageValue > highScore.Value then
		highScore.Value = stageValue
	end
	
	-- Debounce repeated touch events for same player and stage part
	recentTouches[player] = recentTouches[player] or {}
	local now = tick()
	local last = recentTouches[player][stagePart]
	if last and now - last < 0.5 then
		return
	end
	recentTouches[player][stagePart] = now

	-- Award 1 coin immediately when stage number is updated by the stage part
	print("[StageHandler] Awarding 1 coin to", player.Name, "for touching stage part", stagePart.Name, "value", stageValue)
	if CoinHandler then
		CoinHandler.awardCoins(player, 1)
	else
		warn("[StageHandler] CoinHandler module not found; cannot award coins")
	end
end

-- DataStore helpers
local function tryDS(call, ...)
	local ok, res = pcall(call, ...)
	if ok then return res end
	warn("DataStore error:", res)
	return nil
end

Players.PlayerAdded:Connect(function(player)
	local leaderstats = Instance.new("Folder")
	leaderstats.Name = "leaderstats"
	leaderstats.Parent = player

	local stage = Instance.new("IntValue")
	stage.Name = "Stage"
	stage.Value = 0
	stage.Parent = leaderstats

	local highScore = Instance.new("IntValue")
	highScore.Name = "HighScore"
	highScore.Value = 0
	highScore.Parent = leaderstats

	-- LOAD high score from DataStore
	local key = "HighScore_" .. player.UserId
	local storedHigh = tryDS(highScoreStore.GetAsync, highScoreStore, key)
	if storedHigh then
		highScore.Value = storedHigh
	end

	-- CharacterAdded no longer resets Stage - CheckpointHandler handles respawn positioning

	-- No per-player prev tracking needed when stage part handles awarding
end)

Players.PlayerRemoving:Connect(function(player)
	local leaderstats = player:FindFirstChild("leaderstats")
	local highScore = leaderstats and leaderstats:FindFirstChild("HighScore")
	if highScore then
		local key = "HighScore_" .. player.UserId
		tryDS(highScoreStore.SetAsync, highScoreStore, key, highScore.Value)
	end
	-- cleanup debounce table
	recentTouches[player] = nil
end)

for _, stagePart in ipairs(stages) do
	stagePart.Touched:Connect(function(otherPart)
		onStageTouched(otherPart, stagePart)
	end)
end

	-- Initialize CoinHandler module
	CoinHandler.init()
