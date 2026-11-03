--[[
	Passe de Temporada.

	- Todo XP ganho (ProgressionService.XPGained) também enche o passe
	- Progresso salvo nos dados da progressão: Season = { Id, XP, Free = {..}, Premium = {..} }
	- Títulos ganhos ficam em Titles (para sempre) e o equipado em EquippedTitle
	- Premium: Gamepass (Config.PremiumGamePassId) ou dado pelo painel de admin

	O HUD lê o atributo "SeasonPass" (JSON) e pede ações pelo
	RemoteFunction GameRemotes > SeasonPassAction. Quem decide é o servidor.
]]

local HttpService = game:GetService("HttpService")
local MarketplaceService = game:GetService("MarketplaceService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

local Config = require(ReplicatedStorage:WaitForChild("SeasonPass"):WaitForChild("Config"))
local EconomyConfig = require(ReplicatedStorage:WaitForChild("Economy"):WaitForChild("Config"))
local ProgressionService = require(ServerScriptService:WaitForChild("Progression"):WaitForChild("ProgressionService"))

local Announcer = require(script.Parent.Announcer)
local Money = require(script.Parent.Money)
local Remotes = require(script.Parent.Remotes)

local ActionRemote = Remotes.Function("SeasonPassAction")

local SeasonPass = {}

local PASS_XP_REASON = "Passe de temporada"

-- Quem tem o Premium nesta sessão (comprado ou dado por admin).
local premium: { [Player]: boolean } = {}
local started = false

---------------------------------------------------------------------------
-- Dados
---------------------------------------------------------------------------

-- Progresso da temporada atual (zera se a temporada mudou).
local function getSeason(player: Player)
	local data = ProgressionService.GetLiveData(player)
	if not data then
		return nil, nil
	end
	local season = data.Season
	if type(season) ~= "table" or season.Id ~= Config.SeasonId then
		season = { Id = Config.SeasonId, XP = 0, Free = {}, Premium = {} }
		data.Season = season
		ProgressionService.MarkDirty(player)
	end
	season.Free = season.Free or {}
	season.Premium = season.Premium or {}
	if type(data.Titles) ~= "table" then
		data.Titles = {}
	end
	return season, data
end

local function tierFromXP(xp: number): number
	return math.min(xp // Config.XPPerTier, Config.MaxTier)
end

local function replicate(player: Player)
	local season, data = getSeason(player)
	if not season or not data then
		return
	end

	local tier = tierFromXP(season.XP)
	local claimedFree, claimedPremium = {}, {}
	for key in season.Free do
		table.insert(claimedFree, tonumber(key))
	end
	for key in season.Premium do
		table.insert(claimedPremium, tonumber(key))
	end

	player:SetAttribute(
		"SeasonPass",
		HttpService:JSONEncode({
			Tier = tier,
			XPInTier = if tier >= Config.MaxTier then Config.XPPerTier else season.XP % Config.XPPerTier,
			Premium = premium[player] == true,
			ClaimedFree = claimedFree,
			ClaimedPremium = claimedPremium,
			Titles = data.Titles,
			Equipped = data.EquippedTitle or "",
		})
	)
	player:SetAttribute("EquippedTitle", if data.EquippedTitle ~= "" then data.EquippedTitle else nil)
end

---------------------------------------------------------------------------
-- Recompensas
---------------------------------------------------------------------------

-- Entrega uma recompensa. Retorna o texto do que foi dado.
local function grant(player: Player, data, reward): string
	local parts = {}
	if reward.Money then
		local paid = Money.Add(player, reward.Money, true)
		table.insert(parts, EconomyConfig.Format(paid))
	end
	if reward.Title and not table.find(data.Titles, reward.Title) then
		table.insert(data.Titles, reward.Title)
		table.insert(parts, `título "{reward.Title}"`)
	end
	return table.concat(parts, " + ")
end

-- Tenta resgatar um nível de uma trilha ("Free" ou "Premium").
local function claim(player: Player, track: string, tier: number): (boolean, string?)
	local season, data = getSeason(player)
	if not season or not data then
		return false, "Seus dados ainda estão carregando"
	end
	if track ~= "Free" and track ~= "Premium" then
		return false, "Trilha inválida"
	end
	if type(tier) ~= "number" or tier < 1 or tier > Config.MaxTier or tier % 1 ~= 0 then
		return false, "Nível inválido"
	end
	if tier > tierFromXP(season.XP) then
		return false, "Você ainda não chegou nesse nível"
	end
	if track == "Premium" and not premium[player] then
		return false, "Precisa do Passe Premium"
	end

	local key = tostring(tier)
	if season[track][key] then
		return false, "Já resgatado"
	end

	local reward = Config.Rewards[tier] and Config.Rewards[tier][track]
	if not reward then
		return false, "Sem recompensa"
	end

	season[track][key] = true
	local given = grant(player, data, reward)
	ProgressionService.MarkDirty(player)
	return true, given
end

-- Resgata tudo o que estiver liberado. Retorna quantos foram resgatados.
local function claimAll(player: Player): number
	local season = getSeason(player)
	if not season then
		return 0
	end
	local count = 0
	for tier = 1, tierFromXP(season.XP) do
		if claim(player, "Free", tier) then
			count += 1
		end
		if premium[player] and claim(player, "Premium", tier) then
			count += 1
		end
	end
	return count
end

---------------------------------------------------------------------------
-- API pública
---------------------------------------------------------------------------

function SeasonPass.HasPremium(player: Player): boolean
	return premium[player] == true
end

-- Dá o Premium nesta sessão (ex.: painel de admin). Para ser permanente,
-- o jogador precisa ter o Gamepass.
function SeasonPass.GrantPremium(player: Player)
	premium[player] = true
	replicate(player)
end

-- Soma XP direto no passe (ex.: painel de admin).
function SeasonPass.AddPassXP(player: Player, amount: number)
	local season = getSeason(player)
	if not season or type(amount) ~= "number" or amount <= 0 then
		return
	end
	local before = tierFromXP(season.XP)
	season.XP = math.min(season.XP + math.floor(amount), Config.MaxTier * Config.XPPerTier)
	ProgressionService.MarkDirty(player)

	local after = tierFromXP(season.XP)
	if after > before then
		Announcer.To(player, `🎟️ Passe de temporada: nível {after}! Abra o PASSE para resgatar.`, "Daily")
	end
	replicate(player)
end

---------------------------------------------------------------------------
-- Início
---------------------------------------------------------------------------

local function checkPremium(player: Player)
	if Config.PremiumGamePassId == 0 then
		return
	end
	local ok, owns = pcall(function()
		return MarketplaceService:UserOwnsGamePassAsync(player.UserId, Config.PremiumGamePassId)
	end)
	if ok and owns then
		premium[player] = true
		replicate(player)
	end
end

local function onAction(player: Player, action: any, a: any, b: any)
	if action == "claim" then
		local ok, result = claim(player, a, b)
		replicate(player)
		if ok then
			Announcer.To(player, `🎁 Recompensa do passe: +{result}`, "Daily")
		end
		return ok, result
	elseif action == "claimAll" then
		local count = claimAll(player)
		replicate(player)
		if count > 0 then
			Announcer.To(player, `🎁 {count} recompensas do passe resgatadas!`, "Daily")
		end
		return count > 0, if count > 0 then nil else "Nada para resgatar"
	elseif action == "equipTitle" then
		local _, data = getSeason(player)
		if not data then
			return false
		end
		if a == "" or (type(a) == "string" and table.find(data.Titles, a)) then
			data.EquippedTitle = a
			ProgressionService.MarkDirty(player)
			replicate(player)
			return true
		end
		return false, "Você não tem esse título"
	elseif action == "buyPremium" then
		if Config.PremiumGamePassId == 0 then
			return false, "Premium indisponível"
		end
		if premium[player] then
			return false, "Você já tem o Premium"
		end
		MarketplaceService:PromptGamePassPurchase(player, Config.PremiumGamePassId)
		return true
	end
	return false, "Ação inválida"
end

function SeasonPass.Start()
	if started then
		return
	end
	started = true

	ActionRemote.OnServerInvoke = onAction

	ProgressionService.XPGained:Connect(function(player: Player, gained: number, reason: string?)
		if reason == PASS_XP_REASON then
			return
		end
		if os.time() > Config.EndsAt then
			return -- temporada acabou
		end
		SeasonPass.AddPassXP(player, gained)
	end)

	ProgressionService.ProfileLoaded:Connect(function(player)
		replicate(player)
		task.spawn(checkPremium, player)
	end)
	for _, player in Players:GetPlayers() do
		replicate(player)
		task.spawn(checkPremium, player)
	end

	MarketplaceService.PromptGamePassPurchaseFinished:Connect(function(player, gamePassId, purchased)
		if purchased and gamePassId == Config.PremiumGamePassId then
			premium[player] = true
			replicate(player)
			Announcer.To(player, "⭐ Passe Premium ativado! Resgate suas recompensas.", "Daily")
		end
	end)

	Players.PlayerRemoving:Connect(function(player)
		premium[player] = nil
	end)
end

return SeasonPass
