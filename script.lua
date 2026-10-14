--[[
================================================================================
 UNIVERSAL MOVEMENT HUB  ·  v2.0.0  ·  Luau / Roblox
 Reescrito para compatibilidade máxima (Delta, Xeno, Solara, Wave, etc.)
================================================================================
]]

--================================================================================
-- [0] LOG DE INICIALIZAÇÃO
--================================================================================
local function log(msg)
	print("[UMH] " .. tostring(msg))
end

log("Iniciando Universal Movement Hub v2.0...")

--================================================================================
-- [1] SERVIÇOS (com proteção contra falha)
--================================================================================
local Players, RunService, UserInputService, TweenService, Lighting
local LocalPlayer

local ok, err = pcall(function()
	Players          = game:GetService("Players")
	RunService       = game:GetService("RunService")
	UserInputService = game:GetService("UserInputService")
	TweenService     = game:GetService("TweenService")
	Lighting         = game:GetService("Lighting")
	LocalPlayer      = Players.LocalPlayer
end)

if not ok then
	warn("[UMH] Falha ao obter serviços: " .. tostring(err))
	return
end

--================================================================================
-- [2] AMBIENTE GLOBAL (fallback seguro para executores sem getgenv)
--================================================================================
local ENV
if typeof(getgenv) == "function" then
	local ok2, g = pcall(getgenv)
	ENV = (ok2 and g) or _G
else
	ENV = _G
end

-- Limpa instância anterior
if ENV.UMH_Loaded then
	pcall(function() ENV.UMH_Loaded:Destroy() end)
	ENV.UMH_Loaded = nil
end

--================================================================================
-- [3] CONFIGURAÇÃO
--================================================================================
ENV.UMH_Config = ENV.UMH_Config or {
	Speed        = { Enabled = false, Value = 60,  Min = 16,  Max = 500 },
	Fly          = { Enabled = false, Value = 80,  Min = 10,  Max = 1000 },
	Noclip       = { Enabled = false },
	InfiniteJump = { Enabled = false },
}

local Config = ENV.UMH_Config

--================================================================================
-- [4] UTILITÁRIOS
--================================================================================
local Util = {}

function Util.New(class, props)
	local inst = Instance.new(class)
	local parent
	for k, v in pairs(props) do
		if k == "Parent" then parent = v else inst[k] = v end
	end
	if parent then inst.Parent = parent end
	return inst
end

function Util.GetUIParent()
	-- Tenta gethui primeiro (executor)
	if typeof(gethui) == "function" then
		local ok2, hui = pcall(gethui)
		if ok2 and hui then return hui end
	end
	-- Fallback: PlayerGui (funciona em todos)
	local pg = LocalPlayer:FindFirstChildOfClass("PlayerGui")
	if pg then return pg end
	return LocalPlayer:WaitForChild("PlayerGui", 10)
end

function Util.Tween(inst, props, time, style, dir)
	local info = TweenInfo.new(
		time or 0.22,
		style or Enum.EasingStyle.Quad,
		dir or Enum.EasingDirection.Out
	)
	local t = TweenService:Create(inst, info, props)
	t:Play()
	return t
end

function Util.GetChar()
	local char = LocalPlayer.Character
	if not char or not char.Parent then return nil end
	local hum = char:FindFirstChildOfClass("Humanoid")
	local hrp = char:FindFirstChild("HumanoidRootPart")
	if not hum or not hrp then return nil end
	if hum.Health <= 0 then return nil end
	return hum, hrp, char
end

--================================================================================
-- [5] TEMA
--================================================================================
local T = {
	Bg      = Color3.fromRGB(16, 18, 26),
	Surface = Color3.fromRGB(26, 29, 40),
	Field   = Color3.fromRGB(38, 42, 56),
	Accent  = Color3.fromRGB(0, 200, 255),
	Accent2 = Color3.fromRGB(150, 80, 255),
	Green   = Color3.fromRGB(0, 230, 150),
	Red     = Color3.fromRGB(255, 80, 100),
	Text    = Color3.fromRGB(235, 240, 250),
	Dim     = Color3.fromRGB(140, 148, 170),
	White   = Color3.fromRGB(255, 255, 255),
}

