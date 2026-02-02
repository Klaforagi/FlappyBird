local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Disable automatic respawning - players must click respawn button
Players.CharacterAutoLoads = false

-- Create RemoteEvent for respawn requests
local respawnEvent = Instance.new("RemoteEvent")
respawnEvent.Name = "RespawnEvent"
respawnEvent.Parent = ReplicatedStorage

-- Handle respawn requests from clients
respawnEvent.OnServerEvent:Connect(function(player)
	if player.Character then
		player.Character:Destroy()
	end
	player:LoadCharacter()
end)

-- Spawn players when they first join
Players.PlayerAdded:Connect(function(player)
	player:LoadCharacter()
end)
