local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Lighting = game:GetService("Lighting")

local LocalPlayer = Players.LocalPlayer
local biomeFolder = workspace:WaitForChild("Biome")
local skyboxFolder = ReplicatedStorage:WaitForChild("Skybox")

local currentBiome = nil

-- Get the biome number from part name
local function getBiomeNumber(partName)
	local num = tonumber(partName)
	return num
end

-- Change skybox to match biome number
local function changeSkybox(biomeNum)
	if currentBiome == biomeNum then return end
	currentBiome = biomeNum
	
	-- Find the matching skybox
	local skyboxName = tostring(biomeNum)
	local skybox = skyboxFolder:FindFirstChild(skyboxName)
	
	if not skybox then
		warn("Skybox not found for biome:", biomeNum)
		return
	end
	
	-- Clear existing skybox
	for _, obj in ipairs(Lighting:GetChildren()) do
		if obj:IsA("Sky") then
			obj:Destroy()
		end
	end
	
	-- Clone and apply new skybox
	local newSky = skybox:Clone()
	newSky.Parent = Lighting
end

-- Setup biome checker
local function setupBiomeChecker(part)
	local biomeNum = getBiomeNumber(part.Name)
	if not biomeNum then return end
	
	part.Touched:Connect(function(hit)
		local char = LocalPlayer.Character
		if char and hit:IsDescendantOf(char) then
			changeSkybox(biomeNum)
		end
	end)
end

-- Initialize all biome checkers
for _, part in ipairs(biomeFolder:GetChildren()) do
	if part:IsA("BasePart") then
		setupBiomeChecker(part)
	end
end

-- Handle new biome checkers added
biomeFolder.ChildAdded:Connect(function(child)
	if child:IsA("BasePart") then
		setupBiomeChecker(child)
	end
end)
