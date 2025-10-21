-- VIP Loader System v11.0 - UPDATED
-- Connected to: https://astrion-keycrate.vercel.app/api/validate

local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local HttpService = game:GetService("HttpService")
local UserInputService = game:GetService("UserInputService")

local LocalPlayer = Players.LocalPlayer
local userId = LocalPlayer.UserId

-- GitHub URLs
local GITHUB_VIP_URL = "https://raw.githubusercontent.com/syannnho/Astrion/refs/heads/main/vip.txt"
local TRIAL_VIP_URL = "https://raw.githubusercontent.com/syannnho/Astrion/refs/heads/main/Keys/Trialvip.txt"

-- Map Scripts - ALL MAPS
local ALL_MAPS = {
    {name = "ATIN", url = "https://raw.githubusercontent.com/syannnho/Astrion/refs/heads/main/DATAMAP/ATIN/main.lua", icon = "🏔️"},
    {name = "ARUNIKA", url = "https://raw.githubusercontent.com/syannnho/Astrion/refs/heads/main/DATAMAP/ARUNIKA/main.lua", icon = "🌅"},
    {name = "DAUN", url = "https://raw.githubusercontent.com/syannnho/Astrion/refs/heads/main/DATAMAP/DAUN/main.lua", icon = "🍃"},
    {name = "MT AGE", url = "https://raw.githubusercontent.com/syannnho/Astrion/refs/heads/main/DATAMAP/MT%20AGE/main.lua", icon = "⛰️"},
    {name = "PARGOY", url = "https://raw.githubusercontent.com/syannnho/Astrion/refs/heads/main/DATAMAP/PARGOY/main.lua", icon = "🗻"},
    {name = "PEDAUNAN", url = "https://raw.githubusercontent.com/syannnho/Astrion/refs/heads/main/DATAMAP/PEDAUNAN/main.lua", icon = "🌿"},
    {name = "SIBUATAN", url = "https://raw.githubusercontent.com/syannnho/Astrion/refs/heads/main/DATAMAP/SIBUATAN/main.lua", icon = "🏞️"}
}

-- Free user map (only ARUNIKA)
local FREE_MAPS = {
    {name = "ARUNIKA", url = "https://raw.githubusercontent.com/syannnho/Astrion/refs/heads/main/DATAMAP/ARUNIKA/main.lua", icon = "🌅"}
}

-- Key validation endpoint
local KEY_VALIDATE_URL = "https://astrion-keycrate.vercel.app/api/validate"

-- Local storage
local STORAGE_FOLDER = "AstrionKeys"
local STORAGE_FILE = STORAGE_FOLDER .. "/key_" .. userId .. ".json"
local VIP_STORAGE_FILE = STORAGE_FOLDER .. "/vip_" .. userId .. ".json"
local TRIAL_STORAGE_FILE = STORAGE_FOLDER .. "/trial_" .. userId .. ".json"

-- Key durations
local KEY_DURATION = 86400 -- 24 hours
local TRIAL_DURATION = 3600 -- 1 hour

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
    if isfile(STORAGE_FILE) then delfile(STORAGE_FILE) end
    if isfile(TRIAL_STORAGE_FILE) then delfile(TRIAL_STORAGE_FILE) end
    print("✅ VIP Key saved - Lifetime Access")
end

local function saveTrialVIPData(key, expireTime)
    ensureFolder()
    local data = {
        key = key,
        userId = userId,
        vipType = "trial",
        expireTime = expireTime,
        activatedAt = os.time()
    }
    writefile(TRIAL_STORAGE_FILE, HttpService:JSONEncode(data))
    if isfile(STORAGE_FILE) then delfile(STORAGE_FILE) end
    print("✅ Trial VIP Key saved - 1 Hour Access")
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

