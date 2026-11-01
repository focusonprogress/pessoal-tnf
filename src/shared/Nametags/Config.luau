--[[
	Configuração das tags acima da cabeça e no chat.
	Usa o nível e o título do sistema de progressão.
]]

local Config = {}

-- Tag acima da cabeça
Config.Overhead = {
	Enabled = true,

	-- Distância máxima (em studs) para ver a tag.
	MaxDistance = 80,

	-- Mostrar a tag dos inimigos? Com false, você só vê a tag de aliados
	-- (e de times neutros), o que evita entregar a posição de quem está escondido.
	ShowForEnemies = false,

	-- Altura da tag acima da cabeça (em studs).
	Height = 2.6,
}

-- Tag no chat: "[Soldado] Fulano: mensagem", com a cor do time.
Config.Chat = {
	Enabled = true,
}

-- Times que contam como neutros: todo mundo vê a tag deles e eles veem a de todos.
Config.NeutralTeams = {
	"Morador",
}

return Config