local FONT = Enum.Font.Gotham
local FONT_BOLD = Enum.Font.GothamBold

--================================================================================
-- [6] UI KIT
--================================================================================
local UI = {}

function UI.Section(parent, text, order)
	local f = Util.New("Frame", {
		BackgroundTransparency = 1,
		Size = UDim2.new(1, 0, 0, 24),
		LayoutOrder = order or 0,
		Parent = parent,
	})
	Util.New("TextLabel", {
		BackgroundTransparency = 1,
		Size = UDim2.new(1, 0, 1, 0),
		Font = FONT_BOLD,
		Text = string.upper(text),
		TextColor3 = T.Dim,
		TextSize = 11,
		TextXAlignment = Enum.TextXAlignment.Left,
		Parent = f,
	})
	return f
end

function UI.Toggle(parent, cfg)
	local text = cfg.Text or "Toggle"
	local cb = cfg.Callback or function() end
	local state = cfg.Default and true or false

	local holder = Util.New("Frame", {
		BackgroundTransparency = 1,
		Size = UDim2.new(1, 0, 0, 34),
		LayoutOrder = cfg.Order or 0,
		Parent = parent,
	})
	Util.New("TextLabel", {
		BackgroundTransparency = 1,
		Size = UDim2.new(1, -60, 1, 0),
		Font = FONT,
		Text = text,
		TextColor3 = T.Text,
		TextSize = 14,
		TextXAlignment = Enum.TextXAlignment.Left,
		Parent = holder,
	})
	local track = Util.New("Frame", {
		AnchorPoint = Vector2.new(1, 0.5),
		Position = UDim2.new(1, 0, 0.5, 0),
		Size = UDim2.new(0, 42, 0, 22),
		BackgroundColor3 = T.Field,
		BorderSizePixel = 0,
		Parent = holder,
	})
	Util.New("UICorner", { CornerRadius = UDim.new(1, 0), Parent = track })
	Util.New("UIStroke", {
		Color = T.White, Transparency = 0.85, Thickness = 1, Parent = track,
	})
	local knob = Util.New("Frame", {
		AnchorPoint = Vector2.new(0, 0.5),
		Position = UDim2.new(0, 3, 0.5, 0),
		Size = UDim2.new(0, 16, 0, 16),
		BackgroundColor3 = T.Dim,
		BorderSizePixel = 0,
		Parent = track,
	})
	Util.New("UICorner", { CornerRadius = UDim.new(1, 0), Parent = knob })

	local btn = Util.New("TextButton", {
		Size = UDim2.new(1, 0, 1, 0),
		BackgroundTransparency = 1,
		Text = "",
		Parent = holder,
	})

	local api = {}
	function api:Set(v, silent)
		state = v and true or false
		Util.Tween(track, { BackgroundColor3 = state and T.Accent or T.Field }, 0.18)
		Util.Tween(knob, {
			Position = state and UDim2.new(0, 23, 0.5, 0) or UDim2.new(0, 3, 0.5, 0),
			BackgroundColor3 = state and T.White or T.Dim,
		}, 0.18)
		if not silent then
			local ok3, err3 = pcall(cb, state)
			if not ok3 then warn("[UMH] Callback erro: " .. tostring(err3)) end
		end
	end
	function api:Get() return state end

	btn.MouseButton1Click:Connect(function() api:Set(not state) end)
	api:Set(state, true)
	return api
end

