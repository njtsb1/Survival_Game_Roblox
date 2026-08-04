local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Debris = game:GetService("Debris")

local Config = require(ReplicatedStorage:WaitForChild("Config"))
local remoteFolder = ReplicatedStorage:WaitForChild("RemoteEvents")
local FireBullet = remoteFolder:WaitForChild("FireBullet")

-- Container for zombies
local zombieFolder = Instance.new("Folder")
zombieFolder.Name = "Zombies"
zombieFolder.Parent = workspace

-- Utility: create a simple zombie model (Part + Humanoid)
local function createZombieModel(position, size)
    local model = Instance.new("Model")
    model.Name = "Zombie"

    local root = Instance.new("Part")
    root.Name = "HumanoidRootPart"
    root.Size = Vector3.new(size, size, size)
    root.Position = position
    root.Anchored = false
    root.CanCollide = true
    root.Parent = model

    local torso = Instance.new("Part")
    torso.Name = "Torso"
    torso.Size = Vector3.new(size*0.9, size*0.9, size*0.9)
    torso.Position = position + Vector3.new(0, size*0.5, 0)
    torso.Anchored = false
    torso.CanCollide = true
    torso.Parent = model

    local humanoid = Instance.new("Humanoid")
    humanoid.MaxHealth = Config.Zombie.BaseHP
    humanoid.Health = humanoid.MaxHealth
    humanoid.Parent = model

    -- Weld parts
    local weld = Instance.new("WeldConstraint")
    weld.Part0 = root
    weld.Part1 = torso
    weld.Parent = root

    model.PrimaryPart = root
    model.Parent = zombieFolder

    -- Visuals
    root.BrickColor = BrickColor.new("Bright green")
    torso.BrickColor = BrickColor.new("Dark stone grey")

    return model, humanoid
end

-- Move zombie toward nearest player
local function moveZombie(zombie, speed, dt)
    if not zombie or not zombie.PrimaryPart then return end
    local nearestPlayer, nearestDist, targetPos = nil, math.huge, nil
    for _, pl in pairs(Players:GetPlayers()) do
        if pl.Character and pl.Character:FindFirstChild("HumanoidRootPart") and pl.Character:FindFirstChild("Humanoid") and pl.Character.Humanoid.Health > 0 then
            local pos = pl.Character.HumanoidRootPart.Position
            local d = (zombie.PrimaryPart.Position - pos).Magnitude
            if d < nearestDist then
                nearestDist = d
                nearestPlayer = pl
                targetPos = pos
            end
        end
    end
    if targetPos then
        local dir = (targetPos - zombie.PrimaryPart.Position).Unit
        local bodyVel = zombie.PrimaryPart:FindFirstChild("ZombieVelocity")
        if not bodyVel then
            bodyVel = Instance.new("BodyVelocity")
            bodyVel.Name = "ZombieVelocity"
            bodyVel.MaxForce = Vector3.new(1e5, 1e5, 1e5)
            bodyVel.Parent = zombie.PrimaryPart
        end
        bodyVel.Velocity = dir * speed
    end
end

-- Explosion effect (server-side)
local function explodeAt(position)
    -- small visual: create ephemeral parts or use ParticleEmitter if you have assets
    local p = Instance.new("Part")
    p.Size = Vector3.new(1,1,1)
    p.Transparency = 1
    p.Anchored = true
    p.CanCollide = false
    p.Position = position
    p.Parent = workspace
    Debris:AddItem(p, 1)
    -- optionally play sound if you have asset
end

