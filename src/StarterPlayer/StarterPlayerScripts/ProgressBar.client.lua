local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local RunService = game:GetService("RunService")

local TOTAL_STAGES = 500
local STAGES_PER_ZONE = 50
local ICON_SIZE = 32
local BAR_HEIGHT = 12
local LANE_HEIGHT = 36
local MAX_LANES = 4

-- Mode: "global" shows all 500 stages, "local" shows current zone only
local viewMode = "global"

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

-- Clickable area (generous hitbox)
local clickArea = Instance.new("TextButton")
clickArea.Name = "ClickArea"
clickArea.Size = UDim2.new(1, 0, 0, BAR_HEIGHT + 30)
clickArea.Position = UDim2.new(0, 0, 1, -BAR_HEIGHT - 15)
clickArea.BackgroundTransparency = 1
clickArea.Text = ""
clickArea.Parent = container

-- Progress bar background
local barBackground = Instance.new("Frame")
barBackground.Name = "BarBackground"
barBackground.Size = UDim2.new(1, 0, 0, BAR_HEIGHT)
barBackground.Position = UDim2.new(0, 0, 1, -BAR_HEIGHT)
barBackground.AnchorPoint = Vector2.new(0, 0)
barBackground.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
barBackground.BorderSizePixel = 0
barBackground.ClipsDescendants = true
barBackground.Parent = container

local barCorner = Instance.new("UICorner")
barCorner.CornerRadius = UDim.new(0, 6)
barCorner.Parent = barBackground

-- Colored segments (10 segments of 50 stages each)
local segmentColors = {
	Color3.fromRGB(0, 200, 100),   -- 0-50: green
	Color3.fromRGB(50, 150, 255),  -- 50-100: blue
	Color3.fromRGB(255, 100, 200), -- 100-150: pink
	Color3.fromRGB(40, 40, 40),    -- 150-200: black
	Color3.fromRGB(40, 40, 40),    -- 200-250: black
	Color3.fromRGB(40, 40, 40),    -- 250-300: black
	Color3.fromRGB(40, 40, 40),    -- 300-350: black
	Color3.fromRGB(40, 40, 40),    -- 350-400: black
	Color3.fromRGB(40, 40, 40),    -- 400-450: black
	Color3.fromRGB(40, 40, 40),    -- 450-500: black
}

-- Container for segments
local segmentsContainer = Instance.new("Frame")
segmentsContainer.Name = "SegmentsContainer"
segmentsContainer.Size = UDim2.new(1, 0, 1, 0)
segmentsContainer.BackgroundTransparency = 1
segmentsContainer.Parent = barBackground

-- Container for markers
local markersContainer = Instance.new("Frame")
markersContainer.Name = "MarkersContainer"
markersContainer.Size = UDim2.new(1, 0, 1, 0)
markersContainer.Position = UDim2.new(0, 0, 1, -BAR_HEIGHT)
markersContainer.BackgroundTransparency = 1
markersContainer.Parent = container

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

-- Get local player's current zone (0-9)
local function getLocalPlayerZone()
	local leaderstats = LocalPlayer:FindFirstChild("leaderstats")
	local stage = leaderstats and leaderstats:FindFirstChild("Stage")
	local stageValue = stage and stage.Value or 0
	return math.floor(stageValue / STAGES_PER_ZONE)
end

-- Build segments for global view
local function buildGlobalSegments()
	for _, child in ipairs(segmentsContainer:GetChildren()) do
		child:Destroy()
	end
	
	for i = 1, 10 do
		local segment = Instance.new("Frame")
		segment.Name = "Segment" .. i
		segment.Size = UDim2.new(0.1, 0, 1, 0)
		segment.Position = UDim2.new((i - 1) * 0.1, 0, 0, 0)
		segment.BackgroundColor3 = segmentColors[i]
		segment.BorderSizePixel = 0
		segment.Parent = segmentsContainer
	end
end

-- Build segments for local view (single zone color fills the bar)
local function buildLocalSegments(zoneIndex)
	for _, child in ipairs(segmentsContainer:GetChildren()) do
		child:Destroy()
	end
	
	local colorIndex = math.clamp(zoneIndex + 1, 1, 10)
	local segment = Instance.new("Frame")
	segment.Name = "LocalSegment"
	segment.Size = UDim2.new(1, 0, 1, 0)
	segment.Position = UDim2.new(0, 0, 0, 0)
	segment.BackgroundColor3 = segmentColors[colorIndex]
	segment.BorderSizePixel = 0
	segment.Parent = segmentsContainer
end

