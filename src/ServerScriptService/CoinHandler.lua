-- CoinHandler.lua (ModuleScript)
-- Handles coin tracking, saving, and awarding for players

local DataStoreService = game:GetService("DataStoreService")
local coinStore = DataStoreService:GetDataStore("PlayerCoins")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- RemoteEvent for coin updates
local coinEvent = ReplicatedStorage:FindFirstChild("CoinUpdateEvent")
if not coinEvent then
    local newEvent = Instance.new("RemoteEvent")
    newEvent.Name = "CoinUpdateEvent"
    newEvent.Parent = ReplicatedStorage
    coinEvent = newEvent
end

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

local CoinHandler = {}

function CoinHandler.awardCoins(player, amount)
    if not player or not amount then return end
    print("[CoinHandler] Awarding", amount, "coin(s) to", player.Name)
    playerCoins[player] = (playerCoins[player] or 0) + amount
    coinEvent:FireClient(player, playerCoins[player])
end

function CoinHandler.init()
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

    -- Ensure Events folder and CoinPickupEvent exist in ReplicatedStorage
    local eventsFolder = ReplicatedStorage:FindFirstChild("Events")
    if not eventsFolder then
        eventsFolder = Instance.new("Folder")
        eventsFolder.Name = "Events"
        eventsFolder.Parent = ReplicatedStorage
    end

    local pickupEvent = eventsFolder:FindFirstChild("CoinPickupEvent")
    if not pickupEvent then
        pickupEvent = Instance.new("RemoteEvent")
        pickupEvent.Name = "CoinPickupEvent"
        pickupEvent.Parent = eventsFolder
    end

    pickupEvent.OnServerEvent:Connect(function(player, amount)
        CoinHandler.awardCoins(player, amount)
    end)

    -- Support client requests for current coin count
    local requestEvent = eventsFolder:FindFirstChild("RequestCoinCount")
    if not requestEvent then
        requestEvent = Instance.new("RemoteEvent")
        requestEvent.Name = "RequestCoinCount"
        requestEvent.Parent = eventsFolder
    end

    requestEvent.OnServerEvent:Connect(function(player)
        local coins = playerCoins[player] or 0
        coinEvent:FireClient(player, coins)
    end)

    game:BindToClose(function()
        for player, coins in pairs(playerCoins) do
            saveCoins(player, coins)
        end
    end)
end

return CoinHandler