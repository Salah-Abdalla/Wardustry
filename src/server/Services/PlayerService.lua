-- PlayerService.lua
local Knit = require(game.ReplicatedStorage.Packages.Knit)
local Players = game:GetService("Players")

local PlayerService = Knit.CreateService {
    Name = "PlayerService",
    Client = {},
}

local Registry = {}
-- Registry[player] = {
--     TeamColor = BrickColor or nil,
-- }

-- ============================================================
-- INTERNAL
-- ============================================================

local function OnPlayerAdded(player)
    Registry[player] = {
        TeamColor = nil,
    }
end

local function OnPlayerRemoving(player)
    Registry[player] = nil
end

-- ============================================================
-- PUBLIC
-- ============================================================

function PlayerService:GetAll()
    local players = {}
    for player in pairs(Registry) do
        table.insert(players, player)
    end
    return players
end

function PlayerService:IsRegistered(player)
    return Registry[player] ~= nil
end

function PlayerService:SetTeamColor(player, color)
    if not Registry[player] then
        warn("PlayerService.SetTeamColor: player not registered ->", player.Name)
        return
    end
    Registry[player].TeamColor = color
end

function PlayerService:GetTeamColor(player)
    if not Registry[player] then
        warn("PlayerService.GetTeamColor: player not registered ->", player.Name)
        return nil
    end
    return Registry[player].TeamColor
end

function PlayerService:GetPlayersByTeam(color)
    local players = {}
    for player, data in pairs(Registry) do
        if data.TeamColor == color then
            table.insert(players, player)
        end
    end
    return players
end

function PlayerService:GetAllTeamColors()
    local colors = {}
    local seen = {}
    for _, data in pairs(Registry) do
        if data.TeamColor and not seen[data.TeamColor] then
            seen[data.TeamColor] = true
            table.insert(colors, data.TeamColor)
        end
    end
    return colors
end

-- ============================================================
-- CLIENT
-- ============================================================

function PlayerService.Client:GetMyTeamColor(player)
    return PlayerService:GetTeamColor(player)
end

-- ============================================================
-- KNIT
-- ============================================================

function PlayerService:KnitInit()
    Players.PlayerAdded:Connect(OnPlayerAdded)
    Players.PlayerRemoving:Connect(OnPlayerRemoving)

    -- register any players already in server (edge case)
    for _, player in ipairs(Players:GetPlayers()) do
        OnPlayerAdded(player)
    end
end

function PlayerService:KnitStart()
end

return PlayerService