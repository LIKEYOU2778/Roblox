--[[
    Roblox 模拟作弊菜单 (手机版)
    功能：飞行、穿墙、加速、超级跳跃、无限跳跃、上帝模式、自愈、无限耐力、
          无后坐力、快速换弹、自动瞄准、透视ESP、显示玩家名字、击杀光环、
          夜视、移除迷雾、时间控制、角色大小、隐形、自动拾取、FOV调节、
          第三人称距离、重力调节、飞行速度调节、瞬移距离调节等。
    说明：纯客户端脚本，效果仅本地可见，适合模拟作弊服务器。
]]

-- 服务
local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local Workspace = game:GetService("Workspace")
local Lighting = game:GetService("Lighting")
local Camera = Workspace.CurrentCamera

local LocalPlayer = Players.LocalPlayer
local Character = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
local Humanoid = Character:WaitForChild("Humanoid")
local RootPart = Character:WaitForChild("HumanoidRootPart")

-- 功能状态表
local Features = {
    Fly = false,
    Noclip = false,
    SpeedBoost = false,
    SuperJump = false,
    InfiniteJump = false,
    GodMode = false,
    AutoHeal = false,
    InfiniteStamina = false,
    NoRecoil = false,
    FastReload = false,
    Aimbot = false,
    ESP = false,
    NameTags = false,
    KillAura = false,
    NightVision = false,
    RemoveFog = false,
    TimeControl = false,
    CharacterScale = false,
    Invisible = false,
    AutoPickup = false,
}

-- 飞行相关变量
local flyVelocity = nil
local flyGyro = nil
local flySpeed = 50
local flyConnection = nil

-- 无限跳跃连接
local infiniteJumpConnection = nil

-- 自动治疗连接
local autoHealConnection = nil

-- 自动瞄准连接
local aimbotConnection = nil

-- 透视ESP存储
local espHighlights = {}

-- 名字标签存储
local nameTags = {}

-- 击杀光环连接
local killAuraConnection = nil

-- 颜色定义
local Colors = {
    Background = Color3.fromRGB(25, 25, 35),
    Secondary = Color3.fromRGB(35, 35, 50),
    Accent = Color3.fromRGB(80, 140, 255),
    AccentDark = Color3.fromRGB(50, 100, 200),
    Text = Color3.fromRGB(255, 255, 255),
    Danger = Color3.fromRGB(255, 80, 80),
    Success = Color3.fromRGB(80, 200, 120),
    Warning = Color3.fromRGB(255, 200, 80),
    Disabled = Color3.fromRGB(120, 120, 130),
}

-- 创建主界面
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "CheatMenu"
ScreenGui.IgnoreGuiInset = true
ScreenGui.ResetOnSpawn = false
ScreenGui.Parent = LocalPlayer:WaitForChild("PlayerGui")

-- 主面板
local MainFrame = Instance.new("Frame")
MainFrame.Name = "MainFrame"
MainFrame.Size = UDim2.new(0, 320, 0, 480)
MainFrame.Position = UDim2.new(0.5, -160, 0.5, -240)
MainFrame.BackgroundColor3 = Colors.Background
MainFrame.BorderSizePixel = 0
MainFrame.Active = true
MainFrame.Draggable = false
MainFrame.ClipsDescendants = true
MainFrame.Parent = ScreenGui

-- 圆角
local MainCorner = Instance.new("UICorner")
MainCorner.CornerRadius = UDim.new(0, 12)
MainCorner.Parent = MainFrame

-- 边框
local MainStroke = Instance.new("UIStroke")
MainStroke.Color = Colors.Accent
MainStroke.Thickness = 1.5
MainStroke.Transparency = 0.3
MainStroke.Parent = MainFrame

-- 标题栏
local TitleBar = Instance.new("Frame")
TitleBar.Name = "TitleBar"
TitleBar.Size = UDim2.new(1, 0, 0, 44)
TitleBar.BackgroundColor3 = Colors.Secondary
TitleBar.BorderSizePixel = 0
TitleBar.Parent = MainFrame

local TitleCorner = Instance.new("UICorner")
TitleCorner.CornerRadius = UDim.new(0, 12)
TitleCorner.Parent = TitleBar

-- 标题文本
local TitleText = Instance.new("TextLabel")
TitleText.Size = UDim2.new(0, 180, 1, 0)
TitleText.Position = UDim2.new(0, 12, 0, 0)
TitleText.BackgroundTransparency = 1
TitleText.Font = Enum.Font.GothamBold
TitleText.Text = "🌟 作弊菜单"
TitleText.TextColor3 = Colors.Text
TitleText.TextSize = 18
TitleText.TextXAlignment = Enum.TextXAlignment.Left
TitleText.Parent = TitleBar

