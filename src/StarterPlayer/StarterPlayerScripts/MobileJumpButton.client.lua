local player = game.Players.LocalPlayer
local UIS = game:GetService("UserInputService")

-- Only run on mobile
if not UIS.TouchEnabled then
	return
end

print("MobileJumpButton: Running on mobile device")


local function setupCharacter(char)
	local humanoid = char:WaitForChild("Humanoid")
	local flappyMode = char:WaitForChild("FlappyMode")

	-- Cooldown setup
	local lastJumpTime = 0
	local jumpCooldown = 0.05 -- seconds

	local function doJump()
		local now = tick()
		if now - lastJumpTime > jumpCooldown then
			if flappyMode.Value then
				humanoid:ChangeState(Enum.HumanoidStateType.Jumping)
				lastJumpTime = now
			end
		end
	end

	-- Remove tap-to-jump; only jump button triggers jump
	local tapConn = nil

	-- Create jump button GUI
	local jumpGui = Instance.new("ScreenGui")
	jumpGui.Name = "MobileJumpButtonGui"
	jumpGui.ResetOnSpawn = false
	jumpGui.IgnoreGuiInset = true
	jumpGui.Parent = player:WaitForChild("PlayerGui")

	local jumpButton = Instance.new("TextButton")
	jumpButton.Name = "JumpButton"
	jumpButton.Text = "FLAP"
	-- make the button slightly smaller for mobile
	jumpButton.Size = UDim2.new(0, 80, 0, 80)
	jumpButton.Position = UDim2.new(1, -100, 1, -120)
	jumpButton.AnchorPoint = Vector2.new(0, 0)
	jumpButton.BackgroundColor3 = Color3.fromRGB(100, 180, 255)
	jumpButton.TextColor3 = Color3.fromRGB(255, 255, 255)
	jumpButton.Font = Enum.Font.FredokaOne
	jumpButton.TextScaled = true
	jumpButton.ZIndex = 10
	jumpButton.Parent = jumpGui

	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0.5, 0)
	corner.Parent = jumpButton

	local stroke = Instance.new("UIStroke")
	-- Dark-blue border matching other UI
	stroke.Color = Color3.fromRGB(10, 60, 150)
	stroke.Thickness = 4
	stroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
	stroke.ZIndex = jumpButton.ZIndex + 1
	stroke.Parent = jumpButton

	jumpButton.MouseButton1Down:Connect(function()
		doJump()
	end)

	-- Show/hide jump button based on flappy mode
	local function updateJumpButton()
		jumpButton.Visible = flappyMode.Value
	end
	flappyMode.Changed:Connect(updateJumpButton)
	updateJumpButton()

	-- Clean up when character dies
	humanoid.Died:Connect(function()
		if tapConn then
			tapConn:Disconnect()
		end
		jumpGui:Destroy()
	end)
end

-- Handle current character if it exists
if player.Character then
	setupCharacter(player.Character)
end

-- Handle future characters
player.CharacterAdded:Connect(setupCharacter)
