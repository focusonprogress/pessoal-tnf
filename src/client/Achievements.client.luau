--[[
	Painel de conquistas: botão "CONQUISTAS" + lista com progresso.
	Lê o atributo "Achievements" (JSON) do Player.
]]

local HttpService = game:GetService("HttpService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local player = Players.LocalPlayer
local Config = require(ReplicatedStorage:WaitForChild("Achievements"):WaitForChild("Config"))
local EconomyConfig = require(ReplicatedStorage:WaitForChild("Economy"):WaitForChild("Config"))

local DARK = Color3.fromRGB(14, 14, 18)
local ROW = Color3.fromRGB(28, 28, 34)
local PURPLE = Color3.fromRGB(190, 120, 255)
local MUTED = Color3.fromRGB(150, 150, 150)
local PANEL_WIDTH = 440
local PANEL_HEIGHT = 420
local ROW_HEIGHT = 70

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
gui.Name = "Achievements"
gui.ResetOnSpawn = false
gui.DisplayOrder = 6
gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
gui.Parent = player:WaitForChild("PlayerGui")

-- Botão
local openButton = Instance.new("TextButton")
openButton.Name = "OpenAchievements"
openButton.Position = Config.ButtonPosition
openButton.Size = UDim2.fromOffset(120, 34)
openButton.BackgroundColor3 = DARK
openButton.BackgroundTransparency = 0.2
openButton.Font = Enum.Font.GothamBold
openButton.Text = "CONQUISTAS"
openButton.TextColor3 = Color3.new(1, 1, 1)
openButton.TextSize = 13
openButton.Parent = gui
corner(openButton, 8)

local openStroke = Instance.new("UIStroke")
openStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
openStroke.Color = PURPLE
openStroke.Thickness = 1.5
openStroke.Transparency = 0.3
openStroke.Parent = openButton

-- Painel
local panel = Instance.new("Frame")
panel.Name = "Panel"
panel.AnchorPoint = Vector2.new(0.5, 0.5)
panel.Position = UDim2.fromScale(0.5, 0.5)
panel.Size = UDim2.fromOffset(PANEL_WIDTH, PANEL_HEIGHT)
panel.BackgroundColor3 = DARK
panel.BackgroundTransparency = 0.05
panel.Visible = false
panel.Parent = gui
corner(panel, 12)

local panelStroke = Instance.new("UIStroke")
panelStroke.Color = PURPLE
panelStroke.Thickness = 2
panelStroke.Parent = panel

local panelScale = Instance.new("UIScale")
panelScale.Parent = panel

label({
	Position = UDim2.fromOffset(18, 12),
	Size = UDim2.new(1, -70, 0, 26),
	Font = Enum.Font.GothamBlack,
	TextSize = 22,
	TextColor3 = PURPLE,
	Text = "CONQUISTAS",
	Parent = panel,
})

local countLabel = label({
	Position = UDim2.fromOffset(18, 38),
	Size = UDim2.new(1, -36, 0, 16),
	Font = Enum.Font.GothamMedium,
	TextSize = 13,
	TextColor3 = MUTED,
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

local list = Instance.new("ScrollingFrame")
list.Position = UDim2.fromOffset(14, 64)
list.Size = UDim2.new(1, -28, 1, -78)
list.BackgroundTransparency = 1
list.BorderSizePixel = 0
list.ScrollBarThickness = 6
list.ScrollBarImageColor3 = PURPLE
list.CanvasSize = UDim2.new()
list.AutomaticCanvasSize = Enum.AutomaticSize.Y
list.Parent = panel

local listLayout = Instance.new("UIListLayout")
listLayout.SortOrder = Enum.SortOrder.LayoutOrder
listLayout.Padding = UDim.new(0, 8)
listLayout.Parent = list

local function createRow(achievement, order: number)
	local done = achievement.Done == true
	local color = if done then PURPLE else Color3.fromRGB(255, 196, 0)

	local row = Instance.new("Frame")
	row.LayoutOrder = order
	row.Size = UDim2.new(1, -10, 0, ROW_HEIGHT)
	row.BackgroundColor3 = ROW
	row.BackgroundTransparency = if done then 0 else 0.2
	row.Parent = list
	corner(row, 8)

	if done then
		local stroke = Instance.new("UIStroke")
		stroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
		stroke.Color = PURPLE
		stroke.Thickness = 1.5
		stroke.Parent = row
	end

	label({
		Position = UDim2.fromOffset(12, 8),
		Size = UDim2.new(1, -100, 0, 18),
		Font = Enum.Font.GothamBlack,
		TextSize = 15,
		TextColor3 = if done then PURPLE else Color3.new(1, 1, 1),
		Text = if done then `🏆 {achievement.Name}` else achievement.Name,
		Parent = row,
	})

	label({
		AnchorPoint = Vector2.new(1, 0),
		Position = UDim2.new(1, -12, 0, 8),
		Size = UDim2.fromOffset(90, 18),
		TextSize = 13,
		TextXAlignment = Enum.TextXAlignment.Right,
		TextColor3 = color,
		Text = if done then "COMPLETA" else `{achievement.Progress}/{achievement.Goal}`,
		Parent = row,
	})

	label({
		Position = UDim2.fromOffset(12, 27),
		Size = UDim2.new(1, -24, 0, 15),
		Font = Enum.Font.GothamMedium,
		TextSize = 12,
		TextColor3 = MUTED,
		TextTruncate = Enum.TextTruncate.AtEnd,
		Text = achievement.Description,
		Parent = row,
	})

	local barBackground = Instance.new("Frame")
	barBackground.Position = UDim2.fromOffset(12, 48)
	barBackground.Size = UDim2.new(0.55, -12, 0, 8)
	barBackground.BackgroundColor3 = Color3.fromRGB(50, 50, 58)
	barBackground.Parent = row
	corner(barBackground, 4)

	local ratio = if achievement.Goal > 0 then math.clamp(achievement.Progress / achievement.Goal, 0, 1) else 1
	local barFill = Instance.new("Frame")
	barFill.Size = UDim2.fromScale(ratio, 1)
	barFill.BackgroundColor3 = color
	barFill.Parent = barBackground
	corner(barFill, 4)

	local rewardParts = {}
	if achievement.Money then
		table.insert(rewardParts, EconomyConfig.Format(achievement.Money))
	end
	if achievement.XP then
		table.insert(rewardParts, `{achievement.XP} XP`)
	end
	label({
		AnchorPoint = Vector2.new(1, 0),
		Position = UDim2.new(1, -12, 0, 44),
		Size = UDim2.new(0.45, -12, 0, 16),
		Font = Enum.Font.GothamMedium,
		TextSize = 12,
		TextXAlignment = Enum.TextXAlignment.Right,
		TextColor3 = MUTED,
		Text = table.concat(rewardParts, " + "),
		Parent = row,
	})
end

local function render()
	local raw = player:GetAttribute("Achievements")
	local ok, achievements = pcall(function()
		return HttpService:JSONDecode(raw)
	end)
	if not ok or type(achievements) ~= "table" then
		countLabel.Text = "Carregando..."
		return
	end

	for _, child in list:GetChildren() do
		if child:IsA("Frame") then
			child:Destroy()
		end
	end

	-- Primeiro as que faltam (mais perto de completar no topo), depois as completas.
	local order = {}
	for index, achievement in achievements do
		table.insert(order, { Index = index, Data = achievement })
	end
	table.sort(order, function(a, b)
		local doneA, doneB = a.Data.Done == true, b.Data.Done == true
		if doneA ~= doneB then
			return not doneA
		end
		local ratioA = a.Data.Progress / math.max(a.Data.Goal, 1)
		local ratioB = b.Data.Progress / math.max(b.Data.Goal, 1)
		if ratioA ~= ratioB then
			return ratioA > ratioB
		end
		return a.Index < b.Index
	end)

	local doneCount = 0
	for position, entry in order do
		createRow(entry.Data, position)
		if entry.Data.Done then
			doneCount += 1
		end
	end
	countLabel.Text = `{doneCount} de {#achievements} desbloqueadas`
end

player:GetAttributeChangedSignal("Achievements"):Connect(render)
render()

local function updateScale()
	local camera = workspace.CurrentCamera
	if camera then
		local size = camera.ViewportSize
		panelScale.Scale = math.clamp(math.min((size.X - 24) / PANEL_WIDTH, (size.Y - 24) / PANEL_HEIGHT), 0.5, 1)
	end
end

openButton.Activated:Connect(function()
	updateScale()
	panel.Visible = not panel.Visible
end)
closeButton.Activated:Connect(function()
	panel.Visible = false
end)
