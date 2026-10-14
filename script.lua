-- ===== ARQUIVO: Config (ModuleScript em ReplicatedStorage > DebugTools) =====
--!strict
return table.freeze({
	REMOTE_NAME = "DebugToolsEvent",
	AUTH_ATTR = "DbgAuthorized",
	ATTR_PREFIX = "Dbg_",

	Features = table.freeze({ "Fly", "Speed", "Noclip", "InfiniteJump" }),

	Limits = table.freeze({
		Speed = table.freeze({ Min = 0, Max = 120, Default = 40 }),
		Fly = table.freeze({ Min = 0, Max = 200, Default = 60 }),
	}),
})

-- ===== ARQUIVO: DebugToolsServer (Script em ServerScriptService) =====
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Config = require(ReplicatedStorage:WaitForChild("DebugTools"):WaitForChild("Config"))

local ADMIN_USER_IDS: { [number]: boolean } = {
	-- [123456789] = true,
}

local MIN_REQUEST_INTERVAL = 0.05

local remote = Instance.new("RemoteEvent")
remote.Name = Config.REMOTE_NAME
remote.Parent = ReplicatedStorage

local validFeatures: { [string]: boolean } = {}
for _, feature in Config.Features do
	validFeatures[feature] = true
end

local lastRequest: { [Player]: number } = {}

local function isAuthorized(player: Player): boolean
	if RunService:IsStudio() then
		return true
	end
	if game.CreatorType == Enum.CreatorType.User and player.UserId == game.CreatorId then
		return true
	end
	return ADMIN_USER_IDS[player.UserId] == true
end

local function onPlayerAdded(player: Player)
	if isAuthorized(player) then
		player:SetAttribute(Config.AUTH_ATTR, true)
	end
end

remote.OnServerEvent:Connect(function(player, action, key, value)
	if not isAuthorized(player) then
		return
	end

	local now = os.clock()
	if now - (lastRequest[player] or 0) < MIN_REQUEST_INTERVAL then
		return
	end
	lastRequest[player] = now

	if type(action) ~= "string" or type(key) ~= "string" then
		return
	end

	if action == "Toggle" then
		if validFeatures[key] and type(value) == "boolean" then
			player:SetAttribute(Config.ATTR_PREFIX .. key, value)
		end
	elseif action == "SetValue" then
		local limits = Config.Limits[key]
		if limits and type(value) == "number" and value == value then
			player:SetAttribute(Config.ATTR_PREFIX .. key .. "Value", math.clamp(value, limits.Min, limits.Max))
		end
	end
end)

Players.PlayerAdded:Connect(onPlayerAdded)
for _, player in Players:GetPlayers() do
	onPlayerAdded(player)
end

Players.PlayerRemoving:Connect(function(player)
	lastRequest[player] = nil
end)

-- ===== ARQUIVO: DebugToolsClient (LocalScript em StarterPlayerScripts) =====
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")

local player = Players.LocalPlayer

local DebugTools = ReplicatedStorage:WaitForChild("DebugTools")
local Config = require(DebugTools:WaitForChild("Config"))
local remote = ReplicatedStorage:WaitForChild(Config.REMOTE_NAME) :: RemoteEvent

local HUD = require(script:WaitForChild("HUD"))
local Movement = require(script:WaitForChild("Movement"))

if player:GetAttribute(Config.AUTH_ATTR) ~= true then
	player:GetAttributeChangedSignal(Config.AUTH_ATTR):Wait()
	if player:GetAttribute(Config.AUTH_ATTR) ~= true then
		return
	end
end

local prefix = Config.ATTR_PREFIX

local movement = Movement.new({
	Speed = Config.Limits.Speed.Default,
	Fly = Config.Limits.Fly.Default,
})

local hud = HUD.new(Config, {
	onToggle = function(feature: string, state: boolean)
		remote:FireServer("Toggle", feature, state)
	end,
	onValue = function(key: string, value: number)
		remote:FireServer("SetValue", key, value)
	end,
})

local function applyFeature(feature: string)
	local on = player:GetAttribute(prefix .. feature) == true
	movement:SetEnabled(feature, on)
	hud:SetToggle(feature, on)
end

