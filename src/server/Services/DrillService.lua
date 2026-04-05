-- DrillService
-- Knit Service — mines ores at rate from DrillConfig, buffers items, flushes round-robin to conveyors

local Knit             = require(game:GetService("ReplicatedStorage").Packages.Knit)
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local BuildingConfig  = require(ReplicatedStorage.Config.BuildingConfig)
local DrillConfig     = require(ReplicatedStorage.Config.DrillConfig)
local ResourceConfig  = require(ReplicatedStorage.Config.ResourceConfig)
local Categories      = require(ReplicatedStorage.Dictionaries.Categories)

local DrillService = Knit.CreateService({ Name = "DrillService", Client = {} })

-- ════════════════════════════════════════
--  CONSTANTS
-- ════════════════════════════════════════

local TICK_INTERVAL = 0.1 -- 10 Hz

-- ════════════════════════════════════════
--  STATE
-- ════════════════════════════════════════

-- _drills[model] = DrillState
local _drills = {}

-- ════════════════════════════════════════
--  INTERNAL HELPERS
-- ════════════════════════════════════════

-- Scan the drill's footprint and return the highest-value ore the drill can mine.
local function FindTargetOre(buildingName, gx, gz, sizeX, sizeZ, gridService)
	local candidates = {}
	for tx = gx, gx + sizeX - 1 do
		for tz = gz, gz + sizeZ - 1 do
			local oreId = gridService:GetOre(tx, tz)
			if oreId and DrillConfig.CanMineOre(buildingName, oreId) then
				candidates[oreId] = true
			end
		end
	end
	return ResourceConfig.GetHighestValueOre(candidates)
end

-- Return items/sec for this drill on its target ore.
-- Phase 1: no water, treat as fully powered so rate equals the configured base.
local function ComputeRate(buildingName, oreId)
	local power = DrillConfig.GetPowerNeeded(buildingName)
	return DrillConfig.GetDrillRate(buildingName, oreId, 0, power)
end

-- ════════════════════════════════════════
--  REGISTRATION
-- ════════════════════════════════════════

function DrillService:_RegisterDrill(model, buildingName, team, gx, gz, sizeX, sizeZ)
	local targetOre = FindTargetOre(buildingName, gx, gz, sizeX, sizeZ, self.GridService)
	local rate      = targetOre and ComputeRate(buildingName, targetOre) or 0
	local bufMax    = BuildingConfig.GetItemCapacity(buildingName)

	_drills[model] = {
		Model        = model,
		BuildingName = buildingName,
		Team         = team,
		GX           = gx,
		GZ           = gz,
		SizeX        = sizeX,
		SizeZ        = sizeZ,
		TargetOre    = targetOre,
		Rate         = rate,
		AccumTime    = 0,
		Buffer       = 0,
		BufferMax    = math.max(1, bufMax),
		OutputIndex  = 1,
	}

	print(string.format("[DrillService] Registered %s at (%d,%d) ore=%s rate=%.2f/s buf=%d",
		buildingName, gx, gz, tostring(targetOre), rate, bufMax))
end

function DrillService:_UnregisterDrill(model)
	_drills[model] = nil
end

-- ════════════════════════════════════════
--  TICK
-- ════════════════════════════════════════

function DrillService:_Tick(dt)
	for model, drill in pairs(_drills) do
		if not drill.TargetOre or drill.Rate <= 0 then continue end

		-- Phase 1: mine into internal buffer
		drill.AccumTime += dt
		local interval = 1 / drill.Rate
		while drill.AccumTime >= interval and drill.Buffer < drill.BufferMax do
			drill.AccumTime -= interval
			drill.Buffer    += 1
		end
		-- Buffer full — stop banking time to prevent burst on unblock
		if drill.Buffer >= drill.BufferMax then
			drill.AccumTime = 0
		end

		-- Phase 2: flush buffer round-robin to output conveyors
		while drill.Buffer >= 1 do
			local pushed, newIdx = self.ConveyorService:ProducerPushRoundRobin(
				model, drill.TargetOre, 1, drill.OutputIndex
			)
			if pushed then
				drill.Buffer     -= 1
				drill.OutputIndex = newIdx
			else
				break -- all output conveyors full
			end
		end
	end
end

-- ════════════════════════════════════════
--  EVENT HANDLERS
-- ════════════════════════════════════════

local function OnBuildingPlaced(model, buildingName, team, gx, gz, sizeX, sizeZ, _rotY)
	if BuildingConfig.GetCategory(buildingName) == Categories.Drill then
		DrillService:_RegisterDrill(model, buildingName, team, gx, gz, sizeX, sizeZ)
	end
end

local function OnStructureDestroyed(structureObj)
	if _drills[structureObj.Model] then
		DrillService:_UnregisterDrill(structureObj.Model)
	end
end

-- ════════════════════════════════════════
--  LIFECYCLE
-- ════════════════════════════════════════

function DrillService:KnitInit()
	self.BuildingService  = Knit.GetService("BuildingService")
	self.ConveyorService  = Knit.GetService("ConveyorService")
	self.StructureService = Knit.GetService("StructureService")
	self.GridService      = Knit.GetService("GridService")
end

function DrillService:KnitStart()
	self.BuildingService.BuildingPlaced.Event:Connect(OnBuildingPlaced)
	self.StructureService.StructureDestroyed.Event:Connect(OnStructureDestroyed)

	task.spawn(function()
		while true do
			task.wait(TICK_INTERVAL)
			self:_Tick(TICK_INTERVAL)
		end
	end)

	print("[DrillService] Started")
end

return DrillService
