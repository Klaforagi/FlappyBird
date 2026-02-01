local player = game.Players.LocalPlayer

player.CharacterAdded:Connect(function(char)
	local humanoid = char:WaitForChild("Humanoid")
	local flappyMode = char:WaitForChild("FlappyMode")
	local UIS = game:GetService("UserInputService")

	-- Cooldown setup
	local lastJumpTime = 0
	local jumpCooldown = 0.05 -- seconds

	local function onTap()
		local now = tick()
		if flappyMode.Value and (now - lastJumpTime > jumpCooldown) then
			if humanoid:GetState() == Enum.HumanoidStateType.Running or humanoid:GetState() == Enum.HumanoidStateType.Freefall then
				humanoid:ChangeState(Enum.HumanoidStateType.Jumping)
				lastJumpTime = now
			end
		end
	end

	-- Tap connection management
	local tapConn
	flappyMode.Changed:Connect(function(isFlappy)
		if UIS.TouchEnabled then
			if isFlappy then
				lastJumpTime = 0 -- reset on FlappyMode start
				tapConn = UIS.TouchTap:Connect(function(touchPositions, processed)
					if not processed then
						onTap()
					end
				end)
			elseif tapConn then
				tapConn:Disconnect()
				tapConn = nil
			end
		end
	end)

	-- Handle if already in FlappyMode on spawn
	if UIS.TouchEnabled and flappyMode.Value then
		tapConn = UIS.TouchTap:Connect(function(touchPositions, processed)
			if not processed then
				onTap()
			end
		end)
	end
end)
