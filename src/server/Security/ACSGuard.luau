--[[
	ACSGuard: confere no servidor cada tiro do ACS 2.0.1 antes de aplicar o dano.

	O ACS original confia no que o cliente manda (alvo, distância, multiplicador
	de dano...), o que permite "kill all" e dano infinito. Este módulo refaz
	essas contas no servidor e bloqueia o que não faz sentido.

	Uso (dentro do script do servidor do ACS, na função Damage):
		local settings, mods, distance, hitType = ACSGuard.ValidateHit(player, gun, humanoid, hitType, clientMods)
		if not settings then return end -- tiro bloqueado
		CalculateDMG(player, humanoid, distance, hitType, settings, mods)

	Veja docs/ACS_PATCH.md para o passo a passo.
]]

local Players = game:GetService("Players")

local ACSGuard = {}

ACSGuard.Config = {
	-- Distância máxima de um tiro (em studs). Aumente se o seu mapa tiver
	-- pontos de sniper muito longe.
	MaxRange = 3000,

	-- Folga na distância (o alvo pode ter andado um pouco por causa do ping).
	RangeTolerance = 30,

	-- Maior multiplicador de dano aceito (vem dos acessórios das armas).
	MaxDamageMod = 1.5,
	MaxMinDamageMod = 1.5,

	-- Folga na cadência: aceita até 1.5x a velocidade de tiro da arma
	-- (+ alguns acertos extras, por causa do ping).
	RateTolerance = 1.5,
	ExtraHitsPerSecond = 3,

	-- Máximo de alvos DIFERENTES acertados em 1 segundo.
	-- Escopetas somam a quantidade de balas por tiro.
	MaxTargetsPerSecond = 4,

	-- Advertências até o kick. Cada advertência some depois de StrikeDecay segundos.
	StrikesToKick = 5,
	StrikeDecay = 30,

	KickMessage = "Atividade suspeita detectada. Se foi um engano, entre de novo.",
}

type PlayerState = {
	Hits: { number },
	Targets: { [Humanoid]: number },
	Strikes: { number },
}

local states: { [Player]: PlayerState } = {}

local function getState(player: Player): PlayerState
	local state = states[player]
	if not state then
		state = { Hits = {}, Targets = {}, Strikes = {} }
		states[player] = state
	end
	return state
end

local function prune(list: { number }, now: number, window: number)
	local index = 1
	while index <= #list do
		if now - list[index] > window then
			table.remove(list, index)
		else
			index += 1
		end
	end
end

-- Registra uma advertência; kicka se passar do limite.
local function strike(player: Player, reason: string)
	local config = ACSGuard.Config
	local state = getState(player)
	local now = os.clock()

	prune(state.Strikes, now, config.StrikeDecay)
	table.insert(state.Strikes, now)

	warn(`[ACSGuard] {player.Name} ({player.UserId}): {reason} [{#state.Strikes}/{config.StrikesToKick}]`)

	if #state.Strikes >= config.StrikesToKick then
		warn(`[ACSGuard] {player.Name} foi kickado.`)
		player:Kick(config.KickMessage)
	end
end

local function getRoot(model: Instance?): BasePart?
	if not model or not model:IsA("Model") then
		return nil
	end
	local root = model:FindFirstChild("HumanoidRootPart")
	if root and root:IsA("BasePart") then
		return root
	end
	return model.PrimaryPart
end

local function clampNumber(value: any, default: number, min: number, max: number): number
	local number = tonumber(value) or default
	if number ~= number then -- NaN
		number = default
	end
	return math.clamp(number, min, max)
end

