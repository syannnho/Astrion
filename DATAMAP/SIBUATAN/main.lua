-------------------------------------------------------------
-- LOAD LIBRARY UI
-------------------------------------------------------------
local Rayfield = loadstring(game:HttpGet('https://raw.githubusercontent.com/RullzsyHUB/roblox-scripts/refs/heads/main/UI%20Liblary/Rayfield.lua'))()

-------------------------------------------------------------
-- WINDOW PROCESS
-------------------------------------------------------------
local Window = Rayfield:CreateWindow({
   Name = "RullzsyHUB | SIBUATAN",
   Icon = "braces",
   LoadingTitle = "Created By RullzsyHUB",
   LoadingSubtitle = "Follow Tiktok: @rullzsy99",
   Theme = "Amethyst",
})

-------------------------------------------------------------
-- TAB MENU
-------------------------------------------------------------
local AccountTab = Window:CreateTab("Account", "user")
local BypassTab = Window:CreateTab("Bypass", "shield")
local AutoWalkTab = Window:CreateTab("Auto Walk", "bot")
local VisualTab = Window:CreateTab("Visual", "layers")
local CreditsTab = Window:CreateTab("Credits", "scroll-text")

-------------------------------------------------------------
-- SERVICES
-------------------------------------------------------------
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local HttpService = game:GetService("HttpService")
local StarterGui = game:GetService("StarterGui")
local TweenService = game:GetService("TweenService")
local CoreGui = game:GetService("CoreGui")
local VirtualUser = game:GetService("VirtualUser")

-------------------------------------------------------------
-- IMPORT
-------------------------------------------------------------
local LocalPlayer = Players.LocalPlayer
local player = Players.LocalPlayer
local character = player.Character or player.CharacterAdded:Wait()
local humanoid = character:WaitForChild("Humanoid")
local humanoidRootPart = character:WaitForChild("HumanoidRootPart")

-------------------------------------------------------------
-- ACCOUNT TAB
-------------------------------------------------------------
AccountTab:CreateSection("Account Information")

local InfoParagraph = AccountTab:CreateParagraph({
    Title = "📊 Status Akun",
    Content = "Akun aktif dan siap digunakan."
})

AccountTab:CreateSection("Quick Actions")

AccountTab:CreateButton({
    Name = "🛒 Beli/Perpanjang Key",
    Callback = function()
        local discordLink = "https://discord.gg/KEajwZQaRd"
        if setclipboard then
            setclipboard(discordLink)
            Rayfield:Notify({
                Title = "📋 Copied!",
                Content = "Discord link copied!",
                Duration = 3
            })
        end
    end
})

AccountTab:CreateParagraph({
    Title = "💡 Info",
    Content = "Untuk perpanjang key, silahkan buat ticket di Discord."
})

-------------------------------------------------------------
-- BYPASS AFK
-------------------------------------------------------------
getgenv().AntiIdleActive = false
local AntiIdleConnection
local MovementLoop

local function StartAntiIdle()
    if AntiIdleConnection then
        AntiIdleConnection:Disconnect()
        AntiIdleConnection = nil
    end
    if MovementLoop then
        MovementLoop:Disconnect()
        MovementLoop = nil
    end
    AntiIdleConnection = LocalPlayer.Idled:Connect(function()
        if getgenv().AntiIdleActive then
            VirtualUser:Button2Down(Vector2.new(0,0), workspace.CurrentCamera.CFrame)
            task.wait(1)
            VirtualUser:Button2Up(Vector2.new(0,0), workspace.CurrentCamera.CFrame)
        end
    end)
    MovementLoop = RunService.Heartbeat:Connect(function()
        if getgenv().AntiIdleActive and LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then
            local root = LocalPlayer.Character.HumanoidRootPart
            if tick() % 60 < 0.05 then
                root.CFrame = root.CFrame * CFrame.new(0, 0, 0.1)
                task.wait(0.1)
                root.CFrame = root.CFrame * CFrame.new(0, 0, -0.1)
            end
        end
    end)
end

local function SetupCharacterListener()
    LocalPlayer.CharacterAdded:Connect(function(newChar)
        newChar:WaitForChild("HumanoidRootPart", 10)
        if getgenv().AntiIdleActive then
            StartAntiIdle()
        end
    end)
end

StartAntiIdle()
SetupCharacterListener()

local Section = BypassTab:CreateSection("List All Bypass")

BypassTab:CreateToggle({
    Name = "Bypass AFK",
    CurrentValue = false,
    Flag = "AntiIdleToggle",
    Callback = function(Value)
        getgenv().AntiIdleActive = Value
        if Value then
            StartAntiIdle()
            Rayfield:Notify({
                Image = "shield",
                Title = "Bypass AFK",
                Content = "Bypass AFK diaktifkan",
                Duration = 5
            })
        else
            if AntiIdleConnection then
                AntiIdleConnection:Disconnect()
                AntiIdleConnection = nil
            end
            if MovementLoop then
                MovementLoop:Disconnect()
                MovementLoop = nil
            end
            Rayfield:Notify({
                Image = "shield",
                Title = "Bypass AFK",
                Content = "Bypass AFK dimatikan",
                Duration = 5
            })
        end
    end,
})

-------------------------------------------------------------
-- AUTO WALK
-------------------------------------------------------------
local mainFolder = "RullzsyHUB"
local jsonFolder = mainFolder .. "/js_mount_sibuatan_patch_001"
if not isfolder(mainFolder) then
    makefolder(mainFolder)
end
if not isfolder(jsonFolder) then
    makefolder(jsonFolder)
end

local baseURL = "https://raw.githubusercontent.com/RullzsyHUB/roblox-scripts-json/refs/heads/main/json_mount_sibuatan/"
local jsonFiles = {
    "spawnpoint.json",
    "checkpoint_1.json",
    "checkpoint_2.json",
    "checkpoint_4.json",
    "checkpoint_8.json",
    "checkpoint_9.json",
    "checkpoint_10.json",
    "checkpoint_11.json",
    "checkpoint_17.json",
    "checkpoint_19.json",
    "checkpoint_21.json",
    "checkpoint_24.json",
    "checkpoint_25.json",
    "checkpoint_26.json",
    "checkpoint_27.json",
    "water_checkpoint.json",
    "checkpoint_29.json",
    "checkpoint_32.json",
    "checkpoint_34.json",
    "checkpoint_35.json",
    "checkpoint_36.json",
    "checkpoint_37.json",
    "checkpoint_38.json",
    "checkpoint_39.json",
    "checkpoint_40.json",
    "checkpoint_42.json",
    "checkpoint_43.json",
}

