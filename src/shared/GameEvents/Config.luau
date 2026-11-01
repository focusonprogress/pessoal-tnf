--[[
	Configuração dos eventos de servidor.

	De tempos em tempos um evento aleatório começa e vale para o servidor inteiro.
]]

local Config = {}

-- Tempo entre o fim de um evento e o começo do próximo (em segundos, sorteado).
-- Para testar no Studio, coloque algo como { Min = 20, Max = 30 }.
Config.Interval = { Min = 600, Max = 900 }

-- Mínimo de jogadores no servidor para ter eventos.
Config.MinPlayers = 2

-- Lista de eventos.
--   Name: nome mostrado na tela
--   Description: explicação mostrada quando o evento começa
--   Duration: duração em segundos
--   Weight: chance de ser sorteado (maior = mais comum)
--   XPMultiplier / MoneyMultiplier / BountyMultiplier: multiplicadores (padrão 1)
--   Teams: se tiver, os multiplicadores valem só para esses times
Config.Events = {
	{
		Id = "DoubleXP",
		Name = "XP EM DOBRO",
		Description = "Todo XP ganho vale o dobro!",
		Duration = 300,
		Weight = 3,
		XPMultiplier = 2,
	},
	{
		Id = "DoubleMoney",
		Name = "DINHEIRO EM DOBRO",
		Description = "Recompensas em dinheiro valem o dobro!",
		Duration = 300,
		Weight = 2,
		MoneyMultiplier = 2,
	},
	{
		Id = "PoliceOperation",
		Name = "OPERAÇÃO POLICIAL",
		Description = "PMERJ e BOPE ganham o dobro de XP e dinheiro!",
		Duration = 300,
		Weight = 2,
		Teams = { "PMERJ", "BOPE" },
		XPMultiplier = 2,
		MoneyMultiplier = 2,
	},
	{
		Id = "FactionWar",
		Name = "GUERRA DE FACÇÕES",
		Description = "VERMELHO e AMARELO ganham o dobro de XP e dinheiro!",
		Duration = 300,
		Weight = 2,
		Teams = { "VERMELHO", "AMARELO" },
		XPMultiplier = 2,
		MoneyMultiplier = 2,
	},
	{
		Id = "Hunt",
		Name = "CAÇADA",
		Description = "Recompensas por cabeça valem o triplo!",
		Duration = 300,
		Weight = 2,
		BountyMultiplier = 3,
	},
}

return Config
