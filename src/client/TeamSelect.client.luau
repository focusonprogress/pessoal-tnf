--[[
	Tela de escolha de time.

	- Se adapta ao tamanho da tela: 4 cards em linha no PC/celular deitado,
	  grade 2x2 no celular em pé
	- O card inteiro é clicável (bom para celular)
	- Mostra quantos jogadores tem em cada time, em tempo real
	- Botão "TROCAR TIME" para abrir de novo durante a partida
]]

local Lighting = game:GetService("Lighting")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")

local player = Players.LocalPlayer
local TeamSelect = ReplicatedStorage:WaitForChild("TeamSelect")
local Config = require(TeamSelect:WaitForChild("Config"))
local TeamLookup = require(TeamSelect:WaitForChild("TeamLookup"))
local ChooseTeam = ReplicatedStorage:WaitForChild("TeamSelectRemotes"):WaitForChild("ChooseTeam") :: RemoteFunction

local CARD_RATIO = 0.56 -- largura / altura do card
local MAX_CARD_WIDTH = 260
local CARD_BACKGROUND = Color3.fromRGB(14, 14, 18)
local DISABLED = Color3.fromRGB(70, 70, 76)
local FULL_CARD = Config.ImageMode == "FullCard"

---------------------------------------------------------------------------
-- Helpers de interface
---------------------------------------------------------------------------

local function create(className: string, props: { [string]: any }): any
	local instance = Instance.new(className)
	local parent = props.Parent
	for key, value in props do
		if key ~= "Parent" then
			(instance :: any)[key] = value
		end
	end
	instance.Parent = parent
	return instance
end

local function corner(parent: Instance, radius: number)
	create("UICorner", { CornerRadius = UDim.new(0, radius), Parent = parent })
end

-- Texto que cresce/diminui com o tamanho do card.
local function scaledText(props: { [string]: any }): TextLabel
	local maxSize = props.MaxTextSize or 24
	props.MaxTextSize = nil

	local textLabel = create("TextLabel", {
		BackgroundTransparency = 1,
		Font = Enum.Font.GothamBlack,
		TextColor3 = Color3.new(1, 1, 1),
		TextScaled = true,
		Parent = props.Parent,
	})
	for key, value in props do
		if key ~= "Parent" then
			(textLabel :: any)[key] = value
		end
	end
	create("UITextSizeConstraint", { MaxTextSize = maxSize, MinTextSize = 6, Parent = textLabel })
	return textLabel
end

---------------------------------------------------------------------------
-- Tela principal
---------------------------------------------------------------------------

local gui = create("ScreenGui", {
	Name = "TeamSelect",
	ResetOnSpawn = false,
	IgnoreGuiInset = true,
	DisplayOrder = 20,
	ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
	Enabled = false,
	Parent = player:WaitForChild("PlayerGui"),
})

local overlay = create("Frame", {
	Name = "Overlay",
	Size = UDim2.fromScale(1, 1),
	BackgroundColor3 = Color3.new(0, 0, 0),
	BackgroundTransparency = 0.25,
	BorderSizePixel = 0,
	Parent = gui,
})
create("UIGradient", {
	Rotation = 90,
	Transparency = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 0.1),
		NumberSequenceKeypoint.new(0.5, 0.35),
		NumberSequenceKeypoint.new(1, 0.1),
	}),
	Parent = overlay,
})

local title = scaledText({
	Name = "Title",
	AnchorPoint = Vector2.new(0.5, 1),
	Size = UDim2.new(0.9, 0, 0, 40),
	Text = Config.Title,
	MaxTextSize = 46,
	Parent = gui,
})

local isTouchOnly = UserInputService.TouchEnabled and not UserInputService.KeyboardEnabled
local subtitle = scaledText({
	Name = "Subtitle",
	AnchorPoint = Vector2.new(0.5, 0),
	Size = UDim2.new(0.9, 0, 0, 18),
	Font = Enum.Font.GothamMedium,
	TextColor3 = Color3.fromRGB(190, 190, 190),
	Text = if isTouchOnly then Config.SubtitleTouch else Config.SubtitlePC,
	MaxTextSize = 18,
	Parent = gui,
})

