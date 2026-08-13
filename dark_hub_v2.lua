-- [[ DARK HUB // 手机专属高端模拟作弊菜单 V2.0 ]] --
-- 适配超圆角 UI + 全自定义数字输入 + 修复光照逻辑 --

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local Lighting = game:GetService("Lighting")
local TeleportService = game:GetService("TeleportService")

local LocalPlayer = Players.LocalPlayer
local Camera = workspace.CurrentCamera

-- 备份地图初始光照参数（用于精准关闭夜视）
local OriginalLighting = {
	Ambient = Lighting.Ambient,
	OutdoorAmbient = Lighting.OutdoorAmbient,
	Brightness = Lighting.Brightness,
	GlobalShadows = Lighting.GlobalShadows
}

-- 全局变量
local Flags = {
	Fly = false,
	FlySpeed = 50,
	FlyUp = false,
	FlyDown = false,
	Noclip = false,
	Speed = 16,
	JumpPower = 50,
	InfJump = false,
	ESP = false,
	FullBright = false,
	Aimbot = false,
	TouchTP = false,
	Spinbot = false,
	SpinSpeed = 30, -- 默认旋转速度
	AntiAFK = false,
	BHop = false,
}

------------------------------------------------------------------------
-- 1. 大圆角现代 UI 框架构建
------------------------------------------------------------------------

local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "MobileCheatMenu_v2"
ScreenGui.ResetOnSpawn = false
ScreenGui.Parent = LocalPlayer:WaitForChild("PlayerGui")

-- 悬浮球 (极简圆球)
local ToggleBall = Instance.new("TextButton")
ToggleBall.Name = "ToggleBall"
ToggleBall.Size = UDim2.new(0, 48, 0, 48)
ToggleBall.Position = UDim2.new(0.05, 0, 0.2, 0)
ToggleBall.BackgroundColor3 = Color3.fromRGB(203, 166, 247)
ToggleBall.Text = "HUB"
ToggleBall.TextColor3 = Color3.fromRGB(24, 24, 37)
ToggleBall.Font = Enum.Font.GothamBold
ToggleBall.TextSize = 14
ToggleBall.Parent = ScreenGui

local BallCorner = Instance.new("UICorner")
BallCorner.CornerRadius = UDim.new(1, 0) -- 纯圆
BallCorner.Parent = ToggleBall

local BallStroke = Instance.new("UIStroke")
BallStroke.Color = Color3.fromRGB(255, 255, 255)
BallStroke.Thickness = 2.5
BallStroke.Parent = ToggleBall

-- 悬浮球拖动
local ballDragging, ballStart, ballStartPos
ToggleBall.InputBegan:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.Touch or input.UserInputType == Enum.UserInputType.MouseButton1 then
		ballDragging = true
		ballStart = input.Position
		ballStartPos = ToggleBall.Position
	end
end)

UserInputService.InputChanged:Connect(function(input)
	if ballDragging and (input.UserInputType == Enum.UserInputType.Touch or input.UserInputType == Enum.UserInputType.MouseMovement) then
		local delta = input.Position - ballStart
		ToggleBall.Position = UDim2.new(ballStartPos.X.Scale, ballStartPos.X.Offset + delta.X, ballStartPos.Y.Scale, ballStartPos.Y.Offset + delta.Y)
	end
end)

UserInputService.InputEnded:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.Touch or input.UserInputType == Enum.UserInputType.MouseButton1 then
		ballDragging = false
	end
end)

-- 主界面 Frame (超圆角设计)
local MainFrame = Instance.new("Frame")
MainFrame.Name = "MainFrame"
MainFrame.Size = UDim2.new(0, 350, 0, 250)
MainFrame.Position = UDim2.new(0.5, -175, 0.5, -125)
MainFrame.BackgroundColor3 = Color3.fromRGB(30, 30, 46)
MainFrame.BorderSizePixel = 0
MainFrame.ClipsDescendants = true
MainFrame.Visible = true
MainFrame.Parent = ScreenGui

local MainCorner = Instance.new("UICorner")
MainCorner.CornerRadius = UDim.new(0, 20) -- 20px 高度圆角
MainCorner.Parent = MainFrame

-- 点击悬浮球显示/隐藏
ToggleBall.MouseButton1Click:Connect(function()
	MainFrame.Visible = not MainFrame.Visible
end)

-- 顶栏 (拖动区)
local TopBar = Instance.new("Frame")
TopBar.Size = UDim2.new(1, 0, 0, 40)
TopBar.BackgroundColor3 = Color3.fromRGB(24, 24, 37)
TopBar.BorderSizePixel = 0
TopBar.Parent = MainFrame

