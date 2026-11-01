--[[
	Câmera de morte: quando você morre, a câmera segue quem te matou até
	você renascer, e aparece um painel com o nome dele, a arma e a vida.
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local player = Players.LocalPlayer
local KilledByRemote = ReplicatedStorage:WaitForChild("GameRemotes"):WaitForChild("KilledBy") :: RemoteEvent

local DARK = Color3.fromRGB(14, 14, 18)
local RED = Color3.fromRGB(255, 70, 60)
local MUTED = Color3.fromRGB(170, 170, 170)

local gui = Instance.new("ScreenGui")
gui.Name = "DeathCam"
gui.ResetOnSpawn = false
gui.DisplayOrder = 9
gui.Enabled = false
gui.Parent = player:WaitForChild("PlayerGui")

local panel = Instance.new("Frame")
panel.AnchorPoint = Vector2.new(0.5, 0)
panel.Position = UDim2.new(0.5, 0, 0.62, 0)
panel.Size = UDim2.fromOffset(340, 104)
panel.BackgroundColor3 = DARK
panel.BackgroundTransparency = 0.15
panel.Parent = gui

local panelCorner = Instance.new("UICorner")
panelCorner.CornerRadius = UDim.new(0, 12)
panelCorner.Parent = panel

local panelStroke = Instance.new("UIStroke")
panelStroke.Color = RED
panelStroke.Thickness = 2
panelStroke.Parent = panel

local function label(props: { [string]: any }): TextLabel
	local textLabel = Instance.new("TextLabel")
	textLabel.BackgroundTransparency = 1
	textLabel.Font = Enum.Font.GothamBold
	textLabel.TextColor3 = Color3.new(1, 1, 1)
	textLabel.Size = UDim2.new(1, -24, 0, 20)
	for key, value in props do
		(textLabel :: any)[key] = value
	end
	textLabel.Parent = panel
	return textLabel
end

local titleLabel = label({ Position = UDim2.fromOffset(12, 8), TextSize = 14, TextColor3 = RED, Text = "MORTO POR" })
local killerLabel = label({ Position = UDim2.fromOffset(12, 28), Size = UDim2.new(1, -24, 0, 28), Font = Enum.Font.GothamBlack, TextSize = 26, Text = "" })
local detailLabel = label({ Position = UDim2.fromOffset(12, 58), Font = Enum.Font.GothamMedium, TextSize = 14, TextColor3 = MUTED, Text = "" })
local respawnLabel = label({ Position = UDim2.fromOffset(12, 78), Font = Enum.Font.GothamMedium, TextSize = 13, TextColor3 = MUTED, Text = "" })

local respawnAt: number? = nil
local spectating: Humanoid? = nil

local function stopSpectating()
	spectating = nil
	gui.Enabled = false
	respawnAt = nil
end

KilledByRemote.OnClientEvent:Connect(function(killer: Player?, weapon: string?, killerHealth: number?)
	if killer and killer.Parent == Players then
		titleLabel.Text = "MORTO POR"
		killerLabel.Text = killer.DisplayName
		killerLabel.TextColor3 = if killer.Team and not killer.Neutral then killer.TeamColor.Color else Color3.new(1, 1, 1)

		local details = {}
		if weapon then
			table.insert(details, `🔫 {weapon}`)
		end
		if killerHealth then
			table.insert(details, `❤ {killerHealth} de vida`)
		end
		detailLabel.Text = table.concat(details, "   ")

		-- A câmera passa a seguir quem matou.
		local character = killer.Character
		local humanoid = character and character:FindFirstChildOfClass("Humanoid")
		if humanoid and humanoid.Health > 0 then
			spectating = humanoid
			workspace.CurrentCamera.CameraSubject = humanoid
		end
	else
		titleLabel.Text = ""
		killerLabel.Text = "VOCÊ MORREU"
		killerLabel.TextColor3 = RED
		detailLabel.Text = ""
	end

	respawnAt = if Players.CharacterAutoLoads then os.clock() + Players.RespawnTime else nil
	gui.Enabled = true
end)

RunService.Heartbeat:Connect(function()
	if not gui.Enabled then
		return
	end

	if respawnAt then
		respawnLabel.Text = `Renascendo em {math.max(0, math.ceil(respawnAt - os.clock()))}...`
	else
		respawnLabel.Text = ""
	end

	-- Se quem você está assistindo morrer ou sair, para de seguir.
	if spectating and (spectating.Health <= 0 or not spectating:IsDescendantOf(workspace)) then
		spectating = nil
		local character = player.Character
		local ownHumanoid = character and character:FindFirstChildOfClass("Humanoid")
		if ownHumanoid then
			workspace.CurrentCamera.CameraSubject = ownHumanoid
		end
	end
end)

-- Renasceu: câmera volta para você.
player.CharacterAdded:Connect(function(character)
	stopSpectating()
	local humanoid = character:WaitForChild("Humanoid", 10)
	if humanoid then
		workspace.CurrentCamera.CameraSubject = humanoid
	end
end)
