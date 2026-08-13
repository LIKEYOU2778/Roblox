-- StarterPlayerScripts/MobileSandbox.client.lua
-- 仅用于自己的 Roblox Experience

local Players = game:GetService('Players')
local RunService = game:GetService('RunService')
local TweenService = game:GetService('TweenService')
local UserInputService = game:GetService('UserInputService')
local Lighting = game:GetService('Lighting')
local Workspace = game:GetService('Workspace')

local Player = Players.LocalPlayer

-- 群组拥有的游戏请填写测试者 UserId
local ALLOWED_USER_IDS = {
    -- [123456789] = true,
}

local allowed = RunService:IsStudio()
    or (game.CreatorType == Enum.CreatorType.User and game.CreatorId == Player.UserId)
    or game.PrivateServerOwnerId == Player.UserId
    or ALLOWED_USER_IDS[Player.UserId] == true

if not allowed then
    return
end

local WALK_SPEED = 30
local FLY_SPEED = 55
local MAX_TP_DISTANCE = 500

local State = {
    Fly = false,
    Noclip = false,
    Speed = false,
    InfJump = false,
    ESP = false,
    Fullbright = false,
    FOV = false,
    NoFog = false,
    TapTP = false,
}

local refreshCards = function() end
local showToast = function() end

local function getCharacter()
    local character = Player.Character
    if not character then
        return nil, nil, nil
    end

    return character,
        character:FindFirstChildOfClass('Humanoid'),
        character:FindFirstChild('HumanoidRootPart')
end

-- 飞行：仅开启时连接 RenderStepped
local flyConnection
local flyAttachment
local flyVelocity
local flyOrientation
local flyHumanoid
local flyRoot
local oldPlatformStand = false
local oldAutoRotate = true
local flyBoostUntil = 0

local function stopFly()
    if flyConnection then
        flyConnection:Disconnect()
        flyConnection = nil
    end

    if flyVelocity then
        flyVelocity:Destroy()
        flyVelocity = nil
    end

    if flyOrientation then
        flyOrientation:Destroy()
        flyOrientation = nil
    end

    if flyAttachment then
        flyAttachment:Destroy()
        flyAttachment = nil
    end

    if flyRoot and flyRoot.Parent then
        flyRoot.AssemblyLinearVelocity = Vector3.zero
    end

    if flyHumanoid and flyHumanoid.Parent then
        flyHumanoid.PlatformStand = oldPlatformStand
        flyHumanoid.AutoRotate = oldAutoRotate
    end

    flyHumanoid = nil
    flyRoot = nil
end

local function startFly()
    stopFly()

    local _, humanoid, root = getCharacter()
    if not humanoid or not root or not root:IsA('BasePart') then
        return
    end

    flyHumanoid = humanoid
    flyRoot = root
    oldPlatformStand = humanoid.PlatformStand
    oldAutoRotate = humanoid.AutoRotate

    humanoid.PlatformStand = true
    humanoid.AutoRotate = false

    flyAttachment = Instance.new('Attachment')
    flyAttachment.Name = 'MobileFlyAttachment'
    flyAttachment.Parent = root

    flyVelocity = Instance.new('LinearVelocity')
    flyVelocity.Attachment0 = flyAttachment
    flyVelocity.RelativeTo = Enum.ActuatorRelativeTo.World
    flyVelocity.VelocityConstraintMode = Enum.VelocityConstraintMode.Vector
    flyVelocity.MaxForce = 1000000
    flyVelocity.VectorVelocity = Vector3.zero
    flyVelocity.Parent = root

    flyOrientation = Instance.new('AlignOrientation')
    flyOrientation.Attachment0 = flyAttachment
    flyOrientation.Mode = Enum.OrientationAlignmentMode.OneAttachment
    flyOrientation.MaxTorque = 1000000
    flyOrientation.Responsiveness = 22
    flyOrientation.Parent = root

    flyConnection = RunService.RenderStepped:Connect(function()
        if not State.Fly or not root.Parent or not humanoid.Parent then
            stopFly()
            return
        end

        local camera = Workspace.CurrentCamera
        if not camera then
            return
        end

        local look = camera.CFrame.LookVector
        local rightVector = camera.CFrame.RightVector
        local flatLook = Vector3.new(look.X, 0, look.Z)
        local flatRight = Vector3.new(rightVector.X, 0, rightVector.Z)

        if flatLook.Magnitude < 0.01 then
            flatLook = Vector3.new(0, 0, -1)
        else
            flatLook = flatLook.Unit
        end

        if flatRight.Magnitude < 0.01 then
            flatRight = Vector3.new(1, 0, 0)
        else
            flatRight = flatRight.Unit
        end

        local move = humanoid.MoveDirection
        local forward = move:Dot(flatLook)
        local sideways = move:Dot(flatRight)
        local vertical = look.Y * forward

        -- 手机原生跳跃键用于短暂上升
        if os.clock() < flyBoostUntil then
            vertical += 1
        end

        local direction = flatLook * forward
            + flatRight * sideways
            + Vector3.new(0, vertical, 0)

        if direction.Magnitude > 1 then
            direction = direction.Unit
        end

        flyVelocity.VectorVelocity = direction * FLY_SPEED
        flyOrientation.CFrame = CFrame.lookAt(Vector3.zero, flatLook)
    end)
