local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

local DataServiceTemplate = require(ServerScriptService.Modules.DataServiceTemplate)

local DataService = require(ReplicatedStorage.Packages.DataService).server

DataService:init(DataServiceTemplate)
