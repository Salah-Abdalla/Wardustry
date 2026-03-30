local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ObjectNames = require(ReplicatedStorage.Dictionaries.ObjectNames)

local TurretBehaviorConfig = {

	[ObjectNames["Cannon"]] = {
		Class = "BasicTurret",
		TargetLogic = "Basic",
		ShootLogic = "Basic",
		BulletLogic = "Basic",
	},

	[ObjectNames["Flak Turret"]] = {
		Class = "BasicTurret",
		TargetLogic = "Basic",
		ShootLogic = "Basic",
		BulletLogic = "Basic",
	},

	[ObjectNames["Howitzer"]] = {
		Class = "ArtilleryTurret",
		TargetLogic = "Basic",
		ShootLogic = "Basic",
		BulletLogic = "Artillery",
	},

	[ObjectNames["Railgun"]] = {
		Class = "BasicTurret",
		TargetLogic = "Basic",
		ShootLogic = "Basic",
		BulletLogic = "Basic",
	},

	[ObjectNames["Flamethrower"]] = {
		Class = "FlamethrowerTurret",
		TargetLogic = "Basic",
		ShootLogic = "Continuous",
		BulletLogic = "Basic",
	},

	[ObjectNames["Tesla Tower"]] = {
		Class = "TeslaTurret",
		TargetLogic = "Basic",
		ShootLogic = "Basic",
		BulletLogic = "ChainArc",
	},

	[ObjectNames["Mortar"]] = {
		Class = "ArtilleryTurret",
		TargetLogic = "Basic",
		ShootLogic = "Basic",
		BulletLogic = "Artillery",
	},

	[ObjectNames["Sniper"]] = {
		Class = "BasicTurret",
		TargetLogic = "Basic",
		ShootLogic = "Basic",
		BulletLogic = "Basic",
	},

	[ObjectNames["Laser Cannon"]] = {
		Class = "LaserTurret",
		TargetLogic = "Basic",
		ShootLogic = "Basic",
		BulletLogic = "Pierce",
	},
}

-- ============================================================
-- GETTER APIs
-- ============================================================

function TurretBehaviorConfig.Exists(turretId)
	return TurretBehaviorConfig[turretId] ~= nil
end

function TurretBehaviorConfig.Get(turretId)
	local config = TurretBehaviorConfig[turretId]
	if not config then
		warn("TurretBehaviorConfig.Get: turret not found ->", turretId)
		return nil
	end
	return config
end

function TurretBehaviorConfig.GetClass(turretId)
	local config = TurretBehaviorConfig.Get(turretId)
	return config and config.Class
end

function TurretBehaviorConfig.GetTargetLogic(turretId)
	local config = TurretBehaviorConfig.Get(turretId)
	return config and config.TargetLogic
end

function TurretBehaviorConfig.GetShootLogic(turretId)
	local config = TurretBehaviorConfig.Get(turretId)
	return config and config.ShootLogic
end

function TurretBehaviorConfig.GetBulletLogic(turretId)
	local config = TurretBehaviorConfig.Get(turretId)
	return config and config.BulletLogic
end

function TurretBehaviorConfig.IsBasicTurret(turretId)
	local config = TurretBehaviorConfig.Get(turretId)
	return config and config.Class == "BasicTurret"
end

return TurretBehaviorConfig
