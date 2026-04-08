-- @isnotsin - v0.0.8
-- Changes: Vertical tabs, Galaxy gradient colors, Rainbow ESP colors, Per-ESP color pickers in ESP tab, Other Scripts tab

local player = game.Players.LocalPlayer
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local CoreGui = game:GetService("CoreGui")
local Lighting = game:GetService("Lighting")
local VirtualUser = game:GetService("VirtualUser")

-- Anti-AFK
player.Idled:Connect(function()
    VirtualUser:CaptureController()
    VirtualUser:ClickButton2(Vector2.new())
end)

local CONFIG = {
    KingMode = false,
    AntiAFK = false,
    WalkSpeed = 50,
    JumpPower = 150,
    SpeedBoost = false,
    SuperJump = false,
    FPSBoost = false,
    DisableParticles = false,
    ShowFPS = false,
    Noclip = false,

    -- ESP CONFIG
    BoxESP = false,
    Chams = false,
    Tracers = false,
    Skeleton = false,
    HealthBar = false,
    Names = false,
    TeamFilter = false,

    -- INVISIBILITY
    Invisibility = false,

    -- ESP COLORS
    ESPColor = Color3.fromRGB(0, 255, 0),
    SkeletonColor = Color3.fromRGB(255, 255, 255),
    TracerColor = Color3.fromRGB(0, 255, 255),

    -- RAINBOW FLAGS
    BoxRainbow = false,
    SkeletonRainbow = false,
    TracerRainbow = false,
}

-- GALAXY COLORS
local COLORS = {
    -- Galaxy purples/blues/pinks
    Galaxy1 = Color3.fromRGB(120, 60, 220),   -- deep purple
    Galaxy2 = Color3.fromRGB(60,  80, 200),   -- indigo
    Galaxy3 = Color3.fromRGB(180, 60, 220),   -- violet
    Galaxy4 = Color3.fromRGB(100, 160, 255),  -- nebula blue
    GalaxyAccent = Color3.fromRGB(210, 100, 255), -- bright purple
    Background = Color3.fromRGB(8,  5,  20),  -- very dark space
    DarkBG = Color3.fromRGB(18, 10, 35),
    Frame = Color3.fromRGB(28, 15, 50),
    White = Color3.fromRGB(255, 255, 255),
    Gray = Color3.fromRGB(70,  60,  90),
    Green = Color3.fromRGB(50,  205, 50),
    Red = Color3.fromRGB(255, 50,  50),
}

-- Rainbow hue tracker
local rainbowHue = 0

-- ESP STATE
local boxes = {}
local beamTracers = {}
local skeletons = {}
local healthBars = {}
local nameLabels = {}

-- Cleanup all drawings for a player
local function cleanupPlayerESP(plr)
    if boxes[plr] then boxes[plr]:Remove(); boxes[plr] = nil end
    if nameLabels[plr] then nameLabels[plr]:Remove(); nameLabels[plr] = nil end
    if healthBars[plr] then
        healthBars[plr].background:Remove()
        healthBars[plr].health:Remove()
        healthBars[plr] = nil
    end
    if skeletons[plr] then
        for _, l in pairs(skeletons[plr]) do l:Remove() end
        skeletons[plr] = nil
    end
    if beamTracers[plr] then beamTracers[plr]:Remove(); beamTracers[plr] = nil end
end

game.Players.PlayerRemoving:Connect(cleanupPlayerESP)

-- INVISIBILITY STATE
local invConn = nil

local function tween(obj, props, duration, style, direction)
    if not obj or not obj.Parent then return end
    pcall(function() TweenService:Create(obj, TweenInfo.new(duration or 0.3, style or Enum.EasingStyle.Quad, direction or Enum.EasingDirection.Out), props):Play() end)
end

local function notifyImportant(text)
    pcall(function() game.StarterGui:SetCore("SendNotification", {Title = "@isnotsin", Text = text, Duration = 3}) end)
end

local function createCorner(parent, radius)
    local corner = Instance.new("UICorner", parent)
    corner.CornerRadius = UDim.new(0, radius or 10)
    return corner
end

local function createStroke(parent, color, thickness)
    local stroke = Instance.new("UIStroke", parent)
    stroke.Color = color or COLORS.Galaxy1
    stroke.Thickness = thickness or 2
    return stroke
end

local function createGradient(parent, colors, rotation)
    local gradient = Instance.new("UIGradient", parent)
    gradient.Color = colors
    gradient.Rotation = rotation or 0
    return gradient
end

local function galaxyGradient(parent, rotation)
    createGradient(parent, ColorSequence.new{
        ColorSequenceKeypoint.new(0,   COLORS.Galaxy1),
        ColorSequenceKeypoint.new(0.3, COLORS.Galaxy2),
        ColorSequenceKeypoint.new(0.6, COLORS.Galaxy3),
        ColorSequenceKeypoint.new(1,   COLORS.GalaxyAccent),
    }, rotation or 90)
end

-- ESP HELPERS
local function getRainbowColor()
    return Color3.fromHSV(rainbowHue, 1, 1)
end

local function getESPColor()
    return CONFIG.BoxRainbow and getRainbowColor() or CONFIG.ESPColor
end

