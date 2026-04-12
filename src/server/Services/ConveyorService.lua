-- ConveyorService
-- Knit Service — routes solid items through conveyor chains between producers and consumers
-- Phase 1: Conveyor, Express Conveyor, Reinforced Conveyor, Sprint Conveyor only

local Knit = require(game:GetService("ReplicatedStorage").Packages.Knit)
local TweenService = game:GetService("TweenService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local BuildingConfig = require(ReplicatedStorage.Config.BuildingConfig)
local TransportConfig = require(ReplicatedStorage.Config.TransportConfig)
local ObjectNames = require(ReplicatedStorage.Dictionaries.ObjectNames)
local Categories = require(ReplicatedStorage.Dictionaries.Categories)

local ConveyorService = Knit.CreateService({ Name = "ConveyorService", Client = {} })

-- ════════════════════════════════════════
--  CONSTANTS
-- ════════════════════════════════════════
local FLOOR_Y = 0.5
local TICK_INTERVAL = 0.1 -- 10 Hz
local TILE_SIZE = 4
local ITEM_Y = 2 -- studs above world floor (sits just above a thin conveyor model)

-- Temporary colour map — one colour per resource type
local RESOURCE_COLORS = {
	[ObjectNames["Copper"]] = Color3.fromRGB(184, 115, 51),
	[ObjectNames["Tin"]] = Color3.fromRGB(180, 180, 180),
	[ObjectNames["Coal"]] = Color3.fromRGB(40, 40, 40),
	[ObjectNames["Sand"]] = Color3.fromRGB(220, 200, 140),
	[ObjectNames["Ironstone"]] = Color3.fromRGB(130, 60, 40),
	[ObjectNames["Bauxite"]] = Color3.fromRGB(160, 90, 70),
	[ObjectNames["Quartz"]] = Color3.fromRGB(230, 220, 255),
	[ObjectNames["Uranium"]] = Color3.fromRGB(80, 220, 80),
	[ObjectNames["Bronze"]] = Color3.fromRGB(200, 130, 50),
	[ObjectNames["Ferrocast"]] = Color3.fromRGB(100, 40, 30),
	[ObjectNames["Aluminite"]] = Color3.fromRGB(160, 180, 200),
	[ObjectNames["Glassite"]] = Color3.fromRGB(100, 220, 220),
	[ObjectNames["Graphite"]] = Color3.fromRGB(60, 60, 70),
	[ObjectNames["Silicon"]] = Color3.fromRGB(140, 100, 180),
	[ObjectNames["Quartzite"]] = Color3.fromRGB(100, 120, 200),
	[ObjectNames["Steel"]] = Color3.fromRGB(100, 120, 140),
	[ObjectNames["Refined Uranium"]] = Color3.fromRGB(50, 255, 100),
	[ObjectNames["Pyro Charge"]] = Color3.fromRGB(220, 80, 30),
}

-- Cardinal directions (index 0–3)
local DIR = { NORTH = 0, EAST = 1, SOUTH = 2, WEST = 3 }

-- Grid deltas per direction
local DIR_OFFSET = {
	[0] = { dx = 0, dz = -1 }, -- NORTH: -Z
	[1] = { dx = 1, dz = 0 }, -- EAST:  +X
	[2] = { dx = 0, dz = 1 }, -- SOUTH: +Z
	[3] = { dx = -1, dz = 0 }, -- WEST:  -X
}

local OPPOSITE = { [0] = 2, [1] = 3, [2] = 0, [3] = 1 }

-- All solid-item conveyor building names
local SOLID_TRANSPORTS = {
	[ObjectNames["Conveyor"]] = true,
	[ObjectNames["Express Conveyor"]] = true,
	[ObjectNames["Reinforced Conveyor"]] = true,
	[ObjectNames["Sprint Conveyor"]] = true,
}

-- ════════════════════════════════════════
--  STATE
-- ════════════════════════════════════════

-- _nodes["gx,gz"]    = ConveyorNode
-- _producers["gx,gz"] = ProducerEntry  (one per tile of the producer footprint)
-- _consumers["gx,gz"] = ConsumerEntry  (one per tile of the consumer footprint)
-- _producerEdges[model] = { ConveyorNode, ... }  (cached output edges for ProducerPush)
-- _consumerEdges[model] = { ConveyorNode, ... }  (cached input edges for ConsumerPull)

local _nodes = {}
local _producers = {}
local _consumers = {}
-- Per-model delivery callbacks registered by other services (e.g. FactoryService)
-- [model] = function(resourceId, amount) -> bool (false = buffer full, keep item on conveyor)
local _consumerCallbacks = {}
local _producerEdges = {}
local _consumerEdges = {}
local _itemFolder = nil -- Folder in workspace that holds all item parts

-- ════════════════════════════════════════
--  HELPERS
-- ════════════════════════════════════════

local function NodeKey(gx, gz)
	return gx .. "," .. gz
end

local function RotationToDir(rotY)
	local n = (rotY + 180) % 360
	if n == 0 then
		return DIR.EAST
	end
	if n == 90 then
		return DIR.NORTH
	end
	if n == 180 then
		return DIR.WEST
	end
	if n == 270 then
		return DIR.SOUTH
	end
	return DIR.EAST
end

local function GetOutputTile(gx, gz, dir)
	local off = DIR_OFFSET[dir]
	return gx + off.dx, gz + off.dz
end

local function TileCenter(gx, gz)
	return Vector3.new(gx * TILE_SIZE + TILE_SIZE / 2, ITEM_Y, gz * TILE_SIZE + TILE_SIZE / 2)
end

local function SpawnItemPart(resourceId, worldX, worldY, worldZ)
	local part = Instance.new("Part")
	part.Size = Vector3.one
	part.Anchored = true
	part.CanCollide = false
	part.CastShadow = false
	part.Color = RESOURCE_COLORS[resourceId] or Color3.fromRGB(200, 200, 200)
	part.Material = Enum.Material.SmoothPlastic
	part.Position = Vector3.new(worldX, worldY, worldZ)
	part.Parent = _itemFolder
	return part
end

local function TileWorldCenter(gx, gz, itemY)
	return gx * TILE_SIZE + TILE_SIZE / 2, itemY, gz * TILE_SIZE + TILE_SIZE / 2
end

local function ItemStartPos(node)
	-- enter from the back edge of the tile
	local off = DIR_OFFSET[node.Dir]
	local cx, _, cz = TileWorldCenter(node.GX, node.GZ, node.ItemY)
	return cx - off.dx * TILE_SIZE / 2, node.ItemY, cz - off.dz * TILE_SIZE / 2
end

local function TweenItemPart(part, gx, gz, speed, itemY)
	if not part or not part.Parent then
		return
	end
	local info = TweenInfo.new(1 / speed, Enum.EasingStyle.Linear)
	TweenService:Create(part, info, {
		Position = Vector3.new(gx * TILE_SIZE + TILE_SIZE / 2, itemY, gz * TILE_SIZE + TILE_SIZE / 2),
	}):Play()
end

-- ════════════════════════════════════════
--  LINK RESOLUTION
-- ════════════════════════════════════════

-- Wire up OutputNode for `node` and update any neighbor whose output faces `node`.
local function ResolveLinks(node)
	local outX, outZ = GetOutputTile(node.GX, node.GZ, node.Dir)
	node.OutputNode = _nodes[NodeKey(outX, outZ)]
	print(
		string.format(
			"[ResolveLinks] (%d,%d) dir=%d → output(%d,%d) OutputNode=%s",
			node.GX,
			node.GZ,
			node.Dir,
			outX,
			outZ,
			tostring(node.OutputNode ~= nil)
		)
	)

	for _, off in pairs(DIR_OFFSET) do
		local nx, nz = node.GX + off.dx, node.GZ + off.dz
		local neighbor = _nodes[NodeKey(nx, nz)]
		if neighbor then
			local nOutX, nOutZ = GetOutputTile(neighbor.GX, neighbor.GZ, neighbor.Dir)
			print(
				string.format(
					"  neighbor (%d,%d) dir=%d → output(%d,%d) matches=%s",
					nx,
					nz,
					neighbor.Dir,
					nOutX,
					nOutZ,
					tostring(nOutX == node.GX and nOutZ == node.GZ)
				)
			)
			if nOutX == node.GX and nOutZ == node.GZ then
				neighbor.OutputNode = node
			end

			print(
				string.format(
					"[ResolveLinks] updated neighbor (%d,%d) OutputNode → (%d,%d)",
					nx,
					nz,
					node.GX,
					node.GZ
				)
			)
		end
	end
end

-- Rebuild cached output-edge list for a producer model after network changes.
-- Only checks tiles that share an edge with the footprint (no diagonals).
local function RebuildProducerEdges(model, entry)
	local edges = {}
	local gx, gz, sx, sz = entry.GX, entry.GZ, entry.SizeX, entry.SizeZ

	local function inFootprint(x, z)
		return x >= gx and x < gx + sx and z >= gz and z < gz + sz
	end

	-- Left and right columns, within the Z span of the footprint
	for tz = gz, gz + sz - 1 do
		for _, tx in ipairs({ gx - 1, gx + sx }) do
			local node = _nodes[NodeKey(tx, tz)]
			if node then
				local outX, outZ = GetOutputTile(node.GX, node.GZ, node.Dir)
				if not inFootprint(outX, outZ) then
					table.insert(edges, node)
				end
			end
		end
	end

	-- Top and bottom rows, within the X span of the footprint
	for tx = gx, gx + sx - 1 do
		for _, tz in ipairs({ gz - 1, gz + sz }) do
			local node = _nodes[NodeKey(tx, tz)]
			if node then
				local outX, outZ = GetOutputTile(node.GX, node.GZ, node.Dir)
				if not inFootprint(outX, outZ) then
					table.insert(edges, node)
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
					local inFootprint = outX >= gx and outX < gx + sx and outZ >= gz and outZ < gz + sz
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
	local dir = RotationToDir(rotY)
	local speed = TransportConfig.GetSpeed(buildingName)
	local key = NodeKey(gx, gz)

	local node = {
		Key = key,
		BuildingName = buildingName,
		Team = team,
		GX = gx,
		GZ = gz,
		Dir = dir,
		Speed = speed,
		Buffer = {},
		BufferMax = 1,
		AccumTime = 0,
		OutputNode = nil,
		Model = model,
	}

	_nodes[key] = node

	-- In _RegisterNode, after creating the node, add:
	local modelHeight = TILE_SIZE -- fallback
	if model and model:IsA("Model") then
		local size = model:GetExtentsSize()
		modelHeight = size.Y
	end
	node.ItemY = FLOOR_Y + modelHeight + 0.5

	ResolveLinks(node)
	RefreshNeighborEndpoints(gx, gz)

	print(string.format("[ConveyorService] Registered %s at (%d,%d) dir=%d speed=%g", buildingName, gx, gz, dir, speed))
end

function ConveyorService:_UnregisterNode(gx, gz)
	local key = NodeKey(gx, gz)
	local node = _nodes[key]
	if not node then
		return
	end

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
		Model = model,
		BuildingName = buildingName,
		Team = team,
		GX = gx,
		GZ = gz,
		SizeX = sizeX,
		SizeZ = sizeZ,
	}
	-- Index every tile in the footprint
	for tx = gx, gx + sizeX - 1 do
		for tz = gz, gz + sizeZ - 1 do
			_producers[NodeKey(tx, tz)] = entry
		end
	end

	print(
		string.format(
			"[ConveyorService] Registered producer %s at (%d,%d) size (%d,%d) of team %s",
			buildingName,
			gx,
			gz,
			sizeX,
			sizeZ,
			team
		)
	)

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
		Model = model,
		BuildingName = buildingName,
		Team = team,
		GX = gx,
		GZ = gz,
		SizeX = sizeX,
		SizeZ = sizeZ,
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

