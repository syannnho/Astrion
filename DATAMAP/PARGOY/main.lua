-- ============================================================
-- CORE (fungsi asli + log/notify)
-- ============================================================
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local player = Players.LocalPlayer
local hrp = nil
local firstLoadComplete = false -- flag untuk cegah teleport awal
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
-- ROUTE EXAMPLE (isi CFrame)
-- ============================================================
-- Tinggi default waktu record
local DEFAULT_HEIGHT = 4.947289
-- 4.882498383522034 

-- Ambil tinggi avatar sekarang
local function getCurrentHeight()
    local char = player.Character or player.CharacterAdded:Wait()
    local humanoid = char:WaitForChild("Humanoid")
    return humanoid.HipHeight + (char:FindFirstChild("Head") and char.Head.Size.Y or 2)
end

-- Adjustment posisi sesuai tinggi avatar
local function adjustRoute(frames)
    local adjusted = {}
    local currentHeight = getCurrentHeight()
    local offsetY = currentHeight - DEFAULT_HEIGHT  -- full offset
    for _, cf in ipairs(frames) do
        local pos, rot = cf.Position, cf - cf.Position
        local newPos = Vector3.new(pos.X, pos.Y + offsetY, pos.Z)
        table.insert(adjusted, CFrame.new(newPos) * rot)
    end
    return adjusted
end

-- ============================================================
-- ROUTE EXAMPLE (isi CFrame)
-- ============================================================
local intervalFlip = false -- toggle interval rotation

-- ============================================================
-- Hapus frame duplikat
-- ============================================================
local function removeDuplicateFrames(frames, tolerance)
    tolerance = tolerance or 0.01 -- toleransi kecil
    if #frames < 2 then return frames end
    local newFrames = {frames[1]}
    for i = 2, #frames do
        local prev = frames[i-1]
        local curr = frames[i]
        local prevPos, currPos = prev.Position, curr.Position
        local prevRot, currRot = prev - prev.Position, curr - curr.Position

        local posDiff = (prevPos - currPos).Magnitude
        local rotDiff = (prevRot.Position - currRot.Position).Magnitude -- rot diff sederhana

        if posDiff > tolerance or rotDiff > tolerance then
            table.insert(newFrames, curr)
        end
    end
    return newFrames
end
-- ============================================================
-- Apply interval flip
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
-- Load route dengan auto adjust + hapus duplikat
-- ============================================================
local function loadRoute(url)
    local ok, result = pcall(function()
        return loadstring(game:HttpGet(url))()
    end)
    if ok and type(result) == "table" then
        local cleaned = removeDuplicateFrames(result, 0.01) -- tambahkan tolerance
        return adjustRoute(cleaned)
    else
        warn("Gagal load route dari: "..url)
        return {}
    end
end

-- daftar link raw route (ubah ke link punyamu)
routes = {
    {"BASE → FINISH", loadRoute("https://raw.githubusercontent.com/yrejinhoo/Replays/refs/heads/main/PARGOY/V2/PARGOY.lua")},
}

-- ============================================================
-- Fungsi bantu & core logic
-- ============================================================
local VirtualUser = game:GetService("VirtualUser")
local antiIdleActive = true -- langsung aktif
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
-- ============================================================
-- Modifikasi lerpCF untuk interval flip
-- ============================================================
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


-- notify placeholder
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
    local lastVelocity = Vector3.zero

    if bypassConn then bypassConn:Disconnect() end
    bypassConn = RunService.Heartbeat:Connect(function(dt)
        if not hrp or not hrp.Parent then return end
        if bypassActive then
            local currentPos = hrp.Position
            local direction = (currentPos - lastPos)
            local dist = direction.Magnitude

            -- Hitung velocity yang smooth
            local targetVelocity = direction / math.max(dt, 0.016)
            local smoothVelocity = lastVelocity:Lerp(targetVelocity, math.clamp(dt * 8, 0, 1))

            -- Deteksi perbedaan ketinggian (Y) lebih halus
            local yDiff = currentPos.Y - lastPos.Y
            if yDiff > 0.3 then
                humanoid:ChangeState(Enum.HumanoidStateType.Jumping)
            elseif yDiff < -0.5 then
                humanoid:ChangeState(Enum.HumanoidStateType.Freefall)
            end

            if dist > 0.005 then
                -- Gunakan velocity smooth untuk movement yang lebih natural
                local moveStrength = math.clamp(smoothVelocity.Magnitude * 0.1, 0, 0.8)
                humanoid:Move(smoothVelocity.Unit * moveStrength, false)
            else
                -- Jangan paksa idle, biarkan animasi natural jalan
                humanoid:Move(Vector3.zero, false)
            end

            lastVelocity = smoothVelocity
        else
            -- Saat bypass OFF, biarkan humanoid bergerak normal
            humanoid:Move(Vector3.zero, false)
        end
        lastPos = hrp.Position
    end)
