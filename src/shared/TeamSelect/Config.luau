--[[
	Configuração da tela de escolha de time.
]]

local Config = {}

-- Times que aparecem na tela, na ordem (da esquerda para a direita).
--
--   TeamName: nome do Team no serviço "Teams" do Studio (maiúsculas não importam)
--   DisplayName: nome grande mostrado no card
--   Subtitle: texto pequeno embaixo do nome
--   Color: cor do card
--   Image: imagem do avatar. Para pegar o ID: no seu menu antigo, clique na
--          ImageLabel do avatar, e em Properties copie o campo "Image"
--          (algo como "rbxassetid://1234567890"). Vazio = mostra a inicial do time.
Config.Teams = {
	{
		TeamName = "VERMELHO",
		DisplayName = "VERMELHO",
		Subtitle = "FACÇÃO",
		Color = Color3.fromRGB(230, 40, 40),
		Image = "",
	},
	{
		TeamName = "PMERJ",
		DisplayName = "PMERJ",
		Subtitle = "POLÍCIA MILITAR",
		Color = Color3.fromRGB(40, 120, 255),
		Image = "",
	},
	{
		TeamName = "BOPE",
		DisplayName = "BOPE",
		Subtitle = "OPERAÇÕES ESPECIAIS",
		Color = Color3.fromRGB(205, 140, 70),
		Image = "",
	},
	{
		TeamName = "AMARELO",
		DisplayName = "AMARELO",
		Subtitle = "FACÇÃO",
		Color = Color3.fromRGB(255, 200, 0),
		Image = "",
	},
}

-- Time em que o jogador nasce antes de escolher (nil = Neutral).
-- Não precisa estar na lista acima: ele não aparece como card.
Config.DefaultTeam = "Morador" :: string?

-- Como a imagem é usada:
--   "Avatar": a imagem é só o boneco; o nome e as cores são desenhados pelo script.
--   "FullCard": a imagem já é o card inteiro (com nome, fundo, etc.); o script
--               só coloca o contador de jogadores e o botão por cima.
Config.ImageMode = "Avatar"

-- Textos da tela.
Config.Title = "ESCOLHA SEU TIME"
Config.SubtitlePC = "Clique em um time para entrar"
Config.SubtitleTouch = "Toque em um time para entrar"

-- Mostrar a tela quando o jogador entra no jogo.
Config.ShowOnJoin = true

-- Botão para trocar de time durante a partida.
Config.ChangeTeamButton = {
	Enabled = true,
	Text = "TROCAR TIME",
	-- Posição na tela (UDim2). Mude se ficar em cima de outra coisa do seu HUD.
	Position = UDim2.new(0, 12, 0.35, 0),
	-- Tecla de atalho (ou nil para nenhuma). Ex.: Enum.KeyCode.N
	Key = nil :: Enum.KeyCode?,
}

-- Renascer ao escolher o time (vai para o spawn do time novo).
Config.RespawnOnChoose = true

-- Segundos de espera entre trocas de time (evita abuso para fugir de tiroteio).
Config.ChangeCooldown = 15

-- Máximo de jogadores por time (nil = sem limite).
Config.MaxPlayersPerTeam = nil :: number?

-- Balanceamento: não deixa entrar num time que já tem essa quantidade de
-- jogadores A MAIS que o time com menos gente (nil = desligado).
Config.MaxTeamDifference = nil :: number?

return Config
