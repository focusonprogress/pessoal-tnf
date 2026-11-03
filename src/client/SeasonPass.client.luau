--[[
	Tela do Passe de Temporada: botão "PASSE" + janela com os 50 níveis
	(trilha Grátis em cima, Premium embaixo), resgatar, comprar Premium e
	escolher o título exclusivo.
	Lê o atributo "SeasonPass" (JSON) do Player.
]]

local HttpService = game:GetService("HttpService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local player = Players.LocalPlayer
local Config = require(ReplicatedStorage:WaitForChild("SeasonPass"):WaitForChild("Config"))
local EconomyConfig = require(ReplicatedStorage:WaitForChild("Economy"):WaitForChild("Config"))
local ActionRemote = ReplicatedStorage:WaitForChild("GameRemotes"):WaitForChild("SeasonPassAction") :: RemoteFunction

local DARK = Color3.fromRGB(14, 14, 18)
local CARD = Color3.fromRGB(28, 28, 34)
local ACCENT = Color3.fromRGB(255, 196, 0)
local GOLD = Color3.fromRGB(255, 170, 40)
local DONE = Color3.fromRGB(80, 220, 120)
local MUTED = Color3.fromRGB(150, 150, 150)

local PANEL_WIDTH = 780
local PANEL_HEIGHT = 440
local COLUMN_WIDTH = 96
local BOX_HEIGHT = 112

local function corner(parent: Instance, radius: number)
	local uiCorner = Instance.new("UICorner")
	uiCorner.CornerRadius = UDim.new(0, radius)
	uiCorner.Parent = parent
end

local function stroke(parent: Instance, color: Color3, thickness: number): UIStroke
	local uiStroke = Instance.new("UIStroke")
	uiStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
	uiStroke.Color = color
	uiStroke.Thickness = thickness
	uiStroke.Parent = parent
	return uiStroke
end

local function label(parent: Instance, props: { [string]: any }): TextLabel
	local textLabel = Instance.new("TextLabel")
	textLabel.BackgroundTransparency = 1
	textLabel.Font = Enum.Font.GothamBold
	textLabel.TextColor3 = Color3.new(1, 1, 1)
	for key, value in props do
		(textLabel :: any)[key] = value
	end
	textLabel.Parent = parent
	return textLabel
end

local function button(parent: Instance, props: { [string]: any }): TextButton
	local textButton = Instance.new("TextButton")
	textButton.Font = Enum.Font.GothamBlack
	textButton.TextSize = 14
	textButton.AutoButtonColor = true
	for key, value in props do
		(textButton :: any)[key] = value
	end
	textButton.Parent = parent
	corner(textButton, 8)
	return textButton
end

local gui = Instance.new("ScreenGui")
gui.Name = "SeasonPass"
gui.ResetOnSpawn = false
gui.DisplayOrder = 12
gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
gui.Parent = player:WaitForChild("PlayerGui")

-- Botão "PASSE"
local openButton = button(gui, {
	Name = "OpenPass",
	Position = Config.ButtonPosition,
	Size = UDim2.fromOffset(120, 34),
	BackgroundColor3 = DARK,
	BackgroundTransparency = 0.2,
	Font = Enum.Font.GothamBold,
	TextSize = 13,
	TextColor3 = Color3.new(1, 1, 1),
	Text = "PASSE",
})
stroke(openButton, GOLD, 1.5).Transparency = 0.3

local badge = label(openButton, {
	AnchorPoint = Vector2.new(0.5, 0.5),
	Position = UDim2.new(1, -2, 0, 2),
	Size = UDim2.fromOffset(20, 20),
	BackgroundColor3 = Color3.fromRGB(255, 70, 60),
	BackgroundTransparency = 0,
	TextSize = 12,
	Text = "",
	Visible = false,
})
corner(badge, 10)

-- Janela
local panel = Instance.new("Frame")
panel.Name = "Panel"
panel.AnchorPoint = Vector2.new(0.5, 0.5)
panel.Position = UDim2.fromScale(0.5, 0.5)
panel.Size = UDim2.fromOffset(PANEL_WIDTH, PANEL_HEIGHT)
panel.BackgroundColor3 = DARK
panel.BackgroundTransparency = 0.04
panel.Visible = false
panel.Parent = gui
corner(panel, 14)
stroke(panel, GOLD, 2)

local panelScale = Instance.new("UIScale")
panelScale.Parent = panel

label(panel, {
	Position = UDim2.fromOffset(20, 12),
	Size = UDim2.new(1, -200, 0, 26),
	Font = Enum.Font.GothamBlack,
	TextSize = 22,
	TextColor3 = GOLD,
	TextXAlignment = Enum.TextXAlignment.Left,
	Text = Config.SeasonName,
})

local endsLabel = label(panel, {
	Position = UDim2.fromOffset(20, 38),
	Size = UDim2.new(1, -200, 0, 16),
	Font = Enum.Font.GothamMedium,
	TextSize = 13,
	TextColor3 = MUTED,
	TextXAlignment = Enum.TextXAlignment.Left,
	Text = "",
})

local closeButton = button(panel, {
	AnchorPoint = Vector2.new(1, 0),
	Position = UDim2.new(1, -12, 0, 12),
	Size = UDim2.fromOffset(32, 32),
	BackgroundColor3 = Color3.fromRGB(40, 40, 46),
	TextColor3 = Color3.new(1, 1, 1),
	TextSize = 16,
	Text = "X",
})

-- Nível atual + barra
local tierLabel = label(panel, {
	Position = UDim2.fromOffset(20, 64),
	Size = UDim2.fromOffset(140, 24),
	Font = Enum.Font.GothamBlack,
	TextSize = 20,
	TextXAlignment = Enum.TextXAlignment.Left,
	Text = "NÍVEL 0",
})

local barBackground = Instance.new("Frame")
barBackground.Position = UDim2.fromOffset(160, 70)
barBackground.Size = UDim2.new(1, -330, 0, 12)
barBackground.BackgroundColor3 = Color3.fromRGB(50, 50, 58)
barBackground.Parent = panel
corner(barBackground, 6)

local barFill = Instance.new("Frame")
barFill.Size = UDim2.fromScale(0, 1)
barFill.BackgroundColor3 = GOLD
barFill.Parent = barBackground
corner(barFill, 6)

local xpLabel = label(panel, {
	AnchorPoint = Vector2.new(1, 0),
	Position = UDim2.new(1, -20, 0, 64),
	Size = UDim2.fromOffset(150, 24),
	Font = Enum.Font.GothamBold,
	TextSize = 13,
	TextColor3 = MUTED,
	TextXAlignment = Enum.TextXAlignment.Right,
	Text = "",
})

-- Rótulos das trilhas
label(panel, {
	Position = UDim2.fromOffset(20, 124),
	Size = UDim2.fromOffset(70, BOX_HEIGHT),
	TextSize = 13,
	TextColor3 = Color3.new(1, 1, 1),
	Text = "GRÁTIS",
})
local premiumTrackLabel = label(panel, {
	Position = UDim2.fromOffset(20, 124 + BOX_HEIGHT + 8),
	Size = UDim2.fromOffset(70, BOX_HEIGHT),
	TextSize = 13,
	TextColor3 = GOLD,
	TextWrapped = true,
	Text = "⭐\nPREMIUM",
})

-- Níveis (rolagem na horizontal)
local scroller = Instance.new("ScrollingFrame")
scroller.Position = UDim2.fromOffset(96, 96)
scroller.Size = UDim2.new(1, -112, 0, 28 + BOX_HEIGHT * 2 + 8 + 12)
scroller.BackgroundTransparency = 1
scroller.BorderSizePixel = 0
scroller.ScrollBarThickness = 6
scroller.ScrollBarImageColor3 = GOLD
scroller.ScrollingDirection = Enum.ScrollingDirection.X
scroller.CanvasSize = UDim2.fromOffset(Config.MaxTier * COLUMN_WIDTH, 0)
scroller.Parent = panel

-- Rodapé
local titleButton = button(panel, {
	AnchorPoint = Vector2.new(0, 1),
	Position = UDim2.new(0, 20, 1, -16),
	Size = UDim2.fromOffset(260, 40),
	BackgroundColor3 = CARD,
	TextColor3 = Color3.new(1, 1, 1),
	Font = Enum.Font.GothamBold,
	TextSize = 13,
	Text = "TÍTULO: do nível",
})

local claimAllButton = button(panel, {
	AnchorPoint = Vector2.new(1, 1),
	Position = UDim2.new(1, -20, 1, -16),
	Size = UDim2.fromOffset(190, 40),
	BackgroundColor3 = ACCENT,
	TextColor3 = DARK,
	Text = "RESGATAR TUDO",
})

local buyButton = button(panel, {
	AnchorPoint = Vector2.new(1, 1),
	Position = UDim2.new(1, -222, 1, -16),
	Size = UDim2.fromOffset(200, 40),
	BackgroundColor3 = GOLD,
	TextColor3 = DARK,
	Text = "⭐ COMPRAR PREMIUM",
	Visible = false,
})

---------------------------------------------------------------------------
-- Estado e desenho
---------------------------------------------------------------------------

local state = nil
local busy = false

local function rewardText(reward): string
	if not reward then
		return ""
	end
	local parts = {}
	if reward.Money then
		table.insert(parts, EconomyConfig.Format(reward.Money))
	end
	if reward.Title then
		table.insert(parts, `🏷️ "{reward.Title}"`)
	end
	return table.concat(parts, "\n")
end

local function sendAction(action: string, a: any?, b: any?)
	if busy then
		return
	end
	busy = true
	pcall(ActionRemote.InvokeServer, ActionRemote, action, a, b)
	busy = false
end

local function createBox(column: Frame, tier: number, track: string, y: number)
	local reward = Config.Rewards[tier] and Config.Rewards[tier][track]
	local isPremium = track == "Premium"
	local reached = state and tier <= state.Tier
	local claimedList = if isPremium then state.ClaimedPremium else state.ClaimedFree
	local claimed = table.find(claimedList, tier) ~= nil
	local locked = isPremium and not state.Premium
	local claimable = reached and not claimed and not locked and reward ~= nil

	local box = Instance.new("TextButton")
	box.Position = UDim2.fromOffset(4, y)
	box.Size = UDim2.new(1, -8, 0, BOX_HEIGHT)
	box.BackgroundColor3 = if isPremium then Color3.fromRGB(40, 32, 14) else CARD
	box.BackgroundTransparency = if reached then 0 else 0.45
	box.AutoButtonColor = claimable
	box.Text = ""
	box.Parent = column
	corner(box, 10)

	local boxStroke = stroke(box, if claimable then ACCENT else (if isPremium then GOLD else Color3.fromRGB(60, 60, 66)), if claimable then 2.5 else 1)
	boxStroke.Transparency = if claimable then 0 else 0.4

	label(box, {
		Position = UDim2.fromOffset(4, 10),
		Size = UDim2.new(1, -8, 0, 64),
		TextSize = 13,
		TextWrapped = true,
		TextColor3 = if reward and reward.Title then GOLD else Color3.new(1, 1, 1),
		TextTransparency = if reached then 0 else 0.4,
		Text = rewardText(reward),
	})

	local status = label(box, {
		AnchorPoint = Vector2.new(0.5, 1),
		Position = UDim2.new(0.5, 0, 1, -8),
		Size = UDim2.new(1, -8, 0, 18),
		TextSize = 12,
		Text = "",
	})
	if claimed then
		status.Text = "✓ PEGO"
		status.TextColor3 = DONE
	elseif locked then
		status.Text = "🔒"
		status.TextColor3 = GOLD
	elseif claimable then
		status.Text = "RESGATAR"
		status.TextColor3 = ACCENT
	elseif not reached then
		status.Text = ""
	end

	if claimable then
		box.Activated:Connect(function()
			sendAction("claim", track, tier)
		end)
	elseif locked and Config.PremiumGamePassId ~= 0 then
		box.Activated:Connect(function()
			sendAction("buyPremium")
		end)
	end
end

local function render()
	local raw = player:GetAttribute("SeasonPass")
	local ok, decoded = pcall(function()
		return HttpService:JSONDecode(raw)
	end)
	if not ok or type(decoded) ~= "table" then
		return
	end
	state = decoded

	-- Topo
	tierLabel.Text = `NÍVEL {state.Tier}`
	local ratio = math.clamp(state.XPInTier / Config.XPPerTier, 0, 1)
	barFill.Size = UDim2.fromScale(ratio, 1)
	xpLabel.Text = if state.Tier >= Config.MaxTier then "PASSE COMPLETO!" else `{state.XPInTier} / {Config.XPPerTier} XP`
	premiumTrackLabel.Text = if state.Premium then "⭐\nPREMIUM\nATIVO" else "⭐\nPREMIUM"

	-- Colunas
	for _, child in scroller:GetChildren() do
		if child:IsA("Frame") then
			child:Destroy()
		end
	end

	local pending = 0
	for tier = 1, Config.MaxTier do
		local column = Instance.new("Frame")
		column.Position = UDim2.fromOffset((tier - 1) * COLUMN_WIDTH, 0)
		column.Size = UDim2.fromOffset(COLUMN_WIDTH, 28 + BOX_HEIGHT * 2 + 8)
		column.BackgroundTransparency = 1
		column.Parent = scroller

		label(column, {
			Size = UDim2.new(1, 0, 0, 22),
			Font = Enum.Font.GothamBlack,
			TextSize = 14,
			TextColor3 = if tier <= state.Tier then ACCENT else MUTED,
			Text = tostring(tier),
		})

		createBox(column, tier, "Free", 28)
		createBox(column, tier, "Premium", 28 + BOX_HEIGHT + 8)

		if tier <= state.Tier then
			if not table.find(state.ClaimedFree, tier) and Config.Rewards[tier].Free then
				pending += 1
			end
			if state.Premium and not table.find(state.ClaimedPremium, tier) and Config.Rewards[tier].Premium then
				pending += 1
			end
		end
	end

	badge.Text = tostring(pending)
	badge.Visible = pending > 0
	claimAllButton.Visible = pending > 0
	buyButton.Visible = not state.Premium and Config.PremiumGamePassId ~= 0

	local equipped = if state.Equipped ~= "" then state.Equipped else "do nível"
	titleButton.Text = `TÍTULO: {equipped}  ▶`
end

player:GetAttributeChangedSignal("SeasonPass"):Connect(render)
render()

---------------------------------------------------------------------------
-- Botões
---------------------------------------------------------------------------

local function updateScale()
	local camera = workspace.CurrentCamera
	if camera then
		local size = camera.ViewportSize
		panelScale.Scale = math.clamp(math.min((size.X - 24) / PANEL_WIDTH, (size.Y - 24) / PANEL_HEIGHT), 0.4, 1)
	end
end

openButton.Activated:Connect(function()
	updateScale()
	panel.Visible = not panel.Visible
	if panel.Visible and state then
		-- Rola até o nível atual
		local x = math.max(0, (state.Tier - 2) * COLUMN_WIDTH)
		scroller.CanvasPosition = Vector2.new(x, 0)
	end
end)

closeButton.Activated:Connect(function()
	panel.Visible = false
end)

claimAllButton.Activated:Connect(function()
	sendAction("claimAll")
end)

buyButton.Activated:Connect(function()
	sendAction("buyPremium")
end)

-- Troca o título: do nível -> título 1 -> título 2 -> ... -> do nível
titleButton.Activated:Connect(function()
	if not state or type(state.Titles) ~= "table" or #state.Titles == 0 then
		titleButton.Text = "Nenhum título ainda. Suba no passe!"
		return
	end
	local options = { "" }
	for _, title in state.Titles do
		table.insert(options, title)
	end
	local current = table.find(options, state.Equipped or "") or 1
	local nextTitle = options[current % #options + 1]
	sendAction("equipTitle", nextTitle)
end)

-- Contador do fim da temporada
RunService.Heartbeat:Connect(function()
	if not panel.Visible then
		return
	end
	local remaining = Config.EndsAt - workspace:GetServerTimeNow()
	if remaining <= 0 then
		endsLabel.Text = "Temporada encerrada. Resgate o que faltar!"
	else
		local days = math.floor(remaining / 86400)
		local hours = math.floor((remaining % 86400) / 3600)
		endsLabel.Text = `Termina em {days}d {hours}h`
	end
end)
