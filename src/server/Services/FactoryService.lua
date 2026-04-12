-- FactoryService
-- Knit Service — receives inputs via ConveyorService delivery callbacks,
-- processes recipes, and pushes output round-robin to output conveyors.

local Knit = require(game:GetService("ReplicatedStorage").Packages.Knit)
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local BuildingConfig = require(ReplicatedStorage.Config.BuildingConfig)
local FactoryConfig  = require(ReplicatedStorage.Config.FactoryConfig)
local Categories     = require(ReplicatedStorage.Dictionaries.Categories)

local FactoryService = Knit.CreateService({
	Name = "FactoryService",
	Client = {
		-- Fires every CLIENT_INTERVAL to all clients:
		-- (model, { Name, Team, Output, OutputBuffer, InputBuffers, ProcessTimer })
		FactoryStateChanged = Knit.CreateSignal(),
	},
})

-- ════════════════════════════════════════
--  CONSTANTS
-- ════════════════════════════════════════

local TICK_INTERVAL   = 0.1  -- 10 Hz processing tick
local CLIENT_INTERVAL = 0.5  -- broadcast rate to clients

-- ════════════════════════════════════════
--  STATE
-- ════════════════════════════════════════

-- _factories[model] = FactoryState
local _factories = {}

-- ════════════════════════════════════════
--  INTERNAL HELPERS
-- ════════════════════════════════════════

local function BuildSnapshot(factory)
	return {
		Name         = factory.BuildingName,
		Team         = factory.Team,
		Output       = factory.Output,
		OutputBuffer = factory.OutputBuffer,
		InputBuffers = table.clone(factory.InputBuffers),
		ProcessTimer = factory.ProcessTimer,
	}
end

-- ════════════════════════════════════════
--  ITEM DELIVERY (called by ConveyorService)
-- ════════════════════════════════════════

-- Returns true if the item was accepted (added to input buffer),
-- false if the buffer is full (item stays on the conveyor).
function FactoryService:_ReceiveItem(model, resourceId, amount)
	local factory = _factories[model]
	if not factory then return false end

	local current = factory.InputBuffers[resourceId]
	if current == nil then return false end

	local cap = FactoryConfig.GetInputCapacity(factory.BuildingName, resourceId)
	if current >= cap then return false end

	factory.InputBuffers[resourceId] = math.min(current + amount, cap)
	return true
end

-- ════════════════════════════════════════
--  REGISTRATION
-- ════════════════════════════════════════

function FactoryService:_RegisterFactory(model, buildingName, team, gx, gz, sx, sz)
	local inputs = FactoryConfig.GetInputs(buildingName)
	if not inputs then
		warn("[FactoryService] No inputs found for", buildingName)
		return
	end

	local buffers = {}
	for res in pairs(inputs) do
		buffers[res] = 0
	end

	_factories[model] = {
		Model         = model,
		BuildingName  = buildingName,
		Team          = team,
		GX = gx, GZ = gz, SizeX = sx, SizeZ = sz,

		InputBuffers  = buffers,
		Output        = FactoryConfig.GetOutput(buildingName),
		OutputAmount  = FactoryConfig.GetOutputAmount(buildingName),
		OutputBuffer  = 0,
		OutputMax     = FactoryConfig.GetOutputCapacity(buildingName),

		Processing    = false,
		ProcessTimer  = 0,
		ProcessingTime = FactoryConfig.GetProcessingTime(buildingName),

		OutputIndex   = 1,
	}

	-- Register delivery callback with ConveyorService
	self.ConveyorService:RegisterConsumerCallback(model, function(resourceId, amount)
		return self:_ReceiveItem(model, resourceId, amount)
	end)

	print(string.format(
		"[FactoryService] Registered %s at (%d,%d) output=%s",
		buildingName, gx, gz, tostring(FactoryConfig.GetOutput(buildingName))
	))
end

function FactoryService:_UnregisterFactory(model)
	self.ConveyorService:UnregisterConsumerCallback(model)
	_factories[model] = nil
end

-- ════════════════════════════════════════
--  TICK
-- ════════════════════════════════════════

function FactoryService:_Tick(dt)
	for model, factory in pairs(_factories) do

		-- ── Phase 1: Advance processing ──────────────────────────────────
		if not factory.Processing then
			local outputRoom = factory.OutputBuffer + factory.OutputAmount <= factory.OutputMax
			if outputRoom and FactoryConfig.CanProduce(factory.BuildingName, factory.InputBuffers) then
				local inputs = FactoryConfig.GetInputs(factory.BuildingName)
				for res, data in pairs(inputs) do
					factory.InputBuffers[res] -= data.Amount
				end
				factory.Processing   = true
				factory.ProcessTimer = factory.ProcessingTime
			end
		else
			factory.ProcessTimer -= dt
			if factory.ProcessTimer <= 0 then
				factory.OutputBuffer += factory.OutputAmount
				factory.Processing   = false
				factory.ProcessTimer = 0
			end
		end

		-- ── Phase 2: Flush output round-robin ────────────────────────────
		if factory.Output then
			while factory.OutputBuffer >= 1 do
				local pushed, newIdx = self.ConveyorService:ProducerPushRoundRobin(
					model, factory.Output, 1, factory.OutputIndex
				)
				if pushed then
					factory.OutputBuffer -= 1
					factory.OutputIndex   = newIdx
				else
					break
				end
			end
		end
	end
end

-- ════════════════════════════════════════
--  CLIENT BROADCAST
-- ════════════════════════════════════════

function FactoryService:_BroadcastState()
	for model, factory in pairs(_factories) do
		self.Client.FactoryStateChanged:FireAll(model, BuildSnapshot(factory))
	end
end

-- ════════════════════════════════════════
--  EVENT HANDLERS
-- ════════════════════════════════════════

local function OnBuildingPlaced(model, buildingName, team, gx, gz, sizeX, sizeZ, _rotY)
	if BuildingConfig.GetCategory(buildingName) == Categories.Factory then
		FactoryService:_RegisterFactory(model, buildingName, team, gx, gz, sizeX, sizeZ)
	end
end

local function OnStructureDestroyed(structureObj)
	if _factories[structureObj.Model] then
		FactoryService:_UnregisterFactory(structureObj.Model)
	end
end

-- ════════════════════════════════════════
--  LIFECYCLE
-- ════════════════════════════════════════

function FactoryService:KnitInit()
	self.BuildingService  = Knit.GetService("BuildingService")
	self.ConveyorService  = Knit.GetService("ConveyorService")
	self.StructureService = Knit.GetService("StructureService")
end

function FactoryService:KnitStart()
	self.BuildingService.BuildingPlaced.Event:Connect(OnBuildingPlaced)
	self.StructureService.StructureDestroyed.Event:Connect(OnStructureDestroyed)

	-- Processing tick
	task.spawn(function()
		while true do
			task.wait(TICK_INTERVAL)
			self:_Tick(TICK_INTERVAL)
		end
	end)

	-- Client broadcast tick
	task.spawn(function()
		while true do
			task.wait(CLIENT_INTERVAL)
			self:_BroadcastState()
		end
	end)

	print("[FactoryService] Started")
end

return FactoryService
