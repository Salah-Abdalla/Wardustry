local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Knit = require(ReplicatedStorage.Packages.Knit)

local ServicesFolder = game:GetService("ServerScriptService").Services

require(ServicesFolder.GridService)
require(ServicesFolder.ResourceService)
require(ServicesFolder.StructureService)
require(ServicesFolder.TeamService)
require(ServicesFolder.CoreService)
require(ServicesFolder.BuildingService)
require(ServicesFolder.CampaignService)

Knit.Start():catch(warn)
