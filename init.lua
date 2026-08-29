--==================================================
-- AZOTHUI v1.3.2
-- Compatibility-focused UI Framework
--==================================================

local AzothUI = {}

AzothUI.Name = "AzothUI"
AzothUI.Version = "1.3.4"

--==================================================
-- SERVICES
--==================================================

local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local HttpService = game:GetService("HttpService")

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
        Width = 720,
        Height = 500,
        MinWidth = 520,
        MinHeight = 360,
        MaxWidth = 1200,
        MaxHeight = 900,
        Radius = 14,
        HeaderHeight = 54,
        SidebarWidth = 205,
    },

    Logo = "rbxassetid://111606226814401",
}

Config.ThemeName = "Red"
AzothUI.Config = Config
AzothUI.Theme = Config.ThemeName

--==================================================
-- THEME / CONFIG MANAGER
--==================================================

local ThemePresets = {
    Red = {
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

    Dark = {
        Background = Color3.fromRGB(10, 11, 14),
        Sidebar = Color3.fromRGB(15, 16, 20),
        Surface = Color3.fromRGB(22, 23, 28),
        Surface2 = Color3.fromRGB(31, 33, 40),
        Border = Color3.fromRGB(55, 58, 68),
        Red = Color3.fromRGB(220, 32, 48),
        RedHover = Color3.fromRGB(238, 45, 61),
        Text = Color3.fromRGB(242, 243, 247),
        SubText = Color3.fromRGB(165, 168, 177),
        Muted = Color3.fromRGB(112, 116, 126),
        White = Color3.fromRGB(255, 255, 255),
    },
}

local ScreenGui

local ThemeBindings = {}
local RegisteredThemes = {}
for name, theme in pairs(ThemePresets) do
    RegisteredThemes[name] = theme
end

local function copyTheme(theme)
    local result = {}
    for key, value in pairs(theme or {}) do
        result[key] = value
    end
    return result
end

local function colorEquals(a, b)
    return typeof(a) == "Color3" and typeof(b) == "Color3"
        and math.abs(a.R - b.R) < 0.0001
        and math.abs(a.G - b.G) < 0.0001
        and math.abs(a.B - b.B) < 0.0001
end

local function findThemeKey(color)
    for key, themeColor in pairs(Config.Theme) do
        if colorEquals(color, themeColor) then
            return key
        end
    end
    return nil
end

local function registerThemeProperty(object, property, value)
    if typeof(value) ~= "Color3" then
        return
    end

    local key = findThemeKey(value)
    if not key then
        return
    end

    ThemeBindings[object] = ThemeBindings[object] or {}
    ThemeBindings[object][property] = key
end

local function applyTheme(theme, oldTheme)
    -- First update registered semantic bindings.
    for object, bindings in pairs(ThemeBindings) do
        if object and object.Parent then
            for property, key in pairs(bindings) do
                if theme[key] ~= nil then
                    pcall(function()
                        object[property] = theme[key]
                    end)
                end
            end
        else
            ThemeBindings[object] = nil
        end
    end

    -- Also catch colors assigned directly after creation (for example
    -- active tab states) by comparing the live GUI against the previous theme.
    if ScreenGui and ScreenGui.Parent and oldTheme then
        local function replaceProperty(object, property)
            local ok, current = pcall(function()
                return object[property]
            end)
            if not ok or typeof(current) ~= "Color3" then
                return
            end

            for key, oldColor in pairs(oldTheme) do
                if colorEquals(current, oldColor) and theme[key] ~= nil then
                    pcall(function()
                        object[property] = theme[key]
                    end)
                    break
                end
            end
        end

        for _, object in ipairs(ScreenGui:GetDescendants()) do
            replaceProperty(object, "BackgroundColor3")
            replaceProperty(object, "TextColor3")
            replaceProperty(object, "PlaceholderColor3")
            replaceProperty(object, "ImageColor3")
            replaceProperty(object, "ScrollBarImageColor3")
            if object:IsA("UIStroke") then
                replaceProperty(object, "Color")
            end
        end
    end
end

local function sanitizeConfigName(name)
    name = tostring(name or "Default")
    name = name:gsub("[^%w%-%._]", "_")
    if name == "" then
        name = "Default"
    end
    return "AzothUI_" .. name .. ".json"
end

local function hasFileApi()
    return type(isfile) == "function"
        and type(readfile) == "function"
        and type(writefile) == "function"
end

local function encodeConfigValue(value, depth)
    depth = depth or 0
    if depth > 8 then
        return nil
    end

    local valueType = typeof(value)

    if valueType == "EnumItem" then
        return {
            __azoth_type = "EnumItem",
            enumType = tostring(value.EnumType),
            name = value.Name,
        }
    end

    if valueType == "Color3" then
        return {
            __azoth_type = "Color3",
            r = value.R,
            g = value.G,
            b = value.B,
        }
    end

    if type(value) == "table" then
        local result = {}

        -- Preserve arrays as real JSON arrays. Converting numeric indexes
        -- to strings breaks ipairs() when the config is loaded again.
        local isArray = true
        local maxIndex = 0
        local count = 0

        for key in pairs(value) do
            if type(key) ~= "number" or key < 1 or key % 1 ~= 0 then
                isArray = false
                break
            end
            maxIndex = math.max(maxIndex, key)
            count += 1
        end

        if isArray and maxIndex ~= count then
            isArray = false
        end

        if isArray then
            for index = 1, maxIndex do
                local encoded = encodeConfigValue(value[index], depth + 1)
                if encoded ~= nil then
                    result[index] = encoded
                end
            end
        else
            for key, item in pairs(value) do
                local encoded = encodeConfigValue(item, depth + 1)
                if encoded ~= nil then
                    result[tostring(key)] = encoded
                end
            end
        end

        return result
    end

    if type(value) == "string" or type(value) == "number" or type(value) == "boolean" then
        return value
    end

    return nil
end

local function decodeConfigValue(value, depth)
    depth = depth or 0
    if depth > 8 then
        return nil
    end

    if type(value) ~= "table" then
        return value
    end

    if value.__azoth_type == "EnumItem" and value.enumType and value.name then
        local enumTypeString = tostring(value.enumType)
        local enumName = enumTypeString:match("Enum%.(.+)") or enumTypeString

        -- Robust Enum lookup. Some executors/JSON paths stringify
        -- EnumType differently, so always normalize the Enum name first.
        local enumObject = Enum[enumName]
        if enumObject then
            local ok, item = pcall(function()
                return enumObject[value.name]
            end)
            if ok and item then
                return item
            end
        end

        -- Explicit KeyCode fallback.
        if enumName == "KeyCode" then
            local ok, item = pcall(function()
                return Enum.KeyCode[value.name]
            end)
            if ok and item then
                return item
            end
        end
    end

    if value.__azoth_type == "Color3" then
        return Color3.new(
            tonumber(value.r) or 0,
            tonumber(value.g) or 0,
            tonumber(value.b) or 0
        )
    end

    local result = {}
    for key, item in pairs(value) do
        result[key] = decodeConfigValue(item, depth + 1)
    end
    return result
end


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
        registerThemeProperty(object, property, value)
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
    registerThemeProperty(stroke, "Color", stroke.Color)
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
    }, parent)
end

