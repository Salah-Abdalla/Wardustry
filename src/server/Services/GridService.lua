local ServerStorage = game:GetService("ServerStorage")
-- GridService.lua
local Knit = require(game.ReplicatedStorage.Packages.Knit)

local GridService = Knit.CreateService({
	Name = "GridService",
	Client = {},
})

local TILE_SIZE = 4
local Grid = {}

function GridService:LoadFromSector(sectorName)
	local sectors = ServerStorage:FindFirstChild("Sectors")
	if not sectors then
		return false, "No 'Sectors' folder in ServerStorage."
	end

	local m = sectors:FindFirstChild(sectorName)
	if not m then
		return false, ('No sector named "' .. sectorName .. '" in ServerStorage.Sectors.')
	end

	local ok, sectorResult = pcall(require, m)
	if not ok or type(sectorResult) ~= "table" then
		return false, ("Failed to require sector module: " .. tostring(sectorResult))
	end

	self:SetBounds(sectorResult.Size.X, sectorResult.Size.Z)

	for key, oreKind in pairs(sectorResult.Ores or {}) do
		local x, z = key:match("^(-?%d+),(-?%d+)$")
		self:SetOre(tonumber(x), tonumber(z), oreKind)
	end

	for key, obsKind in pairs(sectorResult.Obstructions or {}) do
		local x, z = key:match("^(-?%d+),(-?%d+)$")
		self:SetObstruction(tonumber(x), tonumber(z), 0)
	end

	for key, specialKind in pairs(sectorResult.SpecialTiles or {}) do
		local x, z = key:match("^(-?%d+),(-?%d+)$")
		self:SetSpecialTile(tonumber(x), tonumber(z), specialKind)
	end

	for key, liquidKind in pairs(sectorResult.LiquidTiles or {}) do
		local x, z = key:match("^(-?%d+),(-?%d+)$")
		self:SetSpecialTile(tonumber(x), tonumber(z), liquidKind)
	end

	-- mark core tiles as occupied
	for _, core in ipairs(sectorResult.Cores or {}) do
		local w = core.W or 2
		local h = core.H or 2
		self:SetBuilding(core.X, core.Z, w, h, "Core")
	end
end

-- ============================================================
-- INTERNAL
-- ============================================================

local function InBounds(self, x, z)
	if not self._sizeX or not self._sizeZ then
		warn("GridService: bounds not set — call SetBounds first")
		return false
	end
	return x >= 0 and x < self._sizeX and z >= 0 and z < self._sizeZ
end

local function EnsureTile(self, x, z)
	if not InBounds(self, x, z) then
		return nil
	end
	if not Grid[x] then
		Grid[x] = {}
	end
	if not Grid[x][z] then
		Grid[x][z] = {
			Building = nil,
			OreId = nil,
			IsObstruction = false,
			ObstructionHeight = 0,
			SpecialTile = nil,
		}
	end
	return Grid[x][z]
end

-- ============================================================
-- BOUNDS
-- ============================================================

function GridService:SetBounds(sizeX, sizeZ)
	self._sizeX = sizeX
	self._sizeZ = sizeZ
	Grid = {} -- clear grid when bounds are set
end

function GridService:GetSize()
	return { X = self._sizeX, Z = self._sizeZ }
end

function GridService:IsInBounds(x, z)
	return InBounds(self, x, z)
end

-- ============================================================
-- COORDINATE HELPERS
-- ============================================================

function GridService:WorldToGrid(worldPos)
	return {
		X = math.round(worldPos.X / TILE_SIZE),
		Z = math.round(worldPos.Z / TILE_SIZE),
	}
end

function GridService:GridToWorld(gridX, gridZ)
	return Vector3.new(gridX * TILE_SIZE, 0, gridZ * TILE_SIZE)
end

function GridService:GetSnappedWorldPos(worldPos, sizeX, sizeZ)
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

function GridService:GetGridOrigin(snappedWorldPos, sizeX, sizeZ)
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