local function applyValue(key: string)
	local value = player:GetAttribute(prefix .. key .. "Value")
	if type(value) ~= "number" then
		value = Config.Limits[key].Default
	end
	movement:SetValue(key, value)
	hud:SetValue(key, value)
end

for _, feature in Config.Features do
	player:GetAttributeChangedSignal(prefix .. feature):Connect(function()
		applyFeature(feature)
	end)
	applyFeature(feature)
end

for key in Config.Limits do
	player:GetAttributeChangedSignal(prefix .. key .. "Value"):Connect(function()
		applyValue(key)
	end)
	applyValue(key)
end

if player.Character then
	task.spawn(movement.Bind, movement, player.Character)
end
player.CharacterAdded:Connect(function(character)
	movement:Bind(character)
end)

UserInputService.InputBegan:Connect(function(input, gameProcessed)
	if not gameProcessed and input.KeyCode == Enum.KeyCode.F4 then
		hud:ToggleVisible()
	end
end)

-- ===== ARQUIVO: HUD (ModuleScript, filho de DebugToolsClient) =====
local Players = game:GetService("Players")

local HUD = {}
HUD.__index = HUD

local COLORS = {
	Panel = Color3.fromRGB(32, 34, 38),
	Row = Color3.fromRGB(44, 47, 53),
	Stroke = Color3.fromRGB(66, 70, 78),
	Text = Color3.fromRGB(228, 230, 234),
	Muted = Color3.fromRGB(145, 150, 159),
	On = Color3.fromRGB(64, 160, 110),
	Off = Color3.fromRGB(78, 82, 90),
}

local FEATURE_LABELS = {
	Fly = "Voo",
	Speed = "Super-velocidade",
	Noclip = "Modo espectador",
	InfiniteJump = "Pulo repetitivo",
}

local VALUE_LABELS = {
	Fly = "Força de voo",
	Speed = "Velocidade extra",
}

local function formatNumber(n: number): string
	return string.format("%g", n)
end

local function addCorner(instance: Instance, radius: number)
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, radius)
	corner.Parent = instance
end

local function addStroke(instance: Instance)
	local stroke = Instance.new("UIStroke")
	stroke.Color = COLORS.Stroke
	stroke.Thickness = 1
	stroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
	stroke.Parent = instance
end

local function newLabel(parent: Instance, text: string, font: Enum.Font, size: number, color: Color3, order: number)
	local label = Instance.new("TextLabel")
	label.BackgroundTransparency = 1
	label.Size = UDim2.new(1, 0, 0, size + 6)
	label.Font = font
	label.Text = text
	label.TextSize = size
	label.TextColor3 = color
	label.TextXAlignment = Enum.TextXAlignment.Left
	label.LayoutOrder = order
	label.Parent = parent
	return label
end

local function newRow(parent: Instance, order: number, text: string): Frame
	local row = Instance.new("Frame")
	row.Size = UDim2.new(1, 0, 0, 36)
	row.BackgroundColor3 = COLORS.Row
	row.BorderSizePixel = 0
	row.LayoutOrder = order
	row.Parent = parent
	addCorner(row, 6)

	local padding = Instance.new("UIPadding")
	padding.PaddingLeft = UDim.new(0, 10)
	padding.PaddingRight = UDim.new(0, 5)
	padding.Parent = row

	local label = Instance.new("TextLabel")
	label.BackgroundTransparency = 1
	label.Size = UDim2.new(1, -80, 1, 0)
	label.Font = Enum.Font.Gotham
	label.Text = text
	label.TextSize = 13
	label.TextColor3 = COLORS.Text
	label.TextXAlignment = Enum.TextXAlignment.Left
	label.Parent = row

	return row
end

