local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ObjectNames = require(ReplicatedStorage.Dictionaries.ObjectNames)

local ResearchTree = {}

-- ============================================================
-- TREE DATA
-- each node:
--   parent = string or nil (root nodes have no parent)
--   cost   = { [resource] = amount }
-- ============================================================

local Nodes = {

	-- ============
	-- ROOT NODES
	-- ============
	[ObjectNames["Basic Drill"]] = {
		parent = nil,
		cost = {},
	},
	[ObjectNames["Conveyor"]] = {
		parent = nil,
		cost = {},
	},
	[ObjectNames["Cannon"]] = {
		parent = nil,
		cost = {},
	},
	[ObjectNames["Core Shard"]] = {
		parent = nil,
		cost = {},
	},

	-- ============
	-- MINING
	-- ============
	[ObjectNames["Pneumatic Drill"]] = {
		parent = ObjectNames["Basic Drill"],
		cost = {
			[ObjectNames.Copper] = 1000,
			[ObjectNames.Ironstone] = 800,
		},
	},
	[ObjectNames["Laser Drill"]] = {
		parent = ObjectNames["Pneumatic Drill"],
		cost = {
			[ObjectNames.Ironstone] = 3000,
			[ObjectNames.Quartz] = 2000,
			[ObjectNames.Silicon] = 1500,
		},
	},
	[ObjectNames["Mega Drill"]] = {
		parent = ObjectNames["Laser Drill"],
		cost = {
			[ObjectNames.Ironstone] = 6000,
			[ObjectNames.Quartzite] = 4000,
			[ObjectNames.Silicon] = 3000,
			[ObjectNames.Steel] = 1000,
		},
	},
	[ObjectNames["Liquid Extractor"]] = {
		parent = ObjectNames["Basic Drill"],
		cost = {
			[ObjectNames.Copper] = 800,
			[ObjectNames.Tin] = 600,
			[ObjectNames.Bronze] = 400,
		},
	},

	-- ============
	-- PROCESSING
	-- ============
	[ObjectNames["Bronze Smelter"]] = {
		parent = ObjectNames["Basic Drill"],
		cost = {
			[ObjectNames.Copper] = 1000,
			[ObjectNames.Tin] = 1000,
		},
	},
	[ObjectNames["Ironstone Forge"]] = {
		parent = ObjectNames["Bronze Smelter"],
		cost = {
			[ObjectNames.Ironstone] = 2000,
			[ObjectNames.Coal] = 1500,
			[ObjectNames.Bronze] = 1000,
		},
	},
	[ObjectNames["Graphite Press"]] = {
		parent = ObjectNames["Ironstone Forge"],
		cost = {
			[ObjectNames.Coal] = 2000,
			[ObjectNames.Ironstone] = 1500,
		},
	},
	[ObjectNames["Silicon Smelter"]] = {
		parent = ObjectNames["Graphite Press"],
		cost = {
			[ObjectNames.Coal] = 3000,
			[ObjectNames.Sand] = 2000,
			[ObjectNames.Graphite] = 1500,
		},
	},
	[ObjectNames["Quartz Press"]] = {
		parent = ObjectNames["Silicon Smelter"],
		cost = {
			[ObjectNames.Quartz] = 4000,
			[ObjectNames.Ferrocast] = 3000,
			[ObjectNames.Silicon] = 2000,
		},
	},
	[ObjectNames["Steel Manufactuary"]] = {
		parent = ObjectNames["Quartz Press"],
		cost = {
			[ObjectNames.Ferrocast] = 8000,
			[ObjectNames.Graphite] = 6000,
			[ObjectNames.Silicon] = 4000,
		},
	},
	[ObjectNames["Sand Kiln"]] = {
		parent = ObjectNames["Ironstone Forge"],
		cost = {
			[ObjectNames.Sand] = 1500,
			[ObjectNames.Copper] = 1000,
			[ObjectNames.Ironstone] = 1000,
		},
	},
	[ObjectNames["Bauxite Refinery"]] = {
		parent = ObjectNames["Sand Kiln"],
		cost = {
			[ObjectNames.Bauxite] = 2000,
			[ObjectNames.Ironstone] = 1500,
		},
	},
	[ObjectNames["Coolant Mixer"]] = {
		parent = ObjectNames["Bauxite Refinery"],
		cost = {
			[ObjectNames.Bauxite] = 3000,
			[ObjectNames.Water] = 2000,
			[ObjectNames.Aluminite] = 1500,
		},
	},
	[ObjectNames["Crude Vat"]] = {
		parent = ObjectNames["Ironstone Forge"],
		cost = {
			[ObjectNames.Coal] = 2000,
			[ObjectNames.Ironstone] = 1500,
			[ObjectNames.Glassite] = 1000,
		},
	},
	[ObjectNames["Uranium Refinery"]] = {
		parent = ObjectNames["Crude Vat"],
		cost = {
			[ObjectNames.Ironstone] = 6000,
			[ObjectNames.Quartzite] = 4000,
			[ObjectNames.Silicon] = 3000,
		},
	},

	-- ============
	-- POWER
	-- ============
	[ObjectNames["Coal Generator"]] = {
		parent = ObjectNames["Conveyor"],
		cost = {
			[ObjectNames.Copper] = 1000,
			[ObjectNames.Tin] = 800,
			[ObjectNames.Coal] = 800,
		},
	},
	[ObjectNames["Solar Panel"]] = {
		parent = ObjectNames["Coal Generator"],
		cost = {
			[ObjectNames.Silicon] = 2000,
			[ObjectNames.Glassite] = 1500,
			[ObjectNames.Copper] = 1000,
		},
	},
	[ObjectNames["Geothermal Vent"]] = {
		parent = ObjectNames["Solar Panel"],
		cost = {
			[ObjectNames.Ferrocast] = 4000,
			[ObjectNames.Silicon] = 3000,
			[ObjectNames.Glassite] = 2000,
		},
	},
	[ObjectNames["Nuclear Reactor"]] = {
		parent = ObjectNames["Geothermal Vent"],
		cost = {
			[ObjectNames.Steel] = 8000,
			[ObjectNames.Quartzite] = 6000,
			[ObjectNames.Silicon] = 4000,
			[ObjectNames.Uranium] = 2000,
		},
	},
	[ObjectNames["Safety Module"]] = {
		parent = ObjectNames["Nuclear Reactor"],
		cost = {
			[ObjectNames.Steel] = 3000,
			[ObjectNames.Quartzite] = 2000,
			[ObjectNames.Silicon] = 1500,
		},
	},
	[ObjectNames["Reinforcement Module"]] = {
		parent = ObjectNames["Nuclear Reactor"],
		cost = {
			[ObjectNames.Steel] = 4000,
			[ObjectNames.Ferrocast] = 3000,
		},
	},

	-- ============
	-- LOGISTICS
	-- ============
	[ObjectNames["Express Conveyor"]] = {
		parent = ObjectNames["Conveyor"],
		cost = {
			[ObjectNames.Copper] = 1000,
			[ObjectNames.Bronze] = 800,
		},
	},
	[ObjectNames["Reinforced Conveyor"]] = {
		parent = ObjectNames["Express Conveyor"],
		cost = {
			[ObjectNames.Ferrocast] = 2000,
			[ObjectNames.Ironstone] = 1500,
		},
	},
	[ObjectNames["Sprint Conveyor"]] = {
		parent = ObjectNames["Reinforced Conveyor"],
		cost = {
			[ObjectNames.Aluminite] = 4000,
			[ObjectNames.Silicon] = 3000,
			[ObjectNames.Glassite] = 2000,
		},
	},
	[ObjectNames["Gate Splitter"]] = {
		parent = ObjectNames["Conveyor"],
		cost = {
			[ObjectNames.Copper] = 800,
			[ObjectNames.Tin] = 600,
		},
	},
	[ObjectNames["Sieve"]] = {
		parent = ObjectNames["Gate Splitter"],
		cost = {
			[ObjectNames.Copper] = 1000,
			[ObjectNames.Bronze] = 800,
		},
	},
	[ObjectNames["Crossway"]] = {
		parent = ObjectNames["Sieve"],
		cost = {
			[ObjectNames.Bronze] = 1000,
			[ObjectNames.Copper] = 800,
		},
	},
	[ObjectNames["Span Conveyor"]] = {
		parent = ObjectNames["Conveyor"],
		cost = {
			[ObjectNames.Ferrocast] = 1500,
			[ObjectNames.Copper] = 1000,
		},
	},
	[ObjectNames["Duct"]] = {
		parent = ObjectNames["Conveyor"],
		cost = {
			[ObjectNames.Copper] = 1000,
			[ObjectNames.Tin] = 800,
		},
	},
	[ObjectNames["Conduit"]] = {
		parent = ObjectNames["Duct"],
		cost = {
			[ObjectNames.Aluminite] = 2000,
			[ObjectNames.Glassite] = 1500,
		},
	},
	[ObjectNames["Pipe Bridge"]] = {
		parent = ObjectNames["Conduit"],
		cost = {
			[ObjectNames.Ferrocast] = 2000,
			[ObjectNames.Glassite] = 1500,
		},
	},
	[ObjectNames["Manifold"]] = {
		parent = ObjectNames["Pipe Bridge"],
		cost = {
			[ObjectNames.Ferrocast] = 3000,
			[ObjectNames.Silicon] = 2000,
			[ObjectNames.Aluminite] = 1500,
		},
	},
	[ObjectNames["Haul Sled"]] = {
		parent = ObjectNames["Conveyor"],
		cost = {
			[ObjectNames.Ferrocast] = 3000,
			[ObjectNames.Silicon] = 2000,
			[ObjectNames.Graphite] = 1500,
		},
	},
	[ObjectNames["Haul Router"]] = {
		parent = ObjectNames["Haul Sled"],
		cost = {
			[ObjectNames.Ferrocast] = 4000,
			[ObjectNames.Silicon] = 3000,
			[ObjectNames.Aluminite] = 2000,
		},
	},
	[ObjectNames["Dispatch Bay"]] = {
		parent = ObjectNames["Haul Router"],
		cost = {
			[ObjectNames.Ferrocast] = 5000,
			[ObjectNames.Silicon] = 3000,
			[ObjectNames.Aluminite] = 2000,
		},
	},

	-- ============
	-- DEFENSE — TURRETS
	-- ============
	[ObjectNames["Flak Turret"]] = {
		parent = ObjectNames["Cannon"],
		cost = {
			[ObjectNames.Copper] = 1500,
			[ObjectNames.Bronze] = 1000,
			[ObjectNames.Tin] = 800,
		},
	},
	[ObjectNames["Railgun"]] = {
		parent = ObjectNames["Flak Turret"],
		cost = {
			[ObjectNames.Aluminite] = 5000,
			[ObjectNames.Silicon] = 4000,
			[ObjectNames.Quartzite] = 3000,
		},
	},
	[ObjectNames["Howitzer"]] = {
		parent = ObjectNames["Cannon"],
		cost = {
			[ObjectNames.Ferrocast] = 2000,
			[ObjectNames.Bronze] = 1500,
			[ObjectNames.Coal] = 1000,
		},
	},
	[ObjectNames["Mortar"]] = {
		parent = ObjectNames["Howitzer"],
		cost = {
			[ObjectNames.Ferrocast] = 3000,
			[ObjectNames.Silicon] = 2000,
			[ObjectNames.Graphite] = 1500,
		},
	},
	[ObjectNames["Sniper"]] = {
		parent = ObjectNames["Cannon"],
		cost = {
			[ObjectNames.Ferrocast] = 3000,
			[ObjectNames.Silicon] = 2000,
			[ObjectNames.Quartzite] = 1500,
		},
	},
	[ObjectNames["Laser Cannon"]] = {
		parent = ObjectNames["Sniper"],
		cost = {
			[ObjectNames.Quartzite] = 8000,
			[ObjectNames.Silicon] = 6000,
			[ObjectNames.Steel] = 4000,
		},
	},
	[ObjectNames["Flamethrower"]] = {
		parent = ObjectNames["Cannon"],
		cost = {
			[ObjectNames.Ferrocast] = 2000,
			[ObjectNames.Crude] = 1500,
			[ObjectNames.Coal] = 1000,
		},
	},
	[ObjectNames["Tesla Tower"]] = {
		parent = ObjectNames["Flamethrower"],
		cost = {
			[ObjectNames.Silicon] = 5000,
			[ObjectNames.Quartzite] = 4000,
			[ObjectNames.Aluminite] = 3000,
		},
	},

	-- ============
	-- DEFENSE — WALLS
	-- ============
	[ObjectNames["Ironstone Wall"]] = {
		parent = ObjectNames["Cannon"],
		cost = {
			[ObjectNames.Ironstone] = 1000,
			[ObjectNames.Copper] = 800,
		},
	},
	[ObjectNames["Ferrocast Wall"]] = {
		parent = ObjectNames["Ironstone Wall"],
		cost = {
			[ObjectNames.Ferrocast] = 2000,
			[ObjectNames.Ironstone] = 1500,
		},
	},
	[ObjectNames["Quartzite Wall"]] = {
		parent = ObjectNames["Ferrocast Wall"],
		cost = {
			[ObjectNames.Quartzite] = 4000,
			[ObjectNames.Ferrocast] = 3000,
		},
	},
	[ObjectNames["Steel Wall"]] = {
		parent = ObjectNames["Quartzite Wall"],
		cost = {
			[ObjectNames.Steel] = 8000,
			[ObjectNames.Quartzite] = 6000,
		},
	},

	-- ============
	-- UNIT FACTORIES
	-- ============
	[ObjectNames["Tank Factory Basic"]] = {
		parent = ObjectNames["Cannon"],
		cost = {
			[ObjectNames.Ferrocast] = 2000,
			[ObjectNames.Bronze] = 1500,
			[ObjectNames.Silicon] = 1000,
		},
	},
	[ObjectNames["Basic Tank"]] = {
		parent = ObjectNames["Tank Factory Basic"],
		cost = {
			[ObjectNames.Ferrocast] = 1000,
			[ObjectNames.Silicon] = 800,
			[ObjectNames.Bronze] = 600,
		},
	},
	[ObjectNames["Light Tank"]] = {
		parent = ObjectNames["Basic Tank"],
		cost = {
			[ObjectNames.Ferrocast] = 1500,
			[ObjectNames.Silicon] = 1000,
			[ObjectNames.Aluminite] = 800,
		},
	},
	[ObjectNames["Basic Heavy Tank"]] = {
		parent = ObjectNames["Basic Tank"],
		cost = {
			[ObjectNames.Ferrocast] = 2000,
			[ObjectNames.Silicon] = 1500,
			[ObjectNames.Graphite] = 1000,
		},
	},
	[ObjectNames["Tank Factory Advanced"]] = {
		parent = ObjectNames["Tank Factory Basic"],
		cost = {
			[ObjectNames.Ferrocast] = 6000,
			[ObjectNames.Quartzite] = 5000,
			[ObjectNames.Silicon] = 4000,
			[ObjectNames.Steel] = 2000,
		},
	},
	[ObjectNames["Super Heavy Tank"]] = {
		parent = ObjectNames["Tank Factory Advanced"],
		cost = {
			[ObjectNames.Ferrocast] = 6000,
			[ObjectNames.Steel] = 5000,
			[ObjectNames.Silicon] = 4000,
		},
	},
	[ObjectNames["Sniper Tank"]] = {
		parent = ObjectNames["Tank Factory Advanced"],
		cost = {
			[ObjectNames.Quartzite] = 5000,
			[ObjectNames.Silicon] = 4000,
			[ObjectNames.Aluminite] = 3000,
		},
	},
	[ObjectNames["Howitzer Tank"]] = {
		parent = ObjectNames["Tank Factory Advanced"],
		cost = {
			[ObjectNames.Ferrocast] = 5000,
			[ObjectNames.Quartzite] = 4000,
			[ObjectNames.Silicon] = 3000,
		},
	},
	[ObjectNames["Drone Factory Basic"]] = {
		parent = ObjectNames["Cannon"],
		cost = {
			[ObjectNames.Aluminite] = 2000,
			[ObjectNames.Silicon] = 1500,
			[ObjectNames.Bronze] = 1000,
		},
	},
	[ObjectNames["Basic Drone"]] = {
		parent = ObjectNames["Drone Factory Basic"],
		cost = {
			[ObjectNames.Aluminite] = 1000,
			[ObjectNames.Silicon] = 800,
			[ObjectNames.Bronze] = 600,
		},
	},
	[ObjectNames["Bomber Drone"]] = {
		parent = ObjectNames["Basic Drone"],
		cost = {
			[ObjectNames.Aluminite] = 1500,
			[ObjectNames.Silicon] = 1000,
			[ObjectNames.Coal] = 800,
		},
	},
	[ObjectNames["Kamikaze Drone"]] = {
		parent = ObjectNames["Basic Drone"],
		cost = {
			[ObjectNames.Aluminite] = 1000,
			[ObjectNames.Coal] = 800,
			[ObjectNames.Bronze] = 600,
		},
	},
	[ObjectNames["Drone Factory Advanced"]] = {
		parent = ObjectNames["Drone Factory Basic"],
		cost = {
			[ObjectNames.Aluminite] = 6000,
			[ObjectNames.Quartzite] = 5000,
			[ObjectNames.Silicon] = 4000,
			[ObjectNames.Steel] = 2000,
		},
	},
	[ObjectNames["Gunship"]] = {
		parent = ObjectNames["Drone Factory Advanced"],
		cost = {
			[ObjectNames.Aluminite] = 6000,
			[ObjectNames.Quartzite] = 5000,
			[ObjectNames.Silicon] = 4000,
		},
	},
	[ObjectNames["AA Drone"]] = {
		parent = ObjectNames["Drone Factory Advanced"],
		cost = {
			[ObjectNames.Aluminite] = 5000,
			[ObjectNames.Quartzite] = 4000,
			[ObjectNames.Silicon] = 3000,
		},
	},
	[ObjectNames["Stealth Drone"]] = {
		parent = ObjectNames["Drone Factory Advanced"],
		cost = {
			[ObjectNames.Quartzite] = 5000,
			[ObjectNames.Silicon] = 4000,
			[ObjectNames.Aluminite] = 3000,
		},
	},
	[ObjectNames["Support Factory Basic"]] = {
		parent = ObjectNames["Cannon"],
		cost = {
			[ObjectNames.Ferrocast] = 2000,
			[ObjectNames.Aluminite] = 1500,
			[ObjectNames.Silicon] = 1000,
		},
	},
	[ObjectNames["Artillery Walker"]] = {
		parent = ObjectNames["Support Factory Basic"],
		cost = {
			[ObjectNames.Ferrocast] = 1500,
			[ObjectNames.Silicon] = 1000,
			[ObjectNames.Bronze] = 800,
		},
	},
	[ObjectNames["AA Crawler"]] = {
		parent = ObjectNames["Artillery Walker"],
		cost = {
			[ObjectNames.Aluminite] = 2000,
			[ObjectNames.Silicon] = 1500,
			[ObjectNames.Bronze] = 1000,
		},
	},
	[ObjectNames["Medic Walker"]] = {
		parent = ObjectNames["AA Crawler"],
		cost = {
			[ObjectNames.Ferrocast] = 2000,
			[ObjectNames.Silicon] = 1500,
			[ObjectNames.Aluminite] = 1000,
		},
	},
	[ObjectNames["Support Factory Advanced"]] = {
		parent = ObjectNames["Support Factory Basic"],
		cost = {
			[ObjectNames.Quartzite] = 6000,
			[ObjectNames.Aluminite] = 5000,
			[ObjectNames.Silicon] = 4000,
			[ObjectNames.Steel] = 2000,
		},
	},
	[ObjectNames["Projectile Interceptor"]] = {
		parent = ObjectNames["Support Factory Advanced"],
		cost = {
			[ObjectNames.Aluminite] = 5000,
			[ObjectNames.Quartzite] = 4000,
			[ObjectNames.Silicon] = 3000,
		},
	},
	[ObjectNames["Kamikaze Drone Manufacturer"]] = {
		parent = ObjectNames["Support Factory Advanced"],
		cost = {
			[ObjectNames.Ferrocast] = 4000,
			[ObjectNames.Quartzite] = 3000,
			[ObjectNames.Coal] = 2000,
		},
	},
	[ObjectNames["Commander"]] = {
		parent = ObjectNames["Support Factory Advanced"],
		cost = {
			[ObjectNames.Quartzite] = 8000,
			[ObjectNames.Silicon] = 6000,
			[ObjectNames.Aluminite] = 4000,
			[ObjectNames.Steel] = 2000,
		},
	},

	-- ============
	-- CORE
	-- ============
	[ObjectNames["Vault"]] = {
		parent = ObjectNames["Core Shard"],
		cost = {
			[ObjectNames.Copper] = 1000,
			[ObjectNames.Ironstone] = 800,
			[ObjectNames.Bronze] = 800,
		},
	},
	[ObjectNames["Crate"]] = {
		parent = ObjectNames["Vault"],
		cost = {
			[ObjectNames.Copper] = 800,
			[ObjectNames.Bronze] = 600,
		},
	},
	[ObjectNames["Liquid Tank"]] = {
		parent = ObjectNames["Vault"],
		cost = {
			[ObjectNames.Ferrocast] = 1500,
			[ObjectNames.Glassite] = 1000,
		},
	},
	[ObjectNames["Core Bastion"]] = {
		parent = ObjectNames["Core Shard"],
		cost = {
			[ObjectNames.Ferrocast] = 5000,
			[ObjectNames.Silicon] = 4000,
			[ObjectNames.Quartzite] = 3000,
		},
	},
	[ObjectNames["Mend Point"]] = {
		parent = ObjectNames["Core Bastion"],
		cost = {
			[ObjectNames.Ferrocast] = 2000,
			[ObjectNames.Silicon] = 1500,
			[ObjectNames.Bronze] = 1000,
		},
	},
	[ObjectNames["Mend Tower"]] = {
		parent = ObjectNames["Mend Point"],
		cost = {
			[ObjectNames.Ferrocast] = 4000,
			[ObjectNames.Silicon] = 3000,
			[ObjectNames.Quartzite] = 2000,
		},
	},
	[ObjectNames["Mending Pulsator"]] = {
		parent = ObjectNames["Mend Point"],
		cost = {
			[ObjectNames.Ferrocast] = 3000,
			[ObjectNames.Silicon] = 2000,
			[ObjectNames.Glassite] = 1500,
		},
	},
	[ObjectNames["Core Citadel"]] = {
		parent = ObjectNames["Core Bastion"],
		cost = {
			[ObjectNames.Steel] = 10000,
			[ObjectNames.Quartzite] = 8000,
			[ObjectNames.Silicon] = 6000,
			[ObjectNames.Aluminite] = 4000,
		},
	},
}