-- Handle projectile creation and collision on server
local function spawnProjectile(origin, direction, shooter)
    local proj = Instance.new("Part")
    proj.Name = "Bullet"
    proj.Size = Config.Projectile.Size
    proj.CFrame = CFrame.new(origin)
    proj.CanCollide = false
    proj.Anchored = false
    proj.Parent = workspace

    local bv = Instance.new("BodyVelocity")
    bv.MaxForce = Vector3.new(1e5,1e5,1e5)
    bv.Velocity = direction.Unit * Config.Projectile.Speed
    bv.Parent = proj

    -- lifetime cleanup
    Debris:AddItem(proj, Config.Projectile.Lifetime)

    -- Touched handler
    local conn
    conn = proj.Touched:Connect(function(hit)
        if not hit or not hit.Parent then return end
        -- ignore shooter character parts
        if shooter and shooter.Character and hit:IsDescendantOf(shooter.Character) then return end

        -- check if hit a zombie model
        local model = hit:FindFirstAncestorOfClass("Model")
        if model and model.Parent == zombieFolder and model:FindFirstChildOfClass("Humanoid") then
            local hum = model:FindFirstChildOfClass("Humanoid")
            if hum and hum.Health > 0 then
                hum:TakeDamage(Config.Projectile.Damage)
                -- small hit effect
                explodeAt(proj.Position)
                -- award points if dead
                if hum.Health - Config.Projectile.Damage <= 0 then
                    -- give points to shooter
                    if shooter and shooter:IsA("Player") then
                        local leaderstats = shooter:FindFirstChild("leaderstats")
                        if leaderstats and leaderstats:FindFirstChild("Score") then
                            leaderstats.Score.Value = leaderstats.Score.Value + Config.Zombie.PointsPerKill
                        end
                    end
                end
                -- destroy projectile
                if conn then conn:Disconnect() end
                proj:Destroy()
            end
        else
            -- hit world or other object: destroy bullet
            if conn then conn:Disconnect() end
            proj:Destroy()
        end
    end)
end

-- Listen to client fire events
FireBullet.OnServerEvent:Connect(function(player, data)
    -- data = {Origin = Vector3, Direction = Vector3}
    if not data or not data.Origin or not data.Direction then return end
    spawnProjectile(data.Origin, data.Direction, player)
end)

-- Leaderstats for score
local function onPlayerAdded(player)
    local leaderstats = Instance.new("Folder")
    leaderstats.Name = "leaderstats"
    leaderstats.Parent = player

    local score = Instance.new("IntValue")
    score.Name = "Score"
    score.Value = 0
    score.Parent = leaderstats
end
Players.PlayerAdded:Connect(onPlayerAdded)

-- Spawn loop
spawn(function()
    while true do
        -- count zombies
        if #zombieFolder:GetChildren() < Config.World.MaxZombies then
            -- choose a random player to spawn around (if none, spawn near origin)
            local players = Players:GetPlayers()
            local spawnPos = Vector3.new(0,5,0)
            if #players > 0 then
                local p = players[math.random(1,#players)]
                if p.Character and p.Character:FindFirstChild("HumanoidRootPart") then
                    local base = p.Character.HumanoidRootPart.Position
                    local angle = math.random() * math.pi * 2
                    local r = Config.World.SpawnRadius
                    spawnPos = base + Vector3.new(math.cos(angle)*r, 0, math.sin(angle)*r)
                    spawnPos = Vector3.new(spawnPos.X, 3 + math.random()*2, spawnPos.Z)
                end
            end

            local model, humanoid = createZombieModel(spawnPos, 2.8)
            -- set speed based on score average (simple)
            local avgScore = 0
            local count = 0
            for _,pl in pairs(Players:GetPlayers()) do
                local ls = pl:FindFirstChild("leaderstats")
                if ls and ls:FindFirstChild("Score") then
                    avgScore = avgScore + ls.Score.Value
                    count = count + 1
                end
            end
            if count > 0 then avgScore = avgScore / count end
            local speed = math.random() * (Config.Zombie.BaseSpeedMax - Config.Zombie.BaseSpeedMin) + Config.Zombie.BaseSpeedMin
            speed = speed + (avgScore * Config.Zombie.SpeedPerScore)

            -- connect humanoid death to explosion and cleanup
            humanoid.Died:Connect(function()
                local pos = model.PrimaryPart and model.PrimaryPart.Position or Vector3.new(0,0,0)
                explodeAt(pos)
                model:Destroy()
            end)

            -- simple movement loop for this zombie
            spawn(function()
                while model.Parent == zombieFolder and model.PrimaryPart and humanoid.Health > 0 do
                    local dt = 0.1
                    moveZombie(model, speed, dt)
                    wait(dt)
                end
            end)
        end
        wait(Config.Zombie.SpawnInterval)
    end
end)
