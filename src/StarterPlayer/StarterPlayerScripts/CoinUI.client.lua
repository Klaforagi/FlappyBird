-- CoinUI.client.lua
-- Displays the player's coin count in the bottom right

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local player = game.Players.LocalPlayer
local coinEvent = ReplicatedStorage:WaitForChild("CoinUpdateEvent")

-- Create UI
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "CoinGui"
screenGui.Parent = player:WaitForChild("PlayerGui")

local coinLabel = Instance.new("TextLabel")
coinLabel.Name = "CoinLabel"
coinLabel.Size = UDim2.new(0, 180, 0, 50)
coinLabel.Position = UDim2.new(1, -190, 1, -60) -- Bottom right
coinLabel.AnchorPoint = Vector2.new(0, 0)
coinLabel.BackgroundTransparency = 0.4
coinLabel.BackgroundColor3 = Color3.fromRGB(255, 215, 0)
coinLabel.TextColor3 = Color3.fromRGB(0, 0, 0)
coinLabel.Font = Enum.Font.FredokaOne
coinLabel.TextScaled = true
coinLabel.Text = "Coins: 0"
coinLabel.Parent = screenGui

-- Update coin count
local function updateCoins(amount)
	coinLabel.Text = "Coins: " .. tostring(amount)
end

coinEvent.OnClientEvent:Connect(updateCoins)