local function getSkeletonColor()
    return CONFIG.SkeletonRainbow and getRainbowColor() or CONFIG.SkeletonColor
end

local function getTracerColor()
    return CONFIG.TracerRainbow and getRainbowColor() or CONFIG.TracerColor
end

local function getPlayerBaseColor(plr)
    if CONFIG.TeamFilter and player.Team and plr.Team and player.Team == plr.Team then
        return Color3.fromRGB(0, 255, 0)
    end
    return getESPColor()
end

local function shouldShowPlayer(plr)
    if plr == player then return false end
    if not CONFIG.TeamFilter then return true end
    if player.Team and plr.Team then
        return player.Team ~= plr.Team
    end
    return true
end

-- DRAWING UTILS
local function createDrawing(drawType, props)
    local obj = Drawing.new(drawType)
    for k, v in pairs(props) do obj[k] = v end
    return obj
end

-- INVISIBILITY LOGIC
local function stopInvLoop()
    if invConn then invConn:Disconnect(); invConn = nil end
end

local function startInvLoop()
    stopInvLoop()
    invConn = RunService.RenderStepped:Connect(function()
        if not CONFIG.Invisibility then stopInvLoop(); return end
        local char = player.Character
        local hrp = char and char:FindFirstChild("HumanoidRootPart")
        local hum = char and char:FindFirstChild("Humanoid")
        if not hrp or not hum then return end
        local orig = hrp.CFrame
        local offset = hum.CameraOffset
        hrp.CFrame = orig * CFrame.new(0, -200000, 0)
        hum.CameraOffset = hrp.CFrame:ToObjectSpace(CFrame.new(orig.Position)).Position
        task.defer(function()
            if hrp and hrp.Parent then
                hrp.CFrame = orig
                hum.CameraOffset = offset
            end
        end)
    end)
end

local function applyInvisibility(state)
    local char = player.Character
    if not char then return end
    for _, part in pairs(char:GetDescendants()) do
        if part:IsA("BasePart") then
            if state then
                if part.Transparency ~= 0.5 then part.Transparency = 0.5 end
            else
                if part.Transparency ~= 0 then part.Transparency = 0 end
            end
        end
    end
    if state then startInvLoop() else stopInvLoop() end
end

