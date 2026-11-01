--[[
	Dá dinheiro aos jogadores usando o valor que o jogo já tem
	(leaderstats > Dinheiro). Quem salva é o seu sistema antigo.
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage:WaitForChild("Economy"):WaitForChild("Config"))
local Events = require(script.Parent.Events)

local Money = {}

local function getValue(player: Player): (IntValue | NumberValue)?
	local leaderstats = player:FindFirstChild("leaderstats")
	local value = leaderstats and leaderstats:FindFirstChild(Config.MoneyValueName)
	if value and (value:IsA("IntValue") or value:IsA("NumberValue")) then
		return value
	end
	return nil
end

function Money.Get(player: Player): number
	local value = getValue(player)
	return if value then value.Value else 0
end

-- Soma dinheiro. Aplica o multiplicador de eventos (ex.: dinheiro em dobro),
-- a não ser que ignoreEvents seja true. Retorna quanto foi dado de verdade.
function Money.Add(player: Player, amount: number, ignoreEvents: boolean?): number
	local value = getValue(player)
	if not value then
		warn(`[Money] {player.Name} não tem leaderstats.{Config.MoneyValueName}; dinheiro não foi dado.`)
		return 0
	end

	local multiplier = if ignoreEvents then 1 else Events.GetMultiplier(player, "Money")
	local given = math.floor(amount * multiplier + 0.5)
	value.Value += given
	return given
end

return Money
