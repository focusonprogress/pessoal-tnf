--[[
	Inicia os sistemas de jogo: eventos, recompensa por cabeça e missões.
	(Depende da progressão, que também é iniciada aqui por garantia.)
]]

local ServerScriptService = game:GetService("ServerScriptService")

local Progression = ServerScriptService:WaitForChild("Progression")
local ProgressionService = require(Progression:WaitForChild("ProgressionService"))
local KillTracker = require(Progression:WaitForChild("KillTracker"))

local Gameplay = ServerScriptService:WaitForChild("Gameplay")
local Events = require(Gameplay:WaitForChild("Events"))
local Bounty = require(Gameplay:WaitForChild("Bounty"))
local Missions = require(Gameplay:WaitForChild("Missions"))

-- Confere se a progressão está atualizada (os sistemas novos usam essas funções).
if not ProgressionService.ProfileLoaded or not ProgressionService.GetLiveData then
	error("[Gameplay] O ProgressionService está desatualizado. Cole de novo o arquivo src/server/Progression/ProgressionService.luau")
end
if not KillTracker.PlayerKilled then
	error("[Gameplay] O KillTracker está desatualizado. Cole de novo o arquivo src/server/Progression/KillTracker.luau")
end

ProgressionService.Start()
KillTracker.Start()

-- Eventos de XP em dobro, etc. multiplicam o XP da progressão.
ProgressionService.SetMultiplierProvider(function(player)
	return Events.GetMultiplier(player, "XP")
end)

Events.Start()
Bounty.Start()
Missions.Start()
