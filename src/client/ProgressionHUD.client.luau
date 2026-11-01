--[[
	HUD de progressão: barra de XP, avisos de "+XP" e banner de subir de nível.

	Lê os atributos "Level", "XP", "XPToNext" e "Title" do jogador
	(definidos pelo ProgressionService) e ouve os RemoteEvents de
	ProgressionRemotes.
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local player = Players.LocalPlayer
local Progression = ReplicatedStorage:WaitForChild("Progression")
local Config = require(Progression:WaitForChild("Config"))
local Remotes = ReplicatedStorage:WaitForChild("ProgressionRemotes")

local ACCENT = Color3.fromRGB(255, 196, 0)
local DARK = Color3.fromRGB(20, 20, 24)
local FONT = Enum.Font.GothamBold

-- Distância da barra de XP até a parte de baixo da tela.
-- Se a hotbar de armas existir, a barra fica logo acima dela.
local function getBottomOffset(): number
	local hotbar = ReplicatedStorage:WaitForChild("Hotbar", 5)
	local hotbarConfig = hotbar and hotbar:FindFirstChild("Config")
	if hotbarConfig and hotbarConfig:IsA("ModuleScript") then
		local HotbarConfig = require(hotbarConfig) :: any
		return HotbarConfig.BottomMargin + HotbarConfig.SlotSize + 12
	end
	return 16
end

local BOTTOM_OFFSET = getBottomOffset()

---------------------------------------------------------------------------
-- Montagem da interface
---------------------------------------------------------------------------

local function corner(parent: Instance, radius: number)
	local uiCorner = Instance.new("UICorner")
	uiCorner.CornerRadius = UDim.new(0, radius)
	uiCorner.Parent = parent
end

local function label(props: { [string]: any }): TextLabel
	local textLabel = Instance.new("TextLabel")
	textLabel.BackgroundTransparency = 1
	textLabel.Font = FONT
	textLabel.TextColor3 = Color3.new(1, 1, 1)
	textLabel.TextStrokeTransparency = 0.6
	for key, value in props do
		(textLabel :: any)[key] = value
	end
	return textLabel
end

local gui = Instance.new("ScreenGui")
gui.Name = "ProgressionHUD"
gui.ResetOnSpawn = false
gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
gui.Parent = player:WaitForChild("PlayerGui")

-- Barra de XP (embaixo, no centro)
local container = Instance.new("Frame")
container.Name = "XPBar"
container.AnchorPoint = Vector2.new(0.5, 1)
container.Position = UDim2.new(0.5, 0, 1, -BOTTOM_OFFSET)
container.Size = UDim2.fromOffset(360, 30)
container.BackgroundTransparency = 1
container.Parent = gui

local levelBadge = Instance.new("Frame")
levelBadge.Size = UDim2.fromOffset(56, 30)
levelBadge.BackgroundColor3 = ACCENT
levelBadge.Parent = container
corner(levelBadge, 6)

local levelLabel = label({
	Size = UDim2.fromScale(1, 1),
	Text = "1",
	TextColor3 = DARK,
	TextStrokeTransparency = 1,
	TextSize = 18,
	Parent = levelBadge,
})

local barBackground = Instance.new("Frame")
barBackground.Position = UDim2.fromOffset(64, 7)
barBackground.Size = UDim2.new(1, -64, 0, 16)
barBackground.BackgroundColor3 = DARK
barBackground.BackgroundTransparency = 0.25
barBackground.ClipsDescendants = true
barBackground.Parent = container
corner(barBackground, 8)

local barFill = Instance.new("Frame")
barFill.Size = UDim2.fromScale(0, 1)
barFill.BackgroundColor3 = ACCENT
barFill.Parent = barBackground
corner(barFill, 8)

local xpLabel = label({
	Size = UDim2.fromScale(1, 1),
	Text = "0 / 0 XP",
	TextSize = 12,
	ZIndex = 2,
	Parent = barBackground,
})

local titleLabel = label({
	AnchorPoint = Vector2.new(0, 1),
	Position = UDim2.fromOffset(64, 6),
	Size = UDim2.new(1, -64, 0, 16),
	Text = "",
	TextColor3 = ACCENT,
	TextSize = 13,
	TextXAlignment = Enum.TextXAlignment.Left,
	Parent = container,
})

-- Avisos de "+XP" (acima da barra)
local feed = Instance.new("Frame")
feed.Name = "XPFeed"
feed.AnchorPoint = Vector2.new(0.5, 1)
feed.Position = UDim2.new(0.5, 0, 1, -(BOTTOM_OFFSET + 56))
feed.Size = UDim2.fromOffset(360, 120)
feed.BackgroundTransparency = 1
feed.Parent = gui

local feedLayout = Instance.new("UIListLayout")
feedLayout.VerticalAlignment = Enum.VerticalAlignment.Bottom
feedLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
feedLayout.SortOrder = Enum.SortOrder.LayoutOrder
feedLayout.Padding = UDim.new(0, 2)
feedLayout.Parent = feed

-- Banner de subir de nível (no topo)
local banner = Instance.new("Frame")
banner.Name = "LevelUpBanner"
banner.AnchorPoint = Vector2.new(0.5, 0)
banner.Position = UDim2.new(0.5, 0, 0, -140)
banner.Size = UDim2.fromOffset(420, 110)
banner.BackgroundColor3 = DARK
banner.BackgroundTransparency = 0.15
banner.Visible = false
banner.Parent = gui
corner(banner, 10)

local bannerStroke = Instance.new("UIStroke")
bannerStroke.Color = ACCENT
bannerStroke.Thickness = 2
bannerStroke.Parent = banner

local bannerTitle = label({
	Position = UDim2.fromOffset(0, 10),
	Size = UDim2.new(1, 0, 0, 22),
	Text = "SUBIU DE NÍVEL!",
	TextColor3 = ACCENT,
	TextSize = 18,
	Parent = banner,
})

local bannerLevel = label({
	Position = UDim2.fromOffset(0, 34),
	Size = UDim2.new(1, 0, 0, 36),
	Text = "Nível 2",
	TextSize = 32,
	Parent = banner,
})

local bannerReward = label({
	Position = UDim2.fromOffset(10, 74),
	Size = UDim2.new(1, -20, 0, 28),
	Text = "",
	TextSize = 14,
	TextWrapped = true,
	Parent = banner,
})

---------------------------------------------------------------------------
-- Atualização
---------------------------------------------------------------------------

local function refresh()
	local level = player:GetAttribute("Level") or 1
	local xp = player:GetAttribute("XP") or 0
	local xpToNext = player:GetAttribute("XPToNext") or 0
	local title = player:GetAttribute("Title")

	levelLabel.Text = tostring(level)
	titleLabel.Text = if type(title) == "string" then title else ""

	local ratio
	if level >= Config.MaxLevel or xpToNext <= 0 then
		ratio = 1
		xpLabel.Text = "NÍVEL MÁXIMO"
	else
		ratio = math.clamp(xp / xpToNext, 0, 1)
		xpLabel.Text = `{xp} / {xpToNext} XP`
	end

	TweenService:Create(barFill, TweenInfo.new(0.35, Enum.EasingStyle.Quad), {
		Size = UDim2.fromScale(ratio, 1),
	}):Play()
end

for _, attribute in { "Level", "XP", "XPToNext", "Title" } do
	player:GetAttributeChangedSignal(attribute):Connect(refresh)
end
refresh()

local feedOrder = 0
local function showXPGain(amount: number, reason: string?)
	feedOrder += 1
	local reasonText = reason and Config.ReasonLabels[reason] or reason
	local text = if reasonText then `+{amount} XP  {reasonText}` else `+{amount} XP`

	local entry = label({
		Size = UDim2.new(1, 0, 0, 20),
		Text = text,
		TextColor3 = ACCENT,
		TextSize = 16,
		LayoutOrder = feedOrder,
		Parent = feed,
	})

	task.delay(1.8, function()
		local fade = TweenService:Create(entry, TweenInfo.new(0.5), {
			TextTransparency = 1,
			TextStrokeTransparency = 1,
		})
		fade:Play()
		fade.Completed:Wait()
		entry:Destroy()
	end)
end

-- Fila para não sobrepor banners quando sobe vários níveis de uma vez.
local bannerQueue = {}
local bannerShowing = false

local function describeReward(reward): string
	if type(reward) ~= "table" then
		return ""
	end
	local parts = {}
	if reward.Title then
		table.insert(parts, `Título: {reward.Title}`)
	end
	if type(reward.Unlocks) == "table" and #reward.Unlocks > 0 then
		table.insert(parts, "Desbloqueado: " .. table.concat(reward.Unlocks, ", "))
	end
	return table.concat(parts, "  •  ")
end

local function showNextBanner()
	if bannerShowing or #bannerQueue == 0 then
		return
	end
	bannerShowing = true

	local item = table.remove(bannerQueue, 1)
	bannerLevel.Text = `Nível {item.Level}`
	bannerReward.Text = describeReward(item.Reward)
	bannerTitle.Text = "SUBIU DE NÍVEL!"

	banner.Position = UDim2.new(0.5, 0, 0, -140)
	banner.Visible = true

	local show = TweenService:Create(banner, TweenInfo.new(0.4, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
		Position = UDim2.new(0.5, 0, 0, 24),
	})
	show:Play()
	show.Completed:Wait()
	task.wait(2.5)

	local hide = TweenService:Create(banner, TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {
		Position = UDim2.new(0.5, 0, 0, -140),
	})
	hide:Play()
	hide.Completed:Wait()

	banner.Visible = false
	bannerShowing = false
	showNextBanner()
end

Remotes:WaitForChild("XPGained").OnClientEvent:Connect(showXPGain)

Remotes:WaitForChild("LevelUp").OnClientEvent:Connect(function(level: number, reward)
	table.insert(bannerQueue, { Level = level, Reward = reward })
	task.spawn(showNextBanner)
end)
