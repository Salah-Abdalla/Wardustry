local DataServiceModule = {}

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local DataService = require(ReplicatedStorage.Packages.DataService).server

-- Profile
function DataServiceModule.GetLevel(player: Player): number
	return DataService:get(player, { "Profile", "Level" })
end

function DataServiceModule.SetLevel(player: Player, value: number)
	DataService:set(player, { "Profile", "Level" }, value)
end

function DataServiceModule.GetXP(player: Player): number
	return DataService:get(player, { "Profile", "XP" })
end

function DataServiceModule.SetXP(player: Player, value: number)
	DataService:set(player, { "Profile", "XP" }, value)
end

function DataServiceModule.GetGems(player: Player): number
	return DataService:get(player, { "Profile", "Gems" })
end

function DataServiceModule.SetGems(player: Player, value: number)
	DataService:set(player, { "Profile", "Gems" }, value)
end

-- Settings
function DataServiceModule.GetSFX(player: Player): number
	return DataService:get(player, { "Settings", "SFX" })
end

function DataServiceModule.SetSFX(player: Player, value: number)
	DataService:set(player, { "Settings", "SFX" }, value)
end

function DataServiceModule.GetMusic(player: Player): number
	return DataService:get(player, { "Settings", "Music" })
end

function DataServiceModule.SetMusic(player: Player, value: number)
	DataService:set(player, { "Settings", "Music" }, value)
end

-- Campaign: [sectorId] = starCount (nil = uncompleted)
function DataServiceModule.GetSectorStars(player: Player, sectorId: string): number?
	return DataService:get(player, { "Campaign", sectorId })
end

function DataServiceModule.SetSectorStars(player: Player, sectorId: string, starCount: number)
	DataService:set(player, { "Campaign", sectorId }, starCount)
end

function DataServiceModule.IsSectorCompleted(player: Player, sectorId: string): boolean
	return DataService:get(player, { "Campaign", sectorId }) ~= nil
end

function DataServiceModule.GetCampaign(player: Player): { [string]: number }
	return DataService:get(player, { "Campaign" })
end

-- Resources: [id] = amount
function DataServiceModule.GetResource(player: Player, id: string): number
	return DataService:get(player, { "Resources", id }) or 0
end

function DataServiceModule.SetResource(player: Player, id: string, amount: number)
	DataService:set(player, { "Resources", id }, amount)
end

function DataServiceModule.GetResources(player: Player): { [string]: number }
	return DataService:get(player, { "Resources" })
end

-- Research: [itemId] = true/false/nil
function DataServiceModule.IsResearched(player: Player, itemId: string): boolean
	return DataService:get(player, { "Research", itemId }) == true
end

function DataServiceModule.SetResearched(player: Player, itemId: string, value: boolean?)
	DataService:set(player, { "Research", itemId }, value)
end

function DataServiceModule.GetResearch(player: Player): { [string]: boolean }
	return DataService:get(player, { "Research" })
end

-- Quests
function DataServiceModule.GetCompletedQuests(player: Player): { any }
	return DataService:get(player, { "Quests", "Completed" })
end

function DataServiceModule.GetActiveQuests(player: Player): { any }
	return DataService:get(player, { "Quests", "Active" })
end

function DataServiceModule.GetDailyReset(player: Player): number
	return DataService:get(player, { "Quests", "DailyReset" })
end

function DataServiceModule.SetDailyReset(player: Player, value: number)
	DataService:set(player, { "Quests", "DailyReset" }, value)
end

function DataServiceModule.GetWeeklyReset(player: Player): number
	return DataService:get(player, { "Quests", "WeeklyReset" })
end

function DataServiceModule.SetWeeklyReset(player: Player, value: number)
	DataService:set(player, { "Quests", "WeeklyReset" }, value)
end

return DataServiceModule
