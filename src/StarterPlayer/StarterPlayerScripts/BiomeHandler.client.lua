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
	{ name = "Snowland",      xMin = 4648.373,   xMax = 6309.000, id = 4 },
	{ name = "Haunted Woods", xMin = 6309.001,   xMax = 7971.000, id = 5 },
}

local currentZoneName = nil

-- Preload skybox textures so transitions are smooth
local ContentProvider = game:GetService("ContentProvider")
local function preloadSkyboxes()
	local skyboxFolder = ReplicatedStorage:FindFirstChild("Skybox")
	if not skyboxFolder then return end
	local assets = {}
	for _, sky in ipairs(skyboxFolder:GetChildren()) do
		if sky:IsA("Sky") then
			for _, prop in ipairs({"SkyboxBk","SkyboxDn","SkyboxFt","SkyboxLf","SkyboxRt","SkyboxUp"}) do
				local val = sky[prop]
				if val and type(val) == "string" and val ~= "" then
					table.insert(assets, val)
				end
			end
		end
	end
	if #assets > 0 then
		task.spawn(function()
			pcall(function()
				ContentProvider:PreloadAsync(assets)
			end)
		end)
	end
end

preloadSkyboxes()

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

-- Monitor the camera's X position for zone detection (works in main menu and in-game)
local cameraConn
local function monitorCamera()
	if cameraConn then
		cameraConn:Disconnect()
		cameraConn = nil
	end

	local tries = 0
	local cam = workspace.CurrentCamera
	while not cam and tries < 100 do
		cam = workspace.CurrentCamera
		task.wait(0.02)
		tries = tries + 1
	end
	if not cam then return end

	local lastZone = nil
	local function checkAndUpdate()
		local c = workspace.CurrentCamera
		if not c then return end
		local x = c.CFrame.Position.X
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
	end

	-- Initial update
	checkAndUpdate()

	cameraConn = RunService.RenderStepped:Connect(function()
		checkAndUpdate()
	end)
end

-- Start monitoring immediately so skybox updates on main menu camera movement
monitorCamera()

-- Also restart monitoring if camera is recreated or player respawns
workspace:GetPropertyChangedSignal("CurrentCamera"):Connect(function()
	monitorCamera()
end)

LocalPlayer.CharacterAdded:Connect(function()
	-- ensure camera monitor is active when character spawns
	monitorCamera()
end)
