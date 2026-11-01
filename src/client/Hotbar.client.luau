--[[
	Hotbar de armas: mostra as ferramentas da mochila (armas do ACS, etc.)
	embaixo da tela e substitui a mochila padrão do Roblox.

	- Teclas 1 a 9 equipam/desequipam (no celular, é só tocar no espaço)
	- A arma equipada fica destacada em amarelo
	- Mostra o ícone da ferramenta (TextureId) quando ela tiver um
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local StarterGui = game:GetService("StarterGui")
local UserInputService = game:GetService("UserInputService")

local player = Players.LocalPlayer
local Config = require(ReplicatedStorage:WaitForChild("Hotbar"):WaitForChild("Config"))
local Colors = Config.Colors

---------------------------------------------------------------------------
-- Esconde a mochila padrão do Roblox
---------------------------------------------------------------------------

task.spawn(function()
	-- SetCoreGuiEnabled pode falhar se for chamado cedo demais.
	for _ = 1, 20 do
		local ok = pcall(StarterGui.SetCoreGuiEnabled, StarterGui, Enum.CoreGuiType.Backpack, false)
		if ok then
			return
		end
		task.wait(0.5)
	end
end)

---------------------------------------------------------------------------
-- Interface
---------------------------------------------------------------------------

local gui = Instance.new("ScreenGui")
gui.Name = "Hotbar"
gui.ResetOnSpawn = false
gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
gui.Parent = player:WaitForChild("PlayerGui")

local fullWidth = Config.MaxSlots * Config.SlotSize + (Config.MaxSlots - 1) * Config.SlotPadding

local bar = Instance.new("Frame")
bar.Name = "Slots"
bar.AnchorPoint = Vector2.new(0.5, 1)
bar.Position = UDim2.new(0.5, 0, 1, -Config.BottomMargin)
bar.Size = UDim2.fromOffset(fullWidth, Config.SlotSize)
bar.BackgroundTransparency = 1
bar.Parent = gui

local layout = Instance.new("UIListLayout")
layout.FillDirection = Enum.FillDirection.Horizontal
layout.HorizontalAlignment = Enum.HorizontalAlignment.Center
layout.SortOrder = Enum.SortOrder.LayoutOrder
layout.Padding = UDim.new(0, Config.SlotPadding)
layout.Parent = bar

-- Diminui a hotbar em telas pequenas (celular) para caber.
local uiScale = Instance.new("UIScale")
uiScale.Parent = bar

local function updateScale()
	local camera = workspace.CurrentCamera
	if not camera then
		return
	end
	local available = camera.ViewportSize.X - 20
	uiScale.Scale = math.clamp(available / fullWidth, 0.5, 1)
end

local function watchCamera()
	local camera = workspace.CurrentCamera
	if camera then
		camera:GetPropertyChangedSignal("ViewportSize"):Connect(updateScale)
	end
	updateScale()
end
workspace:GetPropertyChangedSignal("CurrentCamera"):Connect(watchCamera)
watchCamera()

type SlotUI = {
	Button: TextButton,
	Stroke: UIStroke,
	Icon: ImageLabel,
	Name: TextLabel,
	Key: TextLabel,
}

local slotUIs: { SlotUI } = {}

local function createSlot(index: number): SlotUI
	local button = Instance.new("TextButton")
	button.Name = `Slot{index}`
	button.LayoutOrder = index
	button.Size = UDim2.fromOffset(Config.SlotSize, Config.SlotSize)
	button.BackgroundColor3 = Colors.Slot
	button.BackgroundTransparency = 0.2
	button.AutoButtonColor = false
	button.Text = ""
	button.Parent = bar

	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 8)
	corner.Parent = button

	local stroke = Instance.new("UIStroke")
	stroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
	stroke.Color = Colors.Accent
	stroke.Thickness = 2
	stroke.Transparency = 1
	stroke.Parent = button

	local key = Instance.new("TextLabel")
	key.Name = "Key"
	key.BackgroundTransparency = 1
	key.Position = UDim2.fromOffset(6, 3)
	key.Size = UDim2.fromOffset(16, 14)
	key.Font = Enum.Font.GothamBold
	key.TextSize = 12
	key.TextColor3 = Colors.TextMuted
	key.TextXAlignment = Enum.TextXAlignment.Left
	key.Text = tostring(index)
	key.ZIndex = 2
	key.Parent = button

	local icon = Instance.new("ImageLabel")
	icon.Name = "Icon"
	icon.BackgroundTransparency = 1
	icon.AnchorPoint = Vector2.new(0.5, 0.5)
	icon.Position = UDim2.fromScale(0.5, 0.42)
	icon.Size = UDim2.fromScale(0.6, 0.6)
	icon.ScaleType = Enum.ScaleType.Fit
	icon.Parent = button

	local name = Instance.new("TextLabel")
	name.Name = "ToolName"
	name.BackgroundTransparency = 1
	name.Font = Enum.Font.GothamBold
	name.TextColor3 = Colors.Text
	name.TextScaled = true
	name.TextWrapped = true
	name.Parent = button

	local sizeLimit = Instance.new("UITextSizeConstraint")
	sizeLimit.MaxTextSize = 14
	sizeLimit.MinTextSize = 7
	sizeLimit.Parent = name

	return {
		Button = button,
		Stroke = stroke,
		Icon = icon,
		Name = name,
		Key = key,
	}
end

for index = 1, Config.MaxSlots do
	slotUIs[index] = createSlot(index)
end

---------------------------------------------------------------------------
-- Estado: quais ferramentas estão em quais espaços
---------------------------------------------------------------------------

local slots: { [number]: Tool? } = {}
local character: Model? = nil
local backpack: Backpack? = nil

local function isOwned(tool: Tool): boolean
	return tool.Parent ~= nil and (tool.Parent == backpack or tool.Parent == character)
end

local function render()
	for index, ui in slotUIs do
		local tool = slots[index]

		if not tool then
			ui.Button.Visible = Config.ShowEmptySlots
			ui.Icon.Image = ""
			ui.Name.Text = ""
			ui.Stroke.Transparency = 1
			ui.Button.BackgroundColor3 = Colors.Slot
			ui.Key.TextColor3 = Colors.TextMuted
			continue
		end

		local equipped = character ~= nil and tool.Parent == character
		local hasIcon = tool.TextureId ~= ""

		ui.Button.Visible = true
		ui.Icon.Image = tool.TextureId
		ui.Icon.Visible = hasIcon
		ui.Name.Text = tool.Name

		if hasIcon then
			-- Nome pequeno embaixo do ícone
			ui.Name.Position = UDim2.new(0, 4, 1, -16)
			ui.Name.Size = UDim2.new(1, -8, 0, 13)
		else
			-- Sem ícone: nome grande no meio
			ui.Name.Position = UDim2.fromOffset(4, 16)
			ui.Name.Size = UDim2.new(1, -8, 1, -20)
		end

		ui.Stroke.Transparency = if equipped then 0 else 1
		ui.Button.BackgroundColor3 = if equipped then Colors.SlotEquipped else Colors.Slot
		ui.Name.TextColor3 = if equipped then Colors.Accent else Colors.Text
		ui.Key.TextColor3 = if equipped then Colors.Accent else Colors.TextMuted
	end
end

local function findSlot(tool: Tool): number?
	for index = 1, Config.MaxSlots do
		if slots[index] == tool then
			return index
		end
	end
	return nil
end

local function addTool(tool: Tool)
	if not findSlot(tool) then
		for index = 1, Config.MaxSlots do
			if slots[index] == nil then
				slots[index] = tool
				break
			end
		end
	end
	render()
end

local function onToolLeft(tool: Tool)
	-- Ao equipar, a ferramenta sai da mochila e vai para o personagem.
	-- Espera um instante para saber se ela foi embora de verdade.
	task.defer(function()
		if not isOwned(tool) then
			local index = findSlot(tool)
			if index then
				slots[index] = nil
			end
		end
		render()
	end)
end

local function watchContainer(container: Instance, connections: { RBXScriptConnection })
	for _, child in container:GetChildren() do
		if child:IsA("Tool") then
			addTool(child)
		end
	end
	table.insert(
		connections,
		container.ChildAdded:Connect(function(child)
			if child:IsA("Tool") then
				addTool(child)
			end
		end)
	)
	table.insert(
		connections,
		container.ChildRemoved:Connect(function(child)
			if child:IsA("Tool") then
				onToolLeft(child)
			end
		end)
	)
end

local backpackConnections: { RBXScriptConnection } = {}
local characterConnections: { RBXScriptConnection } = {}

local function disconnectAll(connections: { RBXScriptConnection })
	for _, connection in connections do
		connection:Disconnect()
	end
	table.clear(connections)
end

local function bindBackpack(newBackpack: Backpack)
	disconnectAll(backpackConnections)
	table.clear(slots) -- mochila nova (respawn): começa do zero
	backpack = newBackpack
	watchContainer(newBackpack, backpackConnections)
	render()
end

local function bindCharacter(newCharacter: Model)
	disconnectAll(characterConnections)
	character = newCharacter
	watchContainer(newCharacter, characterConnections)
	render()
end

player.ChildAdded:Connect(function(child)
	if child:IsA("Backpack") then
		bindBackpack(child)
	end
end)
local existingBackpack = player:FindFirstChildOfClass("Backpack")
if existingBackpack then
	bindBackpack(existingBackpack)
end

player.CharacterAdded:Connect(bindCharacter)
if player.Character then
	bindCharacter(player.Character)
end

---------------------------------------------------------------------------
-- Equipar
---------------------------------------------------------------------------

local function toggleSlot(index: number)
	local tool = slots[index]
	local humanoid = character and character:FindFirstChildOfClass("Humanoid")
	if not tool or not humanoid or humanoid.Health <= 0 then
		return
	end

	if tool.Parent == character then
		humanoid:UnequipTools()
	else
		humanoid:EquipTool(tool)
	end
end

local keyToSlot: { [Enum.KeyCode]: number } = {}
for index, keyCode in Config.Keys do
	if index <= Config.MaxSlots then
		keyToSlot[keyCode] = index
	end
end

UserInputService.InputBegan:Connect(function(input, gameProcessed)
	-- gameProcessed = true quando o jogador está digitando no chat, etc.
	if gameProcessed then
		return
	end
	local index = keyToSlot[input.KeyCode]
	if index then
		toggleSlot(index)
	end
end)

for index, ui in slotUIs do
	ui.Button.Activated:Connect(function()
		toggleSlot(index)
	end)
end
