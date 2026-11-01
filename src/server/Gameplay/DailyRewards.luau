--[[
	Recompensa de login diário.

	Estado salvo nos dados da progressão: LoginStreak e LastLoginClaimDay.
	O HUD lê o atributo "DailyReward" (JSON) e pede o resgate pelo
	RemoteFunction GameRemotes > ClaimDaily. Quem decide é o servidor.
]]

local HttpService = game:GetService("HttpService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

local Config = require(ReplicatedStorage:WaitForChild("DailyRewards"):WaitForChild("Config"))
local EconomyConfig = require(ReplicatedStorage:WaitForChild("Economy"):WaitForChild("Config"))
local ProgressionService = require(ServerScriptService:WaitForChild("Progression"):WaitForChild("ProgressionService"))

local Announcer = require(script.Parent.Announcer)
local Money = require(script.Parent.Money)
local Remotes = require(script.Parent.Remotes)

local ClaimRemote = Remotes.Function("ClaimDaily")

local DailyRewards = {}

local claimedEvent = Instance.new("BindableEvent")
-- Dispara quando alguém resgata: (player, streak)
DailyRewards.Claimed = claimedEvent.Event

local started = false

local function currentDay(): number
	return (os.time() - Config.ResetHourUTC * 3600) // 86400
end

local function nextResetTime(day: number): number
	return (day + 1) * 86400 + Config.ResetHourUTC * 3600
end

-- Situação de hoje: pode resgatar? Qual dia do ciclo (1 a 7)?
local function getStatus(data)
	local today = currentDay()
	local streak = data.LoginStreak or 0
	local last = data.LastLoginClaimDay or -1
	local cycle = #Config.Rewards

	if last == today then
		return {
			Today = today,
			CanClaim = false,
			Streak = streak,
			Index = (math.max(streak, 1) - 1) % cycle + 1,
		}
	end

	local nextStreak = if last == today - 1 then streak + 1 else 1
	return {
		Today = today,
		CanClaim = true,
		Streak = nextStreak,
		Index = (nextStreak - 1) % cycle + 1,
	}
end

local function replicate(player: Player)
	local data = ProgressionService.GetLiveData(player)
	if not data then
		return
	end
	local status = getStatus(data)
	player:SetAttribute(
		"DailyReward",
		HttpService:JSONEncode({
			CanClaim = status.CanClaim,
			Index = status.Index,
			ResetsAt = nextResetTime(status.Today),
		})
	)
end

local function claim(player: Player): (boolean, string?)
	local data = ProgressionService.GetLiveData(player)
	if not data then
		return false, "Seus dados ainda estão carregando"
	end

	local status = getStatus(data)
	if not status.CanClaim then
		return false, "Você já resgatou hoje. Volte amanhã!"
	end

	data.LoginStreak = status.Streak
	data.LastLoginClaimDay = status.Today
	ProgressionService.MarkDirty(player)

	local reward = Config.Rewards[status.Index]
	local paid = if reward.Money then Money.Add(player, reward.Money) else 0
	if reward.XP then
		ProgressionService.AddXP(player, reward.XP, "Recompensa diária")
	end

	Announcer.To(player, `🎁 Recompensa do dia {status.Index} resgatada! +{EconomyConfig.Format(paid)}`, "Daily")
	replicate(player)
	claimedEvent:Fire(player, status.Streak)
	return true, nil
end

function DailyRewards.Start()
	if started then
		return
	end
	started = true

	ClaimRemote.OnServerInvoke = claim

	ProgressionService.ProfileLoaded:Connect(replicate)
	for _, player in Players:GetPlayers() do
		replicate(player)
	end

	-- Quando o dia vira, avisa quem está online que já pode resgatar de novo.
	task.spawn(function()
		local lastDay = currentDay()
		while true do
			task.wait(60)
			if currentDay() ~= lastDay then
				lastDay = currentDay()
				for _, player in Players:GetPlayers() do
					replicate(player)
				end
			end
		end
	end)
end

return DailyRewards
