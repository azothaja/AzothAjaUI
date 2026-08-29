--==================================================
-- AZOTHUI v1.0.2
-- Compatibility-focused UI Framework
--==================================================

local AzothUI = {}

AzothUI.Name = "AzothUI"
AzothUI.Version = "1.0.2"

--==================================================
-- SERVICES
--==================================================

local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")

local LocalPlayer = Players.LocalPlayer

--==================================================
-- CONFIG
--==================================================

local Config = {
    Theme = {
        Background = Color3.fromRGB(8, 8, 10),
        Sidebar = Color3.fromRGB(12, 9, 11),
        Surface = Color3.fromRGB(18, 12, 15),
        Surface2 = Color3.fromRGB(28, 15, 19),
        Border = Color3.fromRGB(75, 28, 38),
        Red = Color3.fromRGB(220, 32, 48),
        RedHover = Color3.fromRGB(238, 45, 61),
        Text = Color3.fromRGB(242, 242, 246),
        SubText = Color3.fromRGB(155, 150, 158),
        Muted = Color3.fromRGB(105, 101, 108),
        White = Color3.fromRGB(255, 255, 255),
    },

    Window = {
        Width = 760,
        Height = 480,
        MinWidth = 560,
        MinHeight = 380,
        Radius = 14,
        HeaderHeight = 60,
        SidebarWidth = 180,
    },

    Logo = "rbxassetid://111606226814401",
}

AzothUI.Config = Config

--==================================================
-- SAFE GUI PARENT
--
-- IMPORTANT:
-- We intentionally do NOT use CoreGui as the normal
-- parent. Xeno and some other environments interact
-- with Roblox's internal CoreGui/RoboGui modules.
--
-- PlayerGui is the official container for player UI.
--==================================================

local function getGuiParent()
    if not LocalPlayer then
        return nil
    end

    local ok, playerGui = pcall(function()
        return LocalPlayer:FindFirstChildOfClass("PlayerGui")
            or LocalPlayer:WaitForChild("PlayerGui", 5)
    end)

    if ok and playerGui then
        return playerGui
    end

    -- Only use gethui as a last fallback.
    -- This prevents us from touching CoreGui directly.
    if type(gethui) == "function" then
        local ok2, hui = pcall(gethui)
        if ok2 and hui then
            return hui
        end
    end

    return nil
end

local GuiParent = getGuiParent()

if not GuiParent then
    error("[AzothUI] Unable to find a safe GUI parent.")
end

--==================================================
-- ANTI DUPLICATE
--==================================================

local Existing = GuiParent:FindFirstChild("AzothUI")

if Existing then
    pcall(function()
        Existing:Destroy()
    end)
end

-- Also remove a previous copy from gethui if PlayerGui
-- was selected this time and an old version exists there.
if type(gethui) == "function" then
    pcall(function()
        local hui = gethui()
        if hui and hui ~= GuiParent then
            local old = hui:FindFirstChild("AzothUI")
            if old then
                old:Destroy()
            end
        end
    end)
end

--==================================================
-- HELPERS
--==================================================

local function New(className, properties, parent)
    local object = Instance.new(className)

    for property, value in pairs(properties or {}) do
        pcall(function()
            object[property] = value
        end)
    end

    object.Parent = parent
    return object
end

local function Corner(object, radius)
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, radius or 8)
    corner.Parent = object
    return corner
end

local function Border(object, color, thickness, transparency)
    local stroke = Instance.new("UIStroke")
    stroke.Color = color or Config.Theme.Border
    stroke.Thickness = thickness or 1
    stroke.Transparency = transparency or 0
    stroke.LineJoinMode = Enum.LineJoinMode.Round
    stroke.Parent = object
    return stroke
end

local function Tween(object, duration, properties)
    local tween = TweenService:Create(
        object,
        TweenInfo.new(
            duration or 0.15,
            Enum.EasingStyle.Quint,
            Enum.EasingDirection.Out
        ),
        properties
    )

    tween:Play()
    return tween
end

local function Text(parent, value, size, color, font)
    return New("TextLabel", {
        BackgroundTransparency = 1,
        Text = tostring(value or ""),
        TextColor3 = color or Config.Theme.Text,
        TextSize = size or 13,
        Font = font or Enum.Font.Gotham,
        TextXAlignment = Enum.TextXAlignment.Left,
        TextYAlignment = Enum.TextYAlignment.Center,
        TextTruncate = Enum.TextTruncate.AtEnd,
    }, parent)
end

local function MakeDraggable(handle, target)
    local dragging = false
    local dragStart
    local startPosition

    handle.InputBegan:Connect(function(input)
        if input.UserInputType ~= Enum.UserInputType.MouseButton1
        and input.UserInputType ~= Enum.UserInputType.Touch then
            return
        end

        dragging = true
        dragStart = input.Position
        startPosition = target.Position

        local connection
        connection = input.Changed:Connect(function()
            if input.UserInputState == Enum.UserInputState.End then
                dragging = false

                if connection then
                    connection:Disconnect()
                end
            end
        end)
    end)

    UserInputService.InputChanged:Connect(function(input)
        if not dragging then
            return
        end

        if input.UserInputType ~= Enum.UserInputType.MouseMovement
        and input.UserInputType ~= Enum.UserInputType.Touch then
            return
        end

        local delta = input.Position - dragStart

        target.Position = UDim2.new(
            startPosition.X.Scale,
            startPosition.X.Offset + delta.X,
            startPosition.Y.Scale,
            startPosition.Y.Offset + delta.Y
        )
    end)
