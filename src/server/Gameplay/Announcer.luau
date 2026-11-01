--[[
	Avisos na tela dos jogadores (aparecem no topo, no GameHUD).

	kind muda a cor: "Event" (amarelo), "Bounty" (vermelho), "Mission" (verde),
	"Achievement" (roxo), "Daily" (amarelo).
]]

local Remotes = require(script.Parent.Remotes)

local AnnounceRemote = Remotes.Event("Announce")

local Announcer = {}

-- Aviso para todos os jogadores.
function Announcer.All(text: string, kind: string?)
	AnnounceRemote:FireAllClients(text, kind)
end

-- Aviso só para um jogador.
function Announcer.To(player: Player, text: string, kind: string?)
	AnnounceRemote:FireClient(player, text, kind)
end

return Announcer