local function loadTrialVIPData()
    if isfile(TRIAL_STORAGE_FILE) then
        local success, data = pcall(function()
            return HttpService:JSONDecode(readfile(TRIAL_STORAGE_FILE))
        end)
        if success and data and data.vipType == "trial" then
            local currentTime = os.time()
            if currentTime < data.expireTime then
                return true, data.key, data.expireTime
            else
                delfile(TRIAL_STORAGE_FILE)
                print("🗑️ Trial VIP expired and deleted")
            end
        end
    end
    return false, nil, nil
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
        print("🗑️ Expired key deleted")
    end
end

local function isKeyValid()
    local key, expireTime = loadKeyData()
    if key and expireTime then
        if os.time() < expireTime then
            return true, expireTime
        else
            deleteKeyData()
        end
    end
    return false, nil
end

-- Format time
local function formatTimeRemaining(seconds)
    if seconds <= 0 then return "EXPIRED" end
    local hours = math.floor(seconds / 3600)
    local minutes = math.floor((seconds % 3600) / 60)
    local secs = seconds % 60
    if hours > 0 then
        return string.format("%02d:%02d:%02d", hours, minutes, secs)
    else
        return string.format("%02d:%02d", minutes, secs)
    end
end

-- Fetch VIP IDs
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

-- Fetch Trial VIP Keys
local function fetchTrialVIPKeys()
    local success, response = pcall(function()
        return game:HttpGet(TRIAL_VIP_URL)
    end)
    if success then
        local keys = {}
        for line in response:gmatch("[^\r\n]+") do
            local key = line:match("^%s*(.-)%s*$")
            if key ~= "" then
                table.insert(keys, key)
            end
        end
        return keys
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

-- Check if key is trial VIP
local function isTrialVIPKey(key, trialKeys)
    for _, trialKey in ipairs(trialKeys) do
        if key == trialKey then
            return true
        end
    end
    return false
end

-- Validate key
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
        local isVIPKey = decoded.vip == true or decoded.lifetime == true or decoded.type == "vip"
        return true, "", isVIPKey
    else
        return false, decoded and decoded.error or "Unknown error", false
    end
end

-- Get expiry time string
local function getExpiryTimeString(expireTime)
    if expireTime then
        return os.date("%Y-%m-%d %H:%M:%S", expireTime)
    end
    return ""
end

