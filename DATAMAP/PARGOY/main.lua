-- ============================================================
-- CORE (fungsi asli + log/notify)
-- ============================================================
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local player = Players.LocalPlayer
local hrp = nil
local Packs = {
    lucide = loadstring(game:HttpGetAsync("https://raw.githubusercontent.com/Footagesus/Icons/refs/heads/main/lucide/dist/Icons.lua"))(),
    craft  = loadstring(game:HttpGetAsync("https://raw.githubusercontent.com/Footagesus/Icons/refs/heads/main/craft/dist/Icons.lua"))(),
    geist  = loadstring(game:HttpGetAsync("https://raw.githubusercontent.com/Footagesus/Icons/refs/heads/main/geist/dist/Icons.lua"))(),
}

local function refreshHRP(char)
    if not char then
        char = player.Character or player.CharacterAdded:Wait()
    end
    hrp = char:WaitForChild("HumanoidRootPart")
end
if player.Character then refreshHRP(player.Character) end
player.CharacterAdded:Connect(refreshHRP)

local frameTime = 1/30
local playbackRate = 1.0
local isRunning = false
local routes = {}

-- ============================================================
-- ROUTE CONFIG
-- ============================================================
local DEFAULT_HEIGHT = 4.947289

local function getCurrentHeight()
    local char = player.Character or player.CharacterAdded:Wait()
    local humanoid = char:WaitForChild("Humanoid")
    return humanoid.HipHeight + (char:FindFirstChild("Head") and char.Head.Size.Y or 2)
end

local function adjustRoute(frames)
    local adjusted = {}
    local currentHeight = getCurrentHeight()
    local offsetY = currentHeight - DEFAULT_HEIGHT
    for _, cf in ipairs(frames) do
        local pos, rot = cf.Position, cf - cf.Position
        local newPos = Vector3.new(pos.X, pos.Y + offsetY, pos.Z)
        table.insert(adjusted, CFrame.new(newPos) * rot)
    end
    return adjusted
end

local intervalFlip = false

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

local function loadRoute(url)
    local ok, result = pcall(function()
        return loadstring(game:HttpGet(url))()
    end)
    if ok and type(result) == "table" then
        local cleaned = removeDuplicateFrames(result, 0.01)
        return adjustRoute(cleaned)
    else
        warn("Gagal load route dari: "..url)
        return {}
    end
end

routes = {
    {"BASE → CP8", loadRoute("https://raw.githubusercontent.com/Bardenss/YAHAYUK/refs/heads/main/cadangan.lua")},
}

-- ============================================================
-- Fungsi bantu & core logic
-- ============================================================
local VirtualUser = game:GetService("VirtualUser")
local antiIdleActive = true
local antiIdleConn

local function respawnPlayer()
    player.Character:BreakJoints()
end

local function getNearestRoute()
    local nearestIdx, dist = 1, math.huge
    if hrp then
        local pos = hrp.Position
        for i,data in ipairs(routes) do
            for _,cf in ipairs(data[2]) do
                local d = (cf.Position - pos).Magnitude
                if d < dist then
                    dist = d
                    nearestIdx = i
                end
            end
        end
    end
    return nearestIdx
end

