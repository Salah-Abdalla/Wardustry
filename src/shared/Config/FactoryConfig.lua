local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ObjectNames = require(ReplicatedStorage.Dictionaries.ObjectNames)

local FactoryConfig = {

	[ObjectNames["Bronze Smelter"]] = {
		Inputs = {
			[ObjectNames.Copper] = { Amount = 3, Capacity = 50 },
			[ObjectNames.Tin] = { Amount = 3, Capacity = 50 },
		},
		Output = ObjectNames.Bronze,
		OutputAmount = 2,
		OutputCapacity = 50,
		ProcessingTime = 2.5,
		PowerNeeded = 0,
	},

	[ObjectNames["Ironstone Forge"]] = {
		Inputs = {
			[ObjectNames.Ironstone] = { Amount = 3, Capacity = 50 },
			[ObjectNames.Coal] = { Amount = 2, Capacity = 50 },
		},
		Output = ObjectNames.Ferrocast,
		OutputAmount = 2,
		OutputCapacity = 50,
		ProcessingTime = 3.0,
		PowerNeeded = 0,
	},

	[ObjectNames["Sand Kiln"]] = {
		Inputs = {
			[ObjectNames.Sand] = { Amount = 2, Capacity = 50 },
			[ObjectNames.Copper] = { Amount = 1, Capacity = 50 },
		},
		Output = ObjectNames.Glassite,
		OutputAmount = 1,
		OutputCapacity = 50,
		ProcessingTime = 2.5,
		PowerNeeded = 0,
	},

	[ObjectNames["Bauxite Refinery"]] = {
		Inputs = {
			[ObjectNames.Bauxite] = { Amount = 4, Capacity = 50 },
		},
		Output = ObjectNames.Aluminite,
		OutputAmount = 2,
		OutputCapacity = 50,
		ProcessingTime = 3.0,
		PowerNeeded = 1.5,
	},

	[ObjectNames["Graphite Press"]] = {
		Inputs = {
			[ObjectNames.Coal] = { Amount = 4, Capacity = 50 },
		},
		Output = ObjectNames.Graphite,
		OutputAmount = 3,
		OutputCapacity = 50,
		ProcessingTime = 4.0,
		PowerNeeded = 0,
	},

	[ObjectNames["Silicon Smelter"]] = {
		Inputs = {
			[ObjectNames.Coal] = { Amount = 2, Capacity = 50 },
			[ObjectNames.Sand] = { Amount = 6, Capacity = 50 },
		},
		Output = ObjectNames.Silicon,
		OutputAmount = 3,
		OutputCapacity = 50,
		ProcessingTime = 2.0,
		PowerNeeded = 1.2,
	},

	[ObjectNames["Quartz Press"]] = {
		Inputs = {
			[ObjectNames.Quartz] = { Amount = 2, Capacity = 50 },
			[ObjectNames.Ferrocast] = { Amount = 2, Capacity = 50 },
		},
		Output = ObjectNames.Quartzite,
		OutputAmount = 1,
		OutputCapacity = 50,
		ProcessingTime = 3.5,
		PowerNeeded = 2.0,
	},

	[ObjectNames["Steel Manufactuary"]] = {
		Inputs = {
			[ObjectNames.Ferrocast] = { Amount = 2, Capacity = 50 },
			[ObjectNames.Graphite] = { Amount = 2, Capacity = 50 },
		},
		Output = ObjectNames.Steel,
		OutputAmount = 1,
		OutputCapacity = 50,
		ProcessingTime = 3.0,
		PowerNeeded = 3.0,
	},

	[ObjectNames["Crude Vat"]] = {
		Inputs = {
			[ObjectNames.Coal] = { Amount = 4, Capacity = 50 },
			[ObjectNames.Coolant] = { Amount = 2, Capacity = 50 },
		},
		Output = ObjectNames.Crude,
		OutputAmount = 3,
		OutputCapacity = 50,
		ProcessingTime = 2.0,
		PowerNeeded = 1.8,
	},

	[ObjectNames["Uranium Refinery"]] = {
		Inputs = {
			[ObjectNames.Uranium] = { Amount = 4, Capacity = 30 },
		},
		Output = ObjectNames["Refined Uranium"],
		OutputAmount = 1,
		OutputCapacity = 20,
		ProcessingTime = 6.0,
		PowerNeeded = 2.5,
	},

	[ObjectNames["Coolant Mixer"]] = {
		Inputs = {
			[ObjectNames.Bauxite] = { Amount = 2, Capacity = 50 },
			[ObjectNames.Water] = { Amount = 4, Capacity = 50 },
		},
		Output = ObjectNames.Coolant,
		OutputAmount = 3,
		OutputCapacity = 50,
		ProcessingTime = 2.5,
		PowerNeeded = 1.0,
	},

	[ObjectNames["Steam Generator"]] = {
		Inputs = {
			[ObjectNames.Coal] = { Amount = 2, Capacity = 50 },
			[ObjectNames.Water] = { Amount = 4, Capacity = 50 },
		},
		Output = nil,
		OutputAmount = 0,
		OutputCapacity = 0,
		ProcessingTime = 2.0,
		PowerNeeded = 0,
	},
}