end

-- 穿墙：开启时处理已有部件，之后仅处理新增部件
local collisionOriginal = {}
local descendantConnection

local function stopNoclip()
    if descendantConnection then
        descendantConnection:Disconnect()
        descendantConnection = nil
    end

    for part, original in pairs(collisionOriginal) do
        if part.Parent then
            part.CanCollide = original
        end
    end

    table.clear(collisionOriginal)
end

local function startNoclip()
    stopNoclip()

    local character = Player.Character
    if not character then
        return
    end

    local function apply(object)
        if object:IsA('BasePart') then
            if collisionOriginal[object] == nil then
                collisionOriginal[object] = object.CanCollide
            end
            object.CanCollide = false
        end
    end

    for _, object in ipairs(character:GetDescendants()) do
        apply(object)
    end

    descendantConnection = character.DescendantAdded:Connect(apply)
end

-- 角色默认属性
local characterDefaults

local function captureDefaults()
    local _, humanoid = getCharacter()
    if humanoid then
        characterDefaults = {
            Humanoid = humanoid,
            WalkSpeed = humanoid.WalkSpeed,
        }
    end
end

captureDefaults()

-- ESP：使用原生 Highlight，无逐帧绘制
local highlights = {}
local characterConnections = {}

local function removeHighlight(player)
    local highlight = highlights[player]
    if highlight then
        highlight:Destroy()
        highlights[player] = nil
    end
end

local function addHighlight(player)
    if not State.ESP or player == Player then
        return
    end

    removeHighlight(player)

    local character = player.Character
    if not character then
        return
    end

    local highlight = Instance.new('Highlight')
    highlight.Name = 'MobileSandboxHighlight'
    highlight.Adornee = character
    highlight.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
    highlight.FillTransparency = 0.72
    highlight.OutlineTransparency = 0.08
    highlight.FillColor = player.Team and player.TeamColor.Color
        or Color3.fromRGB(124, 105, 255)
    highlight.OutlineColor = Color3.fromRGB(240, 248, 255)
    highlight.Parent = character

    highlights[player] = highlight
end

local function refreshESP()
    for _, highlight in pairs(highlights) do
        highlight:Destroy()
    end
    table.clear(highlights)

    if State.ESP then
        for _, player in ipairs(Players:GetPlayers()) do
            addHighlight(player)
        end
    end
end

local function bindPlayer(player)
    if characterConnections[player] then
        characterConnections[player]:Disconnect()
    end

    characterConnections[player] = player.CharacterAdded:Connect(function()
        task.wait(0.15)
        addHighlight(player)
    end)

    addHighlight(player)
end

for _, player in ipairs(Players:GetPlayers()) do
    bindPlayer(player)
end

Players.PlayerAdded:Connect(bindPlayer)
Players.PlayerRemoving:Connect(function(player)
    removeHighlight(player)

    if characterConnections[player] then
        characterConnections[player]:Disconnect()
        characterConnections[player] = nil
    end
end)

-- 光照与视野备份
local lightingDefault = {
    Brightness = Lighting.Brightness,
    ClockTime = Lighting.ClockTime,
    Ambient = Lighting.Ambient,
    OutdoorAmbient = Lighting.OutdoorAmbient,
    GlobalShadows = Lighting.GlobalShadows,
    FogStart = Lighting.FogStart,
    FogEnd = Lighting.FogEnd,
}

local atmosphereDefaults = {}
for _, object in ipairs(Lighting:GetDescendants()) do
    if object:IsA('Atmosphere') then
        atmosphereDefaults[object] = {
            Density = object.Density,
            Haze = object.Haze,
            Glare = object.Glare,
        }
    end
end

local cameraFOVDefaults = setmetatable({}, {__mode = 'k'})

local function applyLighting()
    if State.Fullbright then
        Lighting.Brightness = 3
        Lighting.ClockTime = 14
        Lighting.Ambient = Color3.fromRGB(190, 200, 215)
        Lighting.OutdoorAmbient = Color3.fromRGB(170, 185, 205)
        Lighting.GlobalShadows = false
    else
        Lighting.Brightness = lightingDefault.Brightness
        Lighting.ClockTime = lightingDefault.ClockTime
        Lighting.Ambient = lightingDefault.Ambient
        Lighting.OutdoorAmbient = lightingDefault.OutdoorAmbient
        Lighting.GlobalShadows = lightingDefault.GlobalShadows
    end

    if State.NoFog then
        Lighting.FogStart = 0
        Lighting.FogEnd = 1000000

        for atmosphere in pairs(atmosphereDefaults) do
            if atmosphere.Parent then
                atmosphere.Density = 0
                atmosphere.Haze = 0
                atmosphere.Glare = 0
            end
        end
    else
        Lighting.FogStart = lightingDefault.FogStart
        Lighting.FogEnd = lightingDefault.FogEnd

        for atmosphere, default in pairs(atmosphereDefaults) do
            if atmosphere.Parent then
                atmosphere.Density = default.Density
                atmosphere.Haze = default.Haze
                atmosphere.Glare = default.Glare
            end
        end
    end
