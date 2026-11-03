--[[
	Configuração do modo treino.

	Quem entra num servidor vazio vai para o treino: nasce na área de treino,
	atira em bonecos e recebe dicas. Depois de alguns minutos (ou quando outro
	jogador entra), volta para o modo principal.

	ÁREA DE TREINO (opcional): no Workspace, crie uma Folder chamada "Treino" com:
	  - uma Part chamada "Spawn" (onde o jogador nasce no treino)
	  - várias Parts chamadas "Alvo" (onde os bonecos aparecem)
	Deixe essas Parts com Anchored ligado, CanCollide desligado e Transparency 1.
	Sem a pasta, os bonecos aparecem na frente do jogador, onde ele estiver.
]]

local Config = {}

-- Liga/desliga o modo treino.
Config.Enabled = true

-- Começa o treino se o servidor tiver até essa quantidade de jogadores
-- (contando quem acabou de entrar). 1 = só quando a pessoa está sozinha.
Config.MaxPlayers = 1

-- Duração do treino, em segundos.
Config.Duration = 300

-- Se outro jogador entrar durante o treino, o treino acaba na hora.
Config.EndWhenSomeoneJoins = true

-- Segundos mostrando "Indo para o modo principal" antes de renascer no spawn normal.
Config.ReturnDelay = 4

-- Nome da pasta da área de treino no Workspace.
Config.AreaFolderName = "Treino"

-- Bonecos
Config.Dummies = {
	Name = "Alvo de treino",
	-- Quantos bonecos quando NÃO tem a pasta Treino (com a pasta, é um por Part "Alvo").
	Count = 6,
	Health = 100,
	-- Segundos até um boneco abatido reaparecer.
	RespawnDelay = 3,
	-- Bonecos andam um pouco de um lado para o outro.
	Moving = true,
	MoveRadius = 8,
	WalkSpeed = 8,
	-- Cor do corpo dos bonecos.
	Color = Color3.fromRGB(200, 70, 60),
}

-- Arma entregue durante o treino, se o jogador não tiver nenhuma.
-- Coloque o nome de uma Tool que esteja no ServerStorage (ex.: "Glock 17").
-- nil = não entrega nada (usa as armas que o jogador já ganha ao nascer).
Config.TrainingWeapon = nil :: string?

-- Intro com câmera: quando o jogador chega no treino, a câmera voa até os
-- bonecos, mostra eles e volta. O jogador fica parado durante a intro.
Config.Intro = {
	Enabled = true,
	FlyTime = 2, -- segundos indo até os bonecos
	HoldTime = 3, -- segundos mostrando os bonecos
	ReturnTime = 1.5, -- segundos voltando para o jogador
	Title = "MODO TREINO",
	Subtitle = "Acerte os alvos de treino! Você tem 5 minutos.",
}

-- Dicas mostradas no painel, em ordem. Trocam a cada TipInterval segundos.
Config.TipInterval = 12
Config.Tips = {
	"Bem-vindo ao TNF! Enquanto o servidor enche, treine sua mira aqui.",
	"Use as teclas 1 a 9 (ou toque na hotbar) para pegar suas armas.",
	"Clique para atirar, botão direito para mirar e R para recarregar.",
	"Tiros na cabeça dão muito mais dano. Mire alto!",
	"Abates em jogadores dão XP. Subindo de nível você ganha títulos e libera armas.",
	"Faça 5 abates seguidos sem morrer e sua cabeça fica a prêmio!",
	"Abra MISSÕES para ver as tarefas do dia. Elas dão dinheiro e XP.",
	"Entre todo dia para pegar a recompensa diária no botão DIÁRIO.",
	"Fique de olho nos eventos no topo da tela: XP em dobro, operação policial...",
	"Jogue junto com o seu time. Sozinho no morro ninguém sobrevive!",
}

return Config
