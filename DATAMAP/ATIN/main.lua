
-------------------------------------------------------------
-- LOAD LIBRARY UI (WindUI)
-------------------------------------------------------------
local WindUI

do
    local ok, result = pcall(function()
        return require("./src/Init")
    end)
    
    if ok then
        WindUI = result
    else 
        WindUI = loadstring(game:HttpGet("https://github.com/Footagesus/WindUI/releases/latest/download/main.lua"))()
    end
end

-------------------------------------------------------------
-- WINDOW PROCESS
-------------------------------------------------------------
local Window = WindUI:CreateWindow({
    Title = "AstrionHUB | MOUNT ATIN",
    Author = "by Jinho",
    Folder = "AstrionHUB_MountAtin",
    
    OpenButton = {
        Title = "Open AstrionHUB",
        CornerRadius = UDim.new(0.5, 0),
        StrokeThickness = 2,
        Enabled = true,
        Draggable = true,
        OnlyMobile = false,
        Color = ColorSequence.new(
            Color3.fromHex("#9333EA"), 
            Color3.fromHex("#C026D3")
        )
    }
})

-------------------------------------------------------------
-- SERVICES
-------------------------------------------------------------
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local HttpService = game:GetService("HttpService")
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
-- TAB SECTIONS
-------------------------------------------------------------
local BypassSection = Window:Section({
    Title = "Bypass",
})

local AutoWalkSection = Window:Section({
    Title = "Auto Walk",
})

local VisualSection = Window:Section({
    Title = "Visual",
})

local UpdateSection = Window:Section({
    Title = "Update",
})

local CommunitySection = Window:Section({
    Title = "Community",
})

-------------------------------------------------------------
-- BYPASS TAB
-------------------------------------------------------------
local BypassTab = BypassSection:Tab({
    Title = "Bypass",
    Icon = "shield"
})

-- =============================================================
-- BYPASS AFK
-- =============================================================
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