local isPlaying = false
local playbackConnection = nil
local autoLoopEnabled = false
local currentCheckpoint = 0

local isPaused = false
local manualLoopEnabled = false
local pausedTime = 0
local pauseStartTime = 0

local lastPlaybackTime = 0
local accumulatedTime = 0

local loopingEnabled = false
local isManualMode = false
local manualStartCheckpoint = 0

local recordedHipHeight = nil
local currentHipHeight = nil
local hipHeightOffset = 0

local playbackSpeed = 0.9

local lastFootstepTime = 0
local footstepInterval = 0.35
local leftFootstep = true

local isFlipped = false
local FLIP_SMOOTHNESS = 0.05
local currentFlipRotation = CFrame.new()

local noDamageEnabled = false

-----| AUTO WALK FUNCTIONS |-----
local function vecToTable(v3)
    return {x = v3.X, y = v3.Y, z = v3.Z}
end

local function tableToVec(t)
    return Vector3.new(t.x, t.y, t.z)
end

local function lerp(a, b, t)
    return a + (b - a) * t
end

local function lerpVector(a, b, t)
    return Vector3.new(lerp(a.X, b.X, t), lerp(a.Y, b.Y, t), lerp(a.Z, b.Z, t))
end

local function lerpAngle(a, b, t)
    local diff = (b - a)
    while diff > math.pi do diff = diff - 2*math.pi end
    while diff < -math.pi do diff = diff + 2*math.pi end
    return a + diff * t
end

local function calculateHipHeightOffset()
    if not humanoid then return 0 end
    
    currentHipHeight = humanoid.HipHeight
    
    if not recordedHipHeight then
        recordedHipHeight = 2.0
    end
    
    hipHeightOffset = recordedHipHeight - currentHipHeight
    
    return hipHeightOffset
end

local function adjustPositionForAvatarSize(position)
    if hipHeightOffset == 0 then return position end
    
    return Vector3.new(
        position.X,
        position.Y - hipHeightOffset,
        position.Z
    )
end

local function playFootstepSound()
    if not humanoid or not character then return end
    
    pcall(function()
        local hrp = character:FindFirstChild("HumanoidRootPart")
        if not hrp then return end
        
        local rayOrigin = hrp.Position
        local rayDirection = Vector3.new(0, -5, 0)
        local raycastParams = RaycastParams.new()
        raycastParams.FilterDescendantsInstances = {character}
        raycastParams.FilterType = Enum.RaycastFilterType.Exclude
        
        local rayResult = workspace:Raycast(rayOrigin, rayDirection, raycastParams)
        
        if rayResult and rayResult.Instance then
            local sound = Instance.new("Sound")
            sound.Volume = 0.8
            sound.RollOffMaxDistance = 100
            sound.RollOffMinDistance = 10
            
            local soundId = "rbxasset://sounds/action_footsteps_plastic.mp3"
            
            sound.SoundId = soundId
            sound.Parent = hrp
            sound:Play()
            
            game:GetService("Debris"):AddItem(sound, 1)
        end
    end)
end

local function simulateNaturalMovement(moveDirection, velocity)
    if not humanoid or not character then return end
    
    local horizontalVelocity = Vector3.new(velocity.X, 0, velocity.Z)
    local speed = horizontalVelocity.Magnitude
    
    local onGround = false
    pcall(function()
        local state = humanoid:GetState()
        onGround = (state == Enum.HumanoidStateType.Running or 
                   state == Enum.HumanoidStateType.RunningNoPhysics or 
                   state == Enum.HumanoidStateType.Landed)
    end)
    
    if speed > 0.5 and onGround then
        local currentTime = tick()
        
        local speedMultiplier = math.clamp(speed / 16, 0.3, 2)
        local adjustedInterval = footstepInterval / (speedMultiplier * playbackSpeed)
        
        if currentTime - lastFootstepTime >= adjustedInterval then
            playFootstepSound()
            lastFootstepTime = currentTime
            leftFootstep = not leftFootstep
        end
    end
end

local function EnsureJsonFile(fileName)
    local savePath = jsonFolder .. "/" .. fileName
    if isfile(savePath) then return true, savePath end
    local ok, res = pcall(function() return game:HttpGet(baseURL..fileName) end)
    if ok and res and #res > 0 then
        writefile(savePath, res)
        return true, savePath
    end
    return false, nil
end

local function loadCheckpoint(fileName)
    local filePath = jsonFolder .. "/" .. fileName
    
    if not isfile(filePath) then
        warn("File not found:", filePath)
        return nil
    end
    
    local success, result = pcall(function()
        local jsonData = readfile(filePath)
        if not jsonData or jsonData == "" then
            error("Empty file")
        end
        return HttpService:JSONDecode(jsonData)
    end)
    
    if success and result then
        if result[1] and result[1].hipHeight then
            recordedHipHeight = result[1].hipHeight
        end
        return result
    else
        warn("❌ Load error for", fileName, ":", result)
        return nil
    end
end

