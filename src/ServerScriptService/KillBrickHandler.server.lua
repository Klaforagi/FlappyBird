local function getAllKillBricks(parent)
	local bricks = {}
	for _, obj in ipairs(parent:GetChildren()) do
		if obj:IsA("BasePart") and type(obj.Name) == "string" and obj.Name:find("KillBrick", 1, true) then
			table.insert(bricks, obj)
		elseif obj:IsA("Folder") or obj:IsA("Model") then
			for _, b in ipairs(getAllKillBricks(obj)) do
				table.insert(bricks, b)
			end
		end
	end
	return bricks
end

local workspace = game:GetService("Workspace")

local killbricks = getAllKillBricks(workspace:WaitForChild("KillBricks"))

local function onBrickTouched(otherPart)
	local char = otherPart.Parent
	local humanoid = char and char:FindFirstChildWhichIsA("Humanoid")
	if humanoid then
		humanoid.Health = 0
	end
end

for _, brick in ipairs(killbricks) do
	brick.Touched:Connect(onBrickTouched)
end

-- Handle dynamically added killbricks
workspace.KillBricks.DescendantAdded:Connect(function(obj)
	if obj:IsA("BasePart") and type(obj.Name) == "string" and obj.Name:find("KillBrick", 1, true) then
		obj.Touched:Connect(onBrickTouched)
	end
end)
