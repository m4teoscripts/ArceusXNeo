--[[
    ArceusXLibrary.lua
    Modern lightweight Roblox UI library

    Features:
    - Window / Tabs / scrolling content
    - Button / Toggle / Slider / Dropdown
    - ColorPicker with preview + Aceptar/Cancelar
    - Notifications
    - Minimize / Close / Dragging
    - Smooth animations + click sounds
    - RGB exterior border (not individual controls)
    - Header profile avatar between library name and minimize
    - Mobile / PC friendly
]]

local ArceusUI = {}

local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local SoundService = game:GetService("SoundService")

local LocalPlayer = Players.LocalPlayer
local PlayerGui = LocalPlayer:WaitForChild("PlayerGui")

local DEFAULTS = {
    Name = "ArceusUI",
    Subtitle = "Arceus X UI Library",
    Size = UDim2.fromOffset(520, 360),
    Position = UDim2.fromScale(0.5, 0.5),
    RGB = false,
    BorderColor = Color3.fromRGB(75, 75, 82),
    BorderThickness = 1,
    BorderRadius = 16,
    Sounds = true,
    AnimationSpeed = 0.22,
    ShowProfile = true,
    ProfileName = nil,
    ProfileUsername = nil,
    ProfileImage = nil,
    KeySystem = false,
    Theme = "Midnight",
    ConfigFolder = "ArceusX",
    Watermark = false,
}

local Library = { Windows = {} }

local function Create(className, properties, parent)
    local object = Instance.new(className)
    for property, value in pairs(properties or {}) do
        object[property] = value
    end
    if parent then
        object.Parent = parent
    end
    return object
end

local function Tween(object, properties, duration, style, direction)
    if not object or not object.Parent then return nil end
    local info = TweenInfo.new(
        duration or DEFAULTS.AnimationSpeed,
        style or Enum.EasingStyle.Quint,
        direction or Enum.EasingDirection.Out
    )
    local tween = TweenService:Create(object, info, properties)
    tween:Play()
    return tween
end

local function Corner(parent, radius)
    return Create("UICorner", {
        CornerRadius = UDim.new(0, radius or 8)
    }, parent)
end

local function Stroke(parent, color, thickness, transparency)
    return Create("UIStroke", {
        Color = color or Color3.fromRGB(70, 70, 75),
        Thickness = thickness or 1,
        Transparency = transparency or 0,
        ApplyStrokeMode = Enum.ApplyStrokeMode.Border
    }, parent)
end

local function Padding(parent, left, right, top, bottom)
    return Create("UIPadding", {
        PaddingLeft = UDim.new(0, left or 0),
        PaddingRight = UDim.new(0, right or 0),
        PaddingTop = UDim.new(0, top or 0),
        PaddingBottom = UDim.new(0, bottom or 0)
    }, parent)
end

local function PlayClick(enabled)
    if not enabled then return end
    local sound = Create("Sound", {
        SoundId = "rbxassetid://6026984224",
        Volume = 0.28,
        PlaybackSpeed = 1
    }, SoundService)
    sound:Play()
    task.delay(2, function()
        if sound then sound:Destroy() end
    end)
end

local RGBStrokes = {}
local RGBRunning = false

local function StartRGB(stroke, enabled)
    if not enabled or not stroke then return end

    table.insert(RGBStrokes, stroke)

    if RGBRunning then return end
    RGBRunning = true

    task.spawn(function()
        while #RGBStrokes > 0 do
            local hue = (os.clock() * 0.12) % 1
            local color = Color3.fromHSV(hue, 0.9, 1)

            for i = #RGBStrokes, 1, -1 do
                local s = RGBStrokes[i]
                if s and s.Parent then
                    s.Color = color
                else
                    table.remove(RGBStrokes, i)
                end
            end

            task.wait()
        end
        RGBRunning = false
    end)
end

local function GetAvatar(imageOverride)
    if imageOverride and imageOverride ~= "" then
        return imageOverride
    end

    local ok, image = pcall(function()
        local content = Players:GetUserThumbnailAsync(
            LocalPlayer.UserId,
            Enum.ThumbnailType.HeadShot,
            Enum.ThumbnailSize.Size100x100
        )
        return content
    end)

    if ok then return image end
    return ""
end

function ArceusUI:Notify(data)
    data = data or {}
    local gui = self.ScreenGui
    if not gui then return end

    local holder = gui:FindFirstChild("Notifications")
    if not holder then
        holder = Create("Frame", {
            Name = "Notifications",
            BackgroundTransparency = 1,
            AnchorPoint = Vector2.new(1, 1),
            Position = UDim2.new(1, -15, 1, -15),
            Size = UDim2.fromOffset(300, 500),
            ZIndex = 100
        }, gui)
        Create("UIListLayout", {
            FillDirection = Enum.FillDirection.Vertical,
            VerticalAlignment = Enum.VerticalAlignment.Bottom,
            HorizontalAlignment = Enum.HorizontalAlignment.Right,
            Padding = UDim.new(0, 8)
        }, holder)
    end

    local notification = Create("Frame", {
        BackgroundColor3 = Color3.fromRGB(30, 30, 34),
        BackgroundTransparency = 0.04,
        Size = UDim2.fromOffset(285, 70),
        Position = UDim2.fromOffset(320, 0),
        ZIndex = 101
    }, holder)
    Corner(notification, 9)
    Stroke(notification, Color3.fromRGB(75, 75, 80), 1)

    local titleLabel = Create("TextLabel", {
        BackgroundTransparency = 1,
        Position = UDim2.fromOffset(14, 8),
        Size = UDim2.new(1, -25, 0, 20),
        Font = Enum.Font.GothamBold,
        Text = data.Title or "ArceusUI",
        TextColor3 = Color3.new(1, 1, 1),
        TextSize = 14,
        TextXAlignment = Enum.TextXAlignment.Left,
        ZIndex = 102
    }, notification)

    local contentLabel = Create("TextLabel", {
        BackgroundTransparency = 1,
        Position = UDim2.fromOffset(14, 30),
        Size = UDim2.new(1, -25, 0, 30),
        Font = Enum.Font.Gotham,
        Text = data.Content or "",
        TextColor3 = Color3.fromRGB(175, 175, 180),
        TextSize = 12,
        TextWrapped = true,
        TextXAlignment = Enum.TextXAlignment.Left,
        ZIndex = 102
    }, notification)

    Tween(notification, {Position = UDim2.fromOffset(0, 0)}, 0.3)

    task.delay(data.Duration or 3, function()
        if notification and notification.Parent then
            Tween(notification, {
                Position = UDim2.fromOffset(320, 0),
                BackgroundTransparency = 1
            }, 0.25)
            task.wait(0.3)
            if notification then notification:Destroy() end
        end
    end)
end


