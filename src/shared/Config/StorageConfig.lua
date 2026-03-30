local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ObjectNames = require(ReplicatedStorage.Dictionaries.ObjectNames)

local StorageConfig = {

	-- ============
	-- CORE TIERS
	-- ============
	[ObjectNames["Core Shard"]] = {
		ItemCapacity = 1000,
		LiquidCapacity = 0,
		AcceptsLiquid = false,
	},
	[ObjectNames["Core Bastion"]] = {
		ItemCapacity = 4000,
		LiquidCapacity = 0,
		AcceptsLiquid = false,
	},
	[ObjectNames["Core Citadel"]] = {
		ItemCapacity = 10000,
		LiquidCapacity = 0,
		AcceptsLiquid = false,
	},

	-- ============
	-- SOLID STORAGE
	-- ============
	[ObjectNames["Vault"]] = {
		ItemCapacity = 1200,
		LiquidCapacity = 0,
		AcceptsLiquid = false,
	},
	[ObjectNames["Crate"]] = {
		ItemCapacity = 500,
		LiquidCapacity = 0,
		AcceptsLiquid = false,
	},

	-- ============
	-- LIQUID STORAGE
	-- ============
	[ObjectNames["Liquid Tank"]] = {
		ItemCapacity = 0,
		LiquidCapacity = 2000,
		AcceptsLiquid = true,
	},
}

-- ============================================================
-- GETTER APIs
-- ============================================================

function StorageConfig.Exists(buildingId)
	return StorageConfig[buildingId] ~= nil
end

function StorageConfig.Get(buildingId)
	local config = StorageConfig[buildingId]
	if not config then
		warn("StorageConfig.Get: building not found ->", buildingId)
		return nil
	end
	return config
end

function StorageConfig.GetItemCapacity(buildingId)
	local config = StorageConfig.Get(buildingId)
	return config and config.ItemCapacity or 0
end

function StorageConfig.GetLiquidCapacity(buildingId)
	local config = StorageConfig.Get(buildingId)
	return config and config.LiquidCapacity or 0
end

function StorageConfig.AcceptsLiquid(buildingId)
	local config = StorageConfig.Get(buildingId)
	return config and config.AcceptsLiquid == true
end

function StorageConfig.AcceptsItems(buildingId)
	return StorageConfig.GetItemCapacity(buildingId) > 0
end

function StorageConfig.IsCore(buildingId)
	return buildingId == ObjectNames["Core Shard"]
		or buildingId == ObjectNames["Core Bastion"]
		or buildingId == ObjectNames["Core Citadel"]
end

return StorageConfig