-- ESP LOGIC
local function updateESP()
    local camera = workspace.CurrentCamera
    for _, plr in pairs(game.Players:GetPlayers()) do
        local char = plr.Character
        local hrp = char and char:FindFirstChild("HumanoidRootPart")
        local hum = char and char:FindFirstChild("Humanoid")

        if not shouldShowPlayer(plr) or not hrp or not hum then
            if boxes[plr] then boxes[plr].Visible = false end
            if nameLabels[plr] then nameLabels[plr].Visible = false end
            if healthBars[plr] then healthBars[plr].background.Visible = false healthBars[plr].health.Visible = false end
            if skeletons[plr] then
                for _, l in pairs(skeletons[plr]) do l:Remove() end
                skeletons[plr] = nil
            end
            if beamTracers[plr] then beamTracers[plr].Visible = false end
            continue
        end

        local rootPos, onScreen = camera:WorldToViewportPoint(hrp.Position)
        local boxColor = getPlayerBaseColor(plr)

        -- Box ESP
        if CONFIG.BoxESP and onScreen then
            if not boxes[plr] then boxes[plr] = createDrawing("Square", {Thickness = 2, Filled = false, Transparency = 1}) end
            local box = boxes[plr]
            local distance = (camera.CFrame.Position - hrp.Position).Magnitude
            local size = (1000 / distance) * 2
            box.Size = Vector2.new(size, size * 1.5)
            box.Position = Vector2.new(rootPos.X - box.Size.X / 2, rootPos.Y - box.Size.Y / 2)
            box.Color = boxColor
            box.Visible = true
        elseif boxes[plr] then
            boxes[plr]:Remove(); boxes[plr] = nil
        end

        -- Name ESP
        if CONFIG.Names and onScreen then
            if not nameLabels[plr] then nameLabels[plr] = createDrawing("Text", {Size = 16, Center = true, Outline = true, Transparency = 1}) end
            local label = nameLabels[plr]
            label.Position = Vector2.new(rootPos.X, rootPos.Y - (boxes[plr] and boxes[plr].Size.Y / 2 or 20) - 20)
            label.Text = plr.Name
            label.Color = COLORS.White
            label.Visible = true
        elseif nameLabels[plr] then
            nameLabels[plr]:Remove(); nameLabels[plr] = nil
        end

        -- Health Bar
        if CONFIG.HealthBar and onScreen then
            if not healthBars[plr] then
                healthBars[plr] = {
                    background = createDrawing("Square", {Filled = true, Thickness = 1, Transparency = 1, Color = Color3.new(0,0,0)}),
                    health = createDrawing("Square", {Filled = true, Thickness = 1, Transparency = 1})
                }
            end
            local hb = healthBars[plr]
            local bSize = boxes[plr] and boxes[plr].Size or Vector2.new(40, 60)
            local bPos = boxes[plr] and boxes[plr].Position or Vector2.new(rootPos.X - 20, rootPos.Y - 30)
            hb.background.Size = Vector2.new(4, bSize.Y)
            hb.background.Position = Vector2.new(bPos.X - 6, bPos.Y)
            hb.background.Visible = true
            local healthPercent = hum.Health / hum.MaxHealth
            hb.health.Size = Vector2.new(2, bSize.Y * healthPercent)
            hb.health.Position = Vector2.new(bPos.X - 5, bPos.Y + (bSize.Y * (1 - healthPercent)))
            hb.health.Color = Color3.fromHSV(healthPercent * 0.3, 1, 1)
            hb.health.Visible = true
        elseif healthBars[plr] then
            healthBars[plr].background:Remove()
            healthBars[plr].health:Remove()
            healthBars[plr] = nil
        end

        -- Tracers
        if CONFIG.Tracers and onScreen then
            if not beamTracers[plr] then
                beamTracers[plr] = createDrawing("Line", {Thickness = 1, Transparency = 1})
            end
            local tracer = beamTracers[plr]
            local vpSize = camera.ViewportSize
            tracer.From = Vector2.new(vpSize.X / 2, vpSize.Y)
            tracer.To = Vector2.new(rootPos.X, rootPos.Y)
            tracer.Color = getTracerColor()
            tracer.Visible = true
        elseif beamTracers[plr] then
            beamTracers[plr]:Remove(); beamTracers[plr] = nil
        end

        -- Skeleton
        if CONFIG.Skeleton and onScreen then
            local skeleton = skeletons[plr] or {}
            skeletons[plr] = skeleton
            local joints = {}
            local connections = {}
            if hum.RigType == Enum.HumanoidRigType.R15 then
                joints = {
                    ["Head"] = char:FindFirstChild("Head"), ["UpperTorso"] = char:FindFirstChild("UpperTorso"), ["LowerTorso"] = char:FindFirstChild("LowerTorso"),
                    ["LeftUpperArm"] = char:FindFirstChild("LeftUpperArm"), ["LeftLowerArm"] = char:FindFirstChild("LeftLowerArm"), ["LeftHand"] = char:FindFirstChild("LeftHand"),
                    ["RightUpperArm"] = char:FindFirstChild("RightUpperArm"), ["RightLowerArm"] = char:FindFirstChild("RightLowerArm"), ["RightHand"] = char:FindFirstChild("RightHand"),
                    ["LeftUpperLeg"] = char:FindFirstChild("LeftUpperLeg"), ["LeftLowerLeg"] = char:FindFirstChild("LeftLowerLeg"),
                    ["RightUpperLeg"] = char:FindFirstChild("RightUpperLeg"), ["RightLowerLeg"] = char:FindFirstChild("RightLowerLeg")
                }
                connections = {
                    {"Head","UpperTorso"}, {"UpperTorso","LowerTorso"}, {"LowerTorso","LeftUpperLeg"}, {"LeftUpperLeg","LeftLowerLeg"},
                    {"LowerTorso","RightUpperLeg"}, {"RightUpperLeg","RightLowerLeg"}, {"UpperTorso","LeftUpperArm"}, {"LeftUpperArm","LeftLowerArm"},
                    {"LeftLowerArm","LeftHand"}, {"UpperTorso","RightUpperArm"}, {"RightUpperArm","RightLowerArm"}, {"RightLowerArm","RightHand"}
                }
            else
                joints = {
                    ["Head"] = char:FindFirstChild("Head"), ["Torso"] = char:FindFirstChild("Torso"),
                    ["LeftArm"] = char:FindFirstChild("Left Arm"), ["RightArm"] = char:FindFirstChild("Right Arm"),
                    ["LeftLeg"] = char:FindFirstChild("Left Leg"), ["RightLeg"] = char:FindFirstChild("Right Leg")
                }
                connections = {
                    {"Head","Torso"}, {"Torso","LeftArm"}, {"Torso","RightArm"}, {"Torso","LeftLeg"}, {"Torso","RightLeg"}
                }
            end
            local skelColor = getSkeletonColor()
            for i, conn in ipairs(connections) do
                local partA, partB = joints[conn[1]], joints[conn[2]]
                if partA and partB then
                    local posA, osA = camera:WorldToViewportPoint(partA.Position)
                    local posB, osB = camera:WorldToViewportPoint(partB.Position)
                    local line = skeleton[i] or createDrawing("Line", {Thickness = 3, Transparency = 1})
                    skeleton[i] = line
                    line.Color = skelColor
                    if osA and osB then
                        line.From = Vector2.new(posA.X, posA.Y)
                        line.To = Vector2.new(posB.X, posB.Y)
                        line.Visible = true
                    else
                        line.Visible = false
                    end
                elseif skeleton[i] then
                    skeleton[i].Visible = false
                end
            end
        elseif skeletons[plr] then
            for _, l in pairs(skeletons[plr]) do l:Remove() end
            skeletons[plr] = nil
        end
    end
end

-- ============================================================
-- UI CREATION
-- ============================================================
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "@isnotsin"
screenGui.ResetOnSpawn = false
screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
screenGui.Parent = CoreGui

