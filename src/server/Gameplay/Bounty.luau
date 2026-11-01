--[[
	Recompensa por cabeça.

	Quem chega numa sequência de abates fica com a cabeça a prêmio
	(atributo "Bounty" no Player, que o marcador acima da cabeça usa).
	Quem matar essa pessoa leva o dinheiro e um XP extra.
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

local Config = require(ReplicatedStorage:WaitForChild("Bounty"):WaitForChild("Config"))
local EconomyConfig = require(ReplicatedStorage:WaitForChild("Economy"):WaitForChild("Config"))

local Progression = ServerScriptService:WaitForChild("Progression")
local ProgressionService = require(Progression:WaitForChild("ProgressionService"))
local KillTracker = require(Progression:WaitForChild("KillTracker"))

local Announcer = require(script.Parent.Announcer)
local Events = require(script.Parent.Events)
local Money = require(script.Parent.Money)

local Bounty = {}

local collectedEvent = Instance.new("BindableEvent")
-- Dispara quando alguém coleta uma recompensa: (collector: Player, victim: Player, amount: number)
Bounty.Collected = collectedEvent.Event

local started = false

local function rewardForStreak(streak: number): number
	local reward = Config.BaseReward + (streak - Config.StartStreak) * Config.RewardPerKill
	return math.min(reward, Config.MaxReward)
end

local function onPlayerKilled(victim: Player?, killer: Player?)
	-- 1) Quem morreu perde a recompensa; quem matou leva.
	if victim then
		local bounty = victim:GetAttribute("Bounty")
		victim:SetAttribute("Bounty", nil)

		if killer and type(bounty) == "number" and bounty > 0 then
			local amount = math.floor(bounty * Events.GetMultiplier(killer, "Bounty"))
			local paid = Money.Add(killer, amount)
			ProgressionService.AddXP(killer, Config.XPReward, "Bounty")
			Announcer.All(
				`💀 {killer.DisplayName} coletou {EconomyConfig.Format(paid)} pela cabeça de {victim.DisplayName}!`,
				"Bounty"
			)
			collectedEvent:Fire(killer, victim, paid)
		end
	end

	-- 2) Quem matou pode ficar com a cabeça a prêmio.
	if killer then
		local streak = KillTracker.GetStreak(killer)
		if streak < Config.StartStreak then
			return
		end

		local reward = rewardForStreak(streak)
		local previous = killer:GetAttribute("Bounty")
		killer:SetAttribute("Bounty", reward)

		if type(previous) ~= "number" then
			Announcer.All(
				`🎯 {killer.DisplayName} está com a cabeça a prêmio: {EconomyConfig.Format(reward)}!`,
				"Bounty"
			)
		elseif reward ~= previous and (streak - Config.StartStreak) % Config.AnnounceEvery == 0 then
			Announcer.All(
				`🎯 A cabeça de {killer.DisplayName} agora vale {EconomyConfig.Format(reward)} ({streak} abates seguidos)!`,
				"Bounty"
			)
		end
	end
end

function Bounty.Start()
	if started then
		return
	end
	started = true
	KillTracker.PlayerKilled:Connect(onPlayerKilled)
end

return Bounty
