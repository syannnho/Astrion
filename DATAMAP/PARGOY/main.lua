
-- ============================================================
-- Guards (Auto Reload Friendly - Safe Version)
-- ============================================================
if _G.__AWM_FULL_LOADED and _G.__AWM_FULL_LOADED.Active then
    for _,v in pairs(game:GetService("CoreGui"):GetChildren()) do
        if v.Name == "AutoWalk Mount" then v:Destroy() end
    end
    _G.__AWM_NOTIFY = nil
    _G.__AWM_FULL_LOADED = nil
    task.wait(0.5)
end
_G.__AWM_FULL_LOADED = { Active = true }

-- ============================================================
-- Services & Vars
-- ============================================================
local Players            = game:GetService("Players")
local RunService         = game:GetService("RunService")
local TeleportService    = game:GetService("TeleportService")
local PathfindingService = game:GetService("PathfindingService")
local VirtualUser        = game:GetService("VirtualUser")
local player             = Players.LocalPlayer
local hrp                = nil

-- ============================================================
-- Route Links (hanya 1 map)
-- ============================================================
local ROUTE_LINKS = {
    ["YAHAYUK"] = "https://raw.githubusercontent.com/Bardenss/YAHAYUK/refs/heads/main/01.lua", -- Ganti dengan URL route Anda
}

-- ============================================================
-- Globals
-- ============================================================
local routes            = {}
local rawRoutes         = {}
local animConn          = nil
local isMoving          = false
local frameTime         = 1/30
local playbackRate      = 1
local isReplayRunning   = false
local isRunning         = false
local intervalFlip      = false

-- ============================================================
-- CP DETECTOR GLOBALS
-- ============================================================
local autoCPEnabled       = false
local cpKeyword           = "cp"
local cpDetectRadius      = 15
local cpDelayAfterDetect  = 25

local cachedCPs        = {}
local lastCPScan       = 0
local CP_SCAN_INTERVAL = 5

local triggeredCP       = {}
local completedCPs      = {}
local CP_RADIUS         = cpDetectRadius
local CP_COOLDOWN       = cpDelayAfterDetect
local lastReplayIndex   = 1
local lastReplayPos     = nil
local lastUsedKeyword   = nil
local cpHighlight       = nil
local cpBeamEnabled     = true
local awaitingCP        = false

-- Anti Idle & Anti Beton
local antiIdleActive    = true
local antiIdleConn
local antiBetonActive   = false
local antiBetonConn

-- ============================================================
-- HRP helpers
-- ============================================================
local function refreshHRP(char)
    if not char then
        char = player.Character or player.CharacterAdded:Wait()
    end
    hrp = char:WaitForChild("HumanoidRootPart")
end
player.CharacterAdded:Connect(refreshHRP)
if player.Character then refreshHRP(player.Character) end

local function stopMovement()  isMoving = false end
local function startMovement() isMoving = true  end

-- ============================================================
-- Movement driver
-- ============================================================
local function setupMovement(char)
    task.spawn(function()
        if not char then char = player.Character or player.CharacterAdded:Wait() end
        local humanoid = char:WaitForChild("Humanoid", 5)
        local root     = char:WaitForChild("HumanoidRootPart", 5)
        if not humanoid or not root then return end

        humanoid.Died:Connect(function()
            isReplayRunning = false
            stopMovement()
            isRunning = false
            if _G.__AWM_NOTIFY then _G.__AWM_NOTIFY("Replay", "Karakter mati, replay dihentikan.", 3) end
        end)

        if animConn then animConn:Disconnect() end
        local lastPos = root.Position
        local jumpCooldown = false

        animConn = RunService.RenderStepped:Connect(function()
            if not isMoving then return end
            if not hrp or not hrp.Parent or not hrp:IsDescendantOf(workspace) then
                if player.Character and player.Character:FindFirstChild("HumanoidRootPart") then
                    hrp = player.Character:FindFirstChild("HumanoidRootPart")
                    root = hrp
                else return end
            end
            if not humanoid or humanoid.Health <= 0 then return end

            local direction = root.Position - lastPos
            local dist = direction.Magnitude
            if dist > 0.01 then
                humanoid:Move(direction.Unit * math.clamp(dist * 5, 0, 1), false)
            else
                humanoid:Move(Vector3.zero, false)
            end

            local deltaY = root.Position.Y - lastPos.Y
            if deltaY > 0.9 and not jumpCooldown then
                humanoid.Jump = true
                jumpCooldown = true
                task.delay(0.4, function() jumpCooldown = false end)
            end
            lastPos = root.Position
        end)
    end)