end

local function applyFOV()
    local camera = Workspace.CurrentCamera
    if not camera then
        return
    end

    if cameraFOVDefaults[camera] == nil then
        cameraFOVDefaults[camera] = camera.FieldOfView
    end

    camera.FieldOfView = State.FOV and 100 or cameraFOVDefaults[camera]
end

local function setFeature(key, enabled)
    if State[key] == nil then
        return
    end

    State[key] = enabled

    if key == 'Fly' then
        if enabled then
            startFly()
        else
            stopFly()
        end

    elseif key == 'Noclip' then
        if enabled then
            startNoclip()
        else
            stopNoclip()
        end

    elseif key == 'Speed' then
        local _, humanoid = getCharacter()
        if humanoid then
            if not characterDefaults or characterDefaults.Humanoid ~= humanoid then
                captureDefaults()
            end

            humanoid.WalkSpeed = enabled
                and WALK_SPEED
                or characterDefaults.WalkSpeed
        end

    elseif key == 'ESP' then
        refreshESP()

    elseif key == 'Fullbright' or key == 'NoFog' then
        applyLighting()

    elseif key == 'FOV' then
        applyFOV()
    end

    refreshCards()
end

-- 无限跳跃及飞行上升
UserInputService.JumpRequest:Connect(function()
    if State.Fly then
        flyBoostUntil = os.clock() + 0.22
        return
    end

    if not State.InfJump then
        return
    end

    local _, humanoid = getCharacter()
    if humanoid then
        humanoid:ChangeState(Enum.HumanoidStateType.Jumping)
    end
end)

-- 手机点击传送
UserInputService.TouchTapInWorld:Connect(function(positions, processedByUI)
    if not State.TapTP or processedByUI then
        return
    end

    local camera = Workspace.CurrentCamera
    local touch = positions[1]
    local character, _, root = getCharacter()

    if not camera or not touch or not character or not root then
        return
    end

    local ray = camera:ViewportPointToRay(touch.X, touch.Y)
    local parameters = RaycastParams.new()
    parameters.FilterType = Enum.RaycastFilterType.Exclude
    parameters.FilterDescendantsInstances = {character}

    local result = Workspace:Raycast(
        ray.Origin,
        ray.Direction * 1000,
        parameters
    )

    if not result then
        return
    end

    if (result.Position - root.Position).Magnitude > MAX_TP_DISTANCE then
        showToast('目标距离过远')
        return
    end

    character:PivotTo(
        CFrame.new(result.Position + Vector3.new(0, 3, 0))
            * root.CFrame.Rotation
    )
end)

-- 重生后恢复已开启功能
Player.CharacterAdded:Connect(function()
    stopFly()
    stopNoclip()
    characterDefaults = nil

    task.wait(0.25)
    captureDefaults()

    local _, humanoid = getCharacter()
    if State.Speed and humanoid then
        humanoid.WalkSpeed = WALK_SPEED
    end

    if State.Noclip then
        startNoclip()
    end

    if State.Fly then
        startFly()
    end
end)

local savedCFrame

local function savePoint()
    local _, _, root = getCharacter()
    if root then
        savedCFrame = root.CFrame
        showToast('位置已保存')
    end
end

local function returnPoint()
    local character = Player.Character

    if not character or not savedCFrame then
        showToast('还没有保存位置')
        return
    end

    character:PivotTo(savedCFrame + Vector3.new(0, 3, 0))
    showToast('已返回保存点')
end

local function resetAll()
    for key, enabled in pairs(State) do
        if enabled then
            setFeature(key, false)
        end
    end

    savedCFrame = nil
    showToast('所有效果已恢复')
end

local Pages = {
    {
        title = '移动能力',
        tab = '移动',
        items = {
            {key = 'Fly', label = '飞行', icon = '△', toggle = true},
            {key = 'Noclip', label = '穿墙', icon = '◇', toggle = true},
            {key = 'Speed', label = '疾跑', icon = '»', toggle = true},
            {key = 'InfJump', label = '无限跳', icon = '↟', toggle = true},
        },
    },
    {
        title = '视觉辅助',
        tab = '视觉',
        items = {
            {key = 'ESP', label = '玩家高亮', icon = '◎', toggle = true},
            {key = 'Fullbright', label = '全亮', icon = '☀', toggle = true},
            {key = 'FOV', label = '广角视野', icon = '◫', toggle = true},
            {key = 'NoFog', label = '移除雾气', icon = '≋', toggle = true},
        },
    },
    {
        title = '快捷工具',
        tab = '工具',
        items = {
            {key = 'TapTP', label = '点击传送', icon = '⌖', toggle = true},
            {key = 'Save', label = '保存位置', icon = '+', action = savePoint},
            {key = 'Return', label = '返回位置', icon = '↶', action = returnPoint},
            {key = 'Reset', label = '全部恢复', icon = '!', action = resetAll, danger = true},
        },
    },
}

