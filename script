--[[
================================================================================
 ██╗   ██╗███╗   ███╗██╗  ██╗
 ██║   ██║████╗ ████║██║  ██║
 ██║   ██║██╔████╔██║███████║
 ██║   ██║██║╚██╔╝██║██╔══██║
 ╚██████╔╝██║ ╚═╝ ██║██║  ██║
  ╚═════╝ ╚═╝     ╚═╝╚═╝  ╚═╝
 UNIVERSAL MOVEMENT HUB  ·  v1.0.0  ·  Luau / Roblox
 Arquitetura OOP Modular  |  Target: Executor Nível 8
================================================================================
]]

--================================================================================
-- [1] SERVIÇOS
--================================================================================
local Players          = game:GetService("Players")
local RunService       = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local TweenService     = game:GetService("TweenService")
local Lighting         = game:GetService("Lighting")

local LocalPlayer = Players.LocalPlayer
while not LocalPlayer do
	task.wait(0.1)
	LocalPlayer = Players.LocalPlayer
end

-- Ambiente global do executor (fallback seguro)
local ENV = (typeof(getgenv) == "function" and getgenv()) or _G

--================================================================================
-- [2] CONFIGURAÇÃO GLOBAL  (getgenv().UMH_Settings / getgenv().UMH_Config)
--================================================================================
-- UMH_Settings → preferências persistentes de UI/input (raramente mudam)
ENV.UMH_Settings = {
	Version     = "1.0.0",
	ToggleKey   = Enum.KeyCode.RightShift,
	BlurEffect  = true,
	BlurSize    = 18,
}

-- UMH_Config → estado de runtime LIDO A CADA FRAME pelo motor de movimento.
-- A UI escreve diretamente aqui, permitindo alteração instantânea.
ENV.UMH_Config = {
	Speed = {
		Enabled = false,
		Value   = 60,
		Min     = 16,
		Max     = 500,
	},
	Fly = {
		Enabled = false,
		Value   = 80,
		Min     = 10,
		Max     = 1000,
		Responsiveness = 14, -- ganho do controlador P (aceleração)
	},
	Noclip = {
		Enabled = false,
	},
	InfiniteJump = {
		Enabled = false,
	},
}

local Settings = ENV.UMH_Settings
local Config   = ENV.UMH_Config

--================================================================================
-- [3] UTILITÁRIOS
--================================================================================
local Util = {}

--[[ Cria uma Instance de forma performática (Parent aplicado por último). ]]
function Util.New(className, props)
	local inst = Instance.new(className)
	local parent
	for k, v in pairs(props) do
		if k == "Parent" then
			parent = v
		else
			inst[k] = v
		end
	end
	if parent then
		inst.Parent = parent
	end
	return inst
end

--[[ Resolve o melhor container de UI disponível no executor. ]]
function Util.GetUIParent()
	if typeof(gethui) == "function" then
		local ok, hui = pcall(gethui)
		if ok and hui then return hui end
	end
	local ok, cg = pcall(function() return game:GetService("CoreGui") end)
	if ok and cg then return cg end
	return LocalPlayer:WaitForChild("PlayerGui")
end

--[[ Atalho para tweens padronizados. ]]
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

--[[ Retorna o Humanoid / HumanoidRootPart atuais com validação. ]]
function Util.GetCharacter()
	local char = LocalPlayer.Character
	if not char or not char.Parent then return nil, nil end
	local hum = char:FindFirstChildOfClass("Humanoid")
	local hrp = char:FindFirstChild("HumanoidRootPart")
	if not hum or not hrp then return nil, nil end
	if hum.Health <= 0 then return nil, nil end
	return hum, hrp
end

--[[ Vetor de direção planar normalizado com base no input do teclado. ]]
function Util.GetPlanarInput(camera)
	local dir = Vector3.zero
	if UserInputService:IsKeyDown(Enum.KeyCode.W) then dir += camera.CFrame.LookVector end
	if UserInputService:IsKeyDown(Enum.KeyCode.S) then dir -= camera.CFrame.LookVector end
	if UserInputService:IsKeyDown(Enum.KeyCode.A) then dir -= camera.CFrame.RightVector end
	if UserInputService:IsKeyDown(Enum.KeyCode.D) then dir += camera.CFrame.RightVector end
	dir = Vector3.new(dir.X, 0, dir.Z)
	if dir.Magnitude > 0.01 then dir = dir.Unit end
	return dir
end

--================================================================================
-- [4] TEMA VISUAL (Glassmorphism)
--================================================================================
local THEME = {
	Background = Color3.fromRGB(14, 15, 22),
	Surface    = Color3.fromRGB(24, 26, 36),
	SurfaceAlt = Color3.fromRGB(34, 37, 50),
	Accent     = Color3.fromRGB(0, 210, 255),
	Accent2    = Color3.fromRGB(155, 80, 255),
	Success    = Color3.fromRGB(0, 230, 150),
	Danger     = Color3.fromRGB(255, 72, 92),
	Text       = Color3.fromRGB(238, 242, 255),
	TextDim    = Color3.fromRGB(140, 148, 172),
	Stroke     = Color3.fromRGB(255, 255, 255),
}

local FONT       = Enum.Font.GothamMedium
local FONT_BOLD  = Enum.Font.GothamBold

--================================================================================
-- [5] BIBLIOTECA DE COMPONENTES (UI Kit)
--================================================================================
local Components = {}

