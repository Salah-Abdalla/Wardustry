local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ObjectNames = require(ReplicatedStorage.Dictionaries.ObjectNames)

local BehaviorConfig = {

	-- ============
	-- TANKS
	-- ============
	[ObjectNames["Basic Tank"]] = {
		Class = "BasicUnit",
		MoveLogic = "Basic",
		TargetLogic = "Basic",
		ShootLogic = "Basic",
		BulletLogic = "Basic",
	},
	[ObjectNames["Light Tank"]] = {
		Class = "BasicUnit",
		MoveLogic = "Basic",
		TargetLogic = "Basic",
		ShootLogic = "Basic",
		BulletLogic = "Basic",
	},
	[ObjectNames["Basic Heavy Tank"]] = {
		Class = "BasicUnit",
		MoveLogic = "Basic",
		TargetLogic = "Basic",
		ShootLogic = "Basic",
		BulletLogic = "Basic",
	},
	[ObjectNames["Super Heavy Tank"]] = {
		Class = "BasicUnit",
		MoveLogic = "Basic",
		TargetLogic = "Basic",
		ShootLogic = "Basic",
		BulletLogic = "Basic",
	},
	[ObjectNames["Sniper Tank"]] = {
		Class = "BasicUnit",
		MoveLogic = "Basic",
		TargetLogic = "Basic",
		ShootLogic = "Basic",
		BulletLogic = "Basic",
	},
	[ObjectNames["Howitzer Tank"]] = {
		Class = "ArtilleryUnit",
		MoveLogic = "Basic",
		TargetLogic = "Basic",
		ShootLogic = "Basic",
		BulletLogic = "Artillery",
	},

	-- ============
	-- DRONES
	-- ============
	[ObjectNames["Basic Drone"]] = {
		Class = "AirUnit",
		MoveLogic = "BasicAir",
		TargetLogic = "Basic",
		ShootLogic = "Basic",
		BulletLogic = "Basic",
	},
	[ObjectNames["Bomber Drone"]] = {
		Class = "BomberUnit",
		MoveLogic = "BasicAir",
		TargetLogic = "Basic",
		ShootLogic = "Dive",
		BulletLogic = "Basic",
	},
	[ObjectNames["Kamikaze Drone"]] = {
		Class = "KamikazeUnit",
		MoveLogic = "Kamikaze",
		TargetLogic = "Basic",
		ShootLogic = "N/A",
		BulletLogic = "N/A",
	},
	[ObjectNames["Gunship"]] = {
		Class = "AirUnit",
		MoveLogic = "BasicAir",
		TargetLogic = "Basic",
		ShootLogic = "Basic",
		BulletLogic = "Scatter",
	},
	[ObjectNames["AA Drone"]] = {
		Class = "AirUnit",
		MoveLogic = "BasicAir",
		TargetLogic = "Basic",
		ShootLogic = "Basic",
		BulletLogic = "ChainArc",
	},
	[ObjectNames["Stealth Drone"]] = {
		Class = "StealthUnit",
		MoveLogic = "BasicAir",
		TargetLogic = "Basic",
		ShootLogic = "Basic",
		BulletLogic = "Basic",
	},

	-- ============
	-- SUPPORT
	-- ============
	[ObjectNames["Artillery Walker"]] = {
		Class = "ArtilleryUnit",
		MoveLogic = "Basic",
		TargetLogic = "Basic",
		ShootLogic = "Basic",
		BulletLogic = "Artillery",
	},
	[ObjectNames["AA Crawler"]] = {
		Class = "BasicUnit",
		MoveLogic = "Basic",
		TargetLogic = "Basic",
		ShootLogic = "Basic",
		BulletLogic = "Basic",
	},
	[ObjectNames["Medic Walker"]] = {
		Class = "MedicUnit",
		MoveLogic = "Basic",
		TargetLogic = "Ally",
		ShootLogic = "N/A",
		BulletLogic = "N/A",
	},
	[ObjectNames["Projectile Interceptor"]] = {
		Class = "InterceptorUnit",
		MoveLogic = "Basic",
		TargetLogic = "Projectile",
		ShootLogic = "Basic",
		BulletLogic = "Basic",
	},
	[ObjectNames["Kamikaze Drone Manufacturer"]] = {
		Class = "ManufacturerUnit",
		MoveLogic = "Basic",
		TargetLogic = "N/A",
		ShootLogic = "N/A",
		BulletLogic = "N/A",
	},
	[ObjectNames["Commander"]] = {
		Class = "CommanderUnit",
		MoveLogic = "Basic",
		TargetLogic = "Ally",
		ShootLogic = "N/A",
		BulletLogic = "N/A",
	},
}

-- ============================================================
-- GETTER APIs
-- ============================================================

function BehaviorConfig.Exists(unitId)
	return BehaviorConfig[unitId] ~= nil
end

function BehaviorConfig.Get(unitId)
	local config = BehaviorConfig[unitId]
	if not config then
		warn("BehaviorConfig.Get: unit not found ->", unitId)
		return nil
	end
	return config
end

function BehaviorConfig.GetClass(unitId)
	local config = BehaviorConfig.Get(unitId)
	return config and config.Class
end

function BehaviorConfig.GetMoveLogic(unitId)
	local config = BehaviorConfig.Get(unitId)
	return config and config.MoveLogic
end

function BehaviorConfig.GetTargetLogic(unitId)
	local config = BehaviorConfig.Get(unitId)
	return config and config.TargetLogic
end

function BehaviorConfig.GetShootLogic(unitId)
	local config = BehaviorConfig.Get(unitId)
	return config and config.ShootLogic
end

function BehaviorConfig.GetBulletLogic(unitId)
	local config = BehaviorConfig.Get(unitId)
	return config and config.BulletLogic
end

-- Check if unit uses basic master class behavior (no overrides needed)
function BehaviorConfig.IsBasicUnit(unitId)
	local config = BehaviorConfig.Get(unitId)
	return config and config.Class == "BasicUnit"
end

-- Check if unit has any N/A logics (non-combat unit)
function BehaviorConfig.IsNonCombat(unitId)
	local config = BehaviorConfig.Get(unitId)
	if not config then
		return false
	end
	return config.ShootLogic == "N/A" and config.BulletLogic == "N/A"
end

return BehaviorConfig