-- Create UI
local function createLoader(userType, playerName, keyExpireTime)
    local isVIP = userType == "vip"
    local isTrialVIP = userType == "trial"
    local isFree = userType == "free"
    
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

    -- Frame size - FIXED: Proper sizing
    local frameWidth = isMobile() and 350 or 600
    local frameHeight = isMobile() and 450 or 500

    -- Main Frame
    local MainFrame = Instance.new("Frame")
    MainFrame.Size = UDim2.new(0, frameWidth, 0, frameHeight)
    MainFrame.Position = UDim2.new(0.5, 0, 0.5, 0)
    MainFrame.AnchorPoint = Vector2.new(0.5, 0.5)
    MainFrame.BackgroundColor3 = Color3.fromRGB(15, 20, 45)
    MainFrame.BorderSizePixel = 0
    MainFrame.ZIndex = 2
    MainFrame.ClipsDescendants = true
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
    avatarStroke.Color = (isVIP or isTrialVIP) and Color3.fromRGB(255, 215, 0) or Color3.fromRGB(93, 173, 226)
    avatarStroke.Thickness = (isVIP or isTrialVIP) and 3 or 2

    local Avatar = Instance.new("ImageLabel")
    Avatar.BackgroundTransparency = 1
    Avatar.Size = UDim2.new(1, -6, 1, -6)
    Avatar.Position = UDim2.new(0, 3, 0, 3)
    Avatar.Image = "https://www.roblox.com/headshot-thumbnail/image?userId=" .. userId .. "&width=420&height=420&format=png"
    Avatar.Parent = AvatarFrame
    Instance.new("UICorner", Avatar).CornerRadius = UDim.new(0.25, 0)

    -- VIP Badge
    local VIPBadge = Instance.new("Frame")
    VIPBadge.Size = UDim2.new(0, isMobile() and 28 or 40, 0, isMobile() and 28 or 40)
    VIPBadge.Position = UDim2.new(0, isMobile() and -10 or -15, 0, isMobile() and -10 or -15)
    VIPBadge.BackgroundColor3 = Color3.fromRGB(10, 15, 35)
    VIPBadge.BorderSizePixel = 0
    VIPBadge.Visible = isVIP or isTrialVIP
    VIPBadge.Parent = AvatarFrame
    Instance.new("UICorner", VIPBadge).CornerRadius = UDim.new(0.5, 0)
    
    local vipBadgeStroke = Instance.new("UIStroke", VIPBadge)
    vipBadgeStroke.Color = Color3.fromRGB(255, 215, 0)
    vipBadgeStroke.Thickness = 2

    local VIPIcon = Instance.new("TextLabel")
    VIPIcon.Size = UDim2.new(1, 0, 1, 0)
    VIPIcon.BackgroundTransparency = 1
    VIPIcon.Text = isTrialVIP and "⏳" or "✨"
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

    -- Status Badge
    local StatusBadge = Instance.new("Frame")
    StatusBadge.Size = UDim2.new(0.85, 0, 0, isMobile() and 55 or 65)
    StatusBadge.Position = UDim2.new(0.5, 0, 0, isMobile() and 168 or 238)
    StatusBadge.AnchorPoint = Vector2.new(0.5, 0)
    StatusBadge.BackgroundColor3 = (isVIP or isTrialVIP) and Color3.fromRGB(255, 215, 0) or Color3.fromRGB(26, 32, 58)
    StatusBadge.BackgroundTransparency = (isVIP or isTrialVIP) and 0.85 or 0.5
    StatusBadge.BorderSizePixel = 0
    StatusBadge.Parent = LeftPanel
    Instance.new("UICorner", StatusBadge).CornerRadius = UDim.new(0, 10)
    
    local badgeStroke = Instance.new("UIStroke", StatusBadge)
    badgeStroke.Color = (isVIP or isTrialVIP) and Color3.fromRGB(255, 215, 0) or Color3.fromRGB(93, 173, 226)
    badgeStroke.Transparency = 0.5
    badgeStroke.Thickness = 2

    -- Status text
    local CountdownIcon = Instance.new("TextLabel")
    CountdownIcon.Size = UDim2.new(1, -10, 0, isMobile() and 20 or 24)
    CountdownIcon.Position = UDim2.new(0.5, 0, 0, 5)
    CountdownIcon.AnchorPoint = Vector2.new(0.5, 0)
    CountdownIcon.BackgroundTransparency = 1
    CountdownIcon.Text = isVIP and "👑 VIP Status" or (isTrialVIP and "⏳ Trial VIP" or "⏱️ Key Expires In:")
    CountdownIcon.TextColor3 = (isVIP or isTrialVIP) and Color3.fromRGB(255, 215, 0) or Color3.fromRGB(160, 174, 192)
    CountdownIcon.TextSize = isMobile() and 9 or 11
    CountdownIcon.Font = Enum.Font.GothamBold
    CountdownIcon.Parent = StatusBadge

    local CountdownLabel = Instance.new("TextLabel")
    CountdownLabel.Size = UDim2.new(1, -10, 0, isMobile() and 26 or 32)
    CountdownLabel.Position = UDim2.new(0.5, 0, 0, isMobile() and 25 or 29)
    CountdownLabel.AnchorPoint = Vector2.new(0.5, 0)
    CountdownLabel.BackgroundTransparency = 1
    CountdownLabel.Text = isVIP and "LIFETIME" or ""
    CountdownLabel.TextColor3 = (isVIP or isTrialVIP) and Color3.fromRGB(255, 215, 0) or Color3.fromRGB(46, 204, 113)
    CountdownLabel.TextSize = isMobile() and 14 or 18
    CountdownLabel.Font = Enum.Font.GothamBold
    CountdownLabel.Parent = StatusBadge

    -- Right Panel
    local RightPanel = Instance.new("Frame")
    RightPanel.Size = UDim2.new(0.65, 0, 1, 0)
    RightPanel.Position = UDim2.new(0.35, 0, 0, 0)
    RightPanel.BackgroundTransparency = 1
    RightPanel.ClipsDescendants = true
    RightPanel.Parent = MainFrame

    -- Welcome Text
    local WelcomeText = Instance.new("TextLabel")
    WelcomeText.Size = UDim2.new(1, -40, 0, isMobile() and 30 or 40)
    WelcomeText.Position = UDim2.new(0.5, 0, 0, isMobile() and 15 or 25)
    WelcomeText.AnchorPoint = Vector2.new(0.5, 0)
    WelcomeText.BackgroundTransparency = 1
    WelcomeText.Text = isVIP and "WELCOME VIP" or (isTrialVIP and "TRIAL VIP" or "WELCOME FREE")
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
    Subtitle.Text = isVIP and "Lifetime Premium Access" or (isTrialVIP and "1 Hour VIP Access" or "Limited Access")
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
    AuthContainer.Visible = isFree
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

    -- Map Container - FIXED: Better scrolling
    local MapContainer = Instance.new("Frame")
    MapContainer.Size = UDim2.new(1, -30, 1, isMobile() and -80 or -100)
    MapContainer.Position = UDim2.new(0, 15, 0, isMobile() and 70 or 90)
    MapContainer.BackgroundTransparency = 1
    MapContainer.Visible = not isFree
    MapContainer.ClipsDescendants = true
    MapContainer.Parent = RightPanel

    local MapsScrollFrame = Instance.new("ScrollingFrame")
    MapsScrollFrame.Size = UDim2.new(1, 0, 1, 0)
    MapsScrollFrame.BackgroundTransparency = 1
    MapsScrollFrame.ScrollBarThickness = isMobile() and 4 or 6
    MapsScrollFrame.CanvasSize = UDim2.new(0, 0, 0, 0)
    MapsScrollFrame.BorderSizePixel = 0
    MapsScrollFrame.ScrollBarImageColor3 = Color3.fromRGB(255, 215, 0)
    MapsScrollFrame.Parent = MapContainer

    local MapsFrame = Instance.new("Frame")
    MapsFrame.BackgroundTransparency = 1
    MapsFrame.Size = UDim2.new(1, 0, 0, 0)
    MapsFrame.Parent = MapsScrollFrame

    local MapsLayout = Instance.new("UIGridLayout")
    MapsLayout.CellSize = UDim2.new(0.48, 0, 0, isMobile() and 80 or 100)
    MapsLayout.CellPadding = UDim2.new(0.04, 0, 0, isMobile() and 8 or 12)
    MapsLayout.SortOrder = Enum.SortOrder.LayoutOrder
    MapsLayout.Parent = MapsFrame

    local function updateCanvasSize()
        local contentHeight = MapsLayout.AbsoluteContentSize.Y
        MapsScrollFrame.CanvasSize = UDim2.new(0, 0, 0, contentHeight + 10)
    end
    MapsLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(updateCanvasSize)

    return ScreenGui, MainFrame, Overlay, BlurEffect, AuthContainer, MapContainer, KeyInput, VerifyButton, StatusText, WelcomeText, Subtitle, CountdownLabel, CountdownIcon, StatusBadge, avatarStroke, VIPBadge, badgeStroke, VIPIcon, MapsFrame, MapsScrollFrame