function UI.NumberInput(parent, cfg)
	local text = cfg.Text or "Valor"
	local min, max = cfg.Min or 0, cfg.Max or 1000
	local cb = cfg.Callback or function() end
	local current = math.clamp(cfg.Default or 0, min, max)

	local holder = Util.New("Frame", {
		BackgroundTransparency = 1,
		Size = UDim2.new(1, 0, 0, 34),
		LayoutOrder = cfg.Order or 0,
		Parent = parent,
	})
	Util.New("TextLabel", {
		BackgroundTransparency = 1,
		Size = UDim2.new(1, -110, 1, 0),
		Font = FONT,
		Text = text,
		TextColor3 = T.Text,
		TextSize = 14,
		TextXAlignment = Enum.TextXAlignment.Left,
		Parent = holder,
	})
	local boxHolder = Util.New("Frame", {
		AnchorPoint = Vector2.new(1, 0.5),
		Position = UDim2.new(1, 0, 0.5, 0),
		Size = UDim2.new(0, 96, 0, 26),
		BackgroundColor3 = T.Field,
		BorderSizePixel = 0,
		Parent = holder,
	})
	Util.New("UICorner", { CornerRadius = UDim.new(0, 7), Parent = boxHolder })
	local stroke = Util.New("UIStroke", {
		Color = T.White, Transparency = 0.85, Thickness = 1, Parent = boxHolder,
	})
	local box = Util.New("TextBox", {
		BackgroundTransparency = 1,
		Size = UDim2.new(1, -12, 1, 0),
		Position = UDim2.new(0, 6, 0, 0),
		Font = FONT,
		Text = tostring(current),
		TextColor3 = T.Accent,
		TextSize = 13,
		TextXAlignment = Enum.TextXAlignment.Center,
		ClearTextOnFocus = false,
		Parent = boxHolder,
	})

	local api = {}
	function api:Set(v, silent)
		current = math.clamp(tonumber(v) or current, min, max)
		box.Text = tostring(math.floor(current * 100 + 0.5) / 100)
		if not silent then pcall(cb, current) end
	end
	function api:Get() return current end

	box.FocusLost:Connect(function()
		local n = tonumber(box.Text)
		if n then api:Set(n) else box.Text = tostring(current) end
	end)
	return api
end

function UI.Button(parent, cfg)
	local text = cfg.Text or "Btn"
	local cb = cfg.Callback or function() end

	local btn = Util.New("TextButton", {
		Size = UDim2.new(1, 0, 0, 32),
		BackgroundColor3 = T.Field,
		BorderSizePixel = 0,
		Font = FONT,
		Text = text,
		TextColor3 = T.Text,
		TextSize = 13,
		AutoButtonColor = false,
		LayoutOrder = cfg.Order or 0,
		Parent = parent,
	})
	Util.New("UICorner", { CornerRadius = UDim.new(0, 8), Parent = btn })
	local stroke = Util.New("UIStroke", {
		Color = T.White, Transparency = 0.85, Thickness = 1, Parent = btn,
	})

	btn.MouseEnter:Connect(function()
		Util.Tween(btn, { BackgroundColor3 = T.Surface }, 0.15)
		Util.Tween(stroke, { Color = T.Accent, Transparency = 0.4 }, 0.15)
	end)
	btn.MouseLeave:Connect(function()
		Util.Tween(btn, { BackgroundColor3 = T.Field }, 0.15)
		Util.Tween(stroke, { Color = T.White, Transparency = 0.85 }, 0.15)
	end)
	btn.MouseButton1Click:Connect(function()
		local ok3, err3 = pcall(cb)
		if not ok3 then warn("[UMH] Botão erro: " .. tostring(err3)) end
	end)

	return {
		Instance = btn,
		SetText = function(self, v) btn.Text = v end,
	}
end

function UI.Label(parent, text, order, dim)
	Util.New("TextLabel", {
		BackgroundTransparency = 1,
		Size = UDim2.new(1, 0, 0, 18),
		Font = FONT,
		Text = text,
		TextColor3 = dim and T.Dim or T.Text,
		TextSize = 12,
		TextWrapped = true,
		TextXAlignment = Enum.TextXAlignment.Left,
		LayoutOrder = order or 0,
		Parent = parent,
	})
end

--================================================================================
-- [7] HUD
--================================================================================
local HUD = {}
HUD.__index = HUD

function HUD.new()
	local self = setmetatable({}, HUD)
	self.IsOpen = false
	self.Tabs = {}
	self:Build()
	return self
end

