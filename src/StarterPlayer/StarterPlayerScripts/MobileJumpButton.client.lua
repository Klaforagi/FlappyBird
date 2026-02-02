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

	local function onTap()
		local now = tick()
		if now - lastJumpTime > jumpCooldown then
			-- In flappy mode, always allow jump (tap to flap)
			if flappyMode.Value then
				local state = humanoid:GetState()
				if state == Enum.HumanoidStateType.Running or state == Enum.HumanoidStateType.Freefall then
					humanoid:ChangeState(Enum.HumanoidStateType.Jumping)
					lastJumpTime = now
				end
			end
			-- In manual mode, Roblox's default jump button handles jumping
		end
	end

	-- Always listen for taps on mobile (for flappy mode jumping)
	local tapConn = UIS.TouchTap:Connect(function(touchPositions, processed)
		-- Only process if not already handled by UI
		if not processed then
			onTap()
		end
	end)
	
	-- Clean up when character dies
	humanoid.Died:Connect(function()
		if tapConn then
			tapConn:Disconnect()
		end
	end)
end

-- Handle current character if it exists
if player.Character then
	setupCharacter(player.Character)
end

-- Handle future characters
player.CharacterAdded:Connect(setupCharacter)