local function findSurroundingFrames(data, t)
    if #data == 0 then return nil, nil, 0 end
    if t <= data[1].time then return 1, 1, 0 end
    if t >= data[#data].time then return #data, #data, 0 end
    
    local left, right = 1, #data
    while left < right - 1 do
        local mid = math.floor((left + right) / 2)
        if data[mid].time <= t then
            left = mid
        else
            right = mid
        end
    end
    
    local i0, i1 = left, right
    local span = data[i1].time - data[i0].time
    local alpha = span > 0 and math.clamp((t - data[i0].time) / span, 0, 1) or 0
    
    return i0, i1, alpha
end

local function stopPlayback()
    isPlaying = false
    isPaused = false
    pausedTime = 0
    accumulatedTime = 0
    lastPlaybackTime = 0
    lastFootstepTime = 0
    recordedHipHeight = nil
    hipHeightOffset = 0
    isFlipped = false
    currentFlipRotation = CFrame.new()
    if playbackConnection then
        playbackConnection:Disconnect()
        playbackConnection = nil
    end
end

local function startPlayback(data, onComplete)
    if not data or #data == 0 then
        warn("No data to play!")
        if onComplete then onComplete() end
        return
    end
    
    if isPlaying then stopPlayback() end
    
    isPlaying = true
    isPaused = false
    pausedTime = 0
    accumulatedTime = 0
    local playbackStartTime = tick()
    lastPlaybackTime = playbackStartTime
    local lastJumping = false
    
    calculateHipHeightOffset()
    
    if playbackConnection then
        playbackConnection:Disconnect()
        playbackConnection = nil
    end

    local first = data[1]
    if character and character:FindFirstChild("HumanoidRootPart") then
        local hrp = character.HumanoidRootPart
        local firstPos = tableToVec(first.position)
        firstPos = adjustPositionForAvatarSize(firstPos)
        local firstYaw = first.rotation or 0
        local startCFrame = CFrame.new(firstPos) * CFrame.Angles(0, firstYaw, 0)
        hrp.CFrame = startCFrame
        hrp.AssemblyLinearVelocity = Vector3.new(0, 0, 0)
        hrp.AssemblyAngularVelocity = Vector3.new(0, 0, 0)

        if humanoid then
            humanoid:Move(tableToVec(first.moveDirection or {x=0,y=0,z=0}), false)
        end
    end

    playbackConnection = RunService.Heartbeat:Connect(function(deltaTime)
        if not isPlaying then return end
        
        if isPaused then
            if pauseStartTime == 0 then
                pauseStartTime = tick()
            end
            lastPlaybackTime = tick()
            return
        else
            if pauseStartTime > 0 then
                pausedTime = pausedTime + (tick() - pauseStartTime)
                pauseStartTime = 0
                lastPlaybackTime = tick()
            end
        end
        
        if not character or not character:FindFirstChild("HumanoidRootPart") then return end
        if not humanoid or humanoid.Parent ~= character then
            humanoid = character:FindFirstChild("Humanoid")
            calculateHipHeightOffset()
        end
        
        local currentTime = tick()
        local actualDelta = currentTime - lastPlaybackTime
        lastPlaybackTime = currentTime
        
        actualDelta = math.min(actualDelta, 0.1)
        
        accumulatedTime = accumulatedTime + (actualDelta * playbackSpeed)
        
        local totalDuration = data[#data].time
        
        if accumulatedTime > totalDuration then
            local final = data[#data]
            if character and character:FindFirstChild("HumanoidRootPart") then
                local hrp = character.HumanoidRootPart
                local finalPos = tableToVec(final.position)
                finalPos = adjustPositionForAvatarSize(finalPos)
                local finalYaw = final.rotation or 0
                local targetCFrame = CFrame.new(finalPos) * CFrame.Angles(0, finalYaw, 0)
                
                local targetFlipRotation = isFlipped and CFrame.Angles(0, math.pi, 0) or CFrame.new()
                currentFlipRotation = currentFlipRotation:Lerp(targetFlipRotation, FLIP_SMOOTHNESS)
                
                hrp.CFrame = targetCFrame * currentFlipRotation
                if humanoid then
                    humanoid:Move(tableToVec(final.moveDirection or {x=0,y=0,z=0}), false)
                end
            end
            stopPlayback()
            if onComplete then onComplete() end
            return
        end
        
        local i0, i1, alpha = findSurroundingFrames(data, accumulatedTime)
        local f0, f1 = data[i0], data[i1]
        if not f0 or not f1 then return end
        
        local pos0 = tableToVec(f0.position)
        local pos1 = tableToVec(f1.position)
        local vel0 = tableToVec(f0.velocity or {x=0,y=0,z=0})
        local vel1 = tableToVec(f1.velocity or {x=0,y=0,z=0})
        local move0 = tableToVec(f0.moveDirection or {x=0,y=0,z=0})
        local move1 = tableToVec(f1.moveDirection or {x=0,y=0,z=0})
        local yaw0 = f0.rotation or 0
        local yaw1 = f1.rotation or 0
        
        local interpPos = lerpVector(pos0, pos1, alpha)
        interpPos = adjustPositionForAvatarSize(interpPos)
        
        local interpVel = lerpVector(vel0, vel1, alpha)
        local interpMove = lerpVector(move0, move1, alpha)
        local interpYaw = lerpAngle(yaw0, yaw1, alpha)
        
        local hrp = character.HumanoidRootPart
        local targetCFrame = CFrame.new(interpPos) * CFrame.Angles(0, interpYaw, 0)
        
        local targetFlipRotation = isFlipped and CFrame.Angles(0, math.pi, 0) or CFrame.new()
        currentFlipRotation = currentFlipRotation:Lerp(targetFlipRotation, FLIP_SMOOTHNESS)
        
        local lerpFactor = math.clamp(1 - math.exp(-10 * actualDelta), 0, 1)
        hrp.CFrame = hrp.CFrame:Lerp(targetCFrame * currentFlipRotation, lerpFactor)
        
        pcall(function()
            hrp.AssemblyLinearVelocity = interpVel
        end)
        
        if humanoid then
            humanoid:Move(interpMove, false)
        end
        
        simulateNaturalMovement(interpMove, interpVel)
        
        local jumpingNow = f0.jumping or false
        if f1.jumping then jumpingNow = true end
        if jumpingNow and not lastJumping then
            if humanoid then
                humanoid:ChangeState(Enum.HumanoidStateType.Jumping)
            end
        end
        lastJumping = jumpingNow
    end)
end

local function startAutoWalkSequence()
    currentCheckpoint = 0

    local function playNext()
        if not autoLoopEnabled then return end
        
        currentCheckpoint = currentCheckpoint + 1
        if currentCheckpoint > #jsonFiles then
            autoLoopEnabled = false
            Rayfield:Notify({
                Title = "Auto Walk",
                Content = "Semua checkpoint selesai! Auto walk berakhir.",
                Duration = 4,
                Image = "check-check"
            })
            return
        end

        local checkpointFile = jsonFiles[currentCheckpoint]
        local ok, path = EnsureJsonFile(checkpointFile)
        if not ok then
            Rayfield:Notify({
                Title = "Error",
                Content = "Failed to download: " .. checkpointFile,
                Duration = 5,
                Image = "ban"
            })
            autoLoopEnabled = false
            return
        end

        local data = loadCheckpoint(checkpointFile)
        if data and #data > 0 then
            startPlayback(data, playNext)
        else
            Rayfield:Notify({
                Title = "Error",
                Content = "Error loading: " .. checkpointFile,
                Duration = 5,
                Image = "ban"
            })
            autoLoopEnabled = false
        end
    end

    playNext()
end

local function startManualAutoWalkSequence(startCheckpoint)
    currentCheckpoint = startCheckpoint - 1
    isManualMode = true
    autoLoopEnabled = true

    local function walkToStartIfNeeded(data)
        if not character or not character:FindFirstChild("HumanoidRootPart") then
            Rayfield:Notify({
                Title = "Auto Walk (Manual)",
                Content = "Character belum siap (HRP tidak ditemukan).",
                Duration = 3,
                Image = "ban"
            })
            return false
        end

        local hrp = character.HumanoidRootPart
        if not data or not data[1] or not data[1].position then
            return true
        end

        local startPos = tableToVec(data[1].position)
        local distance = (hrp.Position - startPos).Magnitude

        if distance > 100 then
            Rayfield:Notify({
                Title = "Auto Walk (Manual)",
                Content = string.format("Terlalu jauh (%.0f studs). Maks 100 studs untuk memulai.", distance),
                Duration = 4,
                Image = "alert-triangle"
            })
            autoLoopEnabled = false
            isManualMode = false
            return false
        end

        Rayfield:Notify({
            Title = "Auto Walk (Manual)",
            Content = string.format("Menuju titik awal... (%.0f studs)", distance),
            Duration = 3,
            Image = "walk"
        })

        local humanoidLocal = character:FindFirstChildOfClass("Humanoid")
        if not humanoidLocal then
            Rayfield:Notify({
                Title = "Auto Walk (Manual)",
                Content = "Humanoid tidak ditemukan, gagal berjalan.",
                Duration = 3,
                Image = "ban"
            })
            autoLoopEnabled = false
            isManualMode = false
            return false
        end

        local reached = false
        local reachedConnection
        reachedConnection = humanoidLocal.MoveToFinished:Connect(function(r)
            reached = r
            if reachedConnection then
                reachedConnection:Disconnect()
                reachedConnection = nil
            end
        end)

        humanoidLocal:MoveTo(startPos)

        local timeout = 20
        local waited = 0
        while not reached and waited < timeout and autoLoopEnabled do
            task.wait(0.25)
            waited = waited + 0.25
        end

        if reached then
            Rayfield:Notify({
                Title = "Auto Walk (Manual)",
                Content = "Sudah sampai titik awal. Memulai playback...",
                Duration = 2,
                Image = "play"
            })
            return true
        else
            if reachedConnection then
                reachedConnection:Disconnect()
                reachedConnection = nil
            end
            Rayfield:Notify({
                Title = "Auto Walk (Manual)",
                Content = "Gagal mencapai titik awal (timeout atau dibatalkan).",
                Duration = 3,
                Image = "ban"
            })
            autoLoopEnabled = false
            isManualMode = false
            return false
        end
    end

    local function playNext()
        if not autoLoopEnabled then return end

        currentCheckpoint = currentCheckpoint + 1
        if currentCheckpoint > #jsonFiles then
            autoLoopEnabled = false
            isManualMode = false
            Rayfield:Notify({
                Title = "Auto Walk (Manual)",
                Content = "Semua checkpoint selesai! Auto walk berakhir.",
                Duration = 3,
                Image = "check-check"
            })
            return
        end

        local checkpointFile = jsonFiles[currentCheckpoint]
        local ok, path = EnsureJsonFile(checkpointFile)
        if not ok then
            Rayfield:Notify({
                Title = "Error",
                Content = "Failed to download checkpoint",
                Duration = 5,
                Image = "ban"
            })
            autoLoopEnabled = false
            isManualMode = false
            return
        end

        local data = loadCheckpoint(checkpointFile)
        if data and #data > 0 then
            if isManualMode and currentCheckpoint == startCheckpoint then
                local okWalk = walkToStartIfNeeded(data)
                if not okWalk then
                    return
                end
            end
            startPlayback(data, playNext)
        else
            Rayfield:Notify({
                Title = "Error",
                Content = "Error loading: " .. checkpointFile,
                Duration = 5,
                Image = "ban"
            })
            autoLoopEnabled = false
            isManualMode = false
        end
    end

    playNext()
end

local function playSingleCheckpointFile(fileName, checkpointIndex)
    if loopingEnabled then
        stopPlayback()
        startManualAutoWalkSequence(checkpointIndex)
        return
    end

    autoLoopEnabled = false
    isManualMode = false
    stopPlayback()

    local ok, path = EnsureJsonFile(fileName)
    if not ok then
        Rayfield:Notify({
            Title = "Error",
            Content = "Failed to ensure JSON checkpoint",
            Duration = 4,
            Image = "ban"
        })
        return
    end

    local data = loadCheckpoint(fileName)
    if not data or #data == 0 then
        Rayfield:Notify({
            Title = "Error",
            Content = "File invalid / kosong",
            Duration = 4,
            Image = "ban"
        })
        return
    end

    local hrp = character:FindFirstChild("HumanoidRootPart")
    if not hrp then
        Rayfield:Notify({
            Title = "Error",
            Content = "HumanoidRootPart tidak ditemukan!",
            Duration = 4,
            Image = "ban"
        })
        return
    end

    local startPos = tableToVec(data[1].position)
    local distance = (hrp.Position - startPos).Magnitude

    if distance > 100 then
        Rayfield:Notify({
            Title = "Auto Walk (Manual)",
            Content = string.format("Terlalu jauh (%.0f studs)! Harus dalam jarak 100.", distance),
            Duration = 4,
            Image = "alert-triangle"
        })
        return
    end

    Rayfield:Notify({
        Title = "Auto Walk (Manual)",
        Content = string.format("Menuju ke titik awal... (%.0f studs)", distance),
        Duration = 3,
        Image = "walk"
    })

    local humanoid = character:FindFirstChildOfClass("Humanoid")
    local moving = true
    humanoid:MoveTo(startPos)

    local reachedConnection
    reachedConnection = humanoid.MoveToFinished:Connect(function(reached)
        if reached then
            moving = false
            reachedConnection:Disconnect()

            Rayfield:Notify({
                Title = "Auto Walk (Manual)",
                Content = "Sudah sampai di titik awal, mulai playback...",
                Duration = 2,
                Image = "play"
            })

            startPlayback(data, function()
                Rayfield:Notify({
                    Title = "Auto Walk (Manual)",
                    Content = "Auto walk selesai!",
                    Duration = 2,
                    Image = "check-check"
                })
            end)
        else
            Rayfield:Notify({
                Title = "Auto Walk (Manual)",
                Content = "Gagal mencapai titik awal!",
                Duration = 3,
                Image = "ban"
            })
            moving = false
            reachedConnection:Disconnect()
        end
    end)

    task.spawn(function()
        local timeout = 20
        local elapsed = 0
        while moving and elapsed < timeout do
            task.wait(1)
            elapsed += 1
        end
        if moving then
            Rayfield:Notify({
                Title = "Auto Walk (Manual)",
                Content = "Tidak bisa mencapai titik awal (timeout)!",
                Duration = 3,
                Image = "ban"
            })
            humanoid:Move(Vector3.new(0,0,0))
            moving = false
            if reachedConnection then reachedConnection:Disconnect() end
        end
    end)
end

player.CharacterAdded:Connect(function(newChar)
    character = newChar
    humanoid = character:WaitForChild("Humanoid")
    humanoidRootPart = character:WaitForChild("HumanoidRootPart")
    
    if isPlaying then stopPlayback() end
end)

-----| PAUSE/ROTATE UI |-----
local BTN_COLOR = Color3.fromRGB(38, 38, 38)
local BTN_HOVER = Color3.fromRGB(55, 55, 55)
local TEXT_COLOR = Color3.fromRGB(230, 230, 230)

local function createPauseRotateUI()
    local ui = Instance.new("ScreenGui")
    ui.Name = "PauseRotateUI"
    ui.IgnoreGuiInset = true
    ui.ResetOnSpawn = false
    ui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    ui.Parent = CoreGui

    local bgFrame = Instance.new("Frame")
    bgFrame.Name = "PR_Background"
    bgFrame.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
    bgFrame.BackgroundTransparency = 0.4
    bgFrame.BorderSizePixel = 0
    bgFrame.AnchorPoint = Vector2.new(0.5, 0.5)
    bgFrame.Position = UDim2.new(0.5, 0, 0.85, 0)
    bgFrame.Size = UDim2.new(0, 130, 0, 70)
    bgFrame.Visible = false
    bgFrame.Parent = ui

    local bgCorner = Instance.new("UICorner", bgFrame)
    bgCorner.CornerRadius = UDim.new(0, 20)

    local dragIndicator = Instance.new("Frame")
    dragIndicator.Name = "DragIndicator"
    dragIndicator.BackgroundTransparency = 1
    dragIndicator.Position = UDim2.new(0.5, 0, 0, 8)
    dragIndicator.Size = UDim2.new(0, 40, 0, 6)
    dragIndicator.AnchorPoint = Vector2.new(0.5, 0)
    dragIndicator.Parent = bgFrame

    local dotLayout = Instance.new("UIListLayout", dragIndicator)
    dotLayout.FillDirection = Enum.FillDirection.Horizontal
    dotLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
    dotLayout.VerticalAlignment = Enum.VerticalAlignment.Center
    dotLayout.Padding = UDim.new(0, 6)

    for i = 1, 3 do
        local dot = Instance.new("Frame")
        dot.Name = "Dot" .. i
        dot.BackgroundColor3 = Color3.fromRGB(150, 150, 150)
        dot.BackgroundTransparency = 0.3
        dot.BorderSizePixel = 0
        dot.Size = UDim2.new(0, 6, 0, 6)
        dot.Parent = dragIndicator

        local dotCorner = Instance.new("UICorner", dot)
        dotCorner.CornerRadius = UDim.new(1, 0)
    end

    local mainFrame = Instance.new("Frame")
    mainFrame.Name = "PR_Main"
    mainFrame.BackgroundTransparency = 1
    mainFrame.BorderSizePixel = 0
    mainFrame.AnchorPoint = Vector2.new(0.5, 0.5)
    mainFrame.Position = UDim2.new(0.5, 0, 0.6, 0)
    mainFrame.Size = UDim2.new(1, -10, 0, 50)
    mainFrame.Parent = bgFrame

    local dragging = false
    local dragInput, dragStart, startPos
    local UserInputService = game:GetService("UserInputService")

    local function update(input)
        local delta = input.Position - dragStart
        local newPos = UDim2.new(
            startPos.X.Scale,
            startPos.X.Offset + delta.X,
            startPos.Y.Scale,
            startPos.Y.Offset + delta.Y
        )
        bgFrame.Position = newPos
    end

    bgFrame.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = true
            dragStart = input.Position
            startPos = bgFrame.Position

            for i, dot in ipairs(dragIndicator:GetChildren()) do
                if dot:IsA("Frame") then
                    TweenService:Create(dot, TweenInfo.new(0.2, Enum.EasingStyle.Quad), {
                        BackgroundColor3 = Color3.fromRGB(255, 255, 255),
                        BackgroundTransparency = 0
                    }):Play()
                end
            end

            input.Changed:Connect(function()
                if input.UserInputState == Enum.UserInputState.End then
                    dragging = false
                    for i, dot in ipairs(dragIndicator:GetChildren()) do
                        if dot:IsA("Frame") then
                            TweenService:Create(dot, TweenInfo.new(0.2, Enum.EasingStyle.Quad), {
                                BackgroundColor3 = Color3.fromRGB(150, 150, 150),
                                BackgroundTransparency = 0.3
                            }):Play()
                        end
                    end
                end
            end)
        end
    end)

    bgFrame.InputChanged:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
            dragInput = input
        end
    end)

    UserInputService.InputChanged:Connect(function(input)
        if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
            update(input)
        end
    end)

    UserInputService.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            if dragging then
                dragging = false
                for i, dot in ipairs(dragIndicator:GetChildren()) do
                    if dot:IsA("Frame") then
                        TweenService:Create(dot, TweenInfo.new(0.2, Enum.EasingStyle.Quad), {
                            BackgroundColor3 = Color3.fromRGB(150, 150, 150),
                            BackgroundTransparency = 0.3
                        }):Play()
                    end
                end
            end
        end
    end)

    local layout = Instance.new("UIListLayout", mainFrame)
    layout.FillDirection = Enum.FillDirection.Horizontal
    layout.HorizontalAlignment = Enum.HorizontalAlignment.Center
    layout.VerticalAlignment = Enum.VerticalAlignment.Center
    layout.Padding = UDim.new(0, 10)

    local function createButton(emoji, color)
        local btn = Instance.new("TextButton")
        btn.Size = UDim2.new(0, 50, 0, 50)
        btn.BackgroundColor3 = BTN_COLOR
        btn.BackgroundTransparency = 0.1
        btn.TextColor3 = TEXT_COLOR
        btn.Font = Enum.Font.GothamBold
        btn.TextSize = 24
        btn.Text = emoji
        btn.AutoButtonColor = false
        btn.BorderSizePixel = 0
        btn.Parent = mainFrame

        local c = Instance.new("UICorner", btn)
        c.CornerRadius = UDim.new(1, 0)
        
        btn.MouseEnter:Connect(function()
            TweenService:Create(btn, TweenInfo.new(0.12, Enum.EasingStyle.Quad), {
                BackgroundColor3 = BTN_HOVER,
                Size = UDim2.new(0, 54, 0, 54)
            }):Play()
        end)
        btn.MouseLeave:Connect(function()
            TweenService:Create(btn, TweenInfo.new(0.12, Enum.EasingStyle.Quad), {
                BackgroundColor3 = color or BTN_COLOR,
                Size = UDim2.new(0, 50, 0, 50)
            }):Play()
        end)

        return btn
    end

    local pauseResumeBtn = createButton("⏸️", BTN_COLOR)
    local rotateBtn = createButton("🔄", BTN_COLOR)

    local currentlyPaused = false

    local tweenTime = 0.25
    local showScale = 1
    local hideScale = 0

    local function showUI()
        bgFrame.Visible = true
        bgFrame.Size = UDim2.new(0, 130 * hideScale, 0, 70 * hideScale)
        TweenService:Create(bgFrame, TweenInfo.new(tweenTime, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
            Size = UDim2.new(0, 130 * showScale, 0, 70 * showScale)
        }):Play()
    end

    local function hideUI()
        TweenService:Create(bgFrame, TweenInfo.new(tweenTime, Enum.EasingStyle.Back, Enum.EasingDirection.In), {
            Size = UDim2.new(0, 130 * hideScale, 0, 70 * hideScale)
        }):Play()
        task.delay(tweenTime, function()
            bgFrame.Visible = false
        end)
    end

    pauseResumeBtn.MouseButton1Click:Connect(function()
        if not isPlaying then
            Rayfield:Notify({
                Title = "Auto Walk",
                Content = "❌ Tidak ada auto walk yang sedang berjalan!",
                Duration = 3,
                Image = "alert-triangle"
            })
            return
        end

        if not currentlyPaused then
            isPaused = true
            currentlyPaused = true
            pauseResumeBtn.Text = "▶️"
            pauseResumeBtn.BackgroundColor3 = Color3.fromRGB(0, 170, 85)
            Rayfield:Notify({
                Title = "Auto Walk",
                Content = "⏸️ Auto walk dijeda.",
                Duration = 2,
                Image = "pause"
            })
        else
            isPaused = false
            currentlyPaused = false
            pauseResumeBtn.Text = "⏸️"
            pauseResumeBtn.BackgroundColor3 = BTN_COLOR
            Rayfield:Notify({
                Title = "Auto Walk",
                Content = "▶️ Auto walk dilanjutkan.",
                Duration = 2,
                Image = "play"
            })
        end
    end)

    rotateBtn.MouseButton1Click:Connect(function()
        if not isPlaying then
            Rayfield:Notify({
                Title = "Rotate",
                Content = "❌ Auto walk harus berjalan terlebih dahulu!",
                Duration = 3,
                Image = "alert-triangle"
            })
            return
        end

        isFlipped = not isFlipped
        
        if isFlipped then
            rotateBtn.Text = "🔃"
            rotateBtn.BackgroundColor3 = Color3.fromRGB(0, 170, 85)
            Rayfield:Notify({
                Title = "Rotate",
                Content = "🔄 Mode rotate AKTIF (jalan mundur)",
                Duration = 2,
                Image = "rotate-cw"
            })
        else
            rotateBtn.Text = "🔄"
            rotateBtn.BackgroundColor3 = BTN_COLOR
            Rayfield:Notify({
                Title = "Rotate",
                Content = "🔄 Mode rotate NONAKTIF",
                Duration = 2,
                Image = "rotate-ccw"
            })
        end
    end)

    local function resetUIState()
        currentlyPaused = false
        pauseResumeBtn.Text = "⏸️"
        pauseResumeBtn.BackgroundColor3 = BTN_COLOR
        isFlipped = false
        rotateBtn.Text = "🔄"
        rotateBtn.BackgroundColor3 = BTN_COLOR
    end

    return {
        mainFrame = bgFrame,
        showUI = showUI,
        hideUI = hideUI,
        resetUIState = resetUIState
    }
