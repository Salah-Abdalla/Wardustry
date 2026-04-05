-- BuildingController
-- Knit Controller — handles building placement UI, ghost preview, staged placements, bulk confirm
-- Place in StarterPlayerScripts

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local CollectionService = game:GetService("CollectionService")

local Knit = require(ReplicatedStorage.Packages.Knit)
local BuildingConfig = require(ReplicatedStorage.Config.BuildingConfig)
local ResourceConfig = require(ReplicatedStorage.Config.ResourceConfig)
local GridClient = require(ReplicatedStorage.Modules.GridClient)

local LocalPlayer = Players.LocalPlayer
local PlayerGui = LocalPlayer.PlayerGui
local Camera = workspace.CurrentCamera

local GameGui = PlayerGui:WaitForChild("GameGui")

local BuildingTypeHolder = GameGui.BuildingTypeHolder
local BuildingTypeScrollingFrame = BuildingTypeHolder.ScrollingFrame

local BuildingHolder = GameGui.BuildingHolder
local BuildingScrollingFrame = BuildingHolder.ScrollingFrame

local BuildingSettings = GameGui.BuildingSettings
local ConfirmButton = BuildingSettings.ConfirmButton
local CancelButton = BuildingSettings.CancelButton
local RotateButton = BuildingSettings.RotateButton

local FLOOR_Y = 0.5
local TILE_SIZE = 4
local VALID_COLOR = Color3.fromHex("00FF00")
local INVALID_COLOR = Color3.fromHex("FF0000")
local STAGED_COLOR = Color3.fromHex("4488FF")
local GHOST_TRANSPARENCY = 0.5

local CategoryOrder = {
	"Transport",
	"Drill",
	"Factory",
	"Turret",
	"Power",
	"Unit Factory",
	"Storage",
	"Core",
}

local BuildingController = Knit.CreateController({ Name = "BuildingController" })

-- ── State ──
local _selectedBuilding = nil
local _ghostPart = nil
local _placementValid = false
local _currentRotation = 0
local _placementConn = nil
local _buildingService = nil

-- Staged placements: array of { BuildingName, WorldPosition, Rotation, GhostPart }
local _staged = {}

-- ════════════════════════════════════════
--  GHOST HELPERS
-- ════════════════════════════════════════

-- Adds a direction arrow to the top face of a ghost part
-- Arrow points toward the "output" side (positive Z of the part, before rotation)
local function AddDirectionArrow(part)
	local sg = Instance.new("SurfaceGui")
	sg.Name = "DirectionArrow"
	sg.Face = Enum.NormalId.Top
	sg.SizingMode = Enum.SurfaceGuiSizingMode.PixelsPerStud
	sg.PixelsPerStud = 20
	sg.AlwaysOnTop = false
	sg.Parent = part

	local label = Instance.new("TextLabel")
	label.Size = UDim2.fromScale(1, 1)
	label.BackgroundTransparency = 1
	label.Text = "▲"
	label.TextColor3 = Color3.fromHex("FFFFFF")
	label.TextScaled = true
	label.Font = Enum.Font.GothamBold
	label.Parent = sg

	local stroke = Instance.new("UIStroke")
	stroke.Color = Color3.fromHex("000000")
	stroke.Thickness = 2
	stroke.Parent = label
end

local function MakeGhostPart(buildingName, color)
	local configSize = BuildingConfig.GetSize(buildingName)
	local sizeX = (configSize and configSize.X or 1) * TILE_SIZE
	local sizeZ = (configSize and configSize.Y or 1) * TILE_SIZE
	local sizeY = TILE_SIZE

	local part = Instance.new("Part")
	part.Name = "GhostPreview"
	part.Size = Vector3.new(sizeX, sizeY, sizeZ)
	part.Anchored = true
	part.CanCollide = false
	part.CastShadow = false
	part.Color = color
	part.Transparency = GHOST_TRANSPARENCY
	part.Material = Enum.Material.SmoothPlastic
	part.Parent = workspace

	-- only add arrow if the building can rotate (conveyors, factories, etc.)
	if BuildingConfig.CanRotate(buildingName) then
		AddDirectionArrow(part)
	end

	return part
end

local function DestroyActiveGhost()
	if _ghostPart then
		_ghostPart:Destroy()
		_ghostPart = nil
	end
end

-- ════════════════════════════════════════
--  STAGED PLACEMENTS
-- ════════════════════════════════════════

local function GetStagedAtPart(part)
	for _, entry in ipairs(_staged) do
		if entry.GhostPart == part then
			return entry
		end
	end
	return nil
end

local function RemoveStaged(entry)
	for i, e in ipairs(_staged) do
		if e == entry then
			e.GhostPart:Destroy()
			table.remove(_staged, i)
			return
		end
	end
end

local function ClearAllStaged()
	for _, entry in ipairs(_staged) do
		entry.GhostPart:Destroy()
	end
	_staged = {}