local closeButton = create("TextButton", {
	Name = "Close",
	AnchorPoint = Vector2.new(1, 0.5),
	Size = UDim2.fromOffset(40, 40),
	BackgroundColor3 = CARD_BACKGROUND,
	BackgroundTransparency = 0.2,
	Font = Enum.Font.GothamBlack,
	Text = "X",
	TextColor3 = Color3.new(1, 1, 1),
	TextSize = 18,
	AutoButtonColor = true,
	Visible = false,
	Parent = gui,
})
corner(closeButton, 20)

local message = scaledText({
	Name = "Message",
	AnchorPoint = Vector2.new(0.5, 1),
	Position = UDim2.new(0.5, 0, 1, -12),
	Size = UDim2.new(0.9, 0, 0, 22),
	Font = Enum.Font.GothamBold,
	TextColor3 = Color3.fromRGB(255, 90, 90),
	TextStrokeTransparency = 0.5,
	Text = "",
	MaxTextSize = 18,
	Parent = gui,
})

local cardsHolder = create("Frame", {
	Name = "Cards",
	Size = UDim2.fromScale(1, 1),
	BackgroundTransparency = 1,
	Parent = gui,
})

---------------------------------------------------------------------------
-- Cards
---------------------------------------------------------------------------

type Card = {
	Entry: any,
	Root: TextButton,
	Scale: UIScale,
	Stroke: UIStroke,
	Count: TextLabel,
	Action: Frame,
	ActionStroke: UIStroke,
	ActionLabel: TextLabel,
}

local cards: { Card } = {}