end

local pauseRotateUI = createPauseRotateUI()

local originalStopPlayback = stopPlayback
stopPlayback = function()
    originalStopPlayback()
    pauseRotateUI.resetUIState()
end

-----| AUTO WALK SETTINGS |-----
local Section = AutoWalkTab:CreateSection("Auto Walk (Settings)")

AutoWalkTab:CreateToggle({
    Name = "Pause/Rotate Menu",
    CurrentValue = false,
    Callback = function(Value)
        if Value then
            pauseRotateUI.showUI()
        else
            pauseRotateUI.hideUI()
        end
    end,
})

local SpeedSlider = AutoWalkTab:CreateSlider({
    Name = "⚡ Set Speed",
    Range = {0.5, 0.9},
    Increment = 0.10,
    Suffix = "x Speed",
    CurrentValue = 0.9,
    Callback = function(Value)
        playbackSpeed = Value
    end,
})

-----| AUTO WALK LOOPING |-----
local Section = AutoWalkTab:CreateSection("Auto Walk (Looping)")

AutoWalkTab:CreateToggle({
    Name = "🔄 Enable Looping",
    CurrentValue = false,
    Callback = function(Value)
        loopingEnabled = Value
        if Value then
            Rayfield:Notify({
                Title = "Looping",
                Content = "Fitur looping diaktifkan!",
                Duration = 3,
                Image = "repeat"
            })
        else
            Rayfield:Notify({
                Title = "Looping",
                Content = "Fitur looping dinonaktifkan!",
                Duration = 3,
                Image = "x"
            })
        end
    end,
})

