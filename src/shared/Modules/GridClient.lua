-- GridClient
-- Client-side mirror of the server grid, read-only
-- Place in ReplicatedStorage or StarterPlayerScripts
-- Require this wherever you need local grid queries (BuildingController, placement preview, etc.)

local Knit = require(game:GetService("ReplicatedStorage").Packages.Knit)

local TILE_SIZE = 4

local GridClient = {}

-- ── Local grid mirror ──
local _grid = {} -- [x][z] = tileData
local _sizeX = nil
local _sizeZ = nil
local _ready = false

-- ============================================================
-- INTERNAL
-- ============================================================

local function ApplyTile(x, z, tileData)
	if not _grid[x] then
		_grid[x] = {}
	end
	_grid[x][z] = tileData
end

local function ApplySnapshot(snapshot)
	_grid = {}
	_sizeX = snapshot.SizeX
	_sizeZ = snapshot.SizeZ
	for x, col in pairs(snapshot.Tiles or {}) do
		_grid[x] = {}
		for z, tile in pairs(col) do
			_grid[x][z] = tile
		end
	end
	_ready = true
end

local function InBounds(x, z)
	if not _sizeX or not _sizeZ then
		return false
	end
	return x >= 0 and x < _sizeX and z >= 0 and z < _sizeZ
end

-- ============================================================
-- COORDINATE HELPERS  (mirrors GridService, client-side)
-- ============================================================

function GridClient.WorldToGrid(worldPos)
	return {
		X = math.round(worldPos.X / TILE_SIZE),
		Z = math.round(worldPos.Z / TILE_SIZE),
	}
end

function GridClient.GridToWorld(gridX, gridZ)
	return Vector3.new(gridX * TILE_SIZE, 0, gridZ * TILE_SIZE)
end

function GridClient.GetSnappedWorldPos(worldPos, sizeX, sizeZ)
	local gridX = math.round(worldPos.X / TILE_SIZE)
	local gridZ = math.round(worldPos.Z / TILE_SIZE)

	local snappedX = gridX * TILE_SIZE
	local snappedZ = gridZ * TILE_SIZE

	if sizeX % 2 == 0 then
		snappedX = snappedX + TILE_SIZE / 2
	end
	if sizeZ % 2 == 0 then
		snappedZ = snappedZ + TILE_SIZE / 2
	end

	return Vector3.new(snappedX, 0, snappedZ)
end

function GridClient.GetGridOrigin(snappedWorldPos, sizeX, sizeZ)
	local originX = snappedWorldPos.X - (sizeX * TILE_SIZE) / 2
	local originZ = snappedWorldPos.Z - (sizeZ * TILE_SIZE) / 2
	return {
		X = math.round(originX / TILE_SIZE),
		Z = math.round(originZ / TILE_SIZE),
	}
end

-- ============================================================
-- TILE READ
-- ============================================================

function GridClient.IsReady()
	return _ready
end

function GridClient.GetSize()
	return { X = _sizeX, Z = _sizeZ }
end

function GridClient.IsInBounds(x, z)
	return InBounds(x, z)
end

function GridClient.GetTile(x, z)
	if not InBounds(x, z) then
		return nil
	end
	if not _grid[x] then
		return nil
	end
	return _grid[x][z]
end

function GridClient.IsOccupied(x, z)
	local tile = GridClient.GetTile(x, z)
	if not tile then
		return false
	end
	return tile.Building ~= nil or tile.IsObstruction
end

function GridClient.IsObstruction(x, z)
	local tile = GridClient.GetTile(x, z)
	if not tile then
		return false
	end
	return tile.IsObstruction
end

function GridClient.GetBuilding(x, z)
	local tile = GridClient.GetTile(x, z)
	if not tile then
		return nil
	end
	return tile.Building
end

function GridClient.GetOre(x, z)
	local tile = GridClient.GetTile(x, z)
	if not tile then
		return nil
	end
	return tile.OreId
end

function GridClient.GetSpecialTile(x, z)
	local tile = GridClient.GetTile(x, z)
	if not tile then
		return nil
	end
	return tile.SpecialTile
end

-- ============================================================
-- VALIDATION
-- ============================================================

-- Main placement validation used by BuildingController for ghost preview
-- worldPos: Vector3 mouse hit position
-- modelSize: { X = tileCountX, Z = tileCountZ }
function GridClient.IsValidPosition(worldPos, modelSize)
	if not _ready then
		return false
	end

	local sizeX = modelSize.X
	local sizeZ = modelSize.Z

	local snapped = GridClient.GetSnappedWorldPos(worldPos, sizeX, sizeZ)
	local gridOrigin = GridClient.GetGridOrigin(snapped, sizeX, sizeZ)

	for x = gridOrigin.X, gridOrigin.X + sizeX - 1 do
		for z = gridOrigin.Z, gridOrigin.Z + sizeZ - 1 do
			if not InBounds(x, z) then
				return false
			end
			if GridClient.IsOccupied(x, z) then
				return false
			end
		end
	end

	return true
end

-- Returns the snapped world position for a given mouse hit and model size
-- Use this to position the ghost preview
function GridClient.GetPlacementPosition(worldPos, modelSize)
	return GridClient.GetSnappedWorldPos(worldPos, modelSize.X, modelSize.Z)
end

-- ============================================================
-- INIT  (call this once from your Knit controller's KnitStart)
-- ============================================================

function GridClient.Init()
	local GridService = Knit.GetService("GridService")

	-- receive full snapshot on join
	GridService.GridSnapshot:Connect(function(snapshot)
		ApplySnapshot(snapshot)
	end)

	-- receive delta updates
	GridService.TileUpdated:Connect(function(x, z, tileData)
		ApplyTile(x, z, tileData)
	end)

	-- request snapshot in case PlayerAdded already fired before we connected
	local snapshot = GridService:RequestSnapshot()
	if snapshot and snapshot.SizeX then
		ApplySnapshot(snapshot)
	end
end

return GridClient
