--[[
	Eventos de servidor: de tempos em tempos sorteia um evento (XP em dobro,
	operação policial, caçada...) que vale para o servidor inteiro.

	O evento atual fica em atributos do ReplicatedStorage, que o HUD lê:
	  EventName, EventEndsAt (horário do servidor, workspace:GetServerTimeNow())

	Outros scripts do servidor podem usar:
	  Events.StartEvent("DoubleXP")             -- começar um evento agora (ex.: comando de admin)
	  Events.GetMultiplier(player, "XP")        -- "XP", "Money" ou "Bounty"
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage:WaitForChild("Events"):WaitForChild("Config"))
local Announcer = require(script.Parent.Announcer)

local Events = {}

local current = nil
local eventToken = 0
local started = false
local rng = Random.new()

local function findEvent(id: string)
	for _, event in Config.Events do
		if event.Id == id then
			return event
		end
	end
	return nil
end

local function appliesTo(event, player: Player?): boolean
	if not event.Teams then
		return true
	end
	if not player or player.Neutral or not player.Team then
		return false
	end
	local teamName = string.lower(player.Team.Name)
	for _, name in event.Teams do
		if string.lower(name) == teamName then
			return true
		end
	end
	return false
end

local function pickRandomEvent()
	local total = 0
	for _, event in Config.Events do
		total += event.Weight or 1
	end
	if total <= 0 then
		return nil
	end

	local roll = rng:NextNumber() * total
	for _, event in Config.Events do
		roll -= event.Weight or 1
		if roll <= 0 then
			return event
		end
	end
	return Config.Events[#Config.Events]
end

-- Multiplicador atual para o jogador. kind: "XP", "Money" ou "Bounty".
function Events.GetMultiplier(player: Player?, kind: string): number
	if not current then
		return 1
	end
	local value = current[kind .. "Multiplier"]
	if type(value) ~= "number" or not appliesTo(current, player) then
		return 1
	end
	return value
end

-- Evento atual (tabela da configuração) ou nil.
function Events.GetCurrent()
	return current
end

function Events.StopEvent()
	if not current then
		return
	end
	Announcer.All(`O evento {current.Name} terminou.`, "Event")
	current = nil
	eventToken += 1
	ReplicatedStorage:SetAttribute("EventName", nil)
	ReplicatedStorage:SetAttribute("EventEndsAt", nil)
end

-- Começa um evento agora (encerra o atual, se tiver). Retorna true se deu certo.
function Events.StartEvent(id: string): boolean
	local event = findEvent(id)
	if not event then
		warn(`[Events] Evento "{id}" não existe.`)
		return false
	end

	if current then
		Events.StopEvent()
	end

	current = event
	eventToken += 1
	local token = eventToken

	ReplicatedStorage:SetAttribute("EventName", event.Name)
	ReplicatedStorage:SetAttribute("EventEndsAt", workspace:GetServerTimeNow() + event.Duration)
	Announcer.All(`⚡ EVENTO: {event.Name}! {event.Description}`, "Event")

	task.delay(event.Duration, function()
		if eventToken == token then
			Events.StopEvent()
		end
	end)
	return true
end

function Events.Start()
	if started then
		return
	end
	started = true

	task.spawn(function()
		while true do
			task.wait(rng:NextInteger(Config.Interval.Min, Config.Interval.Max))
			if not current and #Players:GetPlayers() >= Config.MinPlayers then
				local event = pickRandomEvent()
				if event and Events.StartEvent(event.Id) then
					task.wait(event.Duration)
				end
			end
		end
	end)
end

return Events
