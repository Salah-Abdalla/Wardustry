local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ObjectNames = require(ReplicatedStorage.Dictionaries.ObjectNames)

local TurretConfig = {

	-- ============
	-- CANNON
	-- ============
	[ObjectNames["Cannon"]] = {
		HP = 150,
		MaxAmmo = 12,
		Reload = 1.0,
		EngagementRange = 85,
		MinRange = 0,
		Targets = "Ground",
		Ammo = ObjectNames.Copper,
		BulletStats = {
			Damage = 30,
			Speed = 110,
			Range = 70,
			Splash = 0,
		},
	},

	-- ============
	-- FLAK TURRET
	-- ============
	[ObjectNames["Flak Turret"]] = {
		HP = 185,
		MaxAmmo = 8,
		Reload = 1.3,
		EngagementRange = 85,
		MinRange = 0,
		Targets = "Air",
		Ammo = ObjectNames.Bronze,
		BulletStats = {
			Damage = 55,
			Speed = 240,
			Range = 80,
			Splash = 0,
		},
	},

	-- ============
	-- HOWITZER
	-- ============
	[ObjectNames["Howitzer"]] = {
		HP = 320,
		MaxAmmo = 1,
		Reload = 4.5,
		EngagementRange = 195,
		MinRange = 60,
		Targets = "Ground",
		Ammo = ObjectNames["Pyro Charge"],
		BulletStats = {
			Damage = 110,
			Speed = 140,
			Range = 195,
			Splash = 10,
		},
	},

	-- ============
	-- RAILGUN
	-- ============
	[ObjectNames["Railgun"]] = {
		HP = 300,
		MaxAmmo = 5,
		Reload = 0.8,
		EngagementRange = 110,
		MinRange = 0,
		Targets = "Air",
		Ammo = ObjectNames.Aluminite,
		BulletStats = {
			Damage = 35,
			Speed = 275,
			Range = 120,
			Splash = 5,
		},
	},

	-- ============
	-- FLAMETHROWER
	-- ============
	[ObjectNames["Flamethrower"]] = {
		HP = 200,
		MaxAmmo = 20,
		Reload = 0.15,
		EngagementRange = 60,
		MinRange = 0,
		Targets = "Ground",
		Ammo = ObjectNames.Crude,
		BulletStats = {
			Damage = 12,
			Speed = 80,
			Range = 55,
			Splash = 4,
		},
	},

	-- ============
	-- TESLA TOWER
	-- ============
	[ObjectNames["Tesla Tower"]] = {
		HP = 280,
		MaxAmmo = 10,
		Reload = 0.8,
		EngagementRange = 110,
		MinRange = 0,
		Targets = "Both",
		Ammo = ObjectNames.Silicon,
		BulletStats = {
			Damage = 45,
			Speed = 300,
			Range = 100,
			Splash = 0,
		},
	},

	-- ============
	-- MORTAR
	-- ============
	[ObjectNames["Mortar"]] = {
		HP = 300,
		MaxAmmo = 1,
		Reload = 4.0,
		EngagementRange = 200,
		MinRange = 50,
		Targets = "Ground",
		Ammo = ObjectNames["Pyro Charge"],
		BulletStats = {
			Damage = 100,
			Speed = 150,
			Range = 200,
			Splash = 12,
		},
	},

	-- ============
	-- SNIPER
	-- ============
	[ObjectNames["Sniper"]] = {
		HP = 250,
		MaxAmmo = 10,
		Reload = 4.0,
		EngagementRange = 250,
		MinRange = 10,
		Targets = "Both",
		Ammo = ObjectNames.Ferrocast,
		BulletStats = {
			Damage = 150,
			Speed = 250,
			Range = 250,
			Splash = 0,
		},
	},

	-- ============
	-- LASER CANNON
	-- ============
	[ObjectNames["Laser Cannon"]] = {
		HP = 400,
		MaxAmmo = 6,
		Reload = 3.5,
		EngagementRange = 200,
		MinRange = 0,
		Targets = "Both",
		Ammo = ObjectNames.Quartzite,
		BulletStats = {
			Damage = 200,
			Speed = 400,
			Range = 190,
			Splash = 0,
		},
	},
}

-- ============================================================
-- GETTER APIs
-- ============================================================

function TurretConfig.Exists(turretId)
	return TurretConfig[turretId] ~= nil
end

function TurretConfig.Get(turretId)
	local config = TurretConfig[turretId]
	if not config then
		warn("TurretConfig.Get: turret not found ->", turretId)
		return nil
	end
	return config
end

function TurretConfig.GetHP(turretId)
	local config = TurretConfig.Get(turretId)
	return config and config.HP
end

function TurretConfig.GetMaxAmmo(turretId)
	local config = TurretConfig.Get(turretId)
	return config and config.MaxAmmo
end

function TurretConfig.GetReload(turretId)
	local config = TurretConfig.Get(turretId)
	return config and config.Reload
end

function TurretConfig.GetEngagementRange(turretId)
	local config = TurretConfig.Get(turretId)
	return config and config.EngagementRange
end

function TurretConfig.GetMinRange(turretId)
	local config = TurretConfig.Get(turretId)
	return config and config.MinRange
end

function TurretConfig.GetTargets(turretId)
	local config = TurretConfig.Get(turretId)
	return config and config.Targets
end

function TurretConfig.GetAmmo(turretId)
	local config = TurretConfig.Get(turretId)
	return config and config.Ammo
end

function TurretConfig.GetBulletStats(turretId)
	local config = TurretConfig.Get(turretId)
	return config and config.BulletStats
end

function TurretConfig.GetDamage(turretId)
	local config = TurretConfig.Get(turretId)
	return config and config.BulletStats and config.BulletStats.Damage
end

function TurretConfig.GetBulletSpeed(turretId)
	local config = TurretConfig.Get(turretId)
	return config and config.BulletStats and config.BulletStats.Speed
end

function TurretConfig.GetBulletRange(turretId)
	local config = TurretConfig.Get(turretId)
	return config and config.BulletStats and config.BulletStats.Range
end

function TurretConfig.GetSplash(turretId)
	local config = TurretConfig.Get(turretId)
	return config and config.BulletStats and config.BulletStats.Splash or 0
end

function TurretConfig.HasSplash(turretId)
	return TurretConfig.GetSplash(turretId) > 0
end

function TurretConfig.TargetsGround(turretId)
	local targets = TurretConfig.GetTargets(turretId)
	return targets == "Ground" or targets == "Both"
end

function TurretConfig.TargetsAir(turretId)
	local targets = TurretConfig.GetTargets(turretId)
	return targets == "Air" or targets == "Both"
end

return TurretConfig
