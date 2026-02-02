local PhysicsService = game:GetService("PhysicsService")
local Players = game:GetService("Players")

-- Create collision group for players
local PLAYER_GROUP = "Players"

-- Create the collision group if it doesn't exist
local success, err = pcall(function()
	PhysicsService:RegisterCollisionGroup(PLAYER_GROUP)
end)

-- Make players not collide with each other
PhysicsService:CollisionGroupSetCollidable(PLAYER_GROUP, PLAYER_GROUP, false)

-- Function to set all character parts to the Players collision group
local function setCollisionGroup(character)
	for _, part in ipairs(character:GetDescendants()) do
		if part:IsA("BasePart") then
			part.CollisionGroup = PLAYER_GROUP
		end
	end
	
	-- Handle parts added later (accessories, tools, etc.)
	character.DescendantAdded:Connect(function(part)
		if part:IsA("BasePart") then
			part.CollisionGroup = PLAYER_GROUP
		end
	end)
end

-- Apply to existing and new players
Players.PlayerAdded:Connect(function(player)
	player.CharacterAdded:Connect(function(character)
		-- Wait for character to fully load
		task.wait()
		setCollisionGroup(character)
	end)
	
	-- Handle if character already exists
	if player.Character then
		setCollisionGroup(player.Character)
	end
end)

-- Handle players already in the game
for _, player in ipairs(Players:GetPlayers()) do
	if player.Character then
		setCollisionGroup(player.Character)
	end
	player.CharacterAdded:Connect(function(character)
		task.wait()
		setCollisionGroup(character)
	end)
end
