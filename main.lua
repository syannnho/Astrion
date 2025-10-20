-- VIP Loader System - FINAL FIX (MAPS NOW VISIBLE)
-- Connected to: https://astrion-keycrate.vercel.app/api/validate

local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local HttpService = game:GetService("HttpService")
local UserInputService = game:GetService("UserInputService")

local LocalPlayer = Players.LocalPlayer
local userId = LocalPlayer.UserId

-- GitHub URL for VIP IDs only
local GITHUB_VIP_URL = "https://raw.githubusercontent.com/yourusername/vip/main/vip.txt"

-- Map Scripts
local MAP_SCRIPTS = {
    Arunika = "https://raw.githubusercontent.com/yourusername/maps/main/arunika.lua",
    Yahayuk = "https://raw.githubusercontent.com/yrejinhoo/Loader/refs/heads/main/Loader.lua"
}

-- Key validation endpoint
local KEY_VALIDATE_URL = "https://astrion-keycrate.vercel.app/api/validate"

-- Session storage (in-memory)
local ValidatedKeys = {}

-- Device detection
local function isMobile()
    return UserInputService.TouchEnabled and not UserInputService.KeyboardEnabled
end

-- Fetch VIP IDs from GitHub
local function fetchVIPIds()
    local success, response = pcall(function()
        return game:HttpGet(GITHUB_VIP_URL)
    end)
    if success then
        local vipIds = {}
        for line in response:gmatch("[^\r\n]+") do
            local id = line:match("^%s*(.-)%s*$")
            if id ~= "" and tonumber(id) then
                table.insert(vipIds, tonumber(id))
            end
        end
        return vipIds
    end
    return {}
end

-- Check if user is VIP
local function isUserVIP(userId, vipIds)
    for _, vipId in ipairs(vipIds) do
        if userId == vipId then
            return true
        end
    end
    return false
end

-- Validate key via web API
local function validateKey(key)
    if not key or type(key) ~= "string" then
        return false, "Invalid key"
    end

    local url = KEY_VALIDATE_URL .. "?key=" .. HttpService:UrlEncode(key)
    local success, response = pcall(function()
        return game:HttpGetAsync(url)
    end)

    if not success then
        return false, "Network error"
    end

    local decoded = HttpService:JSONDecode(response)
    if decoded and decoded.success then
        return true, ""
    else
        return false, decoded and decoded.error or "Unknown error"
    end
end

