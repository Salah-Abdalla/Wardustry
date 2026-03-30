local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ObjectNames = require(ReplicatedStorage.Dictionaries.ObjectNames)

local UnitFactoryConfig = {

	-- ============
	-- TANK FACTORY BASIC
	-- ============
	[ObjectNames["Tank Factory Basic"]] = {
		PowerNeeded = 3.0,
		Recipes = {
			[ObjectNames["Basic Tank"]] = {
				Inputs = {
					[ObjectNames.Ferrocast] = { Amount = 30, Capacity = 150 },
					[ObjectNames.Silicon] = { Amount = 20, Capacity = 100 },
				},
				ProcessingTime = 10,
			},
			[ObjectNames["Light Tank"]] = {
				Inputs = {
					[ObjectNames.Ferrocast] = { Amount = 25, Capacity = 150 },
					[ObjectNames.Aluminite] = { Amount = 20, Capacity = 100 },
					[ObjectNames.Silicon] = { Amount = 15, Capacity = 100 },
				},
				ProcessingTime = 12,
			},
			[ObjectNames["Basic Heavy Tank"]] = {
				Inputs = {
					[ObjectNames.Ferrocast] = { Amount = 50, Capacity = 200 },
					[ObjectNames.Silicon] = { Amount = 30, Capacity = 150 },
					[ObjectNames.Graphite] = { Amount = 15, Capacity = 100 },
				},
				ProcessingTime = 30,
			},
		},
	},

	-- ============
	-- TANK FACTORY ADVANCED
	-- ============
	[ObjectNames["Tank Factory Advanced"]] = {
		PowerNeeded = 6.5,
		Recipes = {
			[ObjectNames["Super Heavy Tank"]] = {
				Inputs = {
					[ObjectNames.Steel] = { Amount = 40, Capacity = 100 },
					[ObjectNames.Ferrocast] = { Amount = 60, Capacity = 200 },
					[ObjectNames.Silicon] = { Amount = 30, Capacity = 150 },
				},
				ProcessingTime = 60,
			},
			[ObjectNames["Sniper Tank"]] = {
				Inputs = {
					[ObjectNames.Quartzite] = { Amount = 35, Capacity = 150 },
					[ObjectNames.Aluminite] = { Amount = 25, Capacity = 100 },
					[ObjectNames.Silicon] = { Amount = 20, Capacity = 100 },
				},
				ProcessingTime = 40,
			},
			[ObjectNames["Howitzer Tank"]] = {
				Inputs = {
					[ObjectNames.Ferrocast] = { Amount = 50, Capacity = 200 },
					[ObjectNames.Quartzite] = { Amount = 30, Capacity = 150 },
					[ObjectNames.Silicon] = { Amount = 20, Capacity = 100 },
				},
				ProcessingTime = 45,
			},
		},
	},

	-- ============
	-- DRONE FACTORY BASIC
	-- ============
	[ObjectNames["Drone Factory Basic"]] = {
		PowerNeeded = 2.5,
		Recipes = {
			[ObjectNames["Basic Drone"]] = {
				Inputs = {
					[ObjectNames.Aluminite] = { Amount = 20, Capacity = 100 },
					[ObjectNames.Silicon] = { Amount = 18, Capacity = 100 },
				},
				ProcessingTime = 9,
			},
			[ObjectNames["Bomber Drone"]] = {
				Inputs = {
					[ObjectNames.Aluminite] = { Amount = 28, Capacity = 150 },
					[ObjectNames.Silicon] = { Amount = 22, Capacity = 100 },
					[ObjectNames.Coal] = { Amount = 12, Capacity = 100 },
				},
				ProcessingTime = 14,
			},
			[ObjectNames["Kamikaze Drone"]] = {
				Inputs = {
					[ObjectNames.Aluminite] = { Amount = 14, Capacity = 100 },
					[ObjectNames.Coal] = { Amount = 10, Capacity = 100 },
				},
				ProcessingTime = 6,
			},
		},
	},

	-- ============
	-- DRONE FACTORY ADVANCED
	-- ============
	[ObjectNames["Drone Factory Advanced"]] = {
		PowerNeeded = 5.0,
		Recipes = {
			[ObjectNames["Gunship"]] = {
				Inputs = {
					[ObjectNames.Aluminite] = { Amount = 65, Capacity = 200 },
					[ObjectNames.Quartzite] = { Amount = 50, Capacity = 150 },
					[ObjectNames.Steel] = { Amount = 20, Capacity = 80 },
				},
				ProcessingTime = 50,
			},
			[ObjectNames["AA Drone"]] = {
				Inputs = {
					[ObjectNames.Aluminite] = { Amount = 50, Capacity = 200 },
					[ObjectNames.Quartzite] = { Amount = 35, Capacity = 150 },
					[ObjectNames.Silicon] = { Amount = 20, Capacity = 100 },
				},
				ProcessingTime = 35,
			},
			[ObjectNames["Stealth Drone"]] = {
				Inputs = {
					[ObjectNames.Quartzite] = { Amount = 45, Capacity = 150 },
					[ObjectNames.Aluminite] = { Amount = 35, Capacity = 150 },
					[ObjectNames.Silicon] = { Amount = 25, Capacity = 100 },
				},
				ProcessingTime = 40,
			},
		},
	},

	-- ============
	-- SUPPORT FACTORY BASIC
	-- ============
	[ObjectNames["Support Factory Basic"]] = {
		PowerNeeded = 2.2,
		Recipes = {
			[ObjectNames["Artillery Walker"]] = {
				Inputs = {
					[ObjectNames.Ferrocast] = { Amount = 35, Capacity = 150 },
					[ObjectNames.Silicon] = { Amount = 28, Capacity = 100 },
					[ObjectNames.Aluminite] = { Amount = 15, Capacity = 100 },
				},
				ProcessingTime = 16,
			},
			[ObjectNames["AA Crawler"]] = {
				Inputs = {
					[ObjectNames.Aluminite] = { Amount = 30, Capacity = 150 },
					[ObjectNames.Silicon] = { Amount = 25, Capacity = 100 },
				},
				ProcessingTime = 12,
			},
			[ObjectNames["Medic Walker"]] = {
				Inputs = {
					[ObjectNames.Ferrocast] = { Amount = 28, Capacity = 150 },
					[ObjectNames.Silicon] = { Amount = 20, Capacity = 100 },
					[ObjectNames.Glassite] = { Amount = 10, Capacity = 50 },
				},
				ProcessingTime = 11,
			},
		},
	},

	-- ============
	-- SUPPORT FACTORY ADVANCED
	-- ============
	[ObjectNames["Support Factory Advanced"]] = {
		PowerNeeded = 5.5,
		Recipes = {
			[ObjectNames["Projectile Interceptor"]] = {
				Inputs = {
					[ObjectNames.Aluminite] = { Amount = 50, Capacity = 200 },
					[ObjectNames.Quartzite] = { Amount = 40, Capacity = 150 },
					[ObjectNames.Silicon] = { Amount = 30, Capacity = 100 },
				},
				ProcessingTime = 35,
			},
			[ObjectNames["Kamikaze Drone Manufacturer"]] = {
				Inputs = {
					[ObjectNames.Ferrocast] = { Amount = 40, Capacity = 150 },
					[ObjectNames.Quartzite] = { Amount = 30, Capacity = 100 },
					[ObjectNames.Coal] = { Amount = 20, Capacity = 100 },
				},
				ProcessingTime = 30,
			},
			[ObjectNames["Commander"]] = {
				Inputs = {
					[ObjectNames.Quartzite] = { Amount = 80, Capacity = 200 },
					[ObjectNames.Silicon] = { Amount = 60, Capacity = 150 },
					[ObjectNames.Aluminite] = { Amount = 40, Capacity = 150 },
					[ObjectNames.Steel] = { Amount = 20, Capacity = 80 },
				},
				ProcessingTime = 60,
			},
		},
	},
}

