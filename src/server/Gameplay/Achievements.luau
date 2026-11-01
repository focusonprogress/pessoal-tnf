--[[
	Conquistas: confere as estatísticas salvas do jogador e desbloqueia as
	conquistas de Achievements > Config quando a meta é alcançada.

	Também conta as estatísticas novas: BountiesCollected, MissionsCompleted
	e PlaytimeMinutes. O HUD lê o atributo "Achievements" (JSON).
]]

local HttpService = game:GetService("HttpService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

local Config = require(ReplicatedStorage:WaitForChild("Achievements"):WaitForChild("Config"))
local EconomyConfig = require(ReplicatedStorage:WaitForChild("Economy"):WaitForChild("Config"))

local Progression = ServerScriptService:WaitForChild("Progression")
local ProgressionService = require(Progression:WaitForChild("ProgressionService"))
local KillTracker = require(Progression:WaitForChild("KillTracker"))

local Announcer = require(script.Parent.Announcer)
local Bounty = require(script.Parent.Bounty)
local DailyRewards = require(script.Parent.DailyRewards)
local Missions = require(script.Parent.Missions)
local Money = require(script.Parent.Money)

local Achievements = {}

local started = false

local function replicate(player: Player, data)
	local unlocked = data.Achievements
	local list = {}
	for _, achievement in Config.List do
		local value = data[achievement.Stat]
		local progress = if type(value) == "number" then value else 0
		table.insert(list, {
			Name = achievement.Name,
			Description = achievement.Description,
			Goal = achievement.Goal,
			Progress = math.min(progress, achievement.Goal),
			Done = unlocked[achievement.Id] == true,
			Money = achievement.Money,
			XP = achievement.XP,
		})
	end
	player:SetAttribute("Achievements", HttpService:JSONEncode(list))
end

local function unlock(player: Player, achievement)
	local paid = if achievement.Money then Money.Add(player, achievement.Money) else 0
	if achievement.XP then
		ProgressionService.AddXP(player, achievement.XP, "Conquista")
	end
	Announcer.To(player, `🏆 Conquista desbloqueada: {achievement.Name}! +{EconomyConfig.Format(paid)}`, "Achievement")
end

-- Confere todas as conquistas do jogador e desbloqueia as que bateram a meta.
function Achievements.Check(player: Player)
	local data = ProgressionService.GetLiveData(player)
	if not data then
		return
	end
	if type(data.Achievements) ~= "table" then
		data.Achievements = {}
	end

	local newlyUnlocked = {}
	for _, achievement in Config.List do
		if not data.Achievements[achievement.Id] then
			local value = data[achievement.Stat]
			if type(value) == "number" and value >= achievement.Goal then
				data.Achievements[achievement.Id] = true
				table.insert(newlyUnlocked, achievement)
			end
		end
	end

	if #newlyUnlocked > 0 then
		ProgressionService.MarkDirty(player)
	end
	replicate(player, data)

	-- Paga depois de salvar o desbloqueio (o XP pode subir o nível e
	-- disparar outra conferência; assim nada é pago duas vezes).
	for _, achievement in newlyUnlocked do
		unlock(player, achievement)
	end
end

function Achievements.Start()
	if started then
		return
	end
	started = true

	ProgressionService.ProfileLoaded:Connect(Achievements.Check)
	for _, player in Players:GetPlayers() do
		Achievements.Check(player)
	end

	KillTracker.PlayerKilled:Connect(function(_victim: Player?, killer: Player?)
		if killer then
			Achievements.Check(killer)
		end
	end)

	KillTracker.Assisted:Connect(Achievements.Check)

	ProgressionService.LevelUp:Connect(function(player: Player)
		Achievements.Check(player)
	end)

	Bounty.Collected:Connect(function(collector: Player)
		ProgressionService.IncrementStat(collector, "BountiesCollected", 1)
		Achievements.Check(collector)
	end)

	Missions.Completed:Connect(function(player: Player)
		ProgressionService.IncrementStat(player, "MissionsCompleted", 1)
		Achievements.Check(player)
	end)

	DailyRewards.Claimed:Connect(Achievements.Check)

	-- Tempo de jogo
	task.spawn(function()
		while true do
			task.wait(60)
			for _, player in Players:GetPlayers() do
				ProgressionService.IncrementStat(player, "PlaytimeMinutes", 1)
				Achievements.Check(player)
			end
		end
	end)
end

return Achievements