function GridService:GetTile(x, z)
	if not InBounds(self, x, z) then
		warn("GridService.GetTile: out of bounds ->", x, z)
		return nil
	end
	if not Grid[x] then
		return nil
	end
	return Grid[x][z]
end

function GridService:IsOccupied(x, z)
	local tile = self:GetTile(x, z)
	if not tile then
		return false
	end
	return tile.Building ~= nil or tile.IsObstruction
end

function GridService:IsObstruction(x, z)
	local tile = self:GetTile(x, z)
	if not tile then
		return false
	end
	return tile.IsObstruction
end

function GridService:GetObstructionHeight(x, z)
	local tile = self:GetTile(x, z)
	if not tile then
		return 0
	end
	return tile.ObstructionHeight or 0
end

function GridService:GetBuilding(x, z)
	local tile = self:GetTile(x, z)
	if not tile then
		return nil
	end
	return tile.Building
end

function GridService:GetOre(x, z)
	local tile = self:GetTile(x, z)
	if not tile then
		return nil
	end
	return tile.OreId
end

function GridService:GetSpecialTile(x, z)
	local tile = self:GetTile(x, z)
	if not tile then
		return nil
	end
	return tile.SpecialTile
end

function GridService:CanPlace(gridX, gridZ, sizeX, sizeZ)
	for x = gridX, gridX + sizeX - 1 do
		for z = gridZ, gridZ + sizeZ - 1 do
			if not InBounds(self, x, z) then
				return false -- out of bounds counts as blocked
			end
			if self:IsOccupied(x, z) then
				return false
			end
		end
	end
	return true
end

function GridService:GetTilesInRegion(gridX, gridZ, sizeX, sizeZ)
	local tiles = {}
	for x = gridX, gridX + sizeX - 1 do
		for z = gridZ, gridZ + sizeZ - 1 do
			table.insert(tiles, {
				X = x,
				Z = z,
				Tile = self:GetTile(x, z),
			})
		end
	end
	return tiles
end

-- ============================================================
-- TILE WRITE
-- ============================================================

function GridService:SetBuilding(gridX, gridZ, sizeX, sizeZ, buildingId)
	for x = gridX, gridX + sizeX - 1 do
		for z = gridZ, gridZ + sizeZ - 1 do
			local tile = EnsureTile(self, x, z)
			if tile then
				tile.Building = buildingId
			end
		end
	end
end

function GridService:ClearBuilding(gridX, gridZ, sizeX, sizeZ)
	for x = gridX, gridX + sizeX - 1 do
		for z = gridZ, gridZ + sizeZ - 1 do
			local tile = self:GetTile(x, z)
			if tile then
				tile.Building = nil
			end
		end
	end
end

function GridService:SetOre(x, z, oreId)
	local tile = EnsureTile(self, x, z)
	if tile then
		tile.OreId = oreId
	end
end

function GridService:ClearOre(x, z)
	local tile = self:GetTile(x, z)
	if tile then
		tile.OreId = nil
	end
end

function GridService:SetObstruction(x, z, height)
	local tile = EnsureTile(self, x, z)
	if tile then
		tile.IsObstruction = true
		tile.ObstructionHeight = height or 0
	end
end

function GridService:ClearObstruction(x, z)
	local tile = self:GetTile(x, z)
	if tile then
		tile.IsObstruction = false
		tile.ObstructionHeight = 0
	end
end

function GridService:SetSpecialTile(x, z, kind)
	local tile = EnsureTile(self, x, z)
	if tile then
		tile.SpecialTile = kind
	end
end

function GridService:ClearSpecialTile(x, z)
	local tile = self:GetTile(x, z)
	if tile then
		tile.SpecialTile = nil
	end
end

function GridService:ClearGrid()
	Grid = {}
	self._sizeX = nil
	self._sizeZ = nil
end

-- ============================================================
-- KNIT
-- ============================================================

function GridService:KnitInit()
	self._sizeX = nil
	self._sizeZ = nil
end

function GridService:KnitStart() end

return GridService
