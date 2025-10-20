
-- VIP Loader System - FULL CODE WITH 24H KEY EXPIRY + LOCAL STORAGE + COUNTDOWN + LIFETIME VIP + AUTO VIP UPGRADE
-- Connected to: https://astrion-keycrate.vercel.app/api/validate

local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local HttpService = game:GetService("HttpService")
local UserInputService = game:GetService("UserInputService")

local LocalPlayer = Players.LocalPlayer
local userId = LocalPlayer.UserId

-- GitHub URL for VIP IDs only
local GITHUB_VIP_URL = "https://raw.githubusercontent.com/syannnho/Astrion/refs/heads/main/vip.txt"

-- Map Scripts
local MAP_SCRIPTS = {
    Pargoy = "https://raw.githubusercontent.com/yourusername/maps/main/pargoy.lua"
}

-- Key validation endpoint
local KEY_VALIDATE_URL = "https://astrion-keycrate.vercel.app/api/validate"

-- Local storage path
local STORAGE_FOLDER = "AstrionKeys"
local STORAGE_FILE = STORAGE_FOLDER .. "/key_" .. userId .. ".json"
local VIP_STORAGE_FILE = STORAGE_FOLDER .. "/vip_" .. userId .. ".json"

-- Key duration
local KEY_DURATION = 86400 -- 24 hours in seconds

-- Device detection
local function isMobile()
    return UserInputService.TouchEnabled and not UserInputService.KeyboardEnabled
end

-- File system functions
local function ensureFolder()
    if not isfolder(STORAGE_FOLDER) then
        makefolder(STORAGE_FOLDER)
    end
end

local function saveVIPData(key)
    ensureFolder()
    local data = {
        key = key,
        userId = userId,
        vipType = "lifetime",
        activatedAt = os.time()
    }
    writefile(VIP_STORAGE_FILE, HttpService:JSONEncode(data))
    -- Delete regular key file if exists
    if isfile(STORAGE_FILE) then
        delfile(STORAGE_FILE)
    end
    print("✅ VIP Key saved - Lifetime Access")
end

local function loadVIPData()
    if isfile(VIP_STORAGE_FILE) then
        local success, data = pcall(function()
            return HttpService:JSONDecode(readfile(VIP_STORAGE_FILE))
        end)
        if success and data and data.vipType == "lifetime" then
            return true, data.key
        end
    end
    return false, nil
end

local function saveKeyData(key, expireTime)
    ensureFolder()
    local data = {
        key = key,
        expireTime = expireTime,
        userId = userId
    }
    writefile(STORAGE_FILE, HttpService:JSONEncode(data))
    print("✅ Key saved locally until: " .. os.date("%Y-%m-%d %H:%M:%S", expireTime))
end

local function loadKeyData()
    if isfile(STORAGE_FILE) then
        local success, data = pcall(function()
            return HttpService:JSONDecode(readfile(STORAGE_FILE))
        end)
        if success and data then
            return data.key, data.expireTime
        end
    end
    return nil, nil
end

local function deleteKeyData()
    if isfile(STORAGE_FILE) then
        delfile(STORAGE_FILE)
        print("🗑️ Expired key deleted from local storage")
    end
end

local function isKeyValid()
    local key, expireTime = loadKeyData()
    if key and expireTime then
        local currentTime = os.time()
        if currentTime < expireTime then
            return true, expireTime
        else
            deleteKeyData()
            return false, nil
        end
    end
    return false, nil
end

-- Format countdown time
local function formatTimeRemaining(seconds)
    if seconds <= 0 then
        return "EXPIRED"
    end
    
    local hours = math.floor(seconds / 3600)
    local minutes = math.floor((seconds % 3600) / 60)
    local secs = seconds % 60
    
    if hours > 0 then
        return string.format("%02d:%02d:%02d", hours, minutes, secs)
    else
        return string.format("%02d:%02d", minutes, secs)
    end
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

-- Validate key via web API with VIP detection
local function validateKey(key)
    if not key or type(key) ~= "string" then
        return false, "Invalid key", false
    end

    local url = KEY_VALIDATE_URL .. "?key=" .. HttpService:UrlEncode(key)
    local success, response = pcall(function()
        return game:HttpGetAsync(url)
    end)

    if not success then
        return false, "Network error", false
    end

    local decoded = HttpService:JSONDecode(response)
    if decoded and decoded.success then
        -- Check if this is a VIP key (lifetime)
        local isVIPKey = decoded.vip == true or decoded.lifetime == true or decoded.type == "vip"
        return true, "", isVIPKey
    else
        return false, decoded and decoded.error or "Unknown error", false
    end