function HUD:Build()
	local uiParent = Util.GetUIParent()
	if not uiParent then
		warn("[UMH] Não foi possível obter parent de UI")
		return
	end

	self.Gui = Util.New("ScreenGui", {
		Name = "UMH_Hub",
		ResetOnSpawn = false,
		IgnoreGuiInset = true,
		ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
		DisplayOrder = 9999,
		Parent = uiParent,
	})

	-- Launcher
	local launcher = Util.New("TextButton", {
		AnchorPoint = Vector2.new(0, 0.5),
		Position = UDim2.new(0, 8, 0.5, 0),
		Size = UDim2.new(0, 44, 0, 44),
		BackgroundColor3 = T.Accent,
		BorderSizePixel = 0,
		Text = "UMH",
		Font = FONT_BOLD,
		TextColor3 = Color3.fromRGB(10, 12, 18),
		TextSize = 13,
		AutoButtonColor = false,
		Parent = self.Gui,
	})
	Util.New("UICorner", { CornerRadius = UDim.new(1, 0), Parent = launcher })
	Util.New("UIStroke", {
		Color = T.White, Transparency = 0.7, Thickness = 1.5, Parent = launcher,
	})
	self.Launcher = launcher

	-- Painel
	local W, H = 560, 420
	local CLOSED = UDim2.new(0, -(W + 40), 0.5, 0)
	local OPEN = UDim2.new(0, 24, 0.5, 0)

	local panel = Util.New("Frame", {
		AnchorPoint = Vector2.new(0, 0.5),
		Position = CLOSED,
		Size = UDim2.new(0, W, 0, H),
		BackgroundColor3 = T.Bg,
		BackgroundTransparency = 0.1,
		BorderSizePixel = 0,
		ClipsDescendants = true,
		Parent = self.Gui,
	})
	self.Panel = panel
	self.ClosedPos = CLOSED
	self.OpenPos = OPEN
	Util.New("UICorner", { CornerRadius = UDim.new(0, 14), Parent = panel })
	Util.New("UIStroke", {
		Color = T.White, Transparency = 0.82, Thickness = 1.5, Parent = panel,
	})

	-- Sidebar
	local sidebar = Util.New("Frame", {
		Size = UDim2.new(0, 150, 1, 0),
		BackgroundColor3 = T.Surface,
		BackgroundTransparency = 0.3,
		BorderSizePixel = 0,
		Parent = panel,
	})
	Util.New("TextLabel", {
		BackgroundTransparency = 1,
		Position = UDim2.new(0, 18, 0, 22),
		Size = UDim2.new(1, -18, 0, 24),
		Font = FONT_BOLD,
		Text = "UMH",
		TextColor3 = T.Text,
		TextSize = 22,
		TextXAlignment = Enum.TextXAlignment.Left,
		Parent = sidebar,
	})
	Util.New("TextLabel", {
		BackgroundTransparency = 1,
		Position = UDim2.new(0, 18, 0, 46),
		Size = UDim2.new(1, -18, 0, 16),
		Font = FONT,
		Text = "v2.0.0 · universal",
		TextColor3 = T.Accent,
		TextSize = 11,
		TextXAlignment = Enum.TextXAlignment.Left,
		Parent = sidebar,
	})

	local tabHolder = Util.New("Frame", {
		Position = UDim2.new(0, 0, 0, 84),
		Size = UDim2.new(1, 0, 1, -84),
		BackgroundTransparency = 1,
		Parent = sidebar,
	})
	Util.New("UIListLayout", {
		Padding = UDim.new(0, 4),
		SortOrder = Enum.SortOrder.LayoutOrder,
		Parent = tabHolder,
	})
	Util.New("UIPadding", {
		PaddingLeft = UDim.new(0, 10),
		PaddingRight = UDim.new(0, 10),
		Parent = tabHolder,
	})
	self.TabHolder = tabHolder

	-- Conteúdo
	local content = Util.New("Frame", {
		Position = UDim2.new(0, 150, 0, 0),
		Size = UDim2.new(1, -150, 1, 0),
		BackgroundTransparency = 1,
		Parent = panel,
	})
	self.HeaderTitle = Util.New("TextLabel", {
		BackgroundTransparency = 1,
		Position = UDim2.new(0, 18, 0, 0),
		Size = UDim2.new(1, -80, 0, 46),
		Font = FONT_BOLD,
		Text = "Movimentação",
		TextColor3 = T.Text,
		TextSize = 16,
		TextXAlignment = Enum.TextXAlignment.Left,
		Parent = content,
	})

	-- Close
	local closeBtn = Util.New("TextButton", {
		AnchorPoint = Vector2.new(1, 0),
		Position = UDim2.new(1, -14, 0, 10),
		Size = UDim2.new(0, 26, 0, 26),
		BackgroundColor3 = T.Field,
		BorderSizePixel = 0,
		Text = "×",
		Font = FONT_BOLD,
		TextColor3 = T.Dim,
		TextSize = 18,
		AutoButtonColor = false,
		Parent = content,
	})
	Util.New("UICorner", { CornerRadius = UDim.new(0, 8), Parent = closeBtn })
	closeBtn.MouseButton1Click:Connect(function() self:Close() end)

	self.PageContainer = Util.New("Frame", {
		Position = UDim2.new(0, 0, 0, 46),
		Size = UDim2.new(1, 0, 1, -46),
		BackgroundTransparency = 1,
		Parent = content,
	})

	launcher.MouseButton1Click:Connect(function() self:Open() end)

	-- Cria abas
	self:AddTab("Movimentação", 1)
	self:AddTab("Utilidades",   2)
	self:AddTab("Configurações",3)
	self:AddTab("Créditos",     4)

	self:SelectTab(1)
	log("HUD construída com sucesso.")
