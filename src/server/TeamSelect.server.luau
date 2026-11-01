--[[
	Servidor da escolha de time.

	A tela só PEDE para entrar num time; quem decide é este script
	(confere se o time existe, se está cheio, o tempo de espera, etc.).
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local TeamSelect = ReplicatedStorage:WaitForChild("TeamSelect")
local Config = require(TeamSelect:WaitForChild("Config"))
local TeamLookup = require(TeamSelect:WaitForChild("TeamLookup"))

local Remotes = ReplicatedStorage:WaitForChild("TeamSelectRemotes")
local ChooseTeam = Remotes:WaitForChild("ChooseTeam") :: RemoteFunction

local lastChange: { [Player]: number } = {}

-- Avisa no Output se algum time da configuração não existe no Studio.
for _, entry in Config.Teams do
	if not TeamLookup.FindTeam(entry.TeamName) then
		warn(`[TeamSelect] Time "{entry.TeamName}" não encontrado no serviço Teams. Confira o nome em TeamSelect > Config.`)
	end
end

ChooseTeam.OnServerInvoke = function(player: Player, teamName: any): (boolean, string?)
	if type(teamName) ~= "string" or not TeamLookup.GetEntry(teamName) then
		return false, "Time inválido"
	end

	local team = TeamLookup.FindTeam(teamName)
	if not team then
		return false, "Time não encontrado"
	end

	-- Já está nesse time: só fecha a tela.
	if player.Team == team and not player.Neutral then
		return true, nil
	end

	local last = lastChange[player]
	if last then
		local remaining = Config.ChangeCooldown - (os.clock() - last)
		if remaining > 0 then
			return false, `Espere {math.ceil(remaining)}s para trocar de time`
		end
	end

	local reason = TeamLookup.GetJoinBlockReason(team, player)
	if reason then
		return false, reason
	end

	lastChange[player] = os.clock()
	player.Neutral = false
	player.Team = team

	if Config.RespawnOnChoose then
		task.defer(function()
			if player.Parent == Players then
				player:LoadCharacter()
			end
		end)
	end

	return true, nil
end

Players.PlayerRemoving:Connect(function(player)
	lastChange[player] = nil
end)
