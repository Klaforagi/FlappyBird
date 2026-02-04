local Workspace = game:GetService("Workspace")
local Players = game:GetService("Players")

local biomeFolder = Workspace:FindFirstChild("Biome") or Workspace:FindFirstChild("biome")
if not biomeFolder then
	warn("BiomeCollisionHandler: workspace.Biome not found; script will wait for it.")
	biomeFolder = Workspace:WaitForChild("Biome", 10) or Workspace:WaitForChild("biome", 10)
	if not biomeFolder then
		warn("BiomeCollisionHandler: workspace.Biome still not found after wait; aborting.")
		return
	end
end

local playersInFlappy = {} -- map player -> bool

local PhysicsService = game:GetService("PhysicsService")

local BIOME_GROUP = "Biome"
local PLAYERS_COLLIDE = "Players_CollideBiome"
local PLAYERS_NO_COLLIDE = "Players_NoCollideBiome"

-- Create collision groups if they don't exist (CreateCollisionGroup errors if exists)
pcall(function() PhysicsService:CreateCollisionGroup(BIOME_GROUP) end)
pcall(function() PhysicsService:CreateCollisionGroup(PLAYERS_COLLIDE) end)
pcall(function() PhysicsService:CreateCollisionGroup(PLAYERS_NO_COLLIDE) end)

-- Configure collisions: biome vs players that should NOT collide = false
pcall(function() PhysicsService:CollisionGroupSetCollidable(BIOME_GROUP, PLAYERS_NO_COLLIDE, false) end)
pcall(function() PhysicsService:CollisionGroupSetCollidable(BIOME_GROUP, PLAYERS_COLLIDE, true) end)

local function setPartToBiomeGroup(part)
	if part:IsA("BasePart") then
		pcall(function() PhysicsService:SetPartCollisionGroup(part, BIOME_GROUP) end)
	end
end

-- Assign all existing biome parts into the BIOME_GROUP
for _, obj in ipairs(biomeFolder:GetDescendants()) do
	setPartToBiomeGroup(obj)
end

biomeFolder.DescendantAdded:Connect(function(desc)
	setPartToBiomeGroup(desc)
end)

local function setCharacterCollisionGroup(character, groupName)
	if not character then return end
	for _, obj in ipairs(character:GetDescendants()) do
		if obj:IsA("BasePart") then
			pcall(function() PhysicsService:SetPartCollisionGroup(obj, groupName) end)
		end
	end
end

local function updatePlayerCollisionForCharacter(player)
	local char = player.Character
	if not char then return end
	local inFlappy = playersInFlappy[player]
	if inFlappy then
		setCharacterCollisionGroup(char, PLAYERS_NO_COLLIDE)
	else
		setCharacterCollisionGroup(char, PLAYERS_COLLIDE)
	end
end

local function onFlappyChanged(player, value)
	playersInFlappy[player] = value
	updatePlayerCollisionForCharacter(player)
end
-- Listen for client notifications about FlappyMode changes (clients create/modify FlappyMode locally)
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local events = ReplicatedStorage:FindFirstChild("Events") or ReplicatedStorage:FindFirstChild("events")
if not events then
	events = Instance.new("Folder")
	events.Name = "Events"
	events.Parent = ReplicatedStorage
end

local flappyEvent = events:FindFirstChild("FlappyModeChanged")
if not flappyEvent then
	flappyEvent = Instance.new("RemoteEvent")
	flappyEvent.Name = "FlappyModeChanged"
	flappyEvent.Parent = events
end

flappyEvent.OnServerEvent:Connect(function(player, value)
	if type(value) ~= "boolean" then return end
	onFlappyChanged(player, value)
end)

Players.PlayerAdded:Connect(function(player)
	playersInFlappy[player] = false
	player.CharacterAdded:Connect(function(char)
		updatePlayerCollisionForCharacter(player)
		-- ensure new parts added to character also get correct collision group
		char.DescendantAdded:Connect(function(desc)
			if desc:IsA("BasePart") then
				local inFlappy = playersInFlappy[player]
				local group = inFlappy and PLAYERS_NO_COLLIDE or PLAYERS_COLLIDE
				pcall(function() PhysicsService:SetPartCollisionGroup(desc, group) end)
			end
		end)
	end)
	if player.Character then
		updatePlayerCollisionForCharacter(player)
		-- connect descendant added for existing character
		player.Character.DescendantAdded:Connect(function(desc)
			if desc:IsA("BasePart") then
				local inFlappy = playersInFlappy[player]
				local group = inFlappy and PLAYERS_NO_COLLIDE or PLAYERS_COLLIDE
				pcall(function() PhysicsService:SetPartCollisionGroup(desc, group) end)
			end
		end)
	end
end)

Players.PlayerRemoving:Connect(function(player)
	playersInFlappy[player] = nil
end)

-- Initialize for existing players (if script starts after some players joined)
for _, player in ipairs(Players:GetPlayers()) do
	playersInFlappy[player] = false
	if player.Character then
		updatePlayerCollisionForCharacter(player)
		player.Character.DescendantAdded:Connect(function(desc)
			if desc:IsA("BasePart") then
				local inFlappy = playersInFlappy[player]
				local group = inFlappy and PLAYERS_NO_COLLIDE or PLAYERS_COLLIDE
				pcall(function() PhysicsService:SetPartCollisionGroup(desc, group) end)
			end
		end)
	end
	player.CharacterAdded:Connect(function()
		updatePlayerCollisionForCharacter(player)
	end)
end