end

function HUD:AddTab(name, order)
	local btn = Util.New("TextButton", {
		Size = UDim2.new(1, 0, 0, 34),
		BackgroundColor3 = T.Surface,
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		Font = FONT,
		Text = "   " .. name,
		TextColor3 = T.Dim,
		TextSize = 13,
		TextXAlignment = Enum.TextXAlignment.Left,
		AutoButtonColor = false,
		LayoutOrder = order,
		Parent = self.TabHolder,
	})
	Util.New("UICorner", { CornerRadius = UDim.new(0, 8), Parent = btn })

	local ind = Util.New("Frame", {
		AnchorPoint = Vector2.new(0, 0.5),
		Position = UDim2.new(0, 0, 0.5, 0),
		Size = UDim2.new(0, 0, 0, 16),
		BackgroundColor3 = T.Accent,
		BorderSizePixel = 0,
		Parent = btn,
	})
	Util.New("UICorner", { CornerRadius = UDim.new(1, 0), Parent = ind })

	local page = Util.New("ScrollingFrame", {
		Size = UDim2.new(1, 0, 1, 0),
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		ScrollBarThickness = 3,
		ScrollBarImageColor3 = T.Accent,
		CanvasSize = UDim2.new(0, 0, 0, 0),
		AutomaticCanvasSize = Enum.AutomaticSize.Y,
		Visible = false,
		Parent = self.PageContainer,
	})
	Util.New("UIListLayout", {
		Padding = UDim.new(0, 8),
		SortOrder = Enum.SortOrder.LayoutOrder,
		Parent = page,
	})
	Util.New("UIPadding", {
		PaddingLeft = UDim.new(0, 18),
		PaddingRight = UDim.new(0, 18),
		PaddingTop = UDim.new(0, 4),
		PaddingBottom = UDim.new(0, 20),
		Parent = page,
	})

	local tab = { Name = name, Button = btn, Page = page, Ind = ind, Order = order }
	table.insert(self.Tabs, tab)

	btn.MouseButton1Click:Connect(function() self:SelectTab(order) end)
	return tab
end

function HUD:SelectTab(order)
	for _, tab in ipairs(self.Tabs) do
		local active = (tab.Order == order)
		tab.Page.Visible = active
		Util.Tween(tab.Button, {
			BackgroundTransparency = active and 0.55 or 1,
			TextColor3 = active and T.Text or T.Dim,
		}, 0.18)
		Util.Tween(tab.Ind, {
			Size = active and UDim2.new(0, 3, 0, 16) or UDim2.new(0, 0, 0, 16),
		}, 0.2)
		if active then self.HeaderTitle.Text = tab.Name end
	end
end

