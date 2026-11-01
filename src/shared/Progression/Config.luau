--[[
	Configuração do sistema de progressão.

	Este é o ÚNICO arquivo que você precisa mexer para balancear o sistema:
	quanto XP cada ação dá, a curva de níveis, recompensas e desbloqueios.

	Fica no ReplicatedStorage porque o HUD (cliente) também lê daqui.
	Por isso, NÃO coloque nada secreto neste arquivo.
]]

local Config = {}

-- Nível máximo que um jogador pode alcançar.
Config.MaxLevel = 100

-- Curva de XP: quanto XP é preciso para sair do nível N e ir para o N + 1.
-- Fórmula: Base + Growth * (N - 1) ^ Exponent
--   Nível 1 -> 2:   500 XP
--   Nível 10 -> 11: ~1.550 XP
--   Nível 50 -> 51: ~8.500 XP
Config.XPCurve = {
	Base = 500,
	Growth = 75,
	Exponent = 1.2,
}

-- Quanto XP cada ação dá (antes dos multiplicadores).
Config.XP = {
	Kill = 100,
	Assist = 40,

	-- Bônus por sequência de abates sem morrer: [abates seguidos] = XP extra.
	KillStreaks = {
		[3] = 50,
		[5] = 100,
		[10] = 250,
		[15] = 400,
	},
}

-- XP ganho só por estar jogando.
Config.Playtime = {
	Enabled = true,
	Interval = 120, -- segundos
	Amount = 15,
}

-- Multiplicador global. Coloque 2 num evento de XP em dobro, por exemplo.
-- Cada jogador também pode ter um multiplicador próprio via atributo
-- "XPMultiplier" no Player (ex.: gamepass de XP).
Config.XPMultiplier = 1

-- Regras de abate.
Config.Kills = {
	-- Segundos em que um dano ainda conta como assistência.
	AssistWindow = 10,

	-- Tempo de vida da tag "creator" criada por KillTracker.Tag().
	TagLifetime = 10,

	-- Matar alguém do próprio time não dá XP.
	IgnoreTeamKills = true,

	-- Matar NPCs (bots, zumbis, etc.) dá XP?
	CountNPCKills = false,
}

-- Recompensas mostradas ao subir para um nível específico.
-- Title: título do jogador. Unlocks: lista de nomes só para exibição
-- (quem bloqueia de verdade é a tabela Config.Unlocks abaixo).
Config.LevelRewards = {
	[2] = { Title = "Recruta" },
	[5] = { Title = "Soldado", Unlocks = { "MP5" } },
	[10] = { Title = "Cabo", Unlocks = { "AK-47" } },
	[20] = { Title = "Sargento", Unlocks = { "M4A1" } },
	[35] = { Title = "Tenente", Unlocks = { "SCAR-H" } },
	[50] = { Title = "Capitão", Unlocks = { "AWM" } },
	[75] = { Title = "Major" },
	[100] = { Title = "Lenda" },
}

-- Nível mínimo para usar cada item.
-- Use ProgressionService.HasUnlocked(player, "AK-47") no seu script que
-- entrega armas do ACS (loja, armário, spawn) para checar.
-- Itens que não estão aqui ficam liberados desde o nível 1.
Config.Unlocks = {
	["MP5"] = 5,
	["AK-47"] = 10,
	["M4A1"] = 20,
	["SCAR-H"] = 35,
	["AWM"] = 50,
}

-- Nomes exibidos no HUD para cada motivo de XP.
Config.ReasonLabels = {
	Kill = "Abate",
	Assist = "Assistência",
	KillStreak = "Sequência de abates",
	Playtime = "Tempo de jogo",
	MatchWin = "Vitória",
}

-- Mostrar o nível na tabela de jogadores (leaderstats).
Config.Leaderstats = {
	Enabled = true,
	LevelName = "Nível",
}

-- Salvamento de dados.
Config.DataStore = {
	-- Trocar o nome = começar com dados zerados. Cuidado!
	Name = "Progression_v1",
	KeyPrefix = "player_",
	AutosaveInterval = 120, -- segundos
}

-- Mensagem de kick quando não dá para carregar os dados (evita perder progresso).
Config.Messages = {
	LoadFailed = "Não foi possível carregar seu progresso. Tente entrar de novo em instantes.",
}

-- Mostra avisos no Output para ajudar a encontrar problemas
-- (ex.: jogador morreu sem tag "creator", então ninguém ganhou o abate).
Config.Debug = false

return Config
