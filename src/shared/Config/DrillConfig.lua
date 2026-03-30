local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ObjectNames = require(ReplicatedStorage.Dictionaries.ObjectNames)

local DrillConfig = {

	-- ============
	-- ORE MULTIPLIERS
	-- applied to drill BaseSpeed to get final drill rate
	-- ============
	OreMultipliers = {
		[ObjectNames.Copper] = 1.0,
		[ObjectNames.Tin] = 0.9,
		[ObjectNames.Sand] = 1.2,
		[ObjectNames.Ironstone] = 0.8,
		[ObjectNames.Bauxite] = 0.85,
		[ObjectNames.Quartz] = 0.6,
		[ObjectNames.Uranium] = 0.3,
		[ObjectNames.Coal] = 0.95,
	},

	-- ============
	-- DRILLS
	-- ============
	[ObjectNames["Basic Drill"]] = {
		BaseSpeed = 0.7,
		WaterBonus = 0,
		WaterNeeded = 0,
		PowerNeeded = 0,
		CanMine = {
			[ObjectNames.Copper] = { Capacity = 50 },
			[ObjectNames.Tin] = { Capacity = 50 },
			[ObjectNames.Sand] = { Capacity = 50 },
			[ObjectNames.Coal] = { Capacity = 50 },
		},
	},
	[ObjectNames["Pneumatic Drill"]] = {
		BaseSpeed = 1.1,
		WaterBonus = 0.15,
		WaterNeeded = 30,
		PowerNeeded = 1.0,
		CanMine = {
			[ObjectNames.Copper] = { Capacity = 60 },
			[ObjectNames.Tin] = { Capacity = 60 },
			[ObjectNames.Sand] = { Capacity = 60 },
			[ObjectNames.Coal] = { Capacity = 60 },
			[ObjectNames.Ironstone] = { Capacity = 60 },
			[ObjectNames.Bauxite] = { Capacity = 60 },
		},
	},
	[ObjectNames["Laser Drill"]] = {
		BaseSpeed = 2.6,
		WaterBonus = 0.25,
		WaterNeeded = 60,
		PowerNeeded = 1.8,
		CanMine = {
			[ObjectNames.Copper] = { Capacity = 80 },
			[ObjectNames.Tin] = { Capacity = 80 },
			[ObjectNames.Sand] = { Capacity = 80 },
			[ObjectNames.Coal] = { Capacity = 80 },
			[ObjectNames.Ironstone] = { Capacity = 80 },
			[ObjectNames.Bauxite] = { Capacity = 80 },
			[ObjectNames.Quartz] = { Capacity = 80 },
			[ObjectNames.Uranium] = { Capacity = 40 },
		},
	},
	[ObjectNames["Mega Drill"]] = {
		BaseSpeed = 5.5,
		WaterBonus = 0.35,
		WaterNeeded = 100,
		PowerNeeded = 3.5,
		CanMine = {
			[ObjectNames.Copper] = { Capacity = 100 },
			[ObjectNames.Tin] = { Capacity = 100 },
			[ObjectNames.Sand] = { Capacity = 100 },
			[ObjectNames.Coal] = { Capacity = 100 },
			[ObjectNames.Ironstone] = { Capacity = 100 },
			[ObjectNames.Bauxite] = { Capacity = 100 },
			[ObjectNames.Quartz] = { Capacity = 100 },
			[ObjectNames.Uranium] = { Capacity = 50 },
		},
	},
}

-- ============================================================
-- GETTER APIs
-- ============================================================

function DrillConfig.Exists(drillId)
	return DrillConfig[drillId] ~= nil
end

function DrillConfig.Get(drillId)
	local config = DrillConfig[drillId]
	if not config then
		warn("DrillConfig.Get: drill not found ->", drillId)
		return nil
	end
	return config
end

function DrillConfig.GetBaseSpeed(drillId)
	local config = DrillConfig.Get(drillId)
	return config and config.BaseSpeed or 0
end

function DrillConfig.GetWaterBonus(drillId)
	local config = DrillConfig.Get(drillId)
	return config and config.WaterBonus or 0
end

function DrillConfig.GetWaterNeeded(drillId)
	local config = DrillConfig.Get(drillId)
	return config and config.WaterNeeded or 0
end

function DrillConfig.NeedsWater(drillId)
	return DrillConfig.GetWaterNeeded(drillId) > 0
end

function DrillConfig.GetPowerNeeded(drillId)
	local config = DrillConfig.Get(drillId)
	return config and config.PowerNeeded or 0
end

function DrillConfig.NeedsPower(drillId)
	return DrillConfig.GetPowerNeeded(drillId) > 0
end

function DrillConfig.GetCanMine(drillId)
	local config = DrillConfig.Get(drillId)
	return config and config.CanMine
end

function DrillConfig.CanMineOre(drillId, oreId)
	local config = DrillConfig.Get(drillId)
	if not config then
		return false
	end
	return config.CanMine[oreId] ~= nil
end

function DrillConfig.GetOreCapacity(drillId, oreId)
	local config = DrillConfig.Get(drillId)
	if not config then
		return 0
	end
	local ore = config.CanMine[oreId]
	return ore and ore.Capacity or 0
end

function DrillConfig.GetOreMultiplier(oreId)
	local multiplier = DrillConfig.OreMultipliers[oreId]
	if not multiplier then
		warn("DrillConfig.GetOreMultiplier: ore not found ->", oreId)
		return 1.0
	end
	return multiplier
end

function DrillConfig.GetMinableOres(drillId)
	local config = DrillConfig.Get(drillId)
	if not config then
		return {}
	end
	local ores = {}
	for oreId in pairs(config.CanMine) do
		table.insert(ores, oreId)
	end
	return ores
end

function DrillConfig.GetDrillRate(drillId, oreId, currentWater, currentPower)
	if not DrillConfig.CanMineOre(drillId, oreId) then
		return 0
	end

	local base = DrillConfig.GetBaseSpeed(drillId)
	local multiplier = DrillConfig.GetOreMultiplier(oreId)
	local rate = base * multiplier

	-- Power scaling
	local powerNeeded = DrillConfig.GetPowerNeeded(drillId)
	if powerNeeded > 0 then
		local powerEfficiency = math.min((currentPower or 0) / powerNeeded, 1)
		rate = rate * powerEfficiency
	end

	-- Water bonus scaling on top of power adjusted rate
	local waterNeeded = DrillConfig.GetWaterNeeded(drillId)
	if waterNeeded > 0 and currentWater and currentWater > 0 then
		local waterEfficiency = math.min(currentWater / waterNeeded, 1)
		rate = rate * (1 + DrillConfig.GetWaterBonus(drillId) * waterEfficiency)
	end

	return rate
end

return DrillConfig