end

player.CharacterAdded:Connect(setupBypass)
if player.Character then setupBypass(player.Character) end

-- helper otomatis bypass
local function setBypass(state)
    bypassActive = state
    if state then
        notify("Bypass Animasi", "✅ Aktif", 2)
    else
        notify("Bypass Animasi", "❌ Nonaktif", 2)
        -- Reset movement saat OFF
        local char = player.Character
        if char then
            local humanoid = char:FindFirstChild("Humanoid")
            if humanoid then
                humanoid:Move(Vector3.zero, false)
            end
        end
    end
end

-- Fungsi jalan ke posisi target (walkToStart)
local function walkToStart(targetCF)
    if not hrp then refreshHRP() end
    local char = player.Character
    if not char then return end
    local humanoid = char:FindFirstChild("Humanoid")
    if not humanoid then return end
    
    local startPos = hrp.Position
    local targetPos = targetCF.Position
    local distance = (targetPos - startPos).Magnitude
    
    -- Jika jaraknya dekat (< 50 studs), langsung mulai
    if distance < 50 then
        return true
    end
    
    -- Jika jauh, jalan ke sana
    notify("Auto Walk", "Berjalan ke start point...", 2)
    humanoid:MoveTo(targetPos)
    
    -- Tunggu sampai sampai atau timeout (30 detik)
    local timeout = 30
    local elapsed = 0
    while elapsed < timeout do
        if not hrp or not hrp.Parent then return false end
        local currentDist = (hrp.Position - targetPos).Magnitude
        
        -- Kalau sudah dekat (< 10 studs), selesai
        if currentDist < 10 then
            humanoid:MoveTo(hrp.Position) -- stop movement
            return true
        end
        
        -- Cek jika застрял/stuck (tidak bergerak)
        local movedDist = (hrp.Position - startPos).Magnitude
        if elapsed > 5 and movedDist < 5 then
            notify("Auto Walk", "⚠️ Stuck! Teleporting...", 2)
            hrp.CFrame = targetCF
            return true
        end
        
        task.wait(0.5)
        elapsed += 0.5
    end
    
    -- Timeout, teleport paksa
    notify("Auto Walk", "⚠️ Timeout! Teleporting...", 2)
    hrp.CFrame = targetCF
    return true
end


-- Jalankan 1 route dari checkpoint terdekat
local function runRouteOnce()
    if #routes == 0 then return end
    if not hrp then refreshHRP() end

    local idx = getNearestRoute()
    local frames = routes[idx][2]
    if #frames < 2 then 
        return 
    end
    
    local startIdx = getNearestFrameIndex(frames)
    local startFrame = frames[startIdx]
    
    -- Jalan ke start point dulu
    logAndNotify("Mulai dari cp : ", routes[idx][1])
    if not walkToStart(startFrame) then
        notify("Error", "Gagal mencapai start point!", 3)
        return
    end
    
    -- Baru aktifkan bypass dan mulai route
    setBypass(true)
    isRunning = true

    for i = startIdx, #frames - 1 do
        if not isRunning then break end
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

        local idx = getNearestRoute()
        logAndNotify("Sesuaikan dari cp : ", routes[idx][1])

        for r = idx, #routes do
            if not isRunning then break end
            local frames = routes[r][2]
            if #frames < 2 then continue end
            
            local startIdx = getNearestFrameIndex(frames)
            local startFrame = frames[startIdx]
            
            -- Jalan ke start dulu (tanpa bypass)
            if not walkToStart(startFrame) then
                notify("Error", "Gagal mencapai CP "..r, 3)
                break
            end
            
            -- Aktifkan bypass untuk route
            setBypass(true)
            
            for i = startIdx, #frames - 1 do
                if not isRunning then break end
                lerpCF(frames[i], frames[i+1])
            end
            
            setBypass(false)
        end

        -- Respawn + delay 5 detik HANYA jika masih running
        if not isRunning then break end
        respawnPlayer()
        task.wait(5)
    end
    
    setBypass(false)