-- ============================================================
-- GETTER APIs
-- ============================================================

function UnitFactoryConfig.Exists(factoryId)
	return UnitFactoryConfig[factoryId] ~= nil
end

function UnitFactoryConfig.Get(factoryId)
	local config = UnitFactoryConfig[factoryId]
	if not config then
		warn("UnitFactoryConfig.Get: factory not found ->", factoryId)
		return nil
	end
	return config
end

function UnitFactoryConfig.GetRecipes(factoryId)
	local config = UnitFactoryConfig.Get(factoryId)
	return config and config.Recipes
end

function UnitFactoryConfig.GetRecipe(factoryId, unitId)
	local recipes = UnitFactoryConfig.GetRecipes(factoryId)
	if not recipes then
		return nil
	end
	local recipe = recipes[unitId]
	if not recipe then
		warn("UnitFactoryConfig.GetRecipe: recipe not found ->", factoryId, unitId)
		return nil
	end
	return recipe
end

function UnitFactoryConfig.GetProducibleUnits(factoryId)
	local recipes = UnitFactoryConfig.GetRecipes(factoryId)
	if not recipes then
		return {}
	end
	local units = {}
	for unitId in pairs(recipes) do
		table.insert(units, unitId)
	end
	return units
end

function UnitFactoryConfig.GetInputs(factoryId, unitId)
	local recipe = UnitFactoryConfig.GetRecipe(factoryId, unitId)
	return recipe and recipe.Inputs