function ConveyorService:_TryPush(targetNode, item)
	if #targetNode.Buffer >= targetNode.BufferMax then
		return false
	end

	-- keep item's actual current world position
	local actualX = item.PosX
	local actualZ = item.PosZ

	local overflow = math.max(0, item.Progress - 1)
	item.Progress = overflow
	item.CurrentNode = targetNode

	-- where the center line expects the item to be at this progress
	local off = DIR_OFFSET[targetNode.Dir]
	local cx, _, cz = TileWorldCenter(targetNode.GX, targetNode.GZ, targetNode.ItemY)
	local centerX = cx - off.dx * TILE_SIZE / 2 + off.dx * overflow * TILE_SIZE
	local centerZ = cz - off.dz * TILE_SIZE / 2 + off.dz * overflow * TILE_SIZE

	-- offset is difference between actual position and center line
	item.OffsetX = actualX - centerX
	item.OffsetZ = actualZ - centerZ
	item.OffsetProgress = 0

	-- don't move the part — it stays exactly where it is
	table.insert(targetNode.Buffer, item)
	return true
end

-- Register a delivery callback for a consumer building model.
-- callback(resourceId, amount) should return true if the item was accepted,
-- false if the building's input buffer is full (item stays on conveyor).
function ConveyorService:RegisterConsumerCallback(model, callback)
	_consumerCallbacks[model] = callback