-- 最小化按钮
local MinimizeButton = Instance.new("TextButton")
MinimizeButton.Size = UDim2.new(0, 30, 0, 30)
MinimizeButton.Position = UDim2.new(1, -70, 0.5, -15)
MinimizeButton.BackgroundColor3 = Colors.Secondary
MinimizeButton.BorderSizePixel = 0
MinimizeButton.Text = "—"
MinimizeButton.Font = Enum.Font.GothamBold
MinimizeButton.TextColor3 = Colors.Text
MinimizeButton.TextSize = 20
MinimizeButton.Parent = TitleBar

local MinimizeCorner = Instance.new("UICorner")
MinimizeCorner.CornerRadius = UDim.new(0, 6)
MinimizeCorner.Parent = MinimizeButton

-- 关闭按钮
local CloseButton = Instance.new("TextButton")
CloseButton.Size = UDim2.new(0, 30, 0, 30)
CloseButton.Position = UDim2.new(1, -32, 0.5, -15)
CloseButton.BackgroundColor3 = Colors.Danger
CloseButton.BorderSizePixel = 0
CloseButton.Text = "✕"
CloseButton.Font = Enum.Font.GothamBold
CloseButton.TextColor3 = Colors.Text
CloseButton.TextSize = 16
CloseButton.Parent = TitleBar

local CloseCorner = Instance.new("UICorner")
CloseCorner.CornerRadius = UDim.new(0, 6)
CloseCorner.Parent = CloseButton

-- 拖动检测器
local DragDetector = Instance.new("DragDetector")
DragDetector.Name = "DragDetector"
DragDetector.Parent = TitleBar
DragDetector.Enabled = true

-- 主体滚动区域
local ScrollFrame = Instance.new("ScrollingFrame")
ScrollFrame.Size = UDim2.new(1, 0, 1, -44)
ScrollFrame.Position = UDim2.new(0, 0, 0, 44)
ScrollFrame.BackgroundTransparency = 1
ScrollFrame.BorderSizePixel = 0
ScrollFrame.ScrollBarThickness = 4
ScrollFrame.ScrollBarImageColor3 = Colors.Accent
ScrollFrame.CanvasSize = UDim2.new(0, 0, 0, 1200)
ScrollFrame.Parent = MainFrame

-- 内容布局
local ContentList = Instance.new("UIListLayout")
ContentList.Padding = UDim.new(0, 8)
ContentList.HorizontalAlignment = Enum.HorizontalAlignment.Center
ContentList.SortOrder = Enum.SortOrder.LayoutOrder
ContentList.Parent = ScrollFrame

-- 用于存储功能的引用
local function CreateSection(title, order)
    local Section = Instance.new("Frame")
    Section.Name = title
    Section.Size = UDim2.new(1, -16, 0, 36)
    Section.BackgroundColor3 = Colors.Secondary
    Section.BorderSizePixel = 0
    Section.LayoutOrder = order
    Section.Parent = ScrollFrame

    local SectionCorner = Instance.new("UICorner")
    SectionCorner.CornerRadius = UDim.new(0, 8)
    SectionCorner.Parent = Section

    local SectionText = Instance.new("TextLabel")
    SectionText.Size = UDim2.new(1, -10, 1, 0)
    SectionText.Position = UDim2.new(0, 10, 0, 0)
    SectionText.BackgroundTransparency = 1
    SectionText.Font = Enum.Font.GothamBold
    SectionText.Text = title
    SectionText.TextColor3 = Colors.Text
    SectionText.TextSize = 14
    SectionText.TextXAlignment = Enum.TextXAlignment.Left
    SectionText.Parent = Section

    return Section
end

local function CreateToggleButton(name, order, parent, defaultState)
    local Button = Instance.new("TextButton")
    Button.Name = name
    Button.Size = UDim2.new(1, -16, 0, 42)
    Button.BackgroundColor3 = defaultState and Colors.Accent or Colors.Secondary
    Button.BorderSizePixel = 0
    Button.Text = (defaultState and "✅ " or "❌ ") .. name
    Button.Font = Enum.Font.Gotham
    Button.TextColor3 = Colors.Text
    Button.TextSize = 14
    Button.LayoutOrder = order
    Button.Parent = parent

    local Corner = Instance.new("UICorner")
    Corner.CornerRadius = UDim.new(0, 8)
    Corner.Parent = Button

    local Stroke = Instance.new("UIStroke")
    Stroke.Color = Colors.Accent
    Stroke.Thickness = 1
    Stroke.Transparency = 0.7
    Stroke.Parent = Button

    return Button
end

