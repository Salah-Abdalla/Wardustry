-- CampaignService
-- Knit Service — orchestrates sector loading, team setup, and round initialization
-- Place in ServerScriptService/Services

local Knit = require(game:GetService("ReplicatedStorage").Packages.Knit)
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local SectorLoader = require(game.ServerScriptService.Services.SectorLoader) -- adjust path as needed

local CampaignService = Knit.CreateService({
	Name = "CampaignService",
	Client = {},
})

-- resolved in KnitStart
local GridService
local TeamService
local CoreService
local ResourceService

-- ════════════════════════════════════════
--  MAIN LOAD
-- ════════════════════════════════════════

function CampaignService:LoadCampaign(sectorName)
	print("[CampaignService] Loading campaign:", sectorName)

	-- populate grid service with sector tile data
	local gridOk, gridErr = GridService:LoadFromSector(sectorName)
	if not gridOk then
		warn("[CampaignService] GridService failed to load sector:", gridErr)
		return
	end

	-- build the 3D world from sector data
	local ok, result = SectorLoader.Load(sectorName)
	if not ok then
		warn("[CampaignService] SectorLoader failed:", result)
		return
	end

	-- create a team and core for each core in the sector
	for _, coreData in ipairs(result.Cores) do
		local teamColor = coreData.TeamColor
		print(coreData)
		TeamService:CreateTeam(teamColor)

		print(result)

		ResourceService:InitTeam(teamColor, result.StartingResources and result.StartingResources[teamColor])
		CoreService:CreateCore(coreData.CoreName, coreData.Model, teamColor)
	end

	-- assign all current players to the first team
	-- TODO: replace with proper team assignment (lobby selection, PVP balancing, etc.)
	local firstTeam = result.Cores[1] and result.Cores[1].TeamColor
	if firstTeam then
		for _, player in ipairs(Players:GetPlayers()) do
			TeamService:AddPlayerToTeam(player, firstTeam)
		end
		Players.PlayerAdded:Connect(function(player)
			TeamService:AddPlayerToTeam(player, firstTeam)
		end)
	end

	print(
		string.format(
			"[CampaignService] Campaign '%s' loaded — %d teams, %d spawn points",
			sectorName,
			#result.Cores,
			#result.SpawnPoints
		)
	)
end

-- ════════════════════════════════════════
--  LIFECYCLE
-- ════════════════════════════════════════

function CampaignService:KnitInit() end

function CampaignService:KnitStart()
	GridService = Knit.GetService("GridService")
	TeamService = Knit.GetService("TeamService")
	CoreService = Knit.GetService("CoreService")
	ResourceService = Knit.GetService("ResourceService")

	-- TODO: replace with actual campaign/sector selection system
	self:LoadCampaign("Testing Sector")
end

return CampaignService