local Title = Instance.new("TextLabel")
Title.Size = UDim2.new(1, -40, 1, 0)
Title.Position = UDim2.new(0, 15, 0, 0)
Title.Text = "DARK HUB // MOBILE v2"
Title.TextColor3 = Color3.fromRGB(203, 166, 247)
Title.TextSize = 13
Title.Font = Enum.Font.GothamBold
Title.TextXAlignment = Enum.TextXAlignment.Left
Title.BackgroundTransparency = 1
Title.Parent = TopBar

-- 顶栏拖动主界面
local menuDragging, menuStart, menuStartPos
TopBar.InputBegan:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.Touch or input.UserInputType == Enum.UserInputType.MouseButton1 then
		menuDragging = true
		menuStart = input.Position
		menuStartPos = MainFrame.Position
	end
end)

UserInputService.InputChanged:Connect(function(input)
	if menuDragging and (input.UserInputType == Enum.UserInputType.Touch or input.UserInputType == Enum.UserInputType.MouseMovement) then
		local delta = input.Position - menuStart
		MainFrame.Position = UDim2.new(menuStartPos.X.Scale, menuStartPos.X.Offset + delta.X, menuStartPos.Y.Scale, menuStartPos.Y.Offset + delta.Y)
	end
end)

UserInputService.InputEnded:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.Touch or input.UserInputType == Enum.UserInputType.MouseButton1 then
		menuDragging = false
	end
end)

-- 侧边栏 (圆角选项卡背景)
local SideBar = Instance.new("Frame")
SideBar.Size = UDim2.new(0, 95, 1, -40)
SideBar.Position = UDim2.new(0, 0, 0, 40)
SideBar.BackgroundColor3 = Color3.fromRGB(17, 17, 27)
SideBar.BorderSizePixel = 0
SideBar.Parent = MainFrame

local SideLayout = Instance.new("UIListLayout")
SideLayout.Parent = SideBar
SideLayout.Padding = UDim.new(0, 4)
SideLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center

local SidePadding = Instance.new("UIPadding")
SidePadding.PaddingTop = UDim.new(0, 5)
SidePadding.Parent = SideBar

-- 内容区域
local ContentContainer = Instance.new("Frame")
ContentContainer.Size = UDim2.new(1, -105, 1, -45)
ContentContainer.Position = UDim2.new(0, 100, 0, 42)
ContentContainer.BackgroundTransparency = 1
ContentContainer.Parent = MainFrame

local Tabs = {}

local function CreateTab(name)
	local TabButton = Instance.new("TextButton")
	TabButton.Size = UDim2.new(0, 85, 0, 36)
	TabButton.BackgroundColor3 = Color3.fromRGB(17, 17, 27)
	TabButton.Text = name
	TabButton.TextColor3 = Color3.fromRGB(166, 173, 200)
	TabButton.Font = Enum.Font.GothamSemibold
	TabButton.TextSize = 12
	TabButton.Parent = SideBar

	local TabCorner = Instance.new("UICorner")
	TabCorner.CornerRadius = UDim.new(0, 10)
	TabCorner.Parent = TabButton

	local Page = Instance.new("ScrollingFrame")
	Page.Size = UDim2.new(1, -5, 1, 0)
	Page.BackgroundTransparency = 1
	Page.Visible = false
	Page.ScrollBarThickness = 2
	Page.ScrollBarImageColor3 = Color3.fromRGB(203, 166, 247)
	Page.Parent = ContentContainer

	local PageLayout = Instance.new("UIListLayout")
	PageLayout.Parent = Page
	PageLayout.Padding = UDim.new(0, 6)

	TabButton.MouseButton1Click:Connect(function()
		for _, t in pairs(Tabs) do
			t.Page.Visible = false
			t.Button.TextColor3 = Color3.fromRGB(166, 173, 200)
			t.Button.BackgroundColor3 = Color3.fromRGB(17, 17, 27)
		end
		Page.Visible = true
		TabButton.TextColor3 = Color3.fromRGB(203, 166, 247)
		TabButton.BackgroundColor3 = Color3.fromRGB(30, 30, 46)
	end)

	table.insert(Tabs, {Button = TabButton, Page = Page})
	return Page
end

-- 组件构建器 (超圆角 + 支持手机输入数字框)
local UI = {}

