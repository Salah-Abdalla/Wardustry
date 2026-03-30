local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ObjectNames = require(ReplicatedStorage.Dictionaries.ObjectNames)

local UnitConfig = {

	-- ============
	-- TANKS
	-- ============
	[ObjectNames["Basic Tank"]] = {
		HP = 200,
		Speed = 22,
		UnitType = ObjectNames.Ground,
		Targets = "Ground",
		TargetAllies = false,
		ReloadSpeed = 1.1,
		EngagementRange = 85,
		ShootingRange = 65,
		StoppingRange = 20,
		RetreatingRange = 12,
		Armor = 0,
		BulletStats = {
			Damage = 30,
			Speed = 110,
			Range = 65,
			Name = "Basic",
			Splash = 0,
		},
	},
	[ObjectNames["Light Tank"]] = {
		HP = 120,
		Speed = 35,
		UnitType = ObjectNames.Ground,
		Targets = "Ground",
		TargetAllies = false,
		ReloadSpeed = 0.9,
		EngagementRange = 80,
		ShootingRange = 60,
		StoppingRange = 15,
		RetreatingRange = 10,
		Armor = 0,
		BulletStats = {
			Damage = 20,
			Speed = 120,
			Range = 60,
			Name = "Basic",
			Splash = 0,
		},
	},
	[ObjectNames["Basic Heavy Tank"]] = {
		HP = 600,
		Speed = 10,
		UnitType = ObjectNames.Ground,
		Targets = "Ground",
		TargetAllies = false,
		ReloadSpeed = 1.75,
		EngagementRange = 100,
		ShootingRange = 80,
		StoppingRange = 50,
		RetreatingRange = 15,
		Armor = 10,
		BulletStats = {
			Damage = 100,
			Speed = 120,
			Range = 90,
			Name = "Basic",
			Splash = 0,
		},
	},
	[ObjectNames["Super Heavy Tank"]] = {
		HP = 1600,
		Speed = 8,
		UnitType = ObjectNames.Ground,
		Targets = "Ground",
		TargetAllies = false,
		ReloadSpeed = 2.2,
		EngagementRange = 105,
		ShootingRange = 88,
		StoppingRange = 45,
		RetreatingRange = 22,
		Armor = 25,
		BulletStats = {
			Damage = 170,
			Speed = 115,
			Range = 95,
			Name = "Basic",
			Splash = 0,
		},
	},
	[ObjectNames["Sniper Tank"]] = {
		HP = 280,
		Speed = 14,
		UnitType = ObjectNames.Ground,
		Targets = "Ground",
		TargetAllies = false,
		ReloadSpeed = 3.5,
		EngagementRange = 220,
		ShootingRange = 200,
		StoppingRange = 180,
		RetreatingRange = 80,
		Armor = 5,
		BulletStats = {
			Damage = 180,
			Speed = 250,
			Range = 200,
			Name = "Sniper",
			Splash = 0,
		},
	},
	[ObjectNames["Howitzer Tank"]] = {
		HP = 380,
		Speed = 12,
		UnitType = ObjectNames.Ground,
		Targets = "Ground",
		TargetAllies = false,
		ReloadSpeed = 3.8,
		EngagementRange = 190,
		ShootingRange = 175,
		StoppingRange = 155,
		RetreatingRange = 70,
		Armor = 8,
		BulletStats = {
			Damage = 140,
			Speed = 140,
			Range = 180,
			Name = "Mortar Ball",
			Splash = 12,
		},
	},

	-- ============
	-- DRONES
	-- ============
	[ObjectNames["Basic Drone"]] = {
		HP = 100,
		Speed = 35,
		UnitType = ObjectNames.Air,
		Targets = "Both",
		TargetAllies = false,
		ReloadSpeed = 1.2,
		EngagementRange = 120,
		ShootingRange = 70,
		StoppingRange = 20,
		RetreatingRange = 10,
		Armor = 0,
		BulletStats = {
			Damage = 20,
			Speed = 120,
			Range = 80,
			Name = "Basic",
			Splash = 0,
		},
		AirSettings = {
			MaxHeight = 18,
			FallSpeed = -3,
			FlySpeed = 6,
		},
	},
	[ObjectNames["Bomber Drone"]] = {
		HP = 200,
		Speed = 16,
		UnitType = ObjectNames.Air,
		Targets = "Ground",
		TargetAllies = false,
		ReloadSpeed = 0.9,
		EngagementRange = 90,
		ShootingRange = 5,
		StoppingRange = 0.25,
		RetreatingRange = 0,
		Armor = 0,
		BulletStats = {
			Damage = 40,
			Speed = 40,
			Range = 40,
			Name = "TNT",
			Splash = 9,
		},
		AirSettings = {
			MaxHeight = 25,
			FallSpeed = -4,
			FlySpeed = 5,
		},
	},
	[ObjectNames["Kamikaze Drone"]] = {
		HP = 75,
		Speed = 42,
		UnitType = ObjectNames.Air,
		Targets = "Ground",
		TargetAllies = false,
		ReloadSpeed = 0,
		EngagementRange = 75,
		ShootingRange = 0,
		StoppingRange = 0,
		RetreatingRange = 0,
		Armor = 0,
		BulletStats = nil,
		AirSettings = {
			MaxHeight = 12,
			FallSpeed = -28,
			FlySpeed = 5,
		},
	},
	[ObjectNames["Gunship"]] = {
		HP = 750,
		Speed = 15,
		UnitType = ObjectNames.Air,
		Targets = "Both",
		TargetAllies = false,
		ReloadSpeed = 0.6,
		EngagementRange = 125,
		ShootingRange = 95,
		StoppingRange = 40,
		RetreatingRange = 18,
		Armor = 8,
		BulletStats = {
			Damage = 25,
			Speed = 115,
			Range = 100,
			Name = "Basic",
			Splash = 0,
		},
		AirSettings = {
			MaxHeight = 25,
			FallSpeed = -5,
			FlySpeed = 4,
		},
	},
	[ObjectNames["AA Drone"]] = {
		HP = 220,
		Speed = 20,
		UnitType = ObjectNames.Air,
		Targets = "Air",
		TargetAllies = false,
		ReloadSpeed = 0.8,
		EngagementRange = 120,
		ShootingRange = 90,
		StoppingRange = 35,
		RetreatingRange = 15,
		Armor = 0,
		BulletStats = {
			Damage = 40,
			Speed = 280,
			Range = 95,
			Name = "Missile",
			Splash = 5,
		},
		AirSettings = {
			MaxHeight = 20,
			FallSpeed = -3,
			FlySpeed = 5,
		},
	},
	[ObjectNames["Stealth Drone"]] = {
		HP = 180,
		Speed = 28,
		UnitType = ObjectNames.Air,
		Targets = "Ground",
		TargetAllies = false,
		ReloadSpeed = 2.0,
		EngagementRange = 100,
		ShootingRange = 80,
		StoppingRange = 30,
		RetreatingRange = 15,
		Armor = 0,
		BulletStats = {
			Damage = 120,
			Speed = 200,
			Range = 85,
			Name = "Sniper",
			Splash = 0,
		},
		AirSettings = {
			MaxHeight = 20,
			FallSpeed = -3,
			FlySpeed = 6,
		},
	},

	-- ============
	-- SUPPORT
	-- ============
	[ObjectNames["Artillery Walker"]] = {
		HP = 140,
		Speed = 8,
		UnitType = ObjectNames.Ground,
		Targets = "Ground",
		TargetAllies = false,
		ReloadSpeed = 2.8,
		EngagementRange = 185,
		ShootingRange = 170,
		StoppingRange = 155,
		RetreatingRange = 70,
		Armor = 0,
		BulletStats = {
			Damage = 100,
			Speed = 135,
			Range = 170,
			Name = "Mortar Ball",
			Splash = 10,
		},
	},
	[ObjectNames["AA Crawler"]] = {
		HP = 200,
		Speed = 20,
		UnitType = ObjectNames.Ground,
		Targets = "Air",
		TargetAllies = false,
		ReloadSpeed = 1.0,
		EngagementRange = 80,
		ShootingRange = 70,
		StoppingRange = 55,
		RetreatingRange = 50,
		Armor = 0,
		BulletStats = {
			Damage = 50,
			Speed = 210,
			Range = 75,
			Name = "Missile",
			Splash = 0,
		},
	},
	[ObjectNames["Medic Walker"]] = {
		HP = 160,
		Speed = 14,
		UnitType = ObjectNames.Ground,
		Targets = "Neither",
		TargetAllies = true,
		ReloadSpeed = 0,
		EngagementRange = 0,
		ShootingRange = 0,
		StoppingRange = 0,
		RetreatingRange = 0,
		Armor = 0,
		BulletStats = nil,
	},
	[ObjectNames["Projectile Interceptor"]] = {
		HP = 250,
		Speed = 16,
		UnitType = ObjectNames.Ground,
		Targets = "Neither",
		TargetAllies = false,
		ReloadSpeed = 0.5,
		EngagementRange = 90,
		ShootingRange = 80,
		StoppingRange = 60,
		RetreatingRange = 50,
		Armor = 5,
		BulletStats = {
			Damage = 0,
			Speed = 300,
			Range = 85,
			Name = "Interceptor",
			Splash = 0,
		},
	},
	[ObjectNames["Kamikaze Drone Manufacturer"]] = {
		HP = 180,
		Speed = 6,
		UnitType = ObjectNames.Ground,
		Targets = "Neither",
		TargetAllies = false,
		ReloadSpeed = 0,
		EngagementRange = 0,
		ShootingRange = 0,
		StoppingRange = 0,
		RetreatingRange = 0,
		Armor = 0,
		BulletStats = nil,
	},
	[ObjectNames["Commander"]] = {
		HP = 300,
		Speed = 10,
		UnitType = ObjectNames.Ground,
		Targets = "Neither",
		TargetAllies = true,
		ReloadSpeed = 0,
		EngagementRange = 0,
		ShootingRange = 0,
		StoppingRange = 0,
		RetreatingRange = 0,
		Armor = 5,
		BulletStats = nil,
	},
}