local function CreateSlider(name, order, parent, min, max, default, callback)
    local Frame = Instance.new("Frame")
    Frame.Name = name .. "_SliderFrame"
    Frame.Size = UDim2.new(1, -16, 0, 56)
    Frame.BackgroundColor3 = Colors.Secondary
    Frame.BorderSizePixel = 0
    Frame.LayoutOrder = order
    Frame.Parent = parent

    local Corner = Instance.new("UICorner")
    Corner.CornerRadius = UDim.new(0, 8)
    Corner.Parent = Frame

    local Label = Instance.new("TextLabel")
    Label.Size = UDim2.new(1, -20, 0, 20)
    Label.Position = UDim2.new(0, 10, 0, 2)
    Label.BackgroundTransparency = 1
    Label.Font = Enum.Font.Gotham
    Label.Text = name .. ": " .. default
    Label.TextColor3 = Colors.Text
    Label.TextSize = 13
    Label.TextXAlignment = Enum.TextXAlignment.Left
    Label.Parent = Frame

    local Slider = Instance.new("TextButton")
    Slider.Name = name .. "_Slider"
    Slider.Size = UDim2.new(1, -20, 0, 6)
    Slider.Position = UDim2.new(0, 10, 0, 28)
    Slider.BackgroundColor3 = Colors.AccentDark
    Slider.BorderSizePixel = 0
    Slider.Text = ""
    Slider.Parent = Frame

    local SliderCorner = Instance.new("UICorner")
    SliderCorner.CornerRadius = UDim.new(0, 3)
    SliderCorner.Parent = Slider

    local Fill = Instance.new("Frame")
    Fill.Name = "Fill"
    Fill.Size = UDim2.new(0, 0, 1, 0)
    Fill.BackgroundColor3 = Colors.Accent
    Fill.BorderSizePixel = 0
    Fill.Parent = Slider

    local FillCorner = Instance.new("UICorner")
    FillCorner.CornerRadius = UDim.new(0, 3)
    FillCorner.Parent = Fill

    -- 触摸处理
    local function UpdateFromInput(input)
        local relativeX = (input.Position.X - Slider.AbsolutePosition.X) / Slider.AbsoluteSize.X
        relativeX = math.clamp(relativeX, 0, 1)
        local value = min + (max - min) * relativeX
        value = math.floor(value * 100) / 100
        Fill.Size = UDim2.new(relativeX, 0, 1, 0)
        Label.Text = name .. ": " .. value
        callback(value)
    end

    Slider.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.Touch or input.UserInputType == Enum.UserInputType.MouseButton1 then
            UpdateFromInput(input)
            local connection
            connection = UserInputService.InputChanged:Connect(function(changedInput)
                if changedInput.UserInputType == Enum.UserInputType.Touch or changedInput.UserInputType == Enum.UserInputType.MouseMovement then
                    UpdateFromInput(changedInput)
                end
            end)
            UserInputService.InputEnded:Connect(function(endedInput)
                if endedInput.UserInputType == Enum.UserInputType.Touch or endedInput.UserInputType == Enum.UserInputType.MouseButton1 then
                    connection:Disconnect()
                end
            end)
        end
    end)

    return Frame
end

-- 创建所有功能
local orderIndex = 0

-- 移动分类
orderIndex = orderIndex + 1
CreateSection("🚀 移动", orderIndex)

-- 飞行
orderIndex = orderIndex + 1
local FlyButton = CreateToggleButton("飞行", orderIndex, ScrollFrame, false)
FlyButton.MouseButton1Click:Connect(function()
    Features.Fly = not Features.Fly
    FlyButton.Text = (Features.Fly and "✅ " or "❌ ") .. "飞行"
    FlyButton.BackgroundColor3 = Features.Fly and Colors.Accent or Colors.Secondary
    if Features.Fly then
        StartFly()
    else
        StopFly()
    end
end)

-- 穿墙
orderIndex = orderIndex + 1
local NoclipButton = CreateToggleButton("穿墙", orderIndex, ScrollFrame, false)
NoclipButton.MouseButton1Click:Connect(function()
    Features.Noclip = not Features.Noclip
    NoclipButton.Text = (Features.Noclip and "✅ " or "❌ ") .. "穿墙"
    NoclipButton.BackgroundColor3 = Features.Noclip and Colors.Accent or Colors.Secondary
    if Features.Noclip then
        EnableNoclip()
    else
        DisableNoclip()
    end
end)

-- 加速
orderIndex = orderIndex + 1
local SpeedBoostButton = CreateToggleButton("加速", orderIndex, ScrollFrame, false)
SpeedBoostButton.MouseButton1Click:Connect(function()
    Features.SpeedBoost = not Features.SpeedBoost
    SpeedBoostButton.Text = (Features.SpeedBoost and "✅ " or "❌ ") .. "加速"
    SpeedBoostButton.BackgroundColor3 = Features.SpeedBoost and Colors.Accent or Colors.Secondary
    if Features.SpeedBoost then
        Humanoid.WalkSpeed = 50
    else
        Humanoid.WalkSpeed = 16
    end
end)

-- 超级跳跃
orderIndex = orderIndex + 1
local SuperJumpButton = CreateToggleButton("超级跳跃", orderIndex, ScrollFrame, false)
SuperJumpButton.MouseButton1Click:Connect(function()
    Features.SuperJump = not Features.SuperJump
    SuperJumpButton.Text = (Features.SuperJump and "✅ " or "❌ ") .. "超级跳跃"
    SuperJumpButton.BackgroundColor3 = Features.SuperJump and Colors.Accent or Colors.Secondary
    if Features.SuperJump then
        Humanoid.JumpPower = 100
    else
        Humanoid.JumpPower = 50
    end
end)

