--[[
	HUD do modo treino: painel com tempo, alvos abatidos e dicas, e o aviso
	"INDO PARA O MODO PRINCIPAL!" no final.
	Lê os atributos TrainingEndsAt, TrainingKills e TrainingEnding do Player.
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")

local player = Players.LocalPlayer
local Config = require(ReplicatedStorage:WaitForChild("Training"):WaitForChild("Config"))

local DARK = Color3.fromRGB(14, 14, 18)
local ACCENT = Color3.fromRGB(255, 196, 0)
local MUTED = Color3.fromRGB(170, 170, 170)

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

local gui = Instance.new("ScreenGui")
gui.Name = "Training"
gui.ResetOnSpawn = false
gui.DisplayOrder = 7
gui.Parent = player:WaitForChild("PlayerGui")

-- Painel (lado direito)
local panel = Instance.new("Frame")
panel.AnchorPoint = Vector2.new(1, 0)
panel.Position = UDim2.new(1, -16, 0.2, 0)
panel.Size = UDim2.fromOffset(300, 150)
panel.BackgroundColor3 = DARK
panel.BackgroundTransparency = 0.15
panel.Visible = false
panel.Parent = gui
corner(panel, 12)

local panelStroke = Instance.new("UIStroke")
panelStroke.Color = ACCENT
panelStroke.Thickness = 2
panelStroke.Parent = panel

local panelScale = Instance.new("UIScale")
panelScale.Parent = panel

label(panel, {
	Position = UDim2.fromOffset(14, 10),
	Size = UDim2.new(1, -90, 0, 22),
	Font = Enum.Font.GothamBlack,
	TextSize = 18,
	TextColor3 = ACCENT,
	Text = "🎯 MODO TREINO",
})

local timerLabel = label(panel, {
	AnchorPoint = Vector2.new(1, 0),
	Position = UDim2.new(1, -14, 0, 10),
	Size = UDim2.fromOffset(70, 22),
	Font = Enum.Font.GothamBlack,
	TextSize = 18,
	TextXAlignment = Enum.TextXAlignment.Right,
	Text = "5:00",
})

local killsLabel = label(panel, {
	Position = UDim2.fromOffset(14, 34),
	Size = UDim2.new(1, -28, 0, 18),
	Font = Enum.Font.GothamMedium,
	TextSize = 14,
	TextColor3 = MUTED,
	Text = "Alvos abatidos: 0",
})

local divider = Instance.new("Frame")
divider.Position = UDim2.fromOffset(14, 58)
divider.Size = UDim2.new(1, -28, 0, 1)
divider.BackgroundColor3 = Color3.fromRGB(60, 60, 66)
divider.BorderSizePixel = 0
divider.Parent = panel

local tipCounter = label(panel, {
	Position = UDim2.fromOffset(14, 66),
	Size = UDim2.new(1, -28, 0, 14),
	Font = Enum.Font.GothamBold,
	TextSize = 12,
	TextColor3 = ACCENT,
	Text = "DICA 1",
})

local tipLabel = label(panel, {
	Position = UDim2.fromOffset(14, 82),
	Size = UDim2.new(1, -28, 0, 58),
	Font = Enum.Font.GothamMedium,
	TextSize = 15,
	TextWrapped = true,
	TextYAlignment = Enum.TextYAlignment.Top,
	Text = "",
})

-- Aviso grande do final
local banner = label(gui, {
	AnchorPoint = Vector2.new(0.5, 0.5),
	Position = UDim2.fromScale(0.5, 0.4),
	Size = UDim2.new(0.9, 0, 0, 60),
	Font = Enum.Font.GothamBlack,
	TextScaled = true,
	TextXAlignment = Enum.TextXAlignment.Center,
	TextColor3 = ACCENT,
	TextStrokeTransparency = 0.3,
	Text = "INDO PARA O MODO PRINCIPAL!",
	Visible = false,
})
local bannerLimit = Instance.new("UITextSizeConstraint")
bannerLimit.MaxTextSize = 48
bannerLimit.Parent = banner

---------------------------------------------------------------------------
-- Atualização
---------------------------------------------------------------------------

local tipIndex = 1
local nextTipAt = 0

local function showTip(index: number)
	local tips = Config.Tips
	if #tips == 0 then
		return
	end
	tipIndex = (index - 1) % #tips + 1
	tipCounter.Text = `DICA {tipIndex}/{#tips}`
	tipLabel.Text = tips[tipIndex]
	tipLabel.TextTransparency = 1
	TweenService:Create(tipLabel, TweenInfo.new(0.4), { TextTransparency = 0 }):Play()
	nextTipAt = os.clock() + Config.TipInterval
end

local function updateScale()
	local camera = workspace.CurrentCamera
	if camera then
		panelScale.Scale = math.clamp((camera.ViewportSize.X - 32) / 300 / 2.2, 0.6, 1)
	end
end

local function refresh()
	local endsAt = player:GetAttribute("TrainingEndsAt")
	local wasVisible = panel.Visible
	panel.Visible = type(endsAt) == "number"
	if panel.Visible and not wasVisible then
		updateScale()
		showTip(1)
	end

	killsLabel.Text = `Alvos abatidos: {player:GetAttribute("TrainingKills") or 0}`
	banner.Visible = player:GetAttribute("TrainingEnding") == true
end

for _, attribute in { "TrainingEndsAt", "TrainingKills", "TrainingEnding" } do
	player:GetAttributeChangedSignal(attribute):Connect(refresh)
end
refresh()

RunService.Heartbeat:Connect(function()
	if not panel.Visible then
		return
	end
	local endsAt = player:GetAttribute("TrainingEndsAt")
	if type(endsAt) == "number" then
		local seconds = math.max(0, math.floor(endsAt - workspace:GetServerTimeNow()))
		timerLabel.Text = string.format("%d:%02d", seconds // 60, seconds % 60)
	end
	if os.clock() >= nextTipAt then
		showTip(tipIndex + 1)
	end
end)