end

local function StageCurrentPlacement()
	if not _placementValid or not _ghostPart or not _selectedBuilding then
		return
	end

	local pos = _ghostPart.CFrame.Position
	local rot = _currentRotation

	local stagedGhost = MakeGhostPart(_selectedBuilding, STAGED_COLOR)
	stagedGhost.CFrame = CFrame.new(pos) * CFrame.Angles(0, math.rad(rot), 0)

	table.insert(_staged, {
		BuildingName = _selectedBuilding,
		WorldPosition = pos,
		Rotation = rot,
		GhostPart = stagedGhost,
	})
end

-- ════════════════════════════════════════
--  RAYCAST
-- ════════════════════════════════════════

local function RaycastFloor()
	local mousePos = UserInputService:GetMouseLocation()
	local ray = Camera:ViewportPointToRay(mousePos.X, mousePos.Y)

	local floorParts = CollectionService:GetTagged("Floor")
	local params = RaycastParams.new()
	params.FilterType = Enum.RaycastFilterType.Include
	params.FilterDescendantsInstances = floorParts

	return workspace:Raycast(ray.Origin, ray.Direction * 1000, params)
end

local function RaycastStagedGhosts()
	local mousePos = UserInputService:GetMouseLocation()
	local ray = Camera:ViewportPointToRay(mousePos.X, mousePos.Y)

	local ghostParts = {}
	for _, entry in ipairs(_staged) do
		table.insert(ghostParts, entry.GhostPart)
	end
	if #ghostParts == 0 then
		return nil
	end

	local params = RaycastParams.new()
	params.FilterType = Enum.RaycastFilterType.Include
	params.FilterDescendantsInstances = ghostParts

	return workspace:Raycast(ray.Origin, ray.Direction * 1000, params)
end

-- ════════════════════════════════════════
--  PLACEMENT LOOP
-- ════════════════════════════════════════

local function StartPlacementLoop()
	if _placementConn then
		_placementConn:Disconnect()
	end

	_placementConn = RunService.RenderStepped:Connect(function()
		if not _ghostPart or not _selectedBuilding then
			return
		end

		local result = RaycastFloor()
		if not result then
			_ghostPart.Transparency = 1
			_placementValid = false
			return
		end

		local hitPos = result.Position
		local configSize = BuildingConfig.GetSize(_selectedBuilding)
		local modelSize = {
			X = configSize and configSize.X or 1,
			Z = configSize and configSize.Y or 1,
		}

		local snapped = GridClient.GetPlacementPosition(hitPos, modelSize)
		local posY = FLOOR_Y + _ghostPart.Size.Y / 2

		_ghostPart.CFrame = CFrame.new(snapped.X, posY, snapped.Z) * CFrame.Angles(0, math.rad(_currentRotation), 0)
		_ghostPart.Transparency = GHOST_TRANSPARENCY

		_placementValid = GridClient.IsValidPosition(hitPos, modelSize)

		-- also invalid if overlapping a staged ghost
		if _placementValid then
			local ghostCF = CFrame.new(snapped.X, posY, snapped.Z)
			local ghostSize = _ghostPart.Size
			for _, entry in ipairs(_staged) do
				local entryCF = entry.GhostPart.CFrame
				local entrySize = entry.GhostPart.Size
				local dx = math.abs(ghostCF.X - entryCF.X)
				local dz = math.abs(ghostCF.Z - entryCF.Z)
				if dx < (ghostSize.X + entrySize.X) / 2 and dz < (ghostSize.Z + entrySize.Z) / 2 then
					_placementValid = false
					break
				end
			end
		end

		_ghostPart.Color = _placementValid and VALID_COLOR or INVALID_COLOR
	end)
end

local function StopPlacementLoop()
	if _placementConn then
		_placementConn:Disconnect()
		_placementConn = nil
	end
end

-- ════════════════════════════════════════
--  ROTATION HELPER
-- ════════════════════════════════════════

local function Rotate()
	if not _selectedBuilding then
		return
	end
	if not BuildingConfig.CanRotate(_selectedBuilding) then
		return
	end
	_currentRotation = (_currentRotation + 90) % 360
	-- RotateButton shows a circular arrow icon — no directional meaning needed
	-- direction is communicated by the arrow on the ghost in the world
end

-- ════════════════════════════════════════
--  PLACEMENT MODE
-- ════════════════════════════════════════

local function EnterPlacementMode(buildingName)
	_selectedBuilding = buildingName
	_currentRotation = 0

	DestroyActiveGhost()
	_ghostPart = MakeGhostPart(buildingName, VALID_COLOR)

	BuildingSettings.Visible = true
	StartPlacementLoop()
end

local function ExitPlacementMode()
	StopPlacementLoop()
	DestroyActiveGhost()
	ClearAllStaged()
	_selectedBuilding = nil
	_placementValid = false
	_currentRotation = 0
	BuildingSettings.Visible = false