-- ICON BUTTON
local iconBtn = Instance.new("TextButton")
iconBtn.Name = "Icon"
iconBtn.Size = UDim2.new(0, 60, 0, 60)
iconBtn.Position = UDim2.new(0, 20, 0, 20)
iconBtn.BackgroundColor3 = COLORS.Background
iconBtn.Text = "S"
iconBtn.TextColor3 = COLORS.GalaxyAccent
iconBtn.Font = Enum.Font.GothamBlack
iconBtn.TextSize = 28
iconBtn.Active = true
iconBtn.Draggable = true
iconBtn.Parent = screenGui
createCorner(iconBtn, 12)
local iconStroke = createStroke(iconBtn, COLORS.Galaxy1, 3)
galaxyGradient(iconBtn, 135)

-- Animate icon stroke color
RunService.Heartbeat:Connect(function(dt)
    rainbowHue = (rainbowHue + dt * 0.4) % 1
    local c = Color3.fromHSV((rainbowHue + 0.5) % 1, 0.7, 1)
    iconStroke.Color = c
end)

-- MAIN FRAME — wider to accommodate vertical tabs
local FRAME_W = 310
local FRAME_H = 380
local TAB_W = 70

local mainFrame = Instance.new("Frame")
mainFrame.Name = "Main"
mainFrame.Size = UDim2.new(0, FRAME_W, 0, FRAME_H)
mainFrame.Position = UDim2.new(0.5, -FRAME_W/2, 0.5, -FRAME_H/2)
mainFrame.BackgroundColor3 = COLORS.Background
mainFrame.Visible = false
mainFrame.Active = true
mainFrame.Draggable = true
mainFrame.ClipsDescendants = true
mainFrame.Parent = screenGui
createCorner(mainFrame, 15)
createStroke(mainFrame, COLORS.Galaxy1, 2)

-- Top Bar
local topBar = Instance.new("Frame")
topBar.Size = UDim2.new(1, 0, 0, 42)
topBar.BackgroundColor3 = COLORS.Galaxy1
topBar.Parent = mainFrame
createCorner(topBar, 15)
galaxyGradient(topBar, 90)

local titleLabel = Instance.new("TextLabel")
titleLabel.Size = UDim2.new(1, -80, 1, 0)
titleLabel.Position = UDim2.new(0, 15, 0, 0)
titleLabel.BackgroundTransparency = 1
titleLabel.Text = "✦ @isnotsin HUB"
titleLabel.Font = Enum.Font.GothamBold
titleLabel.TextSize = 14
titleLabel.TextColor3 = COLORS.White
titleLabel.TextXAlignment = Enum.TextXAlignment.Left
titleLabel.Parent = topBar

local closeBtn = Instance.new("TextButton")
closeBtn.Size = UDim2.new(0, 25, 0, 25)
closeBtn.Position = UDim2.new(1, -35, 0.5, -12.5)
closeBtn.Text = "×"
closeBtn.BackgroundColor3 = COLORS.DarkBG
closeBtn.TextColor3 = COLORS.White
closeBtn.Font = Enum.Font.GothamBold
closeBtn.TextSize = 20
closeBtn.Parent = topBar
createCorner(closeBtn, 6)

-- ============================================================
-- VERTICAL TABS SIDEBAR
-- ============================================================
local tabSidebar = Instance.new("Frame")
tabSidebar.Size = UDim2.new(0, TAB_W, 1, -42)
tabSidebar.Position = UDim2.new(0, 0, 0, 42)
tabSidebar.BackgroundColor3 = COLORS.DarkBG
tabSidebar.Parent = mainFrame

local sideLayout = Instance.new("UIListLayout", tabSidebar)
sideLayout.SortOrder = Enum.SortOrder.LayoutOrder
sideLayout.Padding = UDim.new(0, 4)

local sidePad = Instance.new("UIPadding", tabSidebar)
sidePad.PaddingTop = UDim.new(0, 6)
sidePad.PaddingLeft = UDim.new(0, 4)
sidePad.PaddingRight = UDim.new(0, 4)

-- Content area (right of sidebar)
local contentFrame = Instance.new("Frame")
contentFrame.Size = UDim2.new(1, -TAB_W, 1, -42)
contentFrame.Position = UDim2.new(0, TAB_W, 0, 42)
contentFrame.BackgroundTransparency = 1
contentFrame.Parent = mainFrame

local tabButtons = {}
local tabs = {"MAIN", "ESP", "FPS", "SCRIPTS"}
local contentContainers = {}
local activeTab = "MAIN"

local function setActiveTab(tabName)
    activeTab = tabName
    for name, btn in pairs(tabButtons) do
        if name == tabName then
            btn.BackgroundColor3 = COLORS.Galaxy1
            btn.TextColor3 = COLORS.White
        else
            btn.BackgroundColor3 = COLORS.Frame
            btn.TextColor3 = Color3.fromRGB(160, 140, 180)
        end
    end
    for name, c in pairs(contentContainers) do
        c.Visible = (name == tabName)
    end
end

local tabIcons = {MAIN = "⚙", ESP = "👁", FPS = "🖥", SCRIPTS = "📜"}