-- ============================================================
-- PUBLIC METHODS
-- ============================================================

-- Check if a node exists
function ResearchTree.NodeExists(nodeId)
	return Nodes[nodeId] ~= nil
end

-- Get the parent of a node (nil if root)
function ResearchTree.GetParent(nodeId)
	local node = Nodes[nodeId]
	if not node then
		warn("ResearchTree.GetParent: node not found ->", nodeId)
		return nil
	end
	return node.parent
end

-- Get the cost table of a node
function ResearchTree.GetCost(nodeId)
	local node = Nodes[nodeId]
	if not node then
		warn("ResearchTree.GetCost: node not found ->", nodeId)
		return nil
	end
	return node.cost
end

-- Get full dependency chain up to root as an ordered list
-- returns { "Basic Drill", "Pneumatic Drill", "Laser Drill" } etc
function ResearchTree.GetDependencyChain(nodeId)
	local chain = {}
	local current = nodeId

	while current ~= nil do
		local node = Nodes[current]
		if not node then
			warn("ResearchTree.GetDependencyChain: broken chain at ->", current)
			break
		end
		table.insert(chain, 1, current)
		current = node.parent
	end

	return chain
end

-- Get all direct children of a node
function ResearchTree.GetChildren(nodeId)
	local children = {}
	for id, node in pairs(Nodes) do
		if node.parent == nodeId then
			table.insert(children, id)
		end
	end
	return children
