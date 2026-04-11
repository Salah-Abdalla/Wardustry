local Knit = require(game:GetService("ReplicatedStorage").Packages.Knit)

local Player = game:GetService("Players").LocalPlayer
local ControllersFolder = script.Parent.Controllers

require(ControllersFolder.BuildController)
require(ControllersFolder.ResourceController)

Knit.Start():catch(warn)