-- ============================================================
-- GETTER APIs
-- ============================================================

function UnitConfig.Exists(unitId)
	return UnitConfig[unitId] ~= nil
end

function UnitConfig.Get(unitId)
	local config = UnitConfig[unitId]
	if not config then
		warn("UnitConfig.Get: unit not found ->", unitId)
		return nil
	end
	return config
end

function UnitConfig.GetHP(unitId)
	local config = UnitConfig.Get(unitId)
	return config and config.HP
end

function UnitConfig.GetSpeed(unitId)
	local config = UnitConfig.Get(unitId)
	return config and config.Speed
end

function UnitConfig.GetUnitType(unitId)
	local config = UnitConfig.Get(unitId)
	return config and config.UnitType
end

function UnitConfig.GetTargets(unitId)
	local config = UnitConfig.Get(unitId)
	return config and config.Targets
end

function UnitConfig.GetTargetAllies(unitId)
	local config = UnitConfig.Get(unitId)
	return config and config.TargetAllies
end

function UnitConfig.GetReloadSpeed(unitId)
	local config = UnitConfig.Get(unitId)
	return config and config.ReloadSpeed
end

function UnitConfig.GetEngagementRange(unitId)
	local config = UnitConfig.Get(unitId)
	return config and config.EngagementRange
