--[[
	Configuração do painel de admin.

	Fica no servidor (ServerScriptService), então ninguém consegue ver nem mudar.
	O dono do jogo (ou o dono do grupo) e quem estiver no Studio são admin sempre.
]]

local AdminConfig = {}

-- UserIds dos admins. Para descobrir o UserId de alguém: abra o perfil da
-- pessoa no site do Roblox; é o número no link (roblox.com/users/123456/profile).
AdminConfig.Admins = {
	-- 123456789,
}

-- Se o jogo for de um GRUPO: cargos com esse rank ou maior são admin.
-- (0 = desligado)
AdminConfig.GroupMinRank = 0

-- Valores máximos por ação, para evitar erro de digitação gigante.
AdminConfig.MaxMoney = 10000000
AdminConfig.MaxXP = 1000000

return AdminConfig