-- 无限跳跃
orderIndex = orderIndex + 1
local InfiniteJumpButton = CreateToggleButton("无限跳跃", orderIndex, ScrollFrame, false)
InfiniteJumpButton.MouseButton1Click:Connect(function()
    Features.InfiniteJump = not Features.InfiniteJump
    InfiniteJumpButton.Text = (Features.InfiniteJump and "✅ " or "❌ ") .. "无限跳跃"
    InfiniteJumpButton.BackgroundColor3 = Features.InfiniteJump and Colors.Accent or Colors.Secondary
    if Features.InfiniteJump then
        EnableInfiniteJump()
    else
        DisableInfiniteJump()
    end
end)

-- 飞行速度滑块
orderIndex = orderIndex + 1
CreateSlider("飞行速度", orderIndex, ScrollFrame, 10, 200, 50, function(value)
    flySpeed = value
end)

-- 重力滑块
orderIndex = orderIndex + 1
CreateSlider("重力", orderIndex, ScrollFrame, 0, 196.2, 196.2, function(value)
    Workspace.Gravity = value
end)

-- 战斗分类
orderIndex = orderIndex + 1
CreateSection("⚔️ 战斗", orderIndex)

-- 上帝模式
orderIndex = orderIndex + 1
local GodModeButton = CreateToggleButton("上帝模式", orderIndex, ScrollFrame, false)
GodModeButton.MouseButton1Click:Connect(function()
    Features.GodMode = not Features.GodMode
    GodModeButton.Text = (Features.GodMode and "✅ " or "❌ ") .. "上帝模式"
    GodModeButton.BackgroundColor3 = Features.GodMode and Colors.Accent or Colors.Secondary
    if Features.GodMode then
        Humanoid.MaxHealth = math.huge
        Humanoid.Health = math.huge
        Humanoid.HealthChanged:Connect(function(health)
            if Features.GodMode and health < math.huge then
                Humanoid.Health = math.huge
            end
        end)
    else
        Humanoid.MaxHealth = 100
        Humanoid.Health = 100
    end
end)

-- 自愈
orderIndex = orderIndex + 1
local AutoHealButton = CreateToggleButton("自愈", orderIndex, ScrollFrame, false)
AutoHealButton.MouseButton1Click:Connect(function()
    Features.AutoHeal = not Features.AutoHeal
    AutoHealButton.Text = (Features.AutoHeal and "✅ " or "❌ ") .. "自愈"
    AutoHealButton.BackgroundColor3 = Features.AutoHeal and Colors.Accent or Colors.Secondary
    if Features.AutoHeal then
        EnableAutoHeal()
    else
        DisableAutoHeal()
    end
end)

-- 无限耐力
orderIndex = orderIndex + 1
local InfiniteStaminaButton = CreateToggleButton("无限耐力", orderIndex, ScrollFrame, false)
InfiniteStaminaButton.MouseButton1Click:Connect(function()
    Features.InfiniteStamina = not Features.InfiniteStamina
    InfiniteStaminaButton.Text = (Features.InfiniteStamina and "✅ " or "❌ ") .. "无限耐力"
    InfiniteStaminaButton.BackgroundColor3 = Features.InfiniteStamina and Colors.Accent or Colors.Secondary
    if Features.InfiniteStamina then
        Humanoid.MaxStamina = math.huge
        Humanoid.Stamina = math.huge
    else
        Humanoid.MaxStamina = 100
        Humanoid.Stamina = 100
    end
end)

-- 无后坐力
orderIndex = orderIndex + 1
local NoRecoilButton = CreateToggleButton("无后坐力", orderIndex, ScrollFrame, false)
NoRecoilButton.MouseButton1Click:Connect(function()
    Features.NoRecoil = not Features.NoRecoil
    NoRecoilButton.Text = (Features.NoRecoil and "✅ " or "❌ ") .. "无后坐力"
    NoRecoilButton.BackgroundColor3 = Features.NoRecoil and Colors.Accent or Colors.Secondary
    -- 需要游戏工具支持，此处仅模拟提示
    if Features.NoRecoil then
        print("无后坐力已开启（需游戏武器支持）")
    end
end)

-- 快速换弹
orderIndex = orderIndex + 1
local FastReloadButton = CreateToggleButton("快速换弹", orderIndex, ScrollFrame, false)
FastReloadButton.MouseButton1Click:Connect(function()
    Features.FastReload = not Features.FastReload
    FastReloadButton.Text = (Features.FastReload and "✅ " or "❌ ") .. "快速换弹"
    FastReloadButton.BackgroundColor3 = Features.FastReload and Colors.Accent or Colors.Secondary
    if Features.FastReload then
        print("快速换弹已开启（需游戏武器支持）")
    end
end)