--[[ ---------------------------------------------------------------- SECTION ]]
function Components.Section(parent, text, order)
	local holder = Util.New("Frame", {
		Name = "Section_" .. text,
		BackgroundTransparency = 1,
		Size = UDim2.new(1, 0, 0, 26),
		LayoutOrder = order or 0,
		Parent = parent,
	})
	Util.New("TextLabel", {
		BackgroundTransparency = 1,
		Size = UDim2.new(1, 0, 1, 0),
		Font = FONT_BOLD,
		Text = string.upper(text),
		TextColor3 = THEME.TextDim,
		TextSize = 11,
		TextXAlignment = Enum.TextXAlignment.Left,
		Parent = holder,
	})
	Util.New("Frame", {
		AnchorPoint = Vector2.new(1, 0.5),
		Position = UDim2.new(1, 0, 0.5, 0),
		Size = UDim2.new(0, 120, 0, 1),
		BackgroundColor3 = THEME.Stroke,
		BackgroundTransparency = 0.92,
		BorderSizePixel = 0,
		Parent = holder,
	})
	return holder
end

--[[ ----------------------------------------------------------------- TOGGLE ]]
function Components.Toggle(parent, cfg)
	local text     = cfg.Text or "Toggle"
	local callback = cfg.Callback or function() end
	local state    = cfg.Default and true or false

	local holder = Util.New("Frame", {
		Name = "Toggle_" .. text,
		BackgroundTransparency = 1,
		Size = UDim2.new(1, 0, 0, 34),
		LayoutOrder = cfg.Order or 0,
		Parent = parent,
	})

	local label = Util.New("TextLabel", {
		BackgroundTransparency = 1,
		Size = UDim2.new(1, -60, 1, 0),
		Font = FONT,
		Text = text,
		TextColor3 = THEME.Text,
		TextSize = 14,
		TextXAlignment = Enum.TextXAlignment.Left,
		Parent = holder,
	})

	local track = Util.New("Frame", {
		AnchorPoint = Vector2.new(1, 0.5),
		Position = UDim2.new(1, 0, 0.5, 0),
		Size = UDim2.new(0, 42, 0, 22),
		BackgroundColor3 = THEME.SurfaceAlt,
		BorderSizePixel = 0,
		Parent = holder,
	})
	Util.New("UICorner", { CornerRadius = UDim.new(1, 0), Parent = track })
	local trackStroke = Util.New("UIStroke", {
		Color = THEME.Stroke, Transparency = 0.86, Thickness = 1, Parent = track,
	})

	local knob = Util.New("Frame", {
		AnchorPoint = Vector2.new(0, 0.5),
		Position = UDim2.new(0, 3, 0.5, 0),
		Size = UDim2.new(0, 16, 0, 16),
		BackgroundColor3 = THEME.TextDim,
		BorderSizePixel = 0,
		Parent = track,
	})
	Util.New("UICorner", { CornerRadius = UDim.new(1, 0), Parent = knob })

	local button = Util.New("TextButton", {
		Size = UDim2.new(1, 0, 1, 0),
		BackgroundTransparency = 1,
		Text = "",
		AutoButtonColor = false,
		Parent = holder,
	})

	local api = {}

	function api:Set(value, silent)
		state = value and true or false
		Util.Tween(track, {
			BackgroundColor3 = state and THEME.Accent or THEME.SurfaceAlt,
		}, 0.20)
		Util.Tween(trackStroke, {
			Color = state and THEME.Accent or THEME.Stroke,
			Transparency = state and 0.55 or 0.86,
		}, 0.20)
		Util.Tween(knob, {
			Position = state and UDim2.new(0, 23, 0.5, 0) or UDim2.new(0, 3, 0.5, 0),
			BackgroundColor3 = state and Color3.new(1, 1, 1) or THEME.TextDim,
		}, 0.20, Enum.EasingStyle.Back, Enum.EasingDirection.Out)
		if not silent then
			task.spawn(callback, state)
		end
	end

	function api:Get() return state end

	button.MouseButton1Click:Connect(function()
		api:Set(not state)
	end)

	button.MouseEnter:Connect(function()
		Util.Tween(label, { TextColor3 = Color3.new(1, 1, 1) }, 0.15)
	end)
	button.MouseLeave:Connect(function()
		Util.Tween(label, { TextColor3 = THEME.Text }, 0.15)
	end)

	api:Set(state, true) -- sincroniza visual sem disparar callback
	return api
end

