--[[
	Avisos na tela dos jogadores (aparecem no topo, no GameHUD).

	kind muda a cor: "Event" (amarelo), "Bounty" (vermelho), "Mission" (verde).
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Cria ReplicatedStorage > GameRemotes > Announce se não existir.
local function getRemote(): RemoteEvent
	local folder = ReplicatedStorage:FindFirstChild("GameRemotes")
	if not folder then
		folder = Instance.new("Folder")
		folder.Name = "GameRemotes"
		folder.Parent = ReplicatedStorage
	end

	local remote = folder:FindFirstChild("Announce")
	if not remote then
		remote = Instance.new("RemoteEvent")
		remote.Name = "Announce"
		remote.Parent = folder
	end
	return remote :: RemoteEvent
end

local AnnounceRemote = getRemote()

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