end

function ConveyorService:UnregisterConsumerCallback(model)
	_consumerCallbacks[model] = nil
end

function ConveyorService:_OnBuildingReceive(consumerEntry, item)
	local cb = _consumerCallbacks[consumerEntry.Model]
	if cb then
		return cb(item.ResourceId, item.Amount)
	end
	return false
end

function ConveyorService:_DeliverToConsumer(consumerEntry, item)
	if BuildingConfig.GetCategory(consumerEntry.BuildingName) == Categories.Core then
		if item.Part then
			item.Part:Destroy()
			item.Part = nil
		end
		self.ResourceService:Add(consumerEntry.Team, item.ResourceId, item.Amount)
		return true
	else
		local accepted = self:_OnBuildingReceive(consumerEntry, item)
		if accepted then
			if item.Part then
				item.Part:Destroy()
				item.Part = nil
			end
		end
		return accepted
	end
end

function ConveyorService:_AdvanceItem(node, item, dt)
	local speed = node.Speed
	item.Progress = item.Progress + speed * dt

	-- lateral correction catches up at same rate as forward movement
	item.OffsetProgress = math.min(1, item.OffsetProgress + speed * dt)
	local lateralFactor = 1 - item.OffsetProgress -- eases to 0

	local off = DIR_OFFSET[node.Dir]
	local cx, _, cz = TileWorldCenter(node.GX, node.GZ, node.ItemY)
	local forwardX = cx - off.dx * TILE_SIZE / 2 + off.dx * item.Progress * TILE_SIZE
	local forwardZ = cz - off.dz * TILE_SIZE / 2 + off.dz * item.Progress * TILE_SIZE

	item.PosX = forwardX + item.OffsetX * lateralFactor
	item.PosZ = forwardZ + item.OffsetZ * lateralFactor

	if item.Part then
		item.Part.Position = Vector3.new(item.PosX, node.ItemY, item.PosZ)
	end

	return item.Progress >= 1