function HUD.new(config, callbacks)
	local self = setmetatable({}, HUD)
	self._values = {}
	self._toggles = {}

	local gui = Instance.new("ScreenGui")
	gui.Name = "DebugToolsHUD"
	gui.ResetOnSpawn = false
	gui.DisplayOrder = 100
	gui.Parent = Players.LocalPlayer:WaitForChild("PlayerGui")
	self._gui = gui

	local panel = Instance.new("Frame")
	panel.Name = "Panel"
	panel.AnchorPoint = Vector2.new(0, 0.5)
	panel.Position = UDim2.new(0, 16, 0.5, 0)
	panel.Size = UDim2.fromOffset(264, 0)
	panel.AutomaticSize = Enum.AutomaticSize.Y
	panel.BackgroundColor3 = COLORS.Panel
	panel.BorderSizePixel = 0
	panel.Parent = gui
	addCorner(panel, 10)
	addStroke(panel)

	local padding = Instance.new("UIPadding")
	padding.PaddingTop = UDim.new(0, 12)
	padding.PaddingBottom = UDim.new(0, 12)
	padding.PaddingLeft = UDim.new(0, 12)
	padding.PaddingRight = UDim.new(0, 12)
	padding.Parent = panel

	local layout = Instance.new("UIListLayout")
	layout.Padding = UDim.new(0, 6)
	layout.SortOrder = Enum.SortOrder.LayoutOrder
	layout.Parent = panel

	newLabel(panel, "CONTROLE DE MOVIMENTO", Enum.Font.GothamBold, 14, COLORS.Text, 1)
	newLabel(panel, "Ferramentas de teste", Enum.Font.Gotham, 11, COLORS.Muted, 2)
	newLabel(panel, "PARÂMETROS", Enum.Font.GothamBold, 11, COLORS.Muted, 3)

	for i, key in { "Fly", "Speed" } do
		local limits = config.Limits[key]
		local row = newRow(panel, 3 + i, VALUE_LABELS[key])

		local box = Instance.new("TextBox")
		box.AnchorPoint = Vector2.new(1, 0.5)
		box.Position = UDim2.new(1, 0, 0.5, 0)
		box.Size = UDim2.fromOffset(64, 26)
		box.BackgroundColor3 = COLORS.Panel
		box.BorderSizePixel = 0
		box.Font = Enum.Font.Gotham
		box.TextSize = 13
		box.TextColor3 = COLORS.Text
		box.ClearTextOnFocus = false
		box.Text = formatNumber(limits.Default)
		box.Parent = row
		addCorner(box, 5)
		addStroke(box)

		self._values[key] = { value = limits.Default, box = box }

		box.FocusLost:Connect(function()
			local entry = self._values[key]
			local number = tonumber(box.Text)
			if number == nil or number ~= number then
				box.Text = formatNumber(entry.value)
				return
			end
			number = math.clamp(number, limits.Min, limits.Max)
			entry.value = number
			box.Text = formatNumber(number)
			callbacks.onValue(key, number)
		end)
	end

	newLabel(panel, "MÓDULOS", Enum.Font.GothamBold, 11, COLORS.Muted, 6)

	for i, feature in config.Features do
		local row = newRow(panel, 6 + i, FEATURE_LABELS[feature])

		local button = Instance.new("TextButton")
		button.AnchorPoint = Vector2.new(1, 0.5)
		button.Position = UDim2.new(1, 0, 0.5, 0)
		button.Size = UDim2.fromOffset(56, 26)
		button.AutoButtonColor = false
		button.BorderSizePixel = 0
		button.Font = Enum.Font.GothamBold
		button.TextSize = 12
		button.TextColor3 = COLORS.Text
		button.Parent = row
		addCorner(button, 5)

		self._toggles[feature] = { button = button, state = false }
		self:SetToggle(feature, false)

		button.Activated:Connect(function()
			callbacks.onToggle(feature, not self._toggles[feature].state)
		end)
	end

	local hint = newLabel(panel, "Voo: WASD + Espaço (sobe) / Ctrl (desce)\nF4 oculta o painel", Enum.Font.Gotham, 11, COLORS.Muted, 20)
	hint.TextWrapped = true
	hint.AutomaticSize = Enum.AutomaticSize.Y
	hint.Size = UDim2.new(1, 0, 0, 0)

	return self
end

function HUD:SetToggle(feature: string, state: boolean)
	local entry = self._toggles[feature]
	if not entry then
		return
	end
	entry.state = state
	entry.button.Text = state and "ON" or "OFF"
	entry.button.BackgroundColor3 = state and COLORS.On or COLORS.Off
end

function HUD:SetValue(key: string, value: number)
	local entry = self._values[key]
	if not entry then
		return
	end
	entry.value = value
	entry.box.Text = formatNumber(value)
end

function HUD:ToggleVisible()
	self._gui.Enabled = not self._gui.Enabled
end

function HUD:Destroy()
	self._gui:Destroy()
