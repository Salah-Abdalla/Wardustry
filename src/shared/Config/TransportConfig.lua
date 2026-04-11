local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ObjectNames = require(ReplicatedStorage.Dictionaries.ObjectNames)

local TransportConfig = {

	-- ============
	-- CONVEYORS
	-- ============
	[ObjectNames["Conveyor"]] = {
		Speed = 2.5,
	},
	[ObjectNames["Express Conveyor"]] = {
		Speed = 5,
	},
	[ObjectNames["Reinforced Conveyor"]] = {
		Speed = 10,
	},
	[ObjectNames["Sprint Conveyor"]] = {
		Speed = 14,
	},

	-- ============
	-- LIQUID DUCTS
	-- ============
	[ObjectNames["Duct"]] = {
		Speed = 10,
	},
	[ObjectNames["Conduit"]] = {
		Speed = 22,
	},
	[ObjectNames["Pipe Bridge"]] = {
		Speed = 10,
	},
	[ObjectNames["Manifold"]] = {
		Speed = 10,
	},

	-- ============
	-- PAYLOAD
	-- ============
	[ObjectNames["Haul Sled"]] = {
		Speed = 4,
	},
	[ObjectNames["Haul Router"]] = {
		Speed = 4,
	},
	[ObjectNames["Dispatch Bay"]] = {
		Speed = 4,
	},
}

-- ============================================================
-- GETTER APIs
-- ============================================================

function TransportConfig.Exists(transportId)
	return TransportConfig[transportId] ~= nil
end

function TransportConfig.Get(transportId)
	local config = TransportConfig[transportId]
	if not config then
		warn("TransportConfig.Get: transport not found ->", transportId)
		return nil
	end
	return config
end

function TransportConfig.GetSpeed(transportId)
	local config = TransportConfig.Get(transportId)
	return config and config.Speed or 0
end

return TransportConfig