end

function ConveyorService:_TryHandoff(node, item)
	-- try next conveyor
	if node.OutputNode then
		if self:_TryPush(node.OutputNode, item) then
			table.remove(node.Buffer, 1)
			return true
		else
			-- backpressure: clamp to front edge
			item.Progress = 1
			return false
		end
	end

	-- try consumer
	local outX, outZ = GetOutputTile(node.GX, node.GZ, node.Dir)
	local consumerEntry = _consumers[NodeKey(outX, outZ)]
	if consumerEntry then
		if self:_DeliverToConsumer(consumerEntry, item) then
			table.remove(node.Buffer, 1)
			return true
		end
	end

	-- stuck: clamp
	item.Progress = 1
	return false
end

function ConveyorService:_Tick(dt)
	for _, node in pairs(_nodes) do
		local i = 1
		while i <= #node.Buffer do
			local item = node.Buffer[i]

			local maxProgress = 1
			if i > 1 then
				maxProgress = math.min(1, node.Buffer[i - 1].Progress - 0.3)
			end

			if item.Progress >= 1 then
				-- already at front, retry handoff every tick
				self:_TryHandoff(node, item)
			elseif item.Progress < maxProgress then
				self:_AdvanceItem(node, item, dt)

				if item.Progress > maxProgress then
					item.Progress = maxProgress
					local off = DIR_OFFSET[node.Dir]
					local cx, _, cz = TileWorldCenter(node.GX, node.GZ, node.ItemY)
					local lateralFactor = 1 - math.min(1, item.OffsetProgress)
					item.PosX = cx
						- off.dx * TILE_SIZE / 2
						+ off.dx * item.Progress * TILE_SIZE
						+ item.OffsetX * lateralFactor
					item.PosZ = cz
						- off.dz * TILE_SIZE / 2
						+ off.dz * item.Progress * TILE_SIZE
						+ item.OffsetZ * lateralFactor
					if item.Part then
						item.Part.Position = Vector3.new(item.PosX, node.ItemY, item.PosZ)
					end
				end

				if item.Progress >= 1 then
					self:_TryHandoff(node, item)
				end
			end
			i += 1
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
	if not edges then
		return false
	end

	for _, node in ipairs(edges) do
		local sx, sy, sz = ItemStartPos(node)
		local part = SpawnItemPart(resourceId, sx, sy, sz)
		local item = {
			ResourceId = resourceId,
			Amount = amount,
			Part = part,
			Progress = 0,
			PosX = sx,
			PosZ = sz,
			OffsetX = 0, -- add these
			OffsetZ = 0,
			OffsetProgress = 1, -- already aligned on spawn
			CurrentNode = node,
		}

		if self:_TryPush(node, item) then
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
	if not edges or #edges == 0 then
		return false, outputIndex
	end

	local count = #edges
	for i = 0, count - 1 do
		local idx = ((outputIndex - 1 + i) % count) + 1
		local node = edges[idx]

		local sx, sy, sz = ItemStartPos(node)
		local part = SpawnItemPart(resourceId, sx, sy, sz)
		local item = {
			ResourceId = resourceId,
			Amount = amount,
			Part = part,
			Progress = 0,
			PosX = sx,
			PosZ = sz,
			OffsetX = 0, -- add these
			OffsetZ = 0,
			OffsetProgress = 1, -- already aligned on spawn
			CurrentNode = node,
		}

		if self:_TryPush(node, item) then
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
	if not edges or #edges == 0 then
		return true
	end
	for _, node in ipairs(edges) do
		if #node.Buffer < node.BufferMax then
			return false
		end
	end
	return true