function HUD:Open()
	if self.IsOpen then return end
	self.IsOpen = true
	self.Launcher.Visible = false
	Util.Tween(self.Panel, { Position = self.OpenPos }, 0.4, Enum.EasingStyle.Quint)
end

function HUD:Close()
	if not self.IsOpen then return end
	self.IsOpen = false
	Util.Tween(self.Panel, { Position = self.ClosedPos }, 0.32, Enum.EasingStyle.Quint)
	task.delay(0.32, function()
		if not self.IsOpen then self.Launcher.Visible = true end
	end)
end

function HUD:Toggle()
	if self.IsOpen then self:Close() else self:Open() end
end

function HUD:Destroy()
	pcall(function() self.Gui:Destroy() end)
end

--================================================================================
-- [8] MOTORES DE MOVIMENTO
--================================================================================

-- SPEED (CFrame Glide)
local Speed = { Original = 16, Active = false }

function Speed:SetState(state)
	local hum = Util.GetChar()
	if state then
		if hum then
			self.Original = hum.WalkSpeed
			hum.WalkSpeed = 0
		end
		self.Active = true
	else
		self.Active = false
		local hum2 = Util.GetChar()
		if hum2 then hum2.WalkSpeed = self.Original > 0 and self.Original or 16 end
	end
end

function Speed:Update(dt)
	if not Config.Speed.Enabled then return end
	local hum, hrp = Util.GetChar()
	if not hum or not hrp then return end

	local cam = workspace.CurrentCamera
	if not cam then return end

	local dir = hum.MoveDirection
	if dir.Magnitude < 0.05 then
		local move = Vector3.zero
		if UserInputService:IsKeyDown(Enum.KeyCode.W) then move += cam.CFrame.LookVector end
		if UserInputService:IsKeyDown(Enum.KeyCode.S) then move -= cam.CFrame.LookVector end
		if UserInputService:IsKeyDown(Enum.KeyCode.A) then move -= cam.CFrame.RightVector end
		if UserInputService:IsKeyDown(Enum.KeyCode.D) then move += cam.CFrame.RightVector end
		move = Vector3.new(move.X, 0, move.Z)
		if move.Magnitude > 0.01 then dir = move.Unit end
	end

	if dir.Magnitude < 0.05 then return end
	if hum.WalkSpeed ~= 0 then hum.WalkSpeed = 0 end
	hrp.CFrame = hrp.CFrame + dir.Unit * Config.Speed.Value * dt
end

-- FLY (VectorForce + BodyGyro)
local Fly = { Force = nil, Gyro = nil, Attach = nil, Active = false, Saved = nil }

function Fly:Build(hrp)
	self:Destroy()
	local att = Util.New("Attachment", { Parent = hrp })
	local force = Util.New("VectorForce", {
		Attachment0 = att,
		ApplyAtCenterOfMass = true,
		RelativeTo = Enum.ActuatorRelativeTo.World,
		Force = Vector3.zero,
		Parent = hrp,
	})
	local gyro = Util.New("BodyGyro", {
		CFrame = hrp.CFrame,
		MaxTorque = Vector3.new(1e6, 1e6, 1e6),
		P = 3000,
		D = 500,
		Parent = hrp,
	})
	self.Attach, self.Force, self.Gyro = att, force, gyro
end

function Fly:Destroy()
	for _, inst in ipairs({ self.Force, self.Gyro, self.Attach }) do
		if inst then pcall(function() inst:Destroy() end) end
	end
	self.Force, self.Gyro, self.Attach = nil, nil, nil
end

function Fly:SetState(state)
	if state == self.Active then return end
	self.Active = state
	local hum, hrp = Util.GetChar()
	if not hum or not hrp then self.Active = false return end

	if state then
		hum.AutoRotate = false
		hum.WalkSpeed = 0
		self.Saved = {
			Freefall = hum:GetStateEnabled(Enum.HumanoidStateType.Freefall),
			Climbing = hum:GetStateEnabled(Enum.HumanoidStateType.Climbing),
			Swimming = hum:GetStateEnabled(Enum.HumanoidStateType.Swimming),
		}
		hum:SetStateEnabled(Enum.HumanoidStateType.Freefall, false)
		hum:SetStateEnabled(Enum.HumanoidStateType.Climbing, false)
		hum:SetStateEnabled(Enum.HumanoidStateType.Swimming, false)
		self:Build(hrp)
	else
		self:Destroy()
		hum.AutoRotate = true
		hum.WalkSpeed = 16
		if self.Saved then
			pcall(function() hum:SetStateEnabled(Enum.HumanoidStateType.Freefall, self.Saved.Freefall) end)
			pcall(function() hum:SetStateEnabled(Enum.HumanoidStateType.Climbing, self.Saved.Climbing) end)
			pcall(function() hum:SetStateEnabled(Enum.HumanoidStateType.Swimming, self.Saved.Swimming) end)
		end
		self.Saved = nil
	end
