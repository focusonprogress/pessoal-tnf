--[[
	Configuração da recompensa de login diário.

	O jogador resgata uma recompensa por dia. Dias seguidos vão aumentando
	o prêmio até o dia 7; depois recomeça do dia 1. Se pular um dia, volta pro dia 1.
]]

local Config = {}

-- Hora (UTC) em que o dia vira. 3 = meia-noite no horário de Brasília.
Config.ResetHourUTC = 3

-- Prêmio de cada dia (Money = dinheiro, XP = experiência).
Config.Rewards = {
	{ Money = 500, XP = 100 },
	{ Money = 1000, XP = 150 },
	{ Money = 1500, XP = 200 },
	{ Money = 2000, XP = 250 },
	{ Money = 3000, XP = 300 },
	{ Money = 4000, XP = 400 },
	{ Money = 10000, XP = 1000 }, -- dia 7: prêmio grande
}

-- Abrir a janela sozinha quando tiver recompensa para resgatar.
Config.ShowAutomatically = true

-- Posição do botão "DIÁRIO" (abaixo de "CONQUISTAS").
Config.ButtonPosition = UDim2.new(0, 12, 0.35, 126)

return Config