-- 自动瞄准
orderIndex = orderIndex + 1
local AimbotButton = CreateToggleButton("自动瞄准", orderIndex, ScrollFrame, false)
AimbotButton.MouseButton1Click:Connect(function()
    Features.Aimbot = not Features.Aimbot
    AimbotButton.Text = (Features.Aimbot and "✅ " or "❌ ") .. "自动瞄准"
    AimbotButton.BackgroundColor3 = Features.Aimbot and Colors.Accent or Colors.Secondary
    if Features.Aimbot then
        EnableAimbot()
    else
        DisableAimbot()
    end
end)

-- 击杀光环
orderIndex = orderIndex + 1
local KillAuraButton = CreateToggleButton("击杀光环", orderIndex, ScrollFrame, false)
KillAuraButton.MouseButton1Click:Connect(function()
    Features.KillAura = not Features.KillAura
    KillAuraButton.Text = (Features.KillAura and "✅ " or "❌ ") .. "击杀光环"
    KillAuraButton.BackgroundColor3 = Features.KillAura and Colors.Accent or Colors.Secondary
    if Features.KillAura then
        EnableKillAura()
    else
        DisableKillAura()
    end
end)

-- 视觉分类
orderIndex = orderIndex + 1
CreateSection("👁️ 视觉", orderIndex)

-- 透视ESP
orderIndex = orderIndex + 1
local ESPButton = CreateToggleButton("透视ESP", orderIndex, ScrollFrame, false)
ESPButton.MouseButton1Click:Connect(function()
    Features.ESP = not Features.ESP
    ESPButton.Text = (Features.ESP and "✅ " or "❌ ") .. "透视ESP"
    ESPButton.BackgroundColor3 = Features.ESP and Colors.Accent or Colors.Secondary
    if Features.ESP then
        EnableESP()
    else
        DisableESP()
    end
end)

-- 显示玩家名字
orderIndex = orderIndex + 1
local NameTagsButton = CreateToggleButton("显示玩家名字", orderIndex, ScrollFrame, false)
NameTagsButton.MouseButton1Click:Connect(function()
    Features.NameTags = not Features.NameTags
    NameTagsButton.Text = (Features.NameTags and "✅ " or "❌ ") .. "显示玩家名字"
    NameTagsButton.BackgroundColor3 = Features.NameTags and Colors.Accent or Colors.Secondary
    if Features.NameTags then
        EnableNameTags()
    else
        DisableNameTags()
    end
end)

-- 夜视
orderIndex = orderIndex + 1
local NightVisionButton = CreateToggleButton("夜视", orderIndex, ScrollFrame, false)
NightVisionButton.MouseButton1Click:Connect(function()
    Features.NightVision = not Features.NightVision
    NightVisionButton.Text = (Features.NightVision and "✅ " or "❌ ") .. "夜视"
    NightVisionButton.BackgroundColor3 = Features.NightVision and Colors.Accent or Colors.Secondary
    if Features.NightVision then
        Lighting.Ambient = Color3.new(1, 1, 1)
        Lighting.Brightness = 2
        Lighting.ColorShift_Top = Color3.new(1, 1, 1)
        Lighting.ColorShift_Bottom = Color3.new(1, 1, 1)
    else
        Lighting.Ambient = Color3.new(0, 0, 0)
        Lighting.Brightness = 1
        Lighting.ColorShift_Top = Color3.new(0, 0, 0)
        Lighting.ColorShift_Bottom = Color3.new(0, 0, 0)
    end
end)

-- 移除迷雾
orderIndex = orderIndex + 1
local RemoveFogButton = CreateToggleButton("移除迷雾", orderIndex, ScrollFrame, false)
RemoveFogButton.MouseButton1Click:Connect(function()
    Features.RemoveFog = not Features.RemoveFog
    RemoveFogButton.Text = (Features.RemoveFog and "✅ " or "❌ ") .. "移除迷雾"
    RemoveFogButton.BackgroundColor3 = Features.RemoveFog and Colors.Accent or Colors.Secondary
    if Features.RemoveFog then
        Lighting.FogEnd = 10000
        Lighting.FogStart = 0
    else
        Lighting.FogEnd = 1000
        Lighting.FogStart = 0
    end
end)

-- 角色大小
orderIndex = orderIndex + 1
local CharacterScaleButton = CreateToggleButton("角色大小", orderIndex, ScrollFrame, false)
CharacterScaleButton.MouseButton1Click:Connect(function()
    Features.CharacterScale = not Features.CharacterScale
    CharacterScaleButton.Text = (Features.CharacterScale and "✅ " or "❌ ") .. "角色大小"
    CharacterScaleButton.BackgroundColor3 = Features.CharacterScale and Colors.Accent or Colors.Secondary
    if Features.CharacterScale then
        SetCharacterScale(1.5)
    else
        SetCharacterScale(1)
    end
end)

