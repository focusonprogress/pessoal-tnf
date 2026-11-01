--[[
	Painel de missões diárias: botão "MISSÕES" + lista com progresso.
	Lê o atributo "Missions" (JSON) que o servidor coloca no Player.
]]

local HttpService = game:GetService("HttpService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local player = Players.LocalPlayer
local Config = require(ReplicatedStorage:WaitForChild("Missions"):WaitForChild("Config"))
local EconomyConfig = require(ReplicatedStorage:WaitForChild("Economy"):WaitForChild("Config"))

local DARK = Color3.fromRGB(14, 14, 18)
local ACCENT = Color3.fromRGB(255, 196, 0)
local DONE = Color3.fromRGB(80, 220, 120)
local PANEL_WIDTH = 420
local ROW_HEIGHT = 74

local function corner(parent: Instance, radius: number)
	local uiCorner = Instance.new("UICorner")
	uiCorner.CornerRadius = UDim.new(0, radius)
	uiCorner.Parent = parent
end

local function label(props: { [string]: any }): TextLabel
	local textLabel = Instance.new("TextLabel")
	textLabel.BackgroundTransparency = 1
	textLabel.Font = Enum.Font.GothamBold
	textLabel.TextColor3 = Color3.new(1, 1, 1)
	textLabel.TextXAlignment = Enum.TextXAlignment.Left
	for key, value in props do
		(textLabel :: any)[key] = value
	end
	return textLabel
end

local gui = Instance.new("ScreenGui")
gui.Name = "Missions"
gui.ResetOnSpawn = false
gui.DisplayOrder = 6
gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
gui.Parent = player:WaitForChild("PlayerGui")

-- Botão
local button = Instance.new("TextButton")
button.Name = "OpenMissions"
button.Position = Config.ButtonPosition
button.Size = UDim2.fromOffset(120, 34)
button.BackgroundColor3 = DARK
button.BackgroundTransparency = 0.2
button.Font = Enum.Font.GothamBold
button.Text = "MISSÕES"
button.TextColor3 = Color3.new(1, 1, 1)
button.TextSize = 13
button.Parent = gui
corner(button, 8)

local buttonStroke = Instance.new("UIStroke")
buttonStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
buttonStroke.Color = ACCENT
buttonStroke.Thickness = 1.5
buttonStroke.Transparency = 0.3
buttonStroke.Parent = button

-- Bolinha com quantas faltam
local badge = label({
	Name = "Badge",
	AnchorPoint = Vector2.new(0.5, 0.5),
	Position = UDim2.new(1, -2, 0, 2),
	Size = UDim2.fromOffset(20, 20),
	BackgroundColor3 = Color3.fromRGB(255, 70, 60),
	BackgroundTransparency = 0,
	TextSize = 12,
	TextXAlignment = Enum.TextXAlignment.Center,
	Text = "",
	Visible = false,
	Parent = button,
})
corner(badge, 10)

-- Painel
local panel = Instance.new("Frame")
panel.Name = "Panel"
panel.AnchorPoint = Vector2.new(0.5, 0.5)
panel.Position = UDim2.fromScale(0.5, 0.5)
panel.Size = UDim2.fromOffset(PANEL_WIDTH, 100)
panel.BackgroundColor3 = DARK
panel.BackgroundTransparency = 0.08
panel.Visible = false
panel.Parent = gui
corner(panel, 12)

local panelStroke = Instance.new("UIStroke")
panelStroke.Color = ACCENT
panelStroke.Thickness = 2
panelStroke.Parent = panel

local panelScale = Instance.new("UIScale")
panelScale.Parent = panel

label({
	Position = UDim2.fromOffset(18, 12),
	Size = UDim2.new(1, -70, 0, 26),
	Font = Enum.Font.GothamBlack,
	TextSize = 22,
	TextColor3 = ACCENT,
	Text = "MISSÕES DIÁRIAS",
	Parent = panel,
})

local resetLabel = label({
	Position = UDim2.fromOffset(18, 38),
	Size = UDim2.new(1, -36, 0, 16),
	Font = Enum.Font.GothamMedium,
	TextSize = 13,
	TextColor3 = Color3.fromRGB(170, 170, 170),
	Text = "",
	Parent = panel,
})

local closeButton = Instance.new("TextButton")
closeButton.AnchorPoint = Vector2.new(1, 0)
closeButton.Position = UDim2.new(1, -12, 0, 12)
closeButton.Size = UDim2.fromOffset(32, 32)
closeButton.BackgroundColor3 = Color3.fromRGB(40, 40, 46)
closeButton.Font = Enum.Font.GothamBlack
closeButton.Text = "X"
closeButton.TextColor3 = Color3.new(1, 1, 1)
closeButton.TextSize = 16
closeButton.Parent = panel
corner(closeButton, 16)

local rowsHolder = Instance.new("Frame")
rowsHolder.BackgroundTransparency = 1
rowsHolder.Position = UDim2.fromOffset(14, 64)
rowsHolder.Size = UDim2.new(1, -28, 1, -78)
rowsHolder.Parent = panel

local rowsLayout = Instance.new("UIListLayout")
rowsLayout.SortOrder = Enum.SortOrder.LayoutOrder
rowsLayout.Padding = UDim.new(0, 8)
rowsLayout.Parent = rowsHolder

---------------------------------------------------------------------------
-- Dados
---------------------------------------------------------------------------

local state = nil

local function readState()
	local raw = player:GetAttribute("Missions")
	if type(raw) ~= "string" then
		return nil
	end
	local ok, decoded = pcall(HttpService.JSONDecode, HttpService, raw)
	return if ok then decoded else nil
end

local function createRow(mission, index: number)
	local done = mission.Done == true
	local color = if done then DONE else ACCENT

	local row = Instance.new("Frame")
	row.LayoutOrder = index
	row.Size = UDim2.new(1, 0, 0, ROW_HEIGHT)
	row.BackgroundColor3 = Color3.fromRGB(28, 28, 34)
	row.Parent = rowsHolder
	corner(row, 8)

	label({
		Position = UDim2.fromOffset(12, 8),
		Size = UDim2.new(1, -100, 0, 20),
		TextSize = 15,
		TextTruncate = Enum.TextTruncate.AtEnd,
		Text = if done then `✅ {mission.Text}` else mission.Text,
		TextColor3 = if done then DONE else Color3.new(1, 1, 1),
		Parent = row,
	})

	label({
		AnchorPoint = Vector2.new(1, 0),
		Position = UDim2.new(1, -12, 0, 8),
		Size = UDim2.fromOffset(80, 20),
		TextSize = 14,
		TextXAlignment = Enum.TextXAlignment.Right,
		Text = `{mission.Progress}/{mission.Goal}`,
		TextColor3 = color,
		Parent = row,
	})

	local barBackground = Instance.new("Frame")
	barBackground.Position = UDim2.fromOffset(12, 34)
	barBackground.Size = UDim2.new(1, -24, 0, 10)
	barBackground.BackgroundColor3 = Color3.fromRGB(50, 50, 58)
	barBackground.Parent = row
	corner(barBackground, 5)

	local ratio = if mission.Goal > 0 then math.clamp(mission.Progress / mission.Goal, 0, 1) else 1
	local barFill = Instance.new("Frame")
	barFill.Size = UDim2.fromScale(ratio, 1)
	barFill.BackgroundColor3 = color
	barFill.Parent = barBackground
	corner(barFill, 5)

	local rewardParts = {}
	if mission.Money then
		table.insert(rewardParts, EconomyConfig.Format(mission.Money))
	end
	if mission.XP then
		table.insert(rewardParts, `{mission.XP} XP`)
	end
	label({
		Position = UDim2.fromOffset(12, 50),
		Size = UDim2.new(1, -24, 0, 16),
		Font = Enum.Font.GothamMedium,
		TextSize = 13,
		TextColor3 = Color3.fromRGB(170, 170, 170),
		Text = "Recompensa: " .. table.concat(rewardParts, " + "),
		Parent = row,
	})
end

local function render()
	state = readState()

	for _, child in rowsHolder:GetChildren() do
		if child:IsA("Frame") then
			child:Destroy()
		end
	end

	local list = if state and type(state.List) == "table" then state.List else {}
	local pending = 0
	for index, mission in list do
		createRow(mission, index)
		if not mission.Done then
			pending += 1
		end
	end

	panel.Size = UDim2.fromOffset(PANEL_WIDTH, 78 + #list * (ROW_HEIGHT + 8))
	badge.Text = tostring(pending)
	badge.Visible = pending > 0
end

player:GetAttributeChangedSignal("Missions"):Connect(render)
render()

---------------------------------------------------------------------------
-- Abrir / fechar e contador
---------------------------------------------------------------------------

local function formatDuration(seconds: number): string
	seconds = math.max(0, math.floor(seconds))
	return string.format("%02d:%02d:%02d", seconds // 3600, (seconds % 3600) // 60, seconds % 60)
end

local function updateScale()
	local camera = workspace.CurrentCamera
	if camera then
		panelScale.Scale = math.clamp((camera.ViewportSize.X - 24) / PANEL_WIDTH, 0.6, 1)
	end
end

button.Activated:Connect(function()
	panel.Visible = not panel.Visible
	updateScale()
end)
closeButton.Activated:Connect(function()
	panel.Visible = false
end)

RunService.Heartbeat:Connect(function()
	if not panel.Visible then
		return
	end
	if state and type(state.ResetsAt) == "number" then
		resetLabel.Text = `Renovam em {formatDuration(state.ResetsAt - workspace:GetServerTimeNow())}`
	else
		resetLabel.Text = "Carregando..."
	end
end)
