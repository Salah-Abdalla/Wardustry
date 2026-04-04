-- StructureService
-- Knit Service — runtime state for all placed structures (HP, armor, damage, destruction)
-- Place in ServerScriptService/Services

local Knit = require(game:GetService("ReplicatedStorage").Packages.Knit)

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

local TeamService = require(ServerScriptService.Services.TeamService)
local BuildingConfig = require(ReplicatedStorage.Config.BuildingConfig)
local Categories = require(ReplicatedStorage.Dictionaries.Categories)
local ObjectNames = require(ReplicatedStorage.Dictionaries.ObjectNames)

local StructureService = Knit.CreateService({
	Name = "StructureService",
	Client = {
		StructureDamaged = Knit.CreateSignal(), -- (model, currentHP, maxHP)
		StructureDestroyed = Knit.CreateSignal(), -- (model, team, type)
	},
})

-- ── Internal storage ──
-- _structures[model] = {
--     Name   = string,
--     Model  = Model,
--     Team   = string,
--     Type   = string,
--     HP     = number,
--     MaxHP  = number,
--     Armor  = number,
-- }
local _structures = {}

-- Server-side signals
StructureService.StructureDamaged = Instance.new("BindableEvent") -- (structureObj, currentHP, maxHP)
StructureService.StructureDestroyed = Instance.new("BindableEvent") -- (structureObj)

-- ════════════════════════════════════════
--  INTERNAL
-- ════════════════════════════════════════

-- Percent-based armor damage formula
-- Higher armor = more damage reduced, but never fully negates
local function ApplyArmor(damage, armor)
	return damage * (100 / (100 + armor))
end

local function GetType(structureName)
	local objectName = ObjectNames[structureName]
	if not objectName then
		warn("[StructureService] No ObjectName found for: " .. tostring(structureName))
		return "Unknown"
	end
	local category = BuildingConfig.GetCategory(objectName)
	if not category then
		warn("[StructureService] No category found for: " .. tostring(objectName))
		return "Unknown"
	end
	return Categories[category] or "Unknown"
end

-- ════════════════════════════════════════
--  PUBLIC API
-- ════════════════════════════════════════

-- Register a structure into the service
-- model: the Model instance in workspace
-- structureName: key used to look up BuildingConfig
-- team: teamColor string from TeamService
function StructureService:Register(model, structureName, team)
	if _structures[model] then
		warn("[StructureService] Structure already registered: " .. tostring(model))
		return nil
	end

	local maxHP = BuildingConfig.GetHP(structureName)
	local armor = BuildingConfig.GetArmor(structureName)

	if not maxHP then
		warn("[StructureService] No HP config for: " .. tostring(structureName))
		return nil
	end

	local structureObj = {
		Name = structureName,
		Model = model,
		Team = team,
		Type = GetType(structureName),
		HP = maxHP,
		MaxHP = maxHP,
		Armor = armor or 0,
	}

	TeamService:AddStructureToTeam(structureObj, team)

	_structures[model] = structureObj
	print(
		string.format(
			"[StructureService] Registered '%s' (Team: %s, HP: %d, Armor: %d)",
			structureName,
			team,
			maxHP,
			armor or 0
		)
	)

	return structureObj
end

-- Deal damage to a structure by its model
-- Returns remaining HP, or nil if structure not found
function StructureService:Damage(model, rawDamage)
	local structureObj = _structures[model]
	if not structureObj then
		warn("[StructureService] Damage called on unregistered model: " .. tostring(model))
		return nil
	end
	if structureObj.HP <= 0 then
		return 0
	end

	local actualDamage = math.max(1, math.floor(ApplyArmor(rawDamage, structureObj.Armor)))
	structureObj.HP = math.max(0, structureObj.HP - actualDamage)

	-- fire damage signals
	StructureService.StructureDamaged:Fire(structureObj, structureObj.HP, structureObj.MaxHP)
	StructureService.Client.StructureDamaged:FireAll(model, structureObj.HP, structureObj.MaxHP)

	if structureObj.HP <= 0 then
		self:_Destroy(structureObj)
	end

	return structureObj.HP
end

-- Repair a structure — to be filled in later
function StructureService:Repair(model, amount)
	-- TODO: implement repair logic
end

-- Get a structure object from its model
function StructureService:GetStructureFromModel(model)
	return _structures[model]
end

-- Get all structures belonging to a team
function StructureService:GetStructuresForTeam(team)
	local list = {}
	for _, structureObj in pairs(_structures) do
		if structureObj.Team == team then
			table.insert(list, structureObj)
		end
	end
	return list
end

-- Get all structures of a specific type
function StructureService:GetStructuresOfType(structureType)
	local list = {}
	for _, structureObj in pairs(_structures) do
		if structureObj.Type == structureType then
			table.insert(list, structureObj)
		end
	end
	return list
end

-- Unregister a structure without destroying it (e.g. manually removed by BuildingService)
function StructureService:Unregister(model)
	if not _structures[model] then
		return
	end
	_structures[model] = nil
end

-- ════════════════════════════════════════
--  INTERNAL DESTRUCTION
-- ════════════════════════════════════════

function StructureService:_Destroy(structureObj)
	local model = structureObj.Model

	-- fire before destroying so listeners can read the object
	StructureService.StructureDestroyed:Fire(structureObj)
	StructureService.Client.StructureDestroyed:FireAll(model, structureObj.Team, structureObj.Type)

	-- remove from registry
	_structures[model] = nil

	-- destroy the model
	if model and model.Parent then
		model:Destroy()
	end

	print(string.format("[StructureService] Destroyed '%s' (Team: %s)", structureObj.Name, structureObj.Team))
end

-- ════════════════════════════════════════
--  LIFECYCLE
-- ════════════════════════════════════════

function StructureService:KnitInit() end

function StructureService:KnitStart()
	print("[StructureService] Started")
end

return StructureService