local function createCard(entry, index: number): Card
	local color: Color3 = entry.Color

	local root = create("TextButton", {
		Name = entry.TeamName,
		AnchorPoint = Vector2.new(0.5, 0.5),
		BackgroundColor3 = CARD_BACKGROUND,
		AutoButtonColor = false,
		Text = "",
		ClipsDescendants = true,
		LayoutOrder = index,
		Parent = cardsHolder,
	})
	corner(root, 12)

	local scale = create("UIScale", { Parent = root })
	local stroke = create("UIStroke", {
		ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
		Color = color,
		Thickness = 2,
		Transparency = 0.45,
		Parent = root,
	})

	local hasImage = type(entry.Image) == "string" and entry.Image ~= ""

	if FULL_CARD and hasImage then
		create("ImageLabel", {
			Name = "CardImage",
			Size = UDim2.fromScale(1, 1),
			BackgroundTransparency = 1,
			Image = entry.Image,
			ScaleType = Enum.ScaleType.Crop,
			Parent = root,
		})
	else
		-- Brilho da cor do time vindo de cima
		local glow = create("Frame", {
			Name = "Glow",
			Size = UDim2.fromScale(1, 1),
			BackgroundColor3 = color,
			BorderSizePixel = 0,
			Parent = root,
		})
		create("UIGradient", {
			Rotation = 90,
			Transparency = NumberSequence.new({
				NumberSequenceKeypoint.new(0, 0.55),
				NumberSequenceKeypoint.new(0.55, 0.88),
				NumberSequenceKeypoint.new(1, 1),
			}),
			Parent = glow,
		})

		scaledText({
			Name = "TeamName",
			Position = UDim2.fromScale(0.06, 0.035),
			Size = UDim2.fromScale(0.88, 0.1),
			Text = entry.DisplayName,
			TextColor3 = color,
			TextStrokeTransparency = 0.6,
			MaxTextSize = 34,
			Parent = root,
		})

		scaledText({
			Name = "Subtitle",
			Position = UDim2.fromScale(0.06, 0.14),
			Size = UDim2.fromScale(0.88, 0.04),
			Font = Enum.Font.GothamBold,
			Text = entry.Subtitle or "",
			TextColor3 = Color3.fromRGB(210, 210, 210),
			MaxTextSize = 14,
			Parent = root,
		})

		create("Frame", {
			Name = "Divider",
			AnchorPoint = Vector2.new(0.5, 0),
			Position = UDim2.fromScale(0.5, 0.195),
			Size = UDim2.new(0.5, 0, 0, 2),
			BackgroundColor3 = color,
			BorderSizePixel = 0,
			Parent = root,
		})

		if hasImage then
			create("ImageLabel", {
				Name = "Avatar",
				AnchorPoint = Vector2.new(0.5, 0),
				Position = UDim2.fromScale(0.5, 0.215),
				Size = UDim2.fromScale(0.96, 0.56),
				BackgroundTransparency = 1,
				Image = entry.Image,
				ScaleType = Enum.ScaleType.Fit,
				Parent = root,
			})
		else
			-- Sem imagem: inicial do time bem grande
			scaledText({
				Name = "Initial",
				AnchorPoint = Vector2.new(0.5, 0),
				Position = UDim2.fromScale(0.5, 0.26),
				Size = UDim2.fromScale(0.8, 0.45),
				Text = string.sub(entry.DisplayName, 1, 1),
				TextColor3 = color,
				TextTransparency = 0.7,
				MaxTextSize = 200,
				Parent = root,
			})
		end
	end

	-- Sombra embaixo para o texto ficar legível em cima da imagem
	local shade = create("Frame", {
		Name = "Shade",
		AnchorPoint = Vector2.new(0, 1),
		Position = UDim2.fromScale(0, 1),
		Size = UDim2.fromScale(1, 0.3),
		BackgroundColor3 = Color3.new(0, 0, 0),
		BorderSizePixel = 0,
		Parent = root,
	})
	create("UIGradient", {
		Rotation = 90,
		Transparency = NumberSequence.new({
			NumberSequenceKeypoint.new(0, 1),
			NumberSequenceKeypoint.new(0.45, 0.25),
			NumberSequenceKeypoint.new(1, 0.1),
		}),
		Parent = shade,
	})

	local count = scaledText({
		Name = "PlayerCount",
		Position = UDim2.fromScale(0.06, 0.785),
		Size = UDim2.fromScale(0.88, 0.065),
		Font = Enum.Font.GothamBold,
		Text = "0 JOGADORES",
		MaxTextSize = 16,
		Parent = root,
	})

	local action = create("Frame", {
		Name = "Action",
		Position = UDim2.fromScale(0.06, 0.87),
		Size = UDim2.fromScale(0.88, 0.095),
		BackgroundColor3 = color,
		Parent = root,
	})
	corner(action, 8)
	local actionStroke = create("UIStroke", {
		ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
		Color = color,
		Thickness = 2,
		Transparency = 1,
		Parent = action,
	})

	local actionLabel = scaledText({
		Name = "Label",
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.5),
		Size = UDim2.fromScale(0.9, 0.6),
		Text = "ENTRAR",
		TextColor3 = CARD_BACKGROUND,
		MaxTextSize = 20,
		Parent = action,
	})

	return {
		Entry = entry,
		Root = root,
		Scale = scale,
		Stroke = stroke,
		Count = count,
		Action = action,
		ActionStroke = actionStroke,
		ActionLabel = actionLabel,
	}
end

for index, entry in Config.Teams do
	table.insert(cards, createCard(entry, index))
end

---------------------------------------------------------------------------
-- Layout responsivo
---------------------------------------------------------------------------

