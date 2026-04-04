-- BuildingService
-- Knit Service — handles placement requests, validation, spawning, and demolition
-- Place in ServerScriptService/Services

local Knit = require(game:GetService("ReplicatedStorage").Packages.Knit)
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Teams = game:GetService("Teams")

local BuildingConfig = require(ReplicatedStorage.Config.BuildingConfig)

local FLOOR_Y = 0.5 -- top of the sector floor part
local TILE_SIZE = 4

local BuildingService = Knit.CreateService({
	Name = "BuildingService",
	Client = {
		PlacementResult = Knit.CreateSignal(), -- (success: bool, message: string) fires to placing player
	},
})

-- tracks placed buildings: model → { BuildingName, Team, GridX, GridZ, SizeX, SizeZ }
local _placed = {}

local GridService
local ResourceService
local StructureService
local TeamService

-- ════════════════════════════════════════
--  INTERNAL
-- ════════════════════════════════════════

local function GetBuildingY(model)
	-- sit the model so its bottom face is at FLOOR_Y
	local size = model:GetExtentsSize()
	return FLOOR_Y + size.Y / 2
end

local function SpawnModel(buildingName, worldPos, rotationY)
	local folder = ReplicatedStorage:FindFirstChild("Buildings")
	local template = folder and folder:FindFirstChild(buildingName)

	if template then
		local model = template:Clone()
		local y = GetBuildingY(model)
		model:PivotTo(CFrame.new(worldPos.X, y, worldPos.Z) * CFrame.Angles(0, math.rad(rotationY or 0), 0))
		model.Parent = workspace
		return model
	else
		-- fallback: plain basepart sized from config
		local configSize = BuildingConfig.GetSize(buildingName)
		local sizeX = (configSize and configSize.X or 1) * TILE_SIZE
		local sizeZ = (configSize and configSize.Z or 1) * TILE_SIZE
		local sizeY = TILE_SIZE -- default height

		local part = Instance.new("Part")
		part.Name = buildingName
		part.Size = Vector3.new(sizeX, sizeY, sizeZ)
		part.Position = Vector3.new(worldPos.X, FLOOR_Y + sizeY / 2, worldPos.Z)
		part.Anchored = true
		part.Color = Color3.fromHex("888888")
		part.Material = Enum.Material.SmoothPlastic
		part.Parent = workspace

		-- wrap in a model so StructureService always gets a Model
		local model = Instance.new("Model")
		model.Name = buildingName
		model.PrimaryPart = part
		part.Parent = model
		model.Parent = workspace
		return model
	end
end

local function Validate(player, buildingName, gridOrigin, sizeX, sizeZ)
	if not BuildingConfig.Exists(buildingName) then
		return false, "Unknown building: " .. buildingName
	end

	local team = TeamService:GetPlayerTeam(player)
	if not team then
		return false, "You are not on a team."
	end

	if not GridService:CanPlace(gridOrigin.X, gridOrigin.Z, sizeX, sizeZ) then
		return false, "Cannot place here — space is occupied or out of bounds."
	end

	local cost = BuildingConfig.GetCost(buildingName)
	if cost then
		-- debug: print what the team has vs what is needed
		print("[BuildingService] Team:", team)
		print("[BuildingService] Cost:", cost)
		print("[BuildingService] Resources:", ResourceService:GetAll(team))

		if not ResourceService:CanAfford(team, cost) then
			return false, "Insufficient resources."
		end
	end

	return true, team
end

-- ════════════════════════════════════════
--  PUBLIC API
-- ════════════════════════════════════════

