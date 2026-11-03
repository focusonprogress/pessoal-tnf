--[[
	Carrega e salva o progresso dos jogadores no DataStore.

	- Tenta de novo quando o Roblox falha (com espera crescente).
	- Load retorna nil quando falha, para o ProgressionService decidir o que
	  fazer (no jogo publicado ele kicka o jogador para não sobrescrever o
	  progresso salvo com dados zerados).
]]

local DataStoreService = game:GetService("DataStoreService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage.Progression.Config)

local MAX_ATTEMPTS = 3

local PlayerData = {}

local store: DataStore? = nil
do
	local ok, result = pcall(function()
		return DataStoreService:GetDataStore(Config.DataStore.Name)
	end)
	if ok then
		store = result
	else
		warn("[Progression] Não foi possível acessar o DataStore:", result)
	end
end

-- Formato dos dados de um jogador novo.
function PlayerData.Template()
	return {
		Version = 1,
		Level = 1,
		XP = 0, -- XP dentro do nível atual
		TotalXP = 0, -- XP ganho desde sempre
		Kills = 0,
		Deaths = 0,
		Assists = 0,
		BestStreak = 0,
		Missions = {}, -- usado pelo sistema de missões diárias
		LoginStreak = 0, -- dias seguidos resgatando a recompensa diária
		LastLoginClaimDay = -1, -- último dia em que resgatou
		BountiesCollected = 0,
		MissionsCompleted = 0,
		PlaytimeMinutes = 0,
		Achievements = {}, -- conquistas desbloqueadas: { [Id] = true }
		Season = {}, -- progresso do passe de temporada atual
		Titles = {}, -- títulos exclusivos ganhos (lista de nomes)
		EquippedTitle = "", -- título exclusivo equipado ("" = usa o título do nível)
	}
end

-- Garante que todos os campos existem e têm o tipo certo
-- (útil quando novos campos são adicionados ao template no futuro).
local function reconcile(saved: any)
	local data = PlayerData.Template()
	if type(saved) == "table" then
		for key, defaultValue in data do
			if type(saved[key]) == type(defaultValue) then
				data[key] = saved[key]
			end
		end
	end
	return data
end

local function withRetries(callback: () -> any): (boolean, any)
	local lastError
	for attempt = 1, MAX_ATTEMPTS do
		local ok, result = pcall(callback)
		if ok then
			return true, result
		end
		lastError = result
		if attempt < MAX_ATTEMPTS then
			task.wait(2 ^ attempt)
		end
	end
	return false, lastError
end

local function keyFor(userId: number): string
	return Config.DataStore.KeyPrefix .. tostring(userId)
end

-- Retorna os dados do jogador, ou nil se não conseguiu carregar.
function PlayerData.Load(userId: number)
	local dataStore = store
	if not dataStore then
		return nil
	end

	local ok, result = withRetries(function()
		return dataStore:GetAsync(keyFor(userId))
	end)

	if not ok then
		warn(`[Progression] Falha ao carregar dados de {userId}:`, result)
		return nil
	end

	return reconcile(result)
end

-- Salva os dados. Retorna true se deu certo.
function PlayerData.Save(userId: number, data): boolean
	local dataStore = store
	if not dataStore then
		return false
	end

	local snapshot = table.clone(data)
	local ok, result = withRetries(function()
		return dataStore:UpdateAsync(keyFor(userId), function()
			return snapshot
		end)
	end)

	if not ok then
		warn(`[Progression] Falha ao salvar dados de {userId}:`, result)
	end
	return ok
end

return PlayerData
