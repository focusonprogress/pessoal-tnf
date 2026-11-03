--[[
	Painel de admin (servidor).

	O botão ADMIN só aparece para quem tem o atributo "IsAdmin", mas isso é só
	visual: TODA ação passa por aqui e é conferida no servidor.
	Ações chegam pelo RemoteFunction GameRemotes > AdminAction.
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local ServerScriptService = game:GetService("ServerScriptService")

local EconomyConfig = require(ReplicatedStorage:WaitForChild("Economy"):WaitForChild("Config"))
local EventsConfig = require(ReplicatedStorage:WaitForChild("GameEvents"):WaitForChild("Config"))
local ProgressionService = require(ServerScriptService:WaitForChild("Progression"):WaitForChild("ProgressionService"))

local AdminConfig = require(script.Parent.AdminConfig)
local Announcer = require(script.Parent.Announcer)
local Events = require(script.Parent.Events)
local Money = require(script.Parent.Money)
local Remotes = require(script.Parent.Remotes)

local ActionRemote = Remotes.Function("AdminAction")

local Admin = {}

local started = false

-- Módulos opcionais (se não existirem, as ações deles só não funcionam).
local function optionalModule(parent: Instance?, name: string)
	local module = parent and parent:FindFirstChild(name)
	if module and module:IsA("ModuleScript") then
		local ok, result = pcall(require, module)
		if ok then
			return result
		end
	end
	return nil
end

function Admin.IsAdmin(player: Player): boolean
	if RunService:IsStudio() then
		return true
	end
	if table.find(AdminConfig.Admins, player.UserId) then
		return true
	end
	if game.CreatorType == Enum.CreatorType.User then
		return player.UserId == game.CreatorId
	end
	if game.CreatorType == Enum.CreatorType.Group then
		local ok, rank = pcall(function()
			return player:GetRankInGroup(game.CreatorId)
		end)
		if ok then
			if rank == 255 then
				return true -- dono do grupo
			end
			return AdminConfig.GroupMinRank > 0 and rank >= AdminConfig.GroupMinRank
		end
	end
	return false
end

local function findPlayer(userId: any): Player?
	if type(userId) ~= "number" then
		return nil
	end
	return Players:GetPlayerByUserId(userId)
end

local function getRoot(player: Player): BasePart?
	local character = player.Character
	local root = character and character:FindFirstChild("HumanoidRootPart")
	return if root and root:IsA("BasePart") then root else nil
end

local function clampAmount(value: any, max: number): number?
	local number = tonumber(value)
	if not number or number ~= number then
		return nil
	end
	return math.clamp(math.floor(number), -max, max)
end

local function logAction(admin: Player, text: string)
	print(`[Admin] {admin.Name}: {text}`)
end

---------------------------------------------------------------------------
-- Ações
---------------------------------------------------------------------------

local actions: { [string]: (admin: Player, ...any) -> (boolean, any?) } = {}

-- Lista de jogadores com estatísticas
actions.players = function()
	local list = {}
	for _, target in Players:GetPlayers() do
		local data = ProgressionService.GetData(target) or {}
		local kills = data.Kills or 0
		local deaths = data.Deaths or 0
		table.insert(list, {
			UserId = target.UserId,
			Name = target.Name,
			DisplayName = target.DisplayName,
			Team = if target.Team and not target.Neutral then target.Team.Name else "Neutro",
			Level = data.Level or 1,
			Kills = kills,
			Deaths = deaths,
			KD = if deaths > 0 then math.floor(kills / deaths * 100) / 100 else kills,
			Money = Money.Get(target),
			Playtime = data.PlaytimeMinutes or 0,
			Bounty = target:GetAttribute("Bounty") or 0,
			InTraining = target:GetAttribute("TrainingEndsAt") ~= nil,
		})
	end
	return true, list
end

actions.giveMoney = function(admin, userId, amount)
	local target = findPlayer(userId)
	local value = clampAmount(amount, AdminConfig.MaxMoney)
	if not target or not value then
		return false, "Jogador ou valor inválido"
	end
	Money.Add(target, value, true)
	logAction(admin, `deu {value} de dinheiro para {target.Name}`)
	Announcer.To(target, `💰 Um admin te deu {EconomyConfig.Format(value)}!`, "Daily")
	return true, `{EconomyConfig.Format(value)} para {target.Name}`
end

actions.giveXP = function(admin, userId, amount)
	local target = findPlayer(userId)
	local value = clampAmount(amount, AdminConfig.MaxXP)
	if not target or not value or value <= 0 then
		return false, "Jogador ou valor inválido"
	end
	ProgressionService.AddXP(target, value, "Presente de admin")
	logAction(admin, `deu {value} XP para {target.Name}`)
	return true, `{value} XP para {target.Name}`
end

actions.setLevel = function(admin, userId, level)
	local target = findPlayer(userId)
	local value = tonumber(level)
	if not target or not value then
		return false, "Jogador ou nível inválido"
	end
	ProgressionService.SetLevel(target, value)
	logAction(admin, `mudou o nível de {target.Name} para {value}`)
	return true, `{target.Name} agora é nível {ProgressionService.GetLevel(target)}`
end

actions.kick = function(admin, userId, reason)
	local target = findPlayer(userId)
	if not target then
		return false, "Jogador não encontrado"
	end
	if target == admin then
		return false, "Você não pode se kickar"
	end
	local message = if type(reason) == "string" and reason ~= "" then string.sub(reason, 1, 200) else "Removido por um admin."
	logAction(admin, `kickou {target.Name} ({message})`)
	target:Kick(message)
	return true, `{target.Name} foi kickado`
end

actions.teleportTo = function(admin, userId)
	local target = findPlayer(userId)
	local targetRoot = target and getRoot(target)
	local adminCharacter = admin.Character
	if not targetRoot or not adminCharacter then
		return false, "Não foi possível teleportar"
	end
	adminCharacter:PivotTo(targetRoot.CFrame * CFrame.new(0, 0, 4))
	return true, `Você foi até {target.Name}`
end

actions.bring = function(admin, userId)
	local target = findPlayer(userId)
	local adminRoot = getRoot(admin)
	if not target or not target.Character or not adminRoot then
		return false, "Não foi possível puxar"
	end
	target.Character:PivotTo(adminRoot.CFrame * CFrame.new(0, 0, -4))
	logAction(admin, `puxou {target.Name}`)
	return true, `{target.Name} veio até você`
end

actions.clearBounty = function(admin, userId)
	local target = findPlayer(userId)
	if not target then
		return false, "Jogador não encontrado"
	end
	target:SetAttribute("Bounty", nil)
	logAction(admin, `tirou a recompensa de {target.Name}`)
	return true, `Recompensa de {target.Name} removida`
end

actions.givePremium = function(admin, userId)
	local target = findPlayer(userId)
	local SeasonPass = optionalModule(script.Parent, "SeasonPass")
	if not target or not SeasonPass then
		return false, "Jogador ou passe não encontrado"
	end
	SeasonPass.GrantPremium(target)
	logAction(admin, `deu o Premium (sessão) para {target.Name}`)
	Announcer.To(target, "⭐ Um admin te deu o Passe Premium nesta sessão!", "Daily")
	return true, `Premium para {target.Name} (até sair do jogo)`
end

actions.endTraining = function(admin, userId)
	local target = findPlayer(userId)
	local Training = optionalModule(script.Parent, "Training")
	if not target or not Training then
		return false, "Jogador ou treino não encontrado"
	end
	Training.End(target, "Um admin encerrou seu treino.")
	return true, `Treino de {target.Name} encerrado`
end

-- Servidor
actions.events = function()
	local list = {}
	for _, event in EventsConfig.Events do
		table.insert(list, { Id = event.Id, Name = event.Name })
	end
	local current = Events.GetCurrent()
	return true, { List = list, Current = if current then current.Id else nil }
end

actions.startEvent = function(admin, eventId)
	if type(eventId) ~= "string" or not Events.StartEvent(eventId) then
		return false, "Evento inválido"
	end
	logAction(admin, `começou o evento {eventId}`)
	return true, "Evento começou"
end

actions.stopEvent = function(admin)
	Events.StopEvent()
	logAction(admin, "parou o evento")
	return true, "Evento parado"
end

actions.announce = function(admin, text)
	if type(text) ~= "string" or text == "" then
		return false, "Mensagem vazia"
	end
	local message = string.sub(text, 1, 150)
	logAction(admin, `anunciou: {message}`)
	Announcer.All(`📢 {message}`, "Event")
	return true, "Aviso enviado"
end

actions.guardLog = function()
	local ACSGuard = optionalModule(ServerScriptService:FindFirstChild("Security"), "ACSGuard")
	if not ACSGuard or not ACSGuard.GetLog then
		return false, "ACSGuard não encontrado"
	end
	return true, ACSGuard.GetLog()
end

---------------------------------------------------------------------------
-- Início
---------------------------------------------------------------------------

function Admin.Start()
	if started then
		return
	end
	started = true

	ActionRemote.OnServerInvoke = function(player: Player, action: any, ...)
		if not Admin.IsAdmin(player) then
			warn(`[Admin] {player.Name} tentou usar o painel sem ser admin ({tostring(action)})`)
			return false, "Sem permissão"
		end
		local handler = type(action) == "string" and actions[action]
		if not handler then
			return false, "Ação inválida"
		end
		local ok, success, result = pcall(handler, player, ...)
		if not ok then
			warn(`[Admin] Erro na ação {action}:`, success)
			return false, "Erro ao executar"
		end
		return success, result
	end

	local function onPlayerAdded(player: Player)
		if Admin.IsAdmin(player) then
			player:SetAttribute("IsAdmin", true)
		end
	end
	Players.PlayerAdded:Connect(onPlayerAdded)
	for _, player in Players:GetPlayers() do
		task.spawn(onPlayerAdded, player)
	end
end

return Admin