end

local function stopRoute()
    if isRunning then
        logAndNotify("Stop route", "Semua route dihentikan!")
    end

    -- hentikan loop utama
    isRunning = false

    -- matikan bypass kalau aktif
    if bypassActive then
        bypassActive = false
        notify("Bypass Animasi", "❌ Nonaktif", 2)
    end
end

local function runSpecificRoute(routeIdx)
    if not routes[routeIdx] then return end
    if not hrp then refreshHRP() end
    
    local frames = routes[routeIdx][2]
    if #frames < 2 then 
        return 
    end
    
    logAndNotify("Memulai track : ", routes[routeIdx][1])
    local startIdx = getNearestFrameIndex(frames)
    local startFrame = frames[startIdx]
    
    -- Jalan ke start dulu
    if not walkToStart(startFrame) then
        notify("Error", "Gagal mencapai start point!", 3)
        return
    end
    
    -- Aktifkan bypass dan mulai route
    setBypass(true)
    isRunning = true
    
    for i = startIdx, #frames - 1 do
        if not isRunning then break end
        lerpCF(frames[i], frames[i+1])
    end
    
    isRunning = false
    setBypass(false)
end

-- ===============================
-- Anti Beton Ultra-Smooth (Presisi Tinggi)
-- ===============================
local antiBetonActive = false
local antiBetonConn

