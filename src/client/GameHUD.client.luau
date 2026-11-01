--[[
	HUD geral do jogo:
	- Avisos no topo da tela (eventos, recompensas, missões)
	- Contador do evento de servidor que está acontecendo
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")

local player = Players.LocalPlayer
local AnnounceRemote = ReplicatedStorage:WaitForChild("GameRemotes"):WaitForChild("Announce")

local DARK = Color3.fromRGB(14, 14, 18)
local KIND_COLORS = {
	Event = Color3.fromRGB(255, 196, 0),
	Bounty = Color3.fromRGB(255, 70, 60),
	Mission = Color3.fromRGB(80, 220, 120),
	Achievement = Color3.fromRGB(190, 120, 255),
	Daily = Color3.fromRGB(255, 196, 0),
}
local DEFAULT_COLOR = Color3.fromRGB(235, 235, 235)
local MAX_TOASTS = 4
local TOAST_SECONDS = 5

local gui = Instance.new("ScreenGui")
gui.Name = "GameHUD"
gui.ResetOnSpawn = false
gui.DisplayOrder = 8
gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
gui.Parent = player:WaitForChild("PlayerGui")

---------------------------------------------------------------------------
-- Contador do evento
---------------------------------------------------------------------------

local eventPill = Instance.new("Frame")
eventPill.Name = "Event"
eventPill.AnchorPoint = Vector2.new(0.5, 0)
eventPill.Position = UDim2.new(0.5, 0, 0, 8)
eventPill.Size = UDim2.fromOffset(0, 32)
eventPill.AutomaticSize = Enum.AutomaticSize.X
eventPill.BackgroundColor3 = DARK
eventPill.BackgroundTransparency = 0.15
eventPill.Visible = false
eventPill.Parent = gui

local pillCorner = Instance.new("UICorner")
pillCorner.CornerRadius = UDim.new(1, 0)
pillCorner.Parent = eventPill

local pillStroke = Instance.new("UIStroke")
pillStroke.Color = KIND_COLORS.Event
pillStroke.Thickness = 2
pillStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
pillStroke.Parent = eventPill

local pillPadding = Instance.new("UIPadding")
pillPadding.PaddingLeft = UDim.new(0, 16)
pillPadding.PaddingRight = UDim.new(0, 16)
pillPadding.Parent = eventPill

local eventLabel = Instance.new("TextLabel")
eventLabel.BackgroundTransparency = 1
eventLabel.Size = UDim2.fromScale(0, 1)
eventLabel.AutomaticSize = Enum.AutomaticSize.X
eventLabel.Font = Enum.Font.GothamBold
eventLabel.TextSize = 15
eventLabel.TextColor3 = KIND_COLORS.Event
eventLabel.Text = ""
eventLabel.Parent = eventPill

local function formatTime(seconds: number): string
	seconds = math.max(0, math.floor(seconds))
	return string.format("%d:%02d", seconds // 60, seconds % 60)
end

RunService.Heartbeat:Connect(function()
	local name = ReplicatedStorage:GetAttribute("EventName")
	local endsAt = ReplicatedStorage:GetAttribute("EventEndsAt")
	if type(name) == "string" and type(endsAt) == "number" then
		eventPill.Visible = true
		eventLabel.Text = `⚡ {name}   {formatTime(endsAt - workspace:GetServerTimeNow())}`
	else
		eventPill.Visible = false
	end
end)

---------------------------------------------------------------------------
-- Avisos
---------------------------------------------------------------------------

local toastList = Instance.new("Frame")
toastList.Name = "Announcements"
toastList.AnchorPoint = Vector2.new(0.5, 0)
toastList.Position = UDim2.new(0.5, 0, 0, 48)
toastList.Size = UDim2.new(0.9, 0, 0, 200)
toastList.BackgroundTransparency = 1
toastList.Parent = gui

local toastLayout = Instance.new("UIListLayout")
toastLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
toastLayout.SortOrder = Enum.SortOrder.LayoutOrder
toastLayout.Padding = UDim.new(0, 6)
toastLayout.Parent = toastList

local toastOrder = 0

local function showToast(text: string, kind: string?)
	toastOrder += 1
	local color = (kind and KIND_COLORS[kind]) or DEFAULT_COLOR

	-- Remove os mais antigos se tiver aviso demais.
	local existing = {}
	for _, child in toastList:GetChildren() do
		if child:IsA("Frame") then
			table.insert(existing, child)
		end
	end
	table.sort(existing, function(a, b)
		return a.LayoutOrder < b.LayoutOrder
	end)
	for index = 1, #existing - MAX_TOASTS + 1 do
		existing[index]:Destroy()
	end

	local toast = Instance.new("Frame")
	toast.LayoutOrder = toastOrder
	toast.Size = UDim2.fromOffset(0, 34)
	toast.AutomaticSize = Enum.AutomaticSize.X
	toast.BackgroundColor3 = DARK
	toast.BackgroundTransparency = 0.15
	toast.Parent = toastList

	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 8)
	corner.Parent = toast

	local stroke = Instance.new("UIStroke")
	stroke.Color = color
	stroke.Thickness = 1.5
	stroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
	stroke.Parent = toast

	local padding = Instance.new("UIPadding")
	padding.PaddingLeft = UDim.new(0, 14)
	padding.PaddingRight = UDim.new(0, 14)
	padding.Parent = toast

	local label = Instance.new("TextLabel")
	label.BackgroundTransparency = 1
	label.Size = UDim2.fromScale(0, 1)
	label.AutomaticSize = Enum.AutomaticSize.X
	label.Font = Enum.Font.GothamBold
	label.TextSize = 15
	label.TextColor3 = color
	label.Text = text
	label.Parent = toast

	task.delay(TOAST_SECONDS, function()
		if not toast.Parent then
			return
		end
		local tweenInfo = TweenInfo.new(0.4)
		TweenService:Create(toast, tweenInfo, { BackgroundTransparency = 1 }):Play()
		TweenService:Create(stroke, tweenInfo, { Transparency = 1 }):Play()
		local fade = TweenService:Create(label, tweenInfo, { TextTransparency = 1 })
		fade:Play()
		fade.Completed:Wait()
		toast:Destroy()
	end)
end

AnnounceRemote.OnClientEvent:Connect(showToast)