-- 隐形
orderIndex = orderIndex + 1
local InvisibleButton = CreateToggleButton("隐形", orderIndex, ScrollFrame, false)
InvisibleButton.MouseButton1Click:Connect(function()
    Features.Invisible = not Features.Invisible
    InvisibleButton.Text = (Features.Invisible and "✅ " or "❌ ") .. "隐形"
    InvisibleButton.BackgroundColor3 = Features.Invisible and Colors.Accent or Colors.Secondary
    if Features.Invisible then
        SetInvisible(true)
    else
        SetInvisible(false)
    end
end)

-- FOV滑块
orderIndex = orderIndex + 1
CreateSlider("视野 FOV", orderIndex, ScrollFrame, 30, 120, 70, function(value)
    Camera.FieldOfView = value
end)

-- 第三人称距离滑块
orderIndex = orderIndex + 1
CreateSlider("第三人称距离", orderIndex, ScrollFrame, 5, 30, 10, function(value)
    LocalPlayer.CameraMaxZoomDistance = value
    LocalPlayer.CameraMinZoomDistance = 0.5
end)

-- 世界分类
orderIndex = orderIndex + 1
CreateSection("🌍 世界", orderIndex)

-- 时间控制
orderIndex = orderIndex + 1
local TimeControlButton = CreateToggleButton("时间控制", orderIndex, ScrollFrame, false)
TimeControlButton.MouseButton1Click:Connect(function()
    Features.TimeControl = not Features.TimeControl
    TimeControlButton.Text = (Features.TimeControl and "✅ " or "❌ ") .. "时间控制"
    TimeControlButton.BackgroundColor3 = Features.TimeControl and Colors.Accent or Colors.Secondary
    if Features.TimeControl then
        Lighting.ClockTime = 12
        Lighting.TimeOfDay = "12:00:00"
    else
        -- 恢复默认
    end
end)

-- 自动拾取
orderIndex = orderIndex + 1
local AutoPickupButton = CreateToggleButton("自动拾取", orderIndex, ScrollFrame, false)
AutoPickupButton.MouseButton1Click:Connect(function()
    Features.AutoPickup = not Features.AutoPickup
    AutoPickupButton.Text = (Features.AutoPickup and "✅ " or "❌ ") .. "自动拾取"
    AutoPickupButton.BackgroundColor3 = Features.AutoPickup and Colors.Accent or Colors.Secondary
    if Features.AutoPickup then
        EnableAutoPickup()
    else
        DisableAutoPickup()
    end
end)

-- 瞬移按钮
orderIndex = orderIndex + 1
local TeleportButton = CreateToggleButton("瞬移（点击瞬移）", orderIndex, ScrollFrame, false)
TeleportButton.MouseButton1Click:Connect(function()
    -- 点击按钮本身瞬移，但按钮会切换状态，这里使用一次性瞬移
    Features.Teleport = not Features.Teleport
    TeleportButton.Text = (Features.Teleport and "✅ " or "❌ ") .. "瞬移（点击瞬移）"
    TeleportButton.BackgroundColor3 = Features.Teleport and Colors.Accent or Colors.Secondary
    if Features.Teleport then
        -- 瞬移到鼠标位置（若触摸则瞬移到前方）
        local mouse = LocalPlayer:GetMouse()
        if mouse then
            local targetPos = mouse.Hit.Position
            RootPart.CFrame = CFrame.new(targetPos + Vector3.new(0, 3, 0))
        end
        Features.Teleport = false
        TeleportButton.Text = "❌ 瞬移（点击瞬移）"
        TeleportButton.BackgroundColor3 = Colors.Secondary
    end
end)

-- 瞬移距离滑块
orderIndex = orderIndex + 1
local TeleportDistance = 10
CreateSlider("瞬移距离", orderIndex, ScrollFrame, 5, 50, 10, function(value)
    TeleportDistance = value
end)

-- 功能实现函数