end

--==================================================
-- SCREEN GUI
--==================================================

local ScreenGui = New("ScreenGui", {
    Name = "AzothUI",
    ResetOnSpawn = false,
    IgnoreGuiInset = true,
    ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
    DisplayOrder = 999999,
}, GuiParent)

--==================================================
-- TAB METHODS
--==================================================

local TabMethods = {}
TabMethods.__index = TabMethods

function TabMethods:AddSection(title)
    local label = Text(
        self.Content,
        string.upper(title or "SECTION"),
        10,
        Config.Theme.SubText,
        Enum.Font.GothamBold
    )

    label.Size = UDim2.new(1, 0, 0, 24)
    label.LayoutOrder = self.Order

    self.Order += 1

    return label
end

function TabMethods:AddButton(data)
    data = data or {}

    local button = New("TextButton", {
        Size = UDim2.new(1, 0, 0, data.Description and 62 or 48),
        BackgroundColor3 = Config.Theme.Surface,
        BorderSizePixel = 0,
        AutoButtonColor = false,
        Text = "",
        LayoutOrder = self.Order,
    }, self.Content)

    self.Order += 1

    Corner(button, 9)
    Border(button)

    local title = Text(
        button,
        data.Title or data.Name or "Button",
        13,
        Config.Theme.Text,
        Enum.Font.GothamMedium
    )

    title.Position = UDim2.fromOffset(16, data.Description and 5 or 0)
    title.Size = UDim2.new(1, -58, 0, data.Description and 25 or 48)

    if data.Description then
        local description = Text(
            button,
            data.Description,
            10,
            Config.Theme.SubText
        )

        description.Position = UDim2.fromOffset(16, 31)
        description.Size = UDim2.new(1, -58, 0, 18)
    end

    local arrow = Text(
        button,
        "›",
        20,
        Config.Theme.Muted,
        Enum.Font.GothamBold
    )

    arrow.Position = UDim2.new(1, -38, 0, 0)
    arrow.Size = UDim2.fromOffset(28, button.Size.Y.Offset)
    arrow.TextXAlignment = Enum.TextXAlignment.Center

    button.MouseEnter:Connect(function()
        Tween(button, 0.12, {
            BackgroundColor3 = Config.Theme.Surface2
        })
    end)

    button.MouseLeave:Connect(function()
        Tween(button, 0.12, {
            BackgroundColor3 = Config.Theme.Surface
        })
    end)

    button.MouseButton1Click:Connect(function()
        if type(data.Callback) == "function" then
            task.spawn(data.Callback)
        end
    end)

    return {
        Instance = button
    }
end

function TabMethods:AddToggle(data)
    data = data or {}

    local value = data.Default == true

    local row = New("Frame", {
        Size = UDim2.new(1, 0, 0, 54),
        BackgroundColor3 = Config.Theme.Surface,
        BorderSizePixel = 0,
        LayoutOrder = self.Order,
    }, self.Content)

    self.Order += 1

    Corner(row, 9)
    Border(row)

    local title = Text(
        row,
        data.Title or data.Name or "Toggle",
        13,
        Config.Theme.Text,
        Enum.Font.GothamMedium
    )

    title.Position = UDim2.fromOffset(16, 0)
    title.Size = UDim2.new(1, -92, 1, 0)

    local switch = New("TextButton", {
        Size = UDim2.fromOffset(46, 25),
        Position = UDim2.new(1, -62, 0.5, -12.5),
        BackgroundColor3 = value and Config.Theme.Red or Config.Theme.Muted,
        BorderSizePixel = 0,
        AutoButtonColor = false,
        Text = "",
    }, row)

    Corner(switch, 12)

    local knob = New("Frame", {
        Size = UDim2.fromOffset(18, 18),
        Position = value
            and UDim2.new(1, -22, 0.5, -9)
            or UDim2.new(0, 3, 0.5, -9),
        BackgroundColor3 = Config.Theme.White,
        BorderSizePixel = 0,
    }, switch)

    Corner(knob, 9)

    local function setValue(newValue, fire)
        value = newValue == true

        Tween(switch, 0.15, {
            BackgroundColor3 = value
                and Config.Theme.Red
                or Config.Theme.Muted
        })

        Tween(knob, 0.15, {
            Position = value
                and UDim2.new(1, -22, 0.5, -9)
                or UDim2.new(0, 3, 0.5, -9)
        })

        if fire and type(data.Callback) == "function" then
            task.spawn(data.Callback, value)
        end
    end

    switch.MouseButton1Click:Connect(function()
        setValue(not value, true)
    end)

    return {
        Instance = row,
        GetValue = function()
            return value
        end,
        SetValue = function(_, newValue, fire)
            setValue(newValue, fire)
        end,
    }
end