end
player.CharacterAdded:Connect(setupMovement)
if player.Character then setupMovement(player.Character) end

-- ============================================================
-- Default Height Adjust
-- ============================================================
local DEFAULT_HEIGHT = 2.9
local function getCurrentHeight()
    local char = player.Character or player.CharacterAdded:Wait()
    local humanoid = char:WaitForChild("Humanoid")
    local head = char:FindFirstChild("Head")
    return humanoid.HipHeight + (head and head.Size.Y or 2)
end

local function adjustRoute(frames)
    local adjusted = {}
    local offsetY = getCurrentHeight() - DEFAULT_HEIGHT
    for _, cf in ipairs(frames) do
        local pos, rot = cf.Position, cf - cf.Position
        table.insert(adjusted, CFrame.new(Vector3.new(pos.X, pos.Y + offsetY, pos.Z)) * rot)
    end
    return adjusted
end

local function recomputeAdjustedRoutes()
    for i, pack in ipairs(routes) do
        local name = pack[1]
        local raw  = rawRoutes[i]
        routes[i]  = {name, adjustRoute(raw)}
    end
end

-- ============================================================
-- Remove Duplicate Frames
-- ============================================================
local function removeDuplicateFrames(frames, tolerance)
    tolerance = tolerance or 0.01
    if #frames < 2 then return frames end
    local newFrames = {frames[1]}
    for i = 2, #frames do
        local prev = frames[i-1]
        local curr = frames[i]
        local prevPos, currPos = prev.Position, curr.Position
        local prevRot, currRot = prev - prev.Position, curr - curr.Position

        local posDiff = (prevPos - currPos).Magnitude
        local rotDiff = (prevRot.Position - currRot.Position).Magnitude

        if posDiff > tolerance or rotDiff > tolerance then
            table.insert(newFrames, curr)
        end
    end
    return newFrames
end

-- ============================================================
-- Apply Interval Rotation
-- ============================================================
local function applyIntervalRotation(cf)
    if intervalFlip then
        local pos = cf.Position
        local rot = cf - pos
        local newRot = CFrame.Angles(0, math.pi, 0) * rot
        return CFrame.new(pos) * newRot
    else
        return cf
    end
end

-- ============================================================
-- Load Routes
-- ============================================================
for name, linkData in pairs(ROUTE_LINKS) do
    local links = typeof(linkData) == "table" and linkData or {linkData}
    for _, link in ipairs(links) do
        if link ~= "" then
            local ok, data = pcall(function()
                return loadstring(game:HttpGet(link))()
            end)
            if ok and typeof(data) == "table" and #data > 0 then
                local cleaned = removeDuplicateFrames(data, 0.01)
                table.insert(rawRoutes, cleaned)
                table.insert(routes, {name, {}})
            else
                warn("[AutoWalk] Gagal memuat route:", name, link)
            end
        end
    end
end
recomputeAdjustedRoutes()

-- ============================================================
-- Helpers
-- ============================================================
local function getNearestRoute()
    local nearestIdx, dist = 1, math.huge
    if hrp then
        local pos = hrp.Position
        for i, data in ipairs(routes) do
            for _, cf in ipairs(data[2]) do
                local d = (cf.Position - pos).Magnitude
                if d < dist then dist = d nearestIdx = i end
            end
        end
    end
    return nearestIdx
end

local function getNearestFrameIndex(frames)
    local startIdx, dist = 1, math.huge
    if hrp then
        local pos = hrp.Position
        for i, cf in ipairs(frames) do
            local d = (cf.Position - pos).Magnitude
            if d < dist then dist = d startIdx = i end
        end
    end
    if startIdx >= #frames then startIdx = math.max(1, #frames - 1) end
    return startIdx
end

