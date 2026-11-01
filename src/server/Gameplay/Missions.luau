--[[
	Missões diárias.

	As missões de cada jogador são sorteadas a partir do dia + UserId, então
	são sempre as mesmas durante o dia e não precisam ser salvas. Só o
	progresso é salvo (dentro dos dados da progressão, campo "Missions").

	O estado vai para o HUD pelo atributo "Missions" do Player (texto JSON).
]]

local HttpService = game:GetService("HttpService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

local Config = require(ReplicatedStorage:WaitForChild("Missions"):WaitForChild("Config"))
local EconomyConfig = require(ReplicatedStorage:WaitForChild("Economy"):WaitForChild("Config"))

local Progression = ServerScriptService:WaitForChild("Progression")
local ProgressionService = require(Progression:WaitForChild("ProgressionService"))
local KillTracker = require(Progression:WaitForChild("KillTracker"))

local Announcer = require(script.Parent.Announcer)
local Bounty = require(script.Parent.Bounty)
local Money = require(script.Parent.Money)

local Missions = {}

local started = false

local function currentDay(): number
	return (os.time() - Config.ResetHourUTC * 3600) // 86400
end

local function nextResetTime(day: number): number
	return (day + 1) * 86400 + Config.ResetHourUTC * 3600
end

local function missionText(mission): string
	return (string.gsub(mission.Text, "{goal}", tostring(mission.Goal)))
end

-- Sorteia as missões do dia para um jogador (sempre o mesmo resultado no mesmo dia).
local function pickMissions(userId: number, day: number)
	local rng = Random.new(userId * 7919 + day)
	local indices = {}
	for index = 1, #Config.Pool do
		indices[index] = index
	end
	for index = #indices, 2, -1 do
		local other = rng:NextInteger(1, index)
		indices[index], indices[other] = indices[other], indices[index]
	end

	local result = {}
	for index = 1, math.min(Config.MissionsPerDay, #indices) do
		table.insert(result, Config.Pool[indices[index]])
	end
	return result
end

-- Estado salvo do dia (cria um novo se o dia virou) e a lista de missões.
local function getState(player: Player)
	local data = ProgressionService.GetLiveData(player)
	if not data then
		return nil, nil
	end

	local day = currentDay()
	local state = data.Missions
	if type(state) ~= "table" or state.Day ~= day then
		state = { Day = day, Progress = {}, Done = {} }
		data.Missions = state
		ProgressionService.MarkDirty(player)
	end
	state.Progress = state.Progress or {}
	state.Done = state.Done or {}

	return state, pickMissions(player.UserId, day)
end

local function replicate(player: Player)
	local state, list = getState(player)
	if not state or not list then
		return
	end

	local payload = {
		ResetsAt = nextResetTime(state.Day),
		List = {},
	}
	for _, mission in list do
		table.insert(payload.List, {
			Text = missionText(mission),
			Goal = mission.Goal,
			Progress = math.min(state.Progress[mission.Id] or 0, mission.Goal),
			Done = state.Done[mission.Id] == true,
			Money = mission.Money,
			XP = mission.XP,
		})
	end
	player:SetAttribute("Missions", HttpService:JSONEncode(payload))
end

local function matchesContext(mission, context: string?): boolean
	if mission.Type ~= "KillWeapon" then
		return true
	end
	if type(context) ~= "string" or type(mission.Weapons) ~= "table" then
		return false
	end
	local weapon = string.lower(context)
	for _, name in mission.Weapons do
		if string.lower(name) == weapon then
			return true
		end
	end
	return false
end

local function complete(player: Player, mission)
	local paid = if mission.Money then Money.Add(player, mission.Money) else 0
	if mission.XP then
		ProgressionService.AddXP(player, mission.XP, "Mission")
	end
	Announcer.To(player, `✅ Missão concluída: {missionText(mission)} (+{EconomyConfig.Format(paid)})`, "Mission")
end

-- Soma progresso nas missões de um tipo.
-- Para "Streak", amount é a sequência atual (guarda a maior do dia).
-- context: nome da arma, para "KillWeapon".
function Missions.AddProgress(player: Player, missionType: string, amount: number, context: string?)
	local state, list = getState(player)
	if not state or not list then
		return
	end

	local changed = false
	for _, mission in list do
		if mission.Type == missionType and not state.Done[mission.Id] and matchesContext(mission, context) then
			local before = state.Progress[mission.Id] or 0
			local after = if missionType == "Streak" then math.max(before, amount) else before + amount

			if after ~= before then
				state.Progress[mission.Id] = after
				changed = true
			end
			if after >= mission.Goal then
				state.Done[mission.Id] = true
				changed = true
				complete(player, mission)
			end
		end
	end

	if changed then
		ProgressionService.MarkDirty(player)
		replicate(player)
	end
end

function Missions.Start()
	if started then
		return
	end
	started = true

	ProgressionService.ProfileLoaded:Connect(replicate)
	for _, player in Players:GetPlayers() do
		replicate(player)
	end

	KillTracker.PlayerKilled:Connect(function(_victim: Player?, killer: Player?, weapon: string?)
		if not killer then
			return
		end
		Missions.AddProgress(killer, "Kill", 1)
		Missions.AddProgress(killer, "KillWeapon", 1, weapon)
		Missions.AddProgress(killer, "Streak", KillTracker.GetStreak(killer))
	end)

	KillTracker.Assisted:Connect(function(attacker: Player)
		Missions.AddProgress(attacker, "Assist", 1)
	end)

	Bounty.Collected:Connect(function(collector: Player)
		Missions.AddProgress(collector, "Bounty", 1)
	end)

	-- A cada minuto: tempo de jogo e virada do dia.
	task.spawn(function()
		local lastDay = currentDay()
		while true do
			task.wait(60)
			local dayChanged = currentDay() ~= lastDay
			lastDay = currentDay()
			for _, player in Players:GetPlayers() do
				Missions.AddProgress(player, "Playtime", 1)
				if dayChanged then
					replicate(player)
				end
			end
		end
	end)
end

return Missions
