local CoreGui    = game:GetService("CoreGui")
local TweenService = game:GetService("TweenService")

local UI = {
    BorderColor = Color3.fromRGB(35, 35, 35),
    TextColor   = Color3.fromRGB(225, 225, 225),
    Font        = "Code",
    TextSize    = 13,
}

local function NewInstance(Type, Class, Properties)
    if Type == "Instance" then
        Class = Instance.new(Class)
        if protectinstance then protectinstance(Class) end
    end
    for k, v in next, Properties do Class[k] = v end
    return Class
end

-- ScreenGui
local NotifGui = Instance.new("ScreenGui")
NotifGui.Name = "HALO-HALO"
NotifGui.ZIndexBehavior = Enum.ZIndexBehavior.Global
NotifGui.ResetOnSpawn = false
NotifGui.IgnoreGuiInset = true
NotifGui.Parent = (gethui and gethui()) or CoreGui

-- Holder frame (bottom-left stack)
local Holder = NewInstance("Instance", "Frame", {
    Parent = NotifGui,
    BackgroundColor3 = Color3.fromRGB(255, 255, 255),
    BackgroundTransparency = 1,
    BorderSizePixel = 0,
    Position = UDim2.new(0.5, 0, 0, 10),
    Size = UDim2.new(0, 260, 0, 300),
    AnchorPoint = Vector2.new(0.5, 0),
})

NewInstance("Instance", "UIListLayout", {
    Parent = Holder,
    SortOrder = Enum.SortOrder.LayoutOrder,
    VerticalAlignment = Enum.VerticalAlignment.Top,
    Padding = UDim.new(0, 4),
})

local Notif = {}

function Notif:Send(text, duration)
    local Frame = NewInstance("Instance", "Frame", {
        Parent = Holder,
        BackgroundColor3 = Color3.fromRGB(255, 255, 255),
        BorderColor3 = Color3.fromRGB(0, 0, 0),
        Size = UDim2.new(0, 0, 0, 26),
        ClipsDescendants = true,
    })

    NewInstance("Instance", "UICorner", {
        Parent = Frame,
        CornerRadius = UDim.new(0, 6),
    })

    NewInstance("Instance", "UIStroke", {
        Parent = Frame,
        Color = UI.BorderColor,
        LineJoinMode = Enum.LineJoinMode.Round,
        Thickness = 1,
    })

    NewInstance("Instance", "UIGradient", {
        Parent = Frame,
        Rotation = 90,
        Color = ColorSequence.new{
            ColorSequenceKeypoint.new(0, Color3.fromRGB(18, 10, 35)),
            ColorSequenceKeypoint.new(1, Color3.fromRGB(28, 15, 50)),
        },
    })

    -- Galaxy accent bar on left
    local Bar = NewInstance("Instance", "Frame", {
        Parent = Frame,
        BackgroundColor3 = Color3.fromRGB(120, 60, 220),
        BorderSizePixel = 0,
        Size = UDim2.new(0, 3, 1, 0),
    })
    NewInstance("Instance", "UICorner", {Parent = Bar, CornerRadius = UDim.new(0, 3)})
    NewInstance("Instance", "UIGradient", {
        Parent = Bar,
        Rotation = 90,
        Color = ColorSequence.new{
            ColorSequenceKeypoint.new(0, Color3.fromRGB(120, 60, 220)),
            ColorSequenceKeypoint.new(1, Color3.fromRGB(210, 100, 255)),
        },
    })

    local Label = NewInstance("Instance", "TextLabel", {
        Parent = Frame,
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        Position = UDim2.new(0, 14, 0, 0),
        Size = UDim2.new(1, -14, 1, 0),
        Text = text or "Notification",
        Font = Enum.Font[UI.Font],
        TextColor3 = UI.TextColor,
        TextSize = UI.TextSize,
        TextStrokeTransparency = 0,
        TextXAlignment = Enum.TextXAlignment.Left,
        TextYAlignment = Enum.TextYAlignment.Center,
        TextWrapped = false,
    })

    task.wait()

    local targetW = math.clamp(Label.TextBounds.X + 24, 140, 500)
    Label.Size = UDim2.new(0, targetW, 1, 0)

    local info = TweenInfo.new(0.4, Enum.EasingStyle.Quint, Enum.EasingDirection.Out)
    TweenService:Create(Frame, info, {Size = UDim2.new(0, targetW, 0, 26)}):Play()

    task.delay(duration or 4, function()
        local outInfo = TweenInfo.new(0.4, Enum.EasingStyle.Quint, Enum.EasingDirection.In)
        local tw = TweenService:Create(Frame, outInfo, {Size = UDim2.new(0, 0, 0, 26)})
        tw:Play()
        tw.Completed:Once(function() Frame:Destroy() end)
    end)
end

return Notif