-----| AUTO WALK MANUAL |-----
local Section = AutoWalkTab:CreateSection("Auto Walk (Manual)")

local SCPToggle = AutoWalkTab:CreateToggle({
    Name = "Auto Walk (Spawnpoint)",
    CurrentValue = false,
    Callback = function(Value)
        if Value then
            playSingleCheckpointFile("spawnpoint.json", 1)
        else
            autoLoopEnabled = false
            isManualMode = false
            stopPlayback()
        end
    end,
})

local CP1Toggle = AutoWalkTab:CreateToggle({
    Name = "Auto Walk (Checkpoint 1)",
    CurrentValue = false,
    Callback = function(Value)
        if Value then
            playSingleCheckpointFile("checkpoint_1.json", 2)
        else
            autoLoopEnabled = false
            isManualMode = false
            stopPlayback()
        end
    end,
})

local CP2Toggle = AutoWalkTab:CreateToggle({
    Name = "Auto Walk (Checkpoint 2)",
    CurrentValue = false,
    Callback = function(Value)
        if Value then
            playSingleCheckpointFile("checkpoint_2.json", 3)
        else
            autoLoopEnabled = false
            isManualMode = false
            stopPlayback()
        end
    end,
})

local CP4Toggle = AutoWalkTab:CreateToggle({
    Name = "Auto Walk (Checkpoint 4)",
    CurrentValue = false,
    Callback = function(Value)
        if Value then
            playSingleCheckpointFile("checkpoint_4.json", 4)
        else
            autoLoopEnabled = false
            isManualMode = false
            stopPlayback()
        end
    end,
})