function TabMethods:AddSlider(data)
    data = data or {}

    local minimum = tonumber(data.Min) or 0
    local maximum = tonumber(data.Max) or 100
    local value = math.clamp(
        tonumber(data.Default) or minimum,
        minimum,
        maximum
    )

    local row = New("Frame", {
        Size = UDim2.new(1, 0, 0, 74),
        BackgroundColor3 = Config.Theme.Surface,
        BorderSizePixel = 0,
        LayoutOrder = self.Order,
    }, self.Content)

    self.Order += 1

    Corner(row, 9)
    Border(row)

    local title = Text(
        row,
        data.Title or data.Name or "Slider",
        12,
        Config.Theme.Text,
        Enum.Font.GothamMedium
    )

    title.Position = UDim2.fromOffset(16, 8)
    title.Size = UDim2.new(1, -80, 0, 20)

    local valueLabel = Text(
        row,
        tostring(value),
        11,
        Config.Theme.SubText
    )

    valueLabel.Position = UDim2.new(1, -70, 0, 7)
    valueLabel.Size = UDim2.fromOffset(55, 20)
    valueLabel.TextXAlignment = Enum.TextXAlignment.Right

    local bar = New("Frame", {
        Size = UDim2.new(1, -32, 0, 5),
        Position = UDim2.fromOffset(16, 49),
        BackgroundColor3 = Config.Theme.Muted,
        BorderSizePixel = 0,
        Active = true,
    }, row)

    Corner(bar, 3)

    local fill = New("Frame", {
        Size = UDim2.new(
            (value - minimum) / math.max(maximum - minimum, 1),
            0,
            1,
            0
        ),
        BackgroundColor3 = Config.Theme.Red,
        BorderSizePixel = 0,
    }, bar)

    Corner(fill, 3)

    local dragging = false

    local function apply(valueToSet, fire)
        valueToSet = math.clamp(
            tonumber(valueToSet) or minimum,
            minimum,
            maximum
        )

        local rounding = tonumber(data.Rounding)

        if rounding then
            local multiplier = 10 ^ rounding
            valueToSet = math.floor(
                valueToSet * multiplier + 0.5
            ) / multiplier
        end

        value = valueToSet

        local alpha = (value - minimum)
            / math.max(maximum - minimum, 1)

        fill.Size = UDim2.new(alpha, 0, 1, 0)
        valueLabel.Text = tostring(value)

        if fire and type(data.Callback) == "function" then
            task.spawn(data.Callback, value)
        end
    end

    local function fromMouse(x)
        local alpha = math.clamp(
            (x - bar.AbsolutePosition.X) / bar.AbsoluteSize.X,
            0,
            1
        )

        apply(
            minimum + (maximum - minimum) * alpha,
            true
        )
    end

    bar.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1
        or input.UserInputType == Enum.UserInputType.Touch then
            dragging = true
            fromMouse(input.Position.X)
        end
    end)

    UserInputService.InputChanged:Connect(function(input)
        if not dragging then
            return
        end

        if input.UserInputType == Enum.UserInputType.MouseMovement
        or input.UserInputType == Enum.UserInputType.Touch then
            fromMouse(input.Position.X)
        end
    end)

    UserInputService.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1
        or input.UserInputType == Enum.UserInputType.Touch then
            dragging = false
        end
    end)

    return {
        Instance = row,
        GetValue = function()
            return value
        end,
        SetValue = function(_, newValue, fire)
            apply(newValue, fire)
        end,
    }
end

