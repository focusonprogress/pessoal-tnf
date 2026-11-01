--[[
	Janela da recompensa de login diário: 7 dias, o de hoje destacado,
	botão RESGATAR. Abre sozinha quando tem recompensa para pegar.
	Lê o atributo "DailyReward" (JSON) do Player.
]]

local HttpService = game:GetService("HttpService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local player = Players.LocalPlayer
local Config = require(ReplicatedStorage:WaitForChild("DailyRewards"):WaitForChild("Config"))
local EconomyConfig = require(ReplicatedStorage:WaitForChild("Economy"):WaitForChild("Config"))
local ClaimRemote = ReplicatedStorage:WaitForChild("GameRemotes"):WaitForChild("ClaimDaily") :: RemoteFunction

local DARK = Color3.fromRGB(14, 14, 18)
local TILE = Color3.fromRGB(28, 28, 34)
local ACCENT = Color3.fromRGB(255, 196, 0)
local DONE = Color3.fromRGB(80, 220, 120)
local MUTED = Color3.fromRGB(150, 150, 150)

local DAYS = #Config.Rewards
local TILE_WIDTH = 82
local TILE_GAP = 8
local PANEL_WIDTH = DAYS * TILE_WIDTH + (DAYS - 1) * TILE_GAP + 40

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
	for key, value in props do
		(textLabel :: any)[key] = value
	end
	return textLabel
end

local gui = Instance.new("ScreenGui")
gui.Name = "DailyRewards"
gui.ResetOnSpawn = false
gui.DisplayOrder = 15
gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
gui.Parent = player:WaitForChild("PlayerGui")

-- Botão "DIÁRIO"
local openButton = Instance.new("TextButton")
openButton.Name = "OpenDaily"
openButton.Position = Config.ButtonPosition
openButton.Size = UDim2.fromOffset(120, 34)
openButton.BackgroundColor3 = DARK
openButton.BackgroundTransparency = 0.2
openButton.Font = Enum.Font.GothamBold
openButton.Text = "DIÁRIO"
openButton.TextColor3 = Color3.new(1, 1, 1)
openButton.TextSize = 13
openButton.Parent = gui
corner(openButton, 8)

local openStroke = Instance.new("UIStroke")
openStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
openStroke.Color = ACCENT
openStroke.Thickness = 1.5
openStroke.Transparency = 0.3
openStroke.Parent = openButton

local badge = label({
	AnchorPoint = Vector2.new(0.5, 0.5),
	Position = UDim2.new(1, -2, 0, 2),
	Size = UDim2.fromOffset(20, 20),
	BackgroundColor3 = Color3.fromRGB(255, 70, 60),
	BackgroundTransparency = 0,
	TextSize = 12,
	Text = "!",
	Visible = false,
	Parent = openButton,
})
corner(badge, 10)

-- Janela
local panel = Instance.new("Frame")
panel.Name = "Panel"
panel.AnchorPoint = Vector2.new(0.5, 0.5)
panel.Position = UDim2.fromScale(0.5, 0.5)
panel.Size = UDim2.fromOffset(PANEL_WIDTH, 260)
panel.BackgroundColor3 = DARK
panel.BackgroundTransparency = 0.05
panel.Visible = false
panel.Parent = gui
corner(panel, 14)

local panelStroke = Instance.new("UIStroke")
panelStroke.Color = ACCENT
panelStroke.Thickness = 2
panelStroke.Parent = panel

local panelScale = Instance.new("UIScale")
panelScale.Parent = panel

label({
	Position = UDim2.fromOffset(0, 14),
	Size = UDim2.new(1, 0, 0, 30),
	Font = Enum.Font.GothamBlack,
	TextSize = 26,
	TextColor3 = ACCENT,
	Text = "RECOMPENSA DIÁRIA",
	Parent = panel,
})

label({
	Position = UDim2.fromOffset(0, 46),
	Size = UDim2.new(1, 0, 0, 16),
	Font = Enum.Font.GothamMedium,
	TextSize = 13,
	TextColor3 = MUTED,
	Text = "Entre todo dia para ganhar prêmios maiores. Se pular um dia, volta pro dia 1!",
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

type Tile = { Frame: Frame, Stroke: UIStroke, Day: TextLabel, Status: TextLabel }
local tiles: { Tile } = {}

for day, reward in Config.Rewards do
	local frame = Instance.new("Frame")
	frame.Position = UDim2.fromOffset(20 + (day - 1) * (TILE_WIDTH + TILE_GAP), 76)
	frame.Size = UDim2.fromOffset(TILE_WIDTH, 110)
	frame.BackgroundColor3 = TILE
	frame.Parent = panel
	corner(frame, 10)

	local stroke = Instance.new("UIStroke")
	stroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
	stroke.Color = ACCENT
	stroke.Thickness = 2
	stroke.Transparency = 1
	stroke.Parent = frame

	local dayLabel = label({
		Position = UDim2.fromOffset(0, 8),
		Size = UDim2.new(1, 0, 0, 16),
		TextSize = 13,
		TextColor3 = MUTED,
		Text = `DIA {day}`,
		Parent = frame,
	})

	label({
		Position = UDim2.fromOffset(4, 32),
		Size = UDim2.new(1, -8, 0, 22),
		Font = Enum.Font.GothamBlack,
		TextScaled = true,
		Text = EconomyConfig.Format(reward.Money or 0),
		TextColor3 = if day == DAYS then ACCENT else Color3.new(1, 1, 1),
		Parent = frame,
	})

	label({
		Position = UDim2.fromOffset(0, 56),
		Size = UDim2.new(1, 0, 0, 16),
		Font = Enum.Font.GothamMedium,
		TextSize = 12,
		TextColor3 = MUTED,
		Text = if reward.XP then `+{reward.XP} XP` else "",
		Parent = frame,
	})

	local status = label({
		Position = UDim2.fromOffset(0, 82),
		Size = UDim2.new(1, 0, 0, 18),
		TextSize = 13,
		Text = "",
		Parent = frame,
	})

	tiles[day] = { Frame = frame, Stroke = stroke, Day = dayLabel, Status = status }
end

local claimButton = Instance.new("TextButton")
claimButton.AnchorPoint = Vector2.new(0.5, 0)
claimButton.Position = UDim2.new(0.5, 0, 0, 200)
claimButton.Size = UDim2.fromOffset(220, 42)
claimButton.BackgroundColor3 = ACCENT
claimButton.Font = Enum.Font.GothamBlack
claimButton.TextSize = 18
claimButton.TextColor3 = DARK
claimButton.Text = "RESGATAR"
claimButton.Parent = panel
corner(claimButton, 10)

---------------------------------------------------------------------------
-- Estado
---------------------------------------------------------------------------

local state = nil
local busy = false

local function formatDuration(seconds: number): string
	seconds = math.max(0, math.floor(seconds))
	return string.format("%02d:%02d:%02d", seconds // 3600, (seconds % 3600) // 60, seconds % 60)
end

local function render()
	local raw = player:GetAttribute("DailyReward")
	local ok, decoded = pcall(function()
		return HttpService:JSONDecode(raw)
	end)
	state = if ok and type(decoded) == "table" then decoded else nil
	if not state then
		return
	end

	local index = state.Index or 1
	for day, tile in tiles do
		-- Dias antes do de hoje já foram resgatados neste ciclo.
		local claimed = day < index or (day == index and not state.CanClaim)
		local isToday = day == index and state.CanClaim

		tile.Stroke.Transparency = if isToday then 0 else 1
		tile.Frame.BackgroundTransparency = if claimed then 0.5 else 0
		tile.Day.TextColor3 = if isToday then ACCENT else MUTED
		if claimed then
			tile.Status.Text = "✓ PEGO"
			tile.Status.TextColor3 = DONE
		elseif isToday then
			tile.Status.Text = "HOJE"
			tile.Status.TextColor3 = ACCENT
		else
			tile.Status.Text = ""
		end
	end

	badge.Visible = state.CanClaim == true
	claimButton.AutoButtonColor = state.CanClaim == true
	claimButton.BackgroundColor3 = if state.CanClaim then ACCENT else Color3.fromRGB(60, 60, 66)
	claimButton.TextColor3 = if state.CanClaim then DARK else MUTED
	if state.CanClaim then
		claimButton.Text = "RESGATAR"
	end

	if state.CanClaim and Config.ShowAutomatically then
		panel.Visible = true
	end
end

local function updateScale()
	local camera = workspace.CurrentCamera
	if camera then
		panelScale.Scale = math.clamp((camera.ViewportSize.X - 24) / PANEL_WIDTH, 0.45, 1)
	end
end

player:GetAttributeChangedSignal("DailyReward"):Connect(function()
	updateScale()
	render()
end)
updateScale()
render()

claimButton.Activated:Connect(function()
	if busy or not state or not state.CanClaim then
		return
	end
	busy = true
	claimButton.Text = "..."
	local ok, success = pcall(ClaimRemote.InvokeServer, ClaimRemote)
	busy = false
	if ok and success then
		task.delay(1.2, function()
			panel.Visible = false
		end)
	else
		claimButton.Text = "TENTE DE NOVO"
	end
end)

openButton.Activated:Connect(function()
	updateScale()
	panel.Visible = not panel.Visible
end)
closeButton.Activated:Connect(function()
	panel.Visible = false
end)

-- Contador "Volte em" quando já resgatou hoje.
RunService.Heartbeat:Connect(function()
	if panel.Visible and state and not state.CanClaim and not busy and type(state.ResetsAt) == "number" then
		claimButton.Text = `VOLTE EM {formatDuration(state.ResetsAt - workspace:GetServerTimeNow())}`
	end
end)
