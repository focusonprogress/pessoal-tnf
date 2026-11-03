--[[
	Configuração do Passe de Temporada.

	Todo XP que o jogador ganha no jogo também enche o passe. A cada
	XPPerTier de XP, ele sobe um nível do passe e libera as recompensas:
	  - Trilha Grátis: todo mundo
	  - Trilha Premium: quem comprou o Gamepass do passe

	NOVA TEMPORADA: troque o SeasonId (ex.: "S2"), o nome, a data de fim e,
	se quiser, as recompensas. O progresso do passe zera; os títulos
	ganhos continuam com o jogador para sempre.
]]

local Config = {}

-- Identificador da temporada. Trocar = todo mundo começa o passe do zero.
Config.SeasonId = "S1"
Config.SeasonName = "TEMPORADA 1: MORRO EM CHAMAS"

-- Fim da temporada (UTC). Depois disso o passe para de ganhar XP,
-- mas ainda dá para resgatar o que já foi liberado.
Config.EndsAt = DateTime.fromUniversalTime(2026, 12, 31, 23, 59, 0).UnixTimestamp

Config.MaxTier = 50
Config.XPPerTier = 1000

-- ID do Gamepass do Premium (crie em create.roblox.com > seu jogo > Monetização > Passes).
-- 0 = Premium desativado (o botão de comprar não aparece).
Config.PremiumGamePassId = 0

-- Recompensas de cada nível do passe: { Free = {...}, Premium = {...} }
-- Tipos: Money = dinheiro, Title = título exclusivo (aparece na tag e no chat)
Config.Rewards = {}

-- Títulos especiais (nível do passe -> título)
local FREE_TITLES = {
	[25] = "Veterano da T1",
	[50] = "Sobrevivente da T1",
}
local PREMIUM_TITLES = {
	[10] = "Cria do Morro",
	[20] = "Sangue Frio",
	[30] = "Patrão",
	[40] = "Lenda Viva",
	[50] = "Dono do Morro",
}

for tier = 1, Config.MaxTier do
	local bigTier = tier % 5 == 0

	Config.Rewards[tier] = {
		Free = {
			Money = if bigTier then 2500 else 500,
			Title = FREE_TITLES[tier],
		},
		Premium = {
			Money = if bigTier then 7500 else 1500,
			Title = PREMIUM_TITLES[tier],
		},
	}
end

-- Posição do botão "PASSE" (abaixo de "DIÁRIO").
Config.ButtonPosition = UDim2.new(0, 12, 0.35, 168)

return Config