local function layout()
	local size = gui.AbsoluteSize
	local count = #cards
	if size.X <= 0 or size.Y <= 0 or count == 0 then
		return
	end

	-- Tela deitada e larga: todos em linha. Senão: 2 por linha.
	local landscape = size.X / size.Y > 1.2 and size.X >= 600
	local columns = if landscape then count else math.min(2, count)
	local rows = math.ceil(count / columns)

	local gap = math.clamp(size.X * 0.015, 8, 20)
	local top = math.clamp(size.Y * 0.2, 70, 140)
	local bottom = math.clamp(size.Y * 0.07, 30, 60)
	local side = math.clamp(size.X * 0.04, 12, 60)

	local availableWidth = size.X - side * 2 - gap * (columns - 1)
	local availableHeight = size.Y - top - bottom - gap * (rows - 1)

	local cardWidth = math.min(availableWidth / columns, MAX_CARD_WIDTH)
	local cardHeight = cardWidth / CARD_RATIO
	if cardHeight * rows > availableHeight then
		cardHeight = availableHeight / rows
		cardWidth = cardHeight * CARD_RATIO
	end

	local totalWidth = cardWidth * columns + gap * (columns - 1)
	local totalHeight = cardHeight * rows + gap * (rows - 1)
	local startX = (size.X - totalWidth) / 2
	local startY = top + (size.Y - top - bottom - totalHeight) / 2

	for index, card in cards do
		local column = (index - 1) % columns
		local row = (index - 1) // columns

		-- Centraliza a última linha se ela estiver incompleta
		local itemsInRow = math.min(columns, count - row * columns)
		local rowOffset = (columns - itemsInRow) * (cardWidth + gap) / 2

		card.Root.Size = UDim2.fromOffset(cardWidth, cardHeight)
		card.Root.Position = UDim2.fromOffset(
			startX + rowOffset + column * (cardWidth + gap) + cardWidth / 2,
			startY + row * (cardHeight + gap) + cardHeight / 2
		)
	end

	title.Position = UDim2.new(0.5, 0, 0, top * 0.55)
	title.Size = UDim2.new(0.9, 0, 0, top * 0.3)
	subtitle.Position = UDim2.new(0.5, 0, 0, top * 0.6)
	subtitle.Size = UDim2.new(0.9, 0, 0, top * 0.14)
	closeButton.Position = UDim2.new(1, -side, 0, top * 0.45)
end

gui:GetPropertyChangedSignal("AbsoluteSize"):Connect(layout)

---------------------------------------------------------------------------
-- Estado dos cards (jogadores, seu time, cheio)
---------------------------------------------------------------------------

local busy = false

local function refreshCard(card: Card)
	local entry = card.Entry
	local team = TeamLookup.FindTeam(entry.TeamName)
	local players = if team then #team:GetPlayers() else 0
	card.Count.Text = if players == 1 then "1 JOGADOR" else `{players} JOGADORES`

	local isMine = team ~= nil and player.Team == team and not player.Neutral
	local blockReason = team and TeamLookup.GetJoinBlockReason(team, player)

	local actionText, actionColor, outlined
	if not team then
		actionText, actionColor, outlined = "INDISPONÍVEL", DISABLED, false
	elseif isMine then
		actionText, actionColor, outlined = "SEU TIME", entry.Color, true
	elseif blockReason then
		actionText, actionColor, outlined = "CHEIO", DISABLED, false
	else
		actionText, actionColor, outlined = "ENTRAR", entry.Color, false
	end

	card.ActionLabel.Text = actionText
	card.Action.BackgroundColor3 = actionColor
	card.Action.BackgroundTransparency = if outlined then 1 else 0
	card.ActionStroke.Transparency = if outlined then 0 else 1
	card.ActionLabel.TextColor3 = if outlined then entry.Color else CARD_BACKGROUND
	card.Stroke.Transparency = if isMine then 0 else 0.45
end

local function refreshAll()
	for _, card in cards do
		refreshCard(card)
	end
end

-- Atualiza quando alguém entra/sai de um time ou do jogo.
local watchedTeams: { [Team]: boolean } = {}
local function watchTeams()
	for _, entry in Config.Teams do
		local team = TeamLookup.FindTeam(entry.TeamName)
		if team and not watchedTeams[team] then
			watchedTeams[team] = true
			team.PlayerAdded:Connect(refreshAll)
			team.PlayerRemoved:Connect(refreshAll)
		end
	end
end
player:GetPropertyChangedSignal("Team"):Connect(refreshAll)
player:GetPropertyChangedSignal("Neutral"):Connect(refreshAll)
Players.PlayerRemoving:Connect(function()
	task.defer(refreshAll)
end)

