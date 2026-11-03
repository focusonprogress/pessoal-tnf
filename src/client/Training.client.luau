--[[
	HUD do modo treino:
	- Intro com câmera: voa até os bonecos, mostra e volta para o jogador
	- Painel com tempo, alvos abatidos e dicas (aparece depois da intro)
	- Aviso "INDO PARA O MODO PRINCIPAL!" no final

	Lê os atributos TrainingEndsAt, TrainingKills, TrainingFocus e
	TrainingEnding do Player.
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
gui.IgnoreGuiInset = true
gui.Parent = player:WaitForChild("PlayerGui")

---------------------------------------------------------------------------
-- Painel (lado direito)
---------------------------------------------------------------------------

local panel = Instance.new("Frame")
panel.AnchorPoint = Vector2.new(1, 0)
panel.Position = UDim2.new(1, -16, 0.22, 0)
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

---------------------------------------------------------------------------
-- Intro (faixas de cinema + título)
---------------------------------------------------------------------------

local topBar = Instance.new("Frame")
topBar.BackgroundColor3 = Color3.new(0, 0, 0)
topBar.BorderSizePixel = 0
topBar.Size = UDim2.new(1, 0, 0, 0)
topBar.Visible = false
topBar.Parent = gui

local bottomBar = Instance.new("Frame")
bottomBar.BackgroundColor3 = Color3.new(0, 0, 0)
bottomBar.BorderSizePixel = 0
bottomBar.AnchorPoint = Vector2.new(0, 1)
bottomBar.Position = UDim2.fromScale(0, 1)
bottomBar.Size = UDim2.new(1, 0, 0, 0)
bottomBar.Visible = false
bottomBar.Parent = gui

local introTitle = label(gui, {
	AnchorPoint = Vector2.new(0.5, 1),
	Position = UDim2.new(0.5, 0, 0.8, 0),
	Size = UDim2.new(0.9, 0, 0, 56),
	Font = Enum.Font.GothamBlack,
	TextScaled = true,
	TextXAlignment = Enum.TextXAlignment.Center,
	TextColor3 = ACCENT,
	TextStrokeTransparency = 0.4,
	TextTransparency = 1,
	Text = Config.Intro.Title,
})
local introTitleLimit = Instance.new("UITextSizeConstraint")
introTitleLimit.MaxTextSize = 52
introTitleLimit.Parent = introTitle

local introSubtitle = label(gui, {
	AnchorPoint = Vector2.new(0.5, 0),
	Position = UDim2.new(0.5, 0, 0.8, 4),
	Size = UDim2.new(0.9, 0, 0, 24),
	Font = Enum.Font.GothamMedium,
	TextScaled = true,
	TextXAlignment = Enum.TextXAlignment.Center,
	TextStrokeTransparency = 0.5,
	TextTransparency = 1,
	Text = Config.Intro.Subtitle,
})
local introSubtitleLimit = Instance.new("UITextSizeConstraint")
introSubtitleLimit.MaxTextSize = 22
introSubtitleLimit.Parent = introSubtitle

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
-- Controles do jogador (parar durante a intro)
---------------------------------------------------------------------------

local function setControlsEnabled(enabled: boolean)
	pcall(function()
		local playerModule = require(player:WaitForChild("PlayerScripts"):WaitForChild("PlayerModule", 5) :: ModuleScript)
		local controls = playerModule:GetControls()
		if enabled then
			controls:Enable()
		else
			controls:Disable()
		end
	end)
end

---------------------------------------------------------------------------
-- Estado
---------------------------------------------------------------------------

local inTraining = false
local introDone = false
local introRunning = false
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

local function showPanel()
	if panel.Visible or not inTraining then
		return
	end
	updateScale()
	panel.Visible = true
	showTip(1)
end

-- A tela de escolha de time está aberta?
local function teamSelectOpen(): boolean
	local playerGui = player:FindFirstChildOfClass("PlayerGui")
	local teamSelect = playerGui and playerGui:FindFirstChild("TeamSelect")
	return teamSelect ~= nil and teamSelect:IsA("ScreenGui") and teamSelect.Enabled
end

local function tween(instance: Instance, seconds: number, goal: { [string]: any }, style: Enum.EasingStyle?): Tween
	local animation = TweenService:Create(instance, TweenInfo.new(seconds, style or Enum.EasingStyle.Quad, Enum.EasingDirection.InOut), goal)
	animation:Play()
	return animation
end

local function restoreView()
	local camera = workspace.CurrentCamera
	if camera then
		camera.CameraType = Enum.CameraType.Custom
		local humanoid = player.Character and player.Character:FindFirstChildOfClass("Humanoid")
		if humanoid then
			camera.CameraSubject = humanoid
		end
	end
	introTitle.TextTransparency = 1
	introSubtitle.TextTransparency = 1
	setControlsEnabled(true)
end

-- A câmera voa até os bonecos, mostra eles e volta.
local function runCameraIntro(root: BasePart, focus: Vector3)
	local camera = workspace.CurrentCamera
	setControlsEnabled(false)

	-- Faixas de cinema entram
	topBar.Visible = true
	bottomBar.Visible = true
	tween(topBar, 0.5, { Size = UDim2.new(1, 0, 0.12, 0) })
	tween(bottomBar, 0.5, { Size = UDim2.new(1, 0, 0.12, 0) })

	-- Vista de cima dos bonecos, do lado de onde o jogador está
	camera.CameraType = Enum.CameraType.Scriptable
	local fromPlayer = root.Position - focus
	local flat = Vector3.new(fromPlayer.X, 0, fromPlayer.Z)
	local direction = if flat.Magnitude > 0.1 then flat.Unit else Vector3.new(0, 0, 1)
	local viewPosition = focus + direction * 24 + Vector3.new(0, 14, 0)
	tween(camera, Config.Intro.FlyTime, { CFrame = CFrame.lookAt(viewPosition, focus) }, Enum.EasingStyle.Sine)

	task.wait(Config.Intro.FlyTime * 0.6)
	tween(introTitle, 0.5, { TextTransparency = 0 })
	tween(introSubtitle, 0.5, { TextTransparency = 0 })
	task.wait(Config.Intro.FlyTime * 0.4 + Config.Intro.HoldTime)

	-- Volta para trás do jogador
	tween(introTitle, 0.4, { TextTransparency = 1 })
	tween(introSubtitle, 0.4, { TextTransparency = 1 })
	local currentRoot = (player.Character and player.Character:FindFirstChild("HumanoidRootPart")) or root
	local backCFrame = CFrame.lookAt(
		currentRoot.Position - currentRoot.CFrame.LookVector * 10 + Vector3.new(0, 4, 0),
		currentRoot.Position + Vector3.new(0, 1.5, 0)
	)
	tween(camera, Config.Intro.ReturnTime, { CFrame = backCFrame }, Enum.EasingStyle.Sine).Completed:Wait()
end

local function playIntro()
	if introRunning or introDone then
		return
	end
	introRunning = true

	-- Espera a tela de times fechar.
	while inTraining and teamSelectOpen() do
		task.wait(0.25)
	end

	-- Espera o personagem e os bonecos ficarem perto dele (até 6s).
	local root, focus
	local deadline = os.clock() + 6
	repeat
		task.wait(0.25)
		local character = player.Character
		root = character and character:FindFirstChild("HumanoidRootPart")
		focus = player:GetAttribute("TrainingFocus")
		local ready = root and typeof(focus) == "Vector3" and (root.Position - focus).Magnitude < 200
	until ready or os.clock() > deadline or not inTraining

	if inTraining and root and typeof(focus) == "Vector3" and workspace.CurrentCamera then
		local ok, err = pcall(runCameraIntro, root, focus)
		if not ok then
			warn("[Training] Erro na intro:", err)
		end
	end

	-- Sempre devolve a câmera, os controles e tira as faixas.
	restoreView()
	tween(topBar, 0.4, { Size = UDim2.new(1, 0, 0, 0) })
	tween(bottomBar, 0.4, { Size = UDim2.new(1, 0, 0, 0) }).Completed:Wait()
	topBar.Visible = false
	bottomBar.Visible = false

	introRunning = false
	introDone = true
	showPanel()
end

-- Teleporta o próprio personagem para o spawn do treino. Feito no cliente
-- porque é ele que controla a posição do personagem (o teleporte do servidor
-- às vezes é desfeito logo depois de nascer).
local function moveToTrainingSpawn(character: Model)
	local root = character:WaitForChild("HumanoidRootPart", 10)
	if not root or not root:IsA("BasePart") then
		return
	end
	for _ = 1, 15 do
		local spawnCFrame = player:GetAttribute("TrainingSpawn")
		if not inTraining or typeof(spawnCFrame) ~= "CFrame" or character.Parent == nil then
			return
		end
		local target = spawnCFrame + Vector3.new(0, 4, 0)
		if (root.Position - target.Position).Magnitude > 20 then
			character:PivotTo(target)
			root.AssemblyLinearVelocity = Vector3.zero
		end
		task.wait(0.2)
	end
end

player.CharacterAdded:Connect(function(character)
	if inTraining then
		task.spawn(moveToTrainingSpawn, character)
	end
end)

local function refresh()
	local endsAt = player:GetAttribute("TrainingEndsAt")
	local nowInTraining = type(endsAt) == "number"

	if nowInTraining and not inTraining then
		-- Começou um treino novo
		inTraining = true
		introDone = false
		if player.Character then
			task.spawn(moveToTrainingSpawn, player.Character)
		end
		if Config.Intro.Enabled then
			task.spawn(playIntro)
		else
			introDone = true
			showPanel()
		end
	elseif not nowInTraining and inTraining then
		inTraining = false
		panel.Visible = false
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
