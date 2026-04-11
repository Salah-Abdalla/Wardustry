-- SectorLoader
-- Place in ServerScriptService or wherever your services live
-- Usage: local ok, result = SectorLoader.Load("SectorName")

local SectorLoader = {}

local ServerStorage = game:GetService("ServerStorage")
local CollectionService = game:GetService("CollectionService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local BuildingConfig = require(ReplicatedStorage.Config.BuildingConfig)
local ObjectNames = require(ReplicatedStorage.Dictionaries.ObjectNames)

-- ── Constants ──
local TILE_SIZE = 4 -- studs per tile
local FLOOR_Y = 0 -- world Y for floor center (1 stud thick, top at 0.5)
local FLOOR_THICK = 1
local TILE_THICK = 0.1
local TILE_Y = FLOOR_Y + (FLOOR_THICK / 2) + (TILE_THICK / 2) -- 0.6
local CORE_SIZE = 16
local CORE_Y = FLOOR_Y + (FLOOR_THICK / 2) + (CORE_SIZE / 2) -- 2.5
local SPAWN_SIZE = 4
local SPAWN_Y = CORE_Y

-- ── Fallback tile colors (fill in decal IDs later) ──
local TILE_COLORS = {
	-- Ores
	Copper = Color3.fromHex("E07000"),
	Tin = Color3.fromHex("AAAAAA"),
	Ironstone = Color3.fromHex("8B3A3A"),
	Coal = Color3.fromHex("111111"),
	Bauxite = Color3.fromHex("A0522D"),
	Sand = Color3.fromHex("D2B48C"),
	Quartz = Color3.fromHex("7EC8E3"),
	Uranium = Color3.fromHex("39FF14"),
	-- Special
	Geothermal = Color3.fromHex("FF8C00"),
	-- Liquid
	Water = Color3.fromHex("1E90FF"),
	Crude = Color3.fromHex("3B1A00"),
}

-- Decal asset IDs — fill these in later when icons are ready
-- local TILE_DECALS = {
-- 	Copper    = "rbxassetid://000",
-- 	...
-- }

local CORE_COLOR = Color3.fromHex("4488FF")
local SPAWN_COLOR = Color3.fromHex("FF3333")

-- ── Helpers ──

local function TileKey(x, z)
	return x .. "," .. z
end

local function MakePart(parent, props)
	local p = Instance.new("Part")
	p.Anchored = true
	p.CanCollide = false
	p.CastShadow = false
	p.TopSurface = Enum.SurfaceType.Smooth
	p.BottomSurface = Enum.SurfaceType.Smooth
	for k, v in pairs(props) do
		p[k] = v
	end
	p.Parent = parent
	return p
end

-- Tiles are centered at (x * TILE_SIZE + TILE_SIZE/2, TILE_Y, z * TILE_SIZE + TILE_SIZE/2)
-- so tile (0,0) occupies studs 0..4 on X and Z
local function TileCenter(x, z)
	return Vector3.new(x * TILE_SIZE + TILE_SIZE / 2, TILE_Y, z * TILE_SIZE + TILE_SIZE / 2)
end

local function CoreCenter(x, z)
	return Vector3.new(x * TILE_SIZE + TILE_SIZE / 2, CORE_Y, z * TILE_SIZE + TILE_SIZE / 2)
end

-- ── Main Load ──

function SectorLoader.Load(sectorName)
	-- 1. Find the sector module
	local sectors = ServerStorage:FindFirstChild("Sectors")
	if not sectors then
		return false, "No 'Sectors' folder in ServerStorage."
	end
	local m = sectors:FindFirstChild(sectorName)
	if not m then
		return false, ('No sector named "' .. sectorName .. '" in ServerStorage.Sectors.')
	end
	local ok, data = pcall(require, m)
	if not ok or type(data) ~= "table" then
		return false, ("Failed to require sector module: " .. tostring(data))
	end

	-- 2. Validate required fields
	local gridSizeX = data.Size and data.Size.X or 0
	local gridSizeZ = data.Size and data.Size.Z or 0
	if gridSizeX <= 0 or gridSizeZ <= 0 then
		return false, "Sector has invalid Size."
	end

	-- 3. Clear any existing Map folder
	local existingMap = workspace:FindFirstChild("Map")
	if existingMap then
		existingMap:Destroy()
	end

	-- 4. Create Map folder structure
	local mapFolder = Instance.new("Folder")
	mapFolder.Name = "Map"
	mapFolder.Parent = workspace

	local tilesFolder = Instance.new("Folder")
	tilesFolder.Name = "Tiles"
	tilesFolder.Parent = mapFolder

	local coresFolder = Instance.new("Folder")
	coresFolder.Name = "Cores"
	coresFolder.Parent = mapFolder

	local spawnsFolder = Instance.new("Folder")
	spawnsFolder.Name = "SpawnPoints"
	spawnsFolder.Parent = mapFolder

	-- 5. Floor
	local floorSizeX = gridSizeX * TILE_SIZE
	local floorSizeZ = gridSizeZ * TILE_SIZE
	local floor = MakePart(mapFolder, {
		Name = "Floor",
		Size = Vector3.new(floorSizeX, FLOOR_THICK, floorSizeZ),
		Position = Vector3.new(floorSizeX / 2, FLOOR_Y, floorSizeZ / 2),
		Color = Color3.fromHex("#7d7d7d"),
		Material = Enum.Material.Plastic,
		CanCollide = true,
	})
	CollectionService:AddTag(floor, "Floor")

	-- 6. Build result mapping
	local result = {
		MapFolder = mapFolder,
		FloorPart = floor,
		TileMap = {},
		Cores = {},
		SpawnPoints = {},
		StartingResources = data.StartingResources or {},
	}

	-- 7. Place ore tiles
	for key, oreKind in pairs(data.Ores or {}) do
		local x, z = key:match("^(-?%d+),(-?%d+)$")
		x = tonumber(x)
		z = tonumber(z)
		if x and z then
			local color = TILE_COLORS[oreKind] or Color3.fromHex("FF00FF")
			local part = MakePart(tilesFolder, {
				Name = oreKind,
				Size = Vector3.new(TILE_SIZE, TILE_THICK, TILE_SIZE),
				Position = TileCenter(x, z),
				Color = color,
				Material = Enum.Material.SmoothPlastic,
			})

			CollectionService:AddTag(part, "Ore")
			CollectionService:AddTag(part, oreKind)

			-- TODO: add decal here when asset IDs are ready
			-- local decalId = TILE_DECALS[oreKind]
			-- if decalId then
			-- 	local d = Instance.new("Decal")
			-- 	d.Texture = decalId; d.Face = Enum.NormalId.Top; d.Parent = part
			-- end
			result.TileMap[key] = { Type = "Ore", Kind = oreKind, Part = part }
		end
	end

	-- 8. Place special tiles
	for key, specialKind in pairs(data.SpecialTiles or {}) do
		local x, z = key:match("^(-?%d+),(-?%d+)$")
		x = tonumber(x)
		z = tonumber(z)
		if x and z then
			local color = TILE_COLORS[specialKind] or Color3.fromHex("FF00FF")
			local part = MakePart(tilesFolder, {
				Name = specialKind,
				Size = Vector3.new(TILE_SIZE, TILE_THICK, TILE_SIZE),
				Position = TileCenter(x, z),
				Color = color,
				Material = Enum.Material.SmoothPlastic,
			})
			CollectionService:AddTag(part, "Special")
			CollectionService:AddTag(part, specialKind)
			result.TileMap[key] = { Type = "Special", Kind = specialKind, Part = part }
		end
	end

	-- 9. Place liquid tiles
	for key, liquidKind in pairs(data.LiquidTiles or {}) do
		local x, z = key:match("^(-?%d+),(-?%d+)$")
		x = tonumber(x)
		z = tonumber(z)
		if x and z then
			local color = TILE_COLORS[liquidKind] or Color3.fromHex("FF00FF")
			local part = MakePart(tilesFolder, {
				Name = liquidKind,
				Size = Vector3.new(TILE_SIZE, TILE_THICK, TILE_SIZE),
				Position = TileCenter(x, z),
				Color = color,
				Material = Enum.Material.SmoothPlastic,
			})
			CollectionService:AddTag(part, "Liquid")
			CollectionService:AddTag(part, liquidKind)
			result.TileMap[key] = { Type = "Liquid", Kind = liquidKind, Part = part }
		end
	end

	-- 11. Place obstruction tiles (color only for now, height later)
	local OBSTRUCTION_COLORS = {
		Wall = Color3.fromHex("555555"),
		Hill = Color3.fromHex("6B6B00"),
		Mountain = Color3.fromHex("4A0E6B"),
	}
	for key, obsKind in pairs(data.Obstructions or {}) do
		local x, z = key:match("^(-?%d+),(-?%d+)$")
		x = tonumber(x)
		z = tonumber(z)
		if x and z then
			local color = OBSTRUCTION_COLORS[obsKind] or Color3.fromHex("888888")
			local part = MakePart(tilesFolder, {
				Name = obsKind,
				Size = Vector3.new(TILE_SIZE, TILE_THICK, TILE_SIZE),
				Position = TileCenter(x, z),
				Color = color,
				Material = Enum.Material.SmoothPlastic,
				CanCollide = true,
			})
			result.TileMap[key] = { Type = "Obstruction", Kind = obsKind, Part = part }
		end
	end

	-- 12. Place Cores
	for _, coreData in ipairs(data.Cores or {}) do
		local PositionX, PositionZ = coreData.X, coreData.Z

		local Length = BuildingConfig.GetSize(ObjectNames["Core Shard"]).X
		local Width = BuildingConfig.GetSize(ObjectNames["Core Shard"]).Y

		local Height = coreData.H or 4 -- default to 2 tiles tall

		-- center position over the full WxH block
		local centerX = PositionX * TILE_SIZE + (Width * TILE_SIZE) / 2
		local centerZ = PositionZ * TILE_SIZE + (Length * TILE_SIZE) / 2

		local part = MakePart(coresFolder, {
			Name = "Core_" .. (coreData.TeamColor or "Unknown"),
			Size = Vector3.new(Width * TILE_SIZE, Height * TILE_SIZE, Length * TILE_SIZE),
			Position = Vector3.new(centerX, CORE_Y, centerZ),
			Color = CORE_COLOR,
			Material = Enum.Material.SmoothPlastic,
			CanCollide = true,
		})

		local model = Instance.new("Model")
		model.Name = "CoreModel_" .. (coreData.TeamColor or "Unknown")
		part.Parent = model
		model.PrimaryPart = part
		model.Parent = coresFolder

		table.insert(result.Cores, {
			TeamColor = coreData.TeamColor,
			gX = PositionX,
			gZ = PositionZ,
			SizeX = Width,
			SizeZ = Length,
			H = Height,
			Model = model,
			CoreName = "Core Shard",
		})
	end

	-- 13. Place SpawnPoints
	for _, spawnData in ipairs(data.SpawnPoints or {}) do
		local x, z = spawnData.X, spawnData.Z
		local part = MakePart(spawnsFolder, {
			Name = "Spawn_" .. (spawnData.Name or "Unknown"),
			Size = Vector3.new(SPAWN_SIZE, TILE_THICK * 2, SPAWN_SIZE),
			Position = TileCenter(x, z),
			Color = SPAWN_COLOR,
			Material = Enum.Material.Neon,
			CanCollide = false,
		})
		table.insert(result.SpawnPoints, {
			Name = spawnData.Name,
			X = x,
			Z = z,
			Part = part,
		})
	end

	print(
		string.format(
			"[SectorLoader] Loaded '%s' — %dx%d grid, %d tiles, %d cores, %d spawns",
			sectorName,
			gridSizeX,
			gridSizeZ,
			(function()
				local n = 0
				for _ in pairs(result.TileMap) do
					n += 1
				end
				return n
			end)(),
			#result.Cores,
			#result.SpawnPoints
		)
	)

	return true, result
end

return SectorLoader