local CP8Toggle = AutoWalkTab:CreateToggle({
    Name = "Auto Walk (Checkpoint 8)",
    CurrentValue = false,
    Callback = function(Value)
        if Value then
            playSingleCheckpointFile("checkpoint_8.json", 5)
        else
            autoLoopEnabled = false
            isManualMode = false
            stopPlayback()
        end
    end,
})

local CP9Toggle = AutoWalkTab:CreateToggle({
    Name = "Auto Walk (Checkpoint 9)",
    CurrentValue = false,
    Callback = function(Value)
        if Value then
            playSingleCheckpointFile("checkpoint_9.json", 6)
        else
            autoLoopEnabled = false
            isManualMode = false
            stopPlayback()
        end
    end,
})

local CP10Toggle = AutoWalkTab:CreateToggle({
    Name = "Auto Walk (Checkpoint 10)",
    CurrentValue = false,
    Callback = function(Value)
        if Value then
            playSingleCheckpointFile("checkpoint_10.json", 7)
        else
            autoLoopEnabled = false
            isManualMode = false
            stopPlayback()
        end
    end,
})

local CP11Toggle = AutoWalkTab:CreateToggle({
    Name = "Auto Walk (Checkpoint 11)",
    CurrentValue = false,
    Callback = function(Value)
        if Value then
            playSingleCheckpointFile("checkpoint_11.json", 8)
        else
            autoLoopEnabled = false
            isManualMode = false
            stopPlayback()
        end
    end,
})