function StartFly()
    if flyConnection then flyConnection:Disconnect() end
    Humanoid.PlatformStand = true
    flyVelocity = Instance.new("BodyVelocity")
    flyVelocity.Name = "FlyVelocity"
    flyVelocity.MaxForce = Vector3.new(math.huge, math.huge, math.huge)
    flyVelocity.Velocity = Vector3.zero
    flyVelocity.Parent = RootPart

    flyGyro = Instance.new("BodyGyro")
    flyGyro.Name = "FlyGyro"
    flyGyro.MaxTorque = Vector3.new(math.huge, math.huge, math.huge)
    flyGyro.CFrame = RootPart.CFrame
    flyGyro.Parent = RootPart

    flyConnection = RunService.RenderStepped:Connect(function()
        if not Features.Fly or not flyVelocity or not flyGyro then return end
        local moveDirection = Vector3.zero
        if UserInputService:IsKeyDown(Enum.KeyCode.W) or UserInputService:IsKeyDown(Enum.KeyCode.Up) then
            moveDirection = moveDirection + Camera.CFrame.LookVector
        end
        if UserInputService:IsKeyDown(Enum.KeyCode.S) or UserInputService:IsKeyDown(Enum.KeyCode.Down) then
            moveDirection = moveDirection - Camera.CFrame.LookVector
        end
        if UserInputService:IsKeyDown(Enum.KeyCode.A) or UserInputService:IsKeyDown(Enum.KeyCode.Left) then
            moveDirection = moveDirection - Camera.CFrame.RightVector
        end
        if UserInputService:IsKeyDown(Enum.KeyCode.D) or UserInputService:IsKeyDown(Enum.KeyCode.Right) then
            moveDirection = moveDirection + Camera.CFrame.RightVector
        end
        if UserInputService:IsKeyDown(Enum.KeyCode.Space) then
            moveDirection = moveDirection + Vector3.new(0, 1, 0)
        end
        if UserInputService:IsKeyDown(Enum.KeyCode.LeftControl) or UserInputService:IsKeyDown(Enum.KeyCode.LeftShift) then
            moveDirection = moveDirection - Vector3.new(0, 1, 0)
        end
        if moveDirection.Magnitude > 0 then
            moveDirection = moveDirection.Unit
        end
        flyVelocity.Velocity = moveDirection * flySpeed
        flyGyro.CFrame = CFrame.lookAt(RootPart.Position, RootPart.Position + Camera.CFrame.LookVector)
    end)
end

function StopFly()
    if flyConnection then
        flyConnection:Disconnect()
        flyConnection = nil
    end
    if flyVelocity then
        flyVelocity:Destroy()
        flyVelocity = nil
    end
    if flyGyro then
        flyGyro:Destroy()
        flyGyro = nil
    end
    Humanoid.PlatformStand = false
end

function EnableNoclip()
    for _, part in ipairs(Character:GetDescendants()) do
        if part:IsA("BasePart") then
            part.CanCollide = false
        end
    end
end

function DisableNoclip()
    for _, part in ipairs(Character:GetDescendants()) do
        if part:IsA("BasePart") then
            part.CanCollide = true
        end
    end
end

function EnableInfiniteJump()
    infiniteJumpConnection = UserInputService.JumpRequest:Connect(function()
        if Features.InfiniteJump then
            Humanoid:ChangeState(Enum.HumanoidStateType.Jumping)
        end
    end)
end

function DisableInfiniteJump()
    if infiniteJumpConnection then
        infiniteJumpConnection:Disconnect()
        infiniteJumpConnection = nil
    end
end

function EnableAutoHeal()
    autoHealConnection = RunService.Heartbeat:Connect(function()
        if Features.AutoHeal and Character and Humanoid then
            Humanoid.Health = Humanoid.MaxHealth
        end
    end)
end

function DisableAutoHeal()
    if autoHealConnection then
        autoHealConnection:Disconnect()
        autoHealConnection = nil
    end
end

function EnableAimbot()
    aimbotConnection = RunService.RenderStepped:Connect(function()
        if not Features.Aimbot then return end
        local nearestPlayer = nil
        local nearestDistance = math.huge
        for _, player in ipairs(Players:GetPlayers()) do
            if player ~= LocalPlayer and player.Character and player.Character:FindFirstChild("HumanoidRootPart") then
                local distance = (player.Character.HumanoidRootPart.Position - RootPart.Position).Magnitude
                if distance < nearestDistance then
                    nearestDistance = distance
                    nearestPlayer = player
                end
            end
        end
        if nearestPlayer and nearestPlayer.Character then
            local head = nearestPlayer.Character:FindFirstChild("Head")
            if head then
                Camera.CFrame = CFrame.lookAt(Camera.CFrame.Position, head.Position)
            end
        end
    end)
end

function DisableAimbot()
    if aimbotConnection then
        aimbotConnection:Disconnect()
        aimbotConnection = nil
    end
end

function EnableESP()
    DisableESP()
    for _, player in ipairs(Players:GetPlayers()) do
        if player ~= LocalPlayer and player.Character then
            local highlight = Instance.new("Highlight")
            highlight.Name = "ESPHighlight_" .. player.Name
            highlight.FillColor = Color3.fromRGB(255, 0, 0)
            highlight.FillTransparency = 0.5
            highlight.OutlineColor = Color3.fromRGB(255, 0, 0)
            highlight.OutlineTransparency = 0
            highlight.Parent = player.Character
            espHighlights[player.Name] = highlight
        end
    end
end

function DisableESP()
    for _, highlight in pairs(espHighlights) do
        if highlight then
            highlight:Destroy()
        end
    end
    espHighlights = {}
end

