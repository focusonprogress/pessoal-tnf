--[[
	Contas de nível e XP, usadas pelo servidor e pelo HUD.
]]

local Config = require(script.Parent.Config)

local LevelMath = {}

-- XP necessário para sair de `level` e chegar no próximo nível.
-- Retorna 0 no nível máximo.
function LevelMath.XPToNext(level: number): number
	if level >= Config.MaxLevel then
		return 0
	end

	local curve = Config.XPCurve
	return math.floor(curve.Base + curve.Growth * (level - 1) ^ curve.Exponent)
end

-- XP total acumulado necessário para chegar em `level` a partir do nível 1.
function LevelMath.TotalXPForLevel(level: number): number
	local total = 0
	for current = 1, math.min(level, Config.MaxLevel) - 1 do
		total += LevelMath.XPToNext(current)
	end
	return total
end

-- Recompensa configurada para um nível (ou nil).
function LevelMath.GetReward(level: number)
	return Config.LevelRewards[level]
end

-- Título mais alto que o jogador já conquistou até `level` (ou nil).
function LevelMath.GetTitle(level: number): string?
	for current = level, 1, -1 do
		local reward = Config.LevelRewards[current]
		if reward and reward.Title then
			return reward.Title
		end
	end
	return nil
end

return LevelMath