end

-- ════════════════════════════════════════
--  CONFIRM BULK
-- ════════════════════════════════════════

local function ConfirmPlacement()
	if #_staged == 0 then
		return
	end

	local requests = {}
	for _, entry in ipairs(_staged) do
		local configSize = BuildingConfig.GetSize(entry.BuildingName)
		local modelSize = {
			X = configSize and configSize.X or 1,
			Z = configSize and configSize.Y or 1,
		}
		if GridClient.IsValidPosition(entry.WorldPosition, modelSize) then
			table.insert(requests, {
				BuildingName = entry.BuildingName,
				WorldPosition = entry.WorldPosition,
				Rotation = entry.Rotation,
			})
		end
	end

	if #requests > 0 then
		_buildingService:PlaceBulk(requests)
	end

	ExitPlacementMode()
end

-- ════════════════════════════════════════
--  CLICK HANDLER
-- ════════════════════════════════════════

local function OnMouseClick()
	local stagedHit = RaycastStagedGhosts()
	if stagedHit then
		local entry = GetStagedAtPart(stagedHit.Instance)
		if entry then
			RemoveStaged(entry)
			return
		end
	end

	if _selectedBuilding and _placementValid then
		StageCurrentPlacement()
	end
end

-- ════════════════════════════════════════
--  UI BUILDERS
-- ════════════════════════════════════════

local function loadBuildingHolder(category)
	for _, frame in pairs(BuildingScrollingFrame:GetChildren()) do
		if frame:IsA("Frame") and frame.Name ~= "Template" then
			frame:Destroy()
		end
	end

	local BuildingList = BuildingConfig.GetByCategory(category)
	for i, building in pairs(BuildingList) do
		local newFrame = BuildingScrollingFrame.Template:Clone()
		newFrame.Visible = true
		newFrame.Name = building
		newFrame.LayoutOrder = i
		newFrame.Parent = BuildingScrollingFrame

		newFrame.Icon.Image = BuildingConfig.GetIcon(building) or "rbxassetid://0"
		newFrame.Title.Text = building

		local costFrame = newFrame.Cost
		for resource, amount in pairs(BuildingConfig.GetCost(building)) do
			local newCostIcon = costFrame.Template:Clone()
			newCostIcon.Visible = true
			newCostIcon.Parent = costFrame

			newCostIcon.Icon.Image = ResourceConfig.GetIconId(resource) or "rbxassetid://0"
			newCostIcon.Amount.Text = tostring(amount)

			if ResourceConfig.GetIconId(resource) == 0 then
				newCostIcon.Icon.FallBackName.Text = resource
			end
		end

		newFrame.Click.Activated:Connect(function()
			EnterPlacementMode(building)
		end)
	end

	local layout = BuildingScrollingFrame:FindFirstChildWhichIsA("UIListLayout")
		or BuildingScrollingFrame:FindFirstChildWhichIsA("UIGridLayout")
	if layout then
		BuildingScrollingFrame.CanvasSize = UDim2.new(0, 0, 0, layout.AbsoluteContentSize.Y + 2)
		layout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
			BuildingScrollingFrame.CanvasSize = UDim2.new(0, 0, 0, layout.AbsoluteContentSize.Y + 2)
		end)
	end
end

local function loadBuildingTypeHolder()
	for _, category in pairs(CategoryOrder) do
		local newButton = BuildingTypeScrollingFrame.Template:Clone()
		newButton.TextLabel.Text = category
		newButton.Visible = true
		newButton.Parent = BuildingTypeScrollingFrame

		newButton.Activated:Connect(function()
			loadBuildingHolder(category)
		end)
	end
end

-- ════════════════════════════════════════
--  INPUT
-- ════════════════════════════════════════

local function SetupInput()
	UserInputService.InputBegan:Connect(function(input, gpe)
		if gpe then
			return
		end

		if input.UserInputType == Enum.UserInputType.MouseButton1 and _selectedBuilding then
			OnMouseClick()
		end

		if input.KeyCode == Enum.KeyCode.R and _selectedBuilding then
			Rotate()
		end

		if input.KeyCode == Enum.KeyCode.Escape and _selectedBuilding then
			ExitPlacementMode()
		end
	end)
end

-- ════════════════════════════════════════
--  KNIT
-- ════════════════════════════════════════

function BuildingController:KnitInit() end

function BuildingController:KnitStart()
	_buildingService = Knit.GetService("BuildingService")

	GridClient.Init()

	ConfirmButton.Activated:Connect(ConfirmPlacement)
	CancelButton.Activated:Connect(ExitPlacementMode)
	RotateButton.Activated:Connect(Rotate)

	BuildingSettings.Visible = false

	loadBuildingTypeHolder()

	_buildingService.PlacementResult:Connect(function(success, message)
		if not success then
			warn("[BuildingController] Placement failed: " .. message)
		end
	end)

	SetupInput()
end

return BuildingController
