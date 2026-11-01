--[[
	Inicia os sistemas de jogo: eventos, recompensa por cabeça e missões.
	(Depende da progressão, que também é iniciada aqui por garantia.)

	As mensagens "[Gameplay] ..." no Output mostram até onde o script chegou.
	Se ele parar numa etapa, o problema está no objeto daquela etapa.
]]

local ServerScriptService = game:GetService("ServerScriptService")

print("[Gameplay] 1/5 Iniciando...")

local Progression = ServerScriptService:WaitForChild("Progression")
local ProgressionService = require(Progression:WaitForChild("ProgressionService"))
local KillTracker = require(Progression:WaitForChild("KillTracker"))
print("[Gameplay] 2/5 Progressão carregada")

-- Confere se a progressão está atualizada (os sistemas novos usam essas funções).
if not ProgressionService.ProfileLoaded or not ProgressionService.GetLiveData then
	error("[Gameplay] O ProgressionService está desatualizado. Cole de novo o arquivo src/server/Progression/ProgressionService.luau")
end
if not KillTracker.PlayerKilled then
	error("[Gameplay] O KillTracker está desatualizado. Cole de novo o arquivo src/server/Progression/KillTracker.luau")
end

local Gameplay = ServerScriptService:WaitForChild("Gameplay")
local Events = require(Gameplay:WaitForChild("Events"))
print("[Gameplay] 3/5 Eventos carregados")
local Bounty = require(Gameplay:WaitForChild("Bounty"))
print("[Gameplay] 4/5 Recompensa carregada")
local Missions = require(Gameplay:WaitForChild("Missions"))

ProgressionService.Start()
KillTracker.Start()

-- Eventos de XP em dobro, etc. multiplicam o XP da progressão.
ProgressionService.SetMultiplierProvider(function(player)
	return Events.GetMultiplier(player, "XP")
end)

Events.Start()
Bounty.Start()
Missions.Start()
print("[Gameplay] 5/5 Tudo pronto! Eventos, recompensa e missões funcionando.")
