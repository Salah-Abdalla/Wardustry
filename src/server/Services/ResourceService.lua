-- ResourceService
-- Knit Service — source of truth for all team resources
-- Place in ServerScriptService/Services

local Knit = require(game:GetService("ReplicatedStorage").Packages.Knit)

local ResourceService = Knit.CreateService({
	Name = "ResourceService",
	Client = {
		ResourceChanged = Knit.CreateSignal(), -- fires to clients: (team, resource, newAmount)
	},
})

-- ── Internal storage ──
-- _resources[team] = { Copper = 0, Tin = 0, ... }
local _resources = {}

local VALID_RESOURCES = {
	"Bronze",
	"Ferrocast",
	"Aluminite",
	"Glassite",
	"Graphite",
	"Quartzite",
	"Silicon",
	"Steel",
	"Coolant",
	"Crude",
	"Refined Uranium",
	"Pyro Charge",
}

-- ── Signals ──
-- Server-side signals other services can connect to
ResourceService.ResourceAdded = Instance.new("BindableEvent") -- (team, resource, amount, newTotal)
ResourceService.ResourceDeducted = Instance.new("BindableEvent") -- (team, resource, amount, newTotal)

-- ════════════════════════════════════════
--  INTERNAL
-- ════════════════════════════════════════

local function EnsureTeam(team)
	if not _resources[team] then
		_resources[team] = {}
		for _, r in ipairs(VALID_RESOURCES) do
			_resources[team][r] = 0
		end
	end
end

local function FireChanged(team, resource, newAmount)
	ResourceService.Client.ResourceChanged:FireAll(team, resource, newAmount)
end

-- ════════════════════════════════════════
--  PUBLIC API
-- ════════════════════════════════════════

-- Initialize a team with a starting resource table
-- startingResources = { Copper = 500, Tin = 200, ... }
function ResourceService:InitTeam(team, startingResources)
	EnsureTeam(team)
	if startingResources then
		for resource, amount in pairs(startingResources) do
			_resources[team][resource] = math.max(0, amount)
			FireChanged(team, resource, _resources[team][resource])
		end
	end
	print(string.format("[ResourceService] Initialized team '%s'", tostring(team)))
end

-- Add resources to a team
function ResourceService:Add(team, resource, amount)
	EnsureTeam(team)
	if not _resources[team][resource] then
		warn("[ResourceService] Unknown resource: " .. tostring(resource))
		return
	end
	amount = math.max(0, amount)
	_resources[team][resource] += amount
	local newTotal = _resources[team][resource]
	ResourceService.ResourceAdded:Fire(team, resource, amount, newTotal)
	FireChanged(team, resource, newTotal)
end

-- Deduct resources from a team
-- Returns true on success, false if insufficient funds
function ResourceService:Deduct(team, resource, amount)
	EnsureTeam(team)
	if not _resources[team][resource] then
		warn("[ResourceService] Unknown resource: " .. tostring(resource))
		return false
	end
	amount = math.max(0, amount)
	if _resources[team][resource] < amount then
		return false
	end
	_resources[team][resource] -= amount
	local newTotal = _resources[team][resource]
	ResourceService.ResourceDeducted:Fire(team, resource, amount, newTotal)
	FireChanged(team, resource, newTotal)
	return true
end

-- Get a single resource amount
function ResourceService:Get(team, resource)
	EnsureTeam(team)
	return _resources[team][resource] or 0
end

-- Get all resources for a team
function ResourceService:GetAll(team)
	EnsureTeam(team)
	local copy = {}
	for k, v in pairs(_resources[team]) do
		copy[k] = v
	end
	return copy
end

-- Check if a team can afford a cost table
-- costs = { Copper = 50, Tin = 20 }
function ResourceService:CanAfford(team, costs)
	EnsureTeam(team)
	for resource, amount in pairs(costs) do
		if (_resources[team][resource] or 0) < amount then
			return false
		end
	end
	return true
end

-- Deduct an entire cost table atomically — only deducts if fully affordable
-- Returns true on success, false if insufficient
function ResourceService:Purchase(team, costs)
	if not self:CanAfford(team, costs) then
		return false
	end
	for resource, amount in pairs(costs) do
		self:Deduct(team, resource, amount)
	end
	return true
end

-- ── Client API ──
-- Clients can request their own team's resources (server validates ownership)
function ResourceService.Client:GetMyResources(player)
	-- You'll need a way to get a player's team — hook into your team system here
	-- Placeholder: return empty until team assignment is wired
	local team = player.Team -- adjust to your team lookup
	if not team then
		return {}
	end
	return ResourceService:GetAll(team)
end

-- ════════════════════════════════════════
--  LIFECYCLE
-- ════════════════════════════════════════

function ResourceService:KnitStart()
	print("[ResourceService] Started")
end

function ResourceService:KnitInit() end

return ResourceService
