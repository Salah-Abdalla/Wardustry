local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

local DataServiceTemplate = require(ServerScriptService.Modules.DataServiceTemplate)
local CampaignService = require(ServerScriptService.Services.CampaignService)

local DataService = require(ReplicatedStorage.Packages.DataService).server

DataService:init(DataServiceTemplate)

CampaignService.LoadCampaign("Testing Sector")
