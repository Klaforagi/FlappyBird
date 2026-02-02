local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local RunService = game:GetService("RunService")

local TOTAL_STAGES = 500
local ICON_SIZE = 32
local BAR_HEIGHT = 12
local LANE_HEIGHT = 36
local MAX_LANES = 4

-- UI Setup
local playerGui = LocalPlayer:WaitForChild("PlayerGui")
local progressGui = Instance.new("ScreenGui")
progressGui.Name = "ProgressBarGui"
progressGui.ResetOnSpawn = false
progressGui.DisplayOrder = 5
progressGui.Parent = playerGui

-- Main container at bottom
local container = Instance.new("Frame")
container.Name = "ProgressContainer"
container.Size = UDim2.new(0.8, 0, 0, LANE_HEIGHT * MAX_LANES + BAR_HEIGHT + 20)
container.Position = UDim2.new(0.5, 0, 1, -10)
container.AnchorPoint = Vector2.new(0.5, 1)
container.BackgroundTransparency = 1
container.Parent = progressGui

-- Progress bar background
local barBackground = Instance.new("Frame")
barBackground.Name = "BarBackground"
barBackground.Size = UDim2.new(1, 0, 0, BAR_HEIGHT)
barBackground.Position = UDim2.new(0, 0, 1, -BAR_HEIGHT)
barBackground.AnchorPoint = Vector2.new(0, 0)
barBackground.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
barBackground.BorderSizePixel = 0
barBackground.Parent = container

local barCorner = Instance.new("UICorner")
barCorner.CornerRadius = UDim.new(0, 6)
barCorner.Parent = barBackground

-- Progress bar fill (for local player)
local barFill = Instance.new("Frame")
barFill.Name = "BarFill"
barFill.Size = UDim2.new(0, 0, 1, 0)
barFill.Position = UDim2.new(0, 0, 0, 0)
barFill.BackgroundColor3 = Color3.fromRGB(0, 200, 100)
barFill.BorderSizePixel = 0
barFill.Parent = barBackground

local fillCorner = Instance.new("UICorner")
fillCorner.CornerRadius = UDim.new(0, 6)
fillCorner.Parent = barFill

-- Stage markers (0, 100, 200, 300, 400, 500)
for i = 0, 5 do
	local marker = Instance.new("Frame")
	marker.Name = "Marker" .. (i * 100)
	marker.Size = UDim2.new(0, 2, 0, BAR_HEIGHT + 8)
	marker.Position = UDim2.new(i / 5, -1, 1, -BAR_HEIGHT - 4)
	marker.BackgroundColor3 = Color3.fromRGB(100, 100, 100)
	marker.BorderSizePixel = 0
	marker.Parent = container
	
	local label = Instance.new("TextLabel")
	label.Size = UDim2.new(0, 40, 0, 16)
	label.Position = UDim2.new(0.5, 0, 1, 2)
	label.AnchorPoint = Vector2.new(0.5, 0)
	label.BackgroundTransparency = 1
	label.TextColor3 = Color3.fromRGB(200, 200, 200)
	label.TextSize = 12
	label.Font = Enum.Font.SourceSansBold
	label.Text = tostring(i * 100)
	label.Parent = marker
end

-- Player icons container
local iconsContainer = Instance.new("Frame")
iconsContainer.Name = "IconsContainer"
iconsContainer.Size = UDim2.new(1, 0, 0, LANE_HEIGHT * MAX_LANES)
iconsContainer.Position = UDim2.new(0, 0, 1, -BAR_HEIGHT - LANE_HEIGHT * MAX_LANES - 5)
iconsContainer.BackgroundTransparency = 1
iconsContainer.Parent = container

-- Store player icons and data
local playerIcons = {}
local playerLanes = {}

-- Get player headshot
local function getHeadshot(userId, imageLabel)
	task.spawn(function()
		local success, content = pcall(function()
			local thumbType = Enum.ThumbnailType.HeadShot
			local thumbSize = Enum.ThumbnailSize.Size48x48
			return Players:GetUserThumbnailAsync(userId, thumbType, thumbSize)
		end)
		
		if success and content and imageLabel and imageLabel.Parent then
			imageLabel.Image = content
		else
			-- Retry after a delay
			task.wait(2)
			local retrySuccess, retryContent = pcall(function()
				local thumbType = Enum.ThumbnailType.HeadShot
				local thumbSize = Enum.ThumbnailSize.Size48x48
				return Players:GetUserThumbnailAsync(userId, thumbType, thumbSize)
			end)
			if retrySuccess and retryContent and imageLabel and imageLabel.Parent then
				imageLabel.Image = retryContent
			end
		end
	end)
end