BypassTab:Toggle({
    Flag = "AntiIdleToggle",
    Title = "Bypass AFK",
    Desc = "Bypass anti-AFK detection",
    Default = false,
    Callback = function(Value)
        getgenv().AntiIdleActive = Value
        if Value then
            StartAntiIdle()
            WindUI:Notify({
                Title = "Bypass AFK",
                Content = "Bypass AFK diaktifkan",
                Icon = "shield"
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
            WindUI:Notify({
                Title = "Bypass AFK",
                Content = "Bypass AFK dinonaktifkan",
                Icon = "shield-off"
            })
        end
    end,
})

-------------------------------------------------------------
-- AUTO WALK TAB
-------------------------------------------------------------
local AutoWalkTab = AutoWalkSection:Tab({
    Title = "Auto Walk",
    Icon = "bot"
})

-----| AUTO WALK VARIABLES |-----
local mainFolder = "AstrionHUB"
local jsonFolder = mainFolder .. "/js_mount_atin_patch_001"
if not isfolder(mainFolder) then
    makefolder(mainFolder)
end
if not isfolder(jsonFolder) then
    makefolder(jsonFolder)
end

local baseURL = "https://raw.githubusercontent.com/RullzsyHUB/roblox-scripts-json/refs/heads/main/json_mount_atin/"
local jsonFiles = {
    "spawnpoint.json",
    "checkpoint_1.json",
    "checkpoint_2.json",
    "checkpoint_3.json",
    "checkpoint_4.json",
    "checkpoint_5.json",
    "checkpoint_6.json",
    "checkpoint_7.json",
    "checkpoint_8.json",
    "checkpoint_9.json",
    "checkpoint_10.json",
    "checkpoint_11.json",
    "checkpoint_12.json",
    "checkpoint_13.json",
    "checkpoint_14.json",
    "checkpoint_15.json",
    "checkpoint_16.json",
    "checkpoint_17.json",
    "checkpoint_18.json",
    "checkpoint_19.json",
    "checkpoint_20.json",
    "checkpoint_21.json",
    "checkpoint_22.json",
    "checkpoint_23.json",
    "checkpoint_24.json",
    "checkpoint_25.json",
    "checkpoint_26.json",
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
local playbackSpeed = 1.0
local lastFootstepTime = 0
local footstepInterval = 0.35
local leftFootstep = true
local isFlipped = false
local FLIP_SMOOTHNESS = 0.05
local currentFlipRotation = CFrame.new()
local noDamageEnabled = false

-------------------------------------------------------------
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
            sound.SoundId = "rbxasset://sounds/action_footsteps_plastic.mp3"
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

local function playSingleCheckpointFile(fileName, checkpointIndex)
    if loopingEnabled then
        stopPlayback()
        -- Start from checkpoint with looping
        currentCheckpoint = checkpointIndex - 1
        isManualMode = true
        autoLoopEnabled = true
        
        local function playNext()
            if not autoLoopEnabled then return end
            
            currentCheckpoint = currentCheckpoint + 1
            if currentCheckpoint > #jsonFiles then
                autoLoopEnabled = false
                isManualMode = false
                WindUI:Notify({
                    Title = "Auto Walk",
                    Content = "Semua checkpoint selesai!",
                    Icon = "check"
                })
                return
            end

            local checkpointFile = jsonFiles[currentCheckpoint]
            local ok, path = EnsureJsonFile(checkpointFile)
            if not ok then
                WindUI:Notify({
                    Title = "Error",
                    Content = "Failed to download checkpoint",
                    Icon = "alert-triangle"
                })
                autoLoopEnabled = false
                isManualMode = false
                return
            end

            local data = loadCheckpoint(checkpointFile)
            if data and #data > 0 then
                startPlayback(data, playNext)
            else
                WindUI:Notify({
                    Title = "Error",
                    Content = "Error loading: " .. checkpointFile,
                    Icon = "alert-triangle"
                })
                autoLoopEnabled = false
                isManualMode = false
            end
        end
        
        playNext()
        return
    end

    autoLoopEnabled = false
    isManualMode = false
    stopPlayback()

    local ok, path = EnsureJsonFile(fileName)
    if not ok then
        WindUI:Notify({
            Title = "Error",
            Content = "Failed to ensure JSON checkpoint",
            Icon = "alert-triangle"
        })
        return
    end

    local data = loadCheckpoint(fileName)
    if not data or #data == 0 then
        WindUI:Notify({
            Title = "Error",
            Content = "File invalid / kosong",
            Icon = "alert-triangle"
        })
        return
    end

    local hrp = character:FindFirstChild("HumanoidRootPart")
    if not hrp then
        WindUI:Notify({
            Title = "Error",
            Content = "HumanoidRootPart tidak ditemukan!",
            Icon = "alert-triangle"
        })
        return
    end

    local startPos = tableToVec(data[1].position)
    local distance = (hrp.Position - startPos).Magnitude

    if distance > 100 then
        WindUI:Notify({
            Title = "Auto Walk (Manual)",
            Content = string.format("Terlalu jauh (%.0f studs)! Harus dalam jarak 100.", distance),
            Icon = "alert-triangle"
        })
        return
    end

    WindUI:Notify({
        Title = "Auto Walk (Manual)",
        Content = string.format("Menuju ke titik awal... (%.0f studs)", distance),
        Icon = "navigation"
    })

    local humanoidLocal = character:FindFirstChildOfClass("Humanoid")
    local moving = true
    humanoidLocal:MoveTo(startPos)

    local reachedConnection
    reachedConnection = humanoidLocal.MoveToFinished:Connect(function(reached)
        if reached then
            moving = false
            reachedConnection:Disconnect()

            WindUI:Notify({
                Title = "Auto Walk (Manual)",
                Content = "Sudah sampai di titik awal, mulai playback...",
                Icon = "play"
            })

            startPlayback(data, function()
                WindUI:Notify({
                    Title = "Auto Walk (Manual)",
                    Content = "Auto walk selesai!",
                    Icon = "check"
                })
            end)
        else
            WindUI:Notify({
                Title = "Auto Walk (Manual)",
                Content = "Gagal mencapai titik awal!",
                Icon = "x"
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
            WindUI:Notify({
                Title = "Auto Walk (Manual)",
                Content = "Tidak bisa mencapai titik awal (timeout)!",
                Icon = "alert-triangle"
            })
            humanoidLocal:Move(Vector3.new(0,0,0))
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

-------------------------------------------------------------
-- AUTO WALK UI
-------------------------------------------------------------
AutoWalkTab:Slider({
    Flag = "SpeedSlider",
    Title = "⚡ Set Speed",
    Step = 0.1,
    Value = {
        Min = 0.5,
        Max = 1.2,
        Default = 1.0,
    },
    Callback = function(Value)
        playbackSpeed = Value
    end
})

AutoWalkTab:Space()

AutoWalkTab:Toggle({
    Flag = "LoopingToggle",
    Title = "🔄 Enable Looping",
    Desc = "Enable auto loop dari checkpoint terpilih",
    Default = false,
    Callback = function(Value)
        loopingEnabled = Value
        
        if Value then
            WindUI:Notify({
                Title = "Looping",
                Content = "Fitur looping diaktifkan!",
                Icon = "repeat"
            })
        else
            WindUI:Notify({
                Title = "Looping",
                Content = "Fitur looping dinonaktifkan!",
                Icon = "x"
            })
        end
    end,
})

AutoWalkTab:Space()

-- Create all checkpoint toggles
local checkpoints = {
    {name = "Spawnpoint", file = "spawnpoint.json", index = 1},
}

for i = 1, 26 do
    table.insert(checkpoints, {
        name = "Checkpoint " .. i,
        file = "checkpoint_" .. i .. ".json",
        index = i + 1
    })
end

for _, cp in ipairs(checkpoints) do
    AutoWalkTab:Toggle({
        Flag = cp.name .. "Toggle",
        Title = "Auto Walk (" .. cp.name .. ")",
        Default = false,
        Callback = function(Value)
            if Value then
                playSingleCheckpointFile(cp.file, cp.index)
            else
                autoLoopEnabled = false
                isManualMode = false
                stopPlayback()
            end
        end,
    })
end

-------------------------------------------------------------
-- PAUSE/ROTATE UI
-------------------------------------------------------------
local BTN_COLOR = Color3.fromRGB(38, 38, 38)
local BTN_HOVER = Color3.fromRGB(55, 55, 55)
local TEXT_COLOR = Color3.fromRGB(230, 230, 230)
local SUCCESS_COLOR = Color3.fromRGB(0, 170, 85)

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
            startPos.X.Offset + delta.X
            
,
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
            WindUI:Notify({
                Title = "Auto Walk",
                Content = "❌ Tidak ada auto walk yang sedang berjalan!",
                Icon = "alert-triangle"
            })
            return
        end

        if not currentlyPaused then
            isPaused = true
            currentlyPaused = true
            pauseResumeBtn.Text = "▶️"
            pauseResumeBtn.BackgroundColor3 = SUCCESS_COLOR
            WindUI:Notify({
                Title = "Auto Walk",
                Content = "⏸️ Auto walk dijeda.",
                Icon = "pause"
            })
        else
            isPaused = false
            currentlyPaused = false
            pauseResumeBtn.Text = "⏸️"
            pauseResumeBtn.BackgroundColor3 = BTN_COLOR
            WindUI:Notify({
                Title = "Auto Walk",
                Content = "▶️ Auto walk dilanjutkan.",
                Icon = "play"
            })
        end
    end)

    rotateBtn.MouseButton1Click:Connect(function()
        if not isPlaying then
            WindUI:Notify({
                Title = "Rotate",
                Content = "❌ Auto walk harus berjalan terlebih dahulu!",
                Icon = "alert-triangle"
            })
            return
        end

        isFlipped = not isFlipped
        
        if isFlipped then
            rotateBtn.Text = "🔃"
            rotateBtn.BackgroundColor3 = SUCCESS_COLOR
            WindUI:Notify({
                Title = "Rotate",
                Content = "🔄 Mode rotate AKTIF (jalan mundur)",
                Icon = "rotate-cw"
            })
        else
            rotateBtn.Text = "🔄"
            rotateBtn.BackgroundColor3 = BTN_COLOR
            WindUI:Notify({
                Title = "Rotate",
                Content = "🔄 Mode rotate NONAKTIF",
                Icon = "rotate-ccw"
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

AutoWalkTab:Space()

AutoWalkTab:Toggle({
    Flag = "PauseRotateMenu",
    Title = "Pause/Rotate Menu",
    Desc = "Show floating pause and rotate buttons",
    Default = false,
    Callback = function(Value)
        if Value then
            pauseRotateUI.showUI()
        else
            pauseRotateUI.hideUI()
        end
    end,
})

-------------------------------------------------------------
-- VISUAL TAB
-------------------------------------------------------------
local VisualTab = VisualSection:Tab({
    Title = "Visual",
    Icon = "layers"
})

local Lighting = game:GetService("Lighting")

VisualTab:Slider({
    Flag = "TimeSlider",
    Title = "🕒 Time Changer",
    Step = 1,
    Value = {
        Min = 0,
        Max = 24,
        Default = Lighting.ClockTime,
    },
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

-------------------------------------------------------------
-- UPDATE SCRIPT TAB
-------------------------------------------------------------
local UpdateTab = UpdateSection:Tab({
    Title = "Update Script",
    Icon = "file"
})

local updateEnabled = false
local stopUpdate = {false}

local StatusLabel = UpdateTab:Section({
    Title = "Pengecekan file...",
})

task.spawn(function()
    for i, f in ipairs(jsonFiles) do
        local ok = EnsureJsonFile(f)
        StatusLabel:Set({
            Title = (ok and "✔ Proses Cek File: " or "❌ Gagal: ").." ("..i.."/"..#jsonFiles..")"
        })
        task.wait(0.5)
    end
    StatusLabel:Set({
        Title = "✔ Semua file aman"
    })
end)

UpdateTab:Space()

UpdateTab:Toggle({
    Flag = "UpdateToggle",
    Title = "Mulai Update Script",
    Desc = "Re-download semua file JSON",
    Default = false,
    Callback = function(state)
        if state then
            updateEnabled = true
            stopUpdate[1] = false
            task.spawn(function()
                StatusLabel:Set({
                    Title = "🔄 Proses update file..."
                })
                
                for _, f in ipairs(jsonFiles) do
                    local savePath = jsonFolder .. "/" .. f
                    if isfile(savePath) then
                        delfile(savePath)
                    end
                end
                
                for i, f in ipairs(jsonFiles) do
                    if stopUpdate[1] then break end
                    
                    WindUI:Notify({
                        Title = "Update Script",
                        Content = "Proses Update " .. " ("..i.."/"..#jsonFiles..")",
                        Icon = "file"
                    })
                    
                    local ok, res = pcall(function() return game:HttpGet(baseURL..f) end)
                    if ok and res and #res > 0 then
                        writefile(jsonFolder.."/"..f, res)
                        StatusLabel:Set({
                            Title = "📥 Proses Update: ".. " ("..i.."/"..#jsonFiles..")"
                        })
                    else
                        WindUI:Notify({
                            Title = "Update Script",
                            Content = "❌ Update script gagal",
                            Icon = "alert-triangle"
                        })
                        StatusLabel:Set({
                            Title = "❌ Gagal: ".. " ("..i.."/"..#jsonFiles..")"
                        })
                    end
                    task.wait(0.3)
                end
                
                if not stopUpdate[1] then
                    WindUI:Notify({
                        Title = "Update Script",
                        Content = "Telah berhasil!",
                        Icon = "check"
                    })
                else
                    WindUI:Notify({
                        Title = "Update Script",
                        Content = "❌ Update canceled",
                        Icon = "x"
                    })
                end
                
                for i, f in ipairs(jsonFiles) do
                    local ok = EnsureJsonFile(f)
                    StatusLabel:Set({
                        Title = (ok and "✔ Cek File: " or "❌ Failed: ").." ("..i.."/"..#jsonFiles..")"
                    })
                    task.wait(0.3)
                end
                StatusLabel:Set({
                    Title = "✔ Semua file aman"
                })
            end)
        else
            updateEnabled = false
            stopUpdate[1] = true
        end
    end,
})

-------------------------------------------------------------
-- DISCORD INTEGRATION
-------------------------------------------------------------
local DiscordTab = CommunitySection:Tab({
    Title = "Discord",
    Icon = "message-circle"
})

local InviteCode = "yQpag5BmH"
local DiscordAPI = "https://discord.com/api/v10/invites/" .. InviteCode .. "?with_counts=true&with_expiration=true"

local function safeRequest(url)
    local success, result = pcall(function()
        return game:HttpGet(url)
    end)
    if success then
        return result
    end
    return nil
end

task.spawn(function()
    local response = safeRequest(DiscordAPI)
    if response then
        local success, data = pcall(function()
            return HttpService:JSONDecode(response)
        end)
        
        if success and data and data.guild then
            DiscordTab:Section({
                Title = "Join our Discord server!",
                TextSize = 20,
            })
            
            DiscordTab:Space()
            
            DiscordTab:Section({
                Title = "Server: " .. tostring(data.guild.name),
                TextSize = 18,
                TextTransparency = 0.2,
            })
            
            DiscordTab:Section({
                Title = tostring(data.guild.description or "No description"),
                TextSize = 14,
                TextTransparency = 0.4,
            })
            
            DiscordTab:Space()
            
            if data.approximate_member_count then
                DiscordTab:Section({
                    Title = "👥 Members: " .. tostring(data.approximate_member_count),
                    TextSize = 14,
                    TextTransparency = 0.3,
                })
            end
            
            if data.approximate_presence_count then
                DiscordTab:Section({
                    Title = "🟢 Online: " .. tostring(data.approximate_presence_count),
                    TextSize = 14,
                    TextTransparency = 0.3,
                })
            end
            
            DiscordTab:Space()
            
            DiscordTab:Button({
                Title = "Copy Discord Link",
                Icon = "link",
                Justify = "Center",
                Callback = function()
                    setclipboard("https://discord.gg/" .. InviteCode)
                    WindUI:Notify({
                        Title = "Discord",
                        Content = "Discord link copied to clipboard!",
                        Icon = "check"
                    })
                end
            })
        else
            DiscordTab:Section({
                Title = "Join our Discord!",
                TextSize = 20,
            })
            
            DiscordTab:Space()
            
            DiscordTab:Button({
                Title = "Copy Discord Link",
                Icon = "link",
                Justify = "Center",
                Callback = function()
                    setclipboard("https://discord.gg/" .. InviteCode)
                    WindUI:Notify({
                        Title = "Discord",
                        Content = "Discord link copied!",
                        Icon = "check"
                    })
                end
            })
        end
    else
        DiscordTab:Section({
            Title = "Failed to load Discord info",
        })
        
        DiscordTab:Space()
        
        DiscordTab:Button({
            Title = "Copy Discord Link",
            Icon = "link",
            Justify = "Center",
            Callback = function()
                setclipboard("https://discord.gg/" .. InviteCode)
                WindUI:Notify({
                    Title = "Discord",
                    Content = "Discord link copied!",
                    Icon = "check"
                })
            end
        })
    end
end)

-------------------------------------------------------------
-- CREDITS
-------------------------------------------------------------
local CreditsTab = CommunitySection:Tab({
    Title = "Credits",
    Icon = "scroll-text"
})

CreditsTab:Section({
    Title = "UI Library",
})

CreditsTab:Section({
    Title = "WindUI by Footagesus (.ftgs)",
    TextSize = 16,
    TextTransparency = 0.3,
})

CreditsTab:Space()

CreditsTab:Section({
    Title = "Developer",
})

CreditsTab:Section({
    Title = "Script by AstrionHUB",
    TextSize = 16,
    TextTransparency = 0.3,
})

CreditsTab:Space()

CreditsTab:Section({
    Title = "Follow Tiktok: @Jinho",
    TextSize = 14,
    TextTransparency = 0.4,
})

-------------------------------------------------------------
-- FINAL NOTIFICATION
-------------------------------------------------------------
WindUI:Notify({
    Title = "AstrionHUB",
    Content = "Mount Atin script loaded successfully!",
    Icon = "check",
    Duration = 5
})