local function Hover(object, normalColor, hoverColor, duration)
    local normalKey = findThemeKey(normalColor)
    local hoverKey = findThemeKey(hoverColor)

    object.MouseEnter:Connect(function()
        Tween(object, duration or 0.12, {
            BackgroundColor3 = (hoverKey and Config.Theme[hoverKey]) or hoverColor
        })
    end)

    object.MouseLeave:Connect(function()
        Tween(object, duration or 0.12, {
            BackgroundColor3 = (normalKey and Config.Theme[normalKey]) or normalColor
        })
    end)
end

local function MakeDraggable(handle, target)
    local state = {
        Dragging = false,
        Moved = false,
    }

    local dragStart
    local startPosition
    local DRAG_THRESHOLD = 5

    handle.InputBegan:Connect(function(input)
        if input.UserInputType ~= Enum.UserInputType.MouseButton1
        and input.UserInputType ~= Enum.UserInputType.Touch then
            return
        end

        state.Dragging = true
        state.Moved = false
        dragStart = input.Position
        startPosition = target.Position

        local connection
        connection = input.Changed:Connect(function()
            if input.UserInputState == Enum.UserInputState.End then
                state.Dragging = false

                -- Keep the click suppressed briefly after an actual drag.
                -- Roblox can fire MouseButton1Click immediately after InputEnded.
                if state.Moved then
                    task.delay(0.20, function()
                        state.Moved = false
                    end)
                end

                if connection then
                    connection:Disconnect()
                end
            end
        end)
    end)

    UserInputService.InputChanged:Connect(function(input)
        if not state.Dragging then
            return
        end

        if input.UserInputType ~= Enum.UserInputType.MouseMovement
        and input.UserInputType ~= Enum.UserInputType.Touch then
            return
        end

        local delta = input.Position - dragStart

        if math.abs(delta.X) >= DRAG_THRESHOLD
        or math.abs(delta.Y) >= DRAG_THRESHOLD then
            state.Moved = true
        end

        target.Position = UDim2.new(
            startPosition.X.Scale,
            startPosition.X.Offset + delta.X,
            startPosition.Y.Scale,
            startPosition.Y.Offset + delta.Y
        )
    end)

    return state
end

--==================================================
-- SCREEN GUI
--==================================================

