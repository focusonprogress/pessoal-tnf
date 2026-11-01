--[[
	Configuração da recompensa por cabeça.

	Quem faz muitos abates seguidos sem morrer fica com a cabeça a prêmio.
	Quem matar ele leva o dinheiro.
]]

local Config = {}

-- A partir de quantos abates seguidos a cabeça fica a prêmio.
Config.StartStreak = 5

-- Valor inicial e quanto aumenta a cada abate a mais.
Config.BaseReward = 1000
Config.RewardPerKill = 500
Config.MaxReward = 20000

-- XP extra para quem coletar a recompensa.
Config.XPReward = 150

-- Avisar o servidor quando a recompensa aumentar, a cada X abates.
Config.AnnounceEvery = 5

-- Marcador acima da cabeça de quem está a prêmio (todo mundo vê).
Config.Marker = {
	Enabled = true,
	-- Aparece através das paredes? Facilita a caçada.
	AlwaysOnTop = true,
	MaxDistance = 300,
}

return Config