-- Create icon for a player
local function createPlayerIcon(player)
	if playerIcons[player] then return end
	
	local iconFrame = Instance.new("Frame")
	iconFrame.Name = player.Name .. "_Icon"
	iconFrame.Size = UDim2.new(0, ICON_SIZE, 0, ICON_SIZE)
	iconFrame.Position = UDim2.new(0, 0, 0, 0)
	iconFrame.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
	iconFrame.BorderSizePixel = 0
	iconFrame.Parent = iconsContainer
	
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0.5, 0)
	corner.Parent = iconFrame
	
	-- Headshot image
	local headshot = Instance.new("ImageLabel")
	headshot.Name = "Headshot"
	headshot.Size = UDim2.new(1, -4, 1, -4)
	headshot.Position = UDim2.new(0.5, 0, 0.5, 0)
	headshot.AnchorPoint = Vector2.new(0.5, 0.5)
	headshot.BackgroundTransparency = 1
	headshot.Image = ""
	headshot.Parent = iconFrame
	
	-- Load headshot async
	getHeadshot(player.UserId, headshot)
	
	local headshotCorner = Instance.new("UICorner")
	headshotCorner.CornerRadius = UDim.new(0.5, 0)
	headshotCorner.Parent = headshot
	
	-- Border for local player
	if player == LocalPlayer then
		local stroke = Instance.new("UIStroke")
		stroke.Color = Color3.fromRGB(255, 215, 0)
		stroke.Thickness = 3
		stroke.Parent = iconFrame
	end
	
	-- Name label below icon
	local nameLabel = Instance.new("TextLabel")
	nameLabel.Name = "NameLabel"
	nameLabel.Size = UDim2.new(0, 60, 0, 14)
	nameLabel.Position = UDim2.new(0.5, 0, 1, 2)
	nameLabel.AnchorPoint = Vector2.new(0.5, 0)
	nameLabel.BackgroundTransparency = 1
	nameLabel.TextColor3 = player == LocalPlayer and Color3.fromRGB(255, 215, 0) or Color3.fromRGB(255, 255, 255)
	nameLabel.TextSize = 11
	nameLabel.Font = Enum.Font.SourceSansBold
	nameLabel.Text = player.DisplayName
	nameLabel.TextTruncate = Enum.TextTruncate.AtEnd
	nameLabel.Parent = iconFrame
	
	playerIcons[player] = iconFrame
	playerLanes[player] = 0
end

-- Remove icon for a player
local function removePlayerIcon(player)
	if playerIcons[player] then
		playerIcons[player]:Destroy()
		playerIcons[player] = nil
		playerLanes[player] = nil
	end
end

-- Calculate lanes to avoid overlap
local function calculateLanes()
	local positions = {}
	
	-- Get all player positions
	for player, icon in pairs(playerIcons) do
		local leaderstats = player:FindFirstChild("leaderstats")
		local stage = leaderstats and leaderstats:FindFirstChild("Stage")
		local stageValue = stage and stage.Value or 0
		local xPos = stageValue / TOTAL_STAGES
		
		table.insert(positions, {
			player = player,
			xPos = xPos,
			stageValue = stageValue
		})
	end
	
	-- Sort by position
	table.sort(positions, function(a, b) return a.xPos < b.xPos end)
	
	-- Assign lanes based on overlap
	local lanes = {}
	for i = 0, MAX_LANES - 1 do
		lanes[i] = -1 -- Last X position in this lane
	end
	
	local overlapThreshold = ICON_SIZE / (iconsContainer.AbsoluteSize.X or 800)
	
	for _, data in ipairs(positions) do
		local assignedLane = 0
		
		-- Find a lane that doesn't overlap
		for lane = 0, MAX_LANES - 1 do
			if lanes[lane] < 0 or (data.xPos - lanes[lane]) > overlapThreshold then
				assignedLane = lane
				break
			end
		end
		
		lanes[assignedLane] = data.xPos
		playerLanes[data.player] = assignedLane
	end
end

-- Update all player positions
local function updatePositions()
	calculateLanes()
	
	for player, icon in pairs(playerIcons) do
		local leaderstats = player:FindFirstChild("leaderstats")
		local stage = leaderstats and leaderstats:FindFirstChild("Stage")
		local stageValue = stage and stage.Value or 0
		
		local xPos = math.clamp(stageValue / TOTAL_STAGES, 0, 1)
		local lane = playerLanes[player] or 0
		local yPos = (MAX_LANES - 1 - lane) * LANE_HEIGHT
		
		-- Animate position
		icon:TweenPosition(
			UDim2.new(xPos, -ICON_SIZE / 2, 0, yPos),
			Enum.EasingDirection.Out,
			Enum.EasingStyle.Quad,
			0.3,
			true
		)
		
		-- Update local player's bar fill
		if player == LocalPlayer then
			barFill:TweenSize(
				UDim2.new(xPos, 0, 1, 0),
				Enum.EasingDirection.Out,
				Enum.EasingStyle.Quad,
				0.3,
				true
			)
		end
	end
end

-- Setup stage listener for a player
local function setupStageListener(player)
	local function onLeaderstatsAdded(leaderstats)
		local stage = leaderstats:WaitForChild("Stage", 10)
		if stage then
			stage.Changed:Connect(function()
				updatePositions()
			end)
			updatePositions()
		end
	end
	
	local leaderstats = player:FindFirstChild("leaderstats")
	if leaderstats then
		onLeaderstatsAdded(leaderstats)
	else
		player.ChildAdded:Connect(function(child)
			if child.Name == "leaderstats" then
				onLeaderstatsAdded(child)
			end
		end)
	end
end

-- Initialize existing players
for _, player in ipairs(Players:GetPlayers()) do
	createPlayerIcon(player)
	setupStageListener(player)
end

-- Handle new players
Players.PlayerAdded:Connect(function(player)
	-- Wait a moment for the player to fully load
	task.wait(0.5)
	createPlayerIcon(player)
	setupStageListener(player)
	task.wait(0.5)
	updatePositions()
end)

-- Handle players leaving
Players.PlayerRemoving:Connect(function(player)
	removePlayerIcon(player)
	task.wait(0.1)
	updatePositions()
end)

-- Initial update
task.delay(1, updatePositions)

-- Periodic refresh to catch any missed updates
task.spawn(function()
	while true do
		task.wait(5)
		-- Re-check for any players without icons
		for _, player in ipairs(Players:GetPlayers()) do
			if not playerIcons[player] then
				createPlayerIcon(player)
				setupStageListener(player)
			end
		end
		updatePositions()
	end
end)
