local FORWARD_SPEED = 18
local MOVE_SPEED = 18
local char = script.Parent
local hrp = char:WaitForChild("HumanoidRootPart")
local humanoid = char:WaitForChild("Humanoid")
local flappyMode = char:WaitForChild("FlappyMode")
local RunService = game:GetService("RunService")
local UIS = game:GetService("UserInputService")

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
			
			-- Face movement direction
			if moveX ~= 0 then
				hrp.CFrame = CFrame.new(hrp.Position, hrp.Position + Vector3.new(moveX, 0, 0))
			end
			
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
	print("Mobile: Using default Roblox controls!")
	
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
	
	-- Let Roblox's default mobile controls work (thumbstick + jump button)
	-- No custom movement code needed - just don't interfere
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