--[[ ----------------------------------------------------------- NUMBER INPUT ]]
function Components.NumberInput(parent, cfg)
	local text     = cfg.Text or "Valor"
	local min      = cfg.Min or 0
	local max      = cfg.Max or 1000
	local callback = cfg.Callback or function() end
	local current  = math.clamp(cfg.Default or 0, min, max)

	local holder = Util.New("Frame", {
		Name = "Input_" .. text,
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
		TextColor3 = THEME.Text,
		TextSize = 14,
		TextXAlignment = Enum.TextXAlignment.Left,
		Parent = holder,
	})

	local boxHolder = Util.New("Frame", {
		AnchorPoint = Vector2.new(1, 0.5),
		Position = UDim2.new(1, 0, 0.5, 0),
		Size = UDim2.new(0, 96, 0, 26),
		BackgroundColor3 = THEME.SurfaceAlt,
		BorderSizePixel = 0,
		Parent = holder,
	})
	Util.New("UICorner", { CornerRadius = UDim.new(0, 7), Parent = boxHolder })
	local stroke = Util.New("UIStroke", {
		Color = THEME.Stroke, Transparency = 0.86, Thickness = 1, Parent = boxHolder,
	})

	local box = Util.New("TextBox", {
		BackgroundTransparency = 1,
		Size = UDim2.new(1, -12, 1, 0),
		Position = UDim2.new(0, 6, 0, 0),
		Font = FONT,
		Text = tostring(current),
		TextColor3 = THEME.Accent,
		TextSize = 13,
		PlaceholderText = "0",
		PlaceholderColor3 = THEME.TextDim,
		TextXAlignment = Enum.TextXAlignment.Center,
		ClearTextOnFocus = false,
		Parent = boxHolder,
	})

	local api = {}

	function api:Set(value, silent)
		current = math.clamp(tonumber(value) or current, min, max)
		box.Text = tostring(math.floor(current * 100 + 0.5) / 100)
		if not silent then
			task.spawn(callback, current)
		end
	end

	function api:Get() return current end

	box.Focused:Connect(function()
		Util.Tween(stroke, { Color = THEME.Accent, Transparency = 0.35 }, 0.15)
	end)

	box.FocusLost:Connect(function()
		Util.Tween(stroke, { Color = THEME.Stroke, Transparency = 0.86 }, 0.15)
		local parsed = tonumber(box.Text)
		if parsed then
			api:Set(parsed)
		else
			box.Text = tostring(current)
		end
	end)

	return api
end

--[[ ----------------------------------------------------------------- BUTTON ]]
function Components.Button(parent, cfg)
	local text     = cfg.Text or "Button"
	local callback = cfg.Callback or function() end
	local accent   = cfg.Accent or THEME.Accent

	local btn = Util.New("TextButton", {
		Name = "Btn_" .. text,
		Size = UDim2.new(1, 0, 0, 32),
		BackgroundColor3 = THEME.SurfaceAlt,
		BorderSizePixel = 0,
		Font = FONT,
		Text = text,
		TextColor3 = THEME.Text,
		TextSize = 13,
		AutoButtonColor = false,
		LayoutOrder = cfg.Order or 0,
		Parent = parent,
	})
	Util.New("UICorner", { CornerRadius = UDim.new(0, 8), Parent = btn })
	local stroke = Util.New("UIStroke", {
		Color = THEME.Stroke, Transparency = 0.85, Thickness = 1, Parent = btn,
	})

	btn.MouseEnter:Connect(function()
		Util.Tween(btn, { BackgroundColor3 = THEME.Surface }, 0.15)
		Util.Tween(stroke, { Color = accent, Transparency = 0.4 }, 0.15)
	end)
	btn.MouseLeave:Connect(function()
		Util.Tween(btn, { BackgroundColor3 = THEME.SurfaceAlt }, 0.15)
		Util.Tween(stroke, { Color = THEME.Stroke, Transparency = 0.85 }, 0.15)
	end)
	btn.MouseButton1Click:Connect(function()
		task.spawn(callback)
	end)

	local api = {}
	api.Instance = btn
	api.Stroke   = stroke

	function api:SetText(value)
		btn.Text = value
	end

	return api
end

--[[ ------------------------------------------------------------------ LABEL ]]
function Components.Label(parent, text, order, dim)
	Util.New("TextLabel", {
		BackgroundTransparency = 1,
		Size = UDim2.new(1, 0, 0, 20),
		Font = FONT,
		Text = text,
		TextColor3 = dim and THEME.TextDim or THEME.Text,
		TextSize = 13,
		TextWrapped = true,
		TextXAlignment = Enum.TextXAlignment.Left,
		LayoutOrder = order or 0,
		Parent = parent,
	})
end

--================================================================================
-- [6] HUD PRINCIPAL (Ultra-Professional Glassmorphism HUD)
--================================================================================
local HUD = {}
HUD.__index = HUD

function HUD.new()
	local self = setmetatable({}, HUD)
	self.IsOpen     = false
	self.Tabs       = {}
	self.ActiveTab  = nil
	self.Blur       = nil
	self:Build()
	return self
end

