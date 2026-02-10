local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local LocalPlayer = Players.LocalPlayer
local PlayerGui = LocalPlayer:WaitForChild("PlayerGui")

-- Zones (should match server)
local Zones = {
	{ name = "Green Meadows", xMin = nil,        xMax = 1360.450 },
	{ name = "Sunny Beach",   xMin = 1360.451,   xMax = 2982.672 },
	{ name = "Sakura Fields", xMin = 2982.673,   xMax = 4648.372 },
	{ name = "Snowland",      xMin = 4648.373,   xMax = 6309.000 },
	{ name = "Haunted Woods", xMin = 6309.001,   xMax = 7971.000 },
	-- Additional zones (added below Haunted Woods)
	{ name = "West Desert",   xMin = nil,        xMax = nil },
	{ name = "Wild Jungle",   xMin = nil,        xMax = nil },
	{ name = "Lavaland",      xMin = nil,        xMax = nil },
	{ name = "Cyber City",    xMin = nil,        xMax = nil },
	{ name = "Galaxy",        xMin = nil,        xMax = nil },
}

-- Ensure RemoteEvent exists (create client-side reference)
local teleportEvent = ReplicatedStorage:FindFirstChild("ZoneTeleportEvent")
if not teleportEvent then
	teleportEvent = Instance.new("RemoteEvent")
	teleportEvent.Name = "ZoneTeleportEvent"
	teleportEvent.Parent = ReplicatedStorage
end

-- Checkpoint purchase events
local RequestCheckpoints = ReplicatedStorage:WaitForChild("RequestCheckpoints")
local CheckpointData = ReplicatedStorage:WaitForChild("CheckpointData")
local PurchaseCheckpoint = ReplicatedStorage:WaitForChild("PurchaseCheckpoint")
local PurchaseResponse = ReplicatedStorage:WaitForChild("PurchaseResponse")
local ResetCheckpoints = ReplicatedStorage:WaitForChild("ResetCheckpoints")

local purchases = {}
local CHECKPOINT_COST = 10