for i, tabName in ipairs(tabs) do
    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(1, 0, 0, 50)
    btn.BackgroundColor3 = (i == 1) and COLORS.Galaxy1 or COLORS.Frame
    btn.TextColor3 = (i == 1) and COLORS.White or Color3.fromRGB(160, 140, 180)
    btn.Font = Enum.Font.GothamBold
    btn.TextSize = 8
    btn.Text = tabIcons[tabName] .. "\n" .. tabName
    btn.TextWrapped = true
    btn.Parent = tabSidebar
    createCorner(btn, 8)
    tabButtons[tabName] = btn

    local container = Instance.new("ScrollingFrame")
    container.Size = UDim2.new(1, 0, 1, 0)
    container.BackgroundTransparency = 1
    container.BorderSizePixel = 0
    container.ScrollBarThickness = 2
    container.Visible = (i == 1)
    container.CanvasSize = UDim2.new(0, 0, 0, 0)
    container.AutomaticCanvasSize = Enum.AutomaticSize.Y
    container.Parent = contentFrame
    contentContainers[tabName] = container

    local layout = Instance.new("UIListLayout", container)
    layout.SortOrder = Enum.SortOrder.LayoutOrder
    layout.Padding = UDim.new(0, 4)

    local pad = Instance.new("UIPadding", container)
    pad.PaddingTop = UDim.new(0, 4)
    pad.PaddingLeft = UDim.new(0, 4)
    pad.PaddingRight = UDim.new(0, 4)

    btn.MouseButton1Click:Connect(function()
        setActiveTab(tabName)
    end)
end

-- ============================================================
-- COMPONENTS
-- ============================================================
local function createToggle(parent, text, key, callback)
    local container = Instance.new("Frame")
    container.Size = UDim2.new(1, -4, 0, 32)
    container.BackgroundColor3 = COLORS.Frame
    container.Parent = parent
    createCorner(container, 8)

    local label = Instance.new("TextLabel")
    label.Size = UDim2.new(1, -50, 1, 0)
    label.Position = UDim2.new(0, 8, 0, 0)
    label.BackgroundTransparency = 1
    label.Text = text
    label.Font = Enum.Font.GothamSemibold
    label.TextSize = 10
    label.TextColor3 = COLORS.White
    label.TextXAlignment = Enum.TextXAlignment.Left
    label.Parent = container

    local toggleBtn = Instance.new("Frame")
    toggleBtn.Size = UDim2.new(0, 34, 0, 17)
    toggleBtn.Position = UDim2.new(1, -42, 0.5, -8.5)
    toggleBtn.BackgroundColor3 = CONFIG[key] and COLORS.Galaxy1 or COLORS.Gray
    toggleBtn.Parent = container
    createCorner(toggleBtn, 9)

    local indicator = Instance.new("Frame")
    indicator.Size = UDim2.new(0, 13, 0, 13)
    indicator.Position = CONFIG[key] and UDim2.new(1, -15, 0.5, -6.5) or UDim2.new(0, 2, 0.5, -6.5)
    indicator.BackgroundColor3 = COLORS.White
    indicator.Parent = toggleBtn
    createCorner(indicator, 7)

    local click = Instance.new("TextButton")
    click.Size = UDim2.new(1, 0, 1, 0)
    click.BackgroundTransparency = 1
    click.Text = ""
    click.Parent = container

    local function updateVisuals(state)
        tween(toggleBtn, {BackgroundColor3 = state and COLORS.Galaxy1 or COLORS.Gray}, 0.2)
        tween(indicator, {Position = state and UDim2.new(1, -15, 0.5, -6.5) or UDim2.new(0, 2, 0.5, -6.5)}, 0.2)
    end

    click.MouseButton1Click:Connect(function()
        CONFIG[key] = not CONFIG[key]
        updateVisuals(CONFIG[key])
        if callback then callback(CONFIG[key]) end
    end)

    return updateVisuals
end

local function createSlider(parent, text, key, min, max, callback)
    local container = Instance.new("Frame")
    container.Size = UDim2.new(1, -4, 0, 45)
    container.BackgroundColor3 = COLORS.Frame
    container.Parent = parent
    createCorner(container, 8)

    local label = Instance.new("TextLabel")
    label.Size = UDim2.new(1, -8, 0, 18)
    label.Position = UDim2.new(0, 8, 0, 4)
    label.BackgroundTransparency = 1
    label.Text = text .. ": " .. CONFIG[key]
    label.Font = Enum.Font.GothamBold
    label.TextSize = 9
    label.TextColor3 = COLORS.White
    label.TextXAlignment = Enum.TextXAlignment.Left
    label.Parent = container

    local sliderBg = Instance.new("Frame")
    sliderBg.Size = UDim2.new(1, -16, 0, 6)
    sliderBg.Position = UDim2.new(0, 8, 0, 30)
    sliderBg.BackgroundColor3 = COLORS.Gray
    sliderBg.Parent = container
    createCorner(sliderBg, 3)

    local fill = Instance.new("Frame")
    local initialPos = math.clamp((CONFIG[key] - min) / (max - min), 0, 1)
    fill.Size = UDim2.new(initialPos, 0, 1, 0)
    fill.BackgroundColor3 = COLORS.Galaxy1
    fill.Parent = sliderBg
    createCorner(fill, 3)
    galaxyGradient(fill, 0)

    local knob = Instance.new("Frame")
    knob.Size = UDim2.new(0, 12, 0, 12)
    knob.Position = UDim2.new(initialPos, -6, 0.5, -6)
    knob.BackgroundColor3 = COLORS.White
    knob.Parent = sliderBg
    createCorner(knob, 6)
    createStroke(knob, COLORS.Galaxy1, 1)

    local dragging = false
    local function update(input)
        local pos = math.clamp((input.Position.X - sliderBg.AbsolutePosition.X) / sliderBg.AbsoluteSize.X, 0, 1)
        local val = math.floor(min + (max - min) * pos)
        CONFIG[key] = val
        label.Text = text .. ": " .. val
        fill.Size = UDim2.new(pos, 0, 1, 0)
        knob.Position = UDim2.new(pos, -6, 0.5, -6)
        if callback then callback(val) end
    end

    sliderBg.InputBegan:Connect(function(i) if i.UserInputType == Enum.UserInputType.MouseButton1 then dragging = true update(i) end end)
    UserInputService.InputEnded:Connect(function(i) if i.UserInputType == Enum.UserInputType.MouseButton1 then dragging = false end end)
    UserInputService.InputChanged:Connect(function(i) if dragging and i.UserInputType == Enum.UserInputType.MouseMovement then update(i) end end)
