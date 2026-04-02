-- TeamService
-- Knit Service — manages team registration, player assignment, and core association
-- Place in ServerScriptService/Services

local Knit = require(game:GetService("ReplicatedStorage").Packages.Knit)
local Players = game:GetService("Players")

local TeamService = Knit.CreateService({
	Name = "TeamService",
	Client = {},
})

-- ── Internal storage ──
-- _teams[teamColor] = {
--     Players = { [player] = true },
--     Core    = coreObject | nil,
-- }
local _teams = {}

-- ════════════════════════════════════════
--  INTERNAL
-- ════════════════════════════════════════

local function EnsureTeam(teamColor)
	if not _teams[teamColor] then
		warn("[TeamService] Team '" .. tostring(teamColor) .. "' does not exist. Call CreateTeam first.")
		return false
	end
	return true
end

-- ════════════════════════════════════════
--  PUBLIC API
-- ════════════════════════════════════════

-- Register a new team by color string
function TeamService:CreateTeam(teamColor)
	if _teams[teamColor] then
		warn("[TeamService] Team '" .. teamColor .. "' already exists.")
		return
	end
	_teams[teamColor] = {
		Players = {},
		Core = nil,
	}
	print("[TeamService] Created team: " .. teamColor)
end

-- Add a player to a team
-- Removes them from their current team first if already assigned
function TeamService:AddPlayerToTeam(player, teamColor)
	if not EnsureTeam(teamColor) then
		return
	end

	-- remove from existing team first
	local current = self:GetPlayerTeam(player)
	if current then
		self:RemovePlayerFromTeam(player, current)
	end

	_teams[teamColor].Players[player] = true
	print("[TeamService] " .. player.Name .. " → " .. teamColor)
end
-- Remove a player from a team
function TeamService:RemovePlayerFromTeam(player, teamColor)
	if not EnsureTeam(teamColor) then
		return
	end
	if not _teams[teamColor].Players[player] then
		warn("[TeamService] " .. player.Name .. " is not in team " .. teamColor)
		return
	end
	_teams[teamColor].Players[player] = nil
end

-- Associate a Core object with a team
function TeamService:SetCoreToTeam(core, teamColor)
	if not EnsureTeam(teamColor) then
		return
	end
	_teams[teamColor].Core = core
end

-- Remove the Core association from a team (e.g. on Core destroyed)
function TeamService:RemoveCoreFromTeam(teamColor)
	if not EnsureTeam(teamColor) then
		return
	end
	_teams[teamColor].Core = nil
end

-- Get all players on a team as an array
function TeamService:GetPlayersFromTeam(teamColor)
	if not EnsureTeam(teamColor) then
		return {}
	end
	local list = {}
	for player in pairs(_teams[teamColor].Players) do
		table.insert(list, player)
	end
	return list
end

-- Check if a specific player is on a specific team
function TeamService:IsPlayerInTeam(player, teamColor)
	if not EnsureTeam(teamColor) then
		return false
	end
	return _teams[teamColor].Players[player] == true
end

-- Get the team color a player belongs to, or nil if unassigned
function TeamService:GetPlayerTeam(player)
	for teamColor, data in pairs(_teams) do
		if data.Players[player] then
			return teamColor
		end
	end
	return nil
end

-- Get the Core object associated with a team
function TeamService:GetTeamCore(teamColor)
	if not EnsureTeam(teamColor) then
		return nil
	end
	return _teams[teamColor].Core
end

-- Get all registered team color strings
function TeamService:GetAllTeams()
	local list = {}
	for teamColor in pairs(_teams) do
		table.insert(list, teamColor)
	end
	return list
end

-- ════════════════════════════════════════
--  LIFECYCLE
-- ════════════════════════════════════════

function TeamService:KnitInit()
	-- Auto-remove players from their team when they leave the game
	Players.PlayerRemoving:Connect(function(player)
		local teamColor = self:GetPlayerTeam(player)
		if teamColor then
			self:RemovePlayerFromTeam(player, teamColor)
			print("[TeamService] " .. player.Name .. " left, removed from " .. teamColor)
		end
	end)
end

function TeamService:KnitStart()
	print("[TeamService] Started")
end

return TeamService