-- Build markers for global view
local function buildGlobalMarkers()
	for _, child in ipairs(markersContainer:GetChildren()) do
		child:Destroy()
	end
	
	for i = 0, 10 do
		local stageNum = i * 50
		local marker = Instance.new("Frame")
		marker.Name = "Marker" .. stageNum
		marker.Size = UDim2.new(0, 2, 0, BAR_HEIGHT + 8)
		marker.Position = UDim2.new(i / 10, -1, 0, -4)
		marker.BackgroundColor3 = Color3.fromRGB(150, 150, 150)
		marker.BorderSizePixel = 0
		marker.Parent = markersContainer
		
		local label = Instance.new("TextLabel")
		label.Size = UDim2.new(0, 40, 0, 16)
		label.Position = UDim2.new(0.5, 0, 1, 2)
		label.AnchorPoint = Vector2.new(0.5, 0)
		label.BackgroundTransparency = 1
		label.TextColor3 = Color3.fromRGB(200, 200, 200)
		label.TextSize = 10
		label.Font = Enum.Font.SourceSansBold
		label.Text = tostring(stageNum)
		label.Parent = marker
	end
end

-- Build markers for local view (no markers, just start/end labels)
local function buildLocalMarkers(zoneIndex)
	for _, child in ipairs(markersContainer:GetChildren()) do
		child:Destroy()
	end
	
	local zoneStart = zoneIndex * STAGES_PER_ZONE
	local zoneEnd = zoneStart + STAGES_PER_ZONE
	
	-- Start label
	local startLabel = Instance.new("TextLabel")
	startLabel.Name = "StartLabel"
	startLabel.Size = UDim2.new(0, 40, 0, 16)
	startLabel.Position = UDim2.new(0, 0, 1, 2)
	startLabel.AnchorPoint = Vector2.new(0, 0)
	startLabel.BackgroundTransparency = 1
	startLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
	startLabel.TextSize = 12
	startLabel.Font = Enum.Font.SourceSansBold
	startLabel.Text = tostring(zoneStart)
	startLabel.Parent = markersContainer
	
	-- End label
	local endLabel = Instance.new("TextLabel")
	endLabel.Name = "EndLabel"
	endLabel.Size = UDim2.new(0, 40, 0, 16)
	endLabel.Position = UDim2.new(1, 0, 1, 2)
	endLabel.AnchorPoint = Vector2.new(1, 0)
	endLabel.BackgroundTransparency = 1
	endLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
	endLabel.TextSize = 12
	endLabel.Font = Enum.Font.SourceSansBold
	endLabel.Text = tostring(zoneEnd)
	endLabel.Parent = markersContainer
end

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
local function calculateLanes(positions)
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
	local currentZone = getLocalPlayerZone()
	local zoneStart = currentZone * STAGES_PER_ZONE
	local zoneEnd = zoneStart + STAGES_PER_ZONE
	
	local positions = {}
	
	-- Get all player positions
	for player, icon in pairs(playerIcons) do
		local leaderstats = player:FindFirstChild("leaderstats")
		local stage = leaderstats and leaderstats:FindFirstChild("Stage")
		local stageValue = stage and stage.Value or 0
		
		local xPos
		local visible = true
		
		if viewMode == "global" then
			xPos = stageValue / TOTAL_STAGES
		else
			-- Local mode: only show players in the same zone
			if stageValue >= zoneStart and stageValue < zoneEnd then
				xPos = (stageValue - zoneStart) / STAGES_PER_ZONE
			else
				visible = false
				xPos = 0
			end
		end
		
		xPos = math.clamp(xPos, 0, 1)
		icon.Visible = visible
		
		if visible then
			table.insert(positions, {
				player = player,
				xPos = xPos,
				stageValue = stageValue
			})
		end
	end
	
	calculateLanes(positions)
	
	for player, icon in pairs(playerIcons) do
		if icon.Visible then
			local leaderstats = player:FindFirstChild("leaderstats")
			local stage = leaderstats and leaderstats:FindFirstChild("Stage")
			local stageValue = stage and stage.Value or 0
			
			local xPos
			if viewMode == "global" then
				xPos = stageValue / TOTAL_STAGES
			else
				xPos = (stageValue - zoneStart) / STAGES_PER_ZONE
			end
			xPos = math.clamp(xPos, 0, 1)
			
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
		end
	end
end

-- Rebuild UI for current mode
local function rebuildUI()
	local currentZone = getLocalPlayerZone()
	
	if viewMode == "global" then
		buildGlobalSegments()
		buildGlobalMarkers()
	else
		buildLocalSegments(currentZone)
		buildLocalMarkers(currentZone)
	end
	
	updatePositions()
end

-- Toggle between global and local mode
local function toggleMode()
	if viewMode == "global" then
		viewMode = "local"
	else
		viewMode = "global"
	end
	rebuildUI()
end

-- Click handler
clickArea.MouseButton1Click:Connect(toggleMode)

-- Track local player's zone for rebuild detection
local lastLocalZone = getLocalPlayerZone()

-- Setup stage listener for a player
local function setupStageListener(player)
	local function onLeaderstatsAdded(leaderstats)
		local stage = leaderstats:WaitForChild("Stage", 10)
		if stage then
			stage.Changed:Connect(function()
				-- If this is the local player and we're in local mode, check for zone change
				if player == LocalPlayer and viewMode == "local" then
					local newZone = getLocalPlayerZone()
					if newZone ~= lastLocalZone then
						lastLocalZone = newZone
						rebuildUI()
						return
					end
				end
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
rebuildUI()
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