end

-- COLOR PICKER with Rainbow option
local COLOR_PRESETS = {
    {name = "White",   color = Color3.fromRGB(255, 255, 255)},
    {name = "Red",     color = Color3.fromRGB(255, 50,  50)},
    {name = "Orange",  color = Color3.fromRGB(255, 165, 0)},
    {name = "Yellow",  color = Color3.fromRGB(255, 255, 0)},
    {name = "Green",   color = Color3.fromRGB(50,  205, 50)},
    {name = "Cyan",    color = Color3.fromRGB(0,   255, 255)},
    {name = "Blue",    color = Color3.fromRGB(50,  100, 255)},
    {name = "Purple",  color = Color3.fromRGB(180, 50,  255)},
    {name = "Pink",    color = Color3.fromRGB(255, 100, 200)},
}

-- Creates a compact color row: [Label] [Swatch+Name] [🌈 Rainbow toggle]
local function createESPColorRow(parent, text, colorKey, rainbowKey)
    local container = Instance.new("Frame")
    container.Size = UDim2.new(1, -4, 0, 54)
    container.BackgroundColor3 = COLORS.Frame
    container.Parent = parent
    createCorner(container, 8)

    -- Top: label
    local label = Instance.new("TextLabel")
    label.Size = UDim2.new(1, -8, 0, 18)
    label.Position = UDim2.new(0, 8, 0, 4)
    label.BackgroundTransparency = 1
    label.Text = text
    label.Font = Enum.Font.GothamBold
    label.TextSize = 9
    label.TextColor3 = Color3.fromRGB(180, 160, 210)
    label.TextXAlignment = Enum.TextXAlignment.Left
    label.Parent = container

    -- Divider
    local div = Instance.new("Frame")
    div.Size = UDim2.new(1, -16, 0, 1)
    div.Position = UDim2.new(0, 8, 0, 24)
    div.BackgroundColor3 = COLORS.Gray
    div.Parent = container

    -- Color swatch
    local currentIdx = 1
    local swatch = Instance.new("Frame")
    swatch.Size = UDim2.new(0, 16, 0, 16)
    swatch.Position = UDim2.new(0, 8, 0, 31)
    swatch.BackgroundColor3 = CONFIG[colorKey]
    swatch.Parent = container
    createCorner(swatch, 4)

    local colorNameLabel = Instance.new("TextLabel")
    colorNameLabel.Size = UDim2.new(0, 55, 0, 16)
    colorNameLabel.Position = UDim2.new(0, 28, 0, 31)
    colorNameLabel.BackgroundTransparency = 1
    colorNameLabel.Text = "White"
    colorNameLabel.Font = Enum.Font.GothamBold
    colorNameLabel.TextSize = 9
    colorNameLabel.TextColor3 = CONFIG[colorKey]
    colorNameLabel.TextXAlignment = Enum.TextXAlignment.Left
    colorNameLabel.Parent = container

    -- Click to cycle color
    local colorBtn = Instance.new("TextButton")
    colorBtn.Size = UDim2.new(0, 75, 0, 20)
    colorBtn.Position = UDim2.new(0, 5, 0, 29)
    colorBtn.BackgroundTransparency = 1
    colorBtn.Text = ""
    colorBtn.Parent = container

    colorBtn.MouseButton1Click:Connect(function()
        currentIdx = (currentIdx % #COLOR_PRESETS) + 1
        local chosen = COLOR_PRESETS[currentIdx]
        CONFIG[colorKey] = chosen.color
        swatch.BackgroundColor3 = chosen.color
        colorNameLabel.Text = chosen.name
        colorNameLabel.TextColor3 = chosen.color
    end)

    -- Rainbow toggle button
    local rbBtn = Instance.new("TextButton")
    rbBtn.Size = UDim2.new(0, 70, 0, 18)
    rbBtn.Position = UDim2.new(1, -78, 0, 29)
    rbBtn.BackgroundColor3 = CONFIG[rainbowKey] and COLORS.Galaxy1 or COLORS.Gray
    rbBtn.Text = "🌈 Rainbow"
    rbBtn.TextColor3 = COLORS.White
    rbBtn.Font = Enum.Font.GothamBold
    rbBtn.TextSize = 7
    rbBtn.Parent = container
    createCorner(rbBtn, 6)

    rbBtn.MouseButton1Click:Connect(function()
        CONFIG[rainbowKey] = not CONFIG[rainbowKey]
        tween(rbBtn, {BackgroundColor3 = CONFIG[rainbowKey] and COLORS.Galaxy1 or COLORS.Gray}, 0.2)
    end)
end

-- ============================================================
-- SCRIPT BUTTON (for Other Scripts tab)
-- ============================================================
local function createScriptButton(parent, name, desc, scriptStr)
    local container = Instance.new("Frame")
    container.Size = UDim2.new(1, -4, 0, 54)
    container.BackgroundColor3 = COLORS.Frame
    container.Parent = parent
    createCorner(container, 8)

    local nameLabel = Instance.new("TextLabel")
    nameLabel.Size = UDim2.new(1, -8, 0, 20)
    nameLabel.Position = UDim2.new(0, 8, 0, 4)
    nameLabel.BackgroundTransparency = 1
    nameLabel.Text = name
    nameLabel.Font = Enum.Font.GothamBold
    nameLabel.TextSize = 10
    nameLabel.TextColor3 = COLORS.White
    nameLabel.TextXAlignment = Enum.TextXAlignment.Left
    nameLabel.Parent = container

    local descLabel = Instance.new("TextLabel")
    descLabel.Size = UDim2.new(1, -90, 0, 14)
    descLabel.Position = UDim2.new(0, 8, 0, 22)
    descLabel.BackgroundTransparency = 1
    descLabel.Text = desc
    descLabel.Font = Enum.Font.Gotham
    descLabel.TextSize = 8
    descLabel.TextColor3 = Color3.fromRGB(160, 140, 180)
    descLabel.TextXAlignment = Enum.TextXAlignment.Left
    descLabel.Parent = container

    local execBtn = Instance.new("TextButton")
    execBtn.Size = UDim2.new(0, 60, 0, 24)
    execBtn.Position = UDim2.new(1, -68, 0.5, -12)
    execBtn.BackgroundColor3 = COLORS.Galaxy1
    execBtn.Text = "LOAD"
    execBtn.TextColor3 = COLORS.White
    execBtn.Font = Enum.Font.GothamBold
    execBtn.TextSize = 9
    execBtn.Parent = container
    createCorner(execBtn, 6)
    galaxyGradient(execBtn, 90)

    execBtn.MouseButton1Click:Connect(function()
        execBtn.Text = "..."
        task.spawn(function()
            pcall(function()
                loadstring(scriptStr)()
            end)
            task.wait(1)
            execBtn.Text = "LOAD"
        end)
        notifyImportant("Loading: " .. name)
    end)
end

-- ============================================================
-- QUICK BUTTONS
-- ============================================================
local quickSyncs = {}
local toggleSyncs = {}

local function createQuickBtn(icon, name, posY, color, key, callback)
    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(0, 50, 0, 50)
    btn.Position = UDim2.new(0, 20, 0.5, posY)
    btn.BackgroundColor3 = COLORS.Background
    btn.Text = icon
    btn.TextColor3 = CONFIG[key] and color or COLORS.Gray
    btn.Font = Enum.Font.GothamBold
    btn.TextSize = 20
    btn.Parent = screenGui
    createCorner(btn, 10)
    local stroke = createStroke(btn, CONFIG[key] and color or COLORS.Gray, 2)

    local label = Instance.new("TextLabel")
    label.Size = UDim2.new(1, 0, 0, 12)
    label.Position = UDim2.new(0, 0, 1, 2)
    label.BackgroundTransparency = 1
    label.Text = name
    label.Font = Enum.Font.GothamBold
    label.TextSize = 8
    label.TextColor3 = CONFIG[key] and color or COLORS.Gray
    label.Parent = btn

    local function updateState(state)
        btn.TextColor3 = state and color or COLORS.Gray
        label.TextColor3 = state and color or COLORS.Gray
        stroke.Color = state and color or COLORS.Gray
    end

    quickSyncs[key] = updateState

    btn.MouseButton1Click:Connect(function()
        CONFIG[key] = not CONFIG[key]
        updateState(CONFIG[key])
        if toggleSyncs[key] then toggleSyncs[key](CONFIG[key]) end
        if callback then callback(CONFIG[key]) end
    end)
end

-- ============================================================
-- POPULATE TABS
-- ============================================================

-- MAIN TAB
local mainContent = contentContainers["MAIN"]
toggleSyncs["SpeedBoost"] = createToggle(mainContent, "Speed Boost", "SpeedBoost", function(v)
    if not v then
        local hum = player.Character and player.Character:FindFirstChildWhichIsA("Humanoid")
        if hum then hum.WalkSpeed = 16 end
    end
    if quickSyncs["SpeedBoost"] then quickSyncs["SpeedBoost"](v) end
end)
createSlider(mainContent, "Walk Speed", "WalkSpeed", 16, 250)
toggleSyncs["Noclip"] = createToggle(mainContent, "Noclip", "Noclip", function(v)
    if quickSyncs["Noclip"] then quickSyncs["Noclip"](v) end
end)
toggleSyncs["Invisibility"] = createToggle(mainContent, "Invisibility", "Invisibility", function(v)
    applyInvisibility(v)
    if quickSyncs["Invisibility"] then quickSyncs["Invisibility"](v) end
end)
createToggle(mainContent, "Super Jump", "SuperJump")
createSlider(mainContent, "Jump Power", "JumpPower", 50, 500)
createToggle(mainContent, "King Mode", "KingMode")
createToggle(mainContent, "Anti AFK", "AntiAFK")

-- ESP TAB (includes color pickers per feature)
local espContent = contentContainers["ESP"]

createToggle(espContent, "Box ESP", "BoxESP")
createESPColorRow(espContent, "Box Color", "ESPColor", "BoxRainbow")

createToggle(espContent, "Skeleton", "Skeleton")
createESPColorRow(espContent, "Skeleton Color", "SkeletonColor", "SkeletonRainbow")

createToggle(espContent, "Tracers", "Tracers")
createESPColorRow(espContent, "Tracer Color", "TracerColor", "TracerRainbow")

createToggle(espContent, "Health Bar", "HealthBar")
createToggle(espContent, "Names", "Names")
createToggle(espContent, "Team Filter", "TeamFilter")

-- FPS TAB
local fpsContent = contentContainers["FPS"]
createToggle(fpsContent, "FPS Boost", "FPSBoost", function(v)
    Lighting.GlobalShadows = not v
    Lighting.Technology = v and Enum.Technology.Compatibility or Enum.Technology.ShadowMap
end)
createToggle(fpsContent, "Disable Particles", "DisableParticles")
createToggle(fpsContent, "Show FPS", "ShowFPS")

-- SCRIPTS TAB
local scriptsContent = contentContainers["SCRIPTS"]

local scriptsHeader = Instance.new("TextLabel")
scriptsHeader.Size = UDim2.new(1, -4, 0, 24)
scriptsHeader.BackgroundTransparency = 1
scriptsHeader.Text = "Other Scripts"
scriptsHeader.Font = Enum.Font.GothamBold
scriptsHeader.TextSize = 10
scriptsHeader.TextColor3 = Color3.fromRGB(180, 140, 255)
scriptsHeader.TextXAlignment = Enum.TextXAlignment.Left
scriptsHeader.Parent = scriptsContent

createScriptButton(
    scriptsContent,
    "Mois7 Loader",
    "External script loader",
    [[loadstring(game:HttpGet("https://mois7.xyz/loader"))()]]
)

-- ============================================================
-- CONNECTIONS
-- ============================================================
local menuOpen = false
iconBtn.MouseButton1Click:Connect(function()
    menuOpen = not menuOpen
    mainFrame.Visible = menuOpen
    if menuOpen then
        mainFrame.Size = UDim2.new(0, 0, 0, 0)
        tween(mainFrame, {Size = UDim2.new(0, FRAME_W, 0, FRAME_H)}, 0.4, Enum.EasingStyle.Back)
    end
end)

closeBtn.MouseButton1Click:Connect(function()
    menuOpen = false
    mainFrame.Visible = false
end)

RunService.Heartbeat:Connect(function()
    pcall(function()
        local char = player.Character
        local hum = char and char:FindFirstChildWhichIsA("Humanoid")
        if hum then
            if CONFIG.SpeedBoost then hum.WalkSpeed = CONFIG.WalkSpeed end
            if CONFIG.KingMode then hum.Health = hum.MaxHealth hum.MaxHealth = 999999 end
        end
        if CONFIG.Noclip and char then
            for _, part in pairs(char:GetDescendants()) do
                if part:IsA("BasePart") and part.CanCollide then
                    part.CanCollide = false
                end
            end
        end
        updateESP()
    end)
end)

UserInputService.JumpRequest:Connect(function()
    if CONFIG.SuperJump then
        pcall(function()
            local char = player.Character
            local hrp = char:FindFirstChild("HumanoidRootPart")
            if hrp then hrp.Velocity = Vector3.new(hrp.Velocity.X, CONFIG.JumpPower, hrp.Velocity.Z) end
        end)
    end
end)

local function onCharacterAdded(newChar)
    task.wait(1)
    if CONFIG.Invisibility then applyInvisibility(true) end
    newChar.ChildAdded:Connect(function()
        if CONFIG.Invisibility then applyInvisibility(true) end
    end)
end

player.CharacterAdded:Connect(onCharacterAdded)
if player.Character then onCharacterAdded(player.Character) end

-- Quick buttons
createQuickBtn("⚡", "SPEED", -120, COLORS.Green, "SpeedBoost", function(v)
    if not v then
        local hum = player.Character and player.Character:FindFirstChildWhichIsA("Humanoid")
        if hum then hum.WalkSpeed = 16 end
    end
end)
createQuickBtn("👻", "NOCLIP", -60, COLORS.GalaxyAccent, "Noclip")
createQuickBtn("👁", "INVIS", 0, COLORS.White, "Invisibility", function(v)
    applyInvisibility(v)
end)

notifyImportant("@isnotsin HUB Loaded!")