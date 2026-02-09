local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Lighting = game:GetService("Lighting")
local RunService = game:GetService("RunService")

local LocalPlayer = Players.LocalPlayer

-- Zone definitions (X coordinate ranges)
local Zones = {
	{ name = "Green Meadows", xMin = nil,        xMax = 1360.450, id = 1 },
	{ name = "Sunny Beach",   xMin = 1360.451,   xMax = 2982.672, id = 2 },
	{ name = "Sakura Fields", xMin = 2982.673,   xMax = 4648.372, id = 3 },
}

local currentZoneName = nil

-- Apply skybox by zone name (expects Skybox children to be named the same as zone names)
local function changeSkyboxByName(biomeName)
	if currentZoneName == biomeName then
		return
	end

	local skyboxFolder = ReplicatedStorage:FindFirstChild("Skybox")
	if not skyboxFolder then
		warn("Skybox folder missing in ReplicatedStorage")
		return
	end

	local skyboxObj = skyboxFolder:FindFirstChild(biomeName)
	if not skyboxObj then
		warn("Skybox not found for name:", biomeName)
		return
	end

	for _, obj in ipairs(Lighting:GetChildren()) do
		if obj:IsA("Sky") then
			obj:Destroy()
		end
	end

	local newSky = skyboxObj:Clone()
	newSky.Parent = Lighting
	currentZoneName = biomeName
end

local function getZoneForX(x)
	for _, z in ipairs(Zones) do
		local minOk = (not z.xMin) or (x >= z.xMin)
		local maxOk = (not z.xMax) or (x <= z.xMax)
		if minOk and maxOk then
			return z
		end
	end
	return nil
end

-- Debug label in bottom-left
local function createZoneLabel()
	local playerGui = LocalPlayer:WaitForChild("PlayerGui")
	local existing = playerGui:FindFirstChild("ZoneDebugGui")
	if existing then
		return existing:FindFirstChild("ZoneLabel")
	end

	local screen = Instance.new("ScreenGui")
	screen.Name = "ZoneDebugGui"
	screen.ResetOnSpawn = false
	screen.Parent = playerGui

	local label = Instance.new("TextLabel")
	label.Name = "ZoneLabel"
	label.AnchorPoint = Vector2.new(0, 1)
	label.Position = UDim2.new(0.02, 0, 0.95, 0)
	label.Size = UDim2.new(0.22, 0, 0.04, 0)
	label.BackgroundTransparency = 0.45
	label.BackgroundColor3 = Color3.fromRGB(10, 10, 10)
	label.BorderSizePixel = 0
	label.TextColor3 = Color3.fromRGB(255, 255, 255)
	label.TextScaled = true
	label.Font = Enum.Font.SourceSansBold
	label.Text = "Zone: --"
	label.Parent = screen

	return label
end

local zoneLabel = createZoneLabel()

local function monitorCharacter(char)
	local hrp = char:WaitForChild("HumanoidRootPart", 5)
	if not hrp then return end

	local lastZone = nil
	lastZone = getZoneForX(hrp.Position.X)
	if lastZone then
		zoneLabel.Text = "Zone: " .. lastZone.name
		changeSkyboxByName(lastZone.name)
		currentZoneName = lastZone.name
	else
		zoneLabel.Text = "Zone: --"
	end

	local conn
	conn = RunService.RenderStepped:Connect(function()
		if not hrp.Parent then
			conn:Disconnect()
			return
		end
		local x = hrp.Position.X
		local z = getZoneForX(x)
		if z then
			if not lastZone or lastZone.name ~= z.name then
				zoneLabel.Text = "Zone: " .. z.name
				changeSkyboxByName(z.name)
				currentZoneName = z.name
				lastZone = z
			end
		else
			if lastZone ~= nil then
				zoneLabel.Text = "Zone: --"
				lastZone = nil
				currentZoneName = nil
			end
		end
	end)
end

LocalPlayer.CharacterAdded:Connect(function(char)
	monitorCharacter(char)
end)

if LocalPlayer.Character then
	monitorCharacter(LocalPlayer.Character)
end
