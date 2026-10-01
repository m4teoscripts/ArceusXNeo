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
    - Bottom-left profile card with avatar + DisplayName + @Username
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
    RGB = true,
    Sounds = true,
    AnimationSpeed = 0.22,
    ShowProfile = true,
    ProfileName = nil,
    ProfileUsername = nil,
    ProfileImage = nil,
    ConfigFolder = "ArceusX",
    KeySystem = false,
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

local function StartRGB(stroke, enabled)
    if not enabled or not stroke then return end
    task.spawn(function()
        local hue = 0
        while stroke and stroke.Parent do
            hue += 0.004
            if hue > 1 then hue = 0 end
            stroke.Color = Color3.fromHSV(hue, 0.9, 1)
            task.wait()
        end
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

    local borderSize = UDim2.new(
        config.Size.X.Scale, config.Size.X.Offset + 4,
        config.Size.Y.Scale, config.Size.Y.Offset + 4
    )

    -- Dedicated border container. Main no longer owns the RGB stroke,
    -- so ClipsDescendants cannot cut the rounded exterior border.
    local BorderFrame = Create("Frame", {
        Name = "ExteriorBorder",
        AnchorPoint = Vector2.new(0.5, 0.5),
        Position = config.Position,
        Size = UDim2.fromOffset(0, 0),
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        ClipsDescendants = false,
        ZIndex = 1
    }, ScreenGui)
    Corner(BorderFrame, 14)
    local BorderStroke = Stroke(BorderFrame, Color3.fromRGB(100, 100, 100), 2)
    StartRGB(BorderStroke, config.RGB)

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
    Corner(Main, 12)

    ----------------------------------------------------------------
    -- TOP BAR
    ----------------------------------------------------------------
    local TopBar = Create("Frame", {
        Name = "TopBar",
        BackgroundColor3 = Color3.fromRGB(31, 31, 35),
        BorderSizePixel = 0,
        Size = UDim2.new(1, 0, 0, 62),
        ZIndex = 3
    }, Main)

    local Title = Create("TextLabel", {
        BackgroundTransparency = 1,
        Position = UDim2.fromOffset(18, 10),
        Size = UDim2.new(1, -130, 0, 22),
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
        Size = UDim2.new(1, -130, 0, 18),
        Font = Enum.Font.Gotham,
        Text = config.Subtitle,
        TextColor3 = Color3.fromRGB(150, 150, 155),
        TextSize = 11,
        TextXAlignment = Enum.TextXAlignment.Left,
        ZIndex = 4
    }, TopBar)

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
    -- SEARCH
    ----------------------------------------------------------------
    local SearchBox = Create("TextBox", {
        Name = "SearchBox",
        BackgroundColor3 = Color3.fromRGB(40, 40, 45),
        Position = UDim2.new(1, -106, 0, 12),
        Size = UDim2.fromOffset(28, 28),
        ClearTextOnFocus = false,
        PlaceholderText = "⌕",
        PlaceholderColor3 = Color3.fromRGB(125, 125, 130),
        Text = "",
        TextColor3 = Color3.fromRGB(235, 235, 238),
        Font = Enum.Font.Gotham,
        TextSize = 10,
        TextXAlignment = Enum.TextXAlignment.Center,
        ZIndex = 5
    }, TopBar)
    Corner(SearchBox, 8)
    Stroke(SearchBox, Color3.fromRGB(65, 65, 72), 1)
    local SearchIcon = Create("ImageButton", {
        BackgroundTransparency = 1, Position = UDim2.new(1, -99, 0, 18),
        Size = UDim2.fromOffset(16, 16), AutoButtonColor = false,
        Image = "rbxassetid://6031154871", ImageColor3 = Color3.fromRGB(160,160,165), ZIndex = 6
    }, TopBar)
    SearchIcon.MouseButton1Click:Connect(function() SearchBox:CaptureFocus() end)
    local searchExpanded = false
    SearchBox.Focused:Connect(function()
        searchExpanded = true
        SearchIcon.Visible = false
        Tween(SearchBox, {Position = UDim2.new(1, -154, 0, 12), Size = UDim2.fromOffset(72, 28)}, 0.18)
        SearchBox.TextXAlignment = Enum.TextXAlignment.Left
        SearchBox.PlaceholderText = "Search"
    end)
    SearchBox.FocusLost:Connect(function()
        if SearchBox.Text == "" then
            searchExpanded = false
            SearchBox.TextXAlignment = Enum.TextXAlignment.Center
            SearchBox.PlaceholderText = ""
            SearchIcon.Visible = true
            Tween(SearchBox, {Position = UDim2.new(1, -106, 0, 12), Size = UDim2.fromOffset(28, 28)}, 0.18)
        end
    end)

    ----------------------------------------------------------------
    -- TAB BAR
    ----------------------------------------------------------------
    local TabBar = Create("ScrollingFrame", {
        Name = "TabBar",
        BackgroundColor3 = Color3.fromRGB(28, 28, 32),
        BorderSizePixel = 0,
        Position = UDim2.fromOffset(0, 62),
        Size = UDim2.new(1, 0, 0, 40),
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
    -- PROFILE - HEADER
    ----------------------------------------------------------------
    local ProfileCard, ProfileAvatar, ProfileDisplay, ProfileUsername
    if config.ShowProfile ~= false then
        ProfileCard=Create("Frame",{Name="ProfileCard",BackgroundTransparency=1,Position=UDim2.new(1,-292,0,8),Size=UDim2.fromOffset(88,38),ZIndex=5},TopBar)
        ProfileAvatar=Create("ImageLabel",{BackgroundColor3=Color3.fromRGB(25,25,28),Position=UDim2.fromOffset(0,1),Size=UDim2.fromOffset(36,36),Image=GetAvatar(config.ProfileImage),ScaleType=Enum.ScaleType.Crop,ZIndex=6},ProfileCard); Corner(ProfileAvatar,18); Stroke(ProfileAvatar,Color3.fromRGB(70,70,78),1)
        ProfileDisplay=Create("TextLabel",{BackgroundTransparency=1,Position=UDim2.fromOffset(43,2),Size=UDim2.fromOffset(45,15),Font=Enum.Font.GothamBold,Text=config.ProfileName or LocalPlayer.DisplayName,TextColor3=Color3.new(1,1,1),TextSize=9,TextTruncate=Enum.TextTruncate.AtEnd,TextXAlignment=Enum.TextXAlignment.Left,ZIndex=6},ProfileCard)
        ProfileUsername=Create("TextLabel",{BackgroundTransparency=1,Position=UDim2.fromOffset(43,18),Size=UDim2.fromOffset(45,13),Font=Enum.Font.Gotham,Text=config.ProfileUsername or ("@"..LocalPlayer.Name),TextColor3=Color3.fromRGB(145,145,150),TextSize=8,TextTruncate=Enum.TextTruncate.AtEnd,TextXAlignment=Enum.TextXAlignment.Left,ZIndex=6},ProfileCard)
    end
    ----------------------------------------------------------------
    -- WATERMARK - HEADER
    ----------------------------------------------------------------
    local WatermarkLabel
    if config.Watermark then
        local wm=type(config.Watermark)=="table" and config.Watermark or {}
        WatermarkLabel=Create("TextLabel",{Name="Watermark",BackgroundTransparency=1,Position=UDim2.new(1,-205,0,16),Size=UDim2.fromOffset(55,18),Font=Enum.Font.GothamMedium,Text=tostring(wm.Text or wm.Prefix or "Arceus X"),TextColor3=Color3.fromRGB(150,150,155),TextSize=9,TextTruncate=Enum.TextTruncate.AtEnd,TextXAlignment=Enum.TextXAlignment.Right,ZIndex=5},TopBar)
    end

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
    local MiniStroke = Stroke(MiniButton, Color3.fromRGB(100, 100, 100), 1.5)
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
            BorderFrame.Position = newPosition
        end
    end)

    ----------------------------------------------------------------
    -- OPEN ANIMATION
    ----------------------------------------------------------------
    Main.Size = UDim2.fromOffset(20, 20)
    BorderFrame.Size = UDim2.fromOffset(24, 24)
    Tween(Main, {Size = config.Size}, 0.38, Enum.EasingStyle.Back)
    Tween(BorderFrame, {Size = borderSize}, 0.38, Enum.EasingStyle.Back)


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
        Tween(BorderFrame, {Size = UDim2.fromOffset(4, 4)}, 0.25)
        task.wait(0.25)

        Main.Visible = false
        BorderFrame.Visible = false
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
        BorderFrame.Visible = true
        Main.Size = UDim2.fromOffset(0, 0)
        BorderFrame.Size = UDim2.fromOffset(4, 4)
        Tween(Main, {Size = config.Size}, 0.32, Enum.EasingStyle.Back)
        Tween(BorderFrame, {Size = borderSize}, 0.32, Enum.EasingStyle.Back)
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
        Tween(BorderFrame, {Size = UDim2.fromOffset(4, 4)}, 0.25)
        task.wait(0.25)
        if ScreenGui then ScreenGui:Destroy() end
    end)

    local Window = {}
    Window.Main = Main
    Window.ScreenGui = ScreenGui
    Window.Border = BorderFrame
    Window.Tabs = {}
    Window.ActiveTab = nil
    Window.Profile = ProfileCard
    Window.ConfigRegistry = {}
    Window.ConfigFolder = config.ConfigFolder or "ArceusX"

    ----------------------------------------------------------------
    -- CONFIG / SEARCH
    ----------------------------------------------------------------
    function Window:RegisterConfig(key, getter, setter)
        if not key or type(getter) ~= "function" then return end
        self.ConfigRegistry[tostring(key)] = {Get = getter, Set = setter}
    end

    function Window:GetConfig()
        local data = {}
        for key, entry in pairs(self.ConfigRegistry) do
            local ok, value = pcall(entry.Get)
            if ok then
                if typeof(value) == "Color3" then
                    data[key] = {__type="Color3", R=value.R, G=value.G, B=value.B}
                elseif type(value) == "table" then
                    local copy = {}
                    for k,v in pairs(value) do copy[k]=v end
                    data[key] = copy
                else
                    data[key] = value
                end
            end
        end
        return data
    end

    function Window:ApplyConfig(data)
        if type(data) ~= "table" then return false end
        for key,value in pairs(data) do
            local entry=self.ConfigRegistry[tostring(key)]
            if entry and type(entry.Set)=="function" then
                if type(value)=="table" and value.__type=="Color3" then
                    value=Color3.new(value.R or 1,value.G or 1,value.B or 1)
                end
                pcall(entry.Set,value)
            end
        end
        return true
    end

    function Window:SaveConfig(name)
        name=tostring(name or "default"):gsub("[^%w_%-]","_")
        local folder=self.ConfigFolder
        local path=folder.."/"..name..".json"
        if type(writefile)~="function" then return false,"writefile is not available" end
        pcall(function()
            if type(isfolder)=="function" and type(makefolder)=="function" and not isfolder(folder) then makefolder(folder) end
        end)
        local ok,encoded=pcall(function() return game:GetService("HttpService"):JSONEncode(self:GetConfig()) end)
        if not ok then return false,"could not encode config" end
        local wrote=pcall(writefile,path,encoded)
        return wrote,wrote and path or "could not write config"
    end

    function Window:LoadConfig(name)
        name=tostring(name or "default"):gsub("[^%w_%-]","_")
        local path=self.ConfigFolder.."/"..name..".json"
        if type(isfile)~="function" or type(readfile)~="function" or not isfile(path) then return false,"config not found" end
        local ok,data=pcall(function() return game:GetService("HttpService"):JSONDecode(readfile(path)) end)
        if not ok then return false,"invalid config" end
        self:ApplyConfig(data)
        return true,path
    end

    local function SearchCurrentPage(query)
        query=string.lower(tostring(query or "")):gsub("^%s+",""):gsub("%s+$","")
        local page=Window.ActiveTab and Window.ActiveTab.Page
        if not page then return end
        for _,child in ipairs(page:GetChildren()) do
            if child:IsA("GuiObject") and not child:IsA("UIListLayout") then
                if query=="" then
                    child.Visible=true
                else
                    local found=false
                    for _,desc in ipairs(child:GetDescendants()) do
                        if desc:IsA("TextLabel") or desc:IsA("TextButton") or desc:IsA("TextBox") then
                            local t=string.lower(desc.Text or "")
                            if t:find(query,1,true) then found=true break end
                        end
                    end
                    child.Visible=found
                end
            end
        end
    end
    SearchBox:GetPropertyChangedSignal("Text"):Connect(function() SearchCurrentPage(SearchBox.Text) end)

    ----------------------------------------------------------------
    -- PROFILE METHODS
    ----------------------------------------------------------------
    function Window:SetProfile(displayName, username, image)
        if not ProfileCard then return end
        if displayName ~= nil then ProfileDisplay.Text = tostring(displayName) end
        if username ~= nil then ProfileUsername.Text = tostring(username) end
        if image ~= nil then ProfileAvatar.Image = tostring(image) end
    end

    ----------------------------------------------------------------
    -- CREATE TAB
    ----------------------------------------------------------------
    function Window:CreateTab(tabName)
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
            SearchBox.Text = ""
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
            function Toggle:Get() return value end
            if data.ConfigKey then
                Window:RegisterConfig(data.ConfigKey,function() return value end,function(v) Toggle:Set(v) end)
            end
            return Toggle
        end

        ----------------------------------------------------------------
        -- SLIDER
        ----------------------------------------------------------------
        function Tab:CreateSlider(data)
            data = data or {}
            local min = data.Min or 0
            local max = data.Max or 100
            if max <= min then max = min + 1 end
            local current = math.clamp(data.Default or min, min, max)

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
                current = math.clamp(value, min, max)
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
            function Slider:Get() return current end
            if data.ConfigKey then
                Window:RegisterConfig(data.ConfigKey,function() return current end,function(v) Slider:Set(v) end)
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
            function Dropdown:Get() return selected end
            if data.ConfigKey then
                Window:RegisterConfig(data.ConfigKey,function() return selected end,function(v) Dropdown:Set(v) end)
            end
            return Dropdown
        end

        ----------------------------------------------------------------
        -- MULTI DROPDOWN
        ----------------------------------------------------------------
        function Tab:CreateMultiDropdown(data)
            data=data or {}; local options=data.Options or {}; local selected={}; local opened=false
            if type(data.Default)=="table" then for k,v in pairs(data.Default) do if type(k)=="number" then selected[tostring(v)]=true elseif v==true then selected[tostring(k)]=true end end end
            local Holder=Create("Frame",{BackgroundColor3=Color3.fromRGB(35,35,40),Size=UDim2.new(1,0,0,44),ClipsDescendants=true,ZIndex=5},Page); Corner(Holder,8)
            local MainButton=Create("TextButton",{BackgroundTransparency=1,Size=UDim2.new(1,0,0,44),AutoButtonColor=false,Font=Enum.Font.GothamMedium,TextColor3=Color3.new(1,1,1),TextSize=12,ZIndex=6},Holder)
            local OptionHolder=Create("Frame",{BackgroundTransparency=1,Position=UDim2.fromOffset(8,48),Size=UDim2.new(1,-16,0,0),ZIndex=6},Holder); Create("UIListLayout",{Padding=UDim.new(0,5)},OptionHolder)
            local function summary() local picked={}; for _,o in ipairs(options) do if selected[tostring(o)] then table.insert(picked,tostring(o)) end end; MainButton.Text=(data.Name or "Multi Dropdown").."   •   "..(#picked>0 and table.concat(picked,", ") or "None") end
            local function rebuild()
                for _,c in ipairs(OptionHolder:GetChildren()) do if c:IsA("TextButton") then c:Destroy() end end
                for _,option in ipairs(options) do local key=tostring(option); local b=Create("TextButton",{BackgroundColor3=selected[key] and Color3.fromRGB(65,65,72) or Color3.fromRGB(45,45,50),Size=UDim2.new(1,0,0,30),AutoButtonColor=false,Font=Enum.Font.Gotham,Text=(selected[key] and "✓  " or "□  ")..key,TextColor3=Color3.fromRGB(225,225,228),TextSize=11,ZIndex=7},OptionHolder); Corner(b,6); b.MouseButton1Click:Connect(function() selected[key]=not selected[key]; rebuild(); if data.Callback then task.spawn(data.Callback,selected) end end) end; summary()
            end
            rebuild(); MainButton.MouseButton1Click:Connect(function() opened=not opened; Tween(Holder,{Size=UDim2.new(1,0,0,opened and (52+#options*35) or 44)},0.2) end)
            local Multi={}
            function Multi:Set(values) selected={}; if type(values)=="table" then for k,v in pairs(values) do if type(k)=="number" then selected[tostring(v)]=true elseif v==true then selected[tostring(k)]=true end end end; rebuild(); if data.Callback then task.spawn(data.Callback,selected) end end
            function Multi:Get() return selected end
            function Multi:Refresh(newOptions) options=newOptions or {}; rebuild() end
            if data.ConfigKey then Window:RegisterConfig(data.ConfigKey,function() return selected end,function(v) Multi:Set(v) end) end
            return Multi
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
            Corner(Modal, 10)
            local ModalStroke = Stroke(Modal, Color3.fromRGB(100, 100, 100), 1.5)
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
                Position = UDim2.fromOffset(15, 160),
                Size = UDim2.new(1, -30, 0, 30),
                ZIndex = 81
            }, Modal)
            Corner(PreviewBox, 7)

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

                local bar = Create("Frame", {
                    BackgroundColor3 = Color3.fromRGB(55, 55, 60),
                    Position = UDim2.fromOffset(45, y + 6),
                    Size = UDim2.new(1, -60, 0, 7),
                    ZIndex = 82
                }, Modal)
                Corner(bar, 5)

                local fill = Create("Frame", {
                    BackgroundColor3 = Color3.fromRGB(120, 120, 125),
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
                    local value = math.floor(percent * 255)
                    Tween(fill, {Size = UDim2.new(percent, 0, 1, 0)}, 0.05)
                    callback(value)
                    PreviewBox.BackgroundColor3 = Color3.fromRGB(R, G, B)
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
                Size = UDim2.fromOffset(105, 32),
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
                Position = UDim2.new(1, -120, 1, -47),
                Size = UDim2.fromOffset(105, 32),
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
                Tween(Modal, {Size = UDim2.fromOffset(310, 225)}, 0.28, Enum.EasingStyle.Back)
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
                Window:RegisterConfig(data.ConfigKey,function() return currentColor end,function(v) ColorPicker:Set(v) end)
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

    ----------------------------------------------------------------
    -- KEY SYSTEM
    -- The full Window/Tab tree is created first; this is only an overlay.
    ----------------------------------------------------------------
    function Window:CreateWatermark(data)
        data=data or {}
        local text=tostring(data.Text or data.Prefix or "Arceus X")
        if WatermarkLabel and WatermarkLabel.Parent then
            WatermarkLabel.Text=text
            WatermarkLabel.Visible=data.Enabled ~= false
            return WatermarkLabel
        end
        WatermarkLabel=Create("TextLabel",{Name="Watermark",BackgroundTransparency=1,Position=UDim2.new(1,-205,0,16),Size=UDim2.fromOffset(55,18),Font=Enum.Font.GothamMedium,Text=text,TextColor3=Color3.fromRGB(150,150,155),TextSize=9,TextTruncate=Enum.TextTruncate.AtEnd,TextXAlignment=Enum.TextXAlignment.Right,ZIndex=5},TopBar)
        return WatermarkLabel
    end

    function Window:CreateKeySystem(data)
        data=data or {}
        local expected=tostring(data.Key or data.KeyValue or "")
        local gate=Create("Frame",{
            Name="KeySystem",AnchorPoint=Vector2.new(.5,.5),Position=UDim2.fromScale(.5,.5),
            Size=UDim2.fromOffset(0,0),BackgroundColor3=Color3.fromRGB(25,25,28),
            BorderSizePixel=0,ZIndex=200,Visible=false
        },ScreenGui)
        Corner(gate,12)
        local gs=Stroke(gate,Color3.fromRGB(100,100,100),2); StartRGB(gs,config.RGB)
        Create("TextLabel",{BackgroundTransparency=1,Position=UDim2.fromOffset(18,16),Size=UDim2.new(1,-36,0,24),Font=Enum.Font.GothamBold,Text=tostring(data.Title or "Arceus X Key System"),TextColor3=Color3.new(1,1,1),TextSize=16,TextXAlignment=Enum.TextXAlignment.Left,ZIndex=201},gate)
        Create("TextLabel",{BackgroundTransparency=1,Position=UDim2.fromOffset(18,45),Size=UDim2.new(1,-36,0,42),Font=Enum.Font.Gotham,Text=tostring(data.Note or "Enter the key to continue."),TextColor3=Color3.fromRGB(155,155,160),TextSize=11,TextWrapped=true,TextXAlignment=Enum.TextXAlignment.Left,ZIndex=201},gate)
        local input=Create("TextBox",{BackgroundColor3=Color3.fromRGB(40,40,45),Position=UDim2.fromOffset(18,96),Size=UDim2.new(1,-36,0,38),ClearTextOnFocus=false,PlaceholderText="Enter key...",PlaceholderColor3=Color3.fromRGB(120,120,125),Text="",TextColor3=Color3.new(1,1,1),Font=Enum.Font.Gotham,TextSize=12,ZIndex=201},gate); Corner(input,8)
        local status=Create("TextLabel",{BackgroundTransparency=1,Position=UDim2.fromOffset(18,138),Size=UDim2.new(1,-36,0,20),Font=Enum.Font.Gotham,Text="",TextColor3=Color3.fromRGB(220,90,90),TextSize=10,TextXAlignment=Enum.TextXAlignment.Left,ZIndex=201},gate)
        local unlock=Create("TextButton",{BackgroundColor3=Color3.fromRGB(65,65,72),Position=UDim2.new(1,-123,1,-48),Size=UDim2.fromOffset(105,32),AutoButtonColor=false,Font=Enum.Font.GothamMedium,Text="Unlock",TextColor3=Color3.new(1,1,1),TextSize=11,ZIndex=201},gate); Corner(unlock,7)
        local verified=false
        local function verify()
            if verified then return end
            if expected=="" or input.Text==expected then
                verified=true; gate.Visible=false; BorderFrame.Visible=true; Main.Visible=true; status.Text=""; PlayClick(config.Sounds)
            else status.Text="Invalid key" end
        end
        unlock.MouseButton1Click:Connect(verify)
        input.FocusLost:Connect(function(enter) if enter then verify() end end)
        local function show()
            if verified or closed then return end
            Main.Visible=false; BorderFrame.Visible=false; gate.Visible=true; gate.Size=UDim2.fromOffset(0,0)
            Tween(gate,{Size=UDim2.fromOffset(350,205)},.3,Enum.EasingStyle.Back)
        end
        Window.KeySystem={Frame=gate,Input=input,Show=show,Verify=verify}
        show()
        return Window.KeySystem
    end

    if config.KeySystem and type(config.KeySystem)=="table" and config.KeySystem.Enabled then
        Window:CreateKeySystem(config.KeySystem)
    end

    Library.Windows[#Library.Windows + 1] = Window
    return Window
end

return ArceusUI