end

function UnitConfig.GetShootingRange(unitId)
	local config = UnitConfig.Get(unitId)
	return config and config.ShootingRange
end

function UnitConfig.GetStoppingRange(unitId)
	local config = UnitConfig.Get(unitId)
	return config and config.StoppingRange
end

function UnitConfig.GetRetreatingRange(unitId)
	local config = UnitConfig.Get(unitId)
	return config and config.RetreatingRange
end

function UnitConfig.GetArmor(unitId)
	local config = UnitConfig.Get(unitId)
	return config and config.Armor or 0
end

function UnitConfig.GetBulletStats(unitId)
	local config = UnitConfig.Get(unitId)
	return config and config.BulletStats
end

function UnitConfig.HasBulletStats(unitId)
	return UnitConfig.GetBulletStats(unitId) ~= nil
end

function UnitConfig.GetAirSettings(unitId)
	local config = UnitConfig.Get(unitId)
	return config and config.AirSettings
end

function UnitConfig.IsAirUnit(unitId)
	return UnitConfig.GetUnitType(unitId) == ObjectNames.Air
end

function UnitConfig.IsGroundUnit(unitId)
	return UnitConfig.GetUnitType(unitId) == ObjectNames.Ground
end

function UnitConfig.TargetsGround(unitId)
	local targets = UnitConfig.GetTargets(unitId)
	return targets == "Ground" or targets == "Both"
end

function UnitConfig.TargetsAir(unitId)
	local targets = UnitConfig.GetTargets(unitId)
	return targets == "Air" or targets == "Both"
end

function UnitConfig.TargetsAllies(unitId)
	return UnitConfig.GetTargetAllies(unitId) == true
end

return UnitConfig
