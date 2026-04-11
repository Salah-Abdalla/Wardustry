local ServerScriptService = game:GetService("ServerScriptService")
-- CoreService
-- Knit Service — manages Core structures, links them to teams, handles destruction
-- Place in ServerScriptService/Services

local ConveyorService = require(ServerScriptService.Services.ConveyorService)
local Knit = require(game:GetService("ReplicatedStorage").Packages.Knit)

local CoreService = Knit.CreateService({
	Name = "CoreService",
	Client = {
		CoreDestroyed = Knit.CreateSignal(), -- (teamColor)
	},
})

-- Server-side signal for CampaignService to listen to
CoreService.CoreDestroyed = Instance.new("BindableEvent") -- (teamColor)

local StructureService
local TeamService

-- ════════════════════════════════════════
--  PUBLIC API
-- ════════════════════════════════════════

-- Register a Core for a team
-- coreData = { TeamColor = string, Model = Model }
function CoreService:CreateCore(CoreName, model, teamColor, gx, gz, sizeX, sizeZ)
	print(CoreName, model, teamColor)

	if not teamColor or not model then
		warn("[CoreService] CreateCore: missing TeamColor or Model")
		return
	end

	-- Register with StructureService
	local structureObj = StructureService:Register(model, CoreName, teamColor)
	if not structureObj then
		warn("[CoreService] CreateCore: failed to register structure for team " .. teamColor)
		return
	end

	ConveyorService:_RegisterConsumer(model, CoreName, teamColor, gx, gz, sizeX, sizeZ)

	-- Link model to team in TeamService
	TeamService:SetCoreToTeam(structureObj, teamColor)

	print("[CoreService] Core created for team: " .. teamColor)
end

-- Get the structure object for a team's Core
function CoreService:GetCoreForTeam(teamColor)
	return TeamService:GetTeamCore(teamColor)
end

-- Get the structure object from a model — delegates to StructureService
function CoreService:GetCoreFromModel(model)
	return StructureService:GetStructureFromModel(model)
end

-- ════════════════════════════════════════
--  INTERNAL
-- ════════════════════════════════════════

-- Listen for any structure destruction and check if it was a Core
local function OnStructureDestroyed(structureObj)
	if structureObj.Type ~= "Core" then
		return
	end

	local teamColor = structureObj.Team

	-- Unlink from TeamService
	TeamService:RemoveCoreFromTeam(teamColor)

	-- Fire server and client signals
	CoreService.CoreDestroyed:Fire(teamColor)
	CoreService.Client.CoreDestroyed:FireAll(teamColor)

	print("[CoreService] Core destroyed for team: " .. teamColor)
end

-- ════════════════════════════════════════
--  LIFECYCLE
-- ════════════════════════════════════════

function CoreService:KnitInit()
	StructureService = Knit.GetService("StructureService")
	TeamService = Knit.GetService("TeamService")
end

function CoreService:KnitStart()
	StructureService.StructureDestroyed.Event:Connect(OnStructureDestroyed)
	print("[CoreService] Started")
end

return CoreService