-- Create UI
local function createLoader(isVIP, playerName)
    local ScreenGui = Instance.new("ScreenGui")
    ScreenGui.Name = "VIPLoader"
    ScreenGui.ResetOnSpawn = false
    ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    ScreenGui.IgnoreGuiInset = true

    if syn then
        syn.protect_gui(ScreenGui)
        ScreenGui.Parent = game.CoreGui
    else
        ScreenGui.Parent = LocalPlayer:WaitForChild("PlayerGui")
    end

    -- Overlay
    local Overlay = Instance.new("Frame")
    Overlay.Size = UDim2.new(1, 0, 1, 0)
    Overlay.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
    Overlay.BackgroundTransparency = 0.3
    Overlay.BorderSizePixel = 0
    Overlay.ZIndex = 1
    Overlay.Parent = ScreenGui

    -- Blur
    local BlurEffect = Instance.new("BlurEffect")
    BlurEffect.Size = 10
    BlurEffect.Parent = game.Lighting

    -- Frame size
    local frameWidth = isMobile() and 350 or 600
    local frameHeight = isMobile() and math.floor(frameWidth / 16 * 9) or math.floor(600 / 16 * 9)

    -- Main Frame
    local MainFrame = Instance.new("Frame")
    MainFrame.Size = UDim2.new(0, frameWidth, 0, frameHeight)
    MainFrame.Position = UDim2.new(0.5, 0, 0.5, 0)
    MainFrame.AnchorPoint = Vector2.new(0.5, 0.5)
    MainFrame.BackgroundColor3 = Color3.fromRGB(15, 20, 45)
    MainFrame.BorderSizePixel = 0
    MainFrame.ZIndex = 2
    MainFrame.Parent = ScreenGui

    Instance.new("UICorner", MainFrame).CornerRadius = UDim.new(0, 15)
    Instance.new("UIStroke", MainFrame).Color = Color3.fromRGB(255, 215, 0)

    -- Left Panel
    local LeftPanel = Instance.new("Frame")
    LeftPanel.Size = UDim2.new(0.35, 0, 1, 0)
    LeftPanel.BackgroundColor3 = Color3.fromRGB(10, 15, 35)
    LeftPanel.BorderSizePixel = 0
    LeftPanel.Parent = MainFrame
    Instance.new("UICorner", LeftPanel).CornerRadius = UDim.new(0, 15)

    -- Avatar
    local AvatarFrame = Instance.new("Frame")
    AvatarFrame.Size = UDim2.new(0, isMobile() and 80 or 120, 0, isMobile() and 80 or 120)
    AvatarFrame.Position = UDim2.new(0.5, 0, 0, isMobile() and 25 or 40)
    AvatarFrame.AnchorPoint = Vector2.new(0.5, 0)
    AvatarFrame.BackgroundColor3 = Color3.fromRGB(93, 173, 226)
    AvatarFrame.BorderSizePixel = 0
    AvatarFrame.Parent = LeftPanel
    Instance.new("UICorner", AvatarFrame).CornerRadius = UDim.new(0.25, 0)
    Instance.new("UIStroke", AvatarFrame).Color = Color3.fromRGB(255, 215, 0)

    local Avatar = Instance.new("ImageLabel")
    Avatar.BackgroundTransparency = 1
    Avatar.Size = UDim2.new(1, -6, 1, -6)
    Avatar.Position = UDim2.new(0, 3, 0, 3)
    Avatar.Image = "https://www.roblox.com/headshot-thumbnail/image?userId=" .. userId .. "&width=420&height=420&format=png"
    Avatar.Parent = AvatarFrame
    Instance.new("UICorner", Avatar).CornerRadius = UDim.new(0.25, 0)

    -- Username
    local Username = Instance.new("TextLabel")
    Username.Size = UDim2.new(1, -20, 0, isMobile() and 25 or 30)
    Username.Position = UDim2.new(0.5, 0, 0, isMobile() and 115 or 175)
    Username.AnchorPoint = Vector2.new(0.5, 0)
    Username.BackgroundTransparency = 1
    Username.Text = "@" .. playerName
    Username.TextColor3 = Color3.fromRGB(255, 255, 255)
    Username.TextSize = isMobile() and 12 or 16
    Username.Font = Enum.Font.GothamBold
    Username.Parent = LeftPanel

    local DisplayName = Instance.new("TextLabel")
    DisplayName.Size = UDim2.new(1, -20, 0, isMobile() and 20 or 25)
    DisplayName.Position = UDim2.new(0.5, 0, 0, isMobile() and 140 or 205)
    DisplayName.AnchorPoint = Vector2.new(0.5, 0)
    DisplayName.BackgroundTransparency = 1
    DisplayName.Text = LocalPlayer.DisplayName
    DisplayName.TextColor3 = Color3.fromRGB(160, 174, 192)
    DisplayName.TextSize = isMobile() and 10 or 14
    DisplayName.Font = Enum.Font.Gotham
    DisplayName.Parent = LeftPanel

    -- Right Panel
    local RightPanel = Instance.new("Frame")
    RightPanel.Size = UDim2.new(0.65, 0, 1, 0)
    RightPanel.Position = UDim2.new(0.35, 0, 0, 0)
    RightPanel.BackgroundTransparency = 1
    RightPanel.Parent = MainFrame

    -- Welcome Text
    local WelcomeText = Instance.new("TextLabel")
    WelcomeText.Size = UDim2.new(1, -40, 0, isMobile() and 30 or 40)
    WelcomeText.Position = UDim2.new(0.5, 0, 0, isMobile() and 15 or 25)
    WelcomeText.AnchorPoint = Vector2.new(0.5, 0)
    WelcomeText.BackgroundTransparency = 1
    WelcomeText.Text = isVIP and "WELCOME VIP" or "WELCOME FREE"
    WelcomeText.TextColor3 = Color3.fromRGB(255, 215, 0)
    WelcomeText.TextSize = isMobile() and 20 or 28
    WelcomeText.Font = Enum.Font.GothamBold
    WelcomeText.Parent = RightPanel
    Instance.new("UIStroke", WelcomeText).Color = Color3.fromRGB(255, 215, 0)

    -- Subtitle
    local Subtitle = Instance.new("TextLabel")
    Subtitle.Size = UDim2.new(1, -40, 0, isMobile() and 15 or 20)
    Subtitle.Position = UDim2.new(0.5, 0, 0, isMobile() and 45 or 65)
    Subtitle.AnchorPoint = Vector2.new(0.5, 0)
    Subtitle.BackgroundTransparency = 1
    Subtitle.Text = "Premium Access System"
    Subtitle.TextColor3 = Color3.fromRGB(160, 174, 192)
    Subtitle.TextSize = isMobile() and 9 or 12
    Subtitle.Font = Enum.Font.Gotham
    Subtitle.Parent = RightPanel

    -- Auth Container
    local AuthContainer = Instance.new("Frame")
    AuthContainer.Size = UDim2.new(1, -40, 0, isMobile() and 170 or 220)
    AuthContainer.Position = UDim2.new(0.5, 0, 0, isMobile() and 75 or 100)
    AuthContainer.AnchorPoint = Vector2.new(0.5, 0)
    AuthContainer.BackgroundTransparency = 1
    AuthContainer.Visible = not isVIP
    AuthContainer.Parent = RightPanel

    local KeyLabel = Instance.new("TextLabel")
    KeyLabel.Size = UDim2.new(1, 0, 0, isMobile() and 15 or 20)
    KeyLabel.BackgroundTransparency = 1
    KeyLabel.Text = "🔑 Enter Your Key"
    KeyLabel.TextColor3 = Color3.fromRGB(203, 213, 224)
    KeyLabel.TextSize = isMobile() and 10 or 12
    KeyLabel.Font = Enum.Font.Gotham
    KeyLabel.Parent = AuthContainer

    local KeyInput = Instance.new("TextBox")
    KeyInput.Size = UDim2.new(1, 0, 0, isMobile() and 35 or 45)
    KeyInput.Position = UDim2.new(0, 0, 0, isMobile() and 20 or 25)
    KeyInput.BackgroundColor3 = Color3.fromRGB(26, 32, 58)
    KeyInput.Text = ""
    KeyInput.PlaceholderText = "Enter 1-day key..."
    KeyInput.TextColor3 = Color3.fromRGB(255, 255, 255)
    KeyInput.PlaceholderColor3 = Color3.fromRGB(113, 128, 150)
    KeyInput.TextSize = isMobile() and 11 or 14
    KeyInput.Font = Enum.Font.Gotham
    KeyInput.ClearTextOnFocus = false
    KeyInput.Parent = AuthContainer
    Instance.new("UICorner", KeyInput).CornerRadius = UDim.new(0, 8)
    local KeyInputStroke = Instance.new("UIStroke", KeyInput)
    KeyInputStroke.Color = Color3.fromRGB(93, 173, 226)
    KeyInputStroke.Thickness = 2
    KeyInputStroke.Transparency = 0.7

    local VerifyButton = Instance.new("TextButton")
    VerifyButton.Size = UDim2.new(1, 0, 0, isMobile() and 35 or 45)
    VerifyButton.Position = UDim2.new(0, 0, 0, isMobile() and 65 or 80)
    VerifyButton.BackgroundColor3 = Color3.fromRGB(255, 215, 0)
    VerifyButton.Text = "VERIFY KEY"
    VerifyButton.TextColor3 = Color3.fromRGB(10, 14, 39)
    VerifyButton.TextSize = isMobile() and 11 or 14
    VerifyButton.Font = Enum.Font.GothamBold
    VerifyButton.Parent = AuthContainer
    Instance.new("UICorner", VerifyButton).CornerRadius = UDim.new(0, 8)

    local StatusText = Instance.new("TextLabel")
    StatusText.Size = UDim2.new(1, 0, 0, isMobile() and 20 or 25)
    StatusText.Position = UDim2.new(0, 0, 0, isMobile() and 110 or 135)
    StatusText.BackgroundTransparency = 1
    StatusText.Text = ""
    StatusText.TextColor3 = Color3.fromRGB(231, 76, 60)
    StatusText.TextSize = isMobile() and 9 or 11
    StatusText.Font = Enum.Font.Gotham
    StatusText.Visible = false
    StatusText.Parent = AuthContainer

    -- Map Container
    local MapContainer = Instance.new("Frame")
    MapContainer.Size = UDim2.new(1, -30, 1, -30)
    MapContainer.Position = UDim2.new(0, 15, 0, 15)
    MapContainer.BackgroundTransparency = 1
    MapContainer.Visible = false
    MapContainer.Parent = RightPanel

    -- Scrollable maps
    local MapsScrollFrame = Instance.new("ScrollingFrame")
    MapsScrollFrame.Size = UDim2.new(1, 0, 1, 0)
    MapsScrollFrame.BackgroundTransparency = 1
    MapsScrollFrame.ScrollBarThickness = isMobile() and 4 or 6
    MapsScrollFrame.CanvasSize = UDim2.new(0, 0, 0, 0)
    MapsScrollFrame.BorderSizePixel = 0
    MapsScrollFrame.Parent = MapContainer

    local MapsFrame = Instance.new("Frame")
    MapsFrame.BackgroundTransparency = 1
    MapsFrame.Size = UDim2.new(1, 0, 0, 0)
    MapsFrame.Parent = MapsScrollFrame

    local MapsLayout = Instance.new("UIGridLayout")
    MapsLayout.CellSize = UDim2.new(0.48, 0, 0, isMobile() and 90 or 120)
    MapsLayout.CellPadding = UDim2.new(0.04, 0, 0, isMobile() and 10 or 15)
    MapsLayout.SortOrder = Enum.SortOrder.LayoutOrder
    MapsLayout.Parent = MapsFrame

    -- Auto-update canvas size
    local function updateCanvasSize()
        MapsScrollFrame.CanvasSize = UDim2.new(0, 0, 0, MapsLayout.AbsoluteContentSize.Y + 20)
    end
    MapsLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(updateCanvasSize)
    task.wait(0.05)
    updateCanvasSize()

    -- Arunika Button
    local ArunikaButton = Instance.new("TextButton")
    ArunikaButton.BackgroundColor3 = Color3.fromRGB(93, 173, 226)
    ArunikaButton.BackgroundTransparency = 0.8
    ArunikaButton.Text = ""
    ArunikaButton.Parent = MapsFrame
    ArunikaButton.LayoutOrder = 1
    Instance.new("UICorner", ArunikaButton).CornerRadius = UDim.new(0, 12)
    Instance.new("UIStroke", ArunikaButton).Color = Color3.fromRGB(93, 173, 226)

    local ArunikaIcon = Instance.new("TextLabel")
    ArunikaIcon.Size = UDim2.new(1, 0, 0, isMobile() and 35 or 50)
    ArunikaIcon.Position = UDim2.new(0, 0, 0, isMobile() and 10 or 15)
    ArunikaIcon.BackgroundTransparency = 1
    ArunikaIcon.Text = "🗺️"
    ArunikaIcon.TextSize = isMobile() and 25 or 35
    ArunikaIcon.Font = Enum.Font.GothamBold
    ArunikaIcon.Parent = ArunikaButton

    local ArunikaText = Instance.new("TextLabel")
    ArunikaText.Size = UDim2.new(1, 0, 0, isMobile() and 25 or 30)
    ArunikaText.Position = UDim2.new(0, 0, 1, isMobile() and -30 or -35)
    ArunikaText.BackgroundTransparency = 1
    ArunikaText.Text = "ARUNIKA"
    ArunikaText.TextColor3 = Color3.fromRGB(255, 255, 255)
    ArunikaText.TextSize = isMobile() and 11 or 14
    ArunikaText.Font = Enum.Font.GothamBold
    ArunikaText.Parent = ArunikaButton

    -- Yahayuk Button
    local YahayukButton = Instance.new("TextButton")
    YahayukButton.BackgroundColor3 = Color3.fromRGB(93, 173, 226)
    YahayukButton.BackgroundTransparency = 0.8
    YahayukButton.Text = ""
    YahayukButton.Parent = MapsFrame
    YahayukButton.LayoutOrder = 2
    Instance.new("UICorner", YahayukButton).CornerRadius = UDim.new(0, 12)
    Instance.new("UIStroke", YahayukButton).Color = Color3.fromRGB(93, 173, 226)

    local YahayukIcon = Instance.new("TextLabel")
    YahayukIcon.Size = UDim2.new(1, 0, 0, isMobile() and 35 or 50)
    YahayukIcon.Position = UDim2.new(0, 0, 0, isMobile() and 10 or 15)
    YahayukIcon.BackgroundTransparency = 1
    YahayukIcon.Text = "🌍"
    YahayukIcon.TextSize = isMobile() and 25 or 35
    YahayukIcon.Font = Enum.Font.GothamBold
    YahayukIcon.Parent = YahayukButton

    local YahayukText = Instance.new("TextLabel")
    YahayukText.Size = UDim2.new(1, 0, 0, isMobile() and 25 or 30)
    YahayukText.Position = UDim2.new(0, 0, 1, isMobile() and -30 or -35)
    YahayukText.BackgroundTransparency = 1
    YahayukText.Text = "YAHAYUK"
    YahayukText.TextColor3 = Color3.fromRGB(255, 255, 255)
    YahayukText.TextSize = isMobile() and 11 or 14
    YahayukText.Font = Enum.Font.GothamBold
    YahayukText.Parent = YahayukButton

    return ScreenGui, MainFrame, Overlay, BlurEffect, AuthContainer, MapContainer, KeyInput, VerifyButton, StatusText, ArunikaButton, YahayukButton, WelcomeText, Subtitle