-- Main placement entry point — called by the client RemoteFunction
-- request = { BuildingName, WorldPosition, Rotation }
function BuildingService:PlaceBuilding(player, request)
	local buildingName = request.BuildingName
	local worldPos = request.WorldPosition
	local rotationY = request.Rotation or 0

	-- get size from config
	local configSize = BuildingConfig.GetSize(buildingName)
	local sizeX = configSize and configSize.X or 1
	local sizeZ = configSize and configSize.Z or 1

	-- snap world position and find grid origin
	local snapped = GridService:GetSnappedWorldPos(worldPos, sizeX, sizeZ)
	local gridOrigin = GridService:GetGridOrigin(snapped, sizeX, sizeZ)

	-- validate
	local ok, result = Validate(player, buildingName, gridOrigin, sizeX, sizeZ)
	if not ok then
		BuildingService.Client.PlacementResult:Fire(player, false, result)
		return
	end

	local team = result

	-- deduct cost
	local cost = BuildingConfig.GetCost(buildingName)
	if cost then
		ResourceService:Purchase(team, cost)
	end

	-- spawn model
	local model = SpawnModel(buildingName, snapped, rotationY)

	-- mark grid tiles as occupied
	GridService:SetBuilding(gridOrigin.X, gridOrigin.Z, sizeX, sizeZ, buildingName)

	-- register with StructureService
	StructureService:Register(model, buildingName, team)

	-- track internally
	_placed[model] = {
		BuildingName = buildingName,
		Team = team,
		GridX = gridOrigin.X,
		GridZ = gridOrigin.Z,
		SizeX = sizeX,
		SizeZ = sizeZ,
	}

	-- notify placing player
	BuildingService.Client.PlacementResult:Fire(player, true, "Placed " .. buildingName)

	print(
		string.format(
			"[BuildingService] %s placed '%s' at grid (%d,%d) for team %s",
			player.Name,
			buildingName,
			gridOrigin.X,
			gridOrigin.Z,
			team
		)
	)
end

-- Demolish a building by its model — to be expanded later
function BuildingService:DemolishBuilding(model)
	local data = _placed[model]
	if not data then
		warn("[BuildingService] DemolishBuilding: model not tracked")
		return
	end

	-- clear grid tiles
	GridService:ClearBuilding(data.GridX, data.GridZ, data.SizeX, data.SizeZ)

	-- unregister from StructureService (no destruction event — player chose to remove it)
	StructureService:Unregister(model)

	-- remove from tracking
	_placed[model] = nil

	-- destroy model
	if model and model.Parent then
		model:Destroy()
	end

	-- TODO: resource refund logic here
end

-- Get placement data for a model
function BuildingService:GetPlacementData(model)
	return _placed[model]
end

-- ── Client API ──
function BuildingService.Client:PlaceBuilding(player, request)
	BuildingService:PlaceBuilding(player, request)
end

-- Bulk placement — processes each request in order, skips invalid ones
-- Returns a results array: { { success=bool, message=string } }
function BuildingService:PlaceBulk(player, requests)
	if type(requests) ~= "table" then
		warn("[BuildingService] PlaceBulk: invalid requests table")
		return
	end
	local results = {}
	for _, request in ipairs(requests) do
		local ok, msg = pcall(function()
			BuildingService:PlaceBuilding(player, request)
		end)
		table.insert(results, { success = ok, message = ok and "OK" or tostring(msg) })
	end
	return results
end

function BuildingService.Client:PlaceBulk(player, requests)
	return BuildingService:PlaceBulk(player, requests)
end

-- ════════════════════════════════════════
--  LIFECYCLE
-- ════════════════════════════════════════

-- clean up when a structure is destroyed by damage (not demolition)
local function OnStructureDestroyed(structureObj)
	local model = structureObj.Model
	local data = _placed[model]
	if not data then
		return
	end

	GridService:ClearBuilding(data.GridX, data.GridZ, data.SizeX, data.SizeZ)
	_placed[model] = nil
end

function BuildingService:KnitInit()
	GridService = Knit.GetService("GridService")
	ResourceService = Knit.GetService("ResourceService")
	StructureService = Knit.GetService("StructureService")
	TeamService = Knit.GetService("TeamService")
end

function BuildingService:KnitStart()
	StructureService.StructureDestroyed.Event:Connect(OnStructureDestroyed)
	print("[BuildingService] Started")
end

return BuildingService