end

function Fly:Update(dt)
	if not Config.Fly.Enabled then return end
	local hum, hrp = Util.GetChar()
	if not hum or not hrp then return end

	if not self.Force or not self.Force.Parent then self:Build(hrp) end
	local cam = workspace.CurrentCamera
	if not cam then return end

	local dir = Vector3.zero
	if UserInputService:IsKeyDown(Enum.KeyCode.W) then dir += cam.CFrame.LookVector end
	if UserInputService:IsKeyDown(Enum.KeyCode.S) then dir -= cam.CFrame.LookVector end
	if UserInputService:IsKeyDown(Enum.KeyCode.A) then dir -= cam.CFrame.RightVector end
	if UserInputService:IsKeyDown(Enum.KeyCode.D) then dir += cam.CFrame.RightVector end
	if UserInputService:IsKeyDown(Enum.KeyCode.Space) then dir += Vector3.new(0, 1, 0) end
	if UserInputService:IsKeyDown(Enum.KeyCode.LeftControl) then dir -= Vector3.new(0, 1, 0) end
	if dir.Magnitude > 0.01 then dir = dir.Unit end

	local speed = Config.Fly.Value
	local target = dir * speed
	local mass = hrp.AssemblyMass
	local curVel = hrp.AssemblyLinearVelocity
	local delta = target - curVel
	local gravityComp = Vector3.new(0, workspace.Gravity * mass, 0)
	local force = gravityComp + (delta * mass * 14)

	local maxF = mass * 100000
	force = Vector3.new(
		math.clamp(force.X, -maxF, maxF),
		math.clamp(force.Y, -maxF, maxF),
		math.clamp(force.Z, -maxF, maxF)
	)
	self.Force.Force = force
	self.Gyro.CFrame = cam.CFrame

	pcall(function() hum:ChangeState(Enum.HumanoidStateType.Running) end)
end

-- NOCLIP
local Noclip = {}
function Noclip:Update()
	if not Config.Noclip.Enabled then return end
	local char = LocalPlayer.Character
	if not char then return end
	for _, p in ipairs(char:GetDescendants()) do
		if p:IsA("BasePart") and p.CanCollide then p.CanCollide = false end
	end
end

-- INFINITE JUMP
local InfJump = { Deb = false }
function InfJump:Init()
	UserInputService.JumpRequest:Connect(function()
		if not Config.InfiniteJump.Enabled then return end
		if self.Deb then return end
		self.Deb = true
		task.delay(0.08, function() self.Deb = false end)
		local hum = Util.GetChar()
		if hum then pcall(function() hum:ChangeState(Enum.HumanoidStateType.Jumping) end) end
	end)
end

--================================================================================
-- [9] BOOTSTRAP
--================================================================================
log("Construindo HUD...")
local hub = HUD.new()
ENV.UMH_Loaded = hub

-- Aba: Movimentação
local pMove = hub.Tabs[1].Page

UI.Section(pMove, "Corrida", 1)
UI.Toggle(pMove, {
	Text = "Speed (CFrame Glide)",
	Default = Config.Speed.Enabled,
	Order = 2,
	Callback = function(s)
		Config.Speed.Enabled = s
		Speed:SetState(s)
		log("Speed: " .. tostring(s))
	end,
})
local speedInput = UI.NumberInput(pMove, {
	Text = "Velocidade de Corrida",
	Default = Config.Speed.Value,
	Min = Config.Speed.Min, Max = Config.Speed.Max,
	Order = 3,
	Callback = function(v) Config.Speed.Value = v end,
})