local CP17Toggle = AutoWalkTab:CreateToggle({
    Name = "Auto Walk (Checkpoint 17)",
    CurrentValue = false,
    Callback = function(Value)
        if Value then
            playSingleCheckpointFile("checkpoint_17.json", 9)
        else
            autoLoopEnabled = false
            isManualMode = false
            stopPlayback()
        end
    end,
})

local CP19Toggle = AutoWalkTab:CreateToggle({
    Name = "Auto Walk (Checkpoint 19)",
    CurrentValue = false,
    Callback = function(Value)
        if Value then
            playSingleCheckpointFile("checkpoint_19.json", 10)
        else
            autoLoopEnabled = false
            isManualMode = false
            stopPlayback()
        end
    end,
})

local CP21Toggle = AutoWalkTab:CreateToggle({
    Name = "Auto Walk (Checkpoint 21)",
    CurrentValue = false,
    Callback = function(Value)
        if Value then
            playSingleCheckpointFile("checkpoint_21.json", 11)
        else
            autoLoopEnabled = false
            isManualMode = false
            stopPlayback()
        end
    end,
})

local CP24Toggle = AutoWalkTab:CreateToggle({
    Name = "Auto Walk (Checkpoint 24)",
    CurrentValue = false,
    Callback = function(Value)
        if Value then
            playSingleCheckpointFile("checkpoint_24.json", 12)
        else
            autoLoopEnabled = false
            isManualMode = false
            stopPlayback()
        end
    end,
})

local CP25Toggle = AutoWalkTab:CreateToggle({
    Name = "Auto Walk (Checkpoint 25)",
    CurrentValue = false,
    Callback = function(Value)
        if Value then
            playSingleCheckpointFile("checkpoint_25.json", 13)
        else
            autoLoopEnabled = false
            isManualMode = false
            stopPlayback()
        end
    end,
})

local CP26Toggle = AutoWalkTab:CreateToggle({
    Name = "Auto Walk (Checkpoint 26)",
    CurrentValue = false,
    Callback = function(Value)
        if Value then
            playSingleCheckpointFile("checkpoint_26.json", 14)
        else
            autoLoopEnabled = false
            isManualMode = false
            stopPlayback()
        end
    end,
})

