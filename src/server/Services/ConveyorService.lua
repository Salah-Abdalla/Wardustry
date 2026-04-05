-- ConveyorService
-- Knit Service — routes solid items through conveyor chains between producers and consumers
-- Phase 1: Conveyor, Express Conveyor, Reinforced Conveyor, Sprint Conveyor only

local Knit         = require(game:GetService("ReplicatedStorage").Packages.Knit)
local TweenService = game:GetService("TweenService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local BuildingConfig  = require(ReplicatedStorage.Config.BuildingConfig)
local TransportConfig = require(ReplicatedStorage.Config.TransportConfig)
local ObjectNames     = require(ReplicatedStorage.Dictionaries.ObjectNames)
local Categories      = require(ReplicatedStorage.Dictionaries.Categories)

local ConveyorService = Knit.CreateService({ Name = "ConveyorService", Client = {} })

-- ════════════════════════════════════════
--  CONSTANTS
-- ════════════════════════════════════════

local TICK_INTERVAL = 0.1 -- 10 Hz
local TILE_SIZE     = 4
local ITEM_Y        = 2   -- studs above world floor (sits just above a thin conveyor model)

-- Temporary colour map — one colour per resource type
local RESOURCE_COLORS = {
	[ObjectNames["Copper"]]           = Color3.fromRGB(184, 115,  51),
	[ObjectNames["Tin"]]              = Color3.fromRGB(180, 180, 180),
	[ObjectNames["Coal"]]             = Color3.fromRGB( 40,  40,  40),
	[ObjectNames["Sand"]]             = Color3.fromRGB(220, 200, 140),
	[ObjectNames["Ironstone"]]        = Color3.fromRGB(130,  60,  40),
	[ObjectNames["Bauxite"]]          = Color3.fromRGB(160,  90,  70),
	[ObjectNames["Quartz"]]           = Color3.fromRGB(230, 220, 255),
	[ObjectNames["Uranium"]]          = Color3.fromRGB( 80, 220,  80),
	[ObjectNames["Bronze"]]           = Color3.fromRGB(200, 130,  50),
	[ObjectNames["Ferrocast"]]        = Color3.fromRGB(100,  40,  30),
	[ObjectNames["Aluminite"]]        = Color3.fromRGB(160, 180, 200),
	[ObjectNames["Glassite"]]         = Color3.fromRGB(100, 220, 220),
	[ObjectNames["Graphite"]]         = Color3.fromRGB( 60,  60,  70),
	[ObjectNames["Silicon"]]          = Color3.fromRGB(140, 100, 180),
	[ObjectNames["Quartzite"]]        = Color3.fromRGB(100, 120, 200),
	[ObjectNames["Steel"]]            = Color3.fromRGB(100, 120, 140),
	[ObjectNames["Refined Uranium"]]  = Color3.fromRGB( 50, 255, 100),
	[ObjectNames["Pyro Charge"]]      = Color3.fromRGB(220,  80,  30),
}

-- Cardinal directions (index 0–3)
local DIR = { NORTH = 0, EAST = 1, SOUTH = 2, WEST = 3 }

-- Grid deltas per direction
local DIR_OFFSET = {
	[0] = { dx = 0,  dz = -1 }, -- NORTH: -Z
	[1] = { dx = 1,  dz = 0  }, -- EAST:  +X
	[2] = { dx = 0,  dz = 1  }, -- SOUTH: +Z
	[3] = { dx = -1, dz = 0  }, -- WEST:  -X
}

local OPPOSITE = { [0] = 2, [1] = 3, [2] = 0, [3] = 1 }

-- All solid-item conveyor building names
local SOLID_TRANSPORTS = {
	[ObjectNames["Conveyor"]]            = true,
	[ObjectNames["Express Conveyor"]]    = true,
	[ObjectNames["Reinforced Conveyor"]] = true,
	[ObjectNames["Sprint Conveyor"]]     = true,
}

-- ════════════════════════════════════════
--  STATE
-- ════════════════════════════════════════

-- _nodes["gx,gz"]    = ConveyorNode
-- _producers["gx,gz"] = ProducerEntry  (one per tile of the producer footprint)
-- _consumers["gx,gz"] = ConsumerEntry  (one per tile of the consumer footprint)
-- _producerEdges[model] = { ConveyorNode, ... }  (cached output edges for ProducerPush)
-- _consumerEdges[model] = { ConveyorNode, ... }  (cached input edges for ConsumerPull)

local _nodes         = {}
local _producers     = {}
local _consumers     = {}
local _producerEdges = {}
local _consumerEdges = {}
local _itemFolder    = nil -- Folder in workspace that holds all item parts

-- ════════════════════════════════════════
--  HELPERS
-- ════════════════════════════════════════

local function NodeKey(gx, gz)
	return gx .. "," .. gz
end

local function RotationToDir(rotY)
	local n = rotY % 360
	if n == 0   then return DIR.NORTH end
	if n == 90  then return DIR.EAST  end
	if n == 180 then return DIR.SOUTH end
	if n == 270 then return DIR.WEST  end
	return DIR.NORTH
end

local function GetOutputTile(gx, gz, dir)
	local off = DIR_OFFSET[dir]
	return gx + off.dx, gz + off.dz
end

local function TileCenter(gx, gz)
	return Vector3.new(gx * TILE_SIZE + TILE_SIZE / 2, ITEM_Y, gz * TILE_SIZE + TILE_SIZE / 2)
end

local function SpawnItemPart(resourceId, gx, gz)
	local part = Instance.new("Part")
	part.Size        = Vector3.one
	part.Anchored    = true
	part.CanCollide  = false
	part.CastShadow  = false
	part.Color       = RESOURCE_COLORS[resourceId] or Color3.fromRGB(200, 200, 200)
	part.Material    = Enum.Material.SmoothPlastic
	part.Position    = TileCenter(gx, gz)
	part.Parent      = _itemFolder
	return part
end

local function TweenItemPart(part, gx, gz, speed)
	if not part or not part.Parent then return end
	local info = TweenInfo.new(1 / speed, Enum.EasingStyle.Linear)
	TweenService:Create(part, info, { Position = TileCenter(gx, gz) }):Play()
end

-- ════════════════════════════════════════
--  LINK RESOLUTION
-- ════════════════════════════════════════

-- Wire up OutputNode for `node` and update any neighbor whose output faces `node`.
local function ResolveLinks(node)
	-- What does this node output into?
	local outX, outZ = GetOutputTile(node.GX, node.GZ, node.Dir)
	local outKey = NodeKey(outX, outZ)
	node.OutputNode = _nodes[outKey] -- nil if consumer/empty

	-- Tell any existing neighbor conveyor that outputs into this tile about us
	for _, off in pairs(DIR_OFFSET) do
		local nx, nz = node.GX + off.dx, node.GZ + off.dz
		local neighbor = _nodes[NodeKey(nx, nz)]
		if neighbor then
			local nOutX, nOutZ = GetOutputTile(neighbor.GX, neighbor.GZ, neighbor.Dir)
			if nOutX == node.GX and nOutZ == node.GZ then
				neighbor.OutputNode = node
			end
		end
	end
end

-- Rebuild cached output-edge list for a producer model after network changes.
local function RebuildProducerEdges(model, entry)
	local edges = {}
	-- Scan all tiles adjacent to the producer's footprint
	local gx, gz, sx, sz = entry.GX, entry.GZ, entry.SizeX, entry.SizeZ
	-- Walk each perimeter tile and check if an adjacent conveyor points at it
	for tx = gx - 1, gx + sx do
		for tz = gz - 1, gz + sz do
			-- Only perimeter
			local onPerim = tx == gx - 1 or tx == gx + sx or tz == gz - 1 or tz == gz + sz
			if onPerim then
				local node = _nodes[NodeKey(tx, tz)]
				if node then
					-- Does this conveyor's output face land on the producer footprint?
					local nOutX, nOutZ = GetOutputTile(node.GX, node.GZ, node.Dir)
					-- Actually, for a producer we want conveyors whose INPUT face
					-- is adjacent to the producer — i.e. the conveyor's input side
					-- is a producer tile. That means the tile BEHIND the conveyor is
					-- inside the footprint.
					local oppOff = DIR_OFFSET[OPPOSITE[node.Dir]]
					local inputX = node.GX + oppOff.dx
					local inputZ = node.GZ + oppOff.dz
					local inFootprint = inputX >= gx and inputX < gx + sx
						and inputZ >= gz and inputZ < gz + sz
					if inFootprint then
						table.insert(edges, node)
					end
					-- Suppress unused nOutX, nOutZ
					local _ = nOutX
					local __ = nOutZ
				end
			end
		end
	end
	_producerEdges[model] = edges
end

-- Rebuild cached input-edge list for a consumer model (conveyors whose output face
-- lands on a consumer tile).
local function RebuildConsumerEdges(model, entry)
	local edges = {}
	local gx, gz, sx, sz = entry.GX, entry.GZ, entry.SizeX, entry.SizeZ
	for tx = gx - 1, gx + sx do
		for tz = gz - 1, gz + sz do
			local onPerim = tx == gx - 1 or tx == gx + sx or tz == gz - 1 or tz == gz + sz
			if onPerim then
				local node = _nodes[NodeKey(tx, tz)]
				if node then
					local outX, outZ = GetOutputTile(node.GX, node.GZ, node.Dir)
					local inFootprint = outX >= gx and outX < gx + sx
						and outZ >= gz and outZ < gz + sz
					if inFootprint then
						table.insert(edges, node)
					end
				end
			end
		end
	end
	_consumerEdges[model] = edges
end

-- After placing/removing a conveyor node, refresh edges for any nearby producers/consumers.
local function RefreshNeighborEndpoints(gx, gz)
	-- Scan a 2-tile radius for registered producer/consumer tiles
	for tx = gx - 2, gx + 2 do
		for tz = gz - 2, gz + 2 do
			local key = NodeKey(tx, tz)
			local prodEntry = _producers[key]
			if prodEntry then
				RebuildProducerEdges(prodEntry.Model, prodEntry)
			end
			local consEntry = _consumers[key]
			if consEntry then
				RebuildConsumerEdges(consEntry.Model, consEntry)
			end
		end
	end
end

-- ════════════════════════════════════════
--  NODE REGISTRATION
-- ════════════════════════════════════════

function ConveyorService:_RegisterNode(model, buildingName, team, gx, gz, rotY)
	local dir   = RotationToDir(rotY)
	local speed = TransportConfig.GetSpeed(buildingName)
	local key   = NodeKey(gx, gz)

	local node = {
		Key          = key,
		BuildingName = buildingName,
		Team         = team,
		GX           = gx,
		GZ           = gz,
		Dir          = dir,
		Speed        = speed,
		Buffer       = {},
		BufferMax    = math.max(1, math.floor(speed * 2)),
		AccumTime    = 0,
		OutputNode   = nil,
		Model        = model,
	}

	_nodes[key] = node
	ResolveLinks(node)
	RefreshNeighborEndpoints(gx, gz)

	print(string.format("[ConveyorService] Registered %s at (%d,%d) dir=%d speed=%g",
		buildingName, gx, gz, dir, speed))
end

function ConveyorService:_UnregisterNode(gx, gz)
	local key  = NodeKey(gx, gz)
	local node = _nodes[key]
	if not node then return end

	-- Disconnect any neighbor whose OutputNode pointed here
	for _, off in pairs(DIR_OFFSET) do
		local nx, nz = gx + off.dx, gz + off.dz
		local neighbor = _nodes[NodeKey(nx, nz)]
		if neighbor and neighbor.OutputNode == node then
			neighbor.OutputNode = nil
		end
	end

	-- Drop buffer and destroy visuals (no refunds in Phase 1)
	for _, item in ipairs(node.Buffer) do
		if item.Part then
			item.Part:Destroy()
		end
	end
	node.Buffer = {}
	_nodes[key] = nil

	RefreshNeighborEndpoints(gx, gz)

	print(string.format("[ConveyorService] Unregistered conveyor at (%d,%d)", gx, gz))
end

-- ════════════════════════════════════════
--  PRODUCER / CONSUMER REGISTRATION
-- ════════════════════════════════════════

function ConveyorService:_RegisterProducer(model, buildingName, team, gx, gz, sizeX, sizeZ)
	local entry = {
		Model        = model,
		BuildingName = buildingName,
		Team         = team,
		GX           = gx,
		GZ           = gz,
		SizeX        = sizeX,
		SizeZ        = sizeZ,
	}
	-- Index every tile in the footprint
	for tx = gx, gx + sizeX - 1 do
		for tz = gz, gz + sizeZ - 1 do
			_producers[NodeKey(tx, tz)] = entry
		end
	end
	_producerEdges[model] = {}
	RebuildProducerEdges(model, entry)
end

function ConveyorService:_UnregisterProducer(gx, gz, sizeX, sizeZ, model)
	for tx = gx, gx + sizeX - 1 do
		for tz = gz, gz + sizeZ - 1 do
			_producers[NodeKey(tx, tz)] = nil
		end
	end
	_producerEdges[model] = nil
end

function ConveyorService:_RegisterConsumer(model, buildingName, team, gx, gz, sizeX, sizeZ)
	local entry = {
		Model        = model,
		BuildingName = buildingName,
		Team         = team,
		GX           = gx,
		GZ           = gz,
		SizeX        = sizeX,
		SizeZ        = sizeZ,
	}
	for tx = gx, gx + sizeX - 1 do
		for tz = gz, gz + sizeZ - 1 do
			_consumers[NodeKey(tx, tz)] = entry
		end
	end
	_consumerEdges[model] = {}
	RebuildConsumerEdges(model, entry)
end

function ConveyorService:_UnregisterConsumer(gx, gz, sizeX, sizeZ, model)
	for tx = gx, gx + sizeX - 1 do
		for tz = gz, gz + sizeZ - 1 do
			_consumers[NodeKey(tx, tz)] = nil
		end
	end
	_consumerEdges[model] = nil
end

-- ════════════════════════════════════════
--  TICK — item movement
-- ════════════════════════════════════════

function ConveyorService:_TryPush(targetNode, item, fromSpeed)
	if #targetNode.Buffer >= targetNode.BufferMax then
		return false -- backpressure: downstream full
	end
	if item.Part then
		TweenItemPart(item.Part, targetNode.GX, targetNode.GZ, fromSpeed)
	end
	table.insert(targetNode.Buffer, item)
	return true
end

function ConveyorService:_OnBuildingReceive(_consumerEntry, _item)
	-- TODO: notify the building's service (FactoryService, StorageService, etc.)
	-- so it can add the item to its own internal buffer
end

function ConveyorService:_DeliverToConsumer(consumerEntry, item)
	if item.Part then
		item.Part:Destroy()
		item.Part = nil
	end
	if BuildingConfig.GetCategory(consumerEntry.BuildingName) == Categories.Core then
		self.ResourceService:Add(consumerEntry.Team, item.ResourceId, item.Amount)
	else
		self:_OnBuildingReceive(consumerEntry, item)
	end
	return true
end

function ConveyorService:_TryFlush(node)
	if #node.Buffer == 0 then return end
	local item = node.Buffer[1]

	if node.OutputNode then
		-- Next tile is another conveyor
		if self:_TryPush(node.OutputNode, item, node.Speed) then
			table.remove(node.Buffer, 1)
		end
		-- else: backpressure — item stays
	else
		-- Check if output tile is a consumer
		local outX, outZ = GetOutputTile(node.GX, node.GZ, node.Dir)
		local consumerEntry = _consumers[NodeKey(outX, outZ)]
		if consumerEntry then
			if self:_DeliverToConsumer(consumerEntry, item) then
				table.remove(node.Buffer, 1)
			end
		end
		-- else: end of chain with no consumer — item stays
	end
end

function ConveyorService:_Tick(dt)
	for _, node in pairs(_nodes) do
		node.AccumTime += dt
		local interval = 1 / node.Speed
		while node.AccumTime >= interval do
			node.AccumTime -= interval
			self:_TryFlush(node)
		end
	end
end

-- ════════════════════════════════════════
--  PUBLIC PRODUCER / CONSUMER API
-- ════════════════════════════════════════

-- Called by DrillService after mining one unit.
-- Returns true if the item entered the network.
function ConveyorService:ProducerPush(producerModel, resourceId, amount)
	local edges = _producerEdges[producerModel]
	if not edges then return false end
	for _, node in ipairs(edges) do
		local part = SpawnItemPart(resourceId, node.GX, node.GZ)
		local item = { ResourceId = resourceId, Amount = amount, Part = part }
		if self:_TryPush(node, item, node.Speed) then
			return true
		else
			part:Destroy()
		end
	end
	return false
end

-- Round-robin push: tries edges starting at outputIndex, wraps around.
-- Returns (pushed: bool, nextIndex: number).
-- nextIndex advances on success so the caller stores it back.
function ConveyorService:ProducerPushRoundRobin(model, resourceId, amount, outputIndex)
	local edges = _producerEdges[model]
	if not edges or #edges == 0 then return false, outputIndex end

	local count = #edges
	for i = 0, count - 1 do
		local idx  = ((outputIndex - 1 + i) % count) + 1
		local node = edges[idx]
		local part = SpawnItemPart(resourceId, node.GX, node.GZ)
		local item = { ResourceId = resourceId, Amount = amount, Part = part }
		if self:_TryPush(node, item, node.Speed) then
			return true, (idx % count) + 1
		else
			part:Destroy()
		end
	end
	return false, outputIndex
end

-- Returns true if all output-facing conveyor buffers are full.
function ConveyorService:IsProducerBlocked(producerModel)
	local edges = _producerEdges[producerModel]
	if not edges or #edges == 0 then return true end
	for _, node in ipairs(edges) do
		if #node.Buffer < node.BufferMax then return false end
	end
	return true
end

-- Called by FactoryService to pull one unit of a specific resource from input conveyors.
-- Returns { ResourceId, Amount } or nil.
function ConveyorService:ConsumerPull(consumerModel, resourceId)
	local edges = _consumerEdges[consumerModel]
	if not edges then return nil end
	for _, node in ipairs(edges) do
		for i, item in ipairs(node.Buffer) do
			if item.ResourceId == resourceId then
				table.remove(node.Buffer, i)
				if item.Part then
					item.Part:Destroy()
					item.Part = nil
				end
				return item
			end
		end
	end
	return nil
end

-- Check whether a specific resource is available without consuming it.
function ConveyorService:ConsumerPeek(consumerModel, resourceId)
	local edges = _consumerEdges[consumerModel]
	if not edges then return false end
	for _, node in ipairs(edges) do
		for _, item in ipairs(node.Buffer) do
			if item.ResourceId == resourceId then return true end
		end
	end
	return false
end

-- ════════════════════════════════════════
--  EVENT HANDLERS
-- ════════════════════════════════════════

local function OnBuildingPlaced(model, buildingName, team, gx, gz, sizeX, sizeZ, rotY)
	if SOLID_TRANSPORTS[buildingName] then
		ConveyorService:_RegisterNode(model, buildingName, team, gx, gz, rotY)
	elseif BuildingConfig.OutputsResources(buildingName) then
		ConveyorService:_RegisterProducer(model, buildingName, team, gx, gz, sizeX, sizeZ)
	elseif BuildingConfig.AcceptsResourceInput(buildingName) then
		ConveyorService:_RegisterConsumer(model, buildingName, team, gx, gz, sizeX, sizeZ)
	end
end

local function OnBuildingDemolished(buildingName, team, gx, gz, sizeX, sizeZ)
	local _ = team -- unused but part of signal signature
	if SOLID_TRANSPORTS[buildingName] then
		ConveyorService:_UnregisterNode(gx, gz)
	elseif BuildingConfig.OutputsResources(buildingName) then
		-- model not passed in demolish signal; find via producer tile
		local entry = _producers[NodeKey(gx, gz)]
		if entry then
			ConveyorService:_UnregisterProducer(gx, gz, sizeX, sizeZ, entry.Model)
		end
	elseif BuildingConfig.AcceptsResourceInput(buildingName) then
		local entry = _consumers[NodeKey(gx, gz)]
		if entry then
			ConveyorService:_UnregisterConsumer(gx, gz, sizeX, sizeZ, entry.Model)
		end
	end
end

local function OnStructureDestroyed(structureObj)
	local model = structureObj.Model
	-- Find the node or endpoint by model reference
	for key, node in pairs(_nodes) do
		if node.Model == model then
			ConveyorService:_UnregisterNode(node.GX, node.GZ)
			return
		end
	end
	-- Check producers
	for _, entry in pairs(_producers) do
		if entry.Model == model then
			ConveyorService:_UnregisterProducer(entry.GX, entry.GZ, entry.SizeX, entry.SizeZ, model)
			return
		end
	end
	-- Check consumers
	for _, entry in pairs(_consumers) do
		if entry.Model == model then
			ConveyorService:_UnregisterConsumer(entry.GX, entry.GZ, entry.SizeX, entry.SizeZ, model)
			return
		end
	end
end

-- ════════════════════════════════════════
--  LIFECYCLE
-- ════════════════════════════════════════

function ConveyorService:KnitInit()
	self.BuildingService   = Knit.GetService("BuildingService")
	self.StructureService  = Knit.GetService("StructureService")
	self.ResourceService   = Knit.GetService("ResourceService")
end

function ConveyorService:KnitStart()
	_itemFolder = Instance.new("Folder")
	_itemFolder.Name = "ConveyorItems"
	_itemFolder.Parent = workspace

	self.BuildingService.BuildingPlaced.Event:Connect(OnBuildingPlaced)
	self.BuildingService.BuildingDemolished.Event:Connect(OnBuildingDemolished)
	self.StructureService.StructureDestroyed.Event:Connect(OnStructureDestroyed)

	task.spawn(function()
		while true do
			task.wait(TICK_INTERVAL)
			self:_Tick(TICK_INTERVAL)
		end
	end)

	print("[ConveyorService] Started")
end

return ConveyorService
