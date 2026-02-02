local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Disable automatic respawning - players must click play/respawn button
Players.CharacterAutoLoads = false

-- Create RemoteEvents
local respawnEvent = Instance.new("RemoteEvent")
respawnEvent.Name = "RespawnEvent"
respawnEvent.Parent = ReplicatedStorage

local playEvent = Instance.new("RemoteEvent")
playEvent.Name = "PlayEvent"
playEvent.Parent = ReplicatedStorage

local spectateEvent = Instance.new("RemoteEvent")
spectateEvent.Name = "SpectateEvent"
spectateEvent.Parent = ReplicatedStorage

-- Track which players have started playing
local playersPlaying = {}

-- Handle respawn requests from clients (after death)
respawnEvent.OnServerEvent:Connect(function(player)
	if player.Character then
		player.Character:Destroy()
	end
	player:LoadCharacter()
end)

-- Handle play button from main menu
playEvent.OnServerEvent:Connect(function(player)
	playersPlaying[player] = true
	if player.Character then
		player.Character:Destroy()
	end
	player:LoadCharacter()
end)

-- Handle spectate button from main menu (spawn but in spectate mode)
spectateEvent.OnServerEvent:Connect(function(player)
	playersPlaying[player] = true
	if not player.Character then
		player:LoadCharacter()
	end
end)

-- Clean up when player leaves
Players.PlayerRemoving:Connect(function(player)
	playersPlaying[player] = nil
end)

-- DON'T auto-spawn on join - wait for Play button
-- Players.PlayerAdded is not needed anymore since we wait for PlayEvent