function HUD:Build()
	local uiParent = Util.GetUIParent()

	-- ------------------------------------------------------------ ScreenGui
	self.Gui = Util.New("ScreenGui", {
		Name = "UMH_Hub",
		ResetOnSpawn = false,
		IgnoreGuiInset = true,
		ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
		DisplayOrder = 9999,
		Parent = uiParent,
	})

	-- --------------------------------------------------- Botão flutuante (abrir)
	local launcher = Util.New("TextButton", {
		Name = "Launcher",
		AnchorPoint = Vector2.new(0, 0.5),
		Position = UDim2.new(0, 8, 0.5, 0),
		Size = UDim2.new(0, 44, 0, 44),
		BackgroundColor3 = THEME.Accent,
		BorderSizePixel = 0,
		Text = "UMH",
		Font = FONT_BOLD,
		TextColor3 = Color3.fromRGB(10, 12, 18),
		TextSize = 13,
		AutoButtonColor = false,
		Parent = self.Gui,
	})
	Util.New("UICorner", { CornerRadius = UDim.new(1, 0), Parent = launcher })
	local launcherGrad = Util.New("UIGradient", {
		Color = ColorSequence.new(THEME.Accent, THEME.Accent2),
		Rotation = 45,
		Parent = launcher,
	})
	Util.New("UIStroke", {
		Color = THEME.Stroke, Transparency = 0.7, Thickness = 1.5, Parent = launcher,
	})
	self.Launcher = launcher

	-- ---------------------------------------------------------------- Painel
	local PANEL_W, PANEL_H = 580, 430
	local CLOSED_POS = UDim2.new(0, -(PANEL_W + 40), 0.5, 0)
	local OPEN_POS   = UDim2.new(0, 24, 0.5, 0)

	local panel = Util.New("Frame", {
		Name = "Panel",
		AnchorPoint = Vector2.new(0, 0.5),
		Position = CLOSED_POS,
		Size = UDim2.new(0, PANEL_W, 0, PANEL_H),
		BackgroundColor3 = THEME.Background,
		BackgroundTransparency = 0.15,
		BorderSizePixel = 0,
		ClipsDescendants = true,
		Parent = self.Gui,
	})
	self.Panel = panel
	self.ClosedPos = CLOSED_POS
	self.OpenPos   = OPEN_POS

	Util.New("UICorner", { CornerRadius = UDim.new(0, 14), Parent = panel })
	Util.New("UIStroke", {
		Color = THEME.Stroke, Transparency = 0.82, Thickness = 1.5, Parent = panel,
	})
	-- Brilho superior (vidro)
	local sheen = Util.New("Frame", {
		Size = UDim2.new(1, 0, 0, 90),
		BackgroundColor3 = Color3.new(1, 1, 1),
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		ZIndex = 0,
		Parent = panel,
	})
	Util.New("UIGradient", {
		Rotation = 90,
		Transparency = NumberSequence.new({
			NumberSequenceKeypoint.new(0, 0.94),
			NumberSequenceKeypoint.new(1, 1),
		}),
		Parent = sheen,
	})

	-- -------------------------------------------------------------- Sidebar
	local sidebar = Util.New("Frame", {
		Name = "Sidebar",
		Size = UDim2.new(0, 152, 1, 0),
		BackgroundColor3 = THEME.Surface,
		BackgroundTransparency = 0.35,
		BorderSizePixel = 0,
		ZIndex = 2,
		Parent = panel,
	})
	local sidebarGrad = Util.New("UIGradient", {
		Rotation = 90,
		Color = ColorSequence.new({
			ColorSequenceKeypoint.new(0, Color3.fromRGB(38, 42, 58)),
			ColorSequenceKeypoint.new(1, Color3.fromRGB(16, 18, 26)),
		}),
		Transparency = NumberSequence.new({
			NumberSequenceKeypoint.new(0, 0.55),
			NumberSequenceKeypoint.new(1, 0.35),
		}),
		Parent = sidebar,
	})

	Util.New("TextLabel", {
		BackgroundTransparency = 1,
		Position = UDim2.new(0, 18, 0, 22),
		Size = UDim2.new(1, -18, 0, 24),
		Font = FONT_BOLD,
		Text = "UMH",
		TextColor3 = THEME.Text,
		TextSize = 22,
		TextXAlignment = Enum.TextXAlignment.Left,
		ZIndex = 3,
		Parent = sidebar,
	})
	Util.New("TextLabel", {
		BackgroundTransparency = 1,
		Position = UDim2.new(0, 18, 0, 46),
		Size = UDim2.new(1, -18, 0, 16),
		Font = FONT,
		Text = "v" .. Settings.Version .. " · universal",
		TextColor3 = THEME.Accent,
		TextSize = 11,
		TextXAlignment = Enum.TextXAlignment.Left,
		ZIndex = 3,
		Parent = sidebar,
	})

	local tabHolder = Util.New("Frame", {
		Name = "Tabs",
		Position = UDim2.new(0, 0, 0, 84),
		Size = UDim2.new(1, 0, 1, -84),
		BackgroundTransparency = 1,
		ZIndex = 3,
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

	-- -------------------------------------------------------------- Conteúdo
	local content = Util.New("Frame", {
		Name = "Content",
		Position = UDim2.new(0, 152, 0, 0),
		Size = UDim2.new(1, -152, 1, 0),
		BackgroundTransparency = 1,
		ZIndex = 2,
		Parent = panel,
	})

	-- Header
	local header = Util.New("Frame", {
		Size = UDim2.new(1, 0, 0, 46),
		BackgroundTransparency = 1,
		Parent = content,
	})
	self.HeaderTitle = Util.New("TextLabel", {
		BackgroundTransparency = 1,
		Position = UDim2.new(0, 18, 0, 0),
		Size = UDim2.new(1, -80, 1, 0),
		Font = FONT_BOLD,
		Text = "Movimentação",
		TextColor3 = THEME.Text,
		TextSize = 16,
		TextXAlignment = Enum.TextXAlignment.Left,
		Parent = header,
	})

	local closeBtn = Util.New("TextButton", {
		AnchorPoint = Vector2.new(1, 0.5),
		Position = UDim2.new(1, -14, 0.5, 0),
		Size = UDim2.new(0, 26, 0, 26),
		BackgroundColor3 = THEME.SurfaceAlt,
		BorderSizePixel = 0,
		Text = "×",
		Font = FONT_BOLD,
		TextColor3 = THEME.TextDim,
		TextSize = 18,
		AutoButtonColor = false,
		Parent = header,
	})
	Util.New("UICorner", { CornerRadius = UDim.new(0, 8), Parent = closeBtn })
	closeBtn.MouseEnter:Connect(function()
		Util.Tween(closeBtn, { BackgroundColor3 = THEME.Danger, TextColor3 = Color3.new(1,1,1) }, 0.15)
	end)
	closeBtn.MouseLeave:Connect(function()
		Util.Tween(closeBtn, { BackgroundColor3 = THEME.SurfaceAlt, TextColor3 = THEME.TextDim }, 0.15)
	end)
	closeBtn.MouseButton1Click:Connect(function() self:Close() end)

	-- Container de páginas
	self.PageContainer = Util.New("Frame", {
		Position = UDim2.new(0, 0, 0, 46),
		Size = UDim2.new(1, 0, 1, -46),
		BackgroundTransparency = 1,
		Parent = content,
	})

	-- Launcher click
	launcher.MouseButton1Click:Connect(function() self:Open() end)

	-- Constrói as abas
	self:AddTab("Movimentação", 1)
	self:AddTab("Utilidades",   2)
	self:AddTab("Configurações",3)
	self:AddTab("Créditos",     4)

	self:SelectTab(1)
end

--[[ Cria uma aba + sua página (ScrollingFrame). ]]
function HUD:AddTab(name, order)
	local btn = Util.New("TextButton", {
		Name = "Tab_" .. name,
		Size = UDim2.new(1, 0, 0, 34),
		BackgroundColor3 = THEME.SurfaceAlt,
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		Font = FONT,
		Text = "   " .. name,
		TextColor3 = THEME.TextDim,
		TextSize = 13,
		TextXAlignment = Enum.TextXAlignment.Left,
		AutoButtonColor = false,
		LayoutOrder = order,
		Parent = self.TabHolder,
	})
	Util.New("UICorner", { CornerRadius = UDim.new(0, 8), Parent = btn })

	local indicator = Util.New("Frame", {
		AnchorPoint = Vector2.new(0, 0.5),
		Position = UDim2.new(0, 0, 0.5, 0),
		Size = UDim2.new(0, 0, 0, 16),
		BackgroundColor3 = THEME.Accent,
		BorderSizePixel = 0,
		Parent = btn,
	})
	Util.New("UICorner", { CornerRadius = UDim.new(1, 0), Parent = indicator })

	local page = Util.New("ScrollingFrame", {
		Name = "Page_" .. name,
		Size = UDim2.new(1, 0, 1, 0),
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		ScrollBarThickness = 3,
		ScrollBarImageColor3 = THEME.Accent,
		ScrollBarImageTransparency = 0.4,
		CanvasSize = UDim2.new(0, 0, 0, 0),
		AutomaticCanvasSize = Enum.AutomaticSize.Y,
		ScrollingDirection = Enum.ScrollingDirection.Y,
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

	local tab = { Name = name, Button = btn, Page = page, Indicator = indicator, Order = order }
	table.insert(self.Tabs, tab)

	btn.MouseEnter:Connect(function()
		if self.ActiveTab ~= tab then
			Util.Tween(btn, { BackgroundTransparency = 0.7, TextColor3 = THEME.Text }, 0.15)
		end
	end)
	btn.MouseLeave:Connect(function()
		if self.ActiveTab ~= tab then
			Util.Tween(btn, { BackgroundTransparency = 1, TextColor3 = THEME.TextDim }, 0.15)
		end
	end)
	btn.MouseButton1Click:Connect(function() self:SelectTab(order) end)

	return page, tab
end

--[[ Alterna a aba ativa com feedback visual. ]]
function HUD:SelectTab(order)
	for _, tab in ipairs(self.Tabs) do
		local active = (tab.Order == order)
		tab.Page.Visible = active
		Util.Tween(tab.Button, {
			BackgroundTransparency = active and 0.55 or 1,
			TextColor3 = active and THEME.Text or THEME.TextDim,
			BackgroundColor3 = active and THEME.SurfaceAlt or THEME.Surface,
		}, 0.18)
		Util.Tween(tab.Indicator, {
			Size = active and UDim2.new(0, 3, 0, 16) or UDim2.new(0, 0, 0, 16),
			BackgroundColor3 = active and THEME.Accent or THEME.SurfaceAlt,
		}, 0.20)
		if active then
			self.ActiveTab = tab
			self.HeaderTitle.Text = tab.Name
		end
	end
end

--[[ Efeito de blur no cenário 3D (reforça o glassmorphism). ]]
function HUD:SetBlur(enabled)
	if enabled then
		if not self.Blur then
			self.Blur = Util.New("BlurEffect", {
				Name = "UMH_Blur",
				Size = Settings.BlurSize,
				Parent = Lighting,
			})
		end
	else
		if self.Blur then
			self.Blur:Destroy()
			self.Blur = nil
		end
	end
end

--[[ Abre o painel com animação de deslize + fade. ]]
function HUD:Open()
	if self.IsOpen then return end
	self.IsOpen = true
	self.Launcher.Visible = false
	if Settings.BlurEffect then self:SetBlur(true) end
	Util.Tween(self.Panel, { Position = self.OpenPos }, 0.42, Enum.EasingStyle.Quint)
end

--[[ Fecha o painel. ]]
function HUD:Close()
	if not self.IsOpen then return end
	self.IsOpen = false
	self:SetBlur(false)
	Util.Tween(self.Panel, { Position = self.ClosedPos }, 0.34, Enum.EasingStyle.Quint)
	task.delay(0.34, function()
		if not self.IsOpen then self.Launcher.Visible = true end
	end)
end

function HUD:Toggle()
	if self.IsOpen then self:Close() else self:Open() end
end

function HUD:Destroy()
	pcall(function() self:SetBlur(false) end)
	pcall(function() self.Gui:Destroy() end)
end

--================================================================================
-- [7] MOTOR DE MOVIMENTAÇÃO
--================================================================================

--=========================================================== SPEED (CFrame)
local SpeedEngine = {}
SpeedEngine.Active = false
SpeedEngine.OriginalWalkSpeed = 16

--[[ Habilita/desabilita o motor de velocidade. ]]
function SpeedEngine:SetState(state)
	if state then
		local hum = select(1, Util.GetCharacter())
		if hum then
			self.OriginalWalkSpeed = hum.WalkSpeed
			hum.WalkSpeed = 0 -- controle total via CFrame
		end
		self.Active = true
	else
		self.Active = false
		local hum = select(1, Util.GetCharacter())
		if hum then
			hum.WalkSpeed = self.OriginalWalkSpeed > 0 and self.OriginalWalkSpeed or 16
		end
	end
end

--[[ Loop de glide: aplica delta de CFrame por frame (anti speed-hack). ]]
function SpeedEngine:Update(dt)
	if not Config.Speed.Enabled then return end

	local hum, hrp = Util.GetCharacter()
	if not hum or not hrp then return end

	local camera = workspace.CurrentCamera
	if not camera then return end

	-- Direção prioriza MoveDirection (nativo); fallback para input direto.
	local dir = hum.MoveDirection
	if dir.Magnitude < 0.05 then
		dir = Util.GetPlanarInput(camera)
	end
	if dir.Magnitude < 0.05 then return end

	-- Mantém WalkSpeed em 0 durante o glide para evitar dupla movimentação
	if hum.WalkSpeed ~= 0 then
		hum.WalkSpeed = 0
	end

	local velocity = dir.Unit * Config.Speed.Value
	hrp.CFrame = hrp.CFrame + velocity * dt
end

--============================================================= FLY (Físico)
local FlyEngine = {}
FlyEngine.Force      = nil
FlyEngine.Gyro       = nil
FlyEngine.Attachment = nil
FlyEngine.Active     = false
FlyEngine.SavedStates = {}

--[[ Cria a malha física (Attachment + VectorForce + BodyGyro). ]]
function FlyEngine:Build(hrp)
	self:Destroy()

	local attachment = Util.New("Attachment", {
		Name = "UMH_FlyAttachment",
		Parent = hrp,
	})

	local force = Util.New("VectorForce", {
		Name = "UMH_FlyForce",
		Attachment0 = attachment,
		ApplyAtCenterOfMass = true,
		RelativeTo = Enum.ActuatorRelativeTo.World,
		Force = Vector3.zero,
		Parent = hrp,
	})

	-- BodyGyro: mantém a orientação alinhada à câmera.
	-- (Deprecado pela Roblox, porém ainda funcional e o padrão histórico
	--  para voo físico. Equivalente moderno: AlignOrientation + Attachment.)
	local gyro = Util.New("BodyGyro", {
		Name = "UMH_FlyGyro",
		CFrame = hrp.CFrame,
		MaxTorque = Vector3.new(1e6, 1e6, 1e6),
		P = 3000,
		D = 500,
		Parent = hrp,
	})

	self.Attachment = attachment
	self.Force      = force
	self.Gyro       = gyro
end

--[[ Remove a malha física. ]]
function FlyEngine:Destroy()
	for _, inst in ipairs({ self.Force, self.Gyro, self.Attachment }) do
		if inst then pcall(function() inst:Destroy() end) end
	end
	self.Force, self.Gyro, self.Attachment = nil, nil, nil
end

--[[ Ativa/desativa o voo, aplicando State Spoofing no Humanoid. ]]
function FlyEngine:SetState(state)
	if state == self.Active then return end
	self.Active = state

	local hum, hrp = Util.GetCharacter()
	if not hum or not hrp then
		self.Active = false
		return
	end

	if state then
		hum.AutoRotate = false
		hum.WalkSpeed  = 0

		-- State Spoofing: força o estado para Running, anulando a detecção
		-- de "Freefall" (voo) do servidor.
		self.SavedStates = {
			Freefall = hum:GetStateEnabled(Enum.HumanoidStateType.Freefall),
			Climbing = hum:GetStateEnabled(Enum.HumanoidStateType.Climbing),
			Swimming = hum:GetStateEnabled(Enum.HumanoidStateType.Swimming),
		}
		hum:SetStateEnabled(Enum.HumanoidStateType.Freefall, false)
		hum:SetStateEnabled(Enum.HumanoidStateType.Climbing, false)
		hum:SetStateEnabled(Enum.HumanoidStateType.Swimming, false)
		pcall(function() hum:ChangeState(Enum.HumanoidStateType.Running) end)

		self:Build(hrp)
	else
		self:Destroy()

		hum.AutoRotate = true
		hum.WalkSpeed  = 16

		for stateType, enabled in pairs(self.SavedStates) do
			pcall(function()
				hum:SetStateEnabled(Enum.HumanoidStateType[stateType], enabled)
			end)
		end
		self.SavedStates = {}
	end
end

--[[ Loop físico do voo: controlador P sobre a velocidade alvo. ]]
function FlyEngine:Update(dt)
	if not Config.Fly.Enabled then return end

	local hum, hrp = Util.GetCharacter()
	if not hum or not hrp then return end

	-- Reconstrução defensiva (respawn / streaming).
	if not self.Force or not self.Force.Parent then
		self:Build(hrp)
	end

	local camera = workspace.CurrentCamera
	if not camera then return end

	-- -------------------------------------------------- Vetor de direção
	local dir = Vector3.zero
	if UserInputService:IsKeyDown(Enum.KeyCode.W) then dir += camera.CFrame.LookVector end
	if UserInputService:IsKeyDown(Enum.KeyCode.S) then dir -= camera.CFrame.LookVector end
	if UserInputService:IsKeyDown(Enum.KeyCode.A) then dir -= camera.CFrame.RightVector end
	if UserInputService:IsKeyDown(Enum.KeyCode.D) then dir += camera.CFrame.RightVector end
	if UserInputService:IsKeyDown(Enum.KeyCode.Space) then dir += Vector3.yAxis end
	if UserInputService:IsKeyDown(Enum.KeyCode.LeftControl) then dir -= Vector3.yAxis end
	if dir.Magnitude > 0.01 then dir = dir.Unit end

	-- Lê a velocidade em tempo real (UI pode alterar a qualquer frame)
	local speed = Config.Fly.Value
	local targetVelocity = dir * speed

	-- -------------------------------------------------- Controlador P
	local mass       = hrp.AssemblyMass
	local currentVel = hrp.AssemblyLinearVelocity
	local delta      = targetVelocity - currentVel
	local gravityComp = Vector3.new(0, workspace.Gravity * mass, 0)

	local force = gravityComp + (delta * mass * Config.Fly.Responsiveness)

	local maxForce = mass * 100000
	force = Vector3.new(
		math.clamp(force.X, -maxForce, maxForce),
		math.clamp(force.Y, -maxForce, maxForce),
		math.clamp(force.Z, -maxForce, maxForce)
	)

	self.Force.Force = force

	-- -------------------------------------------------- Orientação
	self.Gyro.CFrame = camera.CFrame

	-- -------------------------------------------------- State Spoofing
	pcall(function() hum:ChangeState(Enum.HumanoidStateType.Running) end)
end

--================================================================== NOCLIP
local Noclip = {}

function Noclip:Update()
	if not Config.Noclip.Enabled then return end
	local char = LocalPlayer.Character
	if not char then return end
	for _, part in ipairs(char:GetDescendants()) do
		if part:IsA("BasePart") and part.CanCollide then
			part.CanCollide = false
		end
	end
end

--========================================================== INFINITE JUMP
local InfiniteJump = {}
InfiniteJump.Debounce = false

function InfiniteJump:Init()
	UserInputService.JumpRequest:Connect(function()
		if not Config.InfiniteJump.Enabled then return end
		if self.Debounce then return end
		self.Debounce = true
		task.delay(0.08, function() self.Debounce = false end)

		local hum = select(1, Util.GetCharacter())
		if hum then
			pcall(function() hum:ChangeState(Enum.HumanoidStateType.Jumping) end)
		end
	end)
end

--================================================================================
-- [8] BOOTSTRAP  ·  Construção da UI e inicialização dos loops (Anti-Lag)
--================================================================================

-- Limpeza de execução anterior
if ENV.UMH_Loaded then
	pcall(function() ENV.UMH_Loaded:Destroy() end)
end

local hub = HUD.new()
ENV.UMH_Loaded = hub

--================================================================================
-- [8.1] ABA: MOVIMENTAÇÃO
--================================================================================
local pageMove = hub:GetPage and hub:GetPage("Movimentação") or hub.Tabs[1].Page

Components.Section(pageMove, "Corrida", 1)

local speedToggle
speedToggle = Components.Toggle(pageMove, {
	Text     = "Speed (CFrame Glide)",
	Default  = Config.Speed.Enabled,
	Order    = 2,
	Callback = function(state)
		Config.Speed.Enabled = state
		SpeedEngine:SetState(state)
	end,
})

local speedInput
speedInput = Components.NumberInput(pageMove, {
	Text     = "Velocidade de Corrida",
	Default  = Config.Speed.Value,
	Min      = Config.Speed.Min,
	Max      = Config.Speed.Max,
	Order    = 3,
	Callback = function(value)
		Config.Speed.Value = value
	end,
})

Components.Section(pageMove, "Voo", 4)

local flyToggle
flyToggle = Components.Toggle(pageMove, {
	Text     = "Fly (VectorForce + BodyGyro)",
	Default  = Config.Fly.Enabled,
	Order    = 5,
	Callback = function(state)
		Config.Fly.Enabled = state
		FlyEngine:SetState(state)
	end,
})

local flyInput
flyInput = Components.NumberInput(pageMove, {
	Text     = "Velocidade de Voo",
	Default  = Config.Fly.Value,
	Min      = Config.Fly.Min,
	Max      = Config.Fly.Max,
	Order    = 6,
	Callback = function(value)
		Config.Fly.Value = value
	end,
})

Components.Label(pageMove,
	"W/A/S/D → direção  ·  Space → subir  ·  LeftCtrl → descer",
	7, true
)

--================================================================================
-- [8.2] ABA: UTILIDADES
--================================================================================
local pageUtil = hub.Tabs[2].Page

Components.Section(pageUtil, "Mobilidade", 1)

Components.Toggle(pageUtil, {
	Text     = "Noclip (Atravessar Paredes)",
	Default  = Config.Noclip.Enabled,
	Order    = 2,
	Callback = function(state)
		Config.Noclip.Enabled = state
		if not state then
			-- Restaura colisão ao desligar
			local char = LocalPlayer.Character
			if char then
				for _, part in ipairs(char:GetDescendants()) do
					if part:IsA("BasePart") then
						part.CanCollide = true
					end
				end
			end
		end
	end,
})

Components.Toggle(pageUtil, {
	Text     = "Infinite Jump",
	Default  = Config.InfiniteJump.Enabled,
	Order    = 3,
	Callback = function(state)
		Config.InfiniteJump.Enabled = state
	end,
})

Components.Section(pageUtil, "Diagnóstico", 4)
Components.Label(pageUtil, "Anti-Lag: cada sistema roda em thread isolada via task.spawn.", 5, true)
Components.Label(pageUtil, "State Spoofing ativo durante o voo (Humanoid → Running).", 6, true)

--================================================================================
-- [8.3] ABA: CONFIGURAÇÕES
--================================================================================
local pageCfg = hub.Tabs[3].Page

Components.Section(pageCfg, "Interface", 1)

Components.Toggle(pageCfg, {
	Text     = "Efeito Blur (Glassmorphism)",
	Default  = Settings.BlurEffect,
	Order    = 2,
	Callback = function(state)
		Settings.BlurEffect = state
		if hub.IsOpen then hub:SetBlur(state) end
	end,
})

Components.Section(pageCfg, "Atalhos", 3)

local keybindBtn = Components.Button(pageCfg, {
	Text     = "Tecla do Menu: " .. Settings.ToggleKey.Name,
	Order    = 4,
	Callback = function() end,
})

local capturing = false
keybindBtn.Instance.MouseButton1Click:Connect(function()
	if capturing then return end
	capturing = true
	keybindBtn:SetText("Pressione uma tecla...")

	local conn
	conn = UserInputService.InputBegan:Connect(function(input, processed)
		if processed then return end
		if input.UserInputType == Enum.UserInputType.Keyboard then
			Settings.ToggleKey = input.KeyCode
			keybindBtn:SetText("Tecla do Menu: " .. input.KeyCode.Name)
			capturing = false
			conn:Disconnect()
		end
	end)
end)

Components.Section(pageCfg, "Reset", 5)

Components.Button(pageCfg, {
	Text     = "Restaurar Valores Padrão",
	Accent   = THEME.Danger,
	Order    = 6,
	Callback = function()
		Config.Speed.Value = 60
		Config.Fly.Value   = 80
		speedInput:Set(60, true)
		flyInput:Set(80, true)
	end,
})

--================================================================================
-- [8.4] ABA: CRÉDITOS
--================================================================================
local pageCred = hub.Tabs[4].Page

Components.Section(pageCred, "Universal Movement Hub", 1)
Components.Label(pageCred, "Versão " .. Settings.Version, 2)
Components.Label(pageCred,
	"Arquitetura OOP modular em Luau. Motor de velocidade por CFrame Glide, " ..
	"voo físico com VectorForce + BodyGyro, Noclip por RunService.Stepped e " ..
	"Infinite Jump via UserInputService.",
	3, true
)
Components.Section(pageCred, "Stack Técnica", 4)
Components.Label(pageCred, "• RunService.Heartbeat → loop de movimento", 5, true)
Components.Label(pageCred, "• RunService.Stepped   → loop de noclip", 6, true)
Components.Label(pageCred, "• TweenService         → animações da HUD", 7, true)
Components.Label(pageCred, "• task.spawn           → isolamento de threads", 8, true)

--================================================================================
-- [8.5] INICIALIZAÇÃO DOS LOOPS (Anti-Lag: 1 thread por sistema)
--================================================================================

-- Loop de Corrida (CFrame Glide)
task.spawn(function()
	RunService.Heartbeat:Connect(function(dt)
		local ok, err = pcall(SpeedEngine.Update, SpeedEngine, dt)
		if not ok then warn("[UMH][Speed] " .. tostring(err)) end
	end)
end)

-- Loop de Voo (Físico)
task.spawn(function()
	RunService.Heartbeat:Connect(function(dt)
		local ok, err = pcall(FlyEngine.Update, FlyEngine, dt)
		if not ok then warn("[UMH][Fly] " .. tostring(err)) end
	end)
end)

-- Loop de Noclip
task.spawn(function()
	RunService.Stepped:Connect(function()
		local ok, err = pcall(Noclip.Update, Noclip)
		if not ok then warn("[UMH][Noclip] " .. tostring(err)) end
	end)
end)

-- Infinite Jump
task.spawn(function()
	InfiniteJump:Init()
end)

--================================================================================
-- [8.6] EVENTOS GLOBAIS
--================================================================================

-- Keybind de abertura/fechamento
UserInputService.InputBegan:Connect(function(input, processed)
	if processed then return end
	if input.KeyCode == Settings.ToggleKey then
		hub:Toggle()
	end
end)

-- Respawn: restaura estados e reinicializa malha física se necessário
LocalPlayer.CharacterAdded:Connect(function()
	task.wait(0.6)
	if Config.Fly.Enabled then
		FlyEngine.Active = false
		FlyEngine:SetState(true)
	end
	if Config.Speed.Enabled then
		SpeedEngine:SetState(true)
	end
end)

-- Abre o menu automaticamente
task.delay(0.35, function()
	hub:Open()
end)

--================================================================================
-- API PÚBLICA
--================================================================================
ENV.UMH = {
	Version  = Settings.Version,
	Config   = Config,
	Settings = Settings,
	Hub      = hub,
	Speed    = SpeedEngine,
	Fly      = FlyEngine,
	Noclip   = Noclip,
	InfiniteJump = InfiniteJump,
}

print(("[UMH] Universal Movement Hub v%s carregado com sucesso."):format(Settings.Version))