-- Build left menu button
local function createMenuButton()
	local screen = PlayerGui:FindFirstChild("ZoneMenuGui")
	if screen then return screen end
	local screenGui = Instance.new("ScreenGui")
	screenGui.Name = "ZoneMenuGui"
	screenGui.ResetOnSpawn = false
	-- ensure this UI appears above others
	screenGui.DisplayOrder = 1000
	screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
	screenGui.Parent = PlayerGui

	local button = Instance.new("TextButton")
	button.Name = "OpenZoneMenu"
	button.Size = UDim2.new(0, 48, 0, 48)
	button.Position = UDim2.new(0, 12, 0.5, -24)
	button.AnchorPoint = Vector2.new(0, 0.5)
	button.BackgroundColor3 = Color3.fromRGB(30,30,30)
	button.TextColor3 = Color3.fromRGB(255,255,255)
	button.Text = "Menu"
	button.Font = Enum.Font.SourceSansBold
	button.TextScaled = true
	button.Parent = screenGui

	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0,8)
	corner.Parent = button

	-- State label above the button (scale-based)
	local stateLabel = Instance.new("TextLabel")
	stateLabel.Name = "StateLabel"
	stateLabel.Size = UDim2.new(0.12, 0, 0.03, 0)
	stateLabel.Position = UDim2.new(0.01, 0, 0.44, 0)
	stateLabel.AnchorPoint = Vector2.new(0, 0.5)
	stateLabel.BackgroundTransparency = 0.5
	stateLabel.BackgroundColor3 = Color3.fromRGB(0,0,0)
	stateLabel.TextColor3 = Color3.fromRGB(255,255,255)
	stateLabel.Font = Enum.Font.SourceSansBold
	stateLabel.TextScaled = true
	stateLabel.Text = "Normal"
	stateLabel.Parent = screenGui

	-- Popup frame (hidden by default)
	local popup = Instance.new("Frame")
	popup.Name = "ZonePopup"
	popup.Size = UDim2.new(0.6, 0, 0.7, 0)
	-- render above other GUI elements in the same ScreenGui
	popup.ZIndex = 100
	popup.Position = UDim2.new(0.5, 0, 0.5, 0)
	popup.AnchorPoint = Vector2.new(0.5, 0.5)
	popup.BackgroundColor3 = Color3.fromRGB(20,20,30)
	popup.BorderSizePixel = 0
	popup.Visible = false
	popup.Parent = screenGui

	local popupCorner = Instance.new("UICorner")
	popupCorner.CornerRadius = UDim.new(0,10)
	popupCorner.Parent = popup

	-- Top tabs bar (positioned above popup)
	local topTabs = Instance.new("Frame")
	topTabs.Name = "TopTabs"
	-- match popup width and place above it
	topTabs.Size = UDim2.new(0.6, 0, 0.06, 0)
	topTabs.Position = UDim2.new(0.5, 0, 0.09, 0)
	topTabs.AnchorPoint = Vector2.new(0.5, 0)
	topTabs.BackgroundTransparency = 1
	topTabs.Parent = screenGui
	-- hide tabs until the popup is opened
	topTabs.Visible = false

	local tabsLayout = Instance.new("UIListLayout")
	tabsLayout.FillDirection = Enum.FillDirection.Horizontal
	tabsLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
	tabsLayout.SortOrder = Enum.SortOrder.LayoutOrder
	tabsLayout.Padding = UDim.new(0, 12)
	tabsLayout.Parent = topTabs

	local function makeTabButton(text, order)
		local t = Instance.new("TextButton")
		t.Name = text .. "Tab"
		t.Size = UDim2.new(0.28, 0, 1, 0)
		t.LayoutOrder = order
		t.BackgroundColor3 = Color3.fromRGB(100,180,255)
		t.Text = text
		t.TextColor3 = Color3.fromRGB(255,255,255)
		t.Font = Enum.Font.FredokaOne
		t.TextScaled = true
		t.Parent = topTabs
		local c = Instance.new("UICorner") c.CornerRadius = UDim.new(0,8) c.Parent = t
		local s = Instance.new("UIStroke") s.Color = Color3.fromRGB(50,100,150) s.Thickness = 2 s.Parent = t
		local g = Instance.new("UIGradient") g.Color = ColorSequence.new(Color3.fromRGB(255,255,255), Color3.fromRGB(200,200,200)) g.Rotation = 90 g.Parent = t
		return t
	end

	local zonesTab = makeTabButton("Zones", 1)
	local trailsTab = makeTabButton("Trails", 2)
	local skinsTab = makeTabButton("Skins", 3)

	-- Placeholder frames for tabs
	local trailsFrame = Instance.new("Frame")
	trailsFrame.Size = UDim2.new(0.94, 0, 0.82, 0)
	trailsFrame.Position = UDim2.new(0, 0, 0.12, 0)
	trailsFrame.BackgroundTransparency = 1
	trailsFrame.Visible = false
	trailsFrame.Parent = nil -- will parent to contentFrame after it's created

	local trailsSoon = Instance.new("TextLabel")
	trailsSoon.Size = UDim2.new(1, 0, 0.2, 0)
	trailsSoon.Position = UDim2.new(0, 0, 0.35, 0)
	trailsSoon.BackgroundTransparency = 1
	trailsSoon.Text = "Coming Soon"
	trailsSoon.TextColor3 = Color3.fromRGB(180, 180, 180)
	trailsSoon.Font = Enum.Font.FredokaOne
	trailsSoon.TextScaled = true
	trailsSoon.Parent = trailsFrame

	local skinsFrame = Instance.new("Frame")
	skinsFrame.Size = UDim2.new(0.94, 0, 0.82, 0)
	skinsFrame.Position = UDim2.new(0, 0, 0.12, 0)
	skinsFrame.BackgroundTransparency = 1
	skinsFrame.Visible = false
	skinsFrame.Parent = nil -- will parent to contentFrame after it's created

	local skinsSoon = Instance.new("TextLabel")
	skinsSoon.Size = UDim2.new(1, 0, 0.2, 0)
	skinsSoon.Position = UDim2.new(0, 0, 0.35, 0)
	skinsSoon.BackgroundTransparency = 1
	skinsSoon.Text = "Coming Soon"
	skinsSoon.TextColor3 = Color3.fromRGB(180, 180, 180)
	skinsSoon.Font = Enum.Font.FredokaOne
	skinsSoon.TextScaled = true
	skinsSoon.Parent = skinsFrame

	-- Forward-declare UI elements so updateTabVisuals closure can reference them
	local contentTitle
	local buttonsContainer
	local checkpointHeader
	local resetBtn

	local activeTab = "Zones"
	local function updateTabVisuals()
		zonesTab.BackgroundColor3 = (activeTab == "Zones") and Color3.fromRGB(100,180,255) or Color3.fromRGB(60,60,70)
		trailsTab.BackgroundColor3 = (activeTab == "Trails") and Color3.fromRGB(100,180,255) or Color3.fromRGB(60,60,70)
		skinsTab.BackgroundColor3 = (activeTab == "Skins") and Color3.fromRGB(100,180,255) or Color3.fromRGB(60,60,70)
		if contentTitle then
			contentTitle.Text = activeTab
		end
		if buttonsContainer then
			buttonsContainer.Visible = (activeTab == "Zones")
		end
		if trailsFrame then
			trailsFrame.Visible = (activeTab == "Trails")
		end
		if skinsFrame then
			skinsFrame.Visible = (activeTab == "Skins")
		end
		if checkpointHeader then
			checkpointHeader.Visible = (activeTab == "Zones")
		end
		if resetBtn then
			resetBtn.Visible = (activeTab == "Zones")
		end
	end

	zonesTab.MouseButton1Click:Connect(function() activeTab = "Zones"; updateTabVisuals() end)
	trailsTab.MouseButton1Click:Connect(function() activeTab = "Trails"; updateTabVisuals() end)
	skinsTab.MouseButton1Click:Connect(function() activeTab = "Skins"; updateTabVisuals() end)

	-- initial visuals will run after content area is built

	-- Content area (uses more left space now)
	local contentFrame = Instance.new("Frame")
	contentFrame.Name = "ContentFrame"
	contentFrame.Size = UDim2.new(0.90, 0, 1, 0)
	contentFrame.Position = UDim2.new(0.05, 0, 0.03, 0)
	contentFrame.BackgroundTransparency = 1
	contentFrame.Parent = popup

	-- (Zones title removed per request)

	-- Header for checkpoints column (over checkmarks/buy column)
	checkpointHeader = Instance.new("TextLabel")
	checkpointHeader.Size = UDim2.new(0.14, 0, 0.06, 0)
	checkpointHeader.Position = UDim2.new(0.80, 0, 0.045, 0)
	checkpointHeader.AnchorPoint = Vector2.new(0, 0)
	checkpointHeader.BackgroundTransparency = 1
	checkpointHeader.Text = "Checkpoints"
	checkpointHeader.TextColor3 = Color3.fromRGB(255,255,255)
	checkpointHeader.Font = Enum.Font.FredokaOne
	checkpointHeader.TextScaled = true
	checkpointHeader.Parent = contentFrame
	local chkStroke = Instance.new("UIStroke")
	chkStroke.Color = Color3.fromRGB(50,100,150)
	chkStroke.Thickness = 2
	chkStroke.Parent = checkpointHeader

	-- Use a ScrollingFrame so many zones fit inside the popup
	buttonsContainer = Instance.new("ScrollingFrame")
	buttonsContainer.Name = "ButtonsContainer"
	buttonsContainer.Size = UDim2.new(1, 0, 0.82, 0)
	buttonsContainer.Position = UDim2.new(0, 0, 0.12, 0)
	buttonsContainer.BackgroundTransparency = 1
	buttonsContainer.AutomaticCanvasSize = Enum.AutomaticSize.Y
	buttonsContainer.ScrollBarThickness = 8
	buttonsContainer.ScrollBarImageColor3 = Color3.fromRGB(50,50,60)
	buttonsContainer.CanvasSize = UDim2.new(0, 0, 0, 0)
	buttonsContainer.Parent = contentFrame

	local uiList = Instance.new("UIListLayout")
	uiList.Padding = UDim.new(0.02, 0)
	uiList.FillDirection = Enum.FillDirection.Vertical
	uiList.HorizontalAlignment = Enum.HorizontalAlignment.Left
	uiList.VerticalAlignment = Enum.VerticalAlignment.Top
	uiList.Parent = buttonsContainer

	-- Keep canvas size updated based on list content
	local function updateCanvas()
		local h = uiList.AbsoluteContentSize.Y
		buttonsContainer.CanvasSize = UDim2.new(0, 0, 0, h + 0)
	end
	uiList:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(updateCanvas)
	updateCanvas()

	-- now that content controls exist, initialize tab visuals
	updateTabVisuals()

	-- keep the tabs visible only while the popup is visible
	popup:GetPropertyChangedSignal("Visible"):Connect(function()
		topTabs.Visible = popup.Visible
	end)

	-- reparent placeholder tab frames into contentFrame if needed
	if trailsFrame and not trailsFrame.Parent then
		trailsFrame.Parent = contentFrame
	end
	if skinsFrame and not skinsFrame.Parent then
		skinsFrame.Parent = contentFrame
	end

	-- Theme colors for zones (matches progress bar order)
	local zoneColors = {
		Color3.fromRGB(100,200,100), -- green
		Color3.fromRGB(100,180,255), -- blue
		Color3.fromRGB(255,120,180), -- pink
		Color3.fromRGB(245,245,250), -- white/light
		Color3.fromRGB(150,100,255), -- purple
		Color3.fromRGB(255,175, 60), -- West Desert (yellow-orange)
		Color3.fromRGB(20,130,20),   -- Wild Jungle (dark green)
		Color3.fromRGB(220,50,50),   -- Lavaland (red)
		Color3.fromRGB(70,240,240),  -- Cyber City (cyan)
		Color3.fromRGB(30,60,200),   -- Galaxy (deep blue)
	}

	-- Create a row per zone with separate buy button and status
	for i, z in ipairs(Zones) do
		local row = Instance.new("Frame")
		row.Size = UDim2.new(1, 0, 0.16, 0)
		row.BackgroundTransparency = 1
		row.Parent = buttonsContainer

		local zoneBtn = Instance.new("TextButton")
		zoneBtn.Name = "ZoneButton"
		zoneBtn.Size = UDim2.new(0.72, 0, 1, 0)
		zoneBtn.Position = UDim2.new(0, 0, 0, 0)
		-- apply theme color per-zone (fall back to default)
		zoneBtn.BackgroundColor3 = zoneColors[i] or Color3.fromRGB(60,60,70)
		zoneBtn.TextColor3 = Color3.fromRGB(255,255,255)
		zoneBtn.Text = z.name
		zoneBtn.Font = Enum.Font.SourceSansSemibold
		zoneBtn.TextScaled = true
		zoneBtn.Parent = row

		local zoneCorner = Instance.new("UICorner")
		zoneCorner.CornerRadius = UDim.new(0,8)
		zoneCorner.Parent = zoneBtn
		zoneBtn.Font = Enum.Font.FredokaOne
		zoneBtn.TextColor3 = Color3.fromRGB(255,255,255)
		zoneBtn.ZIndex = 101

		local zoneStroke = Instance.new("UIStroke")
		zoneStroke.Color = Color3.fromRGB(50,100,150)
		zoneStroke.Thickness = 2
		zoneStroke.Parent = zoneBtn

		local zoneTextStroke = Instance.new("UIStroke")
		zoneTextStroke.Color = Color3.fromRGB(50,100,150)
		zoneTextStroke.Thickness = 1
		zoneTextStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Contextual
		zoneTextStroke.Parent = zoneBtn

		local zoneGrad = Instance.new("UIGradient")
		zoneGrad.Color = ColorSequence.new(Color3.fromRGB(255,255,255), Color3.fromRGB(220,220,220))
		zoneGrad.Rotation = 90
		zoneGrad.Parent = zoneBtn

		local costLabel = Instance.new("TextLabel")
		costLabel.Name = "CostLabel"
		costLabel.Size = UDim2.new(0.12, 0, 1, 0)
		costLabel.Position = UDim2.new(0.74, 0, 0, 0)
		costLabel.BackgroundTransparency = 1
		costLabel.Text = tostring(CHECKPOINT_COST) .. "c"
		costLabel.TextColor3 = Color3.fromRGB(255, 223, 0)
		costLabel.Font = Enum.Font.SourceSansSemibold
		costLabel.TextScaled = true
		costLabel.Parent = row

		local buyBtn = Instance.new("TextButton")
		buyBtn.Name = "BuyButton"
		buyBtn.Size = UDim2.new(0.12, 0, 1, 0)
		buyBtn.Position = UDim2.new(0.86, 0, 0, 0)
		buyBtn.BackgroundColor3 = Color3.fromRGB(100,180,255)
		buyBtn.Text = "Buy"
		buyBtn.Font = Enum.Font.SourceSansSemibold
		buyBtn.TextScaled = true
		buyBtn.Parent = row

		local buyCorner = Instance.new("UICorner")
		buyCorner.CornerRadius = UDim.new(0,8)
		buyCorner.Parent = buyBtn
		buyBtn.Font = Enum.Font.FredokaOne
		buyBtn.TextColor3 = Color3.fromRGB(255,255,255)
		buyBtn.ZIndex = 101

		local buyStroke = Instance.new("UIStroke")
		buyStroke.Color = Color3.fromRGB(50,100,150)
		buyStroke.Thickness = 2
		buyStroke.Parent = buyBtn

		local buyTextStroke = Instance.new("UIStroke")
		buyTextStroke.Color = Color3.fromRGB(50,100,150)
		buyTextStroke.Thickness = 1
		buyTextStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Contextual
		buyTextStroke.Parent = buyBtn

		local buyGrad = Instance.new("UIGradient")
		buyGrad.Color = ColorSequence.new(Color3.fromRGB(255,255,255), Color3.fromRGB(200,200,200))
		buyGrad.Rotation = 90
		buyGrad.Parent = buyBtn

		-- checkmark hidden (we no longer show the green tick)
		local check = Instance.new("TextLabel")
		check.Name = "CheckLabel"
		check.Size = UDim2.new(0.08, 0, 1, 0)
		check.Position = UDim2.new(0.96, 0, 0, 0)
		check.BackgroundTransparency = 1
		check.Text = ""
		check.Visible = false
		check.Parent = row
		check.ZIndex = 102

		zoneBtn.MouseButton1Click:Connect(function()
			if purchases[z.name] then
				teleportEvent:FireServer(z.name)
				popup.Visible = false
			else
				-- prompt to buy (quick notice)
				local notice = Instance.new("TextLabel")
				notice.Size = UDim2.new(0.6,0,0.08,0)
				notice.Position = UDim2.new(0.5,0,0.5,0)
				notice.AnchorPoint = Vector2.new(0.5,0.5)
				notice.BackgroundTransparency = 0.4
				notice.BackgroundColor3 = Color3.fromRGB(0,0,0)
				notice.TextColor3 = Color3.fromRGB(255,255,255)
				notice.Font = Enum.Font.FredokaOne
				notice.TextScaled = true
				notice.Text = "Buy checkpoint to teleport"
				notice.Parent = PlayerGui
				task.delay(2, function() if notice then notice:Destroy() end end)
			end
		end)

		buyBtn.MouseButton1Click:Connect(function()
			if not buyBtn.Active then return end
			if purchases[z.name] then return end
			buyBtn.Active = false
			buyBtn.AutoButtonColor = false
			PurchaseCheckpoint:FireServer(z.name)
		end)
	end

	-- Helper: refresh buy button states so only the first unowned zone is buyable
	local function refreshBuyStates()
		local firstUnownedFound = false
		for _, z in ipairs(Zones) do
			for _, row in ipairs(buttonsContainer:GetChildren()) do
				if row:IsA("Frame") then
					local zoneBtn = row:FindFirstChild("ZoneButton")
					local buyBtn = row:FindFirstChild("BuyButton")
					local check = row:FindFirstChild("CheckLabel")
					local cost = row:FindFirstChild("CostLabel")
					if zoneBtn and zoneBtn.Text == z.name then
						if purchases[z.name] then
							if check then check.Text = "✓" end
							if cost then cost.Visible = false end
							if buyBtn then buyBtn.Text = "Owned"; buyBtn.BackgroundColor3 = Color3.fromRGB(120,120,120); buyBtn.Active = false end
						else
							if check then check.Text = "" end
							if not firstUnownedFound then
								if cost then cost.Visible = true end
								if buyBtn then buyBtn.Text = "Buy"; buyBtn.BackgroundColor3 = Color3.fromRGB(100,180,255); buyBtn.Active = true end
								firstUnownedFound = true
							else
								if cost then cost.Visible = false end
								if buyBtn then buyBtn.Text = "Buy"; buyBtn.BackgroundColor3 = Color3.fromRGB(120,120,120); buyBtn.Active = false end
							end
						end
						break
					end
				end
			end
		end
	end

	-- Reset Owned button for testing (client-side only)
	resetBtn = Instance.new("TextButton")
	resetBtn.Name = "ResetOwned"
	resetBtn.Size = UDim2.new(0.12, 0, 0.04, 0)
	resetBtn.AnchorPoint = Vector2.new(1, 0)
	resetBtn.Position = UDim2.new(1, -12, 0.01, 0)
	resetBtn.BackgroundColor3 = Color3.fromRGB(180,80,80)
	resetBtn.Text = "Reset Owned"
	resetBtn.Font = Enum.Font.SourceSansSemibold
	resetBtn.TextScaled = true
	resetBtn.Parent = popup

	local resetCorner = Instance.new("UICorner")
	resetCorner.CornerRadius = UDim.new(0,8)
	resetCorner.Parent = resetBtn
	resetBtn.Font = Enum.Font.FredokaOne
	resetBtn.TextColor3 = Color3.fromRGB(255,255,255)
	resetBtn.ZIndex = 101

	local resetStroke = Instance.new("UIStroke")
	resetStroke.Color = Color3.fromRGB(50,100,150)
	resetStroke.Thickness = 2
	resetStroke.Parent = resetBtn

	local resetGrad = Instance.new("UIGradient")
	resetGrad.Color = ColorSequence.new(Color3.fromRGB(255,255,255), Color3.fromRGB(200,200,200))
	resetGrad.Rotation = 90
	resetGrad.Parent = resetBtn

	resetBtn.MouseButton1Click:Connect(function()
		resetBtn.Active = false
		resetBtn.AutoButtonColor = false
		-- request server to clear saved checkpoints
		ResetCheckpoints:FireServer()
		local notice = Instance.new("TextLabel")
		notice.Size = UDim2.new(0.4,0,0.06,0)
		notice.Position = UDim2.new(0.5,0,0.9,0)
		notice.AnchorPoint = Vector2.new(0.5,0.5)
		notice.BackgroundTransparency = 0.4
		notice.BackgroundColor3 = Color3.fromRGB(0,0,0)
		notice.TextColor3 = Color3.fromRGB(255,255,255)
		notice.Font = Enum.Font.FredokaOne
		notice.TextScaled = true
		notice.Text = "Resetting purchases..."
		notice.Parent = PlayerGui
		task.delay(2, function() if notice then notice:Destroy() end end)
	end)

	-- Close button (scaled and top-right inside popup)
	local closeBtn = Instance.new("TextButton")
	closeBtn.Size = UDim2.new(0.06, 0, 0.06, 0)
	closeBtn.AnchorPoint = Vector2.new(1, 0)
	closeBtn.Position = UDim2.new(1, -12, 0.02, 0)
	closeBtn.BackgroundColor3 = Color3.fromRGB(100,180,255)
	closeBtn.Text = "X"
	closeBtn.TextColor3 = Color3.fromRGB(255,255,255)
	closeBtn.Font = Enum.Font.FredokaOne
	closeBtn.TextScaled = true
	closeBtn.ZIndex = 101
	closeBtn.Parent = popup

	local closeCorner = Instance.new("UICorner")
	closeCorner.CornerRadius = UDim.new(0,8)
	closeCorner.Parent = closeBtn

	local closeStroke = Instance.new("UIStroke")
	closeStroke.Color = Color3.fromRGB(50,100,150)
	closeStroke.Thickness = 2
	closeStroke.Parent = closeBtn

	local closeGrad = Instance.new("UIGradient")
	closeGrad.Color = ColorSequence.new(Color3.fromRGB(255,255,255), Color3.fromRGB(200,200,200))
	closeGrad.Rotation = 90
	closeGrad.Parent = closeBtn

	closeBtn.MouseButton1Click:Connect(function()
		popup.Visible = false
	end)

	-- Ensure attribute exists (default enabled)
	if button:GetAttribute("Enabled") == nil then
		button:SetAttribute("Enabled", true)
	end

	button.MouseButton1Click:Connect(function()
		local enabled = button:GetAttribute("Enabled")
		if enabled == false then
			return
		end
		popup.Visible = not popup.Visible
		print("Menu button clicked - popup visible:", popup.Visible)
		if popup.Visible then
			updateTabVisuals()
		end
	end)

	-- State watchers: InMainMenu, FlappyMode, DeathMenu
	local inMainMenu = LocalPlayer:FindFirstChild("InMainMenu")
	local flappyVal = nil
	local humanoid = nil
	local flappyContinueVal = nil

	local function updateButtonState()
		local inMenu = inMainMenu and inMainMenu.Value
		local flappy = flappyVal and flappyVal.Value
		local alive = humanoid and humanoid.Health > 0
		local flappyContinue = flappyContinueVal and flappyContinueVal.Value

		-- Update state label
		local stateText = "Normal"
		if inMenu then
			stateText = "Main Menu"
		elseif not alive then
			stateText = "Dead"
		elseif flappyContinue then
			stateText = "Continue"
		elseif flappy then
			stateText = "FlappyMode"
		end
		stateLabel.Text = stateText

		if inMenu or flappy or not alive or flappyContinue then
			button.Visible = false
			button:SetAttribute("Enabled", false)
			popup.Visible = false
			return
		end
		button.Visible = true
		button:SetAttribute("Enabled", true)
		popup.Visible = false
	end

	-- Monitor InMainMenu
	if inMainMenu then
		inMainMenu.Changed:Connect(updateButtonState)
	end

	-- Monitor FlappyMode on character
	local function bindFlappyForCharacter(char)
		flappyVal = char:FindFirstChild("FlappyMode")
		if flappyVal and flappyVal:IsA("BoolValue") then
			flappyVal.Changed:Connect(updateButtonState)
		end
		char.ChildAdded:Connect(function(child)
			if child.Name == "FlappyMode" and child:IsA("BoolValue") then
				flappyVal = child
				flappyVal.Changed:Connect(updateButtonState)
				updateButtonState()
			end
		end)
		humanoid = char:WaitForChild("Humanoid")
		humanoid.HealthChanged:Connect(updateButtonState)
		flappyContinueVal = char:FindFirstChild("FlappyModeContinue")
		if flappyContinueVal and flappyContinueVal:IsA("BoolValue") then
			flappyContinueVal.Changed:Connect(updateButtonState)
		end
		char.ChildAdded:Connect(function(child)
			if child.Name == "FlappyModeContinue" and child:IsA("BoolValue") then
				flappyContinueVal = child
				flappyContinueVal.Changed:Connect(updateButtonState)
				updateButtonState()
			end
		end)		updateButtonState()
	end

	if LocalPlayer.Character then
		bindFlappyForCharacter(LocalPlayer.Character)
	end
	LocalPlayer.CharacterAdded:Connect(bindFlappyForCharacter)

	-- initial check
	updateButtonState()

	-- initial buy-state refresh (allow top zone to be buyable client-side)
	refreshBuyStates()

	-- Request current purchases
	RequestCheckpoints:FireServer()

	CheckpointData.OnClientEvent:Connect(function(data)
		if type(data) == "table" then
			purchases = data
			refreshBuyStates()
			-- re-enable reset button after server response
			local rb = popup:FindFirstChild("ResetOwned")
			if rb then rb.Active = true; rb.AutoButtonColor = true end
		end
	end)

	PurchaseResponse.OnClientEvent:Connect(function(success, zoneName, reason)
		-- find the row for this zone
		for _, row in ipairs(buttonsContainer:GetChildren()) do
			if row:IsA("Frame") then
				local zoneBtn = row:FindFirstChild("ZoneButton")
				if zoneBtn and zoneBtn.Text == zoneName then
					local check = row:FindFirstChild("CheckLabel")
					local cost = row:FindFirstChild("CostLabel")
					local buyBtn = row:FindFirstChild("BuyButton")
					if success then
						purchases[zoneName] = true
						if check then check.Text = "✓" end
						if cost then cost.Visible = false end
						if buyBtn then buyBtn.Text = "Owned"; buyBtn.BackgroundColor3 = Color3.fromRGB(120,120,120); buyBtn.Active = false end
						-- play buy sound (client-side)
						local soundsFolder = ReplicatedStorage:FindFirstChild("Sounds")
						if soundsFolder then
							local buySound = soundsFolder:FindFirstChild("Buy")
							if buySound and buySound:IsA("Sound") then
								local s = buySound:Clone()
								s.Parent = workspace
								s:Play()
								game:GetService("Debris"):AddItem(s, 3)
							end
						end
					else
						local notice = Instance.new("TextLabel")
						notice.Size = UDim2.new(0.6,0,0.08,0)
						notice.Position = UDim2.new(0.5,0,0.5,0)
						notice.AnchorPoint = Vector2.new(0.5,0.5)
						notice.BackgroundTransparency = 0.4
						notice.BackgroundColor3 = Color3.fromRGB(0,0,0)
						notice.TextColor3 = Color3.fromRGB(255,0,0)
						notice.Font = Enum.Font.FredokaOne
						notice.TextScaled = true
						notice.Text = reason or "Purchase failed"
						notice.Parent = PlayerGui
						task.delay(2, function() if notice then notice:Destroy() end end)
					end
					break
				end
			end
		end
		-- after handling response, refresh available buy states
		refreshBuyStates()
	end)

	return screenGui
end

createMenuButton()
