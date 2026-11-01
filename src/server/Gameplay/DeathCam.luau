--[[
	Avisa quem morreu sobre quem matou (para a câmera seguir o assassino
	e mostrar o painel de morte). Usa o RemoteEvent GameRemotes > KilledBy.
]]

local ServerScriptService = game:GetService("ServerScriptService")

local KillTracker = require(ServerScriptService:WaitForChild("Progression"):WaitForChild("KillTracker"))
local Remotes = require(script.Parent.Remotes)

local KilledByRemote = Remotes.Event("KilledBy")

local DeathCam = {}

local started = false

function DeathCam.Start()
	if started then
		return
	end
	started = true

	KillTracker.PlayerKilled:Connect(function(victim: Player?, killer: Player?, weapon: string?)
		if not victim or victim.Parent == nil then
			return
		end

		local killerHealth = nil
		if killer then
			local character = killer.Character
			local humanoid = character and character:FindFirstChildOfClass("Humanoid")
			if humanoid then
				killerHealth = math.ceil(humanoid.Health)
			end
		end

		KilledByRemote:FireClient(victim, killer, weapon, killerHealth)
	end)
end

return DeathCam