-- ============================================================
-- Walk to Start Position (dari kode referensi)
-- ============================================================
local function walkToPosition(targetCF, threshold)
    threshold = threshold or 5
    if not hrp then return end
    
    local char = player.Character
    if not char then return end
    local humanoid = char:FindFirstChild("Humanoid")
    if not humanoid then return end
    
    local targetPos = targetCF.Position
    local startTime = tick()
    local timeout = 30
    
    while isRunning and (hrp.Position - targetPos).Magnitude > threshold do
        if tick() - startTime > timeout then
            warn("Walk timeout, teleporting instead")
            hrp.CFrame = targetCF
            break
        end
        
        humanoid:MoveTo(targetPos)
        task.wait(0.1)
    end
    
    humanoid:MoveTo(hrp.Position)
end

-- ============================================================
-- Pathfinding helper (untuk CP)
-- ============================================================
local function walkTo(targetPos)
    local humanoid = player.Character and player.Character:FindFirstChildOfClass("Humanoid")
    if not humanoid or not hrp then return end
    local path = PathfindingService:CreatePath({
        AgentRadius = 2, AgentHeight = 5,
        AgentCanJump = true, AgentCanClimb = true,
        WaypointSpacing = 4
    })
    path:ComputeAsync(hrp.Position, targetPos)
    for _, wp in ipairs(path:GetWaypoints()) do
        if not humanoid or humanoid.Health <= 0 then break end
        humanoid:MoveTo(wp.Position + Vector3.new(0, 0.5, 0))
        humanoid.MoveToFinished:Wait(2)
    end
end

-- ============================================================
-- CP Handler (Blocking)
-- ============================================================
local function handleCP(cp)
    if not cp or not hrp then return end
    awaitingCP = true
    isReplayRunning = false
    stopMovement()
    local targetPos = cp.Position + Vector3.new(0, 3, 0)
    walkTo(targetPos)

    local reached = false
    for _ = 1, 100 do
        if hrp and (hrp.Position - cp.Position).Magnitude <= 5 then reached = true break end
        task.wait(0.1)
    end

    if reached then
        completedCPs[cp] = true
        if _G.__AWM_NOTIFY then
            _G.__AWM_NOTIFY("CP Detector", string.format("CP '%s' disentuh, menunggu %ds...", cp.Name, cpDelayAfterDetect), 2)
        end
        task.wait(cpDelayAfterDetect)
    end

    if lastReplayPos then walkTo(lastReplayPos) end
    if _G.__AWM_NOTIFY then _G.__AWM_NOTIFY("CP Detector", "Kembali ke lintasan, lanjut replay...", 2) end
    task.wait(0.2)
    startMovement()
    isReplayRunning = true
    awaitingCP = false
end

-- ============================================================
-- CP Finder (cache + skip completed)
-- ============================================================
local function findNearestCP(radius, keyword)
    if not hrp then return nil end
    local now = tick()
    local kw = (keyword or cpKeyword):lower()
    if not kw or kw == "" then return nil end

    if tick() - lastCPScan > CP_SCAN_INTERVAL or kw ~= lastUsedKeyword then
        lastUsedKeyword = kw
        lastCPScan = tick()
        cachedCPs = {}
        local searchRoot = workspace:FindFirstChild("Checkpoints") or workspace
        for _, part in ipairs(searchRoot:GetDescendants()) do
            if part:IsA("BasePart") then
                local pname = part.Name:lower()
                if pname == kw or pname:match("^" .. kw .. "[%d_]*$") then
                    table.insert(cachedCPs, part)
                end
            end
        end
    end

    local nearest, nearestDist = nil, radius or CP_RADIUS
    local hrpPos, hrpLook = hrp.Position, hrp.CFrame.LookVector

    for _, part in ipairs(cachedCPs) do
        if part and part:IsDescendantOf(workspace) and not completedCPs[part] then
            local diff = (part.Position - hrpPos)
            local dist = diff.Magnitude
            if dist <= nearestDist and diff.Unit:Dot(hrpLook) > 0.25 then
                local lastTriggered = triggeredCP[part]
                if not lastTriggered or now - lastTriggered >= CP_COOLDOWN then
                    nearest = part
                    nearestDist = dist
                end
            end
        end
    end

    if cpBeamEnabled and nearest then
        if cpHighlight then cpHighlight:Destroy() cpHighlight = nil end
        local attachHRP = Instance.new("Attachment", hrp)
        local attachCP  = Instance.new("Attachment", nearest)
        local beam = Instance.new("Beam")
        beam.Color         = ColorSequence.new(Color3.fromRGB(255,220,0))
        beam.Width0        = 0.25
        beam.Width1        = 0.25
        beam.Attachment0   = attachHRP
        beam.Attachment1   = attachCP
        beam.LightEmission = 1
        beam.FaceCamera    = true
        beam.Texture       = "rbxassetid://446111271"
        beam.TextureSpeed  = 0.5
        beam.Transparency  = NumberSequence.new(0.1)
        beam.Parent        = hrp
        cpHighlight = beam
        task.delay(3, function()
            if cpHighlight then cpHighlight:Destroy() cpHighlight = nil end
            if attachHRP then attachHRP:Destroy() end
            if attachCP then attachCP:Destroy() end
        end)
    elseif not cpBeamEnabled and cpHighlight then
        cpHighlight:Destroy() cpHighlight = nil
    end

    return nearest