end

-- Get expiry time in readable format
local function getExpiryTimeString(expireTime)
    if expireTime then
        return os.date("%Y-%m-%d %H:%M:%S", expireTime)
    end
    return ""
end

-- Create UI
local function createLoader(isVIP, hasVIPKey, playerName, keyExpireTime)
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
    
    local avatarStroke = Instance.new("UIStroke", AvatarFrame)
    avatarStroke.Color = (isVIP or hasVIPKey) and Color3.fromRGB(255, 215, 0) or Color3.fromRGB(93, 173, 226)
    avatarStroke.Thickness = (isVIP or hasVIPKey) and 3 or 2

    local Avatar = Instance.new("ImageLabel")
    Avatar.BackgroundTransparency = 1
    Avatar.Size = UDim2.new(1, -6, 1, -6)
    Avatar.Position = UDim2.new(0, 3, 0, 3)
    Avatar.Image = "https://www.roblox.com/headshot-thumbnail/image?userId=" .. userId .. "&width=420&height=420&format=png"
    Avatar.Parent = AvatarFrame
    Instance.new("UICorner", Avatar).CornerRadius = UDim.new(0.25, 0)

    -- VIP Badge Icon (top left of avatar)
    local VIPBadge = Instance.new("Frame")
    VIPBadge.Size = UDim2.new(0, isMobile() and 28 or 40, 0, isMobile() and 28 or 40)
    VIPBadge.Position = UDim2.new(0, isMobile() and -10 or -15, 0, isMobile() and -10 or -15)
    VIPBadge.BackgroundColor3 = Color3.fromRGB(10, 15, 35)
    VIPBadge.BorderSizePixel = 0
    VIPBadge.Visible = isVIP or hasVIPKey
    VIPBadge.Parent = AvatarFrame
    Instance.new("UICorner", VIPBadge).CornerRadius = UDim.new(0.5, 0)
    
    local vipBadgeStroke = Instance.new("UIStroke", VIPBadge)
    vipBadgeStroke.Color = Color3.fromRGB(255, 215, 0)
    vipBadgeStroke.Thickness = 2

    local VIPIcon = Instance.new("TextLabel")
    VIPIcon.Size = UDim2.new(1, 0, 1, 0)
    VIPIcon.BackgroundTransparency = 1
    VIPIcon.Text = "✨"
    VIPIcon.TextSize = isMobile() and 18 or 24
    VIPIcon.Font = Enum.Font.GothamBold
    VIPIcon.Parent = VIPBadge

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

    -- Status Badge (VIP or Time-based)
    local StatusBadge = Instance.new("Frame")
    StatusBadge.Size = UDim2.new(0.85, 0, 0, isMobile() and 55 or 65)
    StatusBadge.Position = UDim2.new(0.5, 0, 0, isMobile() and 168 or 238)
    StatusBadge.AnchorPoint = Vector2.new(0.5, 0)
    StatusBadge.BackgroundColor3 = (isVIP or hasVIPKey) and Color3.fromRGB(255, 215, 0) or Color3.fromRGB(26, 32, 58)
    StatusBadge.BackgroundTransparency = (isVIP or hasVIPKey) and 0.85 or 0.5
    StatusBadge.BorderSizePixel = 0
    StatusBadge.Parent = LeftPanel
    Instance.new("UICorner", StatusBadge).CornerRadius = UDim.new(0, 10)
    
    local badgeStroke = Instance.new("UIStroke", StatusBadge)
    badgeStroke.Color = (isVIP or hasVIPKey) and Color3.fromRGB(255, 215, 0) or Color3.fromRGB(93, 173, 226)
    badgeStroke.Transparency = 0.5
    badgeStroke.Thickness = 2

    -- Countdown icon/label
    local CountdownIcon = Instance.new("TextLabel")
    CountdownIcon.Size = UDim2.new(1, -10, 0, isMobile() and 20 or 24)
    CountdownIcon.Position = UDim2.new(0.5, 0, 0, 5)
    CountdownIcon.AnchorPoint = Vector2.new(0.5, 0)
    CountdownIcon.BackgroundTransparency = 1
    CountdownIcon.Text = (isVIP or hasVIPKey) and "👑 VIP Status" or "⏱️ Key Expires In:"
    CountdownIcon.TextColor3 = (isVIP or hasVIPKey) and Color3.fromRGB(255, 215, 0) or Color3.fromRGB(160, 174, 192)
    CountdownIcon.TextSize = isMobile() and 9 or 11
    CountdownIcon.Font = Enum.Font.GothamBold
    CountdownIcon.Parent = StatusBadge

    -- Countdown Timer / VIP Label
    local CountdownLabel = Instance.new("TextLabel")
    CountdownLabel.Size = UDim2.new(1, -10, 0, isMobile() and 26 or 32)
    CountdownLabel.Position = UDim2.new(0.5, 0, 0, isMobile() and 25 or 29)
    CountdownLabel.AnchorPoint = Vector2.new(0.5, 0)
    CountdownLabel.BackgroundTransparency = 1
    CountdownLabel.Text = (isVIP or hasVIPKey) and "LIFETIME" or ""
    CountdownLabel.TextColor3 = (isVIP or hasVIPKey) and Color3.fromRGB(255, 215, 0) or Color3.fromRGB(46, 204, 113)
    CountdownLabel.TextSize = isMobile() and 14 or 18
    CountdownLabel.Font = Enum.Font.GothamBold
    CountdownLabel.Parent = StatusBadge

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
    WelcomeText.Text = (isVIP or hasVIPKey) and "WELCOME VIP" or "WELCOME FREE"
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
    Subtitle.Text = (isVIP or hasVIPKey) and "Lifetime Premium Access" or "Premium Access System"
    Subtitle.TextColor3 = Color3.fromRGB(160, 174, 192)
    Subtitle.TextSize = isMobile() and 9 or 12
    Subtitle.Font = Enum.Font.Gotham
    Subtitle.Parent = RightPanel

    -- Auth Container
    local AuthContainer = Instance.new("Frame")
    AuthContainer.Size = UDim2.new(1, -40, 0, isMobile() and 200 or 250)
    AuthContainer.Position = UDim2.new(0.5, 0, 0, isMobile() and 75 or 100)
    AuthContainer.AnchorPoint = Vector2.new(0.5, 0)
    AuthContainer.BackgroundTransparency = 1
    AuthContainer.Visible = not (isVIP or hasVIPKey)
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
    KeyInput.PlaceholderText = "Enter key..."
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
    StatusText.Size = UDim2.new(1, 0, 0, isMobile() and 40 or 50)
    StatusText.Position = UDim2.new(0, 0, 0, isMobile() and 110 or 135)
    StatusText.BackgroundTransparency = 1
    StatusText.Text = ""
    StatusText.TextColor3 = Color3.fromRGB(231, 76, 60)
    StatusText.TextSize = isMobile() and 9 or 11
    StatusText.Font = Enum.Font.Gotham
    StatusText.TextWrapped = true
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

    local function updateCanvasSize()
        MapsScrollFrame.CanvasSize = UDim2.new(0, 0, 0, MapsLayout.AbsoluteContentSize.Y + 20)
    end
    MapsLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(updateCanvasSize)
    task.wait(0.05)
    updateCanvasSize()

    -- Pargoy Button
    local PargoyButton = Instance.new("TextButton")
    PargoyButton.BackgroundColor3 = Color3.fromRGB(93, 173, 226)
    PargoyButton.BackgroundTransparency = 0.8
    PargoyButton.Text = ""
    PargoyButton.Parent = MapsFrame
    PargoyButton.LayoutOrder = 3
    Instance.new("UICorner", PargoyButton).CornerRadius = UDim.new(0, 12)
    Instance.new("UIStroke", PargoyButton).Color = Color3.fromRGB(93, 173, 226)

    local PargoyIcon = Instance.new("TextLabel")
    PargoyIcon.Size = UDim2.new(1, 0, 0, isMobile() and 35 or 50)
    PargoyIcon.Position = UDim2.new(0, 0, 0, isMobile() and 10 or 15)
    PargoyIcon.BackgroundTransparency = 1
    PargoyIcon.Text = "🏔️"
    PargoyIcon.TextSize = isMobile() and 25 or 35
    PargoyIcon.Font = Enum.Font.GothamBold
    PargoyIcon.Parent = PargoyButton

    local PargoyText = Instance.new("TextLabel")
    PargoyText.Size = UDim2.new(1, 0, 0, isMobile() and 25 or 30)
    PargoyText.Position = UDim2.new(0, 0, 1, isMobile() and -30 or -35)
    PargoyText.BackgroundTransparency = 1
    PargoyText.Text = "PARGOY"
    PargoyText.TextColor3 = Color3.fromRGB(255, 255, 255)
    PargoyText.TextSize = isMobile() and 11 or 14
    PargoyText.Font = Enum.Font.GothamBold
    PargoyText.Parent = PargoyButton

    return ScreenGui, MainFrame, Overlay, BlurEffect, AuthContainer, MapContainer, KeyInput, VerifyButton, StatusText, ArunikaButton, YahayukButton, PargoyButton, WelcomeText, Subtitle, CountdownLabel, CountdownIcon, StatusBadge, avatarStroke, VIPBadge, badgeStroke