end

-- Show status
local function showStatus(label, msg, success)
    label.Visible = true
    label.Text = msg
    label.TextColor3 = success and Color3.fromRGB(46, 204, 113) or Color3.fromRGB(231, 76, 60)
end

-- Upgrade to VIP
local function upgradeToVIP(WelcomeText, Subtitle, CountdownIcon, CountdownLabel, StatusBadge, avatarStroke, VIPBadge, badgeStroke, VIPIcon, isTrial)
    WelcomeText.Text = isTrial and "TRIAL VIP" or "WELCOME VIP"
    Subtitle.Text = isTrial and "1 Hour VIP Access" or "Lifetime Premium Access"
    CountdownIcon.Text = isTrial and "⏳ Trial VIP" or "👑 VIP Status"
    CountdownIcon.TextColor3 = Color3.fromRGB(255, 215, 0)
    CountdownLabel.Text = isTrial and "" or "LIFETIME"
    CountdownLabel.TextColor3 = Color3.fromRGB(255, 215, 0)
    VIPIcon.Text = isTrial and "⏳" or "✨"
    
    TweenService:Create(StatusBadge, TweenInfo.new(0.5), {
        BackgroundColor3 = Color3.fromRGB(255, 215, 0),
        BackgroundTransparency = 0.85
    }):Play()
    
    TweenService:Create(badgeStroke, TweenInfo.new(0.5), {
        Color = Color3.fromRGB(255, 215, 0)
    }):Play()
    
    TweenService:Create(avatarStroke, TweenInfo.new(0.5), {
        Color = Color3.fromRGB(255, 215, 0),
        Thickness = 3
    }):Play()
    
    VIPBadge.Visible = true
    VIPBadge.Size = UDim2.new(0, 0, 0, 0)
    TweenService:Create(VIPBadge, TweenInfo.new(0.4, Enum.EasingStyle.Back), {
        Size = UDim2.new(0, isMobile() and 28 or 40, 0, isMobile() and 28 or 40)
    }):Play()
    
    print("🎉 Upgraded to " .. (isTrial and "Trial VIP" or "VIP") .. " - UI updated!")
