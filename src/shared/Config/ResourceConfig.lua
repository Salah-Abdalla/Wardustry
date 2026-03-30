local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ObjectNames = require(ReplicatedStorage.Dictionaries.ObjectNames)

local ResourceConfig = {

	-- ============
	-- RAW ORES
	-- ============
	[ObjectNames.Copper] = {
		DisplayName = "Copper",
		IconId = 0,
		Kind = "Ore",
		Value = 1,
		Description = "Common starter ore. Found in abundant surface deposits. Used in most early builds and smelting.",
	},
	[ObjectNames.Tin] = {
		DisplayName = "Tin",
		IconId = 0,
		Kind = "Ore",
		Value = 1,
		Description = "Soft metallic ore. Combined with Copper to produce Bronze.",
	},
	[ObjectNames.Ironstone] = {
		DisplayName = "Ironstone",
		IconId = 0,
		Kind = "Ore",
		Value = 2,
		Description = "Dense iron-bearing rock. Primary source of Ferrocast. Found in most mid-game sectors.",
	},
	[ObjectNames.Coal] = {
		DisplayName = "Coal",
		IconId = 0,
		Kind = "Ore",
		Value = 2,
		Description = "Black fuel mineral. Powers smelters and generators. Required for most early-mid processing.",
	},
	[ObjectNames.Bauxite] = {
		DisplayName = "Bauxite",
		IconId = 0,
		Kind = "Ore",
		Value = 3,
		Description = "Reddish aluminium ore. Refined into Aluminite. Also used with Water to produce Coolant.",
	},
	[ObjectNames.Sand] = {
		DisplayName = "Sand",
		IconId = 0,
		Kind = "Ore",
		Value = 1,
		Description = "Common ground material scraped from sandy tiles. Used to produce Glassite and Silicon.",
	},
	[ObjectNames.Quartz] = {
		DisplayName = "Quartz",
		IconId = 0,
		Kind = "Ore",
		Value = 4,
		Description = "Pale blue crystal ore. Gate material for T3 production. Combined with Ferrocast to make Quartzite.",
	},
	[ObjectNames.Uranium] = {
		DisplayName = "Uranium",
		IconId = 0,
		Kind = "Ore",
		Value = 6,
		Description = "Rare radioactive ore. Found only in late-game biomes. Refined into fuel for the Nuclear Reactor.",
	},

	-- ============
	-- LIQUIDS
	-- ============
	[ObjectNames.Water] = {
		DisplayName = "Water",
		IconId = 0,
		Kind = "Liquid",
		Value = 1,
		Description = "Extracted from water tiles via Liquid Extractor. Used in Coolant production and Steam Generator.",
	},
	[ObjectNames.Coolant] = {
		DisplayName = "Coolant",
		IconId = 0,
		Kind = "Liquid",
		Value = 3,
		Description = "Industrial cooling fluid made from Bauxite and Water. Required to run the Nuclear Reactor safely.",
	},
	[ObjectNames.Crude] = {
		DisplayName = "Crude",
		IconId = 0,
		Kind = "Liquid",
		Value = 3,
		Description = "Volatile dark liquid fuel. Produced in Crude Vat or extracted from Crude deposits. Used by Flamethrower turrets.",
	},

	-- ============
	-- PROCESSED MATERIALS
	-- ============
	[ObjectNames.Bronze] = {
		DisplayName = "Bronze",
		IconId = 0,
		Kind = "Processed",
		Value = 2,
		Description = "Copper-tin alloy. First processed material. Used in early builds, turret ammo and unit production.",
	},
	[ObjectNames.Ferrocast] = {
		DisplayName = "Ferrocast",
		IconId = 0,
		Kind = "Processed",
		Value = 3,
		Description = "Cast iron alloy smelted from Ironstone and Coal. Primary structural mid-game material.",
	},
	[ObjectNames.Aluminite] = {
		DisplayName = "Aluminite",
		IconId = 0,
		Kind = "Processed",
		Value = 3,
		Description = "Refined lightweight alloy from Bauxite. Used in drone frames, light turrets and fast conveyors.",
	},
	[ObjectNames.Glassite] = {
		DisplayName = "Glassite",
		IconId = 0,
		Kind = "Processed",
		Value = 2,
		Description = "Glass-ceramic compound from Sand and Copper. Used in pipes, sensors and optical components.",
	},
	[ObjectNames.Graphite] = {
		DisplayName = "Graphite",
		IconId = 0,
		Kind = "Processed",
		Value = 2,
		Description = "Compressed Coal. Used in Steel production, advanced belts and high-tier unit manufacturing.",
	},
	[ObjectNames.Silicon] = {
		DisplayName = "Silicon",
		IconId = 0,
		Kind = "Processed",
		Value = 3,
		Description = "Produced from Coal and Sand. Core material for electronics, advanced turrets and unit factories.",
	},
	[ObjectNames.Quartzite] = {
		DisplayName = "Quartzite",
		IconId = 0,
		Kind = "Processed",
		Value = 4,
		Description = "Crystal-lattice composite from Quartz and Ferrocast. T3 structural and electronic material.",
	},
	[ObjectNames.Steel] = {
		DisplayName = "Steel",
		IconId = 0,
		Kind = "Processed",
		Value = 6,
		Description = "Endgame alloy from Ferrocast and Graphite. Required for apex structures, walls and advanced units.",
	},
	[ObjectNames["Refined Uranium"]] = {
		DisplayName = "Refined Uranium",
		IconId = 0,
		Kind = "Processed",
		Value = 8,
		Description = "Processed uranium fuel rod. Loaded into the Nuclear Reactor. A small amount lasts a long time.",
	},
	[ObjectNames["Pyro Charge"]] = {
		DisplayName = "Pyro Charge",
		IconId = 0,
		Kind = "Processed",
		Value = 3,
		Description = "Explosive compound used as ammo for Howitzer and Mortar turrets. Flammable — protect storage.",
	},
}

