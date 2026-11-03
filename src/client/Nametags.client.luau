--[[
	Tags com nível e título:
	- Acima da cabeça dos outros jogadores (só aliados, se configurado)
	- No chat, antes do nome

	Lê os atributos "Level" e "Title" que o ProgressionService coloca em cada Player.
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TextChatService = game:GetService("TextChatService")

local localPlayer = Players.LocalPlayer
local Config = require(ReplicatedStorage:WaitForChild("Nametags"):WaitForChild("Config"))

local DEFAULT_COLOR = Color3.fromRGB(235, 235, 235)

local neutralTeams: { [string]: boolean } = {}
for _, name in Config.NeutralTeams do
	neutralTeams[string.lower(name)] = true
end

local function isNeutral(player: Player): boolean
	return player.Neutral or player.Team == nil or neutralTeams[string.lower(player.Team.Name)] == true
end

local function isEnemy(player: Player): boolean
	if isNeutral(player) or isNeutral(localPlayer) then
		return false
	end
	return player.Team ~= localPlayer.Team
end

local function teamColor(player: Player): Color3
	if player.Team and not player.Neutral then
		return player.TeamColor.Color
	end
	return DEFAULT_COLOR
end

-- "Nv 12 · Sargento" ou só "Nv 1"
local function tagText(player: Player): string
	local level = player:GetAttribute("Level") or 1
	-- Título exclusivo equipado (passe de temporada) tem prioridade sobre o do nível.
	local title = player:GetAttribute("EquippedTitle")
	if type(title) ~= "string" or title == "" then
		title = player:GetAttribute("Title")
	end
	if type(title) == "string" and title ~= "" then
		return `Nv {level} · {title}`
	end
	return `Nv {level}`
end

---------------------------------------------------------------------------
-- Tag acima da cabeça
---------------------------------------------------------------------------

-- As tags ficam no PlayerGui deste jogador (só ele vê), presas na cabeça de cada personagem.
local playerGui = localPlayer:WaitForChild("PlayerGui")

type Tag = {
	Gui: BillboardGui,
	Info: TextLabel,
	Name: TextLabel,
}

local tags: { [Player]: Tag } = {}

local function createTag(player: Player): Tag
	local gui = Instance.new("BillboardGui")
	gui.Name = `Nametag_{player.Name}`
	gui.Size = UDim2.fromOffset(200, 44)
	gui.StudsOffset = Vector3.new(0, Config.Overhead.Height, 0)
	gui.MaxDistance = Config.Overhead.MaxDistance
	gui.AlwaysOnTop = false
	gui.ResetOnSpawn = false
	gui.Parent = playerGui

	local info = Instance.new("TextLabel")
	info.Name = "Info"
	info.BackgroundTransparency = 1
	info.Size = UDim2.new(1, 0, 0, 16)
	info.Font = Enum.Font.GothamBold
	info.TextSize = 14
	info.TextStrokeTransparency = 0.4
	info.Parent = gui

	local name = Instance.new("TextLabel")
	name.Name = "PlayerName"
	name.BackgroundTransparency = 1
	name.Position = UDim2.fromOffset(0, 16)
	name.Size = UDim2.new(1, 0, 0, 22)
	name.Font = Enum.Font.GothamBlack
	name.TextSize = 18
	name.TextColor3 = Color3.new(1, 1, 1)
	name.TextStrokeTransparency = 0.3
	name.Text = player.DisplayName
	name.Parent = gui

	return { Gui = gui, Info = info, Name = name }
end

local function updateTag(player: Player)
	local tag = tags[player]
	if not tag then
		return
	end

	local character = player.Character
	local head = character and character:FindFirstChild("Head")
	tag.Gui.Adornee = head
	tag.Gui.Enabled = head ~= nil and (Config.Overhead.ShowForEnemies or not isEnemy(player))

	tag.Info.Text = tagText(player)
	tag.Info.TextColor3 = teamColor(player)
end

local function updateAllTags()
	for player in tags do
		updateTag(player)
	end
end

local function hideDefaultName(character: Model)
	local humanoid = character:WaitForChild("Humanoid", 10)
	if humanoid and humanoid:IsA("Humanoid") then
		humanoid.DisplayDistanceType = Enum.HumanoidDisplayDistanceType.None
	end
end

local function onPlayerAdded(player: Player)
	if player == localPlayer then
		-- Ninguém precisa ver a própria tag, mas o time dele muda quem é inimigo.
		player:GetPropertyChangedSignal("Team"):Connect(updateAllTags)
		player:GetPropertyChangedSignal("Neutral"):Connect(updateAllTags)
		return
	end

	tags[player] = createTag(player)

	local function onCharacter(character: Model)
		task.spawn(hideDefaultName, character)
		character:WaitForChild("Head", 10)
		updateTag(player)
	end
	player.CharacterAdded:Connect(onCharacter)
	if player.Character then
		task.spawn(onCharacter, player.Character)
	end

	for _, property in { "Team", "Neutral", "TeamColor" } do
		player:GetPropertyChangedSignal(property):Connect(function()
			updateTag(player)
		end)
	end
	for _, attribute in { "Level", "Title", "EquippedTitle" } do
		player:GetAttributeChangedSignal(attribute):Connect(function()
			updateTag(player)
		end)
	end

	updateTag(player)
end

if Config.Overhead.Enabled then
	Players.PlayerAdded:Connect(onPlayerAdded)
	for _, player in Players:GetPlayers() do
		task.spawn(onPlayerAdded, player)
	end

	Players.PlayerRemoving:Connect(function(player)
		local tag = tags[player]
		if tag then
			tag.Gui:Destroy()
			tags[player] = nil
		end
	end)
end

---------------------------------------------------------------------------
-- Tag no chat
---------------------------------------------------------------------------

local function toHex(color: Color3): string
	return "#" .. color:ToHex()
end

if Config.Chat.Enabled then
	-- Atenção: o Roblox só permite UM OnIncomingMessage por jogo. Se outro
	-- script seu também usa, junte os dois num só.
	TextChatService.OnIncomingMessage = function(message: TextChatMessage)
		local properties = Instance.new("TextChatMessageProperties")
		local source = message.TextSource
		if not source then
			return properties
		end

		local player = Players:GetPlayerByUserId(source.UserId)
		if not player then
			return properties
		end

		local color = toHex(teamColor(player))
		properties.PrefixText = `<font color="{color}">[{tagText(player)}]</font> {message.PrefixText}`
		return properties
	end
end
