local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local player = Players.LocalPlayer
local mouse = player:GetMouse()
local character = player.Character or player.CharacterAdded:Wait()

local remoteFolder = ReplicatedStorage:WaitForChild("RemoteEvents")
local FireBullet = remoteFolder:WaitForChild("FireBullet")

local Config = require(ReplicatedStorage:WaitForChild("Config"))

-- UI: basic HUD creation (if you already have a ScreenGui, adapt IDs)
local StarterGui = game:GetService("StarterGui")
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "GameUI"
screenGui.ResetOnSpawn = false
screenGui.Parent = player:WaitForChild("PlayerGui")

local scoreLabel = Instance.new("TextLabel")
scoreLabel.Name = "ScoreLabel"
scoreLabel.Size = UDim2.new(0,160,0,36)
scoreLabel.Position = UDim2.new(0,12,0,12)
scoreLabel.BackgroundTransparency = 0.4
scoreLabel.BackgroundColor3 = Color3.fromRGB(20,20,20)
scoreLabel.TextColor3 = Color3.new(1,1,1)
scoreLabel.Text = "Score: 0"
scoreLabel.Parent = screenGui

-- Theme and language simple toggles (client-side)
local theme = "dark"
local lang = "en"

-- Helper: get character root
local function getRoot()
    if player.Character and player.Character:FindFirstChild("HumanoidRootPart") then
        return player.Character.HumanoidRootPart
    end
    return nil
end

-- Aim and shoot
local lastFire = 0
local fireCooldown = 0.18

local function fireAt(targetPos)
    local root = getRoot()
    if not root then return end
    local origin = root.Position + Vector3.new(0,1.2,0)
    local dir = (targetPos - origin).Unit
    -- send to server
    FireBullet:FireServer({Origin = origin, Direction = dir})
    lastFire = tick()
end

-- Mouse click
mouse.Button1Down:Connect(function()
    if tick() - lastFire < fireCooldown then return end
    local target = mouse.Hit and mouse.Hit.p or (getRoot() and getRoot().Position + Vector3.new(0,0,-10) or Vector3.new(0,0,0))
    fireAt(target)
end)

-- Keyboard shooting (space)
UserInputService.InputBegan:Connect(function(input, gameProcessed)
    if gameProcessed then return end
    if input.KeyCode == Enum.KeyCode.Space then
        if tick() - lastFire < fireCooldown then return end
        -- shoot forward relative to camera
        local cam = workspace.CurrentCamera
        local origin = getRoot() and (getRoot().Position + Vector3.new(0,1.2,0)) or Vector3.new(0,5,0)
        local dir = cam.CFrame.LookVector
        FireBullet:FireServer({Origin = origin, Direction = dir})
        lastFire = tick()
    end
end)

-- Rotate character to face mouse (client-side visual)
RunService.RenderStepped:Connect(function()
    local root = getRoot()
    if root and mouse and mouse.Hit then
        local lookAt = Vector3.new(mouse.Hit.p.X, root.Position.Y, mouse.Hit.p.Z)
        root.CFrame = CFrame.new(root.Position, lookAt)
    end
end)

-- Update HUD from leaderstats
local function onLeaderstatsAdded(ls)
    local score = ls:FindFirstChild("Score")
    if score then
        score.Changed:Connect(function(val)
            scoreLabel.Text = "Score: " .. tostring(val)
        end)
        scoreLabel.Text = "Score: " .. tostring(score.Value)
    end
end

if player:FindFirstChild("leaderstats") then
    onLeaderstatsAdded(player.leaderstats)
end
player.ChildAdded:Connect(function(child)
    if child.Name == "leaderstats" then
        onLeaderstatsAdded(child)
    end
end)

-- Respawn handling (optional)
player.CharacterAdded:Connect(function(char)
    character = char
    wait(0.5)
    -- ensure HUD visible
    scoreLabel.Parent = player:WaitForChild("PlayerGui"):FindFirstChild("GameUI") or screenGui
end)