----------------------------------------------------------------
-- EXTENDED FEATURES
----------------------------------------------------------------
local THEMES = {
    Midnight = {Background=Color3.fromRGB(25,25,28), Surface=Color3.fromRGB(35,35,40), Button=Color3.fromRGB(45,45,50), Text=Color3.fromRGB(245,245,245), SubText=Color3.fromRGB(155,155,160), Border=Color3.fromRGB(70,70,75), Accent=Color3.fromRGB(125,80,255)},
    Ocean = {Background=Color3.fromRGB(18,25,32), Surface=Color3.fromRGB(25,36,46), Button=Color3.fromRGB(33,48,60), Text=Color3.fromRGB(240,248,255), SubText=Color3.fromRGB(145,175,195), Border=Color3.fromRGB(60,120,150), Accent=Color3.fromRGB(45,170,255)},
    Purple = {Background=Color3.fromRGB(27,20,35), Surface=Color3.fromRGB(40,30,50), Button=Color3.fromRGB(55,40,68), Text=Color3.fromRGB(248,242,255), SubText=Color3.fromRGB(175,155,190), Border=Color3.fromRGB(115,75,150), Accent=Color3.fromRGB(160,90,255)},
    Crimson = {Background=Color3.fromRGB(32,19,22), Surface=Color3.fromRGB(47,28,32), Button=Color3.fromRGB(64,36,42), Text=Color3.fromRGB(255,242,244), SubText=Color3.fromRGB(190,150,155), Border=Color3.fromRGB(130,55,65), Accent=Color3.fromRGB(235,65,85)},
    Emerald = {Background=Color3.fromRGB(18,30,25), Surface=Color3.fromRGB(27,44,36), Button=Color3.fromRGB(37,58,47), Text=Color3.fromRGB(240,255,248), SubText=Color3.fromRGB(145,180,160), Border=Color3.fromRGB(55,125,90), Accent=Color3.fromRGB(60,210,135)},
    Rose = {Background=Color3.fromRGB(32,21,28), Surface=Color3.fromRGB(48,31,42), Button=Color3.fromRGB(65,40,55), Text=Color3.fromRGB(255,245,250), SubText=Color3.fromRGB(195,160,180), Border=Color3.fromRGB(135,75,105), Accent=Color3.fromRGB(255,95,170)},
    Sunset = {Background=Color3.fromRGB(34,24,18), Surface=Color3.fromRGB(50,35,25), Button=Color3.fromRGB(70,47,30), Text=Color3.fromRGB(255,248,238), SubText=Color3.fromRGB(195,165,135), Border=Color3.fromRGB(145,85,45), Accent=Color3.fromRGB(255,145,55)},
    Amoled = {Background=Color3.fromRGB(0,0,0), Surface=Color3.fromRGB(12,12,12), Button=Color3.fromRGB(22,22,22), Text=Color3.fromRGB(250,250,250), SubText=Color3.fromRGB(145,145,145), Border=Color3.fromRGB(55,55,55), Accent=Color3.fromRGB(255,255,255)},
    Cyber = {Background=Color3.fromRGB(10,17,20), Surface=Color3.fromRGB(15,28,31), Button=Color3.fromRGB(20,42,45), Text=Color3.fromRGB(235,255,255), SubText=Color3.fromRGB(120,180,180), Border=Color3.fromRGB(35,130,135), Accent=Color3.fromRGB(0,255,210)},
    Monochrome = {Background=Color3.fromRGB(30,30,30), Surface=Color3.fromRGB(45,45,45), Button=Color3.fromRGB(60,60,60), Text=Color3.fromRGB(245,245,245), SubText=Color3.fromRGB(175,175,175), Border=Color3.fromRGB(110,110,110), Accent=Color3.fromRGB(220,220,220)},
}

local function SameColor(a,b)
    return a and b and math.abs(a.R-b.R)<0.002 and math.abs(a.G-b.G)<0.002 and math.abs(a.B-b.B)<0.002
end

local function ApplyThemeToGui(root, theme)
    local oldSurface = Color3.fromRGB(35,35,40)
    local oldButton = Color3.fromRGB(45,45,50)
    local oldBackground = Color3.fromRGB(25,25,28)
    local oldSub = Color3.fromRGB(150,150,155)
    local oldText = Color3.new(1,1,1)
    for _,obj in ipairs(root:GetDescendants()) do
        if obj:IsA("UIStroke") then
            if SameColor(obj.Color, Color3.fromRGB(70,70,75)) or SameColor(obj.Color, Color3.fromRGB(55,55,60)) then obj.Color=theme.Border end
        elseif obj:IsA("TextButton") then
            if SameColor(obj.BackgroundColor3, oldButton) or SameColor(obj.BackgroundColor3, oldSurface) then obj.BackgroundColor3=theme.Button end
            if SameColor(obj.TextColor3, oldText) or SameColor(obj.TextColor3, Color3.fromRGB(220,220,220)) then obj.TextColor3=theme.Text end
        elseif obj:IsA("TextLabel") then
            if SameColor(obj.TextColor3, oldText) then obj.TextColor3=theme.Text
            elseif SameColor(obj.TextColor3, oldSub) or SameColor(obj.TextColor3, Color3.fromRGB(175,175,180)) then obj.TextColor3=theme.SubText end
        elseif obj:IsA("Frame") then
            if SameColor(obj.BackgroundColor3, oldBackground) then obj.BackgroundColor3=theme.Background
            elseif SameColor(obj.BackgroundColor3, oldSurface) then obj.BackgroundColor3=theme.Surface
            elseif SameColor(obj.BackgroundColor3, oldButton) then obj.BackgroundColor3=theme.Button end
        end
    end
end

local function EncodeConfig(data)
    local HttpService=game:GetService("HttpService")
    return HttpService:JSONEncode(data or {})
end

local function DecodeConfig(raw)
    local HttpService=game:GetService("HttpService")
    local ok,result=pcall(function() return HttpService:JSONDecode(raw) end)
    return ok and result or nil
end