-- ============================================================
-- GETTER APIs
-- ============================================================

function FactoryConfig.Exists(factoryId)
	return FactoryConfig[factoryId] ~= nil
end

function FactoryConfig.Get(factoryId)
	local config = FactoryConfig[factoryId]
	if not config then
		warn("FactoryConfig.Get: factory not found ->", factoryId)
		return nil
	end
	return config
end

function FactoryConfig.GetInputs(factoryId)
	local config = FactoryConfig.Get(factoryId)
	return config and config.Inputs
end

-- Get required amount for a specific input resource
function FactoryConfig.GetInputAmount(factoryId, resourceId)
	local config = FactoryConfig.Get(factoryId)
	if not config then
		return 0
	end
	local input = config.Inputs[resourceId]
	return input and input.Amount or 0
end

-- Get capacity for a specific input resource
function FactoryConfig.GetInputCapacity(factoryId, resourceId)
	local config = FactoryConfig.Get(factoryId)
	if not config then
		return 0
	end
	local input = config.Inputs[resourceId]
	return input and input.Capacity or 0
end

function FactoryConfig.GetOutput(factoryId)
	local config = FactoryConfig.Get(factoryId)
	return config and config.Output
end

function FactoryConfig.GetOutputAmount(factoryId)
	local config = FactoryConfig.Get(factoryId)
	return config and config.OutputAmount or 0
end

function FactoryConfig.GetOutputCapacity(factoryId)
	local config = FactoryConfig.Get(factoryId)
	return config and config.OutputCapacity or 0
end

function FactoryConfig.GetProcessingTime(factoryId)
	local config = FactoryConfig.Get(factoryId)
	return config and config.ProcessingTime
end

function FactoryConfig.GetPowerNeeded(factoryId)
	local config = FactoryConfig.Get(factoryId)
	return config and config.PowerNeeded or 0
end

function FactoryConfig.NeedsPower(factoryId)
	return FactoryConfig.GetPowerNeeded(factoryId) > 0
end

function FactoryConfig.GetAdjustedProcessingTime(factoryId, currentPower)
	local config = FactoryConfig.Get(factoryId)
	if not config then
		return nil
	end

	local powerNeeded = FactoryConfig.GetPowerNeeded(factoryId)
	if powerNeeded == 0 then
		return config.ProcessingTime
	end

	local powerEfficiency = math.min((currentPower or 0) / powerNeeded, 1)
	if powerEfficiency <= 0 then
		return math.huge
	end

	return config.ProcessingTime / powerEfficiency
end

function FactoryConfig.CanProduce(factoryId, resourceBank)
	local config = FactoryConfig.Get(factoryId)
	if not config then
		return false
	end
	for resource, data in pairs(config.Inputs) do
		if (resourceBank[resource] or 0) < data.Amount then
			return false
		end
	end
	return true
end

return FactoryConfig
