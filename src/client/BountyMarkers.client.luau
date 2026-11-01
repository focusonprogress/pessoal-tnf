--[[
	Marcador "💀 R$ 5.000" acima da cabeça de quem está com a cabeça a prêmio.
	Lê o atributo "Bounty" que o servidor coloca no Player.
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local localPlayer = Players.LocalPlayer
local Config = require(ReplicatedStorage:WaitForChild("Bounty"):WaitForChild("Config"))
local EconomyConfig = require(ReplicatedStorage:WaitForChild("Economy"):WaitForChild("Config"))

if not Config.Marker.Enabled then
	return
end

local playerGui = localPlayer:WaitForChild("PlayerGui")
local markers: { [Player]: BillboardGui } = {}

local function getMarker(player: Player): BillboardGui
	local marker = markers[player]
	if marker then
		return marker
	end

	marker = Instance.new("BillboardGui")
	marker.Name = `Bounty_{player.Name}`
	marker.Size = UDim2.fromOffset(160, 30)
	marker.StudsOffset = Vector3.new(0, 4.4, 0)
	marker.AlwaysOnTop = Config.Marker.AlwaysOnTop
	marker.MaxDistance = Config.Marker.MaxDistance
	marker.ResetOnSpawn = false
	marker.Enabled = false
	marker.Parent = playerGui

	local label = Instance.new("TextLabel")
	label.Name = "Label"
	label.BackgroundColor3 = Color3.fromRGB(20, 0, 0)
	label.BackgroundTransparency = 0.25
	label.Size = UDim2.fromScale(1, 1)
	label.Font = Enum.Font.GothamBlack
	label.TextSize = 16
	label.TextColor3 = Color3.fromRGB(255, 70, 60)
	label.TextStrokeTransparency = 0.5
	label.Parent = marker

	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 6)
	corner.Parent = label

	markers[player] = marker
	return marker
end

local function update(player: Player)
	local bounty = player:GetAttribute("Bounty")
	local character = player.Character
	local head = character and character:FindFirstChild("Head")

	if type(bounty) ~= "number" or bounty <= 0 or not head then
		local marker = markers[player]
		if marker then
			marker.Enabled = false
		end
		return
	end

	local marker = getMarker(player)
	marker.Adornee = head
	marker.Enabled = true
	local label = marker:FindFirstChild("Label") :: TextLabel
	label.Text = `💀 {EconomyConfig.Format(bounty)}`
end

local function onPlayerAdded(player: Player)
	if player == localPlayer then
		return
	end
	player:GetAttributeChangedSignal("Bounty"):Connect(function()
		update(player)
	end)
	player.CharacterAdded:Connect(function(character)
		character:WaitForChild("Head", 10)
		update(player)
	end)
	update(player)
end

Players.PlayerAdded:Connect(onPlayerAdded)
for _, player in Players:GetPlayers() do
	task.spawn(onPlayerAdded, player)
end

Players.PlayerRemoving:Connect(function(player)
	local marker = markers[player]
	if marker then
		marker:Destroy()
		markers[player] = nil
	end
end)