end

-- Show status helper
local function showStatus(label, msg, success)
    label.Visible = true
    label.Text = msg
    label.TextColor3 = success and Color3.fromRGB(46, 204, 113) or Color3.fromRGB(231, 76, 60)
end

-- Upgrade to VIP visuals
local function upgradeToVIP(WelcomeText, Subtitle, CountdownIcon, CountdownLabel, StatusBadge, avatarStroke, VIPBadge, badgeStroke)
    -- Update text labels
    WelcomeText.Text = "WELCOME VIP"
    Subtitle.Text = "Lifetime Premium Access"
    CountdownIcon.Text = "👑 VIP Status"
    CountdownIcon.TextColor3 = Color3.fromRGB(255, 215, 0)
    CountdownLabel.Text = "LIFETIME"
    CountdownLabel.TextColor3 = Color3.fromRGB(255, 215, 0)
    
    -- Animate status badge to gold
    TweenService:Create(StatusBadge, TweenInfo.new(0.5), {
        BackgroundColor3 = Color3.fromRGB(255, 215, 0),
        BackgroundTransparency = 0.85
    }):Play()
    
    TweenService:Create(badgeStroke, TweenInfo.new(0.5), {
        Color = Color3.fromRGB(255, 215, 0)
    }):Play()
    
    -- Animate avatar border to gold
    TweenService:Create(avatarStroke, TweenInfo.new(0.5), {
        Color = Color3.fromRGB(255, 215, 0),
        Thickness = 3
    }):Play()
    
    -- Show VIP badge with animation
    VIPBadge.Visible = true
    VIPBadge.Size = UDim2.new(0, 0, 0, 0)
    TweenService:Create(VIPBadge, TweenInfo.new(0.4, Enum.EasingStyle.Back), {
        Size = UDim2.new(0, isMobile() and 28 or 40, 0, isMobile() and 28 or 40)
    }):Play()
    
    print("🎉 Upgraded to VIP - UI updated!")