---------------------------------------------------------------------------
-- Abrir / fechar
---------------------------------------------------------------------------

local changeTeamGui: ScreenGui? = nil
local messageToken = 0

local function showMessage(text: string)
	messageToken += 1
	local token = messageToken
	message.Text = text
	task.delay(3, function()
		if messageToken == token then
			message.Text = ""
		end
	end)
end

local function hasValidTeam(): boolean
	if player.Neutral or not player.Team then
		return false
	end
	for _, entry in Config.Teams do
		if TeamLookup.FindTeam(entry.TeamName) == player.Team then
			return true
		end
	end
	return false
end

local function setBlur(size: number)
	local blur = Lighting:FindFirstChild("TeamSelectBlur")
	if not blur then
		if size <= 0 then
			return
		end
		blur = create("BlurEffect", { Name = "TeamSelectBlur", Size = 0, Parent = Lighting })
	end
	TweenService:Create(blur, TweenInfo.new(0.3), { Size = size }):Play()
end

local function open()
	watchTeams()
	refreshAll()
	closeButton.Visible = hasValidTeam()
	message.Text = ""
	gui.Enabled = true
	layout()
	setBlur(16)
	if changeTeamGui then
		changeTeamGui.Enabled = false
	end
end

local function close()
	gui.Enabled = false
	setBlur(0)
	for _, card in cards do
		card.Scale.Scale = 1
	end
	if changeTeamGui then
		changeTeamGui.Enabled = true
	end
end

local function choose(card: Card)
	if busy then
		return
	end
	busy = true
	card.ActionLabel.Text = "..."

	local ok, success, reason = pcall(ChooseTeam.InvokeServer, ChooseTeam, card.Entry.TeamName)
	busy = false

	if ok and success then
		close()
	else
		showMessage(if ok then reason or "Não foi possível entrar nesse time" else "Erro de conexão, tente de novo")
		refreshAll()
	end
end

for _, card in cards do
	card.Root.Activated:Connect(function()
		choose(card)
	end)
	card.Root.MouseEnter:Connect(function()
		TweenService:Create(card.Scale, TweenInfo.new(0.15), { Scale = 1.04 }):Play()
	end)
	card.Root.MouseLeave:Connect(function()
		TweenService:Create(card.Scale, TweenInfo.new(0.15), { Scale = 1 }):Play()
	end)
end

closeButton.Activated:Connect(close)

---------------------------------------------------------------------------
-- Botão "TROCAR TIME"
---------------------------------------------------------------------------

local buttonConfig = Config.ChangeTeamButton
if buttonConfig.Enabled then
	local buttonGui = create("ScreenGui", {
		Name = "TeamSelectButton",
		ResetOnSpawn = false,
		DisplayOrder = 5,
		Parent = player:WaitForChild("PlayerGui"),
	})
	changeTeamGui = buttonGui

	local button = create("TextButton", {
		Name = "ChangeTeam",
		Position = buttonConfig.Position,
		Size = UDim2.fromOffset(120, 34),
		BackgroundColor3 = CARD_BACKGROUND,
		BackgroundTransparency = 0.2,
		Font = Enum.Font.GothamBold,
		Text = buttonConfig.Text,
		TextColor3 = Color3.new(1, 1, 1),
		TextSize = 13,
		Parent = buttonGui,
	})
	corner(button, 8)
	create("UIStroke", {
		ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
		Color = Color3.fromRGB(255, 196, 0),
		Thickness = 1.5,
		Transparency = 0.3,
		Parent = button,
	})

	button.Activated:Connect(open)
end

if buttonConfig.Key then
	UserInputService.InputBegan:Connect(function(input, gameProcessed)
		if not gameProcessed and input.KeyCode == buttonConfig.Key then
			if gui.Enabled then
				if closeButton.Visible then
					close()
				end
			else
				open()
			end
		end
	end)
end

if Config.ShowOnJoin then
	open()
end