function EnableNameTags()
    DisableNameTags()
    for _, player in ipairs(Players:GetPlayers()) do
        if player ~= LocalPlayer and player.Character then
            local head = player.Character:FindFirstChild("Head")
            if head then
                local billboard = Instance.new("BillboardGui")
                billboard.Name = "NameTag_" .. player.Name
                billboard.Size = UDim2.new(0, 100, 0, 30)
                billboard.StudsOffset = Vector3.new(0, 2, 0)
                billboard.AlwaysOnTop = true
                billboard.Parent = head

                local label = Instance.new("TextLabel")
                label.Size = UDim2.new(1, 0, 1, 0)
                label.BackgroundTransparency = 0.5
                label.BackgroundColor3 = Colors.Background
                label.TextColor3 = Colors.Text
                label.Font = Enum.Font.GothamBold
                label.TextSize = 14
                label.Text = player.Name
                label.Parent = billboard

                local corner = Instance.new("UICorner")
                corner.CornerRadius = UDim.new(0, 4)
                corner.Parent = label

                nameTags[player.Name] = billboard
            end
        end
    end
end

function DisableNameTags()
    for _, tag in pairs(nameTags) do
        if tag then
            tag:Destroy()
        end
    end
    nameTags = {}
end

function EnableKillAura()
    killAuraConnection = RunService.Heartbeat:Connect(function()
        if not Features.KillAura then return end
        for _, player in ipairs(Players:GetPlayers()) do
            if player ~= LocalPlayer and player.Character and player.Character:FindFirstChild("Humanoid") then
                local distance = (player.Character.HumanoidRootPart.Position - RootPart.Position).Magnitude
                if distance < 15 then
                    -- 客户端无法直接伤害其他玩家，此处仅模拟
                    -- 可以发射射线或使用爆炸，但需要服务器配合
                    print("击杀光环检测到目标: " .. player.Name)
                end
            end
        end
    end)
end

function DisableKillAura()
    if killAuraConnection then
        killAuraConnection:Disconnect()
        killAuraConnection = nil
    end
end

function SetCharacterScale(scale)
    for _, part in ipairs(Character:GetDescendants()) do
        if part:IsA("BasePart") then
            part.Size = part.Size * scale
        end
    end
    Humanoid.HipHeight = Humanoid.HipHeight * scale
end

function SetInvisible(state)
    for _, part in ipairs(Character:GetDescendants()) do
        if part:IsA("BasePart") then
            part.Transparency = state and 0.9 or 0
        end
    end
end

function EnableAutoPickup()
    -- 自动拾取需要服务器支持，此处仅模拟
    print("自动拾取已开启（需游戏支持）")
end

function DisableAutoPickup()
    print("自动拾取已关闭")
end

-- 拖动处理
DragDetector.DragStart:Connect(function()
    -- 可选：添加拖动时的视觉反馈
end)

DragDetector.DragContinue:Connect(function(dragData)
    local newPosition = MainFrame.Position + UDim2.new(0, dragData.Delta.X, 0, dragData.Delta.Y)
    MainFrame.Position = newPosition
end)

-- 最小化/关闭按钮
MinimizeButton.MouseButton1Click:Connect(function()
    if ScrollFrame.Visible then
        ScrollFrame.Visible = false
        MainFrame.Size = UDim2.new(0, 320, 0, 44)
        MainFrame.Position = UDim2.new(0.5, -160, 0.5, -22)
    else
        ScrollFrame.Visible = true
        MainFrame.Size = UDim2.new(0, 320, 0, 480)
        MainFrame.Position = UDim2.new(0.5, -160, 0.5, -240)
    end
end)

CloseButton.MouseButton1Click:Connect(function()
    ScreenGui:Destroy()
end)

-- 角色重生后重新绑定
LocalPlayer.CharacterAdded:Connect(function(newCharacter)
    Character = newCharacter
    Humanoid = Character:WaitForChild("Humanoid")
    RootPart = Character:WaitForChild("HumanoidRootPart")
    -- 如果某些功能开启，重新应用
    if Features.Fly then
        StopFly()
        StartFly()
    end
    if Features.Noclip then
        EnableNoclip()
    end
    if Features.SpeedBoost then
        Humanoid.WalkSpeed = 50
    end
    if Features.SuperJump then
        Humanoid.JumpPower = 100
    end
    if Features.GodMode then
        Humanoid.MaxHealth = math.huge
        Humanoid.Health = math.huge
    end
    if Features.InfiniteStamina then
        Humanoid.MaxStamina = math.huge
        Humanoid.Stamina = math.huge
    end
    if Features.ESP then
        EnableESP()
    end
    if Features.NameTags then
        EnableNameTags()
    end
    if Features.Invisible then
        SetInvisible(true)
    end
end)

-- 初始应用
if Features.Fly then StartFly() end
if Features.Noclip then EnableNoclip() end
if Features.SpeedBoost then Humanoid.WalkSpeed = 50 end
if Features.SuperJump then Humanoid.JumpPower = 100 end
if Features.GodMode then
    Humanoid.MaxHealth = math.huge
    Humanoid.Health = math.huge
end
if Features.InfiniteStamina then
    Humanoid.MaxStamina = math.huge
    Humanoid.Stamina = math.huge
end
if Features.ESP then EnableESP() end
if Features.NameTags then EnableNameTags() end
if Features.Invisible then SetInvisible(true) end

print("作弊菜单已加载，欢迎使用！")