end

-- ============================================================
-- Lerp CF dengan Interval Flip
-- ============================================================
local function lerpCF(fromCF, toCF)
    fromCF = applyIntervalRotation(fromCF)
    toCF = applyIntervalRotation(toCF)
    
    local duration = frameTime / math.max(0.05, playbackRate)
    local startTime = os.clock()
    local t = 0
    while t < duration and isReplayRunning do
        RunService.Heartbeat:Wait()
        t = os.clock() - startTime
        local alpha = math.min(t / duration, 1)
        if hrp and hrp.Parent and hrp:IsDescendantOf(workspace) then
            hrp.CFrame = fromCF:Lerp(toCF, alpha)
        end
    end
end

-- ============================================================
-- Core Replay dengan Walk to Start & CP Detector
-- ============================================================
local function runRoute(startIdx)
    if #routes == 0 then return end
    if not hrp then refreshHRP() end
    isReplayRunning = true
    isRunning = true
    startMovement()
    completedCPs = {}

    local idx = getNearestRoute()
    local frames = routes[idx][2]
    if #frames < 2 then
        isReplayRunning = false
        isRunning = false
        stopMovement()
        return
    end

    local sIdx = startIdx or getNearestFrameIndex(frames)
    local startFrame = frames[sIdx]
    local distanceToStart = (hrp.Position - startFrame.Position).Magnitude
    
    -- Walk to Start Position (threshold 3 studs)
    if distanceToStart > 3 then
        if _G.__AWM_NOTIFY then
            _G.__AWM_NOTIFY("Walk to Start", "Berjalan ke posisi awal...", 2)
        end
        walkToPosition(startFrame, 3)
        task.wait(0.5)
    end

    for i = sIdx, #frames - 1 do
        if not isReplayRunning then break end
        lastReplayIndex = i
        lastReplayPos   = frames[i].Position

        -- CP Detector
        if autoCPEnabled then
            CP_RADIUS   = cpDetectRadius
            CP_COOLDOWN = cpDelayAfterDetect
            local cp = findNearestCP(CP_RADIUS, cpKeyword)
            if cp then
                triggeredCP[cp] = tick()
                if _G.__AWM_NOTIFY then
                    _G.__AWM_NOTIFY("CP Detector","CP terdekat terdeteksi. Menuju CP...",2)
                end
                handleCP(cp)
            end
        end

        lerpCF(frames[i], frames[i+1])
    end

    isReplayRunning = false
    isRunning = false
    stopMovement()
    if _G.__AWM_NOTIFY then
        _G.__AWM_NOTIFY("Replay","Replay selesai.",2)
    end
end

local function stopRoute()
    isReplayRunning = false
    isRunning = false
    stopMovement()
    if _G.__AWM_NOTIFY then
        _G.__AWM_NOTIFY("Replay","Replay dihentikan secara manual.",2)
    end
end

-- ============================================================
-- Anti Idle
-- ============================================================
local function enableAntiIdle()
    if antiIdleConn then antiIdleConn:Disconnect() end
    antiIdleConn = player.Idled:Connect(function()
        if antiIdleActive then
            VirtualUser:CaptureController()
            VirtualUser:ClickButton2(Vector2.new())
            if _G.__AWM_NOTIFY then
                _G.__AWM_NOTIFY("Anti Idle", "Klik otomatis dilakukan.", 2)
            end
        end
    end)
