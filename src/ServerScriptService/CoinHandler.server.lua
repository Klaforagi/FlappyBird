-- CoinHandler.server.lua
-- Handles coin tracking, saving, and awarding for players

local DataStoreService = game:GetService("DataStoreService")
local coinStore = DataStoreService:GetDataStore("PlayerCoins")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- RemoteEvent for coin updates
local coinEvent = Instance.new("RemoteEvent")
coinEvent.Name = "CoinUpdateEvent"
coinEvent.Parent = ReplicatedStorage

-- Helper to load coins
local function loadCoins(player)
	local coins = 0
	local success, result = pcall(function()
		return coinStore:GetAsync(player.UserId)
	end)
	if success and result then
		coins = result
	end
	return coins
end

-- Helper to save coins
local function saveCoins(player, coins)
	pcall(function()
		coinStore:SetAsync(player.UserId, coins)
	end)
end

-- Table to track coins in session
local playerCoins = {}

Players.PlayerAdded:Connect(function(player)
	local coins = loadCoins(player)
	playerCoins[player] = coins
	coinEvent:FireClient(player, coins)
end)

Players.PlayerRemoving:Connect(function(player)
	local coins = playerCoins[player] or 0
	saveCoins(player, coins)
	playerCoins[player] = nil
end)

-- Award coins function
function awardCoins(player, amount)
	if not player or not amount then return end
	playerCoins[player] = (playerCoins[player] or 0) + amount
	coinEvent:FireClient(player, playerCoins[player])
end

-- Example: Coin pickup event
ReplicatedStorage:WaitForChild("CoinPickupEvent").OnServerEvent:Connect(function(player, amount)
	awardCoins(player, amount)
end)

-- Save coins on shutdown
game:BindToClose(function()
	for player, coins in pairs(playerCoins) do
		saveCoins(player, coins)
	end
end)