end

-- Called by FactoryService to pull one unit of a specific resource from input conveyors.
-- Returns { ResourceId, Amount } or nil.
function ConveyorService:ConsumerPull(consumerModel, resourceId)
	local edges = _consumerEdges[consumerModel]
	if not edges then
		return nil
	end
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
	if not edges then
		return false
	end
	for _, node in ipairs(edges) do
		for _, item in ipairs(node.Buffer) do
			if item.ResourceId == resourceId then
				return true
			end
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
	end
	if BuildingConfig.OutputsResources(buildingName) then
		ConveyorService:_RegisterProducer(model, buildingName, team, gx, gz, sizeX, sizeZ)
	end
	if BuildingConfig.AcceptsResourceInput(buildingName) then
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
	self.BuildingService = Knit.GetService("BuildingService")
	self.StructureService = Knit.GetService("StructureService")
	self.ResourceService = Knit.GetService("ResourceService")
end

function ConveyorService:KnitStart()
	_itemFolder = Instance.new("Folder")
	_itemFolder.Name = "ConveyorItems"
	_itemFolder.Parent = workspace

	self.BuildingService.BuildingPlaced.Event:Connect(OnBuildingPlaced)
	self.BuildingService.BuildingDemolished.Event:Connect(OnBuildingDemolished)
	self.StructureService.StructureDestroyed.Event:Connect(OnStructureDestroyed)

	game:GetService("RunService").Heartbeat:Connect(function(dt)
		self:_Tick(dt)
	end)

	print("[ConveyorService] Started")
end

return ConveyorService
