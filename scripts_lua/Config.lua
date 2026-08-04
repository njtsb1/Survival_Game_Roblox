local Config = {}

-- Gameplay
Config.Zombie = {
    SpawnInterval = 2.0,        -- seconds between spawns (adjust)
    BaseSpeedMin = 2.0,         -- minimum speed (studs/s)
    BaseSpeedMax = 4.0,         -- maximum speed
    SpeedPerScore = 0.02,       -- increase per point
    BaseHP = 1,                 -- base HP
    PointsPerKill = 1
}

Config.Projectile = {
    Speed ​​= 120,                -- studs/s
    Lifetime = 4,               -- seconds
    Size = Vector3.new(0.4,0.4,0.4),
    Damage = 1
}

Config.World = {
    SpawnRadius = 80,           -- distance from player to spawn zombies
    MaxZombies = 40
}

-- Audio/visual (optional asset names)
Config.Sounds = {
    Shoot = nil,    -- insert assetId if using Sound instances
    Hit = nil,
    Explosion = nil,
    Spawn = nil
}

return Config