function ArceusUI:CreateWindow(options)
    options = options or {}
    local config = {}
    for key, value in pairs(DEFAULTS) do config[key] = value end
    for key, value in pairs(options) do config[key] = value end

    local ScreenGui = Create("ScreenGui", {
        Name = "ArceusXLibrary",
        ResetOnSpawn = false,
        ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
        IgnoreGuiInset = true
    })

    pcall(function() ScreenGui.Parent = game:GetService("CoreGui") end)
    if not ScreenGui.Parent then ScreenGui.Parent = PlayerGui end
    self.ScreenGui = ScreenGui

    -- Un único borde exterior para la ventana.
    -- El borde pertenece a la misma GUI para que las esquinas queden
    -- perfectamente alineadas y no haya dos rectángulos superpuestos.
    local Main = Create("Frame", {
        Name = "Main",
        AnchorPoint = Vector2.new(0.5, 0.5),
        Position = config.Position,
        Size = UDim2.fromOffset(0, 0),
        BackgroundColor3 = Color3.fromRGB(25, 25, 28),
        BorderSizePixel = 0,
        ClipsDescendants = true,
        ZIndex = 2
    }, ScreenGui)
    Corner(Main, config.BorderRadius)

    local MainStroke = Stroke(Main, config.BorderColor, config.BorderThickness)
    StartRGB(MainStroke, config.RGB)

    ----------------------------------------------------------------
    -- TOP BAR
    ----------------------------------------------------------------
    local TopBar = Create("Frame", {
        Name = "TopBar",
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        Position = UDim2.fromOffset(0, 0),
        Size = UDim2.new(1, 0, 0, 58),
        ZIndex = 3
    }, Main)
    local Title = Create("TextLabel", {
        BackgroundTransparency = 1,
        Position = UDim2.fromOffset(18, 10),
        Size = UDim2.new(1, -160, 0, 22),
        Font = Enum.Font.GothamBold,
        Text = config.Name,
        TextColor3 = Color3.new(1, 1, 1),
        TextSize = 16,
        TextXAlignment = Enum.TextXAlignment.Left,
        ZIndex = 4
    }, TopBar)

    local Subtitle = Create("TextLabel", {
        BackgroundTransparency = 1,
        Position = UDim2.fromOffset(18, 32),
        Size = UDim2.new(1, -160, 0, 18),
        Font = Enum.Font.Gotham,
        Text = config.Subtitle,
        TextColor3 = Color3.fromRGB(150, 150, 155),
        TextSize = 11,
        TextXAlignment = Enum.TextXAlignment.Left,
        ZIndex = 4
    }, TopBar)

    -- Foto de perfil del usuario entre el nombre y los controles.
    -- Es una imagen, NO un botón de texto.
    local HeaderProfile = Create("ImageLabel", {
        Name = "HeaderProfile",
        BackgroundColor3 = Color3.fromRGB(20, 20, 23),
        Position = UDim2.new(1, -108, 0, 15),
        Size = UDim2.fromOffset(28, 28),
        Image = GetAvatar(config.ProfileImage),
        ScaleType = Enum.ScaleType.Crop,
        ZIndex = 5
    }, TopBar)
    Corner(HeaderProfile, 14)

    local HeaderStatus = Create("Frame", {
        BackgroundColor3 = Color3.fromRGB(90, 205, 120),
        Position = UDim2.new(1, -83, 0, 35),
        Size = UDim2.fromOffset(8, 8),
        BorderSizePixel = 0,
        ZIndex = 6
    }, TopBar)
    Corner(HeaderStatus, 4)

    local Minimize = Create("TextButton", {
        BackgroundColor3 = Color3.fromRGB(45, 45, 50),
        Position = UDim2.new(1, -70, 0, 14),
        Size = UDim2.fromOffset(24, 24),
        AutoButtonColor = false,
        Font = Enum.Font.GothamBold,
        Text = "—",
        TextColor3 = Color3.fromRGB(220, 220, 220),
        TextSize = 15,
        ZIndex = 5
    }, TopBar)
    Corner(Minimize, 7)

    local Close = Create("TextButton", {
        BackgroundColor3 = Color3.fromRGB(45, 45, 50),
        Position = UDim2.new(1, -38, 0, 14),
        Size = UDim2.fromOffset(24, 24),
        AutoButtonColor = false,
        Font = Enum.Font.GothamBold,
        Text = "×",
        TextColor3 = Color3.fromRGB(220, 220, 220),
        TextSize = 18,
        ZIndex = 5
    }, TopBar)
    Corner(Close, 7)

    ----------------------------------------------------------------
    -- TAB BAR
    ----------------------------------------------------------------
    local TabBar = Create("ScrollingFrame", {
        Name = "TabBar",
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        Position = UDim2.fromOffset(2, 60),
        Size = UDim2.new(1, -4, 0, 40),
        ScrollBarThickness = 0,
        CanvasSize = UDim2.new(0, 0, 0, 0),
        AutomaticCanvasSize = Enum.AutomaticSize.X,
        ZIndex = 3
    }, Main)
    Padding(TabBar, 8, 8, 5, 5)
    Create("UIListLayout", {
        FillDirection = Enum.FillDirection.Horizontal,
        VerticalAlignment = Enum.VerticalAlignment.Center,
        Padding = UDim.new(0, 6)
    }, TabBar)

    ----------------------------------------------------------------
    -- CONTENT
    ----------------------------------------------------------------
    local Content = Create("Frame", {
        Name = "Content",
        BackgroundTransparency = 1,
        Position = UDim2.fromOffset(0, 102),
        Size = UDim2.new(1, 0, 1, -102),
        ZIndex = 3
    }, Main)

    ----------------------------------------------------------------
    -- PROFILE API
    ----------------------------------------------------------------
    -- The profile avatar is displayed in the header, between the title
    -- and the minimize button. There is intentionally no bottom profile card.
    local ProfileCard = nil
    local ProfileAvatar = HeaderProfile
    local ProfileDisplay = nil
    local ProfileUsername = nil

    ----------------------------------------------------------------
    -- MINIMIZED BUTTON
    ----------------------------------------------------------------
    local MiniButton = Create("TextButton", {
        Name = "MiniButton",
        AnchorPoint = Vector2.new(0, 0.5),
        Position = UDim2.new(0, 15, 0.5, 0),
        Size = UDim2.fromOffset(0, 0),
        BackgroundColor3 = Color3.fromRGB(12, 12, 14),
        AutoButtonColor = false,
        Visible = false,
        Font = Enum.Font.GothamBold,
        Text = "UI",
        TextColor3 = Color3.new(1, 1, 1),
        TextSize = 14,
        ZIndex = 50
    }, ScreenGui)
    Corner(MiniButton, 14)
    local MiniStroke = Stroke(MiniButton, config.BorderColor, config.BorderThickness)
    StartRGB(MiniStroke, config.RGB)

    ----------------------------------------------------------------
    -- DRAGGING
    ----------------------------------------------------------------
    local dragging = false
    local dragStart
    local startPosition

    TopBar.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1
            or input.UserInputType == Enum.UserInputType.Touch then
            dragging = true
            dragStart = input.Position
            startPosition = Main.Position
            input.Changed:Connect(function()
                if input.UserInputState == Enum.UserInputState.End then
                    dragging = false
                end
            end)
        end
    end)

    UserInputService.InputChanged:Connect(function(input)
        if dragging and (
            input.UserInputType == Enum.UserInputType.MouseMovement
            or input.UserInputType == Enum.UserInputType.Touch
        ) then
            local delta = input.Position - dragStart
            local newPosition = UDim2.new(
                startPosition.X.Scale,
                startPosition.X.Offset + delta.X,
                startPosition.Y.Scale,
                startPosition.Y.Offset + delta.Y
            )
            Main.Position = newPosition
        end
    end)

    ----------------------------------------------------------------
    -- OPEN ANIMATION
    ----------------------------------------------------------------
    Main.Size = UDim2.fromOffset(20, 20)
    Tween(Main, {Size = config.Size}, 0.38, Enum.EasingStyle.Back)


    local minimized = false
    local closed = false

    ----------------------------------------------------------------
    -- MINIMIZE
    ----------------------------------------------------------------
    Minimize.MouseButton1Click:Connect(function()
        if closed or minimized then return end
        PlayClick(config.Sounds)
        minimized = true

        Tween(Main, {Size = UDim2.fromOffset(0, 0)}, 0.25)
        task.wait(0.25)

        Main.Visible = false
        MiniButton.Visible = true
        MiniButton.Size = UDim2.fromOffset(0, 0)
        Tween(MiniButton, {Size = UDim2.fromOffset(50, 50)}, 0.28, Enum.EasingStyle.Back)
    end)

    ----------------------------------------------------------------
    -- RESTORE
    ----------------------------------------------------------------
    MiniButton.MouseButton1Click:Connect(function()
        if closed or not minimized then return end
        PlayClick(config.Sounds)
        MiniButton.Visible = false
        Main.Visible = true
        Main.Size = UDim2.fromOffset(0, 0)
        Tween(Main, {Size = config.Size}, 0.32, Enum.EasingStyle.Back)
        minimized = false
    end)

    ----------------------------------------------------------------
    -- CLOSE
    ----------------------------------------------------------------
    Close.MouseButton1Click:Connect(function()
        if closed then return end
        PlayClick(config.Sounds)
        closed = true
        Tween(Main, {Size = UDim2.fromOffset(0, 0)}, 0.25)
        task.wait(0.25)
        if ScreenGui then ScreenGui:Destroy() end
    end)

    local Window = {}
    Window.Main = Main
    Window.ScreenGui = ScreenGui
    Window.Border = MainStroke
    Window.Tabs = {}
    Window.ActiveTab = nil
    Window.Profile = ProfileCard

    Window._ConfigItems = {}
    function Window:RegisterConfig(key, getter, setter)
        if type(key) ~= "string" or key == "" then return end
        self._ConfigItems[key] = {Get=getter, Set=setter}
    end

    function Window:GetConfig()
        local data={}
        for key,item in pairs(self._ConfigItems) do
            if item.Get then
                local ok,value=pcall(item.Get)
                if ok then data[key]=value end
            end
        end
        return data
    end

    function Window:ApplyConfig(data)
        if type(data) ~= "table" then return false end
        for key,value in pairs(data) do
            local item=self._ConfigItems[key]
            if item and item.Set then pcall(item.Set,value) end
        end
        return true
    end

    function Window:SaveConfig(name)
        name=tostring(name or "Default")
        local data=self:GetConfig()
        if not (writefile and readfile) then return false,"Executor file API unavailable" end
        pcall(function() if makefolder and not isfolder(config.ConfigFolder) then makefolder(config.ConfigFolder) end end)
        local path=config.ConfigFolder.."/"..name..".json"
        local ok,err=pcall(function() writefile(path,EncodeConfig(data)) end)
        return ok,err
    end

    function Window:LoadConfig(name)
        name=tostring(name or "Default")
        if not (isfile and readfile) then return false,"Executor file API unavailable" end
        local path=config.ConfigFolder.."/"..name..".json"
        if not isfile(path) then return false,"Config not found" end
        local ok,raw=pcall(readfile,path)
        if not ok then return false,raw end
        local data=DecodeConfig(raw)
        if not data then return false,"Invalid config" end
        self:ApplyConfig(data)
        return true,data
    end

    function Window:SetTheme(name)
        local theme=THEMES[name]
        if not theme then return false end
        ApplyThemeToGui(ScreenGui,theme)
        Main.BackgroundColor3=theme.Background
        MainStroke.Color=theme.Border
        config.BorderColor=theme.Border
        return true
    end

    function Window:GetThemes()
        local list={}
        for name in pairs(THEMES) do table.insert(list,name) end
        table.sort(list)
        return list
    end

    ----------------------------------------------------------------
    -- PROFILE METHODS
    ----------------------------------------------------------------
    function Window:SetProfile(displayName, username, image)
        -- Header-only profile. DisplayName/username are optional and are kept
        -- for API compatibility; the visible element is the avatar.
        if image ~= nil and ProfileAvatar then
            ProfileAvatar.Image = tostring(image)
        end
    end

    ----------------------------------------------------------------
    -- CREATE TAB
    ----------------------------------------------------------------
    function Window:CreateTab(tabName)
        -- Compatibility: accept both CreateTab("Player") and CreateTab({Name = "Player"})
        if type(tabName) == "table" then
            tabName = tabName.Name or tabName.Title or "Tab"
        end
        tabName = tostring(tabName or "Tab")

        local TabButton = Create("TextButton", {
            BackgroundColor3 = Color3.fromRGB(38, 38, 43),
            AutoButtonColor = false,
            Size = UDim2.fromOffset(90, 30),
            Font = Enum.Font.GothamMedium,
            Text = tostring(tabName),
            TextColor3 = Color3.fromRGB(165, 165, 170),
            TextSize = 11,
            ZIndex = 4
        }, TabBar)
        Corner(TabButton, 7)

        local Page = Create("ScrollingFrame", {
            Name = tostring(tabName) .. "_Page",
            BackgroundTransparency = 1,
            Position = UDim2.fromOffset(8, 0),
            Size = UDim2.new(1, 0, 1, 0),
            Visible = false,
            ScrollBarThickness = 3,
            ScrollBarImageTransparency = 0.3,
            CanvasSize = UDim2.new(0, 0, 0, 0),
            AutomaticCanvasSize = Enum.AutomaticSize.Y,
            ZIndex = 4
        }, Content)
        Padding(Page, 12, 12, 12, 12)

        local Layout = Create("UIListLayout", {
            Padding = UDim.new(0, 8),
            SortOrder = Enum.SortOrder.LayoutOrder
        }, Page)

        local Tab = {Button = TabButton, Page = Page, Layout = Layout}
        table.insert(Window.Tabs, Tab)

        local function Activate()
            for _, other in ipairs(Window.Tabs) do
                other.Page.Visible = false
                Tween(other.Button, {
                    BackgroundColor3 = Color3.fromRGB(38, 38, 43),
                    TextColor3 = Color3.fromRGB(165, 165, 170)
                }, 0.15)
            end

            Page.Visible = true
            Page.Position = UDim2.fromOffset(12, 0)
            Tween(Page, {Position = UDim2.fromOffset(0, 0)}, 0.2, Enum.EasingStyle.Quint)
            Tween(TabButton, {
                BackgroundColor3 = Color3.fromRGB(65, 65, 72),
                TextColor3 = Color3.new(1, 1, 1)
            }, 0.15)
            Window.ActiveTab = Tab
        end

        TabButton.MouseButton1Click:Connect(function()
            PlayClick(config.Sounds)
            Activate()
        end)

        TabButton.MouseEnter:Connect(function()
            if Window.ActiveTab ~= Tab then
                Tween(TabButton, {BackgroundColor3 = Color3.fromRGB(48, 48, 54)}, 0.12)
            end
        end)
        TabButton.MouseLeave:Connect(function()
            if Window.ActiveTab ~= Tab then
                Tween(TabButton, {BackgroundColor3 = Color3.fromRGB(38, 38, 43)}, 0.12)
            end
        end)

        if #Window.Tabs == 1 then Activate() end

        ----------------------------------------------------------------
        -- BUTTON
        ----------------------------------------------------------------
        function Tab:CreateButton(data)
            data = data or {}
            local Button = Create("TextButton", {
                BackgroundColor3 = Color3.fromRGB(35, 35, 40),
                AutoButtonColor = false,
                Size = UDim2.new(1, 0, 0, 42),
                Font = Enum.Font.GothamMedium,
                Text = data.Name or "Button",
                TextColor3 = Color3.new(1, 1, 1),
                TextSize = 12,
                ZIndex = 5
            }, Page)
            Corner(Button, 8)

            Button.MouseEnter:Connect(function()
                Tween(Button, {BackgroundColor3 = Color3.fromRGB(45, 45, 50)}, 0.15)
            end)
            Button.MouseLeave:Connect(function()
                Tween(Button, {BackgroundColor3 = Color3.fromRGB(35, 35, 40)}, 0.15)
            end)
            Button.MouseButton1Down:Connect(function()
                Tween(Button, {BackgroundColor3 = Color3.fromRGB(55, 55, 62)}, 0.08)
            end)
            Button.MouseButton1Click:Connect(function()
                PlayClick(config.Sounds)
                if data.Callback then task.spawn(data.Callback) end
            end)
            return Button
        end

        ----------------------------------------------------------------
        -- TOGGLE
        ----------------------------------------------------------------
        function Tab:CreateToggle(data)
            data = data or {}
            local value = data.Default == true
            local Holder = Create("Frame", {
                BackgroundColor3 = Color3.fromRGB(35, 35, 40),
                Size = UDim2.new(1, 0, 0, 46),
                ZIndex = 5
            }, Page)
            Corner(Holder, 8)

            Create("TextLabel", {
                BackgroundTransparency = 1,
                Position = UDim2.fromOffset(13, 0),
                Size = UDim2.new(1, -70, 1, 0),
                Font = Enum.Font.GothamMedium,
                Text = data.Name or "Toggle",
                TextColor3 = Color3.new(1, 1, 1),
                TextSize = 12,
                TextXAlignment = Enum.TextXAlignment.Left,
                ZIndex = 6
            }, Holder)

            local Switch = Create("TextButton", {
                BackgroundColor3 = value and Color3.fromRGB(80, 150, 95) or Color3.fromRGB(60, 60, 65),
                Position = UDim2.new(1, -52, 0.5, -11),
                Size = UDim2.fromOffset(38, 22),
                AutoButtonColor = false,
                Text = "",
                ZIndex = 6
            }, Holder)
            Corner(Switch, 11)

            local Knob = Create("Frame", {
                BackgroundColor3 = Color3.new(1, 1, 1),
                Position = value and UDim2.new(1, -20, 0.5, -8) or UDim2.fromOffset(4, 3),
                Size = UDim2.fromOffset(16, 16),
                ZIndex = 7
            }, Switch)
            Corner(Knob, 8)

            local Toggle = {}
            function Toggle:Set(newValue)
                value = newValue == true
                Tween(Switch, {
                    BackgroundColor3 = value and Color3.fromRGB(80, 150, 95) or Color3.fromRGB(60, 60, 65)
                }, 0.15)
                Tween(Knob, {
                    Position = value and UDim2.new(1, -20, 0.5, -8) or UDim2.fromOffset(4, 3)
                }, 0.15)
                if data.Callback then task.spawn(data.Callback, value) end
            end
            Switch.MouseButton1Click:Connect(function()
                PlayClick(config.Sounds)
                Toggle:Set(not value)
            end)
            if data.ConfigKey then
                Window:RegisterConfig(data.ConfigKey, function() return value end, function(v) Toggle:Set(v) end)
            end
            return Toggle
        end

        ----------------------------------------------------------------
        -- SLIDER
        ----------------------------------------------------------------
        function Tab:CreateSlider(data)
            data = data or {}

            -- Supports both:
            --   Min / Max / Default
            -- and:
            --   Range = {min, max}
            local range = data.Range
            local min = data.Min
            local max = data.Max

            if type(range) == "table" then
                min = range[1] or min
                max = range[2] or max
            end

            min = tonumber(min) or 0
            max = tonumber(max) or 100
            if max <= min then max = min + 1 end

            local increment = tonumber(data.Increment) or 1
            if increment <= 0 then increment = 1 end

            local function Normalize(value)
                value = tonumber(value) or min
                value = math.clamp(value, min, max)
                value = min + math.floor(((value - min) / increment) + 0.5) * increment
                return math.clamp(value, min, max)
            end

            local current = Normalize(data.CurrentValue ~= nil and data.CurrentValue or data.Default or min)

            local Holder = Create("Frame", {
                BackgroundColor3 = Color3.fromRGB(35, 35, 40),
                Size = UDim2.new(1, 0, 0, 62),
                ZIndex = 5
            }, Page)
            Corner(Holder, 8)

            Create("TextLabel", {
                BackgroundTransparency = 1,
                Position = UDim2.fromOffset(13, 7),
                Size = UDim2.new(1, -80, 0, 20),
                Font = Enum.Font.GothamMedium,
                Text = data.Name or "Slider",
                TextColor3 = Color3.new(1, 1, 1),
                TextSize = 12,
                TextXAlignment = Enum.TextXAlignment.Left,
                ZIndex = 6
            }, Holder)

            local ValueLabel = Create("TextLabel", {
                BackgroundTransparency = 1,
                Position = UDim2.new(1, -65, 0, 7),
                Size = UDim2.fromOffset(52, 20),
                Font = Enum.Font.Gotham,
                Text = tostring(math.floor(current)),
                TextColor3 = Color3.fromRGB(170, 170, 175),
                TextSize = 11,
                TextXAlignment = Enum.TextXAlignment.Right,
                ZIndex = 6
            }, Holder)

            local Bar = Create("Frame", {
                BackgroundColor3 = Color3.fromRGB(55, 55, 60),
                Position = UDim2.fromOffset(13, 38),
                Size = UDim2.new(1, -26, 0, 7),
                ZIndex = 6
            }, Holder)
            Corner(Bar, 5)

            local percentage = (current - min) / (max - min)
            local Fill = Create("Frame", {
                BackgroundColor3 = Color3.fromRGB(125, 125, 135),
                Size = UDim2.new(percentage, 0, 1, 0),
                ZIndex = 7
            }, Bar)
            Corner(Fill, 5)

            local draggingSlider = false
            local function SetValue(value)
                current = Normalize(value)
                local percent = (current - min) / (max - min)
                ValueLabel.Text = tostring(math.floor(current))
                Tween(Fill, {Size = UDim2.new(percent, 0, 1, 0)}, 0.08)
                if data.Callback then task.spawn(data.Callback, current) end
            end
            local function UpdateFromInput(input)
                local relative = math.clamp(
                    (input.Position.X - Bar.AbsolutePosition.X) / Bar.AbsoluteSize.X,
                    0, 1
                )
                SetValue(min + (max - min) * relative)
            end

            Bar.InputBegan:Connect(function(input)
                if input.UserInputType == Enum.UserInputType.MouseButton1
                    or input.UserInputType == Enum.UserInputType.Touch then
                    draggingSlider = true
                    UpdateFromInput(input)
                end
            end)
            UserInputService.InputChanged:Connect(function(input)
                if draggingSlider and (
                    input.UserInputType == Enum.UserInputType.MouseMovement
                    or input.UserInputType == Enum.UserInputType.Touch
                ) then UpdateFromInput(input) end
            end)
            UserInputService.InputEnded:Connect(function(input)
                if input.UserInputType == Enum.UserInputType.MouseButton1
                    or input.UserInputType == Enum.UserInputType.Touch then
                    draggingSlider = false
                end
            end)

            local Slider = {}
            function Slider:Set(value) SetValue(value) end
            if data.ConfigKey then
                Window:RegisterConfig(data.ConfigKey, function() return current end, function(v) Slider:Set(v) end)
            end
            return Slider
        end

        ----------------------------------------------------------------
        -- DROPDOWN
        ----------------------------------------------------------------
        function Tab:CreateDropdown(data)
            data = data or {}
            local options = data.Options or {}
            local selected = data.Default or options[1] or "None"
            local opened = false

            local Holder = Create("Frame", {
                BackgroundColor3 = Color3.fromRGB(35, 35, 40),
                Size = UDim2.new(1, 0, 0, 44),
                ClipsDescendants = true,
                ZIndex = 5
            }, Page)
            Corner(Holder, 8)

            local MainButton = Create("TextButton", {
                BackgroundTransparency = 1,
                Size = UDim2.new(1, 0, 0, 44),
                AutoButtonColor = false,
                Font = Enum.Font.GothamMedium,
                Text = (data.Name or "Dropdown") .. "   •   " .. tostring(selected),
                TextColor3 = Color3.new(1, 1, 1),
                TextSize = 12,
                ZIndex = 6
            }, Holder)

            local OptionHolder = Create("Frame", {
                BackgroundTransparency = 1,
                Position = UDim2.fromOffset(8, 48),
                Size = UDim2.new(1, -16, 0, 0),
                ZIndex = 6
            }, Holder)
            Create("UIListLayout", {Padding = UDim.new(0, 5)}, OptionHolder)

            local function Rebuild()
                for _, child in ipairs(OptionHolder:GetChildren()) do
                    if child:IsA("TextButton") then child:Destroy() end
                end
                for _, option in ipairs(options) do
                    local Option = Create("TextButton", {
                        BackgroundColor3 = Color3.fromRGB(45, 45, 50),
                        Size = UDim2.new(1, 0, 0, 30),
                        AutoButtonColor = false,
                        Font = Enum.Font.Gotham,
                        Text = tostring(option),
                        TextColor3 = Color3.fromRGB(220, 220, 220),
                        TextSize = 11,
                        ZIndex = 7
                    }, OptionHolder)
                    Corner(Option, 6)
                    Option.MouseButton1Click:Connect(function()
                        PlayClick(config.Sounds)
                        selected = option
                        MainButton.Text = (data.Name or "Dropdown") .. "   •   " .. tostring(selected)
                        opened = false
                        Tween(Holder, {Size = UDim2.new(1, 0, 0, 44)}, 0.2)
                        if data.Callback then task.spawn(data.Callback, selected) end
                    end)
                end
            end
            Rebuild()

            MainButton.MouseButton1Click:Connect(function()
                PlayClick(config.Sounds)
                opened = not opened
                local height = opened and (52 + (#options * 35)) or 44
                Tween(Holder, {Size = UDim2.new(1, 0, 0, height)}, 0.2)
            end)

            local Dropdown = {}
            function Dropdown:Set(value)
                selected = value
                MainButton.Text = (data.Name or "Dropdown") .. "   •   " .. tostring(selected)
                if data.Callback then task.spawn(data.Callback, selected) end
            end
            function Dropdown:Refresh(newOptions)
                options = newOptions or {}
                Rebuild()
            end
            if data.ConfigKey then
                Window:RegisterConfig(data.ConfigKey, function() return selected end, function(v) Dropdown:Set(v) end)
            end
            return Dropdown
        end


        ----------------------------------------------------------------
        -- MULTI DROPDOWN
        ----------------------------------------------------------------
        function Tab:CreateMultiDropdown(data)
            data=data or {}
            local options=data.Options or {}
            local selected={}
            local holder=Create("Frame",{BackgroundColor3=Color3.fromRGB(35,35,40),Size=UDim2.new(1,0,0,44),ClipsDescendants=true,ZIndex=5},Page)
            Corner(holder,8)
            local button=Create("TextButton",{BackgroundTransparency=1,Size=UDim2.new(1,0,0,44),AutoButtonColor=false,Font=Enum.Font.GothamMedium,Text="",TextColor3=Color3.new(1,1,1),TextSize=11,ZIndex=6},holder)
            local list=Create("Frame",{BackgroundTransparency=1,Position=UDim2.fromOffset(8,48),Size=UDim2.new(1,-16,0,0),ZIndex=6},holder)
            local layout=Create("UIListLayout",{Padding=UDim.new(0,5)},list)
            local function count() local n=0 for _ in pairs(selected) do n+=1 end return n end
            local function refreshText() local names={} for _,o in ipairs(options) do if selected[o] then table.insert(names,tostring(o)) end end button.Text=(data.Name or "Multi Dropdown").."   •   "..( #names>0 and table.concat(names,", ") or "None") end
            local function rebuild()
                for _,c in ipairs(list:GetChildren()) do if c:IsA("TextButton") then c:Destroy() end end
                for _,o in ipairs(options) do
                    local b=Create("TextButton",{BackgroundColor3=selected[o] and Color3.fromRGB(75,65,100) or Color3.fromRGB(45,45,50),Size=UDim2.new(1,0,0,30),AutoButtonColor=false,Font=Enum.Font.Gotham,Text=tostring(o),TextColor3=Color3.new(1,1,1),TextSize=11,ZIndex=7},list)
                    Corner(b,6)
                    b.MouseButton1Click:Connect(function()
                        selected[o]=not selected[o]
                        b.BackgroundColor3=selected[o] and Color3.fromRGB(75,65,100) or Color3.fromRGB(45,45,50)
                        refreshText()
                        if data.Callback then task.spawn(data.Callback,selected) end
                    end)
                end
                refreshText()
            end
            rebuild()
            button.MouseButton1Click:Connect(function()
                PlayClick(config.Sounds)
                local open=holder.Size.Y.Offset>44
                holder.Size=UDim2.new(1,0,0,open and 44 or math.min(44+(#options*35)+8,220))
            end)
            local Multi={}
            function Multi:Set(values)
                selected={}
                if type(values)=="table" then for _,v in ipairs(values) do selected[v]=true end end
                rebuild()
                if data.Callback then task.spawn(data.Callback,selected) end
            end
            function Multi:Get() local out={} for v in pairs(selected) do table.insert(out,v) end return out end
            function Multi:Refresh(newOptions) options=newOptions or {}; rebuild() end
            if data.ConfigKey then Window:RegisterConfig(data.ConfigKey,function() return Multi:Get() end,function(v) Multi:Set(v) end) end
            return Multi
        end

        ----------------------------------------------------------------
        -- KEYBIND
        ----------------------------------------------------------------
        function Tab:CreateKeybind(data)
            data=data or {}
            local key=data.Default or data.Key or Enum.KeyCode.RightShift
            local holder=Create("Frame",{BackgroundColor3=Color3.fromRGB(35,35,40),Size=UDim2.new(1,0,0,46),ZIndex=5},Page)
            Corner(holder,8)
            Create("TextLabel",{BackgroundTransparency=1,Position=UDim2.fromOffset(13,0),Size=UDim2.new(1,-100,1,0),Font=Enum.Font.GothamMedium,Text=data.Name or "Keybind",TextColor3=Color3.new(1,1,1),TextSize=12,TextXAlignment=Enum.TextXAlignment.Left,ZIndex=6},holder)
            local button=Create("TextButton",{BackgroundColor3=Color3.fromRGB(45,45,50),Position=UDim2.new(1,-82,.5,-13),Size=UDim2.fromOffset(68,26),AutoButtonColor=false,Font=Enum.Font.GothamMedium,Text=key.Name,TextColor3=Color3.new(1,1,1),TextSize=10,ZIndex=6},holder)
            Corner(button,7)
            local listening=false
            local bind={}
            local function setKey(k) if typeof(k)=="EnumItem" and k.EnumType==Enum.KeyCode then key=k; button.Text=k.Name end end
            button.MouseButton1Click:Connect(function() listening=true; button.Text="Press..." end)
            UserInputService.InputBegan:Connect(function(input,gp)
                if listening and input.UserInputType==Enum.UserInputType.Keyboard then listening=false; setKey(input.KeyCode); return end
                if not gp and input.UserInputType==Enum.UserInputType.Keyboard and input.KeyCode==key and data.Callback then task.spawn(data.Callback,key) end
            end)
            function bind:Set(k) setKey(k) end
            function bind:Get() return key.Name end
            if data.ConfigKey then Window:RegisterConfig(data.ConfigKey,function() return key.Name end,function(v) if Enum.KeyCode[v] then bind:Set(Enum.KeyCode[v]) end end) end
            return bind
        end

        ----------------------------------------------------------------
        -- COLOR PICKER
        ----------------------------------------------------------------
        function Tab:CreateColorPicker(data)
            data = data or {}
            local currentColor = data.Default or Color3.fromRGB(255, 255, 255)

            local Holder = Create("Frame", {
                BackgroundColor3 = Color3.fromRGB(35, 35, 40),
                Size = UDim2.new(1, 0, 0, 46),
                ZIndex = 5
            }, Page)
            Corner(Holder, 8)

            Create("TextLabel", {
                BackgroundTransparency = 1,
                Position = UDim2.fromOffset(13, 0),
                Size = UDim2.new(1, -75, 1, 0),
                Font = Enum.Font.GothamMedium,
                Text = data.Name or "Color",
                TextColor3 = Color3.new(1, 1, 1),
                TextSize = 12,
                TextXAlignment = Enum.TextXAlignment.Left,
                ZIndex = 6
            }, Holder)

            local Preview = Create("TextButton", {
                BackgroundColor3 = currentColor,
                Position = UDim2.new(1, -53, 0.5, -12),
                Size = UDim2.fromOffset(40, 24),
                AutoButtonColor = false,
                Text = "",
                ZIndex = 6
            }, Holder)
            Corner(Preview, 7)

            local Modal = Create("Frame", {
                BackgroundColor3 = Color3.fromRGB(27, 27, 31),
                AnchorPoint = Vector2.new(0.5, 0.5),
                Position = UDim2.fromScale(0.5, 0.5),
                Size = UDim2.fromOffset(0, 0),
                Visible = false,
                ZIndex = 80
            }, ScreenGui)
            Corner(Modal, 14)
            local ModalStroke = Stroke(Modal, config.BorderColor, config.BorderThickness)
            StartRGB(ModalStroke, config.RGB)

            Create("TextLabel", {
                BackgroundTransparency = 1,
                Position = UDim2.fromOffset(15, 12),
                Size = UDim2.new(1, -30, 0, 22),
                Font = Enum.Font.GothamBold,
                Text = data.Name or "Color Picker",
                TextColor3 = Color3.new(1, 1, 1),
                TextSize = 14,
                TextXAlignment = Enum.TextXAlignment.Left,
                ZIndex = 81
            }, Modal)

            local R = math.floor(currentColor.R * 255)
            local G = math.floor(currentColor.G * 255)
            local B = math.floor(currentColor.B * 255)

            local PreviewBox = Create("Frame", {
                BackgroundColor3 = currentColor,
                Position = UDim2.fromOffset(15, 148),
                Size = UDim2.new(1, -30, 0, 34),
                ZIndex = 81
            }, Modal)
            Corner(PreviewBox, 7)

            local function UpdatePreview()
                local color = Color3.fromRGB(R, G, B)
                PreviewBox.BackgroundColor3 = color
            end

            local function MakeRGBSlider(name, y, initial, callback)
                Create("TextLabel", {
                    BackgroundTransparency = 1,
                    Position = UDim2.fromOffset(15, y),
                    Size = UDim2.fromOffset(25, 20),
                    Font = Enum.Font.GothamBold,
                    Text = name,
                    TextColor3 = Color3.new(1, 1, 1),
                    TextSize = 11,
                    ZIndex = 82
                }, Modal)

                local valueLabel = Create("TextLabel", {
                    BackgroundTransparency = 1,
                    Position = UDim2.new(1, -42, 0, y),
                    Size = UDim2.fromOffset(27, 20),
                    Font = Enum.Font.GothamMedium,
                    Text = tostring(initial),
                    TextColor3 = Color3.fromRGB(180, 180, 185),
                    TextSize = 10,
                    TextXAlignment = Enum.TextXAlignment.Right,
                    ZIndex = 82
                }, Modal)

                local bar = Create("Frame", {
                    BackgroundColor3 = Color3.fromRGB(55, 55, 60),
                    Position = UDim2.fromOffset(45, y + 6),
                    Size = UDim2.new(1, -60, 0, 7),
                    ZIndex = 82
                }, Modal)
                Corner(bar, 5)

                local fill = Create("Frame", {
                    BackgroundColor3 =
                        name == "R" and Color3.fromRGB(220, 70, 70)
                        or name == "G" and Color3.fromRGB(70, 210, 100)
                        or Color3.fromRGB(75, 145, 255),
                    Size = UDim2.new(initial / 255, 0, 1, 0),
                    ZIndex = 83
                }, bar)
                Corner(fill, 5)

                local dragging = false
                local function update(input)
                    local percent = math.clamp(
                        (input.Position.X - bar.AbsolutePosition.X) / bar.AbsoluteSize.X,
                        0, 1
                    )
                    local value = math.floor(percent * 255 + 0.5)
                    Tween(fill, {Size = UDim2.new(percent, 0, 1, 0)}, 0.05)
                    valueLabel.Text = tostring(value)
                    callback(value)
                    UpdatePreview()
                end
                bar.InputBegan:Connect(function(input)
                    if input.UserInputType == Enum.UserInputType.MouseButton1
                        or input.UserInputType == Enum.UserInputType.Touch then
                        dragging = true
                        update(input)
                    end
                end)
                UserInputService.InputChanged:Connect(function(input)
                    if dragging and (
                        input.UserInputType == Enum.UserInputType.MouseMovement
                        or input.UserInputType == Enum.UserInputType.Touch
                    ) then update(input) end
                end)
                UserInputService.InputEnded:Connect(function(input)
                    if input.UserInputType == Enum.UserInputType.MouseButton1
                        or input.UserInputType == Enum.UserInputType.Touch then
                        dragging = false
                    end
                end)
            end

            MakeRGBSlider("R", 50, R, function(v) R = v end)
            MakeRGBSlider("G", 85, G, function(v) G = v end)
            MakeRGBSlider("B", 120, B, function(v) B = v end)

            local Cancel = Create("TextButton", {
                BackgroundColor3 = Color3.fromRGB(48, 48, 53),
                Position = UDim2.new(0, 15, 1, -47),
                Size = UDim2.fromOffset(120, 34),
                AutoButtonColor = false,
                Font = Enum.Font.GothamMedium,
                Text = "Cancelar",
                TextColor3 = Color3.new(1, 1, 1),
                TextSize = 11,
                ZIndex = 82
            }, Modal)
            Corner(Cancel, 7)

            local Accept = Create("TextButton", {
                BackgroundColor3 = Color3.fromRGB(65, 65, 72),
                Position = UDim2.new(1, -135, 1, -49),
                Size = UDim2.fromOffset(120, 34),
                AutoButtonColor = false,
                Font = Enum.Font.GothamMedium,
                Text = "Aceptar",
                TextColor3 = Color3.new(1, 1, 1),
                TextSize = 11,
                ZIndex = 82
            }, Modal)
            Corner(Accept, 7)

            local function CloseModal()
                Tween(Modal, {Size = UDim2.fromOffset(0, 0)}, 0.2)
                task.wait(0.2)
                Modal.Visible = false
            end

            Preview.MouseButton1Click:Connect(function()
                PlayClick(config.Sounds)
                Modal.Visible = true
                Modal.Size = UDim2.fromOffset(0, 0)
                Tween(Modal, {Size = UDim2.fromOffset(330, 235)}, 0.28, Enum.EasingStyle.Back)
            end)
            Cancel.MouseButton1Click:Connect(function()
                PlayClick(config.Sounds)
                CloseModal()
            end)
            Accept.MouseButton1Click:Connect(function()
                PlayClick(config.Sounds)
                currentColor = Color3.fromRGB(R, G, B)
                Preview.BackgroundColor3 = currentColor
                if data.Callback then task.spawn(data.Callback, currentColor) end
                CloseModal()
            end)

            local ColorPicker = {}
            function ColorPicker:Set(color)
                if typeof(color) ~= "Color3" then return end
                currentColor = color
                Preview.BackgroundColor3 = color
                R, G, B = math.floor(color.R * 255), math.floor(color.G * 255), math.floor(color.B * 255)
            end
            function ColorPicker:Get() return currentColor end
            if data.ConfigKey then
                Window:RegisterConfig(data.ConfigKey, function() return {R=currentColor.R,G=currentColor.G,B=currentColor.B} end, function(v)
                    if type(v)=="table" and v.R and v.G and v.B then ColorPicker:Set(Color3.new(v.R,v.G,v.B)) end
                end)
            end
            return ColorPicker
        end

        ----------------------------------------------------------------
        -- LABEL / SEPARATOR
        ----------------------------------------------------------------
        function Tab:CreateLabel(text)
            return Create("TextLabel", {
                BackgroundTransparency = 1,
                Size = UDim2.new(1, 0, 0, 28),
                Font = Enum.Font.GothamMedium,
                Text = tostring(text or ""),
                TextColor3 = Color3.fromRGB(180, 180, 185),
                TextSize = 11,
                TextWrapped = true,
                TextXAlignment = Enum.TextXAlignment.Left,
                ZIndex = 5
            }, Page)
        end

        ----------------------------------------------------------------
        -- PARAGRAPH
        ----------------------------------------------------------------
        function Tab:CreateParagraph(data)
            data = data or {}

            local Holder = Create("Frame", {
                BackgroundColor3 = Color3.fromRGB(35, 35, 40),
                Size = UDim2.new(1, 0, 0, 72),
                ZIndex = 5
            }, Page)
            Corner(Holder, 8)

            local Title = Create("TextLabel", {
                BackgroundTransparency = 1,
                Position = UDim2.fromOffset(13, 8),
                Size = UDim2.new(1, -26, 0, 20),
                Font = Enum.Font.GothamBold,
                Text = tostring(data.Title or "Paragraph"),
                TextColor3 = Color3.new(1, 1, 1),
                TextSize = 12,
                TextXAlignment = Enum.TextXAlignment.Left,
                ZIndex = 6
            }, Holder)

            local Content = Create("TextLabel", {
                BackgroundTransparency = 1,
                Position = UDim2.fromOffset(13, 29),
                Size = UDim2.new(1, -26, 0, 35),
                Font = Enum.Font.Gotham,
                Text = tostring(data.Content or ""),
                TextColor3 = Color3.fromRGB(175, 175, 180),
                TextSize = 11,
                TextWrapped = true,
                TextXAlignment = Enum.TextXAlignment.Left,
                TextYAlignment = Enum.TextYAlignment.Top,
                ZIndex = 6
            }, Holder)

            local Paragraph = {}

            function Paragraph:Set(title, content)
                Title.Text = tostring(title or "")
                Content.Text = tostring(content or "")
            end

            return Paragraph
        end

        ----------------------------------------------------------------
        -- TEXTBOX / INPUT
        ----------------------------------------------------------------
        function Tab:CreateInput(data)
            data = data or {}

            local Holder = Create("Frame", {
                BackgroundColor3 = Color3.fromRGB(35, 35, 40),
                Size = UDim2.new(1, 0, 0, 70),
                ZIndex = 5
            }, Page)
            Corner(Holder, 8)

            Create("TextLabel", {
                BackgroundTransparency = 1,
                Position = UDim2.fromOffset(13, 7),
                Size = UDim2.new(1, -26, 0, 18),
                Font = Enum.Font.GothamMedium,
                Text = tostring(data.Name or "Textbox"),
                TextColor3 = Color3.new(1, 1, 1),
                TextSize = 12,
                TextXAlignment = Enum.TextXAlignment.Left,
                ZIndex = 6
            }, Holder)

            local Box = Create("TextBox", {
                BackgroundColor3 = Color3.fromRGB(25, 25, 30),
                Position = UDim2.fromOffset(10, 30),
                Size = UDim2.new(1, -20, 0, 30),
                ClearTextOnFocus = data.ClearTextOnFocus == true,
                Font = Enum.Font.Gotham,
                PlaceholderText = tostring(data.PlaceholderText or ""),
                Text = tostring(data.CurrentValue or ""),
                TextColor3 = Color3.new(1, 1, 1),
                PlaceholderColor3 = Color3.fromRGB(125, 125, 130),
                TextSize = 11,
                TextXAlignment = Enum.TextXAlignment.Left,
                ZIndex = 6
            }, Holder)
            Corner(Box, 7)
            Stroke(Box, Color3.fromRGB(55, 55, 60), 1)

            Box.FocusLost:Connect(function()
                if data.Callback then
                    task.spawn(data.Callback, Box.Text)
                end
            end)

            local Input = {}

            function Input:Set(value)
                Box.Text = tostring(value or "")
                if data.Callback then
                    task.spawn(data.Callback, Box.Text)
                end
            end

            function Input:Get()
                return Box.Text
            end
            if data.ConfigKey then
                Window:RegisterConfig(data.ConfigKey, function() return Box.Text end, function(v) Input:Set(v) end)
            end

            return Input
        end

        function Tab:CreateSeparator()
            return Create("Frame", {
                BackgroundColor3 = Color3.fromRGB(55, 55, 60),
                BorderSizePixel = 0,
                Size = UDim2.new(1, 0, 0, 1),
                ZIndex = 5
            }, Page)
        end

        return Tab
    end

    ----------------------------------------------------------------
    -- WINDOW METHODS
    ----------------------------------------------------------------

    ----------------------------------------------------------------
    -- KEY SYSTEM
    ----------------------------------------------------------------
    function Window:CreateKeySystem(data)
        data=data or {}
        local expected=tostring(data.Key or "")
        local note=tostring(data.Note or "Enter the key to continue.")
        local gate=Create("Frame",{Name="KeySystem",AnchorPoint=Vector2.new(.5,.5),Position=UDim2.fromScale(.5,.5),Size=UDim2.fromOffset(330,220),BackgroundColor3=Color3.fromRGB(25,25,28),BorderSizePixel=0,ZIndex=200},ScreenGui)
        Corner(gate,16); Stroke(gate,config.BorderColor,config.BorderThickness); StartRGB(gate:FindFirstChildOfClass("UIStroke"),config.RGB)
        Create("TextLabel",{BackgroundTransparency=1,Position=UDim2.fromOffset(20,18),Size=UDim2.new(1,-40,0,25),Font=Enum.Font.GothamBold,Text=tostring(data.Title or "Key System"),TextColor3=Color3.new(1,1,1),TextSize=16,TextXAlignment=Enum.TextXAlignment.Left,ZIndex=201},gate)
        Create("TextLabel",{BackgroundTransparency=1,Position=UDim2.fromOffset(20,50),Size=UDim2.new(1,-40,0,45),Font=Enum.Font.Gotham,Text=note,TextColor3=Color3.fromRGB(165,165,170),TextSize=11,TextWrapped=true,TextXAlignment=Enum.TextXAlignment.Left,ZIndex=201},gate)
        local box=Create("TextBox",{BackgroundColor3=Color3.fromRGB(35,35,40),Position=UDim2.fromOffset(20,105),Size=UDim2.new(1,-40,0,38),ClearTextOnFocus=false,Font=Enum.Font.Gotham,PlaceholderText="Enter key...",Text="",TextColor3=Color3.new(1,1,1),TextSize=11,ZIndex=201},gate); Corner(box,8)
        local status=Create("TextLabel",{BackgroundTransparency=1,Position=UDim2.fromOffset(20,145),Size=UDim2.new(1,-40,0,18),Font=Enum.Font.Gotham,Text="",TextColor3=Color3.fromRGB(235,90,90),TextSize=10,TextXAlignment=Enum.TextXAlignment.Left,ZIndex=201},gate)
        local enter=Create("TextButton",{BackgroundColor3=Color3.fromRGB(75,75,82),Position=UDim2.new(1,-120,1,-48),Size=UDim2.fromOffset(100,34),AutoButtonColor=false,Font=Enum.Font.GothamMedium,Text="Continue",TextColor3=Color3.new(1,1,1),TextSize=11,ZIndex=201},gate); Corner(enter,8)
        local function verify()
            if box.Text==expected then gate:Destroy(); Main.Visible=true; Window.KeyUnlocked=true else status.Text="Invalid key." end
        end
        enter.MouseButton1Click:Connect(verify)
        box.FocusLost:Connect(function(enterPressed) if enterPressed then verify() end end)
        Main.Visible=false
        return gate
    end

    ----------------------------------------------------------------
    -- WATERMARK / FPS / PING
    ----------------------------------------------------------------
    function Window:CreateWatermark(data)
        data=data or {}
        local holder=Create("Frame",{Name="Watermark",AnchorPoint=Vector2.new(1,0),Position=UDim2.new(1,-12,0,12),Size=UDim2.fromOffset(220,30),BackgroundColor3=Color3.fromRGB(18,18,21),BackgroundTransparency=.08,ZIndex=150},ScreenGui)
        Corner(holder,9); Stroke(holder,config.BorderColor,1)
        local label=Create("TextLabel",{BackgroundTransparency=1,Size=UDim2.new(1,-16,1,0),Position=UDim2.fromOffset(8,0),Font=Enum.Font.GothamMedium,TextColor3=Color3.new(1,1,1),TextSize=10,TextXAlignment=Enum.TextXAlignment.Left,ZIndex=151},holder)
        local RunService=game:GetService("RunService")
        local showFPS=data.ShowFPS~=false; local showPing=data.ShowPing~=false; local last=os.clock(); local frames=0; local fps=0
        local conn=RunService.RenderStepped:Connect(function()
            frames+=1
            local now=os.clock()
            if now-last>=1 then fps=frames/(now-last); frames=0; last=now end
            local parts={}
            if data.Prefix then table.insert(parts,tostring(data.Prefix)) end
            if showFPS then table.insert(parts,"FPS: "..math.floor(fps)) end
            if showPing then
                local ping=0
                pcall(function() ping=math.floor(game:GetService("Stats").Network.ServerStatsItem["Data Ping"] and game:GetService("Stats").Network.ServerStatsItem["Data Ping"]:GetValue() or 0) end)
                table.insert(parts,"Ping: "..ping.."ms")
            end
            label.Text=table.concat(parts,"  •  ")
        end)
        function holder.DestroyWatermark() conn:Disconnect(); holder:Destroy() end
        return holder
    end

    function Window:SetKeybind(keyCode, callback)
        self._GlobalKeybind=keyCode
        UserInputService.InputBegan:Connect(function(input,gp) if not gp and input.UserInputType==Enum.UserInputType.Keyboard and input.KeyCode==keyCode and callback then task.spawn(callback) end end)
    end

    function Window:Notify(data)
        ArceusUI:Notify(data)
    end

    function Window:Destroy()
        if ScreenGui then ScreenGui:Destroy() end
    end

    function Window:SetTitle(text)
        Title.Text = tostring(text)
    end

    function Window:SetSubtitle(text)
        Subtitle.Text = tostring(text)
    end

    if config.KeySystem and type(config.KeySystem)=="table" and config.KeySystem.Enabled then Window:CreateKeySystem(config.KeySystem) end
    if config.Watermark and type(config.Watermark)=="table" and config.Watermark.Enabled then Window:CreateWatermark(config.Watermark) end
    if config.Theme and THEMES[config.Theme] then Window:SetTheme(config.Theme) end

    Library.Windows[#Library.Windows + 1] = Window
    return Window
end

return ArceusUI
