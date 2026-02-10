local DataStoreService = game:GetService("DataStoreService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local STORE = DataStoreService:GetDataStore("PlayerCheckpoints_v1")
local COST = 10

-- Ensure RemoteEvents exist
local function ensure(name)
	local ev = ReplicatedStorage:FindFirstChild(name)
	if not ev then
		ev = Instance.new("RemoteEvent")
		ev.Name = name
		ev.Parent = ReplicatedStorage
	end
	return ev
end

local RequestEvent = ensure("RequestCheckpoints")
local DataEvent = ensure("CheckpointData")
local PurchaseEvent = ensure("PurchaseCheckpoint")
local PurchaseResponse = ensure("PurchaseResponse")
local ResetEvent = ensure("ResetCheckpoints")

-- Try require CoinHandler
local CoinHandler
pcall(function()
	local mod = script.Parent:FindFirstChild("CoinHandler") or script.Parent:FindFirstChild("CoinHandler.lua")
	if mod then
		CoinHandler = require(mod)
	end
end)

local playerStore = {}

local function load(player)
	local key = "checkpoints_" .. tostring(player.UserId)
	local ok, data = pcall(function() return STORE:GetAsync(key) end)
	if ok and type(data) == "table" then
		playerStore[player] = data
	else
		playerStore[player] = {}
	end
end

local function save(player)
	local key = "checkpoints_" .. tostring(player.UserId)
	local data = playerStore[player] or {}
	pcall(function() STORE:SetAsync(key, data) end)
end

Players.PlayerAdded:Connect(function(player)
	load(player)
end)

Players.PlayerRemoving:Connect(function(player)
	save(player)
	playerStore[player] = nil
end)

-- Client requests their data
RequestEvent.OnServerEvent:Connect(function(player)
	local data = playerStore[player] or {}
	pcall(function() DataEvent:FireClient(player, data) end)
end)

-- Reset player's purchases (client may request to clear their own checkpoints)
ResetEvent.OnServerEvent:Connect(function(player)
	playerStore[player] = {}
	pcall(function()
		local key = "checkpoints_" .. tostring(player.UserId)
		STORE:SetAsync(key, {})
	end)
	-- send updated data back
	pcall(function() DataEvent:FireClient(player, {}) end)
end)

-- Purchase attempts
PurchaseEvent.OnServerEvent:Connect(function(player, zoneName)
	if type(zoneName) ~= "string" then
		PurchaseResponse:FireClient(player, false, zoneName, "invalid")
		return
	end
	local owned = playerStore[player] or {}
	if owned[zoneName] then
		PurchaseResponse:FireClient(player, false, zoneName, "owned")
		return
	end
	-- Attempt to charge
	local charged = false
	if CoinHandler and type(CoinHandler.spendCoins) == "function" then
		charged = CoinHandler.spendCoins(player, COST)
	end
	if not charged then
		PurchaseResponse:FireClient(player, false, zoneName, "nomoney")
		return
	end
	-- Grant
	owned[zoneName] = true
	playerStore[player] = owned
	pcall(function()
		local key = "checkpoints_" .. tostring(player.UserId)
		STORE:SetAsync(key, owned)
	end)
	PurchaseResponse:FireClient(player, true, zoneName, "success")
end)

-- Save on close
game:BindToClose(function()
	for p,_ in pairs(playerStore) do
		pcall(function() save(p) end)
	end
end)
