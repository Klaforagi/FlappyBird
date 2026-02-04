local FORWARD_SPEED = 18
local MOVE_SPEED = 18
local LOCKED_Z = -153.2
local char = script.Parent
local hrp = char:WaitForChild("HumanoidRootPart")
local humanoid = char:WaitForChild("Humanoid")
local flappyMode = char:WaitForChild("FlappyMode")
local RunService = game:GetService("RunService")
local UIS = game:GetService("UserInputService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

-- Mobile = has touch, PC = no touch (simpler detection)
local isMobile = UIS.TouchEnabled

print("PlayerMovement loaded. TouchEnabled:", UIS.TouchEnabled, "KeyboardEnabled:", UIS.KeyboardEnabled, "isMobile:", isMobile)

local bv
local orientConn
local moveConn

-- ==================== PC CONTROLS ====================
local function enableFlappyMove_PC()
	print("PC: Enabling Auto-Forward Movement!")
	
	-- Disable manual movement
	if moveConn then
		moveConn:Disconnect()
		moveConn = nil
	end
	
	-- Enable auto-forward movement
	if not bv then
		bv = Instance.new("BodyVelocity")
		bv.Velocity = Vector3.new(FORWARD_SPEED, 0, 0)
		bv.MaxForce = Vector3.new(1e5, 0, 0)
		bv.P = 1000
		bv.Parent = hrp
	end

	-- Lock orientation to face right
	if not orientConn then
		orientConn = RunService.RenderStepped:Connect(function()
			hrp.CFrame = CFrame.new(hrp.Position, hrp.Position + Vector3.new(1, 0, 0))
		end)
	end
end

local function enableManualMove_PC()
	print("PC: Enabling Manual Left/Right Movement!")
	
	-- Disable auto-forward movement
	if bv then
		bv:Destroy()
		bv = nil
	end
	
	-- Remove flappy orientation lock
	if orientConn then
		orientConn:Disconnect()
		orientConn = nil
	end
	
	-- Manual A/D movement with jumping (PC only)
	if not moveConn then
		moveConn = RunService.Heartbeat:Connect(function()
			local moveX = 0
			
			if UIS:IsKeyDown(Enum.KeyCode.A) or UIS:IsKeyDown(Enum.KeyCode.Left) then
				moveX = -1
			end
			if UIS:IsKeyDown(Enum.KeyCode.D) or UIS:IsKeyDown(Enum.KeyCode.Right) then
				moveX = moveX + 1
			end
			
			-- Move character along X-axis only
			humanoid:Move(Vector3.new(moveX, 0, 0))
			
			-- Get facing direction
			local faceDir = 1 -- Default face right
			if moveX < 0 then
				faceDir = -1 -- Face left
			elseif moveX > 0 then
				faceDir = 1 -- Face right
			else
				-- Keep current facing direction when not moving
				faceDir = hrp.CFrame.LookVector.X >= 0 and 1 or -1
			end
			
			-- Lock Z position and facing direction (same as mobile)
			hrp.CFrame = CFrame.new(hrp.Position.X, hrp.Position.Y, LOCKED_Z) * CFrame.Angles(0, faceDir > 0 and -math.pi/2 or math.pi/2, 0)
			
			-- Jump with spacebar
			if UIS:IsKeyDown(Enum.KeyCode.Space) then
				if humanoid.FloorMaterial ~= Enum.Material.Air then
					humanoid:ChangeState(Enum.HumanoidStateType.Jumping)
				end
			end
		end)
	end
end

-- ==================== MOBILE CONTROLS ====================
local function enableFlappyMove_Mobile()
	print("Mobile: Enabling Auto-Forward Movement!")
	
	-- Disable manual movement
	if moveConn then
		moveConn:Disconnect()
		moveConn = nil
	end
	
	-- Enable auto-forward movement
	if not bv then
		bv = Instance.new("BodyVelocity")
		bv.Velocity = Vector3.new(FORWARD_SPEED, 0, 0)
		bv.MaxForce = Vector3.new(1e5, 0, 0)
		bv.P = 1000
		bv.Parent = hrp
	end

	-- Lock orientation to face right
	if not orientConn then
		orientConn = RunService.RenderStepped:Connect(function()
			hrp.CFrame = CFrame.new(hrp.Position, hrp.Position + Vector3.new(1, 0, 0))
		end)
	end
end

local function enableManualMove_Mobile()
	print("Mobile: Enabling Manual Left/Right Movement!")
	
	-- Disable auto-forward movement
	if bv then
		bv:Destroy()
		bv = nil
	end
	
	-- Remove flappy orientation lock
	if orientConn then
		orientConn:Disconnect()
		orientConn = nil
	end
	
	-- Lock Z position and facing direction
	if not moveConn then
		moveConn = RunService.Heartbeat:Connect(function()
			-- Keep player locked to Z axis
			local needsZFix = math.abs(hrp.Position.Z - LOCKED_Z) > 0.1
			
			-- Get current facing direction and snap to left or right
			local moveDir = humanoid.MoveDirection
			local faceDir = 1 -- Default face right
			if moveDir.X < -0.1 then
				faceDir = -1 -- Face left
			elseif moveDir.X > 0.1 then
				faceDir = 1 -- Face right
			else
				-- Keep current facing direction when not moving
				faceDir = hrp.CFrame.LookVector.X >= 0 and 1 or -1
			end
			
			-- Apply locked Z and facing direction (face along X-axis: right = +X, left = -X)
			hrp.CFrame = CFrame.new(hrp.Position.X, hrp.Position.Y, LOCKED_Z) * CFrame.Angles(0, faceDir > 0 and -math.pi/2 or math.pi/2, 0)
		end)
	end
end

-- ==================== MODE SWITCHING ====================
local function enableFlappyMove()
	if isMobile then
		enableFlappyMove_Mobile()
	else
		enableFlappyMove_PC()
	end
end

local function enableManualMove()
	if isMobile then
		enableManualMove_Mobile()
	else
		enableManualMove_PC()
	end
end

flappyMode.Changed:Connect(function(isFlappy)
	print("PlayerMovement: FlappyMode changed to:", isFlappy, "(Mobile:", isMobile, ")")
	if isFlappy then
		enableFlappyMove()
	else
		enableManualMove()
	end
end)

-- Start with appropriate movement mode
if flappyMode.Value then
	enableFlappyMove()
else
	enableManualMove()
end

-- Play custom jump sound and mute default character jump sounds
local player = Players:GetPlayerFromCharacter(char)

local function playCustomJump()
	if not player then
		player = Players:GetPlayerFromCharacter(char)
		if not player then return end
	end
	local soundsFolder = ReplicatedStorage:FindFirstChild("Sounds")
	if not soundsFolder then return end
	local template = soundsFolder:FindFirstChild("Jump")
	if not template then return end
	local playerGui = player:FindFirstChild("PlayerGui") or player:WaitForChild("PlayerGui", 5)
	if not playerGui then return end
	local s = template:Clone()
	s.Parent = playerGui
	if s:IsA("Sound") then
		pcall(function() s:Play() end)
		local con
		con = s.Ended:Connect(function()
			if s then s:Destroy() end
			if con then con:Disconnect() end
		end)
	else
		s:Destroy()
	end
end

local function muteCharacterJumpSounds()
	for _, v in ipairs(char:GetDescendants()) do
		if v:IsA("Sound") and string.match(string.lower(v.Name), "jump") then
			v.Volume = 0
		end
	end
	char.DescendantAdded:Connect(function(desc)
		if desc:IsA("Sound") and string.match(string.lower(desc.Name), "jump") then
			desc.Volume = 0
		end
	end)
end

if humanoid then
	humanoid.Jumping:Connect(function(active)
		if active then
			muteCharacterJumpSounds()
			playCustomJump()
		end
	end)
end