end

-- Check if user became VIP (auto upgrade check)
local function checkVIPUpgrade()
    local vipIds = fetchVIPIds()
    local isVIP = isUserVIP(userId, vipIds)
    local hasVIPKey, vipKey = loadVIPData()
    
    if isVIP and not hasVIPKey then
        -- User is now in VIP list but doesn't have VIP file yet
        saveVIPData("VIP_ID_" .. userId)
        return true
    end
    
    return false
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
    local hasVIPKey, vipKey = loadVIPData()
    local keyValid, expireTime = isKeyValid()

    -- Priority: VIP ID > VIP Key > Regular Key
    local hasAccess = isVIP or hasVIPKey or keyValid
    local isLifetimeAccess = isVIP or hasVIPKey

    print("User:", LocalPlayer.Name, "| ID:", userId)
    print("Status:", isVIP and "VIP (ID)" or (hasVIPKey and "VIP (Key)" or (keyValid and "Validated" or "Free")))
    if isLifetimeAccess then
        print("✅ Lifetime Access Granted")
    elseif keyValid then
        print("✅ Key valid until: " .. getExpiryTimeString(expireTime))
    end

    local ScreenGui, MainFrame, Overlay, BlurEffect, AuthContainer, MapContainer, KeyInput, VerifyButton, StatusText, ArunikaButton, YahayukButton, PargoyButton, WelcomeText, Subtitle, CountdownLabel, CountdownIcon, StatusBadge, avatarStroke, VIPBadge, badgeStroke = createLoader(isVIP, hasVIPKey, LocalPlayer.Name, expireTime)

    -- Auto VIP upgrade checker (runs every 30 seconds)
    local vipCheckConnection
    if not isLifetimeAccess and keyValid then
        vipCheckConnection = task.spawn(function()
            while true do
                task.wait(30) -- Check every 30 seconds
                if checkVIPUpgrade() then
                    upgradeToVIP(WelcomeText, Subtitle, CountdownIcon, CountdownLabel, StatusBadge, avatarStroke, VIPBadge, badgeStroke)
                    if countdownConnection then
                        countdownConnection:Disconnect()
                    end
                    break
                end
            end
        end)
    end

    -- Countdown update loop (only for non-VIP users with time-based keys)
    local countdownConnection
    if keyValid and not isLifetimeAccess and expireTime then
        countdownConnection = game:GetService("RunService").Heartbeat:Connect(function()
            local timeRemaining = expireTime - os.time()
            if timeRemaining > 0 then
                CountdownLabel.Text = formatTimeRemaining(timeRemaining)
                
                -- Color changes based on time
                if timeRemaining <= 3600 then -- Less than 1 hour
                    CountdownLabel.TextColor3 = Color3.fromRGB(231, 76, 60) -- Red
                    StatusBadge.BackgroundColor3 = Color3.fromRGB(231, 76, 60)
                    StatusBadge.BackgroundTransparency = 0.85
                    badgeStroke.Color = Color3.fromRGB(231, 76, 60)
                elseif timeRemaining <= 10800 then -- Less than 3 hours
                    CountdownLabel.TextColor3 = Color3.fromRGB(230, 126, 34) -- Orange
                    StatusBadge.BackgroundColor3 = Color3.fromRGB(230, 126, 34)
                    StatusBadge.BackgroundTransparency = 0.85
                    badgeStroke.Color = Color3.fromRGB(230, 126, 34)
                else
                    CountdownLabel.TextColor3 = Color3.fromRGB(46, 204, 113) -- Green
                    StatusBadge.BackgroundColor3 = Color3.fromRGB(46, 204, 113)
                    StatusBadge.BackgroundTransparency = 0.85
                    badgeStroke.Color = Color3.fromRGB(93, 173, 226)
                end
            else
                CountdownLabel.Text = "EXPIRED"
                CountdownLabel.TextColor3 = Color3.fromRGB(231, 76, 60)
                if countdownConnection then
                    countdownConnection:Disconnect()
                end
                if vipCheckConnection then
                    task.cancel(vipCheckConnection)
                end
                -- Force user to re-authenticate
                deleteKeyData()
                task.wait(2)
                if ScreenGui then ScreenGui:Destroy() end
                if BlurEffect then BlurEffect:Destroy() end
                main() -- Restart
            end
        end)
    end

    -- Animate in
    MainFrame.Size = UDim2.new(0, 0, 0, 0)
    MainFrame.BackgroundTransparency = 1
    TweenService:Create(MainFrame, TweenInfo.new(0.5, Enum.EasingStyle.Back), {
        Size = UDim2.new(0, isMobile() and 350 or 600, 0, isMobile() and math.floor(350/16*9) or math.floor(600/16*9)),
        BackgroundTransparency = 0
    }):Play()

    -- If has access (VIP or valid key), show maps immediately
    if hasAccess then
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
            local ok, err, isVIPKey = validateKey(key)
            if ok then
                if isVIPKey then
                    -- VIP Key - Lifetime Access
                    saveVIPData(key)
                    showStatus(StatusText, "✓ VIP Access Granted!\nLifetime Access", true)
                    task.wait(1.5)
                    
                    -- Upgrade UI to VIP
                    upgradeToVIP(WelcomeText, Subtitle, CountdownIcon, CountdownLabel, StatusBadge, avatarStroke, VIPBadge, badgeStroke)
                    
                    -- Stop countdown if running
                    if countdownConnection then
                        countdownConnection:Disconnect()
                    end
                    if vipCheckConnection then
                        task.cancel(vipCheckConnection)
                    end
                else
                    -- Regular Key - 24 Hour Access
                    local newExpireTime = os.time() + KEY_DURATION
                    saveKeyData(key, newExpireTime)
                    
                    local expiryTimeStr = getExpiryTimeString(newExpireTime)
                    showStatus(StatusText, "✓ Access granted!\nExpires: " .. expiryTimeStr, true)
                    task.wait(1.5)

                    -- Start countdown after successful verification
                    if countdownConnection then
                        countdownConnection:Disconnect()
                    end
                    
                    -- Start VIP check loop
                    if vipCheckConnection then
                        task.cancel(vipCheckConnection)
                    end
                    vipCheckConnection = task.spawn(function()
                        while true do
                            task.wait(30)
                            if checkVIPUpgrade() then
                                upgradeToVIP(WelcomeText, Subtitle, CountdownIcon, CountdownLabel, StatusBadge, avatarStroke, VIPBadge, badgeStroke)
                                if countdownConnection then
                                    countdownConnection:Disconnect()
                                end
                                break
                            end
                        end
                    end)
                    
                    countdownConnection = game:GetService("RunService").Heartbeat:Connect(function()
                        local timeRemaining = newExpireTime - os.time()
                        if timeRemaining > 0 then
                            CountdownLabel.Text = formatTimeRemaining(timeRemaining)
                            
                            -- Color changes based on time
                            if timeRemaining <= 3600 then
                                CountdownLabel.TextColor3 = Color3.fromRGB(231, 76, 60)
                                StatusBadge.BackgroundColor3 = Color3.fromRGB(231, 76, 60)
                                StatusBadge.BackgroundTransparency = 0.85
                                badgeStroke.Color = Color3.fromRGB(231, 76, 60)
                            elseif timeRemaining <= 10800 then
                                CountdownLabel.TextColor3 = Color3.fromRGB(230, 126, 34)
                                StatusBadge.BackgroundColor3 = Color3.fromRGB(230, 126, 34)
                                StatusBadge.BackgroundTransparency = 0.85
                                badgeStroke.Color = Color3.fromRGB(230, 126, 34)
                            else
                                CountdownLabel.TextColor3 = Color3.fromRGB(46, 204, 113)
                                StatusBadge.BackgroundColor3 = Color3.fromRGB(46, 204, 113)
                                StatusBadge.BackgroundTransparency = 0.85
                                badgeStroke.Color = Color3.fromRGB(93, 173, 226)
                            end
                        else
                            CountdownLabel.Text = "EXPIRED"
                            CountdownLabel.TextColor3 = Color3.fromRGB(231, 76, 60)
                            if countdownConnection then
                                countdownConnection:Disconnect()
                            end
                            if vipCheckConnection then
                                task.cancel(vipCheckConnection)
                            end
                            deleteKeyData()
                            task.wait(2)
                            if ScreenGui then ScreenGui:Destroy() end
                            if BlurEffect then BlurEffect:Destroy() end
                            main()
                        end
                    end)
                end
                
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
    ArunikaButton.MouseButton1Click:Connect(function() 
        if countdownConnection then
            countdownConnection:Disconnect()
        end
        if vipCheckConnection then
            task.cancel(vipCheckConnection)
        end
        loadMap("Arunika", ScreenGui, BlurEffect) 
    end)
    
    YahayukButton.MouseButton1Click:Connect(function() 
        if countdownConnection then
            countdownConnection:Disconnect()
        end
        if vipCheckConnection then
            task.cancel(vipCheckConnection)
        end
        loadMap("Yahayuk", ScreenGui, BlurEffect) 
    end)
    
    PargoyButton.MouseButton1Click:Connect(function() 
        if countdownConnection then
            countdownConnection:Disconnect()
        end
        if vipCheckConnection then
            task.cancel(vipCheckConnection)
        end
        loadMap("Pargoy", ScreenGui, BlurEffect) 
    end)

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
    hover(PargoyButton)

    -- Input focus
    KeyInput.Focused:Connect(function()
        local s = KeyInput:FindFirstChildOfClass("UIStroke")
        if s then TweenService:Create(s, TweenInfo.new(0.2), {Transparency = 0.3, Thickness = 3}):Play() end
    end)
    KeyInput.FocusLost:Connect(function()
        local s = KeyInput:FindFirstChildOfClass("UIStroke")
        if s then TweenService:Create(s, TweenInfo.new(0.2), {Transparency = 0.7, Thickness = 2}):Play() end
    end)
    
    -- Cleanup on GUI destroy
    ScreenGui.Destroying:Connect(function()
        if countdownConnection then
            countdownConnection:Disconnect()
        end
        if vipCheckConnection then
            task.cancel(vipCheckConnection)
        end
    end)
end

-- Run
main()
print("✅ VIP Loader v10.0 - Auto VIP Upgrade System | Device:", isMobile() and "Mobile" or "Desktop")
print("📁 Storage location: " .. STORAGE_FOLDER)
print("👑 VIP keys grant lifetime access - Regular keys last 24 hours")
print("🔄 Auto VIP upgrade check every 30 seconds")
