local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService("ServerStorage")
local RunService = game:GetService("RunService")

-- Server-side dev check: requires ReplicatedStorage.DevList (ModuleScript returning array of userIds)
local function isDeveloper(player)
    local mod = ReplicatedStorage:FindFirstChild("DevList") or ReplicatedStorage:FindFirstChild("DevConfig")
    if mod and mod:IsA("ModuleScript") then
        local ok, list = pcall(require, mod)
        if ok and type(list) == "table" then
            for _, id in ipairs(list) do
                if id == player.UserId then
                    return true
                        -- Aggressively remove all tools for non-devs (handles Studio auto-copy timing)
                        task.spawn(function()
                            local backpack = player:FindFirstChild("Backpack") or player:WaitForChild("Backpack")
                            -- immediate removal
                            removeAllTools(player)
                            -- extra delayed attempts to catch engine/autocopy timing in Studio
                            task.delay(0.1, function() removeAllTools(player) end)
                            task.delay(1, function() removeAllTools(player) end)
                            task.delay(2, function() removeAllTools(player) end)

                            if backpack then
                                backpack.ChildAdded:Connect(function(child)
                                    if child:IsA("Tool") then
                                        pcall(function() child:Destroy() end)
                                    end
                                end)
                            end

                            player.CharacterAdded:Connect(function(char)
                                -- remove any tools that spawn in character and watch future adds
                                removeAllTools(player)
                                char.ChildAdded:Connect(function(child)
                                    if child:IsA("Tool") then
                                        pcall(function() child:Destroy() end)
                                    end
                                end)
                            end)
                        end)
end

-- Give dev tools to developer players by cloning from ServerStorage.DevTools
local function giveDevToolsToPlayer(player)
    local devToolsFolder = ServerStorage:FindFirstChild("DevTools")
    if not devToolsFolder then return end
    local backpack = player:FindFirstChild("Backpack") or player:WaitForChild("Backpack")
    if not backpack then return end
    for _, devTool in ipairs(devToolsFolder:GetChildren()) do
        if devTool:IsA("Tool") then
            -- avoid duplicates: check backpack for same name
            if not backpack:FindFirstChild(devTool.Name) then
                local clone = devTool:Clone()
                clone.Parent = backpack
            end
        end
    end
end

Players.PlayerAdded:Connect(function(player)
    -- Enforce on join
    if isDeveloper(player) then
        -- Give dev tools
        task.spawn(function()
            giveDevToolsToPlayer(player)
        end)
        -- Ensure tools are re-given on each respawn
        player.CharacterAdded:Connect(function()
            task.spawn(function() giveDevToolsToPlayer(player) end)
        end)
    else
        -- Remove all tools for non-devs and watch for future additions
        task.spawn(function()
            local backpack = player:FindFirstChild("Backpack") or player:WaitForChild("Backpack")
            if backpack then
                removeAllTools(player)
                backpack.ChildAdded:Connect(function(child)
                    if child:IsA("Tool") then
                        pcall(function() child:Destroy() end)
                    end
                end)
            end

            player.CharacterAdded:Connect(function(char)
                -- remove any tools that spawn in character and watch future adds
                for _, cItem in ipairs(char:GetChildren()) do
                    if cItem:IsA("Tool") then
                        pcall(function() cItem:Destroy() end)
                    end
                end
                char.ChildAdded:Connect(function(child)
                    if child:IsA("Tool") then
                        pcall(function() child:Destroy() end)
                    end
                end)
            end)
        end)
    end
end)

-- Cleanup for existing players when this script is added during runtime
for _, player in ipairs(Players:GetPlayers()) do
    if isDeveloper(player) then
        task.spawn(function() giveDevToolsToPlayer(player) end)
        player.CharacterAdded:Connect(function()
            task.spawn(function() giveDevToolsToPlayer(player) end)
        end)
    else
        task.spawn(function()
            local backpack = player:FindFirstChild("Backpack") or player:WaitForChild("Backpack")
            if backpack then
                removeAllTools(player)
                backpack.ChildAdded:Connect(function(child)
                    if child:IsA("Tool") then
                        pcall(function() child:Destroy() end)
                    end
                end)
            end
            if player.Character then
                for _, cItem in ipairs(player.Character:GetChildren()) do
                    if cItem:IsA("Tool") then
                        pcall(function() cItem:Destroy() end)
                    end
                end
                player.Character.ChildAdded:Connect(function(child)
                    if child:IsA("Tool") then
                        pcall(function() child:Destroy() end)
                    end
                end)
            end
        end)
    end
end