end

return HUD

-- ===== ARQUIVO: Movement (ModuleScript, filho de DebugToolsClient) =====
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")

local Movement = {}
Movement.__index = Movement

local FLY_SMOOTHING = 8
local SLIDE_SMOOTHING = 10

function Movement.new(defaults: { Speed: number, Fly: number })
	local self = setmetatable({}, Movement)

	self.enabled = { Fly = false, Speed = false, Noclip = false, InfiniteJump = false }
	self.values = { Speed = defaults.Speed, Fly = defaults.Fly }

	self.character = nil :: Model?
	self.humanoid = nil :: Humanoid?
	self.root = nil :: BasePart?

	self._flyObjects = nil :: { attachment: Attachment, velocity: LinearVelocity, align: AlignOrientation }?
	self._flyVelocity = Vector3.zero
	self._slide = Vector3.zero
	self._prevAutoRotate = true
	self._originalCollide = {} :: { [BasePart]: boolean }
	self._connections = {} :: { RBXScriptConnection }

	self._jumpConnection = UserInputService.JumpRequest:Connect(function()
		local humanoid = self.humanoid
		if self.enabled.InfiniteJump and humanoid and humanoid.Health > 0 then
			humanoid:ChangeState(Enum.HumanoidStateType.Jumping)
		end
	end)

	return self
end

function Movement:Bind(character: Model)
	self:_unbindCharacter()

	local humanoid = character:WaitForChild("Humanoid") :: Humanoid
	local root = character:WaitForChild("HumanoidRootPart") :: BasePart
	self.character, self.humanoid, self.root = character, humanoid, root

	table.insert(
		self._connections,
		RunService.Heartbeat:Connect(function(dt)
			self:_step(dt)
		end)
	)
	table.insert(
		self._connections,
		RunService.Stepped:Connect(function()
			self:_applyNoclip()
		end)
	)

	if self.enabled.Fly then
		self:_startFlight()
	end
end

function Movement:SetEnabled(feature: string, on: boolean)
	if self.enabled[feature] == nil or self.enabled[feature] == on then
		return
	end
	self.enabled[feature] = on

	if feature == "Fly" then
		if on then
			self:_startFlight()
		else
			self:_stopFlight()
		end
	elseif feature == "Noclip" and not on then
		self:_restoreCollisions()
	end
end

function Movement:SetValue(key: string, value: number)
	if self.values[key] ~= nil then
		self.values[key] = value
	end
end

function Movement:Destroy()
	self._jumpConnection:Disconnect()
	self:_unbindCharacter()
end

function Movement:_unbindCharacter()
	for _, connection in self._connections do
		connection:Disconnect()
	end
	table.clear(self._connections)

	self:_stopFlight()
	table.clear(self._originalCollide)
	self._slide = Vector3.zero
	self.character, self.humanoid, self.root = nil, nil, nil
end

function Movement:_step(dt: number)
	local humanoid, root = self.humanoid, self.root
	if not humanoid or not root or humanoid.Health <= 0 or not root.Parent then
		return
	end

	if self._flyObjects then
		self:_stepFlight(dt, humanoid)
	else
		self:_stepSlide(dt, humanoid, root)
	end
end

function Movement:_stepSlide(dt: number, humanoid: Humanoid, root: BasePart)
	local target = Vector3.zero
	if self.enabled.Speed then
		target = humanoid.MoveDirection * self.values.Speed
	end

	local alpha = 1 - math.exp(-SLIDE_SMOOTHING * dt)
	self._slide = self._slide:Lerp(target, alpha)

	if self._slide.Magnitude > 0.01 then
		root.CFrame += self._slide * dt
	end
end

function Movement:_readFlightInput(camera: Camera, humanoid: Humanoid): Vector3
	if UserInputService:GetFocusedTextBox() then
		return Vector3.zero
	end

	local cf = camera.CFrame
	local v = Vector3.zero
	if UserInputService:IsKeyDown(Enum.KeyCode.W) then
		v += cf.LookVector
	end
	if UserInputService:IsKeyDown(Enum.KeyCode.S) then
		v -= cf.LookVector
	end
	if UserInputService:IsKeyDown(Enum.KeyCode.D) then
		v += cf.RightVector
	end
	if UserInputService:IsKeyDown(Enum.KeyCode.A) then
		v -= cf.RightVector
	end
	if UserInputService:IsKeyDown(Enum.KeyCode.Space) then
		v += Vector3.yAxis
	end
	if UserInputService:IsKeyDown(Enum.KeyCode.LeftControl) then
		v -= Vector3.yAxis
	end

	if v.Magnitude < 1e-4 and humanoid.MoveDirection.Magnitude > 0 then
		v = humanoid.MoveDirection
	end
	return v
