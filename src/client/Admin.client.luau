--[[
	Painel de admin (tela). Só aparece para quem tem o atributo "IsAdmin".
	Toda ação é conferida no servidor (Gameplay > Admin).

	Abas:
	  JOGADORES -> estatísticas e ações (dinheiro, XP, nível, kick, teleporte...)
	  SERVIDOR  -> eventos e aviso para todos
	  LOG       -> advertências do ACSGuard
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local player = Players.LocalPlayer

local DARK = Color3.fromRGB(14, 14, 18)
local CARD = Color3.fromRGB(28, 28, 34)
local RED = Color3.fromRGB(255, 70, 60)
local ACCENT = Color3.fromRGB(255, 196, 0)
local DONE = Color3.fromRGB(80, 220, 120)
local MUTED = Color3.fromRGB(150, 150, 150)
local PANEL_WIDTH = 680
local PANEL_HEIGHT = 440

-- Espera o servidor dizer se é admin (até 15s).
local deadline = os.clock() + 15
while player:GetAttribute("IsAdmin") ~= true and os.clock() < deadline do
	task.wait(0.5)
end
if player:GetAttribute("IsAdmin") ~= true then
	return
end

local ActionRemote = ReplicatedStorage:WaitForChild("GameRemotes"):WaitForChild("AdminAction") :: RemoteFunction

local function corner(parent: Instance, radius: number)
	local uiCorner = Instance.new("UICorner")
	uiCorner.CornerRadius = UDim.new(0, radius)
	uiCorner.Parent = parent
end

local function label(parent: Instance, props: { [string]: any }): TextLabel
	local textLabel = Instance.new("TextLabel")
	textLabel.BackgroundTransparency = 1
	textLabel.Font = Enum.Font.GothamBold
	textLabel.TextColor3 = Color3.new(1, 1, 1)
	textLabel.TextXAlignment = Enum.TextXAlignment.Left
	for key, value in props do
		(textLabel :: any)[key] = value
	end
	textLabel.Parent = parent
	return textLabel
end

local function button(parent: Instance, text: string, color: Color3?, props: { [string]: any }?): TextButton
	local textButton = Instance.new("TextButton")
	textButton.BackgroundColor3 = color or CARD
	textButton.Font = Enum.Font.GothamBold
	textButton.TextSize = 13
	textButton.TextColor3 = if color then DARK else Color3.new(1, 1, 1)
	textButton.Text = text
	textButton.AutoButtonColor = true
	for key, value in props or {} do
		(textButton :: any)[key] = value
	end
	textButton.Parent = parent
	corner(textButton, 8)
	return textButton
end

local function textBox(parent: Instance, placeholder: string, props: { [string]: any }): TextBox
	local box = Instance.new("TextBox")
	box.BackgroundColor3 = CARD
	box.Font = Enum.Font.GothamMedium
	box.TextSize = 14
	box.TextColor3 = Color3.new(1, 1, 1)
	box.PlaceholderText = placeholder
	box.PlaceholderColor3 = MUTED
	box.Text = ""
	box.ClearTextOnFocus = false
	for key, value in props do
		(box :: any)[key] = value
	end
	box.Parent = parent
	corner(box, 8)
	return box
end

local function grid(parent: Instance, cellWidth: number, cellHeight: number)
	local layout = Instance.new("UIGridLayout")
	layout.CellSize = UDim2.fromOffset(cellWidth, cellHeight)
	layout.CellPadding = UDim2.fromOffset(8, 8)
	layout.SortOrder = Enum.SortOrder.LayoutOrder
	layout.Parent = parent
	return layout
end

local gui = Instance.new("ScreenGui")
gui.Name = "AdminPanel"
gui.ResetOnSpawn = false
gui.DisplayOrder = 30
gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
gui.Parent = player:WaitForChild("PlayerGui")

local openButton = button(gui, "ADMIN", nil, {
	Position = UDim2.new(0, 12, 0.35, 210),
	Size = UDim2.fromOffset(120, 34),
	BackgroundTransparency = 0.2,
	BackgroundColor3 = DARK,
})
local openStroke = Instance.new("UIStroke")
openStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
openStroke.Color = RED
openStroke.Thickness = 1.5
openStroke.Parent = openButton

local panel = Instance.new("Frame")
panel.AnchorPoint = Vector2.new(0.5, 0.5)
panel.Position = UDim2.fromScale(0.5, 0.5)
panel.Size = UDim2.fromOffset(PANEL_WIDTH, PANEL_HEIGHT)
panel.BackgroundColor3 = DARK
panel.BackgroundTransparency = 0.03
panel.Visible = false
panel.Parent = gui
corner(panel, 12)
local panelStroke = Instance.new("UIStroke")
panelStroke.Color = RED
panelStroke.Thickness = 2
panelStroke.Parent = panel
local panelScale = Instance.new("UIScale")
panelScale.Parent = panel

label(panel, {
	Position = UDim2.fromOffset(18, 12),
	Size = UDim2.fromOffset(200, 26),
	Font = Enum.Font.GothamBlack,
	TextSize = 22,
	TextColor3 = RED,
	Text = "PAINEL ADMIN",
})

local closeButton = button(panel, "X", nil, {
	AnchorPoint = Vector2.new(1, 0),
	Position = UDim2.new(1, -12, 0, 12),
	Size = UDim2.fromOffset(32, 32),
	Font = Enum.Font.GothamBlack,
	TextSize = 16,
})

local feedback = label(panel, {
	AnchorPoint = Vector2.new(0, 1),
	Position = UDim2.new(0, 18, 1, -10),
	Size = UDim2.new(1, -36, 0, 18),
	Font = Enum.Font.GothamMedium,
	TextSize = 13,
	TextColor3 = MUTED,
	Text = "",
})

local function call(action: string, ...): (boolean, any)
	local ok, success, result = pcall(ActionRemote.InvokeServer, ActionRemote, action, ...)
	if not ok then
		feedback.Text = "Erro de conexão"
		feedback.TextColor3 = RED
		return false, nil
	end
	if type(result) == "string" then
		feedback.Text = result
	elseif not success then
		feedback.Text = "Não deu certo"
	end
	if type(result) == "string" or not success then
		feedback.TextColor3 = if success then DONE else RED
	end
	return success, result
end

-- Abas
local tabs: { [string]: Frame } = {}
local tabButtons: { [string]: TextButton } = {}
local tabOrder = { "JOGADORES", "SERVIDOR", "LOG" }

local content = Instance.new("Frame")
content.Position = UDim2.fromOffset(18, 92)
content.Size = UDim2.new(1, -36, 1, -128)
content.BackgroundTransparency = 1
content.Parent = panel

for index, name in tabOrder do
	tabButtons[name] = button(panel, name, nil, {
		Position = UDim2.fromOffset(18 + (index - 1) * 128, 50),
		Size = UDim2.fromOffset(120, 32),
	})
	local frame = Instance.new("Frame")
	frame.Size = UDim2.fromScale(1, 1)
	frame.BackgroundTransparency = 1
	frame.Visible = false
	frame.Parent = content
	tabs[name] = frame
end

---------------------------------------------------------------------------
-- Aba JOGADORES
---------------------------------------------------------------------------

local playersTab = tabs.JOGADORES

local playerList = Instance.new("ScrollingFrame")
playerList.Size = UDim2.new(0, 200, 1, 0)
playerList.BackgroundColor3 = Color3.fromRGB(20, 20, 26)
playerList.BorderSizePixel = 0
playerList.ScrollBarThickness = 5
playerList.CanvasSize = UDim2.new()
playerList.AutomaticCanvasSize = Enum.AutomaticSize.Y
playerList.Parent = playersTab
corner(playerList, 8)
local listLayout = Instance.new("UIListLayout")
listLayout.Padding = UDim.new(0, 4)
listLayout.SortOrder = Enum.SortOrder.LayoutOrder
listLayout.Parent = playerList
local listPadding = Instance.new("UIPadding")
listPadding.PaddingTop = UDim.new(0, 4)
listPadding.PaddingLeft = UDim.new(0, 4)
listPadding.PaddingRight = UDim.new(0, 4)
listPadding.Parent = playerList

local details = Instance.new("Frame")
details.Position = UDim2.fromOffset(212, 0)
details.Size = UDim2.new(1, -212, 1, 0)
details.BackgroundTransparency = 1
details.Parent = playersTab

local statsLabel = label(details, {
	Size = UDim2.new(1, 0, 0, 74),
	Font = Enum.Font.GothamMedium,
	TextSize = 14,
	TextWrapped = true,
	TextYAlignment = Enum.TextYAlignment.Top,
	Text = "Escolha um jogador na lista.",
})

local amountBox = textBox(details, "Valor (ex.: 5000)", {
	Position = UDim2.fromOffset(0, 80),
	Size = UDim2.new(0.5, -4, 0, 34),
})
local reasonBox = textBox(details, "Motivo do kick (opcional)", {
	Position = UDim2.new(0.5, 4, 0, 80),
	Size = UDim2.new(0.5, -4, 0, 34),
})

local actionsGrid = Instance.new("Frame")
actionsGrid.Position = UDim2.fromOffset(0, 124)
actionsGrid.Size = UDim2.new(1, 0, 1, -124)
actionsGrid.BackgroundTransparency = 1
actionsGrid.Parent = details
grid(actionsGrid, 140, 34)

local selectedUserId: number? = nil
local playerRows: { any } = {}

local function showStats()
	for _, info in playerRows do
		if info.UserId == selectedUserId then
			local hours = math.floor(info.Playtime / 60)
			statsLabel.Text = `{info.DisplayName} (@{info.Name}) • {info.Team}\n`
				.. `Nível {info.Level} • {info.Kills} abates • {info.Deaths} mortes • K/D {info.KD}\n`
				.. `Dinheiro: {info.Money} • Jogou {hours}h{info.Playtime % 60}min\n`
				.. (if info.Bounty > 0 then `💀 Recompensa: {info.Bounty}   ` else "")
				.. (if info.InTraining then "🎯 No treino" else "")
			return
		end
	end
	statsLabel.Text = "Escolha um jogador na lista."
end

local function refreshPlayers()
	local ok, list = call("players")
	if not ok or type(list) ~= "table" then
		return
	end
	playerRows = list
	for _, child in playerList:GetChildren() do
		if child:IsA("TextButton") then
			child:Destroy()
		end
	end
	for index, info in list do
		local row = button(playerList, `{info.DisplayName}  (Nv {info.Level})`, nil, {
			LayoutOrder = index,
			Size = UDim2.new(1, 0, 0, 30),
			TextXAlignment = Enum.TextXAlignment.Left,
			BackgroundColor3 = if info.UserId == selectedUserId then Color3.fromRGB(70, 30, 30) else CARD,
		})
		local padding = Instance.new("UIPadding")
		padding.PaddingLeft = UDim.new(0, 8)
		padding.Parent = row
		row.Activated:Connect(function()
			selectedUserId = info.UserId
			refreshPlayers()
		end)
	end
	showStats()
end

local function playerAction(text: string, action: string, getArgs: (() -> ...any)?, color: Color3?)
	local actionButton = button(actionsGrid, text, color)
	actionButton.Activated:Connect(function()
		if not selectedUserId then
			feedback.Text = "Escolha um jogador primeiro"
			feedback.TextColor3 = RED
			return
		end
		if getArgs then
			call(action, selectedUserId, getArgs())
		else
			call(action, selectedUserId)
		end
		task.delay(0.3, refreshPlayers)
	end)
end

local function amount()
	return tonumber(amountBox.Text)
end

playerAction("💰 Dar dinheiro", "giveMoney", amount)
playerAction("⭐ Dar XP", "giveXP", amount)
playerAction("📈 Mudar nível", "setLevel", amount)
playerAction("➡️ Ir até", "teleportTo")
playerAction("⬅️ Puxar", "bring")
playerAction("💀 Tirar recompensa", "clearBounty")
playerAction("🎟️ Dar Premium", "givePremium")
playerAction("🎯 Encerrar treino", "endTraining")
playerAction("🚫 Kickar", "kick", function()
	return reasonBox.Text
end, RED)

---------------------------------------------------------------------------
-- Aba SERVIDOR
---------------------------------------------------------------------------

local serverTab = tabs.SERVIDOR

label(serverTab, {
	Size = UDim2.new(1, 0, 0, 20),
	TextSize = 14,
	TextColor3 = ACCENT,
	Text = "EVENTOS",
})

local eventsGrid = Instance.new("Frame")
eventsGrid.Position = UDim2.fromOffset(0, 26)
eventsGrid.Size = UDim2.new(1, 0, 0, 120)
eventsGrid.BackgroundTransparency = 1
eventsGrid.Parent = serverTab
grid(eventsGrid, 196, 34)

local currentEventLabel = label(serverTab, {
	Position = UDim2.fromOffset(0, 150),
	Size = UDim2.new(1, 0, 0, 18),
	Font = Enum.Font.GothamMedium,
	TextSize = 13,
	TextColor3 = MUTED,
	Text = "",
})

local function refreshEvents()
	local ok, info = call("events")
	if not ok or type(info) ~= "table" then
		return
	end
	for _, child in eventsGrid:GetChildren() do
		if child:IsA("TextButton") then
			child:Destroy()
		end
	end
	for index, event in info.List do
		local eventButton = button(eventsGrid, `▶ {event.Name}`, nil, { LayoutOrder = index })
		eventButton.Activated:Connect(function()
			call("startEvent", event.Id)
			task.delay(0.3, refreshEvents)
		end)
	end
	local stopButton = button(eventsGrid, "⏹ PARAR EVENTO", RED, { LayoutOrder = 999 })
	stopButton.Activated:Connect(function()
		call("stopEvent")
		task.delay(0.3, refreshEvents)
	end)
	currentEventLabel.Text = if info.Current then `Evento agora: {info.Current}` else "Nenhum evento acontecendo"
end

label(serverTab, {
	Position = UDim2.fromOffset(0, 184),
	Size = UDim2.new(1, 0, 0, 20),
	TextSize = 14,
	TextColor3 = ACCENT,
	Text = "AVISO PARA TODOS",
})

local announceBox = textBox(serverTab, "Digite a mensagem...", {
	Position = UDim2.fromOffset(0, 210),
	Size = UDim2.new(1, -130, 0, 36),
	TextXAlignment = Enum.TextXAlignment.Left,
})
local announcePadding = Instance.new("UIPadding")
announcePadding.PaddingLeft = UDim.new(0, 10)
announcePadding.Parent = announceBox

local announceButton = button(serverTab, "📢 ENVIAR", ACCENT, {
	AnchorPoint = Vector2.new(1, 0),
	Position = UDim2.new(1, 0, 0, 210),
	Size = UDim2.fromOffset(120, 36),
})
announceButton.Activated:Connect(function()
	if call("announce", announceBox.Text) then
		announceBox.Text = ""
	end
end)

---------------------------------------------------------------------------
-- Aba LOG (ACSGuard)
---------------------------------------------------------------------------

local logTab = tabs.LOG

local logList = Instance.new("ScrollingFrame")
logList.Size = UDim2.fromScale(1, 1)
logList.BackgroundColor3 = Color3.fromRGB(20, 20, 26)
logList.BorderSizePixel = 0
logList.ScrollBarThickness = 5
logList.CanvasSize = UDim2.new()
logList.AutomaticCanvasSize = Enum.AutomaticSize.Y
logList.Parent = logTab
corner(logList, 8)
local logLayout = Instance.new("UIListLayout")
logLayout.Padding = UDim.new(0, 2)
logLayout.SortOrder = Enum.SortOrder.LayoutOrder
logLayout.Parent = logList
local logPadding = Instance.new("UIPadding")
logPadding.PaddingTop = UDim.new(0, 6)
logPadding.PaddingLeft = UDim.new(0, 8)
logPadding.PaddingRight = UDim.new(0, 8)
logPadding.Parent = logList

local function refreshLog()
	local ok, entries = call("guardLog")
	for _, child in logList:GetChildren() do
		if child:IsA("TextLabel") then
			child:Destroy()
		end
	end
	if not ok or type(entries) ~= "table" then
		return
	end
	if #entries == 0 then
		label(logList, {
			Size = UDim2.new(1, 0, 0, 20),
			Font = Enum.Font.GothamMedium,
			TextSize = 13,
			TextColor3 = MUTED,
			Text = "Nenhuma advertência do ACSGuard neste servidor. 👍",
		})
	end
	for index, entry in entries do
		local time = os.date("%H:%M:%S", entry.Time)
		label(logList, {
			LayoutOrder = index,
			Size = UDim2.new(1, 0, 0, 34),
			Font = Enum.Font.GothamMedium,
			TextSize = 12,
			TextWrapped = true,
			TextColor3 = if entry.Kicked then RED else Color3.new(1, 1, 1),
			Text = `[{time}] {entry.Player} ({entry.UserId}): {entry.Reason}` .. (if entry.Kicked then "  → KICKADO" else ""),
		})
	end
end

---------------------------------------------------------------------------
-- Navegação
---------------------------------------------------------------------------

local currentTab = "JOGADORES"

local function selectTab(name: string)
	currentTab = name
	for tabName, frame in tabs do
		frame.Visible = tabName == name
		tabButtons[tabName].BackgroundColor3 = if tabName == name then Color3.fromRGB(70, 30, 30) else CARD
	end
	if name == "JOGADORES" then
		refreshPlayers()
	elseif name == "SERVIDOR" then
		refreshEvents()
	else
		refreshLog()
	end
end

for name, tabButton in tabButtons do
	tabButton.Activated:Connect(function()
		selectTab(name)
	end)
end

local function updateScale()
	local camera = workspace.CurrentCamera
	if camera then
		local size = camera.ViewportSize
		panelScale.Scale = math.clamp(math.min((size.X - 24) / PANEL_WIDTH, (size.Y - 24) / PANEL_HEIGHT), 0.45, 1)
	end
end

openButton.Activated:Connect(function()
	panel.Visible = not panel.Visible
	if panel.Visible then
		updateScale()
		selectTab(currentTab)
	end
end)
closeButton.Activated:Connect(function()
	panel.Visible = false
end)

-- Atualiza a lista de jogadores enquanto o painel está aberto.
task.spawn(function()
	while true do
		task.wait(5)
		if panel.Visible and currentTab == "JOGADORES" then
			refreshPlayers()
		end
	end
end)