UI.Section(pMove, "Voo", 4)
UI.Toggle(pMove, {
	Text = "Fly (VectorForce)",
	Default = Config.Fly.Enabled,
	Order = 5,
	Callback = function(s)
		Config.Fly.Enabled = s
		Fly:SetState(s)
		log("Fly: " .. tostring(s))
	end,
})
local flyInput = UI.NumberInput(pMove, {
	Text = "Velocidade de Voo",
	Default = Config.Fly.Value,
	Min = Config.Fly.Min, Max = Config.Fly.Max,
	Order = 6,
	Callback = function(v) Config.Fly.Value = v end,
})
UI.Label(pMove, "WASD = direção · Space = subir · Ctrl = descer", 7, true)

-- Aba: Utilidades
local pUtil = hub.Tabs[2].Page
UI.Section(pUtil, "Mobilidade", 1)
UI.Toggle(pUtil, {
	Text = "Noclip",
	Default = Config.Noclip.Enabled,
	Order = 2,
	Callback = function(s)
		Config.Noclip.Enabled = s
		if not s then
			local char = LocalPlayer.Character
			if char then
				for _, p in ipairs(char:GetDescendants()) do
					if p:IsA("BasePart") then p.CanCollide = true end
				end
			end
		end
	end,
})
UI.Toggle(pUtil, {
	Text = "Infinite Jump",
	Default = Config.InfiniteJump.Enabled,
	Order = 3,
	Callback = function(s) Config.InfiniteJump.Enabled = s end,
})
UI.Section(pUtil, "Info", 4)
UI.Label(pUtil, "Anti-Lag: cada sistema em task.spawn separado.", 5, true)
UI.Label(pUtil, "State Spoofing ativo durante o voo.", 6, true)

-- Aba: Configurações
local pCfg = hub.Tabs[3].Page
UI.Section(pCfg, "Reset", 1)
UI.Button(pCfg, {
	Text = "Restaurar Padrões",
	Order = 2,
	Callback = function()
		speedInput:Set(60, true)
		flyInput:Set(80, true)
		Config.Speed.Value = 60
		Config.Fly.Value = 80
		log("Configurações restauradas.")
	end,
})

-- Aba: Créditos
local pCred = hub.Tabs[4].Page
UI.Section(pCred, "Universal Movement Hub", 1)
UI.Label(pCred, "Versão 2.0.0", 2)
UI.Label(pCred, "Arquitetura modular em Luau com motores independentes.", 3, true)
UI.Section(pCred, "Stack", 4)
UI.Label(pCred, "• Heartbeat → Speed / Fly", 5, true)
UI.Label(pCred, "• Stepped → Noclip", 6, true)
UI.Label(pCred, "• TweenService → HUD", 7, true)

--================================================================================
-- [10] LOOPS (isolados em task.spawn)
--================================================================================
task.spawn(function()
	RunService.Heartbeat:Connect(function(dt)
		pcall(Speed.Update, Speed, dt)
	end)
end)

task.spawn(function()
	RunService.Heartbeat:Connect(function(dt)
		pcall(Fly.Update, Fly, dt)
	end)
end)

task.spawn(function()
	RunService.Stepped:Connect(function()
		pcall(Noclip.Update, Noclip)
	end)
end)

task.spawn(function()
	InfJump:Init()
end)

-- Respawn handler
LocalPlayer.CharacterAdded:Connect(function()
	task.wait(0.6)
	if Config.Fly.Enabled then
		Fly.Active = false
		Fly:SetState(true)
	end
	if Config.Speed.Enabled then Speed:SetState(true) end
end)

-- Abre o menu
task.delay(0.3, function() hub:Open() end)

--================================================================================
-- [11] API PÚBLICA
--================================================================================
ENV.UMH = {
	Version = "2.0.0",
	Config  = Config,
	Hub     = hub,
	Speed   = Speed,
	Fly     = Fly,
	Noclip  = Noclip,
	InfJump = InfJump,
}

log("Universal Movement Hub v2.0 carregado com sucesso! ✅")