local CP27Toggle = AutoWalkTab:CreateToggle({
    Name = "Auto Walk (Checkpoint 27)",
    CurrentValue = false,
    Callback = function(Value)
        if Value then
            playSingleCheckpointFile("checkpoint_27.json", 15)
        else
            autoLoopEnabled = false
            isManualMode = false
            stopPlayback()
        end
    end,
})

local WaterCPToggle = AutoWalkTab:CreateToggle({
    Name = "Auto Walk (Water Checkpoint)",
    CurrentValue = false,
    Callback = function(Value)
        if Value then
            playSingleCheckpointFile("water_checkpoint.json", 16)
        else
            autoLoopEnabled = false
            isManualMode = false
            stopPlayback()
        end
    end,
})

local CP29Toggle = AutoWalkTab:CreateToggle({
    Name = "Auto Walk (Checkpoint 29)",
    CurrentValue = false,
    Callback = function(Value)
        if Value then
            playSingleCheckpointFile("checkpoint_29.json", 17)
        else
            autoLoopEnabled = false
            isManualMode = false
            stopPlayback()
        end
    end,
})

local CP32Toggle = AutoWalkTab:CreateToggle({
    Name = "Auto Walk (Checkpoint 32)",
    CurrentValue = false,
    Callback = function(Value)
        if Value then
            playSingleCheckpointFile("checkpoint_32.json", 18)
        else
            autoLoopEnabled = false
            isManualMode = false
            stopPlayback()
        end
    end,
})

local CP34Toggle = AutoWalkTab:CreateToggle({
    Name = "Auto Walk (Checkpoint 34)",
    CurrentValue = false,
    Callback = function(Value)
        if Value then
            playSingleCheckpointFile("checkpoint_34.json", 19)
        else
            autoLoopEnabled = false
            isManualMode = false
            stopPlayback()
        end
    end,
})

local CP35Toggle = AutoWalkTab:CreateToggle({
    Name = "Auto Walk (Checkpoint 35)",
    CurrentValue = false,
    Callback = function(Value)
        if Value then
            playSingleCheckpointFile("checkpoint_35.json", 20)
        else
            autoLoopEnabled = false
            isManualMode = false
            stopPlayback()
        end
    end,
})

local CP36Toggle = AutoWalkTab:CreateToggle({
    Name = "Auto Walk (Checkpoint 36)",
    CurrentValue = false,
    Callback = function(Value)
        if Value then
            playSingleCheckpointFile("checkpoint_36.json", 21)
        else
            autoLoopEnabled = false
            isManualMode = false
            stopPlayback()
        end
    end,
})

local CP37Toggle = AutoWalkTab:CreateToggle({
    Name = "Auto Walk (Checkpoint 37)",
    CurrentValue = false,
    Callback = function(Value)
        if Value then
            playSingleCheckpointFile("checkpoint_37.json", 22)
        else
            autoLoopEnabled = false
            isManualMode = false
            stopPlayback()
        end
    end,
})

local CP38Toggle = AutoWalkTab:CreateToggle({
    Name = "Auto Walk (Checkpoint 38)",
    CurrentValue = false,
    Callback = function(Value)
        if Value then
            playSingleCheckpointFile("checkpoint_38.json", 23)
        else
            autoLoopEnabled = false
            isManualMode = false
            stopPlayback()
        end
    end,
})

local CP39Toggle = AutoWalkTab:CreateToggle({
    Name = "Auto Walk (Checkpoint 39)",
    CurrentValue = false,
    Callback = function(Value)
        if Value then
            playSingleCheckpointFile("checkpoint_39.json", 24)
        else
            autoLoopEnabled = false
            isManualMode = false
            stopPlayback()
        end
    end,
})

local CP40Toggle = AutoWalkTab:CreateToggle({
    Name = "Auto Walk (Checkpoint 40)",
    CurrentValue = false,
    Callback = function(Value)
        if Value then
            playSingleCheckpointFile("checkpoint_40.json", 25)
        else
            autoLoopEnabled = false
            isManualMode = false
            stopPlayback()
        end
    end,
})

local CP42Toggle = AutoWalkTab:CreateToggle({
    Name = "Auto Walk (Checkpoint 42)",
    CurrentValue = false,
    Callback = function(Value)
        if Value then
            playSingleCheckpointFile("checkpoint_42.json", 26)
        else
            autoLoopEnabled = false
            isManualMode = false
            stopPlayback()
        end
    end,
})

local CP43Toggle = AutoWalkTab:CreateToggle({
    Name = "Auto Walk (Checkpoint 43)",
    CurrentValue = false,
    Callback = function(Value)
        if Value then
            playSingleCheckpointFile("checkpoint_43.json", 27)
        else
            autoLoopEnabled = false
            isManualMode = false
            stopPlayback()
        end
    end,
})

-----| VISUAL - TIME MENU |-----
local VisualSection = VisualTab:CreateSection("Time Menu")

local Lighting = game:GetService("Lighting")

local TimeSlider = VisualTab:CreateSlider({
   Name = "🕒 Time Changer",
   Range = {0, 24},
   Increment = 1,
   Suffix = "Hours",
   CurrentValue = Lighting.ClockTime,
   Callback = function(Value)
       Lighting.ClockTime = Value

       if Value >= 6 and Value < 18 then
           Lighting.Brightness = 2
           Lighting.OutdoorAmbient = Color3.fromRGB(200, 200, 200)
       else
           Lighting.Brightness = 0.5
           Lighting.OutdoorAmbient = Color3.fromRGB(50, 50, 100)
       end
   end,
})

-----| CREDITS |-----
local Section = CreditsTab:CreateSection("Credits List")

CreditsTab:CreateLabel("UI: Rayfield Interface")
CreditsTab:CreateLabel("Dev: RullzsyHUB")
CreditsTab:CreateLabel("Modified By: Community")

-----| FINALIZE |-----
Rayfield:Notify({
    Title = "Welcome",
    Content = "RullzsyHUB SIBUATAN loaded successfully!",
    Duration = 5,
    Image = "check-check"
})
