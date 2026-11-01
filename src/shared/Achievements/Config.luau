--[[
	Configuração das conquistas.

	Cada conquista olha uma estatística salva do jogador (Stat) e é
	desbloqueada quando ela chega na meta (Goal). Desbloqueou, ganha na hora.

	Estatísticas disponíveis:
	  Kills, Assists, Deaths, BestStreak, Level, BountiesCollected,
	  MissionsCompleted, LoginStreak, PlaytimeMinutes
]]

local Config = {}

Config.List = {
	-- Abates
	{ Id = "kills_1", Name = "Primeiro Sangue", Description = "Faça seu primeiro abate", Stat = "Kills", Goal = 1, Money = 500, XP = 100 },
	{ Id = "kills_100", Name = "Atirador", Description = "Faça 100 abates", Stat = "Kills", Goal = 100, Money = 5000, XP = 1000 },
	{ Id = "kills_500", Name = "Veterano de Guerra", Description = "Faça 500 abates", Stat = "Kills", Goal = 500, Money = 20000, XP = 4000 },
	{ Id = "kills_1000", Name = "Lenda do Morro", Description = "Faça 1.000 abates", Stat = "Kills", Goal = 1000, Money = 50000, XP = 10000 },

	-- Combate
	{ Id = "assists_100", Name = "Parceiro de Troca", Description = "Consiga 100 assistências", Stat = "Assists", Goal = 100, Money = 4000, XP = 800 },
	{ Id = "streak_10", Name = "Imparável", Description = "Faça 10 abates seguidos sem morrer", Stat = "BestStreak", Goal = 10, Money = 5000, XP = 1000 },
	{ Id = "streak_20", Name = "Máquina de Guerra", Description = "Faça 20 abates seguidos sem morrer", Stat = "BestStreak", Goal = 20, Money = 15000, XP = 3000 },
	{ Id = "bounty_10", Name = "Caçador de Recompensas", Description = "Colete 10 recompensas por cabeça", Stat = "BountiesCollected", Goal = 10, Money = 10000, XP = 2000 },

	-- Nível
	{ Id = "level_10", Name = "Subindo de Patente", Description = "Chegue no nível 10", Stat = "Level", Goal = 10, Money = 3000 },
	{ Id = "level_50", Name = "Patente Alta", Description = "Chegue no nível 50", Stat = "Level", Goal = 50, Money = 20000 },
	{ Id = "level_100", Name = "No Topo", Description = "Chegue no nível 100", Stat = "Level", Goal = 100, Money = 100000 },

	-- Dedicação
	{ Id = "missions_30", Name = "Cumpridor de Missões", Description = "Complete 30 missões diárias", Stat = "MissionsCompleted", Goal = 30, Money = 10000, XP = 2000 },
	{ Id = "login_7", Name = "Fiel ao Morro", Description = "Resgate a recompensa diária 7 dias seguidos", Stat = "LoginStreak", Goal = 7, Money = 5000, XP = 1000 },
	{ Id = "playtime_600", Name = "Morador Antigo", Description = "Jogue 10 horas", Stat = "PlaytimeMinutes", Goal = 600, Money = 15000, XP = 3000 },
}

-- Posição do botão "CONQUISTAS" (abaixo de "MISSÕES").
Config.ButtonPosition = UDim2.new(0, 12, 0.35, 84)

return Config
