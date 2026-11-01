--[[
	KillTracker: descobre quem matou quem e dá o XP de abate, assistência
	e sequência de abates.

	Funciona com a tag "creator" (um ObjectValue dentro do Humanoid apontando
	para o Player que causou o dano). É o padrão do Roblox, usado por muitas
	armas e kits.

	Se a sua versão do ACS NÃO cria essa tag, chame no ponto do ACS onde o
	dano é aplicado (no servidor):

		local KillTracker = require(game.ServerScriptService.Progression.KillTracker)
		KillTracker.Tag(humanoidAtingido, jogadorQueAtirou)

	Ligue Config.Debug para ver no Output quando alguém morre sem tag.
]]

local Debris = game:GetService("Debris")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage.Progression.Config)
local ProgressionService = require(script.Parent.ProgressionService)

local CREATOR_TAG = "creator"

local KillTracker = {}

-- Humanoid -> { [Player] = momento do último dano }
local damageLog: { [Humanoid]: { [Player]: number } } = setmetatable({}, { __mode = "k" }) :: any
-- Humanoids que já estamos observando
local watched: { [Humanoid]: boolean } = setmetatable({}, { __mode = "k" }) :: any
-- Abates seguidos sem morrer
local streaks: { [Player]: number } = setmetatable({}, { __mode = "k" }) :: any

local started = false

local playerKilledEvent = Instance.new("BindableEvent")
-- Dispara a cada morte processada: (victim: Player?, killer: Player?, weaponName: string?)
-- victim é nil para NPCs; killer é nil quando não houve abate válido (queda, aliado, etc.).
KillTracker.PlayerKilled = playerKilledEvent.Event

local assistedEvent = Instance.new("BindableEvent")
-- Dispara a cada assistência: (attacker: Player, victim: Player?)
KillTracker.Assisted = assistedEvent.Event

-- Nome da arma (Tool) que o jogador está segurando agora, ou nil.
local function equippedWeapon(player: Player): string?
	local character = player.Character
	local tool = character and character:FindFirstChildOfClass("Tool")
	return if tool then tool.Name else nil
end

local function debugLog(...)
	if Config.Debug then
		print("[Progression]", ...)
	end
end

local function getTagPlayer(tag: Instance?): Player?
	if tag and tag:IsA("ObjectValue") then
		local value = tag.Value
		if value and value:IsA("Player") then
			return value
		end
	end
	return nil
end

local function isTeammate(a: Player, b: Player): boolean
	return not a.Neutral and a.Team ~= nil and a.Team == b.Team
end

local function recordDamage(humanoid: Humanoid, attacker: Player)
	local log = damageLog[humanoid]
	if not log then
		log = {}
		damageLog[humanoid] = log
	end
	log[attacker] = os.clock()
end

local function trackCreatorTag(humanoid: Humanoid, tag: Instance)
	if tag.Name ~= CREATOR_TAG or not tag:IsA("ObjectValue") then
		return
	end

	-- Alguns scripts definem o Value depois de colocar a tag no Humanoid.
	local function record()
		local attacker = getTagPlayer(tag)
		if attacker then
			recordDamage(humanoid, attacker)
		end
	end
	task.defer(record)
	tag:GetPropertyChangedSignal("Value"):Connect(record)
end

local function awardKill(killer: Player)
	ProgressionService.IncrementStat(killer, "Kills", 1)
	ProgressionService.AddXP(killer, Config.XP.Kill, "Kill")

	local streak = (streaks[killer] or 0) + 1
	streaks[killer] = streak
	ProgressionService.SetStatMax(killer, "BestStreak", streak)

	local bonus = Config.XP.KillStreaks[streak]
	if bonus then
		ProgressionService.AddXP(killer, bonus, "KillStreak")
	end
end

local function onDied(humanoid: Humanoid)
	local character = humanoid.Parent
	local victim = if character then Players:GetPlayerFromCharacter(character) else nil
	local killer = getTagPlayer(humanoid:FindFirstChild(CREATOR_TAG))
	local log = damageLog[humanoid] or {}
	damageLog[humanoid] = nil

	if victim then
		ProgressionService.IncrementStat(victim, "Deaths", 1)
		streaks[victim] = 0
	elseif not Config.Kills.CountNPCKills then
		return -- NPC morreu e NPCs não dão XP
	end

	-- Não conta suicídio nem (se configurado) abate de aliado.
	local function isValidAttacker(attacker: Player): boolean
		if attacker == victim or attacker.Parent ~= Players then
			return false
		end
		if victim and Config.Kills.IgnoreTeamKills and isTeammate(attacker, victim) then
			return false
		end
		return true
	end

	local validKiller: Player? = nil
	if killer and isValidAttacker(killer) then
		validKiller = killer
		awardKill(killer)
		debugLog(`{killer.Name} matou {humanoid.Parent and humanoid.Parent.Name}`)
	elseif not killer then
		debugLog(`{humanoid.Parent and humanoid.Parent.Name} morreu sem tag "creator" (ninguém ganhou o abate)`)
	end

	local now = os.clock()
	for attacker, lastHit in log do
		if attacker ~= killer and now - lastHit <= Config.Kills.AssistWindow and isValidAttacker(attacker) then
			ProgressionService.IncrementStat(attacker, "Assists", 1)
			ProgressionService.AddXP(attacker, Config.XP.Assist, "Assist")
			assistedEvent:Fire(attacker, victim)
		end
	end

	local weapon = if validKiller then equippedWeapon(validKiller) else nil
	playerKilledEvent:Fire(victim, validKiller, weapon)
end

local function watchHumanoid(humanoid: Humanoid)
	if watched[humanoid] then
		return
	end
	watched[humanoid] = true

	for _, child in humanoid:GetChildren() do
		trackCreatorTag(humanoid, child)
	end
	humanoid.ChildAdded:Connect(function(child)
		trackCreatorTag(humanoid, child)
	end)
	humanoid.Died:Once(function()
		onDied(humanoid)
	end)
end

---------------------------------------------------------------------------
-- API pública
---------------------------------------------------------------------------

-- Marca que `attacker` causou dano em `humanoid`. Use se o seu sistema de
-- dano não cria a tag "creator" sozinho.
function KillTracker.Tag(humanoid: Humanoid, attacker: Player)
	if humanoid.Health <= 0 then
		return
	end

	local oldTag = humanoid:FindFirstChild(CREATOR_TAG)
	if oldTag then
		oldTag:Destroy()
	end

	local tag = Instance.new("ObjectValue")
	tag.Name = CREATOR_TAG
	tag.Value = attacker
	tag.Parent = humanoid
	Debris:AddItem(tag, Config.Kills.TagLifetime)

	recordDamage(humanoid, attacker)
end

-- Sequência de abates atual do jogador.
function KillTracker.GetStreak(player: Player): number
	return streaks[player] or 0
end

function KillTracker.Start()
	if started then
		return
	end
	started = true

	-- Observa todo Humanoid que aparecer no Workspace (jogadores e NPCs).
	workspace.DescendantAdded:Connect(function(descendant)
		if descendant:IsA("Humanoid") then
			watchHumanoid(descendant)
		end
	end)
	for _, descendant in workspace:GetDescendants() do
		if descendant:IsA("Humanoid") then
			watchHumanoid(descendant)
		end
	end
end

return KillTracker