end

-- Check VIP upgrade
local function checkVIPUpgrade()
    local vipIds = fetchVIPIds()
    local isVIP = isUserVIP(userId, vipIds)
    local hasVIPKey, vipKey = loadVIPData()
    
    if isVIP and not hasVIPKey then
        saveVIPData("VIP_ID_" .. userId)
        return true
    end
    
    return false
end

-- Load map
local function loadMap(mapName, mapUrl, gui, blur)
    local main = gui:FindFirstChild("MainFrame")
    if main then
        TweenService:Create(main, TweenInfo.new(0.5), {
            Size = UDim2.new(0, 0, 0, 0),
            BackgroundTransparency = 1
        }):Play()
    end

    task.wait(0.5)
    
    local success, err = pcall(function()
        loadstring(game:HttpGet(mapUrl))()
    end)
    
    if not success then
        warn("❌ Failed to load map:", mapName, "Error:", err)
    else
        print("✅ Map loaded successfully:", mapName)
    end

    if blur then blur:Destroy() end
    gui:Destroy()
end

-- Create map buttons
local function createMapButtons(mapsFrame, mapsList, gui, blur)
    local buttons = {}
    
    for i, mapData in ipairs(mapsList) do
        local MapButton = Instance.new("TextButton")
        MapButton.BackgroundColor3 = Color3.fromRGB(93, 173, 226)
        MapButton.BackgroundTransparency = 0.8
        MapButton.Text = ""
        MapButton.LayoutOrder = i
        MapButton.Parent = mapsFrame
        Instance.new("UICorner", MapButton).CornerRadius = UDim.new(0, 12)
        local btnStroke = Instance.new("UIStroke", MapButton)
        btnStroke.Color = Color3.fromRGB(93, 173, 226)
        btnStroke.Thickness = 2

        local MapIcon = Instance.new("TextLabel")
        MapIcon.Size = UDim2.new(1, 0, 0, isMobile() and 30 or 40)
        MapIcon.Position = UDim2.new(0, 0, 0, isMobile() and 8 or 12)
        MapIcon.BackgroundTransparency = 1
        MapIcon.Text = mapData.icon
        MapIcon.TextSize = isMobile() and 20 or 28
        MapIcon.Font = Enum.Font.GothamBold
        MapIcon.Parent = MapButton

        local MapText = Instance.new("TextLabel")
        MapText.Size = UDim2.new(1, 0, 0, isMobile() and 20 or 25)
        MapText.Position = UDim2.new(0, 0, 1, isMobile() and -25 or -30)
        MapText.BackgroundTransparency = 1
        MapText.Text = mapData.name
        MapText.TextColor3 = Color3.fromRGB(255, 255, 255)
        MapText.TextSize = isMobile() and 10 or 12
        MapText.Font = Enum.Font.GothamBold
        MapText.Parent = MapButton

        MapButton.MouseButton1Click:Connect(function()
            loadMap(mapData.name, mapData.url, gui, blur)
        end)
        
        -- Hover effect
        MapButton.MouseEnter:Connect(function()
            TweenService:Create(MapButton, TweenInfo.new(0.2), {BackgroundTransparency = 0.5}):Play()
            TweenService:Create(btnStroke, TweenInfo.new(0.2), {Transparency = 0.3, Thickness = 3}):Play()
        end)
        MapButton.MouseLeave:Connect(function()
            TweenService:Create(MapButton, TweenInfo.new(0.2), {BackgroundTransparency = 0.8}):Play()
            TweenService:Create(btnStroke, TweenInfo.new(0.2), {Transparency = 0, Thickness = 2}):Play()
        end)
        
        table.insert(buttons, MapButton)
    end
    
    return buttons