-- ============================================================
-- GETTER APIs
-- ============================================================

function ResourceConfig.Exists(resourceId)
	return ResourceConfig[resourceId] ~= nil
end

function ResourceConfig.Get(resourceId)
	local config = ResourceConfig[resourceId]
	if not config then
		warn("ResourceConfig.Get: resource not found ->", resourceId)
		return nil
	end
	return config
end

function ResourceConfig.GetDisplayName(resourceId)
	local config = ResourceConfig.Get(resourceId)
	return config and config.DisplayName
end

function ResourceConfig.GetIconId(resourceId)
	local config = ResourceConfig.Get(resourceId)
	return config and config.IconId or 0
end

function ResourceConfig.GetKind(resourceId)
	local config = ResourceConfig.Get(resourceId)
	return config and config.Kind
end

function ResourceConfig.GetValue(resourceId)
	local config = ResourceConfig.Get(resourceId)
	return config and config.Value or 0
end

function ResourceConfig.GetDescription(resourceId)
	local config = ResourceConfig.Get(resourceId)
	return config and config.Description
end

function ResourceConfig.IsOre(resourceId)
	return ResourceConfig.GetKind(resourceId) == "Ore"
end

function ResourceConfig.IsLiquid(resourceId)
	return ResourceConfig.GetKind(resourceId) == "Liquid"
end

function ResourceConfig.IsProcessed(resourceId)
	return ResourceConfig.GetKind(resourceId) == "Processed"
end

function ResourceConfig.GetAllOfKind(kind)
	local results = {}
	for id, config in pairs(ResourceConfig) do
		if type(config) == "table" and config.Kind == kind then
			table.insert(results, id)
		end
	end
	return results
end

-- Returns the highest value ore from a list that the drill can mine
-- oreList = { [ObjectNames.Copper] = true, [ObjectNames.Quartz] = true, ... }
function ResourceConfig.GetHighestValueOre(oreList)
	local bestOre = nil
	local bestValue = -1
	for oreId in pairs(oreList) do
		local value = ResourceConfig.GetValue(oreId)
		if value > bestValue then
			bestValue = value
			bestOre = oreId
		end
	end
	return bestOre
end

return ResourceConfig