local function getNearestFrameIndex(frames)
    local startIdx, dist = 1, math.huge
    if hrp then
        local pos = hrp.Position
        for i,cf in ipairs(frames) do
            local d = (cf.Position - pos).Magnitude
            if d < dist then
                dist = d
                startIdx = i
            end
        end
    end
    if startIdx >= #frames then
        startIdx = math.max(1, #frames - 1)
    end
    return startIdx
end

local function lerpCF(fromCF, toCF)
    fromCF = applyIntervalRotation(fromCF)
    toCF = applyIntervalRotation(toCF)

    local duration = frameTime / math.max(0.05, playbackRate)
    local t = 0
    while t < duration do
        if not isRunning then break end
        local dt = task.wait()
        t += dt
        local alpha = math.min(t / duration, 1)
        if hrp and hrp.Parent and hrp:IsDescendantOf(workspace) then
            hrp.CFrame = fromCF:Lerp(toCF, alpha)
        end
    end
end

local notify = function() end
local function logAndNotify(msg, val)
    local text = val and (msg .. " " .. tostring(val)) or msg
    print(text)
    notify(msg, tostring(val or ""), 3)
end

-- === VAR BYPASS ===
local bypassActive = false
local bypassConn

local function setupBypass(char)
    local humanoid = char:WaitForChild("Humanoid")
    local hrp = char:WaitForChild("HumanoidRootPart")
    local lastPos = hrp.Position

    if bypassConn then bypassConn:Disconnect() end
    bypassConn = RunService.RenderStepped:Connect(function()
        if not hrp or not hrp.Parent then return end
        if bypassActive then
            local direction = (hrp.Position - lastPos)
            local dist = direction.Magnitude

            local yDiff = hrp.Position.Y - lastPos.Y
            if yDiff > 0.5 then
                humanoid:ChangeState(Enum.HumanoidStateType.Jumping)
            elseif yDiff < -1 then
                humanoid:ChangeState(Enum.HumanoidStateType.Freefall)
            end

            if dist > 0.01 then
                local moveVector = direction.Unit * math.clamp(dist * 5, 0, 1)
                humanoid:Move(moveVector, false)
            else
                humanoid:Move(Vector3.zero, false)
            end
        end
        lastPos = hrp.Position
    end)
end

player.CharacterAdded:Connect(setupBypass)
if player.Character then setupBypass(player.Character) end

local function setBypass(state)
    bypassActive = state
    notify("Bypass Animasi", state and "✅ Aktif" or "❌ Nonaktif", 2)
end

-- ============================================================
-- CP DETECTOR GLOBALS
-- ============================================================
local autoCPEnabled = false
local cpKeyword = "cp"
local cpDetectRadius = 15
local cpDelayAfterDetect = 25
local cachedCPs = {}
local lastCPScan = 0
local CP_SCAN_INTERVAL = 5
local triggeredCP = {}
local completedCPs = {}
local CP_RADIUS = cpDetectRadius
local CP_COOLDOWN = cpDelayAfterDetect
local lastReplayIndex = 1
local lastReplayPos = nil
local lastUsedKeyword = nil
local cpHighlight = nil
local cpBeamEnabled = true
local awaitingCP = false

-- ============================================================
-- Pathfinding helper
-- ============================================================
local PathfindingService = game:GetService("PathfindingService")

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
    local targetPos = cp.Position + Vector3.new(0, 3, 0)
    walkTo(targetPos)

    local reached = false
    for _ = 1, 100 do
        if hrp and (hrp.Position - cp.Position).Magnitude <= 5 then reached = true break end
        task.wait(0.1)
    end

    if reached then
        completedCPs[cp] = true
        notify("CP Detector", string.format("CP '%s' disentuh, menunggu %ds...", cp.Name, cpDelayAfterDetect), 2)
        task.wait(cpDelayAfterDetect)
    end

    if lastReplayPos then walkTo(lastReplayPos) end
    notify("CP Detector", "Kembali ke lintasan, lanjut replay...", 2)
    task.wait(0.2)
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
-- Walk to Start Position Function
-- ============================================================
local function walkToStartPosition(targetPos)
    local character = player.Character
    if not character then return false end
    
    local humanoid = character:FindFirstChild("Humanoid")
    local hrp = character:FindFirstChild("HumanoidRootPart")
    if not humanoid or not hrp then return false end
    
    local currentPos = hrp.Position
    local distance = (targetPos - currentPos).Magnitude
    
    if distance > 5 then
        notify("Auto Walk", "🚶 Berjalan ke titik awal replay...", 2)
        
        humanoid:MoveTo(targetPos)
        
        local startTime = tick()
        local reachedPosition = false
        
        while (tick() - startTime) < 30 do
            if not character or not hrp or not humanoid then break end
            
            local currentDist = (hrp.Position - targetPos).Magnitude
            if currentDist < 5 then
                reachedPosition = true
                notify("Auto Walk", "✅ Sampai di posisi awal!", 1)
                break
            end
            
            task.wait(0.1)
        end
        
        if not reachedPosition then
            notify("Auto Walk", "⚠️ Timeout mencapai titik awal, tetap melanjutkan...", 3)
            return false
        end
        
        return true
    end
    
    return true
end

-- Jalankan 1 route dari checkpoint terdekat
local function runRouteOnce()
    if #routes == 0 then return end
    if not hrp then refreshHRP() end

    setBypass(true)
    isRunning = true
    completedCPs = {}

    local idx = getNearestRoute()
    logAndNotify("Mulai dari cp : ", routes[idx][1])
    local frames = routes[idx][2]
    if #frames < 2 then 
        isRunning = false
        setBypass(false)
        return 
    end

    -- Walk to start position
    local startFrame = frames[1]
    if startFrame then
        walkToStartPosition(startFrame.Position)
    end

    local startIdx = getNearestFrameIndex(frames)
    for i = startIdx, #frames - 1 do
        if not isRunning then break end
        lastReplayIndex = i
        lastReplayPos = frames[i].Position

        -- Auto CP Detection
        if autoCPEnabled then
            CP_RADIUS = cpDetectRadius
            CP_COOLDOWN = cpDelayAfterDetect
            local cp = findNearestCP(CP_RADIUS, cpKeyword)
            if cp then
                triggeredCP[cp] = tick()
                notify("CP Detector", "CP terdekat terdeteksi. Menuju CP...", 2)
                handleCP(cp)
            end
        end

        lerpCF(frames[i], frames[i+1])
    end

    isRunning = false
    setBypass(false)
end

local function runAllRoutes()
    if #routes == 0 then return end
    isRunning = true

    while isRunning do
        if not hrp then refreshHRP() end
        setBypass(true)
        completedCPs = {}

        local idx = getNearestRoute()
        logAndNotify("Sesuaikan dari cp : ", routes[idx][1])

        for r = idx, #routes do
            if not isRunning then break end
            local frames = routes[r][2]
            if #frames < 2 then continue end
            
            -- Walk to start position for each route
            local startFrame = frames[1]
            if startFrame then
                walkToStartPosition(startFrame.Position)
            end
            
            local startIdx = getNearestFrameIndex(frames)
            for i = startIdx, #frames - 1 do
                if not isRunning then break end
                lastReplayIndex = i
                lastReplayPos = frames[i].Position

                -- Auto CP Detection
                if autoCPEnabled then
                    CP_RADIUS = cpDetectRadius
                    CP_COOLDOWN = cpDelayAfterDetect
                    local cp = findNearestCP(CP_RADIUS, cpKeyword)
                    if cp then
                        triggeredCP[cp] = tick()
                        notify("CP Detector", "CP terdekat terdeteksi. Menuju CP...", 2)
                        handleCP(cp)
                    end
                end

                lerpCF(frames[i], frames[i+1])
            end
        end

        setBypass(false)

        if not isRunning then break end
        respawnPlayer()
        task.wait(5)
    end
end

local function stopRoute()
    if isRunning then
        logAndNotify("Stop route", "Semua route dihentikan!")
    end

    isRunning = false

    if bypassActive then
        bypassActive = false
        notify("Bypass Animasi", "❌ Nonaktif", 2)
    end
end

local function runSpecificRoute(routeIdx)
    if not routes[routeIdx] then return end
    if not hrp then refreshHRP() end
    isRunning = true
    completedCPs = {}
    local frames = routes[routeIdx][2]
    if #frames < 2 then 
        isRunning = false 
        return 
    end
    logAndNotify("Memulai track : ", routes[routeIdx][1])
    setBypass(true)
    
    -- Walk to start position
    local startFrame = frames[1]
    if startFrame then
        walkToStartPosition(startFrame.Position)
    end
    
    local startIdx = getNearestFrameIndex(frames)
    for i = startIdx, #frames - 1 do
        if not isRunning then break end
        lastReplayIndex = i
        lastReplayPos = frames[i].Position

        -- Auto CP Detection
        if autoCPEnabled then
            CP_RADIUS = cpDetectRadius
            CP_COOLDOWN = cpDelayAfterDetect
            local cp = findNearestCP(CP_RADIUS, cpKeyword)
            if cp then
                triggeredCP[cp] = tick()
                notify("CP Detector", "CP terdekat terdeteksi. Menuju CP...", 2)
                handleCP(cp)
            end
        end

        lerpCF(frames[i], frames[i+1])
    end
    isRunning = false
    setBypass(false)
end

-- ===============================
-- Anti Beton Ultra-Smooth
-- ===============================
local antiBetonActive = false
local antiBetonConn

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
-- UI: WindUI
-- ============================================================
local WindUI = loadstring(game:HttpGet("https://github.com/Footagesus/WindUI/releases/latest/download/main.lua"))()

local Window = WindUI:CreateWindow({
    Title = "BANTAI GUNUNG",
    Icon = "lucide:mountain-snow",
    Author = "bardenss",
    Folder = "BRDNHub",
    Size = UDim2.fromOffset(580, 460),
    Theme = "Midnight",
    Resizable = true,
    SideBarWidth = 200,
    Watermark = "bardenss",
    User = {
        Enabled = true,
        Anonymous = false,
        Callback = function()
            WindUI:Notify({
                Title = "User Profile",
                Content = "User profile clicked!",
                Duration = 3
            })
        end
    }
})

notify = function(title, content, duration)
    pcall(function()
        WindUI:Notify({
            Title = title,
            Content = content or "",
            Duration = duration or 3,
            Icon = "bell",
        })
    end)
end

local function enableAntiIdle()
    if antiIdleConn then antiIdleConn:Disconnect() end
    local player = Players.LocalPlayer
    antiIdleConn = player.Idled:Connect(function()
        if antiIdleActive then
            VirtualUser:CaptureController()
            VirtualUser:ClickButton2(Vector2.new())
            notify("Anti Idle", "Klik otomatis dilakukan.", 2)
        end
    end)
end

enableAntiIdle()

local MainTab = Window:Tab({
    Title = "Main",
    Icon = "geist:shareplay",
    Default = true
})
local AutomationTab = Window:Tab({
    Title = "Automation",
    Icon = "lucide:refresh-cw"
})
local SettingsTab = Window:Tab({
    Title = "Tools",
    Icon = "geist:settings-sliders",
})
local tampTab = Window:Tab({
    Title = "Tampilan",
    Icon = "lucide:app-window",
})
local InfoTab = Window:Tab({
    Title = "Info",
    Icon = "lucide:info",
})

-- ============================================================
-- Main Tab
-- ============================================================
local speeds = {}
for v = 0.25, 3, 0.25 do
    table.insert(speeds, string.format("%.2fx", v))
end
MainTab:Dropdown({
    Title = "Speed",
    Icon = "lucide:zap",
    Values = speeds,
    Value = "1.00x",
    Callback = function(option)
        local num = tonumber(option:match("([%d%.]+)"))
        if num then
            playbackRate = num
            logAndNotify("Speed : ", string.format("%.2fx", playbackRate))
        else
            notify("Playback Speed", "Gagal membaca opsi speed!", 3)
        end
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
            WindUI:Notify({
                Title = "Anti Beton",
                Content = "✅ Aktif (Ultra-Smooth)",
                Duration = 2
            })
        else
            disableAntiBeton()
            WindUI:Notify({
                Title = "Anti Beton",
                Content = "❌ Nonaktif",
                Duration = 2
            })
        end
    end
})

MainTab:Button({
    Title = "START",
    Icon = "craft:back-to-start-stroke",
    Desc = "Mulai dari checkpoint terdekat",
    Callback = function() pcall(runRouteOnce) end
})
MainTab:Button({
    Title = "AWAL KE AKHIR",
    Desc = "Jalankan semua checkpoint",
    Icon = "craft:back-to-start-stroke",
    Callback = function() pcall(runAllRoutes) end
})
MainTab:Button({
    Title = "Stop track",
    Icon = "geist:stop-circle",
    Desc = "Hentikan route",
    Callback = function() pcall(stopRoute) end
})
for idx, data in ipairs(routes) do
    MainTab:Button({
        Title = "TRACK "..data[1],
        Icon = "lucide:train-track",
        Desc = "Jalankan dari "..data[1],
        Callback = function()
            pcall(function() runSpecificRoute(idx) end)
        end
    })
end

-- ============================================================
-- AUTOMATION TAB - CP DETECTOR (FIXED)
-- ============================================================
local AutomationSection = AutomationTab:Section({ Title = "CP Detector Settings", Icon = "lucide:radar" })

AutomationTab:Toggle({
    Title = "🔎 Auto Detect CP During Route",
    Icon = "lucide:map-pin",
    Value = false,
    Desc = "Pause replay saat mendeteksi BasePart sesuai keyword",
    Callback = function(state)
        autoCPEnabled = state
        notify("CP Detector", state and "✅ Aktif" or "❌ Nonaktif", 2)
    end
})

AutomationTab:Toggle({
    Title = "🔦 CP Beam Visual",
    Icon = "lucide:lightbulb",
    Value = cpBeamEnabled,
    Desc = "Tampilkan garis arah ke CP terdekat",
    Callback = function(state)
        cpBeamEnabled = state
        notify("CP Beam", state and "✅ Aktif" or "❌ Nonaktif", 2)
        if not state and cpHighlight then
            cpHighlight:Destroy()
            cpHighlight = nil
        end
    end
})

AutomationTab:Slider({
    Title = "⏲️ Delay setelah CP (detik)",
    Icon = "lucide:clock",
    Value = { Min = 1, Max = 60, Default = cpDelayAfterDetect },
    Step = 1,
    Suffix = "s",
    Callback = function(val)
        cpDelayAfterDetect = tonumber(val) or cpDelayAfterDetect
        notify("CP Detector", "Delay: " .. tostring(cpDelayAfterDetect) .. " dtk", 2)
    end
})

AutomationTab:Slider({
    Title = "📏 Jarak Deteksi CP (studs)",
    Icon = "lucide:ruler",
    Value = { Min = 5, Max = 100, Default = cpDetectRadius },
    Step = 1,
    Suffix = "studs",
    Callback = function(val)
        cpDetectRadius = tonumber(val) or cpDetectRadius
        notify("CP Detector", "Radius: " .. tostring(cpDetectRadius) .. " studs", 2)
    end
})

AutomationTab:Input({
    Title = "🧩 Keyword BasePart CP",
    Icon = "lucide:text-cursor",
    Placeholder = "mis. cp / 14 / pad",
    Default = cpKeyword,
    Callback = function(text)
        if text and text ~= "" then
            cpKeyword = text
            lastUsedKeyword = nil
            notify("CP Detector", "Keyword diubah ke: " .. text, 2)
        else
            notify("CP Detector", "Keyword kosong, tetap: " .. cpKeyword, 2)
        end
    end
})

local AutomationInfoSection = AutomationTab:Section({ Title = "CP Detector Info", Icon = "lucide:info" })

AutomationTab:Paragraph({
    Title = "Cara Kerja CP Detector",
    Desc = [[
• Auto Detect CP = Deteksi checkpoint otomatis saat replay
• CP Beam = Garis visual ke checkpoint terdekat
• Delay = Waktu tunggu setelah sentuh checkpoint
• Jarak Deteksi = Radius mencari checkpoint (studs)
• Keyword = Nama BasePart checkpoint (huruf kecil)

Contoh keyword: "cp", "checkpoint", "pad", "14"
Script akan mencari part dengan nama yang cocok.
    ]],
    TextSize = 14,
})

-- ============================================================
-- SETTINGS TAB
-- ============================================================
SettingsTab:Button({
    Title = "TIMER GUI",
    Icon = "lucide:layers-2",
    Desc = "Timer untuk hitung BT",
    Callback = function()
        loadstring(game:HttpGet("https://raw.githubusercontent.com/Bardenss/YAHAYUK/refs/heads/main/TIMER"))()
    end
})
SettingsTab:Button({
    Title = "PRIVATE SERVER",
    Icon = "lucide:layers-2",
    Desc = "Klik untuk pindah ke private server",
    Callback = function()
        loadstring(game:HttpGet("https://raw.githubusercontent.com/Bardenss/PS/refs/heads/main/ps"))()
    end
})

local delayValues = {}
for i = 1, 10 do table.insert(delayValues, tostring(i).."s") end
local teleportDelay = 3

SettingsTab:Dropdown({
    Title = "Delay Teleport",
    Icon = "lucide:timer",
    Values = delayValues,
    Value = "3s",
    Callback = function(val)
        local n = tonumber(val:match("(%d+)"))
        if n then teleportDelay = n end
    end
})

SettingsTab:Slider({
    Title = "WalkSpeed",
    Icon = "lucide:zap",
    Desc = "Atur kecepatan berjalan karakter",
    Value = { 
        Min = 10,
        Max = 500,
        Default = 16
    },
    Step = 1,
    Suffix = "Speed",
    Callback = function(val)
        local char = player.Character
        if char and char:FindFirstChild("Humanoid") then
            char.Humanoid.WalkSpeed = val
        end
    end
})

SettingsTab:Slider({
    Title = "Jump Height",
    Icon = "lucide:zap",
    Desc = "Atur kekuatan lompat karakter",
    Value = { 
        Min = 10,
        Max = 500,
        Default = 50
    },
    Step = 1,
    Suffix = "Height",
    Callback = function(val)
        local char = player.Character
        if char and char:FindFirstChild("Humanoid") then
            char.Humanoid.JumpPower = val
        end
    end
})

SettingsTab:Button({
    Title = "Respawn Player",
    Icon = "lucide:user-minus",
    Desc = "Respawn karakter saat ini",
    Callback = function()
        respawnPlayer()
    end
})

SettingsTab:Button({
    Title = "Speed Coil",
    Icon = "lucide:zap",
    Desc = "Tambah Speed Coil ke karakter",
    Callback = function()
        local Players = game:GetService("Players")
        local player = Players.LocalPlayer
        local speedValue = 23

        local function giveCoil(char)
            local backpack = player:WaitForChild("Backpack")
            if backpack:FindFirstChild("Speed Coil") or char:FindFirstChild("Speed Coil") then return end

            local tool = Instance.new("Tool")
            tool.Name = "Speed Coil"
            tool.RequiresHandle = false
            tool.Parent = backpack

            tool.Equipped:Connect(function()
                local humanoid = char:FindFirstChildOfClass("Humanoid")
                if humanoid then humanoid.WalkSpeed = speedValue end
            end)

            tool.Unequipped:Connect(function()
                local humanoid = char:FindFirstChildOfClass("Humanoid")
                if humanoid then humanoid.WalkSpeed = 16 end
            end)
        end

        if player.Character then giveCoil(player.Character) end
        player.CharacterAdded:Connect(function(char)
            task.wait(1)
            giveCoil(char)
        end)
    end
})

SettingsTab:Button({
    Title = "TP Tool",
    Icon = "lucide:chevrons-up-down",
    Desc = "Teleport pakai tool",
    Callback = function()
        local Players = game:GetService("Players")
        local player = Players.LocalPlayer
        local mouse = player:GetMouse()

        local tool = Instance.new("Tool")
        tool.RequiresHandle = false
        tool.Name = "Teleport"
        tool.Parent = player.Backpack

        tool.Activated:Connect(function()
            if mouse.Hit then
                local char = player.Character
                if char and char:FindFirstChild("HumanoidRootPart") then
                    char.HumanoidRootPart.CFrame = CFrame.new(mouse.Hit.Position + Vector3.new(0,3,0))
                end
            end
        end)
    end
})

SettingsTab:Button({
    Title = "Gling GUI",
    Icon = "lucide:layers-2",
    Desc = "Load Gling GUI",
    Callback = function()
        loadstring(game:HttpGet("https://rawscripts.net/raw/Universal-Script-Fling-Gui-Op-47914"))()
    end
})

-- ============================================================
-- INFO TAB
-- ============================================================
InfoTab:Button({
    Title = "Copy Discord",
    Icon = "geist:logo-discord",
    Desc = "Salin link Discord ke clipboard",
    Callback = function()
        if setclipboard then
            setclipboard("https://discord.gg/cjZPqHRV")
            logAndNotify("Discord", "Link berhasil disalin!")
        else
            notify("Clipboard Error", "setclipboard tidak tersedia!", 2)
        end
    end
})

InfoTab:Section({
    Title = "INFO SC",
    TextSize = 20,
})
InfoTab:Section({
    Title = [[
Replay/route system untuk checkpoint.

- Start CP = mulai dari checkpoint terdekat
- Start To End = jalankan semua checkpoint
- Run CPx → CPy = jalur spesifik
- Playback Speed = atur kecepatan replay (0.25x - 3.00x)

✨ Fitur Baru V1.2.0:
• Walk to Start Position - Jalan ke posisi awal, bukan teleport
• Auto CP Detector - Deteksi checkpoint otomatis saat replay
• CP Beam Visual - Garis arah ke checkpoint terdekat
• Smart Distance Check - Skip walking jika jarak < 5 studs
• Timeout Protection - Max 30 detik untuk reach position

Tab Automation:
• Auto Detect CP - Toggle deteksi checkpoint
• CP Beam Visual - Toggle garis visual
• Delay setelah CP - Atur waktu tunggu (1-60 detik)
• Jarak Deteksi - Atur radius deteksi (5-100 studs)
• Keyword CP - Nama BasePart checkpoint

Own bardenss
    ]],
    TextSize = 16,
    TextTransparency = 0.25,
})

-- ============================================================
-- TAMPILAN TAB
-- ============================================================
tampTab:Paragraph({
    Title = "Customize Interface",
    Desc = "Personalize your experience",
    Image = "palette",
    ImageSize = 20,
    Color = "White"
})

local themes = {}
for themeName, _ in pairs(WindUI:GetThemes()) do
    table.insert(themes, themeName)
end
table.sort(themes)

local canchangetheme = true
local canchangedropdown = true

local themeDropdown = tampTab:Dropdown({
    Title = "Pilih tema",
    Values = themes,
    SearchBarEnabled = true,
    MenuWidth = 280,
    Value = "Dark",
    Callback = function(theme)
        canchangedropdown = false
        WindUI:SetTheme(theme)
        WindUI:Notify({
            Title = "Tema disesuaikan",
            Content = theme,
            Icon = "palette",
            Duration = 2
        })
        canchangedropdown = true
    end
})

local transparencySlider = tampTab:Slider({
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

local ThemeToggle = tampTab:Toggle({
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

tampTab:Button({
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

-- ============================================================
-- WINDOW CONFIGURATION
-- ============================================================
Window:DisableTopbarButtons({
    "Close",
})

Window:EditOpenButton({
    Title = "BANTAI GUNUNG",
    Icon = "geist:logo-nuxt",
    CornerRadius = UDim.new(0,16),
    StrokeThickness = 2,
    Color = ColorSequence.new(
        Color3.fromHex("FF0F7B"), 
        Color3.fromHex("F89B29")
    ),
    OnlyMobile = false,
    Enabled = true,
    Draggable = true,
})

Window:Tag({
    Title = "V1.2.0",
    Color = Color3.fromHex("#30ff6a"),
    Radius = 10,
})

local TimeTag = Window:Tag({
    Title = "--:--:--",
    Icon = "lucide:timer",
    Radius = 10,
    Color = WindUI:Gradient({
        ["0"]   = { Color = Color3.fromHex("#FF0F7B"), Transparency = 0 },
        ["100"] = { Color = Color3.fromHex("#F89B29"), Transparency = 0 },
    }, {
        Rotation = 45,
    }),
})

local hue = 0

task.spawn(function()
	while true do
		local now = os.date("*t")
		local hours   = string.format("%02d", now.hour)
		local minutes = string.format("%02d", now.min)
		local seconds = string.format("%02d", now.sec)

		hue = (hue + 0.01) % 1
		local color = Color3.fromHSV(hue, 1, 1)

		TimeTag:SetTitle(hours .. ":" .. minutes .. ":" .. seconds)
		TimeTag:SetColor(color)

		task.wait(0.06)
	end
end)

Window:CreateTopbarButton("theme-switcher", "moon", function()
    WindUI:SetTheme(WindUI:GetCurrentTheme() == "Dark" and "Light" or "Dark")
    WindUI:Notify({
        Title = "Theme Changed",
        Content = "Current theme: "..WindUI:GetCurrentTheme(),
        Duration = 2
    })
end, 990)

-- ============================================================
-- FINAL NOTIFICATION & WINDOW SHOW
-- ============================================================
notify("BANTAI GUNUNG", "Script V1.2.0 sudah di load dengan CP Detector! 🎯", 4)

pcall(function()
    Window:Show()
    MainTab:Show()
end)
