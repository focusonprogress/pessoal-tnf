--[[
	Configuração das missões diárias.

	Todo dia cada jogador recebe algumas missões sorteadas desta lista.
	Ao completar, ganha o dinheiro e o XP na hora.
]]

local Config = {}

-- Quantas missões por dia.
Config.MissionsPerDay = 3

-- Hora (UTC) em que as missões renovam. 3 = meia-noite no horário de Brasília.
Config.ResetHourUTC = 3

-- Tipos de missão:
--   Kill: fazer abates
--   KillWeapon: fazer abates com uma das armas de "Weapons" (nome exato da Tool)
--   Assist: conseguir assistências
--   Streak: chegar numa sequência de abates sem morrer
--   Playtime: jogar X minutos
--   Bounty: coletar recompensas por cabeça
--
-- Em Text, {goal} vira o número da meta.
Config.Pool = {
	{ Id = "kills_10", Type = "Kill", Goal = 10, Text = "Faça {goal} abates", Money = 2000, XP = 300 },
	{ Id = "kills_25", Type = "Kill", Goal = 25, Text = "Faça {goal} abates", Money = 5000, XP = 700 },
	{ Id = "assists_5", Type = "Assist", Goal = 5, Text = "Consiga {goal} assistências", Money = 1500, XP = 250 },
	{ Id = "streak_5", Type = "Streak", Goal = 5, Text = "Faça {goal} abates sem morrer", Money = 3000, XP = 500 },
	{ Id = "playtime_20", Type = "Playtime", Goal = 20, Text = "Jogue {goal} minutos", Money = 1500, XP = 250 },
	{ Id = "bounty_1", Type = "Bounty", Goal = 1, Text = "Colete {goal} recompensa por cabeça", Money = 4000, XP = 600 },
	{
		Id = "sniper_5",
		Type = "KillWeapon",
		Weapons = { "Kar98K", "Barrett M107" },
		Goal = 5,
		Text = "Faça {goal} abates com sniper",
		Money = 3000,
		XP = 500,
	},
	{
		Id = "pistol_5",
		Type = "KillWeapon",
		Weapons = { "Glock 17", "Glock17" },
		Goal = 5,
		Text = "Faça {goal} abates de pistola",
		Money = 3000,
		XP = 500,
	},
	{
		Id = "rifle_15",
		Type = "KillWeapon",
		Weapons = { "AR", "AR10A4", "FAL MOD", "FAL Stock", "G3zão", "TROVÃO V2" },
		Goal = 15,
		Text = "Faça {goal} abates com fuzil",
		Money = 3500,
		XP = 550,
	},
}

-- Posição do botão "MISSÕES" na tela (fica abaixo do "TROCAR TIME").
Config.ButtonPosition = UDim2.new(0, 12, 0.35, 42)

return Config
