local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ObjectNames = require(ReplicatedStorage.Dictionaries.ObjectNames)
local Categories = require(ReplicatedStorage.Dictionaries.Categories)

local PowerConfig = {

	-- ============
	-- POWER GENERATORS
	-- ============
	[ObjectNames["Coal Generator"]] = {
		Category = Categories["Power Generator"],
		Output = 1.2,
		Inputs = {
			[ObjectNames.Coal] = { Amount = 1, Capacity = 50 },
		},
	},
	[ObjectNames["Steam Generator"]] = {
		Category = Categories["Power Generator"],
		Output = 6.0,
		Inputs = {
			[ObjectNames.Coal] = { Amount = 2, Capacity = 50 },
			[ObjectNames.Water] = { Amount = 4, Capacity = 50 },
		},
	},
	[ObjectNames["Solar Panel"]] = {
		Category = Categories["Power Generator"],
		Output = 0.12,
		Inputs = nil,
	},
	[ObjectNames["Geothermal Vent"]] = {
		Category = Categories["Power Generator"],
		Output = 5.0,
		Inputs = nil,
	},
	[ObjectNames["Nuclear Reactor"]] = {
		Category = Categories["Power Generator"],
		Output = 160.0,
		Inputs = {
			[ObjectNames["Refined Uranium"]] = { Amount = 1, Capacity = 10 },
			[ObjectNames.Coolant] = { Amount = 4, Capacity = 50 },
		},
	},

	-- ============
	-- BATTERIES
	-- ============
	[ObjectNames["Small Battery"]] = {
		Category = Categories.Battery,
		Capacity = 200,
	},
	[ObjectNames["Large Battery"]] = {
		Category = Categories.Battery,
		Capacity = 2000,
	},

	-- ============
	-- POWER NODES
	-- ============
	[ObjectNames["Small Power Node"]] = {
		Category = Categories["Power Node"],
		Range = 10,
		MaxLinks = 6,
	},
	[ObjectNames["Large Power Node"]] = {
		Category = Categories["Power Node"],
		Range = 18,
		MaxLinks = 15,
	},
}

-- ============================================================
-- GETTER APIs
-- ============================================================

function PowerConfig.Exists(buildingId)
	return PowerConfig[buildingId] ~= nil
end

function PowerConfig.Get(buildingId)
	local config = PowerConfig[buildingId]
	if not config then
		warn("PowerConfig.Get: building not found ->", buildingId)
		return nil
	end
	return config
end

function PowerConfig.GetCategory(buildingId)
	local config = PowerConfig.Get(buildingId)
	return config and config.Category
end

-- Generator APIs
function PowerConfig.GetOutput(buildingId)
	local config = PowerConfig.Get(buildingId)
	return config and config.Output or 0
end

function PowerConfig.GetInputs(buildingId)
	local config = PowerConfig.Get(buildingId)
	return config and config.Inputs
end

function PowerConfig.GetInputAmount(buildingId, resourceId)
	local config = PowerConfig.Get(buildingId)
	if not config or not config.Inputs then
		return 0
	end
	local input = config.Inputs[resourceId]
	return input and input.Amount or 0
end

function PowerConfig.GetInputCapacity(buildingId, resourceId)
	local config = PowerConfig.Get(buildingId)
	if not config or not config.Inputs then
		return 0
	end
	local input = config.Inputs[resourceId]
	return input and input.Capacity or 0
end

function PowerConfig.HasInputs(buildingId)
	local config = PowerConfig.Get(buildingId)
	return config and config.Inputs ~= nil
end

function PowerConfig.IsPassive(buildingId)
	return not PowerConfig.HasInputs(buildingId)
end

-- Battery APIs
function PowerConfig.GetCapacity(buildingId)
	local config = PowerConfig.Get(buildingId)
	return config and config.Capacity or 0
end

-- Node APIs
function PowerConfig.GetRange(buildingId)
	local config = PowerConfig.Get(buildingId)
	return config and config.Range or 0
end

function PowerConfig.GetMaxLinks(buildingId)
	local config = PowerConfig.Get(buildingId)
	return config and config.MaxLinks or 0
end

-- Category checks
function PowerConfig.IsGenerator(buildingId)
	local config = PowerConfig.Get(buildingId)
	return config and config.Category == Categories["Power Generator"]
end

function PowerConfig.IsBattery(buildingId)
	local config = PowerConfig.Get(buildingId)
	return config and config.Category == Categories.Battery
end

function PowerConfig.IsNode(buildingId)
	local config = PowerConfig.Get(buildingId)
	return config and config.Category == Categories["Power Node"]
end

return PowerConfig