-- 1. 开关 Toggle
function UI.CreateToggle(parent, text, flagName, callback)
	local Frame = Instance.new("Frame")
	Frame.Size = UDim2.new(1, -10, 0, 38)
	Frame.BackgroundColor3 = Color3.fromRGB(45, 45, 68)
	Frame.Parent = parent
	
	local Corner = Instance.new("UICorner")
	Corner.CornerRadius = UDim.new(0, 12) -- 12px 圆角
	Corner.Parent = Frame

	local Label = Instance.new("TextLabel")
	Label.Size = UDim2.new(0.65, 0, 1, 0)
	Label.Position = UDim2.new(0, 10, 0, 0)
	Label.Text = text
	Label.TextColor3 = Color3.fromRGB(205, 214, 244)
	Label.TextXAlignment = Enum.TextXAlignment.Left
	Label.Font = Enum.Font.Gotham
	Label.TextSize = 11
	Label.BackgroundTransparency = 1
	Label.Parent = Frame

	local ToggleBtn = Instance.new("TextButton")
	ToggleBtn.Size = UDim2.new(0, 42, 0, 22)
	ToggleBtn.Position = UDim2.new(1, -50, 0.5, -11)
	ToggleBtn.BackgroundColor3 = Color3.fromRGB(88, 91, 112)
	ToggleBtn.Text = ""
	ToggleBtn.Parent = Frame

	local BtnCorner = Instance.new("UICorner")
	BtnCorner.CornerRadius = UDim.new(1, 0)
	BtnCorner.Parent = ToggleBtn

	local Circle = Instance.new("Frame")
	Circle.Size = UDim2.new(0, 18, 0, 18)
	Circle.Position = UDim2.new(0, 2, 0.5, -9)
	Circle.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
	Circle.Parent = ToggleBtn

	local CircleCorner = Instance.new("UICorner")
	CircleCorner.CornerRadius = UDim.new(1, 0)
	CircleCorner.Parent = Circle

	local state = false
	ToggleBtn.MouseButton1Click:Connect(function()
		state = not state
		Flags[flagName] = state
		TweenService:Create(ToggleBtn, TweenInfo.new(0.2), {BackgroundColor3 = state and Color3.fromRGB(166, 227, 161) or Color3.fromRGB(88, 91, 112)}):Play()
		TweenService:Create(Circle, TweenInfo.new(0.2), {Position = state and UDim2.new(1, -20, 0.5, -9) or UDim2.new(0, 2, 0.5, -9)}):Play()
		if callback then callback(state) end
	end)
end

-- 2. 普通按钮 Button
function UI.CreateButton(parent, text, callback)
	local Button = Instance.new("TextButton")
	Button.Size = UDim2.new(1, -10, 0, 36)
	Button.BackgroundColor3 = Color3.fromRGB(45, 45, 68)
	Button.Text = text
	Button.TextColor3 = Color3.fromRGB(205, 214, 244)
	Button.Font = Enum.Font.GothamMedium
	Button.TextSize = 11
	Button.Parent = parent

	local Corner = Instance.new("UICorner")
	Corner.CornerRadius = UDim.new(0, 12)
	Corner.Parent = Button

	Button.MouseButton1Click:Connect(function()
		if callback then callback() end
	end)
end

