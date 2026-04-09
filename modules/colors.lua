local TweenService = game:GetService("TweenService")

local COLORS = {
    Galaxy1      = Color3.fromRGB(120, 60, 220),
    Galaxy2      = Color3.fromRGB(60, 80, 200),
    Galaxy3      = Color3.fromRGB(180, 60, 220),
    GalaxyAccent = Color3.fromRGB(210, 100, 255),
    Background   = Color3.fromRGB(8, 5, 20),
    DarkBG       = Color3.fromRGB(18, 10, 35),
    Frame        = Color3.fromRGB(28, 15, 50),
    White        = Color3.fromRGB(255, 255, 255),
    Gray         = Color3.fromRGB(70, 60, 90),
    Green        = Color3.fromRGB(50, 205, 50),
    Red          = Color3.fromRGB(255, 50, 50),
}

local function createCorner(parent, radius)
    local c = Instance.new("UICorner", parent)
    c.CornerRadius = UDim.new(0, radius or 10)
    return c
end

local function createStroke(parent, color, thickness)
    local s = Instance.new("UIStroke", parent)
    s.Color = color or COLORS.Galaxy1
    s.Thickness = thickness or 2
    return s
end

local function createGradient(parent, colors, rotation)
    local g = Instance.new("UIGradient", parent)
    g.Color = colors
    g.Rotation = rotation or 0
    return g
end

local function galaxyGradient(parent, rotation)
    createGradient(parent, ColorSequence.new{
        ColorSequenceKeypoint.new(0,   COLORS.Galaxy1),
        ColorSequenceKeypoint.new(0.3, COLORS.Galaxy2),
        ColorSequenceKeypoint.new(0.6, COLORS.Galaxy3),
        ColorSequenceKeypoint.new(1,   COLORS.GalaxyAccent),
    }, rotation or 90)
end

local function tween(obj, props, duration, style, direction)
    if not obj or not obj.Parent then return end
    pcall(function()
        TweenService:Create(obj, TweenInfo.new(
            duration or 0.3,
            style or Enum.EasingStyle.Quad,
            direction or Enum.EasingDirection.Out
        ), props):Play()
    end)
end

return {
    COLORS = COLORS,
    createCorner = createCorner,
    createStroke = createStroke,
    createGradient = createGradient,
    galaxyGradient = galaxyGradient,
    tween = tween,
}
