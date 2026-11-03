--[[
	Inicia os sistemas de jogo: eventos, recompensa por cabeça, missões,
	recompensa diária, conquistas, câmera de morte, modo treino, passe de
	temporada e painel de admin.

	Cada sistema liga separado: se um der problema, os outros continuam.
	No Output (busque "Gameplay"):
	  ✅ Nome    -> ligou
	  ❌ Nome    -> deu problema (a mensagem diz qual)
	Se um sistema não aparecer nem com ✅ nem com ❌, ele está esperando algum
	objeto que não existe: busque "Infinite" no Output para ver qual.
]]

local ServerScriptService = game:GetService("ServerScriptService")

print("[Gameplay] Iniciando...")

local Progression = ServerScriptService:WaitForChild("Progression")
local ProgressionService = require(Progression:WaitForChild("ProgressionService"))
local KillTracker = require(Progression:WaitForChild("KillTracker"))

-- Confere se a progressão está atualizada (os sistemas novos usam essas funções).
if not ProgressionService.ProfileLoaded or not ProgressionService.GetLiveData then
	error("[Gameplay] ❌ O ProgressionService está desatualizado. Cole de novo o arquivo src/server/Progression/ProgressionService.luau")
end
if not KillTracker.PlayerKilled then
	error("[Gameplay] ❌ O KillTracker está desatualizado. Cole de novo o arquivo src/server/Progression/KillTracker.luau")
end

ProgressionService.Start()
KillTracker.Start()
print("[Gameplay] ✅ Progressão")

local Gameplay = ServerScriptService:WaitForChild("Gameplay")

-- Carrega e liga um sistema da pasta Gameplay. Retorna o módulo ou nil.
local function startSystem(name: string, label: string)
	local module = Gameplay:WaitForChild(name, 10)
	if not module then
		warn(`[Gameplay] ❌ {label}: não encontrei ServerScriptService > Gameplay > {name}`)
		return nil
	end
	if not module:IsA("ModuleScript") then
		warn(`[Gameplay] ❌ {label}: Gameplay > {name} precisa ser ModuleScript (está como {module.ClassName})`)
		return nil
	end

	local loaded, system = pcall(require, module)
	if not loaded then
		warn(`[Gameplay] ❌ {label}: erro ao carregar -> {system}`)
		return nil
	end

	if type(system) == "table" and type(system.Start) == "function" then
		local started, err = pcall(system.Start)
		if not started then
			warn(`[Gameplay] ❌ {label}: erro ao ligar -> {err}`)
			return nil
		end
	end

	print(`[Gameplay] ✅ {label}`)
	return system
end

-- Eventos primeiro: os outros sistemas usam os multiplicadores dele.
local Events = startSystem("Events", "Eventos")
if Events then
	ProgressionService.SetMultiplierProvider(function(player)
		return Events.GetMultiplier(player, "XP")
	end)
end

-- O resto liga em paralelo, para um sistema travado não segurar os outros.
for _, system in {
	{ "Bounty", "Recompensa por cabeça" },
	{ "Missions", "Missões diárias" },
	{ "DailyRewards", "Recompensa diária" },
	{ "Achievements", "Conquistas" },
	{ "DeathCam", "Câmera de morte" },
	{ "Training", "Modo treino" },
	{ "SeasonPass", "Passe de temporada" },
	{ "Admin", "Painel de admin" },
} do
	task.spawn(startSystem, system[1], system[2])
end