-- 3. 带【数字自定义输入框】的滑动条 Slider
function UI.CreateSlider(parent, text, min, max, default, callback)
	local Frame = Instance.new("Frame")
	Frame.Size = UDim2.new(1, -10, 0, 46)
	Frame.BackgroundColor3 = Color3.fromRGB(45, 45, 68)
	Frame.Parent = parent

	local Corner = Instance.new("UICorner")
	Corner.CornerRadius = UDim.new(0, 12)
	Corner.Parent = Frame

	-- 标题
	local Label = Instance.new("TextLabel")
	Label.Size = UDim2.new(0.6, 0, 0, 20)
	Label.Position = UDim2.new(0, 10, 0, 4)
	Label.Text = text
	Label.TextColor3 = Color3.fromRGB(205, 214, 244)
	Label.TextXAlignment = Enum.TextXAlignment.Left
	Label.Font = Enum.Font.Gotham
	Label.TextSize = 11
	Label.BackgroundTransparency = 1
	Label.Parent = Frame

	-- 手动输入数字的 TextBox (手机用户点这里输入)
	local InputBox = Instance.new("TextBox")
	InputBox.Size = UDim2.new(0, 50, 0, 18)
	InputBox.Position = UDim2.new(1, -60, 0, 4)
	InputBox.BackgroundColor3 = Color3.fromRGB(31, 31, 40)
	InputBox.Text = tostring(default)
	InputBox.TextColor3 = Color3.fromRGB(203, 166, 247)
	InputBox.Font = Enum.Font.GothamBold
	InputBox.TextSize = 11
	InputBox.Parent = Frame

	local InputCorner = Instance.new("UICorner")
	InputCorner.CornerRadius = UDim.new(0, 6)
	InputCorner.Parent = InputBox

	-- 滑条背景
	local SliderBar = Instance.new("Frame")
	SliderBar.Size = UDim2.new(1, -20, 0, 6)
	SliderBar.Position = UDim2.new(0, 10, 0, 28)
	SliderBar.BackgroundColor3 = Color3.fromRGB(31, 31, 40)
	SliderBar.Parent = Frame

	local SliderBarCorner = Instance.new("UICorner")
	SliderBarCorner.CornerRadius = UDim.new(1, 0)
	SliderBarCorner.Parent = SliderBar

	local Fill = Instance.new("Frame")
	Fill.Size = UDim2.new(math.clamp((default - min)/(max - min), 0, 1), 0, 1, 0)
	Fill.BackgroundColor3 = Color3.fromRGB(137, 180, 250)
	Fill.BorderSizePixel = 0
	Fill.Parent = SliderBar

	local FillCorner = Instance.new("UICorner")
	FillCorner.CornerRadius = UDim.new(1, 0)
	FillCorner.Parent = Fill

	-- 更新逻辑
	local function SetValue(val)
		val = tonumber(val) or default
		InputBox.Text = tostring(val)
		local pct = math.clamp((val - min) / (max - min), 0, 1)
		Fill.Size = UDim2.new(pct, 0, 1, 0)
		if callback then callback(val) end
	end

	-- 滑块拖动
	local draggingSlider = false
	local function UpdateFromInput(input)
		local pos = math.clamp((input.Position.X - SliderBar.AbsolutePosition.X) / SliderBar.AbsoluteSize.X, 0, 1)
		local val = math.floor(min + (max - min) * pos)
		SetValue(val)
	end

	SliderBar.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.Touch or input.UserInputType == Enum.UserInputType.MouseButton1 then
			draggingSlider = true
			UpdateFromInput(input)
		end
	end)

	UserInputService.InputEnded:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.Touch or input.UserInputType == Enum.UserInputType.MouseButton1 then
			draggingSlider = false
		end
	end)

	UserInputService.InputChanged:Connect(function(input)
		if draggingSlider and (input.UserInputType == Enum.UserInputType.Touch or input.UserInputType == Enum.UserInputType.MouseMovement) then
			UpdateFromInput(input)
		end
	end)

	-- 手机直接输入数字监听
	InputBox.FocusLost:Connect(function()
		local num = tonumber(InputBox.Text)
		if num then
			SetValue(num)
		else
			InputBox.Text = tostring(default)
		end
	end)
end

------------------------------------------------------------------------
-- 2. 手机飞行悬浮按钮 (圆角)
------------------------------------------------------------------------

local FlyControlFrame = Instance.new("Frame")
FlyControlFrame.Size = UDim2.new(0, 60, 0, 130)
FlyControlFrame.Position = UDim2.new(1, -70, 0.4, 0)
FlyControlFrame.BackgroundTransparency = 1
FlyControlFrame.Visible = false
FlyControlFrame.Parent = ScreenGui

local UpBtn = Instance.new("TextButton")
UpBtn.Size = UDim2.new(0, 52, 0, 52)
UpBtn.Position = UDim2.new(0, 0, 0, 0)
UpBtn.BackgroundColor3 = Color3.fromRGB(45, 45, 68)
UpBtn.Text = "▲\n上升"
UpBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
UpBtn.Font = Enum.Font.GothamBold
UpBtn.TextSize = 11
UpBtn.Parent = FlyControlFrame
Instance.new("UICorner", UpBtn).CornerRadius = UDim.new(1, 0)

local DownBtn = Instance.new("TextButton")
DownBtn.Size = UDim2.new(0, 52, 0, 52)
DownBtn.Position = UDim2.new(0, 0, 0, 60)
DownBtn.BackgroundColor3 = Color3.fromRGB(45, 45, 68)
DownBtn.Text = "▼\n下降"
DownBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
DownBtn.Font = Enum.Font.GothamBold
DownBtn.TextSize = 11
DownBtn.Parent = FlyControlFrame
Instance.new("UICorner", DownBtn).CornerRadius = UDim.new(1, 0)