end

-- Show status helper
local function showStatus(label, msg, success)
    label.Visible = true
    label.Text = msg
    label.TextColor3 = success and Color3.fromRGB(46, 204, 113) or Color3.fromRGB(231, 76, 60)
end

-- Load map
local function loadMap(mapName, gui, blur)
    local url = MAP_SCRIPTS[mapName]
    if not url then return end

    local main = gui:FindFirstChild("MainFrame")
    if main then
        TweenService:Create(main, TweenInfo.new(0.5), {
            Size = UDim2.new(0, 0, 0, 0),
            BackgroundTransparency = 1
        }):Play()
    end

    task.wait(0.5)
    pcall(function()
        loadstring(game:HttpGet(url))()
    end)

    if blur then blur:Destroy() end
    gui:Destroy()
end

-- Main
local function main()
    local vipIds = fetchVIPIds()
    local isVIP = isUserVIP(userId, vipIds)
    local sessionKey = "validated_" .. userId
    local alreadyValid = ValidatedKeys[sessionKey]

    print("User:", LocalPlayer.Name, "| ID:", userId, "| Status:", isVIP and "VIP" or (alreadyValid and "Validated" or "Free"))

    local ScreenGui, MainFrame, Overlay, BlurEffect, AuthContainer, MapContainer, KeyInput, VerifyButton, StatusText, ArunikaButton, YahayukButton, WelcomeText, Subtitle = createLoader(isVIP, LocalPlayer.Name)

    -- Animate in
    MainFrame.Size = UDim2.new(0, 0, 0, 0)
    MainFrame.BackgroundTransparency = 1
    TweenService:Create(MainFrame, TweenInfo.new(0.5, Enum.EasingStyle.Back), {
        Size = UDim2.new(0, isMobile() and 350 or 600, 0, isMobile() and math.floor(350/16*9) or math.floor(600/16*9)),
        BackgroundTransparency = 0
    }):Play()

    -- If VIP or already validated, show maps
    if isVIP or alreadyValid then
        task.wait(0.6)
        WelcomeText.Visible = false
        Subtitle.Visible = false
        AuthContainer.Visible = false
        MapContainer.Visible = true
    end

    -- Verify button
    VerifyButton.MouseButton1Click:Connect(function()
        local key = KeyInput.Text:match("^%s*(.-)%s*$") or ""
        if key == "" then
            showStatus(StatusText, "✗ Please enter a key", false)
            return
        end

        showStatus(StatusText, "⏳ Verifying...", true)
        StatusText.TextColor3 = Color3.fromRGB(255, 215, 0)

        task.spawn(function()
            local ok, err = validateKey(key)
            if ok then
                ValidatedKeys[sessionKey] = true
                showStatus(StatusText, "✓ Access granted!", true)
                task.wait(1.2)

                -- Switch to map view
                WelcomeText.Visible = false
                Subtitle.Visible = false
                AuthContainer.Visible = false
                MapContainer.Visible = true
            else
                showStatus(StatusText, "✗ " .. (err or "Invalid key"), false)
            end
        end)
    end)

    -- Map buttons
    ArunikaButton.MouseButton1Click:Connect(function() loadMap("Arunika", ScreenGui, BlurEffect) end)
    YahayukButton.MouseButton1Click:Connect(function() loadMap("Yahayuk", ScreenGui, BlurEffect) end)

    -- Hover effects
    local function hover(btn)
        local origTrans = btn.BackgroundTransparency
        btn.MouseEnter:Connect(function()
            TweenService:Create(btn, TweenInfo.new(0.2), {BackgroundTransparency = 0.5}):Play()
            local s = btn:FindFirstChildOfClass("UIStroke")
            if s then TweenService:Create(s, TweenInfo.new(0.2), {Transparency = 0.3, Thickness = 3}):Play() end
        end)
        btn.MouseLeave:Connect(function()
            TweenService:Create(btn, TweenInfo.new(0.2), {BackgroundTransparency = origTrans}):Play()
            local s = btn:FindFirstChildOfClass("UIStroke")
            if s then TweenService:Create(s, TweenInfo.new(0.2), {Transparency = 0.7, Thickness = 2}):Play() end
        end)
    end
    hover(VerifyButton)
    hover(ArunikaButton)
    hover(YahayukButton)

    -- Input focus
    KeyInput.Focused:Connect(function()
        local s = KeyInput:FindFirstChildOfClass("UIStroke")
        if s then TweenService:Create(s, TweenInfo.new(0.2), {Transparency = 0.3, Thickness = 3}):Play() end
    end)
    KeyInput.FocusLost:Connect(function()
        local s = KeyInput:FindFirstChildOfClass("UIStroke")
        if s then TweenService:Create(s, TweenInfo.new(0.2), {Transparency = 0.7, Thickness = 2}):Play() end
    end)


end

-- Run
main()
print("✅ VIP Loader v5.1 loaded | Device:", isMobile() and "Mobile" or "Desktop")