-- UI
local Theme = {
    Background = Color3.fromRGB(12, 15, 20),
    Surface = Color3.fromRGB(23, 28, 36),
    Active = Color3.fromRGB(23, 43, 43),
    Accent = Color3.fromRGB(77, 235, 199),
    Accent2 = Color3.fromRGB(124, 105, 255),
    Text = Color3.fromRGB(239, 243, 248),
    Muted = Color3.fromRGB(137, 148, 164),
    Stroke = Color3.fromRGB(64, 75, 91),
    Danger = Color3.fromRGB(255, 92, 112),
}

local FAST = TweenInfo.new(0.12, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
local SMOOTH = TweenInfo.new(0.22, Enum.EasingStyle.Quint, Enum.EasingDirection.Out)
local SNAP = TweenInfo.new(0.28, Enum.EasingStyle.Quart, Enum.EasingDirection.Out)

local function tween(object, info, goal)
    local animation = TweenService:Create(object, info, goal)
    animation:Play()
    return animation
end

local function addCorner(parent, radius)
    local corner = Instance.new('UICorner')
    corner.CornerRadius = UDim.new(0, radius)
    corner.Parent = parent
    return corner
end

local function addStroke(parent, color, transparency)
    local stroke = Instance.new('UIStroke')
    stroke.Color = color
    stroke.Transparency = transparency or 0
    stroke.Thickness = 1
    stroke.Parent = parent
    return stroke
end

local Gui = Instance.new('ScreenGui')
Gui.Name = 'MobileSandboxUI'
Gui.ResetOnSpawn = false
Gui.IgnoreGuiInset = false
Gui.DisplayOrder = 50
Gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
Gui.Parent = Player:WaitForChild('PlayerGui')

local Main = Instance.new('CanvasGroup')
Main.Name = 'Main'
Main.BackgroundColor3 = Theme.Background
Main.BorderSizePixel = 0
Main.ClipsDescendants = true
Main.Active = true
Main.Parent = Gui
addCorner(Main, 14)
addStroke(Main, Theme.Stroke, 0.35)

local mainGradient = Instance.new('UIGradient')
mainGradient.Rotation = 125
mainGradient.Color = ColorSequence.new(
    Color3.fromRGB(19, 24, 31),
    Color3.fromRGB(20, 18, 31)
)
mainGradient.Parent = Main

local MainScale = Instance.new('UIScale')
MainScale.Parent = Main

local accentLine = Instance.new('Frame')
accentLine.Size = UDim2.new(1, 0, 0, 2)
accentLine.BackgroundColor3 = Theme.Accent
accentLine.BorderSizePixel = 0
accentLine.ZIndex = 10
accentLine.Parent = Main

local accentGradient = Instance.new('UIGradient')
accentGradient.Color = ColorSequence.new(Theme.Accent, Theme.Accent2)
accentGradient.Parent = accentLine

local Header = Instance.new('Frame')
Header.Size = UDim2.fromScale(1, 0.22)
Header.BackgroundTransparency = 1
Header.Active = true
Header.ZIndex = 3
Header.Parent = Main

local statusDot = Instance.new('Frame')
statusDot.AnchorPoint = Vector2.new(0, 0.5)
statusDot.Size = UDim2.fromOffset(6, 6)
statusDot.Position = UDim2.new(0, 10, 0.5, 0)
statusDot.BackgroundColor3 = Theme.Accent
statusDot.BorderSizePixel = 0
statusDot.ZIndex = 4
statusDot.Parent = Header
addCorner(statusDot, 99)

local PageTitle = Instance.new('TextLabel')
PageTitle.Size = UDim2.new(1, -55, 1, 0)
PageTitle.Position = UDim2.fromOffset(22, 0)
PageTitle.BackgroundTransparency = 1
PageTitle.Font = Enum.Font.GothamBold
PageTitle.Text = 'SANDBOX · 移动能力'
PageTitle.TextColor3 = Theme.Text
PageTitle.TextScaled = true
PageTitle.TextXAlignment = Enum.TextXAlignment.Left
PageTitle.TextTruncate = Enum.TextTruncate.AtEnd
PageTitle.ZIndex = 4
PageTitle.Parent = Header

local titleConstraint = Instance.new('UITextSizeConstraint')
titleConstraint.MinTextSize = 8
titleConstraint.MaxTextSize = 13
titleConstraint.Parent = PageTitle

local CloseButton = Instance.new('TextButton')
CloseButton.Size = UDim2.fromOffset(30, 28)
CloseButton.Position = UDim2.new(1, -34, 0.5, -14)
CloseButton.BackgroundTransparency = 1
CloseButton.AutoButtonColor = false
CloseButton.Font = Enum.Font.GothamBold
CloseButton.Text = '—'
CloseButton.TextColor3 = Theme.Muted
CloseButton.TextSize = 16
CloseButton.ZIndex = 5
CloseButton.Parent = Header

local Content = Instance.new('CanvasGroup')
Content.Size = UDim2.fromScale(1, 0.56)
Content.Position = UDim2.fromScale(0, 0.22)
Content.BackgroundTransparency = 1
Content.ZIndex = 3
Content.Parent = Main

local contentPadding = Instance.new('UIPadding')
contentPadding.PaddingLeft = UDim.new(0, 6)
contentPadding.PaddingRight = UDim.new(0, 6)
contentPadding.PaddingTop = UDim.new(0, 4)
contentPadding.PaddingBottom = UDim.new(0, 4)
contentPadding.Parent = Content

local Grid = Instance.new('UIGridLayout')
Grid.CellSize = UDim2.new(0.5, -3, 0.5, -3)
Grid.CellPadding = UDim2.fromOffset(6, 6)
Grid.SortOrder = Enum.SortOrder.LayoutOrder
Grid.Parent = Content

local Navigation = Instance.new('Frame')
Navigation.Size = UDim2.fromScale(1, 0.22)
Navigation.Position = UDim2.fromScale(0, 0.78)
Navigation.BackgroundColor3 = Color3.fromRGB(9, 12, 16)
Navigation.BackgroundTransparency = 0.18
Navigation.BorderSizePixel = 0
Navigation.ZIndex = 3
Navigation.Parent = Main

local navLine = Instance.new('Frame')
navLine.Size = UDim2.new(1, -12, 0, 1)
navLine.Position = UDim2.fromOffset(6, 0)
navLine.BackgroundColor3 = Theme.Stroke
navLine.BackgroundTransparency = 0.55
navLine.BorderSizePixel = 0
navLine.ZIndex = 4
navLine.Parent = Navigation

local Toast = Instance.new('CanvasGroup')
Toast.AnchorPoint = Vector2.new(0.5, 0.5)
Toast.Size = UDim2.new(0.8, 0, 0, 28)
Toast.Position = UDim2.fromScale(0.5, 0.5)
Toast.BackgroundColor3 = Color3.fromRGB(28, 34, 43)
Toast.BorderSizePixel = 0
Toast.GroupTransparency = 1
Toast.Visible = false
Toast.ZIndex = 30
Toast.Parent = Main
addCorner(Toast, 99)
addStroke(Toast, Theme.Accent, 0.4)

local ToastScale = Instance.new('UIScale')
ToastScale.Parent = Toast

local ToastText = Instance.new('TextLabel')
ToastText.Size = UDim2.new(1, -14, 1, 0)
ToastText.Position = UDim2.fromOffset(7, 0)
ToastText.BackgroundTransparency = 1
ToastText.Font = Enum.Font.GothamMedium
ToastText.TextColor3 = Theme.Text
ToastText.TextScaled = true
ToastText.ZIndex = 31
ToastText.Parent = Toast

local toastConstraint = Instance.new('UITextSizeConstraint')
toastConstraint.MinTextSize = 8
toastConstraint.MaxTextSize = 11
toastConstraint.Parent = ToastText

local toastToken = 0
showToast = function(text)
    toastToken += 1
    local token = toastToken

    ToastText.Text = text
    Toast.Visible = true
    Toast.GroupTransparency = 1
    ToastScale.Scale = 0.94

    tween(Toast, FAST, {GroupTransparency = 0})
    tween(ToastScale, SMOOTH, {Scale = 1})

    task.delay(1.2, function()
        if token ~= toastToken then
            return
        end

        tween(Toast, FAST, {GroupTransparency = 1})
        task.delay(0.13, function()
            if token == toastToken then
                Toast.Visible = false
            end
        end)
    end)
end

local OpenButton = Instance.new('TextButton')
OpenButton.Name = 'OpenButton'
OpenButton.BackgroundColor3 = Color3.fromRGB(18, 23, 30)
OpenButton.BorderSizePixel = 0
OpenButton.AutoButtonColor = false
OpenButton.Font = Enum.Font.GothamBold
OpenButton.Text = '◆'
OpenButton.TextColor3 = Theme.Accent
OpenButton.TextScaled = true
OpenButton.Visible = false
OpenButton.ZIndex = 40
OpenButton.Parent = Gui
addCorner(OpenButton, 99)
addStroke(OpenButton, Theme.Accent, 0.25)

local OpenScale = Instance.new('UIScale')
OpenScale.Parent = OpenButton

local openConstraint = Instance.new('UITextSizeConstraint')
openConstraint.MinTextSize = 14
openConstraint.MaxTextSize = 19
openConstraint.Parent = OpenButton

-- 四张功能卡
local cards = {}

local function paintCard(card)
    local definition = card.definition

    if not definition.toggle then
        card.dot.Visible = false
        card.icon.TextColor3 = definition.danger
            and Theme.Danger
            or Theme.Accent2
        card.stroke.Color = definition.danger
            and Theme.Danger
            or Theme.Stroke
        return
    end

    local enabled = State[definition.key]
    card.dot.Visible = true

    tween(card.button, FAST, {
        BackgroundColor3 = enabled and Theme.Active or Theme.Surface,
    })

    tween(card.stroke, FAST, {
        Color = enabled and Theme.Accent or Theme.Stroke,
        Transparency = enabled and 0.15 or 0.72,
    })

    tween(card.dot, FAST, {
        BackgroundColor3 = enabled and Theme.Accent or Theme.Muted,
        BackgroundTransparency = enabled and 0 or 0.5,
    })

    card.icon.TextColor3 = enabled and Theme.Accent or Theme.Muted
    card.label.TextColor3 = enabled and Theme.Text
        or Color3.fromRGB(205, 212, 222)
end

refreshCards = function()
    for _, card in pairs(cards) do
        paintCard(card)
    end
end

local function clearCards()
    for _, child in ipairs(Content:GetChildren()) do
        if child:IsA('GuiButton') then
            child:Destroy()
        end
    end
    table.clear(cards)
end

local function createCard(definition, order)
    local button = Instance.new('TextButton')
    button.Name = definition.key
    button.LayoutOrder = order
    button.BackgroundColor3 = Theme.Surface
    button.BorderSizePixel = 0
    button.AutoButtonColor = false
    button.Text = ''
    button.ZIndex = 5
    button.Parent = Content
    addCorner(button, 9)

    local stroke = addStroke(button, Theme.Stroke, 0.72)

    local scale = Instance.new('UIScale')
    scale.Parent = button

    local icon = Instance.new('TextLabel')
    icon.Size = UDim2.new(0.3, 0, 1, 0)
    icon.Position = UDim2.fromOffset(5, 0)
    icon.BackgroundTransparency = 1
    icon.Font = Enum.Font.GothamBold
    icon.Text = definition.icon
    icon.TextColor3 = Theme.Muted
    icon.TextScaled = true
    icon.ZIndex = 6
    icon.Parent = button

    local iconConstraint = Instance.new('UITextSizeConstraint')
    iconConstraint.MinTextSize = 10
    iconConstraint.MaxTextSize = 17
    iconConstraint.Parent = icon

    local label = Instance.new('TextLabel')
    label.Size = UDim2.new(0.66, -8, 1, 0)
    label.Position = UDim2.new(0.3, 4, 0, 0)
    label.BackgroundTransparency = 1
    label.Font = Enum.Font.GothamMedium
    label.Text = definition.label
    label.TextColor3 = Color3.fromRGB(205, 212, 222)
    label.TextScaled = true
    label.TextXAlignment = Enum.TextXAlignment.Left
    label.TextTruncate = Enum.TextTruncate.AtEnd
    label.ZIndex = 6
    label.Parent = button

    local labelConstraint = Instance.new('UITextSizeConstraint')
    labelConstraint.MinTextSize = 7
    labelConstraint.MaxTextSize = 11
    labelConstraint.Parent = label

    local dot = Instance.new('Frame')
    dot.AnchorPoint = Vector2.new(1, 0)
    dot.Size = UDim2.fromOffset(5, 5)
    dot.Position = UDim2.new(1, -6, 0, 6)
    dot.BackgroundColor3 = Theme.Muted
    dot.BackgroundTransparency = 0.5
    dot.BorderSizePixel = 0
    dot.ZIndex = 7
    dot.Parent = button
    addCorner(dot, 99)

    local card = {
        button = button,
        stroke = stroke,
        scale = scale,
        icon = icon,
        label = label,
        dot = dot,
        definition = definition,
    }

    cards[definition.key] = card
    paintCard(card)

    button.Activated:Connect(function()
        tween(scale, FAST, {Scale = 0.94})
        task.delay(0.07, function()
            if scale.Parent then
                tween(scale, SMOOTH, {Scale = 1})
            end
        end)

        if definition.toggle then
            setFeature(definition.key, not State[definition.key])
        elseif definition.action then
            definition.action()
        end
    end)
end

local navButtons = {}
local currentPage = 1
local pageToken = 0

local function updateTabs()
    for index, nav in ipairs(navButtons) do
        local selected = index == currentPage

        tween(nav.button, FAST, {
            BackgroundTransparency = selected and 0.3 or 1,
            TextColor3 = selected and Theme.Text or Theme.Muted,
        })

        tween(nav.indicator, FAST, {
            BackgroundTransparency = selected and 0 or 1,
        })
    end
end

local function buildPage(index)
    clearCards()

    local page = Pages[index]
    PageTitle.Text = 'SANDBOX · ' .. page.title

    for order, definition in ipairs(page.items) do
        createCard(definition, order)
    end
end

local function switchPage(index, instant)
    if not Pages[index] then
        return
    end

    currentPage = index
    updateTabs()
    pageToken += 1
    local token = pageToken

    if instant then
        Content.GroupTransparency = 0
        Content.Position = UDim2.fromScale(0, 0.22)
        buildPage(index)
        return
    end

    tween(Content, FAST, {
        GroupTransparency = 1,
        Position = UDim2.new(0, 6, 0.22, 0),
    })

    task.delay(0.12, function()
        if token ~= pageToken then
            return
        end

        buildPage(index)
        Content.Position = UDim2.new(0, -6, 0.22, 0)

        tween(Content, SMOOTH, {
            GroupTransparency = 0,
            Position = UDim2.fromScale(0, 0.22),
        })
    end)
end

for index, page in ipairs(Pages) do
    local button = Instance.new('TextButton')
    button.Size = UDim2.new(1 / #Pages, -4, 1, -8)
    button.Position = UDim2.new((index - 1) / #Pages, 2, 0, 4)
    button.BackgroundColor3 = Theme.Surface
    button.BackgroundTransparency = 1
    button.BorderSizePixel = 0
    button.AutoButtonColor = false
    button.Font = Enum.Font.GothamMedium
    button.Text = page.tab
    button.TextColor3 = Theme.Muted
    button.TextScaled = true
    button.ZIndex = 5
    button.Parent = Navigation
    addCorner(button, 8)

    local textConstraint = Instance.new('UITextSizeConstraint')
    textConstraint.MinTextSize = 7
    textConstraint.MaxTextSize = 10
    textConstraint.Parent = button

    local indicator = Instance.new('Frame')
    indicator.AnchorPoint = Vector2.new(0.5, 1)
    indicator.Size = UDim2.new(0.35, 0, 0, 2)
    indicator.Position = UDim2.new(0.5, 0, 1, -1)
    indicator.BackgroundColor3 = Theme.Accent
    indicator.BackgroundTransparency = 1
    indicator.BorderSizePixel = 0
    indicator.ZIndex = 6
    indicator.Parent = button
    addCorner(indicator, 99)

    navButtons[index] = {
        button = button,
        indicator = indicator,
    }

    button.Activated:Connect(function()
        if currentPage ~= index then
            switchPage(index)
        end
    end)
end

-- 面板面积严格按可用屏幕 1/8 计算
local MARGIN = 8
local panelWidth = 220
local panelHeight = 150
local orbSize = 42

local function getViewport()
    local size = Gui.AbsoluteSize
    if size.X > 0 and size.Y > 0 then
        return size
    end

    local camera = Workspace.CurrentCamera
    return camera and camera.ViewportSize or Vector2.new(800, 450)
end

local function clampPosition(position, width, height)
    local viewport = getViewport()

    return UDim2.fromOffset(
        math.clamp(
            position.X.Offset,
            MARGIN,
            math.max(MARGIN, viewport.X - width - MARGIN)
        ),
        math.clamp(
            position.Y.Offset,
            MARGIN,
            math.max(MARGIN, viewport.Y - height - MARGIN)
        )
    )
end

local function resizeUI(firstResize)
    local viewport = getViewport()
    local targetArea = viewport.X * viewport.Y / 8
    local aspect = viewport.X >= viewport.Y and 1.9 or 1.08

    local width = math.sqrt(targetArea * aspect)
    local height = targetArea / width
    local maxWidth = viewport.X - MARGIN * 2
    local maxHeight = viewport.Y - MARGIN * 2

    if height > maxHeight then
        height = maxHeight
        width = targetArea / height
    end

    if width > maxWidth then
        width = maxWidth
        height = targetArea / width
    end

    panelWidth = width
    panelHeight = height
    orbSize = math.clamp(
        math.min(viewport.X, viewport.Y) * 0.1,
        38,
        46
    )

    Main.Size = UDim2.fromOffset(panelWidth, panelHeight)
    OpenButton.Size = UDim2.fromOffset(orbSize, orbSize)

    if firstResize then
        Main.Position = UDim2.fromOffset(
            viewport.X - panelWidth - MARGIN,
            (viewport.Y - panelHeight) / 2
        )

        OpenButton.Position = UDim2.fromOffset(
            viewport.X - orbSize - MARGIN,
            (viewport.Y - orbSize) / 2
        )
    else
        Main.Position = clampPosition(Main.Position, panelWidth, panelHeight)
        OpenButton.Position = clampPosition(OpenButton.Position, orbSize, orbSize)
    end
end

local function snapToEdge(target, width, height)
    local viewport = getViewport()
    local centerX = target.Position.X.Offset + width / 2
    local targetX = centerX < viewport.X / 2
        and MARGIN
        or viewport.X - width - MARGIN

    local targetY = math.clamp(
        target.Position.Y.Offset,
        MARGIN,
        math.max(MARGIN, viewport.Y - height - MARGIN)
    )

    tween(target, SNAP, {
        Position = UDim2.fromOffset(targetX, targetY),
    })
end

-- 通用手机拖拽
local function makeDraggable(handle, target, sizeProvider)
    local dragging = false
    local dragInput
    local dragStart
    local startPosition
    local moved = false
    local lastDragEnd = -math.huge

    handle.InputBegan:Connect(function(input)
        if input.UserInputType ~= Enum.UserInputType.Touch
            and input.UserInputType ~= Enum.UserInputType.MouseButton1 then
            return
        end

        dragging = true
        moved = false
        dragInput = input
        dragStart = input.Position
        startPosition = target.Position

        input.Changed:Connect(function()
            if input.UserInputState == Enum.UserInputState.End then
                dragging = false

                if moved then
                    lastDragEnd = os.clock()
                    local width, height = sizeProvider()
                    snapToEdge(target, width, height)
                end
            end
        end)
    end)

    handle.InputChanged:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.Touch
            or input.UserInputType == Enum.UserInputType.MouseMovement then
            dragInput = input
        end
    end)

    UserInputService.InputChanged:Connect(function(input)
        if not dragging or input ~= dragInput then
            return
        end

        local delta = input.Position - dragStart
        if delta.Magnitude > 6 then
            moved = true
            lastDragEnd = os.clock()
        end

        local width, height = sizeProvider()
        target.Position = clampPosition(
            UDim2.fromOffset(
                startPosition.X.Offset + delta.X,
                startPosition.Y.Offset + delta.Y
            ),
            width,
            height
        )
    end)

    return function()
        return os.clock() - lastDragEnd < 0.18
    end
end

local isOpen = true
local animating = false

local function hidePanel()
    if not isOpen or animating then
        return
    end

    animating = true
    local viewport = getViewport()
    local mainCenter = Main.Position.X.Offset + panelWidth / 2
    local orbX = mainCenter < viewport.X / 2
        and MARGIN
        or viewport.X - orbSize - MARGIN

    local orbY = math.clamp(
        Main.Position.Y.Offset + panelHeight / 2 - orbSize / 2,
        MARGIN,
        math.max(MARGIN, viewport.Y - orbSize - MARGIN)
    )

    OpenButton.Position = UDim2.fromOffset(orbX, orbY)
    tween(Main, FAST, {GroupTransparency = 1})
    tween(MainScale, FAST, {Scale = 0.92})

    task.delay(0.13, function()
        Main.Visible = false
        OpenButton.Visible = true
        OpenScale.Scale = 0.82
        tween(OpenScale, SMOOTH, {Scale = 1})

        isOpen = false
        animating = false
    end)
end

local function showPanel()
    if isOpen or animating then
        return
    end

    animating = true
    local viewport = getViewport()
    local orbCenter = OpenButton.Position.X.Offset + orbSize / 2
    local targetX = orbCenter < viewport.X / 2
        and MARGIN
        or viewport.X - panelWidth - MARGIN

    local targetY = math.clamp(
        OpenButton.Position.Y.Offset + orbSize / 2 - panelHeight / 2,
        MARGIN,
        math.max(MARGIN, viewport.Y - panelHeight - MARGIN)
    )

    Main.Position = UDim2.fromOffset(targetX, targetY)
    Main.GroupTransparency = 1
    MainScale.Scale = 0.9
    Main.Visible = true
    OpenButton.Visible = false

    tween(Main, SMOOTH, {GroupTransparency = 0})
    tween(MainScale, SMOOTH, {Scale = 1})

    task.delay(0.23, function()
        isOpen = true
        animating = false
    end)
end

CloseButton.Activated:Connect(hidePanel)

makeDraggable(Header, Main, function()
    return panelWidth, panelHeight
end)

local orbRecentlyDragged = makeDraggable(OpenButton, OpenButton, function()
    return orbSize, orbSize
end)

OpenButton.Activated:Connect(function()
    if not orbRecentlyDragged() then
        showPanel()
    end
end)

-- 屏幕旋转与分辨率变化
local viewportConnection

local function bindCamera()
    if viewportConnection then
        viewportConnection:Disconnect()
        viewportConnection = nil
    end

    local camera = Workspace.CurrentCamera
    if camera then
        viewportConnection = camera:GetPropertyChangedSignal('ViewportSize'):Connect(function()
            resizeUI(false)
        end)
    end
end

Workspace:GetPropertyChangedSignal('CurrentCamera'):Connect(function()
    bindCamera()
    resizeUI(false)
    applyFOV()
end)

Gui:GetPropertyChangedSignal('AbsoluteSize'):Connect(function()
    resizeUI(false)
end)

task.wait()
resizeUI(true)
bindCamera()
switchPage(1, true)