UpBtn.InputBegan:Connect(function() Flags.FlyUp = true end)
UpBtn.InputEnded:Connect(function() Flags.FlyUp = false end)
DownBtn.InputBegan:Connect(function() Flags.FlyUp = false end)
DownBtn.InputEnded:Connect(function() Flags.FlyDown = false end)

------------------------------------------------------------------------
-- 3. 注册菜单功能项
------------------------------------------------------------------------

local MovePage = CreateTab("移动")
local VisualPage = CreateTab("视觉")
local CombatPage = CreateTab("战斗")
local MiscPage = CreateTab("杂项")

-- 默认选中第一页
Tabs[1].Page.Visible = true
Tabs[1].Button.TextColor3 = Color3.fromRGB(203, 166, 247)
Tabs[1].Button.BackgroundColor3 = Color3.fromRGB(30, 30, 46)

-- --- 移动页 ---
UI.CreateToggle(MovePage, "摇杆自由飞行", "Fly", function(val)
	FlyControlFrame.Visible = val
	if not val and LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then
		LocalPlayer.Character.HumanoidRootPart.Velocity = Vector3.zero
	end
end)
UI.CreateSlider(MovePage, "飞行速度", 10, 300, 50, function(val) Flags.FlySpeed = val end)
UI.CreateToggle(MovePage, "穿墙模式 (Noclip)", "Noclip")
UI.CreateSlider(MovePage, "移动速度", 16, 300, 16, function(val) Flags.Speed = val end)
UI.CreateSlider(MovePage, "跳跃高度", 50, 300, 50, function(val) Flags.JumpPower = val end)
UI.CreateToggle(MovePage, "无限连跳", "InfJump")
UI.CreateToggle(MovePage, "自动连跳 (BHop)", "BHop")

-- --- 视觉页 ---
UI.CreateToggle(VisualPage, "玩家透视 (ESP)", "ESP", function(val)
	if not val then
		for _, p in pairs(Players:GetPlayers()) do
			if p.Character and p.Character:FindFirstChild("Highlight") then
				p.Character.Highlight:Destroy()
			end
		end
	end
end)

-- 修复全局夜视开关恢复逻辑！
UI.CreateToggle(VisualPage, "全局夜视/亮光", "FullBright", function(val)
	if not val then
		-- 还原地图原生参数
		Lighting.Ambient = OriginalLighting.Ambient
		Lighting.OutdoorAmbient = OriginalLighting.OutdoorAmbient
		Lighting.Brightness = OriginalLighting.Brightness
		Lighting.GlobalShadows = OriginalLighting.GlobalShadows
	end
end)

UI.CreateSlider(VisualPage, "视野 FOV", 70, 120, 70, function(val) Camera.FieldOfView = val end)

-- --- 战斗页 ---
UI.CreateToggle(CombatPage, "自动自瞄锁定", "Aimbot")
UI.CreateToggle(CombatPage, "点击屏幕传送", "TouchTP")
UI.CreateToggle(CombatPage, "陀螺高速自旋", "Spinbot")
-- 新增：陀螺自旋速度调节！
UI.CreateSlider(CombatPage, "自旋速度", 5, 180, 30, function(val) Flags.SpinSpeed = val end)

UI.CreateButton(CombatPage, "本地隐身/显形", function()
	if LocalPlayer.Character then
		for _, v in pairs(LocalPlayer.Character:GetDescendants()) do
			if v:IsA("BasePart") or v:IsA("Decal") then
				v.Transparency = v.Transparency == 1 and 0 or 1
			end
		end
	end
end)

-- --- 杂项页 ---
UI.CreateToggle(MiscPage, "防挂机踢出", "AntiAFK")
UI.CreateButton(MiscPage, "获取基础建材工具", function()
	Instance.new("HopperBin", LocalPlayer.Backpack).BinType = Enum.BinType.Clone
	Instance.new("HopperBin", LocalPlayer.Backpack).BinType = Enum.BinType.Hammer
	Instance.new("HopperBin", LocalPlayer.Backpack).BinType = Enum.BinType.Grab
end)
UI.CreateButton(MiscPage, "重新连接当前服务器", function()
	TeleportService:TeleportToPlaceInstance(game.PlaceId, game.JobId, LocalPlayer)
end)

------------------------------------------------------------------------
-- 4. 核心功能运行逻辑
------------------------------------------------------------------------

