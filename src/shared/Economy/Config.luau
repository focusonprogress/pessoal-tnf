--[[
	Configuração do dinheiro do jogo.

	O dinheiro em si é do seu sistema antigo (leaderstats > Dinheiro), que
	também cuida de salvar. Os sistemas novos só somam nesse valor.
]]

local Config = {}

-- Nome do valor dentro de leaderstats.
Config.MoneyValueName = "Dinheiro"

-- Símbolo mostrado antes do valor.
Config.Prefix = "R$"

-- Formata um valor: 15000 -> "R$ 15.000"
function Config.Format(amount: number): string
	local text = tostring(math.floor(amount))
	local formatted = text
	repeat
		local count
		formatted, count = string.gsub(formatted, "^(-?%d+)(%d%d%d)", "%1.%2")
	until count == 0
	return `{Config.Prefix} {formatted}`
end

return Config