function TabMethods:AddDropdown(data)
    data = data or {}

    local values = data.Values or {}
    local current = data.Default or values[1] or "Select"

    local row = New("Frame", {
        Size = UDim2.new(1, 0, 0, 52),
        BackgroundColor3 = Config.Theme.Surface,
        BorderSizePixel = 0,
        LayoutOrder = self.Order,
        ZIndex = 10,
    }, self.Content)

    self.Order += 1

    Corner(row, 9)
    Border(row)

    local title = Text(
        row,
        data.Title or data.Name or "Dropdown",
        13,
        Config.Theme.Text,
        Enum.Font.GothamMedium
    )

    title.Position = UDim2.fromOffset(16, 0)
    title.Size = UDim2.new(0.42, 0, 1, 0)

    local selector = New("TextButton", {
        Size = UDim2.fromOffset(180, 34),
        Position = UDim2.new(1, -196, 0.5, -17),
        BackgroundColor3 = Config.Theme.Surface2,
        BorderSizePixel = 0,
        AutoButtonColor = false,
        Text = tostring(current) .. "  ▾",
        TextColor3 = Config.Theme.Text,
        TextSize = 11,
        Font = Enum.Font.GothamMedium,
        ZIndex = 20,
    }, row)

    Corner(selector, 7)
    Border(selector)

    local menu = New("Frame", {
        Size = UDim2.fromOffset(180, 0),
        Position = UDim2.new(1, -196, 1, 4),
        BackgroundColor3 = Config.Theme.Surface,
        BorderSizePixel = 0,
        Visible = false,
        ClipsDescendants = true,
        ZIndex = 30,
    }, row)

    Corner(menu, 7)
    Border(menu)

    local layout = New("UIListLayout", {
        Padding = UDim.new(0, 2),
        SortOrder = Enum.SortOrder.LayoutOrder,
    }, menu)

    local function setValue(newValue, fire)
        current = newValue
        selector.Text = tostring(current) .. "  ▾"

        menu.Visible = false
        menu.Size = UDim2.fromOffset(180, 0)

        if fire and type(data.Callback) == "function" then
            task.spawn(data.Callback, current)
        end
    end

    for _, option in ipairs(values) do
        local item = New("TextButton", {
            Size = UDim2.new(1, -8, 0, 29),
            BackgroundColor3 = Config.Theme.Surface,
            BorderSizePixel = 0,
            AutoButtonColor = false,
            Text = tostring(option),
            TextColor3 = Config.Theme.Text,
            TextSize = 11,
            Font = Enum.Font.Gotham,
            ZIndex = 31,
        }, menu)

        item.MouseEnter:Connect(function()
            item.BackgroundColor3 = Config.Theme.Surface2
        end)

        item.MouseLeave:Connect(function()
            item.BackgroundColor3 = Config.Theme.Surface
        end)

        item.MouseButton1Click:Connect(function()
            setValue(option, true)
        end)
    end

    selector.MouseButton1Click:Connect(function()
        menu.Visible = not menu.Visible

        if menu.Visible then
            menu.Size = UDim2.fromOffset(
                180,
                math.min(#values * 32 + 8, 180)
            )
        else
            menu.Size = UDim2.fromOffset(180, 0)
        end
    end)

    return {
        Instance = row,
        GetValue = function()
            return current
        end,
        SetValue = function(_, newValue, fire)
            setValue(newValue, fire)
        end,
    }
end

function TabMethods:AddInput(data)
    data = data or {}

    local value = tostring(data.Default or "")

    local row = New("Frame", {
        Size = UDim2.new(1, 0, 0, 58),
        BackgroundColor3 = Config.Theme.Surface,
        BorderSizePixel = 0,
        LayoutOrder = self.Order,
    }, self.Content)

    self.Order += 1

    Corner(row, 9)
    Border(row)

    local title = Text(
        row,
        data.Title or data.Name or "Input",
        12,
        Config.Theme.Text,
        Enum.Font.GothamMedium
    )

    title.Position = UDim2.fromOffset(16, 0)
    title.Size = UDim2.fromOffset(105, 58)

    local box = New("TextBox", {
        Size = UDim2.new(1, -137, 0, 34),
        Position = UDim2.fromOffset(122, 12),
        BackgroundColor3 = Config.Theme.Surface2,
        BorderSizePixel = 0,
        Text = value,
        PlaceholderText = data.Placeholder or "",
        PlaceholderColor3 = Config.Theme.Muted,
        TextColor3 = Config.Theme.Text,
        TextSize = 11,
        Font = Enum.Font.Gotham,
        ClearTextOnFocus = false,
    }, row)

    Corner(box, 7)
    Border(box)

    box.FocusLost:Connect(function()
        value = box.Text

        if type(data.Callback) == "function" then
            task.spawn(data.Callback, value)
        end
    end)

    return {
        Instance = row,
        GetValue = function()
            return value
        end,
        SetValue = function(_, newValue, fire)
            value = tostring(newValue or "")
            box.Text = value

            if fire and type(data.Callback) == "function" then
                task.spawn(data.Callback, value)
            end
        end,
    }
end

function TabMethods:AddParagraph(data)
    data = data or {}

    local row = New("Frame", {
        Size = UDim2.new(1, 0, 0, 72),
        BackgroundColor3 = Config.Theme.Surface,
        BorderSizePixel = 0,
        LayoutOrder = self.Order,
    }, self.Content)

    self.Order += 1

    Corner(row, 9)
    Border(row)

    local title = Text(
        row,
        data.Title or "Information",
        12,
        Config.Theme.Text,
        Enum.Font.GothamBold
    )

    title.Position = UDim2.fromOffset(16, 8)
    title.Size = UDim2.new(1, -30, 0, 20)

    local content = Text(
        row,
        data.Content or "",
        11,
        Config.Theme.SubText
    )

    content.Position = UDim2.fromOffset(16, 31)
    content.Size = UDim2.new(1, -30, 0, 34)
    content.TextWrapped = true

    return {
        Instance = row,
        SetTitle = function(_, value)
            title.Text = tostring(value)
        end,
        SetContent = function(_, value)
            content.Text = tostring(value)
        end,
    }
end

--==================================================
-- WINDOW METHODS
--==================================================

local WindowMethods = {}
WindowMethods.__index = WindowMethods

function WindowMethods:AddTab(data)
    data = data or {}

    local title = data.Title or data.Name or "Tab"
    local icon = data.Icon or ""

    local button = New("TextButton", {
        Size = UDim2.new(1, 0, 0, 42),
        BackgroundColor3 = Config.Theme.Sidebar,
        BorderSizePixel = 0,
        AutoButtonColor = false,
        Text = "",
        LayoutOrder = self.TabOrder,
        ZIndex = 20,
    }, self.Sidebar)

    self.TabOrder += 1

    Corner(button, 9)

    local accent = New("Frame", {
        Size = UDim2.new(0, 3, 1, -12),
        Position = UDim2.fromOffset(0, 6),
        BackgroundColor3 = Config.Theme.Red,
        BorderSizePixel = 0,
        Visible = false,
        ZIndex = 21,
    }, button)

    Corner(accent, 2)

    local iconLabel = Text(
        button,
        icon,
        12,
        Config.Theme.SubText
    )

    iconLabel.Position = UDim2.fromOffset(8, 0)
    iconLabel.Size = UDim2.fromOffset(30, 42)
    iconLabel.TextXAlignment = Enum.TextXAlignment.Center

    local nameLabel = Text(
        button,
        title,
        12,
        Config.Theme.SubText,
        Enum.Font.GothamMedium
    )

    nameLabel.Position = UDim2.fromOffset(46, 0)
    nameLabel.Size = UDim2.new(1, -54, 1, 0)

    local content = New("ScrollingFrame", {
        Size = UDim2.new(1, -28, 1, -24),
        Position = UDim2.fromOffset(14, 12),
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        ScrollBarThickness = 3,
        ScrollBarImageColor3 = Config.Theme.Red,
        ScrollBarImageTransparency = 0.35,
        AutomaticCanvasSize = Enum.AutomaticSize.Y,
        CanvasSize = UDim2.new(),
        ScrollingDirection = Enum.ScrollingDirection.Y,
        Active = true,
        Visible = false,
        ZIndex = 19,
    }, self.ContentArea)

    New("UIPadding", {
        PaddingRight = UDim.new(0, 6),
        PaddingBottom = UDim.new(0, 8),
    }, content)

    New("UIListLayout", {
        Padding = UDim.new(0, 7),
        SortOrder = Enum.SortOrder.LayoutOrder,
    }, content)

    local tab = setmetatable({
        Window = self,
        Button = button,
        Accent = accent,
        Label = nameLabel,
        Content = content,
        Order = 1,
    }, TabMethods)

    table.insert(self.Tabs, tab)

button.MouseButton1Click:Connect(function()
    for _, other in ipairs(self.Tabs) do
        other.Content.Visible = false
        other.Accent.Visible = false
        other.Button.BackgroundColor3 = Config.Theme.Sidebar
        other.Label.TextColor3 = Config.Theme.SubText
    end

    content.Visible = true
    accent.Visible = true
    button.BackgroundColor3 = Config.Theme.Surface2
    nameLabel.TextColor3 = Config.Theme.Text
    self.ActiveTab = tab
end)

if #self.Tabs == 1 then
    content.Visible = true
    accent.Visible = true
    button.BackgroundColor3 = Config.Theme.Surface2
    nameLabel.TextColor3 = Config.Theme.Text
    self.ActiveTab = tab
end

    return tab
end

function WindowMethods:SelectTab(tab)
    if not tab then
        return
    end

    for _, other in ipairs(self.Tabs) do
        other.Content.Visible = false
        other.Accent.Visible = false
        other.Button.BackgroundColor3 = Config.Theme.Sidebar
        other.Label.TextColor3 = Config.Theme.SubText
    end

    tab.Content.Visible = true
    tab.Accent.Visible = true
    tab.Button.BackgroundColor3 = Config.Theme.Surface2
    tab.Label.TextColor3 = Config.Theme.Text
    self.ActiveTab = tab
end

function WindowMethods:SetTitle(value)
    if self.Title then
        self.Title.Text = tostring(value)
    end
end

function WindowMethods:SetVersion(value)
    if self.Version then
        self.Version.Text = tostring(value)
    end
end

function WindowMethods:SetSize(width, height)
    width = math.max(
        tonumber(width) or Config.Window.Width,
        Config.Window.MinWidth
    )

    height = math.max(
        tonumber(height) or Config.Window.Height,
        Config.Window.MinHeight
    )

    self.Main.Size = UDim2.fromOffset(width, height)
    if self.Shadow then
        self.Shadow.Size = UDim2.fromOffset(width + 8, height + 8)
    end
end

function WindowMethods:GetSize()
    return self.Main.AbsoluteSize
end

function WindowMethods:SetLogo(asset)
    self.Mini.Image = tostring(asset)
end

function WindowMethods:Minimize()
    self.Main.Visible = false
    if self.Shadow then
        self.Shadow.Visible = false
    end
    self.Mini.Visible = true
end

function WindowMethods:Maximize()
    self.Main.Visible = true
    if self.Shadow then
        self.Shadow.Visible = true
    end
    self.Mini.Visible = false
end

function WindowMethods:Close()
    if self.Destroyed then
        return
    end

    self.Destroyed = true

    -- Resize grip is a child of the window surface and is cleaned up with it.
    if self.Mini then
        self.Mini:Destroy()
    end

    if self.Main then
        self.Main:Destroy()
    end

    if self.Shadow then
        self.Shadow:Destroy()
    end
end

--==================================================
-- NOTIFICATION
--==================================================

local function CreateNotification(title, content, duration)
    duration = tonumber(duration) or 3

    local container = ScreenGui:FindFirstChild("Notifications")

    if not container then
        container = New("Frame", {
            Name = "Notifications",
            Size = UDim2.new(0, 300, 1, -20),
            Position = UDim2.new(1, -315, 0, 10),
            BackgroundTransparency = 1,
            BorderSizePixel = 0,
            ZIndex = 500,
        }, ScreenGui)

        New("UIListLayout", {
            Padding = UDim.new(0, 8),
            HorizontalAlignment = Enum.HorizontalAlignment.Right,
            VerticalAlignment = Enum.VerticalAlignment.Top,
            SortOrder = Enum.SortOrder.LayoutOrder,
        }, container)
    end

    local notification = New("Frame", {
        Size = UDim2.fromOffset(285, 70),
        BackgroundColor3 = Config.Theme.Surface,
        BorderSizePixel = 0,
        ZIndex = 501,
    }, container)

    Corner(notification, 10)
    Border(notification)

    local accent = New("Frame", {
        Size = UDim2.new(0, 3, 1, -18),
        Position = UDim2.fromOffset(0, 9),
        BackgroundColor3 = Config.Theme.Red,
        BorderSizePixel = 0,
        ZIndex = 502,
    }, notification)

    Corner(accent, 2)

    local titleLabel = Text(
        notification,
        title or "AzothUI",
        12,
        Config.Theme.Text,
        Enum.Font.GothamBold
    )

    titleLabel.Position = UDim2.fromOffset(15, 8)
    titleLabel.Size = UDim2.new(1, -25, 0, 22)

    local contentLabel = Text(
        notification,
        content or "",
        10,
        Config.Theme.SubText
    )

    contentLabel.Position = UDim2.fromOffset(15, 31)
    contentLabel.Size = UDim2.new(1, -25, 0, 28)
    contentLabel.TextWrapped = true

    notification.Position = UDim2.new(1, 25, 0, 0)

    Tween(notification, 0.2, {
        Position = UDim2.new(0, 0, 0, 0)
    })

    task.delay(duration, function()
        if notification and notification.Parent then
            local tween = Tween(notification, 0.2, {
                Position = UDim2.new(1, 25, 0, 0)
            })

            tween.Completed:Connect(function()
                if notification then
                    notification:Destroy()
                end
            end)
        end
    end)

    return notification
end

function AzothUI:Notify(data)
    data = data or {}

    return CreateNotification(
        data.Title or "AzothUI",
        data.Content or "",
        data.Duration or 3
    )
end

--==================================================
-- CREATE WINDOW
--==================================================

function AzothUI:CreateWindow(data)
    data = data or {}

    local width = tonumber(data.Width) or Config.Window.Width
    local height = tonumber(data.Height) or Config.Window.Height

    if data.Size then
        if data.Size.X then
            width = tonumber(data.Size.X.Offset) or width
        end

        if data.Size.Y then
            height = tonumber(data.Size.Y.Offset) or height
        end
    end

    width = math.max(width, Config.Window.MinWidth)
    height = math.max(height, Config.Window.MinHeight)

    local shadow = New("Frame", {
        Name = "WindowShadow",
        Size = UDim2.fromOffset(width + 8, height + 8),
        Position = UDim2.new(0.5, 0, 0.5, 4),
        AnchorPoint = Vector2.new(0.5, 0.5),
        BackgroundColor3 = Color3.fromRGB(0, 0, 0),
        BackgroundTransparency = 0.62,
        BorderSizePixel = 0,
        ZIndex = 8,
    }, ScreenGui)
    Corner(shadow, Config.Window.Radius + 2)

    local main = New("Frame", {
        Name = "Window",
        Size = UDim2.fromOffset(width, height),
        Position = UDim2.new(0.5, 0, 0.5, 0),
        AnchorPoint = Vector2.new(0.5, 0.5),
        BackgroundColor3 = Config.Theme.Border,
        BorderSizePixel = 0,
        ClipsDescendants = true,
        ZIndex = 10,
    }, ScreenGui)

    Corner(main, Config.Window.Radius)

    local inside = New("Frame", {
        Position = UDim2.fromOffset(1, 1),
        Size = UDim2.new(1, -2, 1, -2),
        BackgroundColor3 = Config.Theme.Background,
        BorderSizePixel = 0,
        ClipsDescendants = true,
        ZIndex = 11,
    }, main)

    Corner(inside, Config.Window.Radius - 1)

    local header = New("Frame", {
        Size = UDim2.new(1, 0, 0, Config.Window.HeaderHeight),
        BackgroundColor3 = Config.Theme.Background,
        BorderSizePixel = 0,
        ZIndex = 15,
    }, inside)

    local title = Text(
        header,
        data.Title or "AZOTH LOADER",
        17,
        Config.Theme.Text,
        Enum.Font.GothamBold
    )

    title.Position = UDim2.fromOffset(20, 0)
    title.Size = UDim2.new(1, -210, 1, 0)

    local version = Text(
        header,
        data.Version or AzothUI.Version,
        10,
        Config.Theme.SubText
    )

    version.Position = UDim2.new(1, -150, 0, 0)
    version.Size = UDim2.fromOffset(70, Config.Window.HeaderHeight)

    local minimize = New("TextButton", {
        Size = UDim2.fromOffset(38, 38),
        Position = UDim2.new(1, -94, 0.5, -18),
        BackgroundColor3 = Config.Theme.Surface2,
        BorderSizePixel = 0,
        AutoButtonColor = false,
        Text = "—",
        TextColor3 = Config.Theme.Text,
        TextSize = 20,
        Font = Enum.Font.GothamMedium,
        ZIndex = 20,
    }, header)

    Corner(minimize, 9)

    local close = New("TextButton", {
        Size = UDim2.fromOffset(38, 38),
        Position = UDim2.new(1, -48, 0.5, -18),
        BackgroundColor3 = Config.Theme.Surface2,
        BorderSizePixel = 0,
        AutoButtonColor = false,
        Text = "×",
        TextColor3 = Config.Theme.Text,
        TextSize = 18,
        Font = Enum.Font.GothamMedium,
        ZIndex = 20,
    }, header)

    Corner(close, 9)

    local divider = New("Frame", {
        Size = UDim2.new(1, 0, 0, 1),
        Position = UDim2.fromOffset(0, Config.Window.HeaderHeight - 1),
        BackgroundColor3 = Config.Theme.Border,
        BackgroundTransparency = 0.45,
        BorderSizePixel = 0,
        ZIndex = 16,
    }, inside)

    local headerGlow = New("Frame", {
        Size = UDim2.new(1, -24, 0, 1),
        Position = UDim2.fromOffset(12, Config.Window.HeaderHeight - 1),
        BackgroundColor3 = Config.Theme.Red,
        BackgroundTransparency = 0.78,
        BorderSizePixel = 0,
        ZIndex = 17,
    }, inside)

    local sidebar = New("Frame", {
        Size = UDim2.new(
            0,
            Config.Window.SidebarWidth,
            1,
            -Config.Window.HeaderHeight
        ),
        Position = UDim2.fromOffset(0, Config.Window.HeaderHeight),
        BackgroundColor3 = Config.Theme.Sidebar,
        BorderSizePixel = 0,
        ZIndex = 14,
    }, inside)

    New("UIPadding", {
        PaddingLeft = UDim.new(0, 10),
        PaddingRight = UDim.new(0, 10),
        PaddingTop = UDim.new(0, 12),
        PaddingBottom = UDim.new(0, 12),
    }, sidebar)

    New("UIListLayout", {
        Padding = UDim.new(0, 6),
        SortOrder = Enum.SortOrder.LayoutOrder,
    }, sidebar)

    local sidebarCaption = Text(
        sidebar,
        "MENU",
        9,
        Config.Theme.Muted,
        Enum.Font.GothamBold
    )
    sidebarCaption.Size = UDim2.new(1, 0, 0, 18)
    sidebarCaption.LayoutOrder = 0
    sidebarCaption.TextXAlignment = Enum.TextXAlignment.Left

    local sidebarLayout = sidebar:FindFirstChildOfClass("UIListLayout")
    if sidebarLayout then
        sidebarLayout.Padding = UDim.new(0, 6)
    end

    local contentArea = New("Frame", {
        Size = UDim2.new(
            1,
            -Config.Window.SidebarWidth,
            1,
            -Config.Window.HeaderHeight
        ),
        Position = UDim2.fromOffset(
            Config.Window.SidebarWidth,
            Config.Window.HeaderHeight
        ),
        BackgroundColor3 = Config.Theme.Background,
        BorderSizePixel = 0,
        ClipsDescendants = true,
        ZIndex = 13,
    }, inside)

    --==================================================
    -- MINI LOGO
    --==================================================

    local mini = New("ImageButton", {
        Name = "MiniLogo",
        Size = UDim2.fromOffset(58, 58),
        Position = UDim2.new(0.5, 0, 0.5, 0),
        AnchorPoint = Vector2.new(0.5, 0.5),
        BackgroundColor3 = Config.Theme.Background,
        BorderSizePixel = 0,
        Image = data.Logo or Config.Logo,
        ScaleType = Enum.ScaleType.Fit,
        Visible = false,
        Active = true,
        ZIndex = 100,
    }, ScreenGui)

    Corner(mini, 29)
    Border(mini, Config.Theme.Border)

    local window = setmetatable({
        Main = main,
        Shadow = shadow,
        Header = header,
        Sidebar = sidebar,
        ContentArea = contentArea,
        Mini = mini,
        Title = title,
        Version = version,
        Tabs = {},
        TabOrder = 1,
        ActiveTab = nil,
        Destroyed = false,
    }, WindowMethods)

    --==================================================
    -- DRAG
    --==================================================

    MakeDraggable(header, main)
    MakeDraggable(mini, mini)

    --==================================================
    -- RESIZE HANDLE (bottom-right corner)
    --==================================================
    -- This is a CHILD of `inside` (the rounded, clipped surface), not a
    -- separate ScreenGui sibling positioned by hand. The old version
    -- synced its position from Main.AbsolutePosition/AbsoluteSize on
    -- every Position/Size/Visible change - that manual sync could lag
    -- a frame behind during drags/resizes, which is exactly what made
    -- the corner look like it had overlapping straight edges instead of
    -- a clean curve. Anchoring the handle with AnchorPoint(1,1) lets
    -- Roblox's own layout engine keep it glued to the corner
    -- automatically, and insetting it a few pixels keeps every dot
    -- inside the already-rounded corner instead of trying to hug the
    -- curve from outside.

    local gripInset = 7

    local grip = New("TextButton", {
        Name = "ResizeGrip",
        AnchorPoint = Vector2.new(1, 1),
        Position = UDim2.new(1, -gripInset, 1, -gripInset),
        Size = UDim2.fromOffset(18, 18),
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        AutoButtonColor = false,
        Text = "",
        Active = true,
        Selectable = false,
        ZIndex = 300,
    }, inside)

    window.Grip = grip

    local gripDots = {}

    local function addGripDot(dx, dy)
        local dot = New("Frame", {
            AnchorPoint = Vector2.new(1, 1),
            Position = UDim2.new(1, -dx, 1, -dy),
            Size = UDim2.fromOffset(3, 3),
            BackgroundColor3 = Config.Theme.SubText,
            BackgroundTransparency = 0.42,
            BorderSizePixel = 0,
            Active = false,
            ZIndex = 301,
        }, grip)

        Corner(dot, 2)

        table.insert(gripDots, dot)
    end

    -- Classic triangular "resize dots" pattern, fully inside the
    -- handle's own bounds so nothing pokes past the rounded corner.
    addGripDot(4, 4)
    addGripDot(4, 11)
    addGripDot(11, 4)
    addGripDot(4, 16)
    addGripDot(11, 11)
    addGripDot(16, 4)

    grip.MouseEnter:Connect(function()
        for _, dot in ipairs(gripDots) do
            Tween(dot, 0.12, {
                BackgroundTransparency = 0.1
            })
        end
    end)

    grip.MouseLeave:Connect(function()
        for _, dot in ipairs(gripDots) do
            Tween(dot, 0.15, {
                BackgroundTransparency = 0.42
            })
        end
    end)

    local resizing = false
    local resizeStart
    local startingSize

    grip.InputBegan:Connect(function(input)
        if input.UserInputType ~= Enum.UserInputType.MouseButton1
        and input.UserInputType ~= Enum.UserInputType.Touch then
            return
        end

        resizing = true
        resizeStart = input.Position
        startingSize = main.AbsoluteSize

        local connection
        connection = input.Changed:Connect(function()
            if input.UserInputState == Enum.UserInputState.End then
                resizing = false

                if connection then
                    connection:Disconnect()
                end
            end
        end)
    end)

    UserInputService.InputChanged:Connect(function(input)
        if not resizing then
            return
        end

        if input.UserInputType ~= Enum.UserInputType.MouseMovement
        and input.UserInputType ~= Enum.UserInputType.Touch then
            return
        end

        local delta = input.Position - resizeStart

        local newWidth = math.max(
            Config.Window.MinWidth,
            startingSize.X + delta.X
        )
        local newHeight = math.max(
            Config.Window.MinHeight,
            startingSize.Y + delta.Y
        )

        main.Size = UDim2.fromOffset(newWidth, newHeight)

        if shadow then
            shadow.Size = UDim2.fromOffset(newWidth + 8, newHeight + 8)
        end
    end)

    --==================================================
    -- BUTTONS
    --==================================================

    minimize.MouseEnter:Connect(function()
        Tween(minimize, 0.1, {
            BackgroundColor3 = Config.Theme.Red
        })
    end)

    minimize.MouseLeave:Connect(function()
        Tween(minimize, 0.1, {
            BackgroundColor3 = Config.Theme.Surface2
        })
    end)

    close.MouseEnter:Connect(function()
        Tween(close, 0.1, {
            BackgroundColor3 = Config.Theme.Red
        })
    end)

    close.MouseLeave:Connect(function()
        Tween(close, 0.1, {
            BackgroundColor3 = Config.Theme.Surface2
        })
    end)

    minimize.MouseButton1Click:Connect(function()
        window:Minimize()
    end)

    mini.MouseButton1Click:Connect(function()
        window:Maximize()
    end)

    close.MouseButton1Click:Connect(function()
        window:Close()
    end)

    --==================================================
    -- CAPABILITY INFORMATION
    --==================================================

    window.Capabilities = {
        PlayerGui = GuiParent == LocalPlayer:FindFirstChildOfClass("PlayerGui"),
        GetHui = type(gethui) == "function",
        Loadstring = type(loadstring) == "function",
        HttpGet = pcall(function()
            return type(game.HttpGet) == "function"
        end),
    }

    return window
end

--==================================================
-- FRAMEWORK HELPERS
--==================================================

function AzothUI:GetParent()
    return GuiParent
end

function AzothUI:GetCapabilities()
    local result = {}

    for key, value in pairs({
        PlayerGui = GuiParent == LocalPlayer:FindFirstChildOfClass("PlayerGui"),
        GetHui = type(gethui) == "function",
        Loadstring = type(loadstring) == "function",
        HookFunction = type(hookfunction) == "function",
        NewCClosure = type(newcclosure) == "function",
    }) do
        result[key] = value
    end

    return result
end

function AzothUI:Destroy()
    if ScreenGui then
        ScreenGui:Destroy()
    end
end

return AzothUI