end
enableAntiIdle()

-- ============================================================
-- Anti Beton Ultra-Smooth
-- ============================================================
local function enableAntiBeton()
    if antiBetonConn then antiBetonConn:Disconnect() end

    antiBetonConn = RunService.Stepped:Connect(function(_, dt)
        local char = player.Character
        if not char then return end
        local hrp = char:FindFirstChild("HumanoidRootPart")
        local humanoid = char:FindFirstChild("Humanoid")
        if not hrp or not humanoid then return end

        if antiBetonActive and humanoid.FloorMaterial == Enum.Material.Air then
            local targetY = -50
            local currentY = hrp.Velocity.Y
            local newY = currentY + (targetY - currentY) * math.clamp(dt * 2.5, 0, 1)
            hrp.Velocity = Vector3.new(hrp.Velocity.X, newY, hrp.Velocity.Z)
        end
    end)
end

local function disableAntiBeton()
    if antiBetonConn then
        antiBetonConn:Disconnect()
        antiBetonConn = nil
    end
end

-- ============================================================
-- WindUI
-- ============================================================
local WindUI = loadstring(game:HttpGet("https://github.com/Footagesus/WindUI/releases/latest/download/main.lua"))()
local avatarUrl = string.format("https://www.roblox.com/headshot-thumbnail/image?userId=%s&width=420&height=420&format=png", player.UserId)

local Window = WindUI:CreateWindow({
    Title = "AutoWalk Mount",
    Icon = "lucide:mountain-snow",
    Author = "You",
    Folder = "AutoWalkMount",
    Size = UDim2.fromOffset(720, 560),
    Theme = "Dark",
    SideBarWidth = 200,
    Watermark = "AutoWalk",
    User = { Enabled = true, Anonymous = false, Image = avatarUrl, Username = player.DisplayName }
})

local function notify(title, content, duration)
    pcall(function()
        WindUI:Notify({ Title = title, Content = content or "", Duration = duration or 3, Icon = "bell" })
    end)
end
_G.__AWM_NOTIFY = notify

-- ============================================================
-- Launcher Tab
-- ============================================================
local Launcher = Window:Tab({ Title = "Launcher", Icon = "lucide:rocket", Default = true })
Launcher:Section({ Title = "Mulai GUI" })
local __MAIN_BUILT = false