end

-- Check if a node is a root node (no parent, unlocked by default)
function ResearchTree.IsRoot(nodeId)
	local node = Nodes[nodeId]
	if not node then
		warn("ResearchTree.IsRoot: node not found ->", nodeId)
		return false
	end
	return node.parent == nil
end

-- Check if a player can unlock a node given their unlocked set
-- unlockedSet = { ["Basic Drill"] = true, ... }
function ResearchTree.CanUnlock(nodeId, unlockedSet)
	local node = Nodes[nodeId]
	if not node then
		warn("ResearchTree.CanUnlock: node not found ->", nodeId)
		return false
	end

	-- already unlocked
	if unlockedSet[nodeId] then
		return false
	end

	-- root nodes are always unlockable
	if node.parent == nil then
		return true
	end

	-- parent must be unlocked
	return unlockedSet[node.parent] == true
end

-- Check if a player can afford a node given their resource bank
-- resourceBank = { ["Copper"] = 5000, ... }
function ResearchTree.CanAfford(nodeId, resourceBank)
	local node = Nodes[nodeId]
	if not node then
		warn("ResearchTree.CanAfford: node not found ->", nodeId)
		return false
	end

	for resource, amount in pairs(node.cost) do
		if (resourceBank[resource] or 0) < amount then
			return false
		end
	end

	return true
end

-- Deduct research cost from resource bank (modifies in place)
-- returns true on success, false if cant afford
function ResearchTree.DeductCost(nodeId, resourceBank)
	if not ResearchTree.CanAfford(nodeId, resourceBank) then
		return false
	end

	local node = Nodes[nodeId]
	for resource, amount in pairs(node.cost) do
		resourceBank[resource] = (resourceBank[resource] or 0) - amount
	end

	return true
end

-- Get all nodes as a flat list (useful for UI)
function ResearchTree.GetAllNodes()
	local list = {}
	for id, node in pairs(Nodes) do
		table.insert(list, {
			id = id,
			parent = node.parent,
			cost = node.cost,
		})
	end
	return list
end

return ResearchTree