end

function Movement:_startFlight()
	local humanoid, root = self.humanoid, self.root
	if self._flyObjects or not humanoid or not root then
		return
	end

	local attachment = Instance.new("Attachment")
	attachment.Name = "DbgFlyAttachment"
	attachment.Parent = root

	local velocity = Instance.new("LinearVelocity")
	velocity.Name = "DbgFlyVelocity"
	velocity.Attachment0 = attachment
	velocity.RelativeTo = Enum.ActuatorRelativeTo.World
	velocity.VelocityConstraintMode = Enum.VelocityConstraintMode.Vector
	velocity.MaxForce = math.huge
	velocity.VectorVelocity = Vector3.zero
	velocity.Parent = root

	local align = Instance.new("AlignOrientation")
	align.Name = "DbgFlyAlign"
	align.Mode = Enum.OrientationAlignmentMode.OneAttachment
	align.Attachment0 = attachment
	align.RigidityEnabled = false
	align.MaxTorque = math.huge
	align.Responsiveness = 25
	align.CFrame = root.CFrame.Rotation
	align.Parent = root

	self._flyObjects = { attachment = attachment, velocity = velocity, align = align }
	self._flyVelocity = Vector3.zero

	self._prevAutoRotate = humanoid.AutoRotate
	humanoid.AutoRotate = false
	humanoid:SetStateEnabled(Enum.HumanoidStateType.Freefall, false)
	humanoid:SetStateEnabled(Enum.HumanoidStateType.FallingDown, false)
	humanoid:ChangeState(Enum.HumanoidStateType.Running)
end

function Movement:_stepFlight(dt: number, humanoid: Humanoid)
	local objects = self._flyObjects
	local camera = workspace.CurrentCamera
	if not objects or not camera then
		return
	end

	local input = self:_readFlightInput(camera, humanoid)
	local target = Vector3.zero
	if input.Magnitude > 1e-4 then
		target = input.Unit * self.values.Fly
	end

	local alpha = 1 - math.exp(-FLY_SMOOTHING * dt)
	self._flyVelocity = self._flyVelocity:Lerp(target, alpha)
	objects.velocity.VectorVelocity = self._flyVelocity

	local look = camera.CFrame.LookVector
	local flat = Vector3.new(look.X, 0, look.Z)
	if flat.Magnitude > 0.01 then
		objects.align.CFrame = CFrame.lookAt(Vector3.zero, flat)
	end

	if humanoid:GetState() ~= Enum.HumanoidStateType.Running then
		humanoid:ChangeState(Enum.HumanoidStateType.Running)
	end
end

function Movement:_stopFlight()
	local objects = self._flyObjects
	if not objects then
		return
	end
	self._flyObjects = nil
	self._flyVelocity = Vector3.zero

	objects.velocity:Destroy()
	objects.align:Destroy()
	objects.attachment:Destroy()

	local humanoid = self.humanoid
	if humanoid and humanoid.Parent then
		humanoid.AutoRotate = self._prevAutoRotate
		humanoid:SetStateEnabled(Enum.HumanoidStateType.Freefall, true)
		humanoid:SetStateEnabled(Enum.HumanoidStateType.FallingDown, true)
		humanoid:ChangeState(Enum.HumanoidStateType.Freefall)
	end
end

function Movement:_applyNoclip()
	local character = self.character
	if not self.enabled.Noclip or not character then
		return
	end
	for _, part in character:GetDescendants() do
		if part:IsA("BasePart") then
			if self._originalCollide[part] == nil then
				self._originalCollide[part] = part.CanCollide
			end
			part.CanCollide = false
		end
	end
end

function Movement:_restoreCollisions()
	for part, original in self._originalCollide do
		if part.Parent then
			part.CanCollide = original
		end
	end
	table.clear(self._originalCollide)
end

return Movement
