--[[
	Modo treino: quem entra num servidor vazio treina com bonecos até o
	tempo acabar ou outro jogador entrar.

	Estado para o HUD (atributos do Player):
	  TrainingEndsAt  -> horário do servidor em que o treino acaba (nil = fora do treino)
	  TrainingKills   -> bonecos abatidos
	  TrainingEnding  -> true nos segundos de "Indo para o modo principal"
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService("ServerStorage")

local Config = require(ReplicatedStorage:WaitForChild("Training"):WaitForChild("Config"))
local Announcer = require(script.Parent.Announcer)

local Training = {}

type Session = {
	Player: Player,
	Folder: Folder,
	Spots: { CFrame },
	Generation: number, -- muda quando os bonecos são recriados em outro lugar
	Active: boolean,
	GivenWeapon: Tool?,
	Connections: { RBXScriptConnection },
}

local sessions: { [Player]: Session } = {}
local started = false

---------------------------------------------------------------------------
-- Área de treino
---------------------------------------------------------------------------

local function getArea(): Instance?
	return workspace:FindFirstChild(Config.AreaFolderName)
end

local function getSpawnCFrame(): CFrame?
	local area = getArea()
	local spawnPart = area and area:FindFirstChild("Spawn")
	if spawnPart and spawnPart:IsA("BasePart") then
		return spawnPart.CFrame
	end
	return nil
end

-- Lugares dos bonecos: as Parts "Alvo" da pasta, ou um arco na frente do jogador.
local function getSpots(character: Model): { CFrame }
	local spots = {}
	local area = getArea()
	if area then
		for _, child in area:GetChildren() do
			if child.Name == "Alvo" and child:IsA("BasePart") then
				table.insert(spots, child.CFrame)
			end
		end
	end
	if #spots > 0 then
		return spots
	end

	local root = character:FindFirstChild("HumanoidRootPart")
	if not root or not root:IsA("BasePart") then
		return spots
	end

	local count = Config.Dummies.Count
	for index = 1, count do
		local angle = math.rad(-50 + (100 / math.max(count - 1, 1)) * (index - 1))
		local distance = 25 + (index % 3) * 8
		local offset = CFrame.Angles(0, angle, 0) * Vector3.new(0, 0, -distance)
		local position = root.CFrame:PointToWorldSpace(offset)

		-- Procura o chão embaixo do ponto.
		local params = RaycastParams.new()
		params.FilterDescendantsInstances = { character }
		local hit = workspace:Raycast(position + Vector3.new(0, 30, 0), Vector3.new(0, -80, 0), params)
		local ground = if hit then hit.Position else position

		table.insert(spots, CFrame.lookAt(ground, Vector3.new(root.Position.X, ground.Y, root.Position.Z)))
	end
	return spots
end

---------------------------------------------------------------------------
-- Bonecos
---------------------------------------------------------------------------

local function createDummy(session: Session, spot: CFrame, generation: number)
	if not session.Active or session.Generation ~= generation then
		return
	end

	local description = Instance.new("HumanoidDescription")
	local color = Config.Dummies.Color
	description.HeadColor = color
	description.TorsoColor = color
	description.LeftArmColor = color
	description.RightArmColor = color
	description.LeftLegColor = color
	description.RightLegColor = color

	local ok, model = pcall(function()
		return Players:CreateHumanoidModelFromDescription(description, Enum.HumanoidRigType.R6)
	end)
	if not ok or not model then
		warn("[Training] Não consegui criar o boneco:", model)
		return
	end

	model.Name = Config.Dummies.Name
	local humanoid = model:FindFirstChildOfClass("Humanoid") :: Humanoid
	humanoid.DisplayName = Config.Dummies.Name
	humanoid.MaxHealth = Config.Dummies.Health
	humanoid.Health = Config.Dummies.Health
	humanoid.WalkSpeed = Config.Dummies.WalkSpeed

	model:PivotTo(spot + Vector3.new(0, 3, 0))
	model.Parent = session.Folder

	-- Conta o abate se foi o jogador do treino.
	humanoid.Died:Once(function()
		local tag = humanoid:FindFirstChild("creator")
		if tag and tag:IsA("ObjectValue") and tag.Value == session.Player then
			session.Player:SetAttribute("TrainingKills", (session.Player:GetAttribute("TrainingKills") or 0) + 1)
		end
		task.delay(1.5, function()
			model:Destroy()
		end)
		task.delay(Config.Dummies.RespawnDelay, createDummy, session, spot, generation)
	end)

	-- Anda um pouco perto do lugar dele.
	if Config.Dummies.Moving then
		task.spawn(function()
			local random = Random.new()
			while session.Active and model.Parent and humanoid.Health > 0 do
				local radius = Config.Dummies.MoveRadius
				local target = spot.Position + Vector3.new(random:NextNumber(-radius, radius), 0, random:NextNumber(-radius, radius))
				humanoid:MoveTo(target)
				task.wait(random:NextNumber(1.5, 3.5))
			end
		end)
	end
end

local function spawnDummies(session: Session, character: Model)
	local root = character:FindFirstChild("HumanoidRootPart")

	if #session.Spots > 0 then
		-- Sem a pasta Treino, os bonecos ficam perto do jogador: se ele renasceu
		-- longe (ex.: escolheu o time), recria os bonecos perto dele.
		local far = root
			and root:IsA("BasePart")
			and (root.Position - session.Spots[1].Position).Magnitude > 120
		if getArea() or not far then
			return
		end
		session.Generation += 1
		session.Folder:ClearAllChildren()
	end

	session.Spots = getSpots(character)
	for _, spot in session.Spots do
		createDummy(session, spot, session.Generation)
	end

	-- Centro dos bonecos, para a câmera da intro olhar para lá.
	if #session.Spots > 0 then
		local sum = Vector3.zero
		for _, spot in session.Spots do
			sum += spot.Position
		end
		session.Player:SetAttribute("TrainingFocus", sum / #session.Spots)
	end
end

---------------------------------------------------------------------------
-- Arma do treino
---------------------------------------------------------------------------

local function hasAnyTool(player: Player): boolean
	local backpack = player:FindFirstChildOfClass("Backpack")
	local character = player.Character
	return (backpack ~= nil and backpack:FindFirstChildOfClass("Tool") ~= nil)
		or (character ~= nil and character:FindFirstChildOfClass("Tool") ~= nil)
end

local function giveTrainingWeapon(session: Session)
	local weaponName = Config.TrainingWeapon
	if not weaponName or hasAnyTool(session.Player) then
		return
	end
	local template = ServerStorage:FindFirstChild(weaponName, true)
	local backpack = session.Player:FindFirstChildOfClass("Backpack")
	if template and template:IsA("Tool") and backpack then
		local weapon = template:Clone()
		weapon.Parent = backpack
		session.GivenWeapon = weapon
	elseif not template then
		warn(`[Training] Arma "{weaponName}" não encontrada no ServerStorage.`)
	end
end

---------------------------------------------------------------------------
-- Sessão
---------------------------------------------------------------------------

local function onTrainingCharacter(session: Session, character: Model)
	if not session.Active then
		return
	end
	local root = character:WaitForChild("HumanoidRootPart", 10)
	if not root or not session.Active then
		return
	end

	-- Leva para a área de treino (se ela existir). Confere por alguns segundos,
	-- porque o Roblox ou outros scripts (spawn de time, renascer...) podem
	-- mover o personagem logo depois que ele nasce.
	local spawnCFrame = getSpawnCFrame()
	if spawnCFrame and root:IsA("BasePart") then
		local target = spawnCFrame + Vector3.new(0, 4, 0)
		character:PivotTo(target)
		task.spawn(function()
			for _ = 1, 15 do
				task.wait(0.2)
				if not session.Active or character.Parent == nil then
					break
				end
				if (root.Position - target.Position).Magnitude > 20 then
					character:PivotTo(target)
				end
			end
		end)
	end

	task.wait(0.5)
	spawnDummies(session, character)
	giveTrainingWeapon(session)
end

function Training.IsInTraining(player: Player): boolean
	local session = sessions[player]
	return session ~= nil and session.Active
end

-- Encerra o treino de um jogador. sendBack = renascer no spawn normal.
function Training.End(player: Player, reason: string?, sendBack: boolean?)
	local session = sessions[player]
	if not session or not session.Active then
		return
	end
	session.Active = false
	sessions[player] = nil

	for _, connection in session.Connections do
		connection:Disconnect()
	end
	session.Folder:Destroy()
	if session.GivenWeapon then
		session.GivenWeapon:Destroy()
	end

	if player.Parent ~= Players then
		return -- saiu do jogo
	end

	player:SetAttribute("TrainingEndsAt", nil)
	player:SetAttribute("TrainingFocus", nil)
	player:SetAttribute("TrainingSpawn", nil)
	player:SetAttribute("TrainingEnding", true)
	Announcer.To(player, `🎯 {reason or "Treino concluído!"} Indo para o modo principal...`, "Event")

	task.delay(Config.ReturnDelay, function()
		if player.Parent ~= Players then
			return
		end
		player:SetAttribute("TrainingEnding", nil)
		player:SetAttribute("TrainingKills", nil)
		if sendBack ~= false then
			player:LoadCharacter()
		end
	end)
end

function Training.Begin(player: Player)
	if sessions[player] then
		return
	end

	local folder = Instance.new("Folder")
	folder.Name = `Treino_{player.Name}`
	folder.Parent = workspace

	local session: Session = {
		Player = player,
		Folder = folder,
		Spots = {},
		Generation = 1,
		Active = true,
		GivenWeapon = nil,
		Connections = {},
	}
	sessions[player] = session

	player:SetAttribute("TrainingKills", 0)
	player:SetAttribute("TrainingEndsAt", workspace:GetServerTimeNow() + Config.Duration)
	-- O cliente também teleporta (ele controla a posição do próprio personagem).
	player:SetAttribute("TrainingSpawn", getSpawnCFrame())

	table.insert(
		session.Connections,
		player.CharacterAdded:Connect(function(character)
			onTrainingCharacter(session, character)
		end)
	)
	if player.Character then
		task.spawn(onTrainingCharacter, session, player.Character)
	end

	task.delay(Config.Duration, function()
		if sessions[player] == session then
			Training.End(player, "Treino concluído!")
		end
	end)
end

function Training.Start()
	if started then
		return
	end
	started = true

	if not Config.Enabled then
		return
	end

	local function onPlayerAdded(player: Player)
		local count = #Players:GetPlayers()

		-- Alguém entrou: quem estava treinando vai pro modo principal.
		if Config.EndWhenSomeoneJoins and count > Config.MaxPlayers then
			for other in sessions do
				if other ~= player then
					Training.End(other, "Um jogador entrou no servidor!")
				end
			end
		end

		if count <= Config.MaxPlayers then
			Training.Begin(player)
		end
	end

	Players.PlayerAdded:Connect(onPlayerAdded)
	for _, player in Players:GetPlayers() do
		task.spawn(onPlayerAdded, player)
	end

	Players.PlayerRemoving:Connect(function(player)
		Training.End(player, nil, false)
	end)
end

return Training
