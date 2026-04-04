local Knit = require(game:GetService("ReplicatedStorage").Packages.Knit)

local Player = game:GetService("Players").LocalPlayer
local ControllersFolder = script.Parent.Controllers

require(ControllersFolder.BuildController)

Knit.Start():catch(warn)