ScreenGui = New("ScreenGui", {
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

    label.Size = UDim2.new(1, 0, 0, 26)
    label.LayoutOrder = self.Order

    self.Order += 1

    return label
end

function TabMethods:AddSeparator()
    local separator = New("Frame", {
        Size = UDim2.new(1, 0, 0, 1),
        BackgroundColor3 = Config.Theme.Border,
        BackgroundTransparency = 0.45,
        BorderSizePixel = 0,
        LayoutOrder = self.Order,
    }, self.Content)

    self.Order += 1
    return separator
end

function TabMethods:AddLink(data)
    data = data or {}

    local item = New("TextButton", {
        Size = UDim2.new(1, 0, 0, 40),
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        AutoButtonColor = false,
        Text = data.Title or "Link",
        TextColor3 = Config.Theme.RedHover,
        TextSize = 12,
        Font = Enum.Font.GothamMedium,
        TextXAlignment = Enum.TextXAlignment.Left,
        LayoutOrder = self.Order,
    }, self.Content)

    self.Order += 1

    item.MouseEnter:Connect(function()
        item.TextColor3 = Config.Theme.Text
    end)

    item.MouseLeave:Connect(function()
        item.TextColor3 = Config.Theme.RedHover
    end)

    item.MouseButton1Click:Connect(function()
        if type(data.Callback) == "function" then
            task.spawn(data.Callback)
        end
    end)

    return item
end

function TabMethods:AddButton(data)
    data = data or {}

    local button = New("TextButton", {
        Size = UDim2.new(1, 0, 0, data.Description and 58 or 46),
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

    title.Position = UDim2.fromOffset(15, data.Description and 4 or 0)
    title.Size = UDim2.new(1, -55, 0, data.Description and 25 or 46)

    if data.Description then
        local description = Text(
            button,
            data.Description,
            10,
            Config.Theme.SubText
        )

        description.Position = UDim2.fromOffset(15, 29)
        description.Size = UDim2.new(1, -55, 0, 18)
    end

    local arrow = Text(
        button,
        "›",
        20,
        Config.Theme.Muted,
        Enum.Font.GothamBold
    )

    arrow.Position = UDim2.new(1, -34, 0, 0)
    arrow.Size = UDim2.fromOffset(25, button.Size.Y.Offset)
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

    button.MouseEnter:Connect(function()
        if self.ActiveTab ~= tab then
            Tween(button, 0.12, {
                BackgroundColor3 = Config.Theme.Surface
            })
        end
    end)

    button.MouseLeave:Connect(function()
        if self.ActiveTab ~= tab then
            Tween(button, 0.12, {
                BackgroundColor3 = Config.Theme.Sidebar
            })
        end
    end)

    button.MouseButton1Click:Connect(function()
        if type(data.Callback) == "function" then
            task.spawn(data.Callback)
        end
    end)

    return {
        Instance = button,
        SetTitle = function(_, value)
            title.Text = tostring(value)
        end,
        SetDescription = function(_, value)
            if description then
                description.Text = tostring(value or "")
            end
        end,
        SetVisible = function(_, value)
            button.Visible = value == true
        end,
    }
end

function TabMethods:AddToggle(data)
    data = data or {}

    local value = data.Default == true

    local row = New("Frame", {
        Size = UDim2.new(1, 0, 0, 52),
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

    title.Position = UDim2.fromOffset(15, 0)
    title.Size = UDim2.new(1, -85, 1, 0)

    local switch = New("TextButton", {
        Size = UDim2.fromOffset(44, 24),
        Position = UDim2.new(1, -58, 0.5, -12),
        BackgroundColor3 = value and Config.Theme.Red or Config.Theme.Muted,
        BorderSizePixel = 0,
        AutoButtonColor = false,
        Text = "",
    }, row)

    Corner(switch, 12)
    registerThemeProperty(switch, "BackgroundColor3", value and Config.Theme.Red or Config.Theme.Muted)

    local knob = New("Frame", {
        Size = UDim2.fromOffset(18, 18),
        Position = value
            and UDim2.new(1, -21, 0.5, -9)
            or UDim2.new(0, 3, 0.5, -9),
        BackgroundColor3 = Config.Theme.White,
        BorderSizePixel = 0,
    }, switch)

    Corner(knob, 9)

    local function setValue(newValue, fire)
        value = newValue == true

        local switchColor = value and Config.Theme.Red or Config.Theme.Muted

        -- The toggle changes semantic color at runtime. Update its theme
        -- binding too, otherwise a later SetTheme() can force an enabled
        -- toggle back to the Muted color while GetValue() is still true.
        registerThemeProperty(switch, "BackgroundColor3", switchColor)

        Tween(switch, 0.15, {
            BackgroundColor3 = switchColor
        })

        Tween(knob, 0.15, {
            Position = value
                and UDim2.new(1, -21, 0.5, -9)
                or UDim2.new(0, 3, 0.5, -9)
        })

        if fire and type(data.Callback) == "function" then
            task.spawn(data.Callback, value)
        end
    end

    switch.MouseButton1Click:Connect(function()
        setValue(not value, true)
    end)

    local control = {
        Instance = row,
        GetValue = function()
            return value
        end,
        SetValue = function(_, newValue, fire)
            setValue(newValue, fire)
        end,
    }

    if data.Flag then
        self.Window:RegisterControl(data.Flag, control)
    end

    return control
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
        data.Title or data.Name or "Slider",
        12,
        Config.Theme.Text,
        Enum.Font.GothamMedium
    )

    title.Position = UDim2.fromOffset(15, 7)
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
        Size = UDim2.new(1, -30, 0, 5),
        Position = UDim2.fromOffset(15, 47),
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

    local control = {
        Instance = row,
        GetValue = function()
            return value
        end,
        SetValue = function(_, newValue, fire)
            apply(newValue, fire)
        end,
    }

    if data.Flag then
        self.Window:RegisterControl(data.Flag, control)
    end

    return control
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

    title.Position = UDim2.fromOffset(15, 0)
    title.Size = UDim2.new(0.4, 0, 1, 0)

    local selector = New("TextButton", {
        Size = UDim2.fromOffset(190, 34),
        Position = UDim2.new(1, -205, 0.5, -17),
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
        Size = UDim2.fromOffset(190, 0),
        Position = UDim2.new(1, -205, 1, 4),
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
        menu.Size = UDim2.fromOffset(190, 0)

        if fire and type(data.Callback) == "function" then
            task.spawn(data.Callback, current)
        end
    end

    for _, option in ipairs(values) do
        local item = New("TextButton", {
            Size = UDim2.new(1, -8, 0, 30),
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
                190,
                math.min(#values * 32 + 8, 180)
            )
        else
            menu.Size = UDim2.fromOffset(190, 0)
        end
    end)

    local control = {
        Instance = row,
        GetValue = function()
            return current
        end,
        SetValue = function(_, newValue, fire)
            setValue(newValue, fire)
        end,
        SetValues = function(_, newValues)
            values = type(newValues) == "table" and newValues or {}
            current = values[1] or "Select"
            selector.Text = tostring(current) .. "  ▾"

            for _, child in ipairs(menu:GetChildren()) do
                if child:IsA("TextButton") then
                    child:Destroy()
                end
            end

            for _, option in ipairs(values) do
                local item = New("TextButton", {
                    Size = UDim2.new(1, -8, 0, 30),
                    BackgroundColor3 = Config.Theme.Surface,
                    BorderSizePixel = 0,
                    AutoButtonColor = false,
                    Text = tostring(option),
                    TextColor3 = Config.Theme.Text,
                    TextSize = 11,
                    Font = Enum.Font.Gotham,
                    ZIndex = 31,
                }, menu)

                item.MouseButton1Click:Connect(function()
                    setValue(option, true)
                end)
            end
        end,
        Close = function()
            menu.Visible = false
            menu.Size = UDim2.fromOffset(190, 0)
        end,
    }

    if data.Flag then
        self.Window:RegisterControl(data.Flag, control)
    end

    return control
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

    title.Position = UDim2.fromOffset(15, 0)
    title.Size = UDim2.fromOffset(115, 58)

    local box = New("TextBox", {
        Size = UDim2.new(1, -145, 0, 34),
        Position = UDim2.fromOffset(130, 12),
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

    local control = {
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

    if data.Flag then
        self.Window:RegisterControl(data.Flag, control)
    end

    return control
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

    title.Position = UDim2.fromOffset(15, 8)
    title.Size = UDim2.new(1, -30, 0, 20)

    local content = Text(
        row,
        data.Content or "",
        11,
        Config.Theme.SubText
    )

    content.Position = UDim2.fromOffset(15, 31)
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
-- ADDITIONAL COMPONENTS (v1.1.0)
--==================================================

function TabMethods:AddLabel(data)
    data = data or {}

    local label = Text(
        self.Content,
        data.Text or data.Title or data.Name or "Label",
        tonumber(data.TextSize) or 11,
        data.Color or Config.Theme.SubText,
        data.Font or Enum.Font.Gotham
    )

    label.Size = UDim2.new(1, 0, 0, tonumber(data.Height) or 28)
    label.LayoutOrder = self.Order
    label.TextWrapped = data.Wrapped == true

    self.Order += 1

    return {
        Instance = label,
        SetText = function(_, value)
            label.Text = tostring(value)
        end,
        SetColor = function(_, value)
            if typeof(value) == "Color3" then
                label.TextColor3 = value
            end
        end,
    }
end

function TabMethods:AddKeybind(data)
    data = data or {}

    local current = data.Default
    if typeof(current) ~= "EnumItem" or current.EnumType ~= Enum.KeyCode then
        current = Enum.KeyCode.Unknown
    end

    local listening = false

    local row = New("Frame", {
        Size = UDim2.new(1, 0, 0, 52),
        BackgroundColor3 = Config.Theme.Surface,
        BorderSizePixel = 0,
        LayoutOrder = self.Order,
    }, self.Content)

    self.Order += 1
    Corner(row, 9)
    Border(row)

    local title = Text(
        row,
        data.Title or data.Name or "Keybind",
        13,
        Config.Theme.Text,
        Enum.Font.GothamMedium
    )

    title.Position = UDim2.fromOffset(15, 0)
    title.Size = UDim2.new(1, -145, 1, 0)

    local keyButton = New("TextButton", {
        Size = UDim2.fromOffset(105, 32),
        Position = UDim2.new(1, -118, 0.5, -16),
        BackgroundColor3 = Config.Theme.Surface2,
        BorderSizePixel = 0,
        AutoButtonColor = false,
        Text = current == Enum.KeyCode.Unknown and "None" or current.Name,
        TextColor3 = Config.Theme.Text,
        TextSize = 11,
        Font = Enum.Font.GothamMedium,
    }, row)

    Corner(keyButton, 7)
    Border(keyButton)

    local function refresh()
        keyButton.Text = listening
            and "Press key..."
            or (current == Enum.KeyCode.Unknown and "None" or current.Name)
    end

    local function setValue(newKey, fire)
        if typeof(newKey) == "EnumItem" and newKey.EnumType == Enum.KeyCode then
            current = newKey
        elseif newKey == nil then
            current = Enum.KeyCode.Unknown
        else
            return
        end

        listening = false
        refresh()

        if fire and type(data.Callback) == "function" then
            task.spawn(data.Callback, current)
        end
    end

    keyButton.MouseButton1Click:Connect(function()
        listening = not listening
        refresh()
    end)

    local inputConnection = UserInputService.InputBegan:Connect(function(input, processed)
        if not listening then
            return
        end

        if processed and input.UserInputType ~= Enum.UserInputType.Keyboard then
            return
        end

        if input.UserInputType == Enum.UserInputType.Keyboard then
            setValue(input.KeyCode, true)
        end
    end)

    Hover(keyButton, Config.Theme.Surface2, Config.Theme.Red, 0.1)

    local control = {
        Instance = row,
        GetValue = function()
            return current
        end,
        SetValue = function(_, newKey, fire)
            setValue(newKey, fire)
        end,
        Destroy = function()
            if inputConnection then
                inputConnection:Disconnect()
            end
            row:Destroy()
        end,
    }

    if data.Flag then
        self.Window:RegisterControl(data.Flag, control)
    end

    return control
end

function TabMethods:AddMultiDropdown(data)
    data = data or {}

    local values = data.Values or {}
    local selected = {}

    if type(data.Default) == "table" then
        for _, value in ipairs(data.Default) do
            selected[tostring(value)] = true
        end
    end

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
        data.Title or data.Name or "Multi Dropdown",
        13,
        Config.Theme.Text,
        Enum.Font.GothamMedium
    )

    title.Position = UDim2.fromOffset(15, 0)
    title.Size = UDim2.new(0.42, 0, 1, 0)

    local selector = New("TextButton", {
        Size = UDim2.fromOffset(190, 34),
        Position = UDim2.new(1, -205, 0.5, -17),
        BackgroundColor3 = Config.Theme.Surface2,
        BorderSizePixel = 0,
        AutoButtonColor = false,
        Text = "Select...",
        TextColor3 = Config.Theme.Text,
        TextSize = 11,
        Font = Enum.Font.GothamMedium,
        ZIndex = 20,
    }, row)

    Corner(selector, 7)
    Border(selector)

    local menu = New("Frame", {
        Size = UDim2.fromOffset(190, 0),
        BackgroundColor3 = Config.Theme.Surface,
        BorderSizePixel = 0,
        Visible = false,
        ClipsDescendants = true,
        ZIndex = 200,
    }, ScreenGui)

    Corner(menu, 7)
    Border(menu)

    local list = New("UIListLayout", {
        Padding = UDim.new(0, 2),
        SortOrder = Enum.SortOrder.LayoutOrder,
    }, menu)

    local function updateText()
        local result = {}
        for _, option in ipairs(values) do
            if selected[tostring(option)] then
                table.insert(result, tostring(option))
            end
        end

        selector.Text = #result == 0 and "Select..."
            or (#result <= 2 and table.concat(result, ", ") or tostring(#result) .. " selected")
    end

    local function positionMenu()
        local pos = selector.AbsolutePosition
        local size = selector.AbsoluteSize
        menu.Position = UDim2.fromOffset(pos.X, pos.Y + size.Y + 4)
    end

    local function rebuild()
        for _, child in ipairs(menu:GetChildren()) do
            if child:IsA("TextButton") then
                child:Destroy()
            end
        end

        for _, option in ipairs(values) do
            local key = tostring(option)
            local item = New("TextButton", {
                Size = UDim2.new(1, -8, 0, 30),
                BackgroundColor3 = selected[key] and Config.Theme.Surface2 or Config.Theme.Surface,
                BorderSizePixel = 0,
                AutoButtonColor = false,
                Text = (selected[key] and "✓ " or "  ") .. key,
                TextColor3 = Config.Theme.Text,
                TextSize = 11,
                Font = Enum.Font.Gotham,
                ZIndex = 201,
            }, menu)

            item.MouseButton1Click:Connect(function()
                selected[key] = not selected[key]
                rebuild()
                updateText()

                if type(data.Callback) == "function" then
                    local result = {}
                    for _, value in ipairs(values) do
                        if selected[tostring(value)] then
                            table.insert(result, value)
                        end
                    end
                    task.spawn(data.Callback, result)
                end
            end)

            item.MouseEnter:Connect(function()
                item.BackgroundColor3 = Config.Theme.Surface2
            end)

            item.MouseLeave:Connect(function()
                item.BackgroundColor3 = selected[key] and Config.Theme.Surface2 or Config.Theme.Surface
            end)
        end
    end

    selector.MouseButton1Click:Connect(function()
        menu.Visible = not menu.Visible
        if menu.Visible then
            rebuild()
            menu.Size = UDim2.fromOffset(190, math.min(#values * 32 + 8, 180))
            positionMenu()
        else
            menu.Size = UDim2.fromOffset(190, 0)
        end
    end)

    UserInputService.InputBegan:Connect(function(input)
        if not menu.Visible then
            return
        end

        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            local p = input.Position
            local a = menu.AbsolutePosition
            local b = a + menu.AbsoluteSize
            local s = selector.AbsolutePosition
            local e = s + selector.AbsoluteSize

            if (p.X < a.X or p.X > b.X or p.Y < a.Y or p.Y > b.Y)
            and (p.X < s.X or p.X > e.X or p.Y < s.Y or p.Y > e.Y) then
                menu.Visible = false
                menu.Size = UDim2.fromOffset(190, 0)
            end
        end
    end)

    updateText()

    local control = {
        Instance = row,
        GetValue = function()
            local result = {}
            for _, option in ipairs(values) do
                if selected[tostring(option)] then
                    table.insert(result, option)
                end
            end
            return result
        end,
        SetValue = function(_, newValues, fire)
            selected = {}
            if type(newValues) == "table" then
                for _, value in ipairs(newValues) do
                    selected[tostring(value)] = true
                end
            end
            updateText()
            rebuild()

            if fire and type(data.Callback) == "function" then
                local result = {}
                for _, value in ipairs(values) do
                    if selected[tostring(value)] then
                        table.insert(result, value)
                    end
                end
                task.spawn(data.Callback, result)
            end
        end,
        SetValues = function(_, newValues)
            values = type(newValues) == "table" and newValues or {}
            rebuild()
            updateText()
        end,
        Close = function()
            menu.Visible = false
            menu.Size = UDim2.fromOffset(190, 0)
        end,
    }

    if data.Flag then
        self.Window:RegisterControl(data.Flag, control)
    end

    return control
end

function TabMethods:SetTitle(value)
    if self.Label then
        self.Label.Text = tostring(value or "Tab")
    end
end

function TabMethods:SetIcon(value)
    if self.Icon then
        self.Icon.Text = tostring(value or "")
    end
end

function TabMethods:SetVisible(value)
    if self.Button then
        self.Button.Visible = value == true
    end
end

function TabMethods:Select()
    if self.Window then
        self.Window:SelectTab(self)
    end
end

function TabMethods:Destroy()
    if self.Destroyed then
        return
    end

    self.Destroyed = true

    for i, tab in ipairs(self.Window.Tabs) do
        if tab == self then
            table.remove(self.Window.Tabs, i)
            break
        end
    end

    if self.Button then self.Button:Destroy() end
    if self.Content then self.Content:Destroy() end

    if self.Window.ActiveTab == self then
        local nextTab = self.Window.Tabs[1]
        self.Window.ActiveTab = nil
        if nextTab then
            self.Window:SelectTab(nextTab)
        end
    end
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
        Size = UDim2.new(1, 0, 0, 44),
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
        Size = UDim2.new(0, 3, 1, -14),
        Position = UDim2.fromOffset(0, 7),
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

    iconLabel.Position = UDim2.fromOffset(9, 0)
    iconLabel.Size = UDim2.fromOffset(28, 44)
    iconLabel.TextXAlignment = Enum.TextXAlignment.Center

    local nameLabel = Text(
        button,
        title,
        12,
        Config.Theme.SubText,
        Enum.Font.GothamMedium
    )

    nameLabel.Position = UDim2.fromOffset(48, 0)
    nameLabel.Size = UDim2.new(1, -55, 1, 0)

    local content = New("ScrollingFrame", {
        Size = UDim2.new(1, -18, 1, -18),
        Position = UDim2.fromOffset(9, 9),
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        ScrollBarThickness = 3,
        ScrollBarImageColor3 = Config.Theme.Red,
        ScrollBarImageTransparency = 0.25,
        AutomaticCanvasSize = Enum.AutomaticSize.Y,
        CanvasSize = UDim2.new(),
        ScrollingDirection = Enum.ScrollingDirection.Y,
        Active = true,
        Visible = false,
        ZIndex = 19,
    }, self.ContentArea)

    New("UIListLayout", {
        Padding = UDim.new(0, 8),
        SortOrder = Enum.SortOrder.LayoutOrder,
    }, content)

    local tab = setmetatable({
        Window = self,
        Button = button,
        Accent = accent,
        Icon = iconLabel,
        Label = nameLabel,
        Content = content,
        Order = 1,
        Destroyed = false,
    }, TabMethods)

    table.insert(self.Tabs, tab)

    -- Route every tab click through the same selector. This is important
    -- for special tabs such as Theme; otherwise two content frames can
    -- remain visible at the same time.
    button.MouseButton1Click:Connect(function()
        self:SelectTab(tab)
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

--==================================================
-- HOME TAB
--==================================================

function WindowMethods:CreateHomeTab(data)
    if self.HomeTab and not self.HomeTab.Destroyed then
        return self.HomeTab
    end

    data = data or {}

    local tab = self:AddTab({
        Title = data.Title or "Home",
        Icon = data.Icon or "◆",
    })

    tab.IsHomeTab = true

    tab:AddSection(data.SectionTitle or "WELCOME")

    tab:AddParagraph({
        Title = data.WelcomeTitle or ("Welcome to " .. AzothUI.Name),
        Content = data.WelcomeText
            or "A lightweight and compatibility-focused Roblox UI framework. Use the menu on the left to get started.",
    })

    tab:AddSection(data.InfoSectionTitle or "INFORMATION")

    tab:AddParagraph({
        Title = "Version",
        Content = tostring(AzothUI.Version),
    })

    tab:AddParagraph({
        Title = "Current Theme",
        Content = tostring(AzothUI.Theme),
    })

    tab:AddParagraph({
        Title = data.StatusTitle or "Status",
        Content = data.StatusText or "UI loaded successfully and ready to use.",
    })

    tab:AddSection(data.HelpSectionTitle or "QUICK GUIDE")

    tab:AddLabel({
        Text = data.GuideText
            or "• Home — overview and information\n• Main — your controls and features\n• Theme — change the UI appearance",
        TextSize = 11,
        Height = 58,
        Wrapped = true,
    })

    self.HomeTab = tab
    return tab
end

--==================================================
-- THEME TAB
--==================================================

function WindowMethods:CreateThemeTab()
    if self.ThemeTab and not self.ThemeTab.Destroyed then
        return self.ThemeTab
    end

    local button = New("TextButton", {
        Name = "ThemeTab",
        Size = UDim2.new(1, 0, 0, 44),
        BackgroundColor3 = Config.Theme.Sidebar,
        BorderSizePixel = 0,
        AutoButtonColor = false,
        Text = "",
        LayoutOrder = 1000,
        ZIndex = 20,
    }, self.Sidebar)

    Corner(button, 9)

    local icon = Text(button, "◆", 12, Config.Theme.SubText)
    icon.Position = UDim2.fromOffset(9, 0)
    icon.Size = UDim2.fromOffset(28, 44)
    icon.TextXAlignment = Enum.TextXAlignment.Center

    local label = Text(button, "Theme", 12, Config.Theme.SubText, Enum.Font.GothamMedium)
    label.Position = UDim2.fromOffset(48, 0)
    label.Size = UDim2.new(1, -55, 1, 0)

    local accent = New("Frame", {
        Size = UDim2.new(0, 3, 1, -14),
        Position = UDim2.fromOffset(0, 7),
        BackgroundColor3 = Config.Theme.Red,
        BorderSizePixel = 0,
        Visible = false,
        ZIndex = 21,
    }, button)
    Corner(accent, 2)

    local content = New("ScrollingFrame", {
        Size = UDim2.new(1, -18, 1, -18),
        Position = UDim2.fromOffset(9, 9),
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        ScrollBarThickness = 3,
        ScrollBarImageColor3 = Config.Theme.Red,
        ScrollBarImageTransparency = 0.25,
        AutomaticCanvasSize = Enum.AutomaticSize.Y,
        CanvasSize = UDim2.new(),
        ScrollingDirection = Enum.ScrollingDirection.Y,
        Active = true,
        Visible = false,
        ZIndex = 19,
    }, self.ContentArea)

    New("UIListLayout", {
        Padding = UDim.new(0, 8),
        SortOrder = Enum.SortOrder.LayoutOrder,
    }, content)

    local heading = Text(content, "THEME", 10, Config.Theme.SubText, Enum.Font.GothamBold)
    heading.Size = UDim2.new(1, 0, 0, 26)
    heading.LayoutOrder = 1

    local current = New("Frame", {
        Size = UDim2.new(1, 0, 0, 52),
        BackgroundColor3 = Config.Theme.Surface,
        BorderSizePixel = 0,
        LayoutOrder = 2,
    }, content)
    Corner(current, 9)
    Border(current)

    local currentLabel = Text(current, "Current Theme", 12, Config.Theme.Text, Enum.Font.GothamMedium)
    currentLabel.Position = UDim2.fromOffset(15, 0)
    currentLabel.Size = UDim2.new(0.55, 0, 1, 0)

    local currentValue = Text(current, Config.ThemeName, 11, Config.Theme.SubText)
    currentValue.Position = UDim2.new(0.55, 0, 0, 0)
    currentValue.Size = UDim2.new(0.45, -15, 1, 0)
    currentValue.TextXAlignment = Enum.TextXAlignment.Right

    local function refreshCurrent()
        currentValue.Text = tostring(AzothUI.Theme)
    end

    local function addThemeButton(themeName, order)
        local themeButton = New("TextButton", {
            Size = UDim2.new(1, 0, 0, 52),
            BackgroundColor3 = Config.Theme.Surface,
            BorderSizePixel = 0,
            AutoButtonColor = false,
            Text = "",
            LayoutOrder = order,
        }, content)
        Corner(themeButton, 9)
        Border(themeButton)

        local nameLabel = Text(themeButton, themeName, 13, Config.Theme.Text, Enum.Font.GothamMedium)
        nameLabel.Position = UDim2.fromOffset(15, 0)
        nameLabel.Size = UDim2.new(1, -70, 1, 0)

        local check = Text(themeButton, "✓", 14, Config.Theme.Red, Enum.Font.GothamBold)
        check.Position = UDim2.new(1, -48, 0, 0)
        check.Size = UDim2.fromOffset(35, 52)
        check.TextXAlignment = Enum.TextXAlignment.Center
        check.Visible = AzothUI.Theme == themeName

        themeButton.MouseEnter:Connect(function()
            Tween(themeButton, 0.1, {BackgroundColor3 = Config.Theme.Surface2})
        end)

        themeButton.MouseLeave:Connect(function()
            Tween(themeButton, 0.1, {BackgroundColor3 = Config.Theme.Surface})
        end)

        themeButton.MouseButton1Click:Connect(function()
            local ok = AzothUI:SetTheme(themeName)
            if ok then
                refreshCurrent()
                for _, child in ipairs(content:GetChildren()) do
                    if child:IsA("TextButton") then
                        local marker = child:FindFirstChildOfClass("TextLabel")
                        if marker and marker ~= nameLabel then
                            -- check labels are updated below through named children
                        end
                    end
                end
                check.Visible = true
                for _, child in ipairs(content:GetChildren()) do
                    local marker = child:FindFirstChild("ThemeCheck")
                    if marker and marker ~= check then
                        marker.Visible = false
                    end
                end
            end
        end)

        check.Name = "ThemeCheck"
        return themeButton
    end

    addThemeButton("Red", 3)
    addThemeButton("Dark", 4)

    local info = Text(
        content,
        "Theme changes are applied live to the current window.",
        10,
        Config.Theme.Muted
    )
    info.Size = UDim2.new(1, 0, 0, 40)
    info.TextWrapped = true
    info.LayoutOrder = 5

    local tab = {
        Window = self,
        Button = button,
        Accent = accent,
        Icon = icon,
        Label = label,
        Content = content,
        Order = 6,
        Destroyed = false,
        IsThemeTab = true,
    }

    -- Theme is a normal tab as far as selection is concerned. Keeping it
    -- inside Window.Tabs prevents its content from remaining visible when
    -- another tab is selected.
    table.insert(self.Tabs, tab)

    local function selectThemeTab()
        self:SelectTab(tab)
    end

    function tab:Select()
        selectThemeTab()
    end

    function tab:SetTitle(value)
        label.Text = tostring(value or "Theme")
    end

    function tab:SetIcon(value)
        icon.Text = tostring(value or "")
    end

    function tab:SetVisible(value)
        button.Visible = value == true
    end

    function tab:Destroy()
        if self.Destroyed then return end
        self.Destroyed = true

        for i, existing in ipairs(self.Window.Tabs) do
            if existing == self then
                table.remove(self.Window.Tabs, i)
                break
            end
        end

        local wasActive = self.Window.ActiveTab == self
        button:Destroy()
        content:Destroy()
        self.Window.ThemeTab = nil

        if wasActive then
            self.Window.ActiveTab = nil
            local first = self.Window.Tabs[1]
            if first then
                self.Window:SelectTab(first)
            end
        end
    end

    button.MouseButton1Click:Connect(function()
        self:SelectTab(tab)
    end)

    self.ThemeTab = tab
    return tab
end

function WindowMethods:RegisterControl(flag, control)
    if not flag or flag == "" or type(control) ~= "table" then
        return control
    end

    self.Controls = self.Controls or {}
    local key = tostring(flag)
    self.Controls[key] = control

    if self.PendingConfig and self.PendingConfig[key] ~= nil
    and type(control.SetValue) == "function" then
        local value = decodeConfigValue(self.PendingConfig[key])
        pcall(control.SetValue, control, value, self.ConfigFireCallbacks == true)
        self.PendingConfig[key] = nil
    end

    return control
end

function WindowMethods:GetConfigData()
    local data = {}

    for flag, control in pairs(self.Controls or {}) do
        if type(control.GetValue) == "function" then
            local ok, value = pcall(control.GetValue, control)
            if ok then
                data[flag] = encodeConfigValue(value)
            end
        end
    end

    return data
end

function WindowMethods:ApplyConfigData(data, fire)
    if type(data) ~= "table" then
        return false
    end

    for flag, encodedValue in pairs(data) do
        local control = self.Controls and self.Controls[tostring(flag)]
        if control and type(control.SetValue) == "function" then
            local value = decodeConfigValue(encodedValue)
            pcall(control.SetValue, control, value, fire == true)
        end
    end

    return true
end

function WindowMethods:SaveConfig(name, extraData)
    if not hasFileApi() then
        return false, "File API unavailable"
    end

    local payload = {
        Version = AzothUI.Version,
        Theme = Config.ThemeName,
        Controls = self:GetConfigData(),
    }

    if type(extraData) == "table" then
        for key, value in pairs(extraData) do
            payload[key] = encodeConfigValue(value)
        end
    end

    local ok, encoded = pcall(HttpService.JSONEncode, HttpService, payload)
    if not ok then
        return false, "JSON encode failed"
    end

    local filename = sanitizeConfigName(name or self.ConfigName or "Default")
    local writeOk, writeErr = pcall(writefile, filename, encoded)
    if not writeOk then
        return false, tostring(writeErr or "writefile failed")
    end

    return true, filename
end

function WindowMethods:LoadConfig(name, fire)
    if not hasFileApi() then
        return false, "File API unavailable"
    end

    local filename = sanitizeConfigName(name or self.ConfigName or "Default")
    if type(isfile) == "function" and not isfile(filename) then
        return false, "Config not found"
    end

    local okRead, raw = pcall(readfile, filename)
    if not okRead then
        return false, tostring(raw)
    end

    local okDecode, payload = pcall(HttpService.JSONDecode, HttpService, raw)
    if not okDecode or type(payload) ~= "table" then
        return false, "Invalid config JSON"
    end

    -- Accept the v1.2-style flat config format as well.
    local controls = payload.Controls or payload
    if payload.Controls then
        if type(payload.Theme) == "string" then
            AzothUI:SetTheme(payload.Theme)
        end
    end

    self.PendingConfig = controls
    self:ApplyConfigData(controls, fire)
    return true, payload
end

function WindowMethods:HasConfig(name)
    if type(isfile) ~= "function" then
        return false
    end
    return isfile(sanitizeConfigName(name or self.ConfigName or "Default")) == true
end

function WindowMethods:DeleteConfig(name)
    if type(isfile) ~= "function" or type(delfile) ~= "function" then
        return false, "File API unavailable"
    end

    local filename = sanitizeConfigName(name or self.ConfigName or "Default")
    if not isfile(filename) then
        return false, "Config not found"
    end

    local ok, err = pcall(delfile, filename)
    if not ok then
        return false, tostring(err or "delfile failed")
    end

    return true
end

function WindowMethods:SelectTab(tab)
    if not tab or tab.Destroyed then
        return false
    end

    -- HARD RESET: hide every tab content directly under ContentArea.
    -- This also covers ThemeTab even if a caller created it through an
    -- older/custom path and it was not present in Window.Tabs.
    if self.ContentArea then
        for _, child in ipairs(self.ContentArea:GetChildren()) do
            if child:IsA("ScrollingFrame") then
                child.Visible = false
            end
        end
    end

    -- Reset registered tab buttons.
    for _, other in ipairs(self.Tabs) do
        if other and not other.Destroyed then
            if other.Content then other.Content.Visible = false end
            if other.Accent then other.Accent.Visible = false end
            if other.Button then
                other.Button.BackgroundColor3 = Config.Theme.Sidebar
            end
            if other.Label then
                other.Label.TextColor3 = Config.Theme.SubText
            end
        end
    end

    -- Activate exactly one tab.
    if tab.Content then tab.Content.Visible = true end
    if tab.Accent then tab.Accent.Visible = true end
    if tab.Button then tab.Button.BackgroundColor3 = Config.Theme.Surface2 end
    if tab.Label then tab.Label.TextColor3 = Config.Theme.Text end
    self.ActiveTab = tab

    return true
end

function WindowMethods:Toggle()
    if self.Main.Visible then
        self:Minimize()
    else
        self:Maximize()
    end
end

function WindowMethods:IsMinimized()
    return self.Mini.Visible == true and self.Main.Visible == false
end

function WindowMethods:SetVisible(value)
    value = value == true
    self.Main.Visible = value
    if value then
        self.Mini.Visible = false
    end
end

function WindowMethods:GetActiveTab()
    return self.ActiveTab
end

function WindowMethods:SetSidebarVisible(value)
    if self.Sidebar then
        self.Sidebar.Visible = value == true
    end
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
    width = math.clamp(
        tonumber(width) or Config.Window.Width,
        Config.Window.MinWidth,
        Config.Window.MaxWidth
    )

    height = math.clamp(
        tonumber(height) or Config.Window.Height,
        Config.Window.MinHeight,
        Config.Window.MaxHeight
    )

    self.Main.Size = UDim2.fromOffset(width, height)
end

function WindowMethods:GetSize()
    return self.Main.AbsoluteSize
end

function WindowMethods:SetLogo(asset)
    self.Mini.Image = tostring(asset)
end

function WindowMethods:Minimize()
    self.Main.Visible = false
    self.Mini.Visible = true

    if self.Callbacks and type(self.Callbacks.OnMinimize) == "function" then
        task.spawn(self.Callbacks.OnMinimize, self)
    end
end

function WindowMethods:Maximize()
    self.Main.Visible = true
    self.Mini.Visible = false

    if self.Callbacks and type(self.Callbacks.OnMaximize) == "function" then
        task.spawn(self.Callbacks.OnMaximize, self)
    end
end

function WindowMethods:Close()
    if self.Destroyed then
        return
    end

    if self.AutoSaveConfig then
        pcall(function()
            self:SaveConfig(self.ConfigName)
        end)
    end

    self.Destroyed = true

    if self.Callbacks and type(self.Callbacks.OnClose) == "function" then
        task.spawn(self.Callbacks.OnClose, self)
    end

    if self.Grip then
        self.Grip:Destroy()
    end

    if self.Mini then
        self.Mini:Destroy()
    end

    if self.Main then
        self.Main:Destroy()
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

    --==================================================
    -- SINGLE WINDOW SURFACE
    --==================================================
    -- Kita kembalikan ke Frame karena CanvasGroup rusak di banyak executor.
    
    local main = New("Frame", {
        Name = "Window",
        Size = UDim2.fromOffset(width, height),
        Position = UDim2.new(0.5, 0, 0.5, 0),
        AnchorPoint = Vector2.new(0.5, 0.5),
        BackgroundColor3 = Config.Theme.Background,
        BorderSizePixel = 0,
        ClipsDescendants = true,
        ZIndex = 10,
    }, ScreenGui)

    Corner(main, Config.Window.Radius)
    Border(main, Config.Theme.Border, 1, 0)

    --==================================================
    -- HEADER
    --==================================================

    local header = New("Frame", {
        Size = UDim2.new(1, 0, 0, Config.Window.HeaderHeight),
        BackgroundColor3 = Config.Theme.Background,
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        ZIndex = 15,
    }, main)

    local title = Text(
        header,
        data.Title or "AZOTH LOADER",
        16,
        Config.Theme.Text,
        Enum.Font.GothamBold
    )

    title.Position = UDim2.fromOffset(22, 0)
    title.Size = UDim2.new(1, -180, 1, 0)

    local version = Text(
        header,
        data.Version or AzothUI.Version,
        10,
        Config.Theme.SubText
    )

    version.Position = UDim2.new(1, -145, 0, 0)
    version.Size = UDim2.fromOffset(65, Config.Window.HeaderHeight)

    local minimize = New("TextButton", {
        Size = UDim2.fromOffset(32, 32),
        Position = UDim2.new(1, -80, 0.5, -16),
        BackgroundColor3 = Config.Theme.Surface2,
        BorderSizePixel = 0,
        AutoButtonColor = false,
        Text = "—",
        TextColor3 = Config.Theme.Text,
        TextSize = 17,
        Font = Enum.Font.GothamMedium,
        ZIndex = 20,
    }, header)

    Corner(minimize, 8)

    local close = New("TextButton", {
        Size = UDim2.fromOffset(32, 32),
        Position = UDim2.new(1, -42, 0.5, -16),
        BackgroundColor3 = Config.Theme.Surface2,
        BorderSizePixel = 0,
        AutoButtonColor = false,
        Text = "×",
        TextColor3 = Config.Theme.Text,
        TextSize = 16,
        Font = Enum.Font.GothamMedium,
        ZIndex = 20,
    }, header)

    Corner(close, 8)

    local divider = New("Frame", {
        Size = UDim2.new(1, 0, 0, 1),
        Position = UDim2.fromOffset(0, Config.Window.HeaderHeight - 1),
        BackgroundColor3 = Config.Theme.Border,
        BackgroundTransparency = 0.45,
        BorderSizePixel = 0,
        ZIndex = 16,
    }, main)

    --==================================================
    -- SIDEBAR (FOOLPROOF CORNER METHOD)
    --==================================================

    -- 1. Buat background untuk sidebar yang memiliki UICorner
    local sidebarBg = New("Frame", {
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
    }, main)

    Corner(sidebarBg, Config.Window.Radius)

    -- 2. Tambal sudut ATAS sidebar agar menjadi kotak siku (bukan lengkung)
    New("Frame", {
        Size = UDim2.new(1, 0, 0, Config.Window.Radius),
        Position = UDim2.new(0, 0, 0, 0),
        BackgroundColor3 = Config.Theme.Sidebar,
        BorderSizePixel = 0,
        ZIndex = 14,
    }, sidebarBg)

    -- 3. Tambal sudut KANAN sidebar agar tersambung rata dengan konten
    New("Frame", {
        Size = UDim2.new(0, Config.Window.Radius, 1, 0),
        Position = UDim2.new(1, -Config.Window.Radius, 0, 0),
        BackgroundColor3 = Config.Theme.Sidebar,
        BorderSizePixel = 0,
        ZIndex = 14,
    }, sidebarBg)

    -- 4. Container asli untuk isi menu (dibuat transparan)
    local sidebar = New("ScrollingFrame", {
        Size = UDim2.new(1, 0, 1, 0),
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        ScrollBarThickness = 3,
        ScrollBarImageColor3 = Config.Theme.Red,
        ScrollBarImageTransparency = 0.25,
        AutomaticCanvasSize = Enum.AutomaticSize.Y,
        CanvasSize = UDim2.new(),
        ScrollingDirection = Enum.ScrollingDirection.Y,
        Active = true,
        ZIndex = 15,
    }, sidebarBg)

    New("UIPadding", {
        PaddingLeft = UDim.new(0, 12),
        PaddingRight = UDim.new(0, 12),
        PaddingTop = UDim.new(0, 14),
        PaddingBottom = UDim.new(0, 14),
    }, sidebar)

    New("UIListLayout", {
        Padding = UDim.new(0, 7),
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

    --==================================================
    -- CONTENT
    --==================================================
    -- Dibuat transparan agar mewarisi lengkungan & warna sempurna dari `main`
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
        BackgroundTransparency = 1, 
        BorderSizePixel = 0,
        ClipsDescendants = true,
        ZIndex = 13,
    }, main)

    --==================================================
    -- MINI LOGO
    --==================================================

    local mini = New("ImageButton", {
        Name = "MiniLogo",
        Size = UDim2.fromOffset(45, 45),
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

    Corner(mini, 22.5)
    Border(mini, Config.Theme.Border)

    --==================================================
    -- WINDOW OBJECT
    --==================================================

    local window = setmetatable({
        Main = main,
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
        Connections = {},
        Controls = {},
        ConfigName = data.ConfigName or (type(data.Config) == "table" and data.Config.Name) or "Default",
        AutoSaveConfig = type(data.Config) == "table" and data.Config.AutoSave == true,
        ConfigFireCallbacks = type(data.Config) == "table" and data.Config.FireCallbacks == true,
        Callbacks = {
            OnMinimize = data.OnMinimize,
            OnMaximize = data.OnMaximize,
            OnClose = data.OnClose,
        },
    }, WindowMethods)

    --==================================================
    -- DRAG
    --==================================================

    MakeDraggable(header, main)
    local miniDragState = MakeDraggable(mini, mini)

    --==================================================
    -- RESIZE GRIP
    --==================================================

    local gripInset = 6

    local grip = New("TextButton", {
        Name = "ResizeGrip",
        AnchorPoint = Vector2.new(1, 1),
        Position = UDim2.new(1, -gripInset, 1, -gripInset),
        Size = UDim2.fromOffset(20, 20),
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        AutoButtonColor = false,
        Text = "",
        Active = true,
        Selectable = false,
        ZIndex = 300,
    }, main)

    window.Grip = grip

    local gripDots = {}

    local function addGripDot(x, y)
        local dot = New("Frame", {
            Size = UDim2.fromOffset(3, 3),
            Position = UDim2.fromOffset(x, y),
            BackgroundColor3 = Config.Theme.SubText,
            BackgroundTransparency = 0.42,
            BorderSizePixel = 0,
            Active = false,
            ZIndex = 301,
        }, grip)

        Corner(dot, 2)
        table.insert(gripDots, dot)
    end

    addGripDot(13, 13)
    addGripDot(13, 8)
    addGripDot(8, 13)
    addGripDot(13, 3)
    addGripDot(8, 8)
    addGripDot(3, 13)

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

        local newWidth = math.clamp(
            startingSize.X + delta.X,
            Config.Window.MinWidth,
            Config.Window.MaxWidth
        )

        local newHeight = math.clamp(
            startingSize.Y + delta.Y,
            Config.Window.MinHeight,
            Config.Window.MaxHeight
        )

        main.Size = UDim2.fromOffset(newWidth, newHeight)
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
        -- A drag should move the mini logo only; releasing the mouse
        -- must NOT immediately maximize the window.
        if miniDragState.Moved then
            miniDragState.Moved = false
            return
        end

        window:Maximize()
    end)

    close.MouseButton1Click:Connect(function()
        window:Close()
    end)

    -- Optional config behavior. Disabled by default so existing scripts
    -- remain unchanged.
    if type(data.Config) == "table" then
        local configData = data.Config
        if configData.AutoLoad == true then
            task.defer(function()
                window:LoadConfig(configData.Name or window.ConfigName, configData.FireCallbacks == true)
            end)
        end

    end

    window.Capabilities = {
        FileAPI = hasFileApi(),
        IsFile = type(isfile) == "function",
        ReadFile = type(readfile) == "function",
        WriteFile = type(writefile) == "function",
        DeleteFile = type(delfile) == "function",
        ThemeSystem = true,
        ConfigSystem = true,
        PlayerGui = GuiParent == LocalPlayer:FindFirstChildOfClass("PlayerGui"),
        GetHui = type(gethui) == "function",
        Loadstring = type(loadstring) == "function",
        HttpGet = pcall(function()
            return type(game.HttpGet) == "function"
        end),
    }

    -- Home is created first so a fresh execution never opens to an empty
    -- content area. It becomes the initial active tab automatically.
    if data.HomeTab ~= false then
        window:CreateHomeTab(data.Home or {})
    end

    -- Create Theme after Home and the user's normal tabs so it participates
    -- in the same selection system. Home remains the default tab.
    if data.ThemeTab ~= false then
        window:CreateThemeTab()
    end

    return window
end

--==================================================
-- FRAMEWORK HELPERS
--==================================================

function AzothUI:GetTheme()
    return copyTheme(Config.Theme)
end

function AzothUI:RegisterTheme(name, theme)
    name = tostring(name or "")
    if name == "" or type(theme) ~= "table" then
        return false, "Invalid theme"
    end

    local merged = copyTheme(Config.Theme)
    for key, value in pairs(theme) do
        if typeof(value) == "Color3" then
            merged[key] = value
        end
    end

    RegisteredThemes[name] = merged
    return true
end

function AzothUI:SetTheme(theme)
    local selected

    local themeName

    if type(theme) == "string" then
        selected = RegisteredThemes[theme]
        if not selected then
            return false, "Unknown theme: " .. theme
        end
        themeName = theme
    elseif type(theme) == "table" then
        selected = copyTheme(Config.Theme)
        for key, value in pairs(theme) do
            if typeof(value) == "Color3" then
                selected[key] = value
            end
        end
        themeName = "Custom"
    else
        return false, "Theme must be a name or table"
    end

    local oldTheme = copyTheme(Config.Theme)
    Config.Theme = copyTheme(selected)
    Config.ThemeName = themeName or "Custom"
    AzothUI.Theme = Config.ThemeName
    applyTheme(Config.Theme, oldTheme)
    return true
end

function AzothUI:GetThemes()
    local names = {}
    for name in pairs(RegisteredThemes) do
        table.insert(names, name)
    end
    table.sort(names)
    return names
end

function AzothUI:SaveConfig(name, data)
    if not hasFileApi() then
        return false, "File API unavailable"
    end

    local encodedData = encodeConfigValue(data or {})
    local ok, encoded = pcall(HttpService.JSONEncode, HttpService, encodedData)
    if not ok then
        return false, "JSON encode failed"
    end

    local filename = sanitizeConfigName(name or "Default")
    local writeOk, err = pcall(writefile, filename, encoded)
    if not writeOk then
        return false, tostring(err or "writefile failed")
    end

    return true, filename
end

function AzothUI:LoadConfig(name)
    if not hasFileApi() then
        return false, "File API unavailable"
    end

    local filename = sanitizeConfigName(name or "Default")
    if type(isfile) == "function" and not isfile(filename) then
        return false, "Config not found"
    end

    local okRead, raw = pcall(readfile, filename)
    if not okRead then
        return false, tostring(raw)
    end

    local okDecode, data = pcall(HttpService.JSONDecode, HttpService, raw)
    if not okDecode or type(data) ~= "table" then
        return false, "Invalid config JSON"
    end

    return true, decodeConfigValue(data)
end

function AzothUI:HasConfig(name)
    return type(isfile) == "function"
        and isfile(sanitizeConfigName(name or "Default")) == true
end

function AzothUI:DeleteConfig(name)
    if type(isfile) ~= "function" or type(delfile) ~= "function" then
        return false, "File API unavailable"
    end

    local filename = sanitizeConfigName(name or "Default")
    if not isfile(filename) then
        return false, "Config not found"
    end

    local ok, err = pcall(delfile, filename)
    if not ok then
        return false, tostring(err or "delfile failed")
    end

    return true
end

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
        FileAPI = hasFileApi(),
        IsFile = type(isfile) == "function",
        ReadFile = type(readfile) == "function",
        WriteFile = type(writefile) == "function",
        DeleteFile = type(delfile) == "function",
        ThemeSystem = true,
        ConfigSystem = true,
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
