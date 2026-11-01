--[[
	Configuração da hotbar de armas (substitui a mochila padrão do Roblox).
]]

local Config = {}

-- Quantos espaços a hotbar tem (teclas 1 a 9).
Config.MaxSlots = 9

-- Tamanho de cada espaço e distância entre eles, em pixels.
Config.SlotSize = 64
Config.SlotPadding = 6

-- Distância da hotbar até a parte de baixo da tela.
Config.BottomMargin = 12

-- Mostrar espaços vazios? Com false, só aparecem os espaços com arma
-- e a hotbar fica centralizada.
Config.ShowEmptySlots = false

-- Teclas de cada espaço, na ordem.
Config.Keys = {
	Enum.KeyCode.One,
	Enum.KeyCode.Two,
	Enum.KeyCode.Three,
	Enum.KeyCode.Four,
	Enum.KeyCode.Five,
	Enum.KeyCode.Six,
	Enum.KeyCode.Seven,
	Enum.KeyCode.Eight,
	Enum.KeyCode.Nine,
}

-- Cores (mesmo amarelo da barra de XP).
Config.Colors = {
	Slot = Color3.fromRGB(20, 20, 24),
	SlotEquipped = Color3.fromRGB(45, 40, 20),
	Accent = Color3.fromRGB(255, 196, 0),
	Text = Color3.fromRGB(235, 235, 235),
	TextMuted = Color3.fromRGB(150, 150, 150),
}

return Config
