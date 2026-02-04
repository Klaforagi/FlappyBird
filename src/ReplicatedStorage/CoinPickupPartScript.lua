-- CoinPickupPartScript.lua
-- Example script for a coin part in the world
-- Place this in a coin part (e.g., workspace) and set up the part as needed

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local eventsFolder = ReplicatedStorage:WaitForChild("Events")
local CoinPickupEvent = eventsFolder:WaitForChild("CoinPickupEvent")

local coinPart = script.Parent
local COIN_VALUE = 1 -- Change as needed

coinPart.Touched:Connect(function(hit)
	local player = game.Players:GetPlayerFromCharacter(hit.Parent)
	if player then
		CoinPickupEvent:FireServer(COIN_VALUE)
		coinPart:Destroy()
	end
end)