end

function UnitFactoryConfig.GetInputAmount(factoryId, unitId, resourceId)
	local recipe = UnitFactoryConfig.GetRecipe(factoryId, unitId)
	if not recipe then
		return 0
	end
	local input = recipe.Inputs[resourceId]
	return input and input.Amount or 0
end

function UnitFactoryConfig.GetInputCapacity(factoryId, unitId, resourceId)
	local recipe = UnitFactoryConfig.GetRecipe(factoryId, unitId)
	if not recipe then
		return 0
	end
	local input = recipe.Inputs[resourceId]
	return input and input.Capacity or 0
end

function UnitFactoryConfig.GetProcessingTime(factoryId, unitId)
	local recipe = UnitFactoryConfig.GetRecipe(factoryId, unitId)
	return recipe and recipe.ProcessingTime
end

function UnitFactoryConfig.GetPowerNeeded(factoryId)
	local config = UnitFactoryConfig.Get(factoryId)
	return config and config.PowerNeeded or 0
end

function UnitFactoryConfig.NeedsPower(factoryId)
	return UnitFactoryConfig.GetPowerNeeded(factoryId) > 0
end

function UnitFactoryConfig.GetAdjustedProcessingTime(factoryId, unitId, currentPower)
	local recipe = UnitFactoryConfig.GetRecipe(factoryId, unitId)
	if not recipe then
		return nil
	end

	local powerNeeded = UnitFactoryConfig.GetPowerNeeded(factoryId)
	if powerNeeded == 0 then
		return recipe.ProcessingTime
	end

	local powerEfficiency = math.min((currentPower or 0) / powerNeeded, 1)
	if powerEfficiency <= 0 then
		return math.huge
	end

	return recipe.ProcessingTime / powerEfficiency
end

function UnitFactoryConfig.CanProduce(factoryId, unitId, resourceBank)
	local recipe = UnitFactoryConfig.GetRecipe(factoryId, unitId)
	if not recipe then
		return false
	end
	for resource, data in pairs(recipe.Inputs) do
		if (resourceBank[resource] or 0) < data.Amount then
			return false
		end
	end
	return true
end

return UnitFactoryConfig
