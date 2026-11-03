--[[
	ProgressionService: o coração do sistema de progressão.

	Outros scripts do servidor podem usar:

		local ProgressionService = require(game.ServerScriptService.Progression.ProgressionService)

		ProgressionService.AddXP(player, 250, "MatchWin")       -- dar XP
		ProgressionService.GetLevel(player)                      -- nível atual
		ProgressionService.HasUnlocked(player, "AK-47")         -- pode usar a arma?
		ProgressionService.LevelUp:Connect(function(player, level, reward) end)

	O nível/XP também ficam em atributos do Player ("Level", "XP", "XPToNext"),
	que qualquer script (inclusive do cliente) pode ler.
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Config = require(ReplicatedStorage.Progression.Config)
local LevelMath = require(ReplicatedStorage.Progression.LevelMath)
local PlayerData = require(script.Parent.PlayerData)

local Remotes = ReplicatedStorage:WaitForChild("ProgressionRemotes")
local XPGainedRemote = Remotes:WaitForChild("XPGained") :: RemoteEvent
local LevelUpRemote = Remotes:WaitForChild("LevelUp") :: RemoteEvent

type Profile = {
	Data: { [string]: any },
	CanSave: boolean,
	Dirty: boolean,
}

local ProgressionService = {}

local levelUpEvent = Instance.new("BindableEvent")
-- Dispara no servidor quando alguém sobe de nível: (player, newLevel, reward?)
ProgressionService.LevelUp = levelUpEvent.Event

local xpGainedEvent = Instance.new("BindableEvent")
-- Dispara no servidor a cada XP ganho: (player, gained, reason?)
ProgressionService.XPGained = xpGainedEvent.Event

local profileLoadedEvent = Instance.new("BindableEvent")
-- Dispara no servidor quando os dados de um jogador terminam de carregar: (player)
ProgressionService.ProfileLoaded = profileLoadedEvent.Event

-- Função opcional que devolve um multiplicador extra de XP por jogador
-- (usada pelos eventos de servidor, ex.: XP em dobro).
local multiplierProvider: ((Player) -> number)? = nil

local profiles: { [Player]: Profile } = {}
local activeSaves = 0
local started = false

local function debugLog(...)
	if Config.Debug then
		print("[Progression]", ...)
	end
end

local function setupLeaderstats(player: Player)
	if not Config.Leaderstats.Enabled then
		return
	end

	-- Reaproveita a pasta se outro script (ex.: placar de kills) já criou.
	local leaderstats = player:FindFirstChild("leaderstats")
	if not leaderstats then
		leaderstats = Instance.new("Folder")
		leaderstats.Name = "leaderstats"
		leaderstats.Parent = player
	end

	if not leaderstats:FindFirstChild(Config.Leaderstats.LevelName) then
		local levelValue = Instance.new("IntValue")
		levelValue.Name = Config.Leaderstats.LevelName
		levelValue.Parent = leaderstats
	end
end

-- Atualiza o que os outros scripts e o HUD enxergam.
local function replicate(player: Player, data)
	player:SetAttribute("Level", data.Level)
	player:SetAttribute("XP", data.XP)
	player:SetAttribute("XPToNext", LevelMath.XPToNext(data.Level))
	player:SetAttribute("Title", LevelMath.GetTitle(data.Level))

	if Config.Leaderstats.Enabled then
		local leaderstats = player:FindFirstChild("leaderstats")
		local levelValue = leaderstats and leaderstats:FindFirstChild(Config.Leaderstats.LevelName)
		if levelValue and levelValue:IsA("IntValue") then
			levelValue.Value = data.Level
		end
	end
end

local function saveProfile(userId: number, profile: Profile)
	if not profile.CanSave then
		return
	end

	activeSaves += 1
	profile.Dirty = false
	local ok = PlayerData.Save(userId, profile.Data)
	if not ok then
		profile.Dirty = true -- tenta de novo no próximo autosave
	end
	activeSaves -= 1
end

local function onPlayerAdded(player: Player)
	local data = PlayerData.Load(player.UserId)
	local canSave = true

	if not data then
		if RunService:IsStudio() then
			-- No Studio isso costuma acontecer quando "Enable Studio Access to
			-- API Services" está desligado. Joga com dados temporários.
			warn("[Progression] Usando dados temporários (não serão salvos).")
			data = PlayerData.Template()
			canSave = false
		else
			player:Kick(Config.Messages.LoadFailed)
			return
		end
	end

	-- O jogador pode ter saído enquanto os dados carregavam.
	if player.Parent ~= Players then
		return
	end

	profiles[player] = {
		Data = data,
		CanSave = canSave,
		Dirty = false,
	}

	setupLeaderstats(player)
	replicate(player, data)
	debugLog(`{player.Name} carregado: nível {data.Level}, {data.XP} XP`)
	profileLoadedEvent:Fire(player)
end

local function onPlayerRemoving(player: Player)
	local profile = profiles[player]
	if not profile then
		return
	end
	profiles[player] = nil
	saveProfile(player.UserId, profile)
end

local function onServerClosing()
	for player, profile in profiles do
		profiles[player] = nil
		task.spawn(saveProfile, player.UserId, profile)
	end

	-- O Roblox dá ~30s antes de desligar o servidor.
	local deadline = os.clock() + 25
	while activeSaves > 0 and os.clock() < deadline do
		task.wait()
	end
end

---------------------------------------------------------------------------
-- API pública
---------------------------------------------------------------------------

-- Dá XP para o jogador, já aplicando multiplicadores e subindo de nível.
-- `reason` é uma chave de Config.ReasonLabels (aparece no HUD).
-- Retorna o XP realmente ganho.
function ProgressionService.AddXP(player: Player, amount: number, reason: string?): number
	local profile = profiles[player]
	if not profile or type(amount) ~= "number" or amount <= 0 then
		return 0
	end

	local data = profile.Data
	if data.Level >= Config.MaxLevel then
		return 0
	end

	local playerMultiplier = player:GetAttribute("XPMultiplier")
	if type(playerMultiplier) ~= "number" then
		playerMultiplier = 1
	end

	local extraMultiplier = if multiplierProvider then multiplierProvider(player) else 1

	local gained = math.floor(amount * Config.XPMultiplier * playerMultiplier * extraMultiplier + 0.5)
	if gained <= 0 then
		return 0
	end

	data.XP += gained
	data.TotalXP += gained
	profile.Dirty = true

	local newLevels = {}
	while data.Level < Config.MaxLevel do
		local needed = LevelMath.XPToNext(data.Level)
		if data.XP < needed then
			break
		end
		data.XP -= needed
		data.Level += 1
		table.insert(newLevels, data.Level)
	end

	if data.Level >= Config.MaxLevel then
		data.XP = 0
	end

	replicate(player, data)
	XPGainedRemote:FireClient(player, gained, reason)
	xpGainedEvent:Fire(player, gained, reason)

	for _, level in newLevels do
		local reward = LevelMath.GetReward(level)
		debugLog(`{player.Name} subiu para o nível {level}`)
		LevelUpRemote:FireClient(player, level, reward)
		levelUpEvent:Fire(player, level, reward)
	end

	return gained
end

-- Soma em uma estatística salva (Kills, Deaths, Assists...).
function ProgressionService.IncrementStat(player: Player, stat: string, amount: number?)
	local profile = profiles[player]
	if not profile or type(profile.Data[stat]) ~= "number" then
		return
	end
	profile.Data[stat] += amount or 1
	profile.Dirty = true
end

-- Atualiza uma estatística só se o novo valor for maior (ex.: BestStreak).
function ProgressionService.SetStatMax(player: Player, stat: string, value: number)
	local profile = profiles[player]
	if not profile or type(profile.Data[stat]) ~= "number" then
		return
	end
	if value > profile.Data[stat] then
		profile.Data[stat] = value
		profile.Dirty = true
	end
end

-- Muda o nível do jogador direto (usado pelo painel de admin). XP do nível volta a 0.
function ProgressionService.SetLevel(player: Player, level: number)
	local profile = profiles[player]
	if not profile or type(level) ~= "number" then
		return
	end
	profile.Data.Level = math.clamp(math.floor(level), 1, Config.MaxLevel)
	profile.Data.XP = 0
	profile.Dirty = true
	replicate(player, profile.Data)
end

function ProgressionService.GetLevel(player: Player): number
	local profile = profiles[player]
	return if profile then profile.Data.Level else 1
end

-- Cópia dos dados do jogador (mexer nela não altera nada), ou nil.
-- Define a função de multiplicador extra de XP (ver multiplierProvider).
function ProgressionService.SetMultiplierProvider(provider: ((Player) -> number)?)
	multiplierProvider = provider
end

-- Tabela de dados REAL do jogador (não é cópia), para outros sistemas do
-- servidor guardarem coisas salvas (ex.: missões). Chame MarkDirty depois de mudar.
function ProgressionService.GetLiveData(player: Player)
	local profile = profiles[player]
	return if profile then profile.Data else nil
end

-- Marca que os dados mudaram e precisam ser salvos.
function ProgressionService.MarkDirty(player: Player)
	local profile = profiles[player]
	if profile then
		profile.Dirty = true
	end
end

function ProgressionService.GetData(player: Player)
	local profile = profiles[player]
	return if profile then table.clone(profile.Data) else nil
end

-- Nível necessário para um item, ou 1 se ele não tem bloqueio.
function ProgressionService.GetUnlockLevel(itemName: string): number
	return Config.Unlocks[itemName] or 1
end

-- O jogador já pode usar esse item?
function ProgressionService.HasUnlocked(player: Player, itemName: string): boolean
	return ProgressionService.GetLevel(player) >= ProgressionService.GetUnlockLevel(itemName)
end

-- Liga tudo. Chamado uma vez pelo script StartProgression.
function ProgressionService.Start()
	if started then
		return
	end
	started = true

	Players.PlayerAdded:Connect(onPlayerAdded)
	Players.PlayerRemoving:Connect(onPlayerRemoving)
	for _, player in Players:GetPlayers() do
		task.spawn(onPlayerAdded, player)
	end

	game:BindToClose(onServerClosing)

	-- Autosave
	task.spawn(function()
		while true do
			task.wait(Config.DataStore.AutosaveInterval)
			for player, profile in profiles do
				if profile.Dirty then
					task.spawn(saveProfile, player.UserId, profile)
				end
			end
		end
	end)

	-- XP por tempo de jogo
	if Config.Playtime.Enabled then
		task.spawn(function()
			while true do
				task.wait(Config.Playtime.Interval)
				for player in profiles do
					ProgressionService.AddXP(player, Config.Playtime.Amount, "Playtime")
				end
			end
		end)
	end
end

return ProgressionService