local function enableAntiBeton()
    if antiBetonConn then antiBetonConn:Disconnect() end

    local lastVelocityY = 0
    antiBetonConn = RunService.Heartbeat:Connect(function(dt)
        local char = player.Character
        if not char then return end
        local hrp = char:FindFirstChild("HumanoidRootPart")
        local humanoid = char:FindFirstChild("Humanoid")
        if not hrp or not humanoid then return end

        if antiBetonActive and humanoid.FloorMaterial == Enum.Material.Air then
            local targetY = -48 -- target velocity turun
            local currentY = hrp.Velocity.Y
            
            -- Smooth acceleration dengan lerp bertahap
            local smoothFactor = math.clamp(dt * 3.5, 0, 0.95)
            local newY = lastVelocityY + (targetY - lastVelocityY) * smoothFactor
            
            -- Apply dengan smooth transition
            hrp.Velocity = Vector3.new(
                hrp.Velocity.X,
                newY,
                hrp.Velocity.Z
            )
            
            lastVelocityY = newY
        else
            lastVelocityY = 0
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
-- ANIMATION SYSTEM
-- ============================================================
local AnimationSets = {
    ["Run Animation 1"] = {
        Idle1   = "rbxassetid://122257458498464",
        Idle2   = "rbxassetid://102357151005774",
        Walk    = "http://www.roblox.com/asset/?id=18537392113",
        Run     = "rbxassetid://82598234841035",
        Jump    = "rbxassetid://75290611992385",
        Fall    = "http://www.roblox.com/asset/?id=11600206437",
        Climb   = "http://www.roblox.com/asset/?id=10921257536",
        Swim    = "http://www.roblox.com/asset/?id=10921264784",
        SwimIdle= "http://www.roblox.com/asset/?id=10921265698"
    },
    ["Run Animation 2"] = {
        Idle1   = "rbxassetid://122257458498464",
        Idle2   = "rbxassetid://102357151005774",
        Walk    = "rbxassetid://122150855457006",
        Run     = "rbxassetid://82598234841035",
        Jump    = "rbxassetid://75290611992385",
        Fall    = "rbxassetid://98600215928904",
        Climb   = "rbxassetid://88763136693023",
        Swim    = "rbxassetid://133308483266208",
        SwimIdle= "rbxassetid://109346520324160"
    },
    ["Run Animation 3"] = {
        Idle1   = "http://www.roblox.com/asset/?id=18537376492",
        Idle2   = "http://www.roblox.com/asset/?id=18537371272",
        Walk    = "http://www.roblox.com/asset/?id=18537392113",
        Run     = "http://www.roblox.com/asset/?id=18537384940",
        Jump    = "http://www.roblox.com/asset/?id=18537380791",
        Fall    = "http://www.roblox.com/asset/?id=18537367238",
        Climb   = "http://www.roblox.com/asset/?id=10921271391",
        Swim    = "http://www.roblox.com/asset/?id=99384245425157",
        SwimIdle= "http://www.roblox.com/asset/?id=113199415118199"
    },
    ["Run Animation 4"] = {
        Idle1   = "http://www.roblox.com/asset/?id=118832222982049",
        Idle2   = "http://www.roblox.com/asset/?id=76049494037641",
        Walk    = "http://www.roblox.com/asset/?id=92072849924640",
        Run     = "http://www.roblox.com/asset/?id=72301599441680",
        Jump    = "http://www.roblox.com/asset/?id=104325245285198",
        Fall    = "http://www.roblox.com/asset/?id=121152442762481",
        Climb   = "http://www.roblox.com/asset/?id=507765644",
        Swim    = "http://www.roblox.com/asset/?id=99384245425157",
        SwimIdle= "http://www.roblox.com/asset/?id=113199415118199"
    },
    ["Run Animation 5"] = {
        Idle1   = "http://www.roblox.com/asset/?id=656117400",
        Idle2   = "http://www.roblox.com/asset/?id=656118341",
        Walk    = "http://www.roblox.com/asset/?id=656121766",
        Run     = "http://www.roblox.com/asset/?id=656118852",
        Jump    = "http://www.roblox.com/asset/?id=656117878",
        Fall    = "http://www.roblox.com/asset/?id=656115606",
        Climb   = "http://www.roblox.com/asset/?id=656114359",
        Swim    = "http://www.roblox.com/asset/?id=910028158",
        SwimIdle= "http://www.roblox.com/asset/?id=910030921"
    },
    ["Run Animation 6"] = {
        Idle1   = "http://www.roblox.com/asset/?id=616006778",
        Idle2   = "http://www.roblox.com/asset/?id=616008087",
        Walk    = "http://www.roblox.com/asset/?id=616013216",
        Run     = "http://www.roblox.com/asset/?id=616010382",
        Jump    = "http://www.roblox.com/asset/?id=616008936",
        Fall    = "http://www.roblox.com/asset/?id=616005863",
        Climb   = "http://www.roblox.com/asset/?id=616003713",
        Swim    = "http://www.roblox.com/asset/?id=910028158",
        SwimIdle= "http://www.roblox.com/asset/?id=910030921"
    },
    ["Run Animation 7"] = {
        Idle1   = "http://www.roblox.com/asset/?id=1083195517",
        Idle2   = "http://www.roblox.com/asset/?id=1083214717",
        Walk    = "http://www.roblox.com/asset/?id=1083178339",
        Run     = "http://www.roblox.com/asset/?id=1083216690",
        Jump    = "http://www.roblox.com/asset/?id=1083218792",
        Fall    = "http://www.roblox.com/asset/?id=1083189019",
        Climb   = "http://www.roblox.com/asset/?id=1083182000",
        Swim    = "http://www.roblox.com/asset/?id=910028158",
        SwimIdle= "http://www.roblox.com/asset/?id=910030921"
    },
    ["Run Animation 8"] = {
        Idle1   = "http://www.roblox.com/asset/?id=616136790",
        Idle2   = "http://www.roblox.com/asset/?id=616138447",
        Walk    = "http://www.roblox.com/asset/?id=616146177",
        Run     = "http://www.roblox.com/asset/?id=616140816",
        Jump    = "http://www.roblox.com/asset/?id=616139451",
        Fall    = "http://www.roblox.com/asset/?id=616134815",
        Climb   = "http://www.roblox.com/asset/?id=616133594",
        Swim    = "http://www.roblox.com/asset/?id=910028158",
        SwimIdle= "http://www.roblox.com/asset/?id=910030921"
    },
    ["Run Animation 9"] = {
        Idle1   = "http://www.roblox.com/asset/?id=616088211",
        Idle2   = "http://www.roblox.com/asset/?id=616089559",
        Walk    = "http://www.roblox.com/asset/?id=616095330",
        Run     = "http://www.roblox.com/asset/?id=616091570",
        Jump    = "http://www.roblox.com/asset/?id=616090535",
        Fall    = "http://www.roblox.com/asset/?id=616087089",
        Climb   = "http://www.roblox.com/asset/?id=616086039",
        Swim    = "http://www.roblox.com/asset/?id=910028158",
        SwimIdle= "http://www.roblox.com/asset/?id=910030921"
    },
    ["Run Animation 10"] = {
        Idle1   = "http://www.roblox.com/asset/?id=910004836",
        Idle2   = "http://www.roblox.com/asset/?id=910009958",
        Walk    = "http://www.roblox.com/asset/?id=910034870",
        Run     = "http://www.roblox.com/asset/?id=910025107",
        Jump    = "http://www.roblox.com/asset/?id=910016857",
        Fall    = "http://www.roblox.com/asset/?id=910001910",
        Climb   = "http://www.roblox.com/asset/?id=616086039",
        Swim    = "http://www.roblox.com/asset/?id=910028158",
        SwimIdle= "http://www.roblox.com/asset/?id=910030921"
    },
    ["Run Animation 11"] = {
        Idle1   = "http://www.roblox.com/asset/?id=742637544",
        Idle2   = "http://www.roblox.com/asset/?id=742638445",
        Walk    = "http://www.roblox.com/asset/?id=742640026",
        Run     = "http://www.roblox.com/asset/?id=742638842",
        Jump    = "http://www.roblox.com/asset/?id=742637942",
        Fall    = "http://www.roblox.com/asset/?id=742637151",
        Climb   = "http://www.roblox.com/asset/?id=742636889",
        Swim    = "http://www.roblox.com/asset/?id=910028158",
        SwimIdle= "http://www.roblox.com/asset/?id=910030921"
    },
    ["Run Animation 12"] = {
        Idle1   = "http://www.roblox.com/asset/?id=616111295",
        Idle2   = "http://www.roblox.com/asset/?id=616113536",
        Walk    = "http://www.roblox.com/asset/?id=616122287",
        Run     = "http://www.roblox.com/asset/?id=616117076",
        Jump    = "http://www.roblox.com/asset/?id=616115533",
        Fall    = "http://www.roblox.com/asset/?id=616108001",
        Climb   = "http://www.roblox.com/asset/?id=616104706",
        Swim    = "http://www.roblox.com/asset/?id=910028158",
        SwimIdle= "http://www.roblox.com/asset/?id=910030921"
    },
    ["Run Animation 13"] = {
        Idle1   = "http://www.roblox.com/asset/?id=657595757",
        Idle2   = "http://www.roblox.com/asset/?id=657568135",
        Walk    = "http://www.roblox.com/asset/?id=657552124",
        Run     = "http://www.roblox.com/asset/?id=657564596",
        Jump    = "http://www.roblox.com/asset/?id=658409194",
        Fall    = "http://www.roblox.com/asset/?id=657600338",
        Climb   = "http://www.roblox.com/asset/?id=658360781",
        Swim    = "http://www.roblox.com/asset/?id=910028158",
        SwimIdle= "http://www.roblox.com/asset/?id=910030921"
    },
    ["Run Animation 14"] = {
        Idle1   = "http://www.roblox.com/asset/?id=616158929",
        Idle2   = "http://www.roblox.com/asset/?id=616160636",
        Walk    = "http://www.roblox.com/asset/?id=616168032",
        Run     = "http://www.roblox.com/asset/?id=616163682",
        Jump    = "http://www.roblox.com/asset/?id=616161997",
        Fall    = "http://www.roblox.com/asset/?id=616157476",
        Climb   = "http://www.roblox.com/asset/?id=616156119",
        Swim    = "http://www.roblox.com/asset/?id=910028158",
        SwimIdle= "http://www.roblox.com/asset/?id=910030921"
    },
    ["Run Animation 15"] = {
        Idle1   = "http://www.roblox.com/asset/?id=845397899",
        Idle2   = "http://www.roblox.com/asset/?id=845400520",
        Walk    = "http://www.roblox.com/asset/?id=845403856",
        Run     = "http://www.roblox.com/asset/?id=845386501",
        Jump    = "http://www.roblox.com/asset/?id=845398858",
        Fall    = "http://www.roblox.com/asset/?id=845396048",
        Climb   = "http://www.roblox.com/asset/?id=845392038",
        Swim    = "http://www.roblox.com/asset/?id=910028158",
        SwimIdle= "http://www.roblox.com/asset/?id=910030921"
    },
    ["Run Animation 16"] = {
        Idle1   = "http://www.roblox.com/asset/?id=782841498",
        Idle2   = "http://www.roblox.com/asset/?id=782845736",
        Walk    = "http://www.roblox.com/asset/?id=782843345",
        Run     = "http://www.roblox.com/asset/?id=782842708",
        Jump    = "http://www.roblox.com/asset/?id=782847020",
        Fall    = "http://www.roblox.com/asset/?id=782846423",
        Climb   = "http://www.roblox.com/asset/?id=782843869",
        Swim    = "http://www.roblox.com/asset/?id=18537389531",
        SwimIdle= "http://www.roblox.com/asset/?id=18537387180"
    },
    ["Run Animation 17"] = {
        Idle1   = "http://www.roblox.com/asset/?id=891621366",
        Idle2   = "http://www.roblox.com/asset/?id=891633237",
        Walk    = "http://www.roblox.com/asset/?id=891667138",
        Run     = "http://www.roblox.com/asset/?id=891636393",
        Jump    = "http://www.roblox.com/asset/?id=891627522",
        Fall    = "http://www.roblox.com/asset/?id=891617961",
        Climb   = "http://www.roblox.com/asset/?id=891609353",
        Swim    = "http://www.roblox.com/asset/?id=18537389531",
        SwimIdle= "http://www.roblox.com/asset/?id=18537387180"
    },
    ["Run Animation 18"] = {
        Idle1   = "http://www.roblox.com/asset/?id=750781874",
        Idle2   = "http://www.roblox.com/asset/?id=750782770",
        Walk    = "http://www.roblox.com/asset/?id=750785693",
        Run     = "http://www.roblox.com/asset/?id=750783738",
        Jump    = "http://www.roblox.com/asset/?id=750782230",
        Fall    = "http://www.roblox.com/asset/?id=750780242",
        Climb   = "http://www.roblox.com/asset/?id=750779899",
        Swim    = "http://www.roblox.com/asset/?id=18537389531",
        SwimIdle= "http://www.roblox.com/asset/?id=18537387180"
    },
}

local currentAnimationSet = nil
local animationEnabled = false -- flag untuk aktifkan animasi custom

local function applyAnimationSet(char, animSet)
    if not animationEnabled then return end -- cek flag dulu
    
    local humanoid = char:WaitForChild("Humanoid")
    local animate = char:WaitForChild("Animate")
    
    -- Hapus animasi lama
    for _, track in ipairs(humanoid:GetPlayingAnimationTracks()) do
        track:Stop()
    end
    
    -- Apply animasi baru
    if animSet.Idle1 then
        animate.idle.Animation1.AnimationId = animSet.Idle1
    end
    if animSet.Idle2 then
        animate.idle.Animation2.AnimationId = animSet.Idle2
    end
    if animSet.Walk then
        animate.walk.WalkAnim.AnimationId = animSet.Walk
    end
    if animSet.Run then
        animate.run.RunAnim.AnimationId = animSet.Run
    end
    if animSet.Jump then
        animate.jump.JumpAnim.AnimationId = animSet.Jump
    end
    if animSet.Fall then
        animate.fall.FallAnim.AnimationId = animSet.Fall
    end
    if animSet.Climb then
        animate.climb.ClimbAnim.AnimationId = animSet.Climb
    end
    if animSet.Swim then
        animate.swim.Swim.AnimationId = animSet.Swim
    end
    if animSet.SwimIdle then
        animate.swim.SwimIdle.AnimationId = animSet.SwimIdle
    end
    
    -- Reset humanoid untuk apply perubahan
    humanoid:ChangeState(Enum.HumanoidStateType.Landed)
end

local function setAnimationSet(setName)
    local animSet = AnimationSets[setName]
    if not animSet then return end
    
    currentAnimationSet = setName
    
    -- Hanya apply jika enabled
    if animationEnabled then
        local char = player.Character
        if char then
            pcall(function()
                applyAnimationSet(char, animSet)
                notify("Animation", "Applied: "..setName, 2)
            end)
        end
    end
end

-- Auto-apply saat respawn (hanya jika enabled)
player.CharacterAdded:Connect(function(char)
    task.wait(0.5)
    if animationEnabled and currentAnimationSet then
        local animSet = AnimationSets[currentAnimationSet]
        if animSet then
            pcall(function()
                applyAnimationSet(char, animSet)
            end)
        end
    end
end)

-- ============================================================
-- UI: WindUI
-- ============================================================
local WindUI = loadstring(game:HttpGet("https://github.com/Footagesus/WindUI/releases/latest/download/main.lua"))()

local Window = WindUI:CreateWindow({
    Title = "ASTRION HUB+",
    Icon = "lucide:mountain-snow",
    Author = "Jinho",
    Folder = "ASTRHUB",
    Size = UDim2.fromOffset(580, 460),
    Theme = "Midnight",
    Resizable = true,
    SideBarWidth = 200,
    Watermark = "Jinho",
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

-- inject notify
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

-- Jalankan saat script load
enableAntiIdle()

-- Tabs
local MainTab = Window:Tab({
    Title = "Main",
    Icon = "geist:shareplay",
    Default = true
})
local AnimTab = Window:Tab({
    Title = "Animation",
    Icon = "lucide:person-standing",
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
-- Main Tab (Dropdown speed mulai dari 0.25x)
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

-- Main Tab Buttons
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
-- Animation Tab
-- ============================================================
AnimTab:Section({
    Title = "Character Animations",
    TextSize = 18,
})

-- Toggle untuk enable/disable animasi custom
AnimTab:Toggle({
    Title = "Enable Custom Animation",
    Icon = "lucide:toggle-right",
    Desc = "Aktifkan untuk pakai animasi custom",
    Value = false,
    Callback = function(state)
        animationEnabled = state
        
        if state then
            -- Aktifkan animasi custom
            if currentAnimationSet then
                local animSet = AnimationSets[currentAnimationSet]
                if animSet then
                    local char = player.Character
                    if char then
                        pcall(function()
                            applyAnimationSet(char, animSet)
                            notify("Animation", "✅ Custom animation enabled", 2)
                        end)
                    end
                end
            else
                notify("Animation", "⚠️ Pilih animasi dulu!", 2)
            end
        else
            -- Matikan animasi custom (kembali ke default)
            local char = player.Character
            if char then
                char:BreakJoints() -- Respawn untuk reset ke default
                notify("Animation", "❌ Back to default animation", 2)
            end
        end
    end
})

-- Buat list untuk dropdown
local animationNames = {}
for name, _ in pairs(AnimationSets) do
    table.insert(animationNames, name)
end
table.sort(animationNames)

AnimTab:Dropdown({
    Title = "Select Animation Set",
    Icon = "lucide:play",
    Values = animationNames,
    SearchBarEnabled = true,
    Value = animationNames[1],
    Callback = function(selected)
        currentAnimationSet = selected
        
        -- Hanya apply jika toggle enabled
        if animationEnabled then
            setAnimationSet(selected)
        else
            notify("Animation", "Selected: "..selected.."\nToggle ON untuk apply", 2)
        end
    end
})

AnimTab:Button({
    Title = "Apply Selected Animation",
    Icon = "lucide:check",
    Desc = "Apply animasi yang dipilih (toggle harus ON)",
    Callback = function()
        if not currentAnimationSet then
            notify("Animation", "⚠️ Pilih animasi dulu!", 2)
            return
        end
        
        if not animationEnabled then
            notify("Animation", "⚠️ Toggle harus ON!", 2)
            return
        end
        
        setAnimationSet(currentAnimationSet)
    end
})

AnimTab:Button({
    Title = "Reset to Default",
    Icon = "lucide:rotate-ccw",
    Desc = "Reset animasi ke default Roblox",
    Callback = function()
        animationEnabled = false
        currentAnimationSet = nil
        local char = player.Character
        if char then
            char:BreakJoints() -- Respawn untuk reset animasi
            notify("Animation", "Reset to default", 2)
        end
    end
})

AnimTab:Section({
    Title = "Info",
    TextSize = 14,
    TextTransparency = 0.3,
})

AnimTab:Paragraph({
    Title = "How to Use",
    Desc = "1. Select animation from dropdown\n2. Toggle ON 'Enable Custom Animation'\n3. Animation will apply automatically\n4. Toggle OFF to use default animation\n5. Animation persist after respawn",
    Color = "White"
})

-- ============================================================
-- Setup teleport options: BASE + CP1, CP2, dst
-- ============================================================
local teleportOptions = {"BASE"}
for idx, _ in ipairs(routes) do
    table.insert(teleportOptions, "CP "..idx)
end

-- Delay dropdown (1–10 detik)
local delayValues = {}
for i = 1, 10 do table.insert(delayValues, tostring(i).."s") end
local teleportDelay = 3 -- default 3 detik

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

-- Dropdown teleport satu checkpoint
SettingsTab:Dropdown({
    Title = "Teleport ke Checkpoint",
    Icon = "lucide:map-pin",
    Values = teleportOptions,
    SearchBarEnabled = true,
    Value = teleportOptions[1], -- default BASE
    Callback = function(selected)
        -- Cek flag first load
        if not firstLoadComplete then
            notify("Teleport", "Menunggu script load selesai...", 2)
            return
        end
        
        local char = player.Character
        local hrp = char and char:FindFirstChild("HumanoidRootPart")
        if not hrp then return end

        local targetCF
        if selected == "BASE" then
            targetCF = routes[1][2][1] -- frame pertama route 1
        else
            local idx = tonumber(selected:match("%d+"))
            if idx and routes[idx] then
                local frames = routes[idx][2]
                targetCF = frames[#frames] -- frame terakhir route idx
            end
        end

        if targetCF then
            hrp.CFrame = targetCF
            notify("Teleport", "Berhasil ke "..selected, 2)
        else
            notify("Teleport", "Gagal teleport!", 2)
        end
    end
})

-- Loop teleport dari BASE → CP terakhir
SettingsTab:Button({
    Title = "Loop Teleport",
    Icon = "lucide:refresh-ccw",
    Desc = "Teleport dari BASE sampai CP terakhir sesuai route",
    Callback = function()
        -- Cek flag first load
        if not firstLoadComplete then
            notify("Loop Teleport", "Menunggu script load selesai...", 2)
            return
        end
        
        local char = player.Character
        local hrp = char and char:FindFirstChild("HumanoidRootPart")
        if not hrp then return end

        task.spawn(function()
            -- BASE dulu
            hrp.CFrame = routes[1][2][1]
            notify("Loop Teleport", "Teleport ke BASE", 2)
            task.wait(teleportDelay)

            -- Loop dari CP1 sampai CP terakhir
            for idx, _ in ipairs(routes) do
                local frames = routes[idx][2]
                hrp.CFrame = frames[#frames] -- frame terakhir route
                notify("Loop Teleport", "Teleport ke CP "..idx, 2)
                task.wait(teleportDelay)
            end

            notify("Loop Teleport", "Selesai!", 3)
        end)
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
    Icon = "lucide:refresh-ccw",
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

-- Info Tab
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

Own jinho
    ]],
    TextSize = 16,
    TextTransparency = 0.25,
})

-- Topbar custom
Window:DisableTopbarButtons({
    "Close",
})

-- Open button cantik
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

-- Tambah tag
Window:Tag({
    Title = "V1.0.1",
    Color = Color3.fromHex("#30ff6a"),
    Radius = 10,
})

-- Tag Jam
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

-- Rainbow + Jam Real-time
task.spawn(function()
	while true do
		-- Ambil waktu sekarang
		local now = os.date("*t")
		local hours   = string.format("%02d", now.hour)
		local minutes = string.format("%02d", now.min)
		local seconds = string.format("%02d", now.sec)

		-- Update warna rainbow
		hue = (hue + 0.01) % 1
		local color = Color3.fromHSV(hue, 1, 1)

		-- Update judul tag jadi jam lengkap
		TimeTag:SetTitle(hours .. ":" .. minutes .. ":" .. seconds)

		-- Kalau mau rainbow berjalan, aktifkan ini:
		TimeTag:SetColor(color)

		task.wait(0.06) -- refresh cepat
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

-- Final notif
notify("BANTAI GUNUNG", "Script sudah di load, gunakan dengan bijak.", 3)

-- Set flag setelah delay 2 detik untuk cegah teleport awal
task.delay(2, function()
    firstLoadComplete = true
    print("✅ First load complete - teleport enabled")
end)

pcall(function()
    Window:Show()
    MainTab:Show()
end)