Launcher:Button({
    Title = "▶ Run GUI (load semua fitur)",
    Icon  = "lucide:play-circle",
    Desc  = "Klik untuk memuat tab Main, Automation, Tools, Tampilan",
    Callback = function()
        if __MAIN_BUILT then
            notify("AutoWalk", "GUI sudah dimuat.", 2); return
        end
        __MAIN_BUILT = true

        -- ========================
        -- TAB: Main
        -- ========================
        local MainTab = Window:Tab({ Title = "Main", Icon = "geist:shareplay" })
        MainTab:Section({ Title = "Kontrol Replay" })

        MainTab:Button({
            Title = "▶ START (Walk to Start)",
            Icon  = "craft:back-to-start-stroke",
            Desc  = "Mulai dari posisi terdekat dengan walk to start",
            Callback = function()
                if isRunning then notify("Replay","Replay sudah berjalan",2); return end
                notify("Replay","Mulai dengan Walk to Start",2)
                task.spawn(function() runRoute() end)
            end
        })

        MainTab:Button({
            Title = "■ STOP",
            Icon  = "geist:stop-circle",
            Desc  = "Hentikan replay sekarang",
            Callback = function()
                if isRunning or isReplayRunning then
                    stopRoute()
                else
                    notify("Replay","Tidak ada replay berjalan",2)
                end
            end
        })

        local speeds = {}
        for v=0.25,3,0.25 do table.insert(speeds, string.format("%.2fx", v)) end
        MainTab:Dropdown({
            Title = "⚡ Playback Speed",
            Icon = "lucide:zap",
            Values = speeds, Value = "1.00x",
            Callback = function(option)
                local num = tonumber(option:match("([%d%.]+)"))
                if num then playbackRate = num notify("Playback Speed", string.format("%.2fx", num), 2) end
            end
        })

        MainTab:Toggle({
            Title = "Interval Flip",
            Icon = "lucide:refresh-ccw",
            Desc = "ON → Hadap belakang tiap frame",
            Value = false,
            Callback = function(state)
                intervalFlip = state
                notify("Interval Flip", state and "✅ Aktif" or "❌ Nonaktif", 2)
            end
        })

        MainTab:Toggle({
            Title = "Anti Beton Ultra-Smooth",
            Icon = "lucide:shield",
            Desc = "Mencegah jatuh secara kaku saat melayang",
            Value = false,
            Callback = function(state)
                antiBetonActive = state
                if state then
                    enableAntiBeton()
                    notify("Anti Beton", "✅ Aktif (Ultra-Smooth)", 2)
                else
                    disableAntiBeton()
                    notify("Anti Beton", "❌ Nonaktif", 2)
                end
            end
        })

        -- ========================
        -- TAB: Automation (CP Detector)
        -- ========================
        local AutomationTab = Window:Tab({ Title = "Automation", Icon = "lucide:refresh-cw" })
        AutomationTab:Section({ Title = "CP Detector" })

        AutomationTab:Toggle({
            Title = "🔎 Auto Detect CP During Route",
            Icon  = "lucide:map-pin",
            Value = false,
            Desc  = "Pause replay saat mendeteksi BasePart sesuai keyword",
            Callback = function(state) 
                autoCPEnabled = state 
                notify("CP Detector", state and "Aktif" or "Nonaktif", 2) 
            end
        })

        AutomationTab:Toggle({
            Title = "🔦 CP Beam Visual",
            Icon  = "lucide:lightbulb",
            Value = cpBeamEnabled,
            Desc  = "Tampilkan garis arah ke CP terdekat",
            Callback = function(state)
                cpBeamEnabled = state
                notify("CP Beam", state and "Aktif" or "Nonaktif", 2)
                if not state and cpHighlight then cpHighlight:Destroy() cpHighlight = nil end
            end
        })

        AutomationTab:Slider({
            Title = "⏲️ Delay setelah CP (detik)",
            Icon  = "lucide:clock",
            Value = { Min=1, Max=60, Default=cpDelayAfterDetect },
            Step  = 1, Suffix = "s",
            Callback = function(val) 
                cpDelayAfterDetect = tonumber(val) or cpDelayAfterDetect 
                notify("CP Detector","Delay: "..tostring(cpDelayAfterDetect).." dtk",2) 
            end
        })

        AutomationTab:Slider({
            Title = "📏 Jarak Deteksi CP (studs)",
            Icon  = "lucide:ruler",
            Value = { Min=5, Max=100, Default=cpDetectRadius },
            Step  = 1, Suffix = "studs",
            Callback = function(val) 
                cpDetectRadius = tonumber(val) or cpDetectRadius 
                notify("CP Detector","Radius: "..tostring(cpDetectRadius).." studs",2) 
            end
        })

        AutomationTab:Input({
            Title = "🧩 Keyword BasePart CP",
            Placeholder = "mis. cp / 14 / pad",
            Default = cpKeyword,
            Callback = function(text)
                if text and text ~= "" then
                    cpKeyword = text
                    lastUsedKeyword = nil
                    notify("CP Detector","Keyword diubah ke: "..text,2)
                else
                    notify("CP Detector","Keyword kosong, tetap: "..cpKeyword,2)
                end
            end
        })

        -- ========================
        -- TAB: Tools
        -- ========================
        local ToolsTab = Window:Tab({ Title = "Tools", Icon = "geist:settings-sliders" })
        ToolsTab:Section({ Title = "Utility & Player Tools" })

        ToolsTab:Button({
            Title = "PRIVATE SERVER",
            Icon  = "lucide:layers-2",
            Desc  = "Pindah ke private server",
            Callback = function()
                local ok = pcall(function()
                    loadstring(game:HttpGet("https://raw.githubusercontent.com/Bardenss/PS/refs/heads/main/ps"))()
                end)
                if not ok then notify("Private Server","Gagal memuat.",3) end
            end
        })

        ToolsTab:Slider({
            Title = "WalkSpeed", Icon = "lucide:zap",
            Value = { Min=10, Max=500, Default=16},
            Step=1, Suffix="Speed",
            Callback = function(val) 
                local c=player.Character 
                if c and c:FindFirstChild("Humanoid") then 
                    c.Humanoid.WalkSpeed = val 
                end 
            end
        })

        ToolsTab:Slider({
            Title = "Jump Height", Icon="lucide:zap",
            Value = { Min=10, Max=500, Default=50},
            Step=1, Suffix="Height",
            Callback=function(val) 
                local c=player.Character 
                if c and c:FindFirstChild("Humanoid") then 
                    c.Humanoid.JumpPower = val 
                end 
            end
        })

        ToolsTab:Button({
            Title="Respawn Player", Icon="lucide:user-minus",
            Desc="Respawn karakter saat ini",
            Callback=function() 
                local c=player.Character 
                if c then c:BreakJoints() end 
            end
        })

        ToolsTab:Button({
            Title="Speed Coil", Icon="lucide:zap", Desc="Tambah Speed Coil",
            Callback=function()
                local speedValue = 23
                local function giveCoil(char)
                    local backpack = player:WaitForChild("Backpack")
                    if backpack:FindFirstChild("Speed Coil") or char:FindFirstChild("Speed Coil") then return end
                    local tool = Instance.new("Tool")
                    tool.Name = "Speed Coil"; tool.RequiresHandle = false; tool.Parent = backpack
                    tool.Equipped:Connect(function()
                        local h = char:FindFirstChildOfClass("Humanoid")
                        if h then h.WalkSpeed = speedValue end
                    end)
                    tool.Unequipped:Connect(function()
                        local h = char:FindFirstChildOfClass("Humanoid")
                        if h then h.WalkSpeed = 16 end
                    end)
                end
                if player.Character then giveCoil(player.Character) end
                player.CharacterAdded:Connect(function(char) task.wait(1) giveCoil(char) end)
            end
        })

        ToolsTab:Button({
            Title="TP Tool", Icon="lucide:chevrons-up-down", Desc="Teleport pakai tool",
            Callback=function()
                local mouse = player:GetMouse()
                local tool = Instance.new("Tool"); tool.RequiresHandle=false; tool.Name="Teleport"; tool.Parent = player.Backpack
                tool.Activated:Connect(function()
                    if mouse.Hit then
                        local c=player.Character
                        if c and c:FindFirstChild("HumanoidRootPart") then
                            ```lua
                            c.HumanoidRootPart.CFrame = CFrame.new(mouse.Hit.Position + Vector3.new(0,3,0))
                        end
                    end
                end)
            end
        })

        ToolsTab:Button({
            Title="Gling GUI", Icon="lucide:layers-2", Desc="Load Gling GUI",
            Callback=function()
                local ok = pcall(function()
                    loadstring(game:HttpGet("https://rawscripts.net/raw/Universal-Script-Fling-Gui-Op-47914"))()
                end)
                if not ok then notify("Gling GUI","Gagal memuat.",3) end
            end
        })

        ToolsTab:Button({
            Title="Hop Server", Icon="lucide:refresh-ccw", Desc="Pindah server lain",
            Callback=function()
                local ok, err = pcall(function() TeleportService:Teleport(game.PlaceId, player) end)
                if not ok then notify("Hop Server","Gagal: "..tostring(err),3) end
            end
        })

        ToolsTab:Button({
            Title="Rejoin", Icon="lucide:rotate-cw", Desc="Masuk ulang server ini",
            Callback=function()
                local ok, err = pcall(function() TeleportService:TeleportToPlaceInstance(game.PlaceId, game.JobId, player) end)
                if not ok then notify("Rejoin","Gagal: "..tostring(err),3) end
            end
        })

        ToolsTab:Button({
            Title="Infinite Yield", Icon="lucide:terminal", Desc="Load Infinite Yield Admin",
            Callback=function() loadstring(game:HttpGet("https://raw.githubusercontent.com/Xane123/InfiniteFun_IY/master/source"))() end
        })

        ToolsTab:Input({
            Title="Atur ketinggian Avatar", Placeholder="mis. 2.9", Default=tostring(DEFAULT_HEIGHT),
            Callback=function(text)
                local num = tonumber(text)
                if num then 
                    DEFAULT_HEIGHT = num 
                    recomputeAdjustedRoutes() 
                    notify("Default Height","Diatur ke "..tostring(num).." (route disesuaikan ulang)",2)
                else 
                    notify("Default Height","Input tidak valid!",2) 
                end
            end
        })

        ToolsTab:Button({
            Title="📏 Cek Tinggi Avatar", Icon="lucide:ruler", Desc="Tampilkan tinggi avatar",
            Callback=function()
                local ok, err = pcall(function() 
                    loadstring(game:HttpGet("https://pastebin.com/raw/fD6Hg0Eq"))() 
                end)
                if ok then 
                    notify("Avatar Height","Script tinggi avatar berjalan!",3) 
                else 
                    notify("Avatar Height","Gagal: "..tostring(err),4) 
                end
            end
        })

        -- ========================
        -- TAB: Tampilan
        -- ========================
        local TampilanTab = Window:Tab({ Title = "Tampilan", Icon = "lucide:app-window" })
        TampilanTab:Paragraph({ Title = "Tema & Jam" })
        
        local themes = {}
        for t,_ in pairs(WindUI:GetThemes()) do table.insert(themes, t) end
        table.sort(themes)
        
        local canchangetheme = true
        local canchangedropdown = true
        
        local themeDropdown = TampilanTab:Dropdown({
            Title = "Pilih tema",
            Values = themes,
            SearchBarEnabled = true,
            Value = "Dark",
            Callback = function(theme)
                canchangedropdown = false
                WindUI:SetTheme(theme)
                notify("Tema disesuaikan", theme, 2)
                canchangedropdown = true
            end
        })

        local transparencySlider = TampilanTab:Slider({
            Title = "Transparasi",
            Value = { 
                Min = 0,
                Max = 1,
                Default = 0.2,
            },
            Step = 0.1,
            Callback = function(value)
                WindUI.TransparencyValue = tonumber(value)
                Window:ToggleTransparency(tonumber(value) > 0)
            end
        })

        local ThemeToggle = TampilanTab:Toggle({
            Title = "Enable Dark Mode",
            Desc = "Use dark color scheme",
            Value = true,
            Callback = function(state)
                if canchangetheme then
                    WindUI:SetTheme(state and "Dark" or "Light")
                end
                if canchangedropdown then
                    themeDropdown:Select(state and "Dark" or "Light")
                end
            end
        })

        WindUI:OnThemeChange(function(theme)
            canchangetheme = false
            ThemeToggle:Set(theme == "Dark")
            canchangetheme = true
        end)

        TampilanTab:Button({
            Title = "Create New Theme",
            Icon = "plus",
            Callback = function()
                Window:Dialog({
                    Title = "Create Theme",
                    Content = "This feature is coming soon!",
                    Buttons = {
                        {
                            Title = "OK",
                            Variant = "Primary"
                        }
                    }
                })
            end
        })

        local TimeTag = Window:Tag({ Title = "--:--:--", Icon = "lucide:timer" })
        task.spawn(function()
            while true do
                local now = os.date("*t")
                TimeTag:SetTitle(string.format("%02d:%02d:%02d", now.hour, now.min, now.sec))
                task.wait(0.25)
            end
        end)

        notify("AutoWalk Mount", "GUI lengkap dimuat! 🎉", 3)
        MainTab:Show()
    end
})

-- ============================================================
-- Finalize Window
-- ============================================================
Window:EditOpenButton({
    Title = "AutoWalk Mount",
    Icon  = "geist:logo-nuxt",
    CornerRadius = UDim.new(0,16),
    StrokeThickness = 2,
    Enabled = true
})

Window:Tag({ 
    Title = "Dummysih", 
    Color = Color3.fromHex("#30ff6a"), 
    Radius = 10 
})

if _G.__AWM_FULL_LOADED then 
    _G.__AWM_FULL_LOADED.Window = Window 
end

notify("AutoWalk Mount", "Launcher siap. Buka tab Launcher → klik 'Run GUI'.", 5)

pcall(function() 
    Window:Show()
    Launcher:Show()
end)
