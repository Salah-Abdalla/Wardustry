-- ResourceController
-- Knit Controller — displays the local player's team resources in the HUD
-- Place in StarterPlayerScripts

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local LocalPlayer = Players.LocalPlayer

local Knit = require(ReplicatedStorage.Packages.Knit)
local ResourceConfig = require(ReplicatedStorage.Config.ResourceConfig)

local PlayerGui = LocalPlayer.PlayerGui
local GameGui = PlayerGui:WaitForChild("GameGui")

local ResourceHolder = GameGui.ResourceHolder
local ScrollingFrame = ResourceHolder.ScrollingFrame
local Template = ScrollingFrame.Template

-- ─────────────────────────────────────────────────────────────────
local ResourceController = Knit.CreateController({ Name = "ResourceController" })

local _resourceService = nil
local _entries = {} -- [resourceId] = cloned Frame

-- ─────────────────────────────────────────────────────────────────
--  INTERNAL
-- ─────────────────────────────────────────────────────────────────

local function GetOrCreateEntry(resourceId)
	if _entries[resourceId] then
		return _entries[resourceId]
	end

	local entry = Template:Clone()
	entry.Name = resourceId

	print(resourceId)

	if ResourceConfig.GetIconId(resourceId) ~= 0 then
		entry.Icon.Image = "rbxassetid://" .. ResourceConfig.GetIconId(resourceId)
	else
		entry.Icon.FallBackName.Text = ResourceConfig.GetDisplayName(resourceId)
	end
	entry.Amount.Text = "0"
	entry.Visible = true
	entry.Parent = ScrollingFrame
	entry.LayoutOrder = ResourceConfig.GetLayoutOrder(resourceId) or 0

	_entries[resourceId] = entry
	return entry
end

local function UpdateEntry(resourceId, amount)
	local entry = GetOrCreateEntry(resourceId)
	entry.Amount.Text = tostring(amount)
	--entry.Visible = amount > 0
end

-- ─────────────────────────────────────────────────────────────────
--  LIFECYCLE
-- ─────────────────────────────────────────────────────────────────

function ResourceController:KnitStart()
	_resourceService = Knit.GetService("ResourceService")

	-- Populate with current amounts
	_resourceService:GetMyResources():andThen(function(resources)
		print(resources)
		for resourceId, amount in pairs(resources) do
			UpdateEntry(resourceId, amount)
		end
	end)

	-- Live updates — only process changes for the local player's team
	_resourceService.ResourceChanged:Connect(function(team, resourceId, newAmount)
		if team == LocalPlayer:GetAttribute("TeamColor") then
			UpdateEntry(resourceId, newAmount)
		end
	end)
end

function ResourceController:KnitInit() end

return ResourceController