--[[
	Confere um tiro. Retorna (settings, mods, distance, hitType) se o tiro for
	válido, ou nil se deve ser ignorado.
	- settings: status da arma lidos NO SERVIDOR (ignora o que o cliente mandou)
	- mods: multiplicadores de dano já limitados
	- distance: distância calculada pelo servidor
	- hitType: 1 = cabeça, 2 = tronco, 3 = membros
]]
function ACSGuard.ValidateHit(player: Player, gun: any, humanoid: any, hitType: any, clientMods: any)
	local config = ACSGuard.Config
	local character = player.Character
	local ownHumanoid = character and character:FindFirstChildOfClass("Humanoid")
	local ownRoot = getRoot(character)
	if not ownHumanoid or ownHumanoid.Health <= 0 or not ownRoot then
		return nil
	end

	-- A arma tem que ser uma Tool do próprio jogador (na mão ou na mochila).
	if typeof(gun) ~= "Instance" or not gun:IsA("Tool") then
		strike(player, "mandou dano sem uma arma válida")
		return nil
	end
	if gun.Parent ~= character and gun.Parent ~= player:FindFirstChildOfClass("Backpack") then
		strike(player, `mandou dano com uma arma que não é dele ({gun:GetFullName()})`)
		return nil
	end

	local settingsModule = gun:FindFirstChild("ACS_Settings")
	if not settingsModule or not settingsModule:IsA("ModuleScript") then
		strike(player, `arma sem ACS_Settings ({gun.Name})`)
		return nil
	end
	local loaded, settings = pcall(require, settingsModule)
	if not loaded or type(settings) ~= "table" then
		return nil
	end

	-- Alvo
	if typeof(humanoid) ~= "Instance" or not humanoid:IsA("Humanoid") then
		strike(player, "mandou dano num alvo inválido")
		return nil
	end
	if humanoid.Health <= 0 then
		return nil -- já morreu (normal com ping), sem advertência
	end
	local targetCharacter = humanoid.Parent
	if targetCharacter == character then
		strike(player, "tentou se acertar pelo evento de tiro")
		return nil
	end
	local targetRoot = getRoot(targetCharacter)
	if not targetRoot then
		return nil
	end

	-- Distância calculada pelo servidor
	local distance = (ownRoot.Position - targetRoot.Position).Magnitude
	if distance > config.MaxRange + config.RangeTolerance then
		strike(player, `acertou alvo longe demais ({math.floor(distance)} studs)`)
		return nil
	end

	-- Velocidade de tiro
	local now = os.clock()
	local state = getState(player)
	prune(state.Hits, now, 1)
	table.insert(state.Hits, now)

	local shootRate = clampNumber(settings.ShootRate, 600, 1, 5000) -- tiros por minuto
	local bullets = clampNumber(settings.Bullets, 1, 1, 50)
	local allowedHits = (shootRate / 60) * bullets * config.RateTolerance + config.ExtraHitsPerSecond
	if #state.Hits > allowedHits then
		strike(player, `atirando rápido demais ({#state.Hits} acertos em 1s, máximo {math.floor(allowedHits)})`)
		return nil
	end

	-- Alvos diferentes em pouco tempo (kill all)
	state.Targets[humanoid] = now
	local targets = 0
	for target, time in state.Targets do
		if now - time > 1 or target.Parent == nil then
			state.Targets[target] = nil
		else
			targets += 1
		end
	end
	local allowedTargets = config.MaxTargetsPerSecond + (if bullets > 1 then bullets else 0)
	if targets > allowedTargets then
		strike(player, `acertou {targets} alvos diferentes em 1s (possível kill all)`)
		return nil
	end

	-- Multiplicadores (dos acessórios) com limite
	local mods = {
		DamageMod = clampNumber(type(clientMods) == "table" and clientMods.DamageMod, 1, 0, config.MaxDamageMod),
		minDamageMod = clampNumber(type(clientMods) == "table" and clientMods.minDamageMod, 1, 0, config.MaxMinDamageMod),
	}

	local safeHitType = if hitType == 1 or hitType == 2 then hitType else 3

	return settings, mods, distance, safeHitType
end

Players.PlayerRemoving:Connect(function(player)
	states[player] = nil
end)

return ACSGuard
