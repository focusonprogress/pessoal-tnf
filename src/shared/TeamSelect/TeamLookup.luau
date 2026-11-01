--[[
	Encontra os Teams do Studio a partir da configuração.
	Usado pelo servidor e pela tela.
]]

local Teams = game:GetService("Teams")

local Config = require(script.Parent.Config)

local TeamLookup = {}

-- Encontra um Team pelo nome (sem diferenciar maiúsculas de minúsculas).
function TeamLookup.FindTeam(teamName: string): Team?
	local exact = Teams:FindFirstChild(teamName)
	if exact and exact:IsA("Team") then
		return exact
	end

	local wanted = string.lower(teamName)
	for _, child in Teams:GetChildren() do
		if child:IsA("Team") and string.lower(child.Name) == wanted then
			return child
		end
	end
	return nil
end

-- Configuração do time pelo TeamName (ou nil se não estiver na lista).
function TeamLookup.GetEntry(teamName: string)
	for _, entry in Config.Teams do
		if entry.TeamName == teamName then
			return entry
		end
	end
	return nil
end

-- Conta os jogadores de um time, sem contar `ignorePlayer`.
function TeamLookup.CountPlayers(team: Team, ignorePlayer: Player?): number
	local count = 0
	for _, member in team:GetPlayers() do
		if member ~= ignorePlayer then
			count += 1
		end
	end
	return count
end

-- Motivo para não poder entrar no time agora (ou nil se pode).
-- Usado pelo servidor para validar e pela tela para mostrar "CHEIO".
function TeamLookup.GetJoinBlockReason(team: Team, player: Player): string?
	if player.Team == team then
		return nil
	end

	local count = TeamLookup.CountPlayers(team, player)

	local maxPlayers = Config.MaxPlayersPerTeam
	if maxPlayers and count >= maxPlayers then
		return "Time cheio"
	end

	local maxDifference = Config.MaxTeamDifference
	if maxDifference then
		local smallest = math.huge
		for _, entry in Config.Teams do
			local other = TeamLookup.FindTeam(entry.TeamName)
			if other then
				smallest = math.min(smallest, TeamLookup.CountPlayers(other, player))
			end
		end
		if smallest ~= math.huge and count - smallest >= maxDifference then
			return "Time com jogadores demais"
		end
	end

	return nil
end

return TeamLookup