end

-- Main
local function main()
    local vipIds = fetchVIPIds()
    local trialKeys = fetchTrialVIPKeys()
    local isVIP = isUserVIP(userId, vipIds)
    local hasVIPKey, vipKey = loadVIPData()
    local hasTrialVIP, trialKey, trialExpire = loadTrialVIPData()
    local keyValid, expireTime = isKeyValid()

    local userType = "free"
    local keyExpireTime = nil
    
    if isVIP or hasVIPKey then
        userType = "vip"
    elseif hasTrialVIP then
        userType = "trial"
        keyExpireTime = trialExpire
    elseif keyValid then
        userType = "free"
        keyExpireTime = expireTime
    end

    print("User:", LocalPlayer.Name, "| ID:", userId)
    print("Status:", userType == "vip" and "VIP" or (userType == "trial" and "Trial VIP" or "Free"))
    if keyExpireTime then
        print("✅ Access until: " .. getExpiryTimeString(keyExpireTime))
    end

    local ScreenGui, MainFrame, Overlay, BlurEffect, AuthContainer, MapContainer, KeyInput, VerifyButton, StatusText, WelcomeText, Subtitle, CountdownLabel, CountdownIcon, StatusBadge, avatarStroke, VIPBadge, badgeStroke, VIPIcon, MapsFrame, MapsScrollFrame = createLoader(userType, LocalPlayer.Name, keyExpireTime)

    -- Create map buttons based on user type
    local mapsList = (userType == "vip" or userType == "trial") and ALL_MAPS or FREE_MAPS
    createMapButtons(MapsFrame, mapsList, ScreenGui, BlurEffect)
    
    task.wait(0.1)
    MapsScrollFrame.CanvasSize = UDim2.new(0, 0, 0, MapsFrame.UIGridLayout.AbsoluteContentSize.Y + 10)

    -- VIP upgrade checker
    local vipCheckConnection
    if userType ~= "vip" then
        vipCheckConnection = task.spawn(function()
            while true do
                task.wait(30)
                if checkVIPUpgrade() then
                    upgradeToVIP(WelcomeText, Subtitle, CountdownIcon, CountdownLabel, StatusBadge, avatarStroke, VIPBadge, badgeStroke, VIPIcon, false)
                    MapContainer.Visible = false
                    task.wait(0.1)
                    for _, child in ipairs(MapsFrame:GetChildren()) do
                        if child:IsA("TextButton") then
                            child:Destroy()
                        end
                    end
                    createMapButtons(MapsFrame, ALL_MAPS, ScreenGui, BlurEffect)
                    task.wait(0.1)
                    MapsScrollFrame.CanvasSize = UDim2.new(0, 0, 0, MapsFrame.UIGridLayout.AbsoluteContentSize.Y + 10)
                    MapContainer.Visible = true
                    if countdownConnection then
                        countdownConnection:Disconnect()
                    end
                    break
                end
            end
        end)
    end

    -- Countdown
    local countdownConnection
    if keyExpireTime and userType ~= "vip" then
        countdownConnection = game:GetService("RunService").Heartbeat:Connect(function()
            local timeRemaining = keyExpireTime - os.time()
            if timeRemaining > 0 then
                CountdownLabel.Text = formatTimeRemaining(timeRemaining)
                
                if timeRemaining <= 600 then
                    CountdownLabel.TextColor3 = Color3.fromRGB(231, 76, 60)
                    StatusBadge.BackgroundColor3 = Color3.fromRGB(231, 76, 60)
                    StatusBadge.BackgroundTransparency = 0.85
                    badgeStroke.Color = Color3.fromRGB(231, 76, 60)
                elseif timeRemaining <= 1800 then
                    CountdownLabel.TextColor3 = Color3.fromRGB(230, 126, 34)
                    StatusBadge.BackgroundColor3 = Color3.fromRGB(230, 126, 34)
                    StatusBadge.BackgroundTransparency = 0.85
                    badgeStroke.Color = Color3.fromRGB(230, 126, 34)
                else
                    CountdownLabel.TextColor3 = Color3.fromRGB(255, 215, 0)
                    StatusBadge.BackgroundColor3 = Color3.fromRGB(255, 215, 0)
                    StatusBadge.BackgroundTransparency = 0.85
                    badgeStroke.Color = Color3.fromRGB(255, 215, 0)
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
                if userType == "trial" then
                    delfile(TRIAL_STORAGE_FILE)
                else
                    deleteKeyData()
                end
                task.wait(2)
                if ScreenGui then ScreenGui:Destroy() end
                if BlurEffect then BlurEffect:Destroy() end
                main()
            end
        end)
    end

    -- Animate
    MainFrame.Size = UDim2.new(0, 0, 0, 0)
    MainFrame.BackgroundTransparency = 1
    TweenService:Create(MainFrame, TweenInfo.new(0.5, Enum.EasingStyle.Back), {
        Size = UDim2.new(0, isMobile() and 350 or 600, 0, isMobile() and 450 or 500),
        BackgroundTransparency = 0
    }):Play()

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
            -- Check if trial VIP key
            local isTrialKey = isTrialVIPKey(key, trialKeys)
            
            if isTrialKey then
                local newExpireTime = os.time() + TRIAL_DURATION
                saveTrialVIPData(key, newExpireTime)
                showStatus(StatusText, "✓ Trial VIP Activated!\n1 Hour Access", true)
                task.wait(1.5)
                
                upgradeToVIP(WelcomeText, Subtitle, CountdownIcon, CountdownLabel, StatusBadge, avatarStroke, VIPBadge, badgeStroke, VIPIcon, true)
                
                AuthContainer.Visible = false
                MapContainer.Visible = false
                
                for _, child in ipairs(MapsFrame:GetChildren()) do
                    if child:IsA("TextButton") then
                        child:Destroy()
                    end
                end
                createMapButtons(MapsFrame, ALL_MAPS, ScreenGui, BlurEffect)
                task.wait(0.1)
                MapsScrollFrame.CanvasSize = UDim2.new(0, 0, 0, MapsFrame.UIGridLayout.AbsoluteContentSize.Y + 10)
                MapContainer.Visible = true
                
                if countdownConnection then
                    countdownConnection:Disconnect()
                end
                
                countdownConnection = game:GetService("RunService").Heartbeat:Connect(function()
                    local timeRemaining = newExpireTime - os.time()
                    if timeRemaining > 0 then
                        CountdownLabel.Text = formatTimeRemaining(timeRemaining)
                        
                        if timeRemaining <= 600 then
                            CountdownLabel.TextColor3 = Color3.fromRGB(231, 76, 60)
                            StatusBadge.BackgroundColor3 = Color3.fromRGB(231, 76, 60)
                            badgeStroke.Color = Color3.fromRGB(231, 76, 60)
                        elseif timeRemaining <= 1800 then
                            CountdownLabel.TextColor3 = Color3.fromRGB(230, 126, 34)
                            StatusBadge.BackgroundColor3 = Color3.fromRGB(230, 126, 34)
                            badgeStroke.Color = Color3.fromRGB(230, 126, 34)
                        else
                            CountdownLabel.TextColor3 = Color3.fromRGB(255, 215, 0)
                        end
                    else
                        if countdownConnection then
                            countdownConnection:Disconnect()
                        end
                        delfile(TRIAL_STORAGE_FILE)
                        task.wait(2)
                        if ScreenGui then ScreenGui:Destroy() end
                        if BlurEffect then BlurEffect:Destroy() end
                        main()
                    end
                end)
                return
            end
            
            -- Regular key validation
            local ok, err, isVIPKey = validateKey(key)
            if ok then
                if isVIPKey then
                    saveVIPData(key)
                    showStatus(StatusText, "✓ VIP Access Granted!\nLifetime Access", true)
                    task.wait(1.5)
                    
                    upgradeToVIP(WelcomeText, Subtitle, CountdownIcon, CountdownLabel, StatusBadge, avatarStroke, VIPBadge, badgeStroke, VIPIcon, false)
                    
                    if countdownConnection then
                        countdownConnection:Disconnect()
                    end
                    if vipCheckConnection then
                        task.cancel(vipCheckConnection)
                    end
                    
                    AuthContainer.Visible = false
                    MapContainer.Visible = false
                    
                    for _, child in ipairs(MapsFrame:GetChildren()) do
                        if child:IsA("TextButton") then
                            child:Destroy()
                        end
                    end
                    createMapButtons(MapsFrame, ALL_MAPS, ScreenGui, BlurEffect)
                    task.wait(0.1)
                    MapsScrollFrame.CanvasSize = UDim2.new(0, 0, 0, MapsFrame.UIGridLayout.AbsoluteContentSize.Y + 10)
                    MapContainer.Visible = true
                else
                    local newExpireTime = os.time() + KEY_DURATION
                    saveKeyData(key, newExpireTime)
                    showStatus(StatusText, "✓ Access granted!\nFree user - 1 map only", true)
                    task.wait(1.5)
                    
                    AuthContainer.Visible = false
                    MapContainer.Visible = true
                end
            else
                showStatus(StatusText, "✗ " .. (err or "Invalid key"), false)
            end
        end)
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

    -- Input focus
    KeyInput.Focused:Connect(function()
        local s = KeyInput:FindFirstChildOfClass("UIStroke")
        if s then TweenService:Create(s, TweenInfo.new(0.2), {Transparency = 0.3, Thickness = 3}):Play() end
    end)
    KeyInput.FocusLost:Connect(function()
        local s = KeyInput:FindFirstChildOfClass("UIStroke")
        if s then TweenService:Create(s, TweenInfo.new(0.2), {Transparency = 0.7, Thickness = 2}):Play() end
    end)
    
    -- Cleanup
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
print("✅ VIP Loader v11.0 - UPDATED | Device:", isMobile() and "Mobile" or "Desktop")
print("📁 Storage location: " .. STORAGE_FOLDER)
print("👑 VIP keys: Lifetime access (All maps)")
print("⏳ Trial VIP keys: 1 hour access (All maps)")
print("🆓 Free users: Limited to ARUNIKA map only")
print("🔄 Auto VIP upgrade check every 30 seconds")