-- 手机触摸传送
UserInputService.TouchTapInWorld:Connect(function(touchPos, processed)
	if Flags.TouchTP and not processed then
		local unitRay = Camera:ViewportPointToRay(touchPos.X, touchPos.Y)
		local raycastResult = workspace:Raycast(unitRay.Origin, unitRay.Direction * 1000)
		if raycastResult and LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then
			LocalPlayer.Character.HumanoidRootPart.CFrame = CFrame.new(raycastResult.Position + Vector3.new(0, 3, 0))
		end
	end
end)

-- 无限跳
UserInputService.JumpRequest:Connect(function()
	if Flags.InfJump and LocalPlayer.Character and LocalPlayer.Character:FindFirstChildOfClass("Humanoid") then
		LocalPlayer.Character:FindFirstChildOfClass("Humanoid"):ChangeState("Jumping")
	end
end)

-- 逐帧循环
RunService.RenderStepped:Connect(function()
	local char = LocalPlayer.Character
	if not char then return end
	local hrp = char:FindFirstChild("HumanoidRootPart")
	local hum = char:FindFirstChildOfClass("Humanoid")

	-- 1. 飞行
	if Flags.Fly and hrp and hum then
		local moveDir = hum.MoveDirection
		local flyVel = Vector3.zero
		if moveDir.Magnitude > 0 then
			flyVel = (Camera.CFrame.Rotation * moveDir) * Flags.FlySpeed
		end
		if Flags.FlyUp then flyVel = flyVel + Vector3.new(0, Flags.FlySpeed, 0) end
		if Flags.FlyDown then flyVel = flyVel - Vector3.new(0, Flags.FlySpeed, 0) end
		hrp.Velocity = flyVel
	end

	-- 2. 穿墙
	if Flags.Noclip and char then
		for _, part in pairs(char:GetDescendants()) do
			if part:IsA("BasePart") then
				part.CanCollide = false
			end
		end
	end

	-- 3. 速度与跳跃
	if hum then
		if Flags.Speed ~= 16 then hum.WalkSpeed = Flags.Speed end
		if Flags.JumpPower ~= 50 then hum.JumpPower = Flags.JumpPower end
		if Flags.BHop and hum.FloorMaterial ~= Enum.Material.Air and hum.MoveDirection.Magnitude > 0 then
			hum:ChangeState("Jumping")
		end
	end

	-- 4. 自定义速度陀螺自旋
	if Flags.Spinbot and hrp then
		hrp.CFrame = hrp.CFrame * CFrame.Angles(0, math.rad(Flags.SpinSpeed), 0)
	end

	-- 5. 全局夜视 (只在开启时持续生效)
	if Flags.FullBright then
		Lighting.Ambient = Color3.fromRGB(255, 255, 255)
		Lighting.OutdoorAmbient = Color3.fromRGB(255, 255, 255)
		Lighting.Brightness = 2
	end

	-- 6. ESP 透视
	if Flags.ESP then
		for _, p in pairs(Players:GetPlayers()) do
			if p ~= LocalPlayer and p.Character and not p.Character:FindFirstChild("Highlight") then
				local hl = Instance.new("Highlight")
				hl.Name = "Highlight"
				hl.FillColor = Color3.fromRGB(255, 85, 127)
				hl.OutlineColor = Color3.fromRGB(255, 255, 255)
				hl.Parent = p.Character
			end
		end
	end

	-- 7. 手机自瞄
	if Flags.Aimbot then
		local closestChar = nil
		local shortestDistance = math.huge
		local screenCenter = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y / 2)

		for _, p in pairs(Players:GetPlayers()) do
			if p ~= LocalPlayer and p.Character and p.Character:FindFirstChild("Head") then
				local pos, onScreen = Camera:WorldToViewportPoint(p.Character.Head.Position)
				if onScreen then
					local dist = (Vector2.new(pos.X, pos.Y) - screenCenter).Magnitude
					if dist < shortestDistance then
						shortestDistance = dist
						closestChar = p.Character
					end
				end
			end
		end

		if closestChar and closestChar:FindFirstChild("Head") then
			Camera.CFrame = CFrame.new(Camera.CFrame.Position, closestChar.Head.Position)
		end
	end
end)

-- 防挂机
LocalPlayer.Idled:Connect(function()
	if Flags.AntiAFK then
		local VirtualUser = game:GetService("VirtualUser")
		VirtualUser:CaptureController()
		VirtualUser:ClickButton2(Vector2.zero)
	end
end)

print("[DARK HUB v2] 超圆角 UI & 手机优化版载入成功！")
