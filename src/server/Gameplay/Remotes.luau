--[[
	Cria (se não existir) e devolve os RemoteEvents/RemoteFunctions dos
	sistemas de jogo, todos em ReplicatedStorage > GameRemotes.
	Assim ninguém precisa criar remote na mão no Studio.
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Remotes = {}

local function getFolder(): Folder
	local folder = ReplicatedStorage:FindFirstChild("GameRemotes")
	if not folder then
		folder = Instance.new("Folder")
		folder.Name = "GameRemotes"
		folder.Parent = ReplicatedStorage
	end
	return folder :: Folder
end

local function getOrCreate(name: string, className: string): Instance
	local folder = getFolder()
	local existing = folder:FindFirstChild(name)
	if existing and existing.ClassName == className then
		return existing
	end
	local remote = Instance.new(className)
	remote.Name = name
	remote.Parent = folder
	return remote
end

function Remotes.Event(name: string): RemoteEvent
	return getOrCreate(name, "RemoteEvent") :: RemoteEvent
end

function Remotes.Function(name: string): RemoteFunction
	return getOrCreate(name, "RemoteFunction") :: RemoteFunction
end

return Remotes
