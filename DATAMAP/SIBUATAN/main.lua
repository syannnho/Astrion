-------------------------------------------------------------
-- LOAD LIBRARY UI
-------------------------------------------------------------
local WindUI = loadstring(game:HttpGet("https://github.com/Footagesus/WindUI/releases/latest/download/main.lua"))()

-------------------------------------------------------------
-- WINDOW PROCESS
-------------------------------------------------------------
local Window = WindUI:CreateWindow({
    Title = "RullzsyHUB | SIBUATAN",
    Author = "Created By RullzsyHUB",
    Folder = "RullzsyHUB",
    NewElements = true,
    HideSearchBar = false,
    OpenButton = {
        Title = "SIBUATAN",
        CornerRadius = UDim.new(1, 0),
        Enabled = true,
        Draggable = true,
    }
})

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
local AccountTab = Window:Tab({
    Title = "Account",
    Icon = "user"
})

local AccountSection = AccountTab:Section({
    Title = "Account Information"
})

AccountSection:Section({
    Title = "Status Akun",
    TextSize = 16,
})

AccountSection:Section({
    Title = "Akun aktif dan siap digunakan.",
    TextSize = 14,
    TextTransparency = 0.3,
})

AccountSection:Space()

AccountSection:Button({
    Title = "Beli/Perpanjang Key",
    Icon = "shopping-cart",
    Color = Color3.fromHex("#3b82f6"),
    Callback = function()
        local discordLink = "https://discord.gg/KEajwZQaRd"
        if setclipboard then
            setclipboard(discordLink)
            WindUI:Notify({
                Title = "Copied!",
                Desc = "Discord link copied to clipboard!",
                Icon = "check"
            })
        end
    end
})

AccountSection:Space()

AccountSection:Section({
    Title = "Info",
    TextSize = 14,
})

AccountSection:Section({
    Title = "Untuk perpanjang key, silahkan buat ticket di Discord.",
    TextSize = 12,
    TextTransparency = 0.4,
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

-------------------------------------------------------------
-- BYPASS TAB
-------------------------------------------------------------
local BypassTab = Window:Tab({
    Title = "Bypass",
    Icon = "shield"
})

local BypassSection = BypassTab:Section({
    Title = "List All Bypass"
})

BypassSection:Toggle({
    Title = "Bypass AFK",
    Desc = "Prevent being kicked for inactivity",
    Default = false,
    Callback = function(Value)
        getgenv().AntiIdleActive = Value
        if Value then
            StartAntiIdle()
            WindUI:Notify({
                Title = "Bypass AFK",
                Desc = "Bypass AFK diaktifkan",
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
                Desc = "Bypass AFK dimatikan",
                Icon = "power"
            })
        end
    end
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
    "spawnpoint.json", "checkpoint_1.json", "checkpoint_2.json", "checkpoint_4.json", "checkpoint_8.json",
    "checkpoint_9.json", "checkpoint_10.json", "checkpoint_11.json", "checkpoint_17.json", "checkpoint_19.json",
    "checkpoint_21.json", "checkpoint_24.json", "checkpoint_25.json", "checkpoint_26.json", "checkpoint_27.json",
    "water_checkpoint.json", "checkpoint_29.json", "checkpoint_32.json", "checkpoint_34.json", "checkpoint_35.json",
    "checkpoint_36.json", "checkpoint_37.json", "checkpoint_38.json", "checkpoint_39.json", "checkpoint_40.json",
    "checkpoint_42.json", "checkpoint_43.json",
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
    return Vector3.new(position.X, position.Y - hipHeightOffset, position.Z)
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
        warn("Load error for", fileName, ":", result)
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
        return
    end
    autoLoopEnabled = false
    isManualMode = false
    stopPlayback()
    local ok, path = EnsureJsonFile(fileName)
    if not ok then
        WindUI:Notify({
            Title = "Error",
            Desc = "Failed to ensure JSON checkpoint",
            Icon = "ban"
        })
        return
    end
    local data = loadCheckpoint(fileName)
    if not data or #data == 0 then
        WindUI:Notify({
            Title = "Error",
            Desc = "File invalid / kosong",
            Icon = "ban"
        })
        return
    end
    local hrp = character:FindFirstChild("HumanoidRootPart")
    if not hrp then
        WindUI:Notify({
            Title = "Error",
            Desc = "HumanoidRootPart tidak ditemukan!",
            Icon = "ban"
        })
        return
    end
    local startPos = tableToVec(data[1].position)
    local distance = (hrp.Position - startPos).Magnitude
    if distance > 100 then
        WindUI:Notify({
            Title = "Auto Walk (Manual)",
            Desc = string.format("Terlalu jauh (%.0f studs)! Harus dalam jarak 100.", distance),
            Icon = "alert-triangle"
        })
        return
    end
    WindUI:Notify({
        Title = "Auto Walk (Manual)",
        Desc = string.format("Menuju ke titik awal... (%.0f studs)", distance),
        Icon = "walk"
    })
    local humanoid = character:FindFirstChildOfClass("Humanoid")
    local moving = true
    humanoid:MoveTo(startPos)
    local reachedConnection
    reachedConnection = humanoid.MoveToFinished:Connect(function(reached)
        if reached then
            moving = false
            reachedConnection:Disconnect()
            WindUI:Notify({
                Title = "Auto Walk (Manual)",
                Desc = "Sudah sampai di titik awal, mulai playback...",
                Icon = "play"
            })
            startPlayback(data, function()
                WindUI:Notify({
                    Title = "Auto Walk (Manual)",
                    Desc = "Auto walk selesai!",
                    Icon = "check"
                })
            end)
        else
            WindUI:Notify({
                Title = "Auto Walk (Manual)",
                Desc = "Gagal mencapai titik awal!",
                Icon = "ban"
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
                Desc = "Tidak bisa mencapai titik awal (timeout)!",
                Icon = "ban"
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

-----| AUTO WALK SETTINGS |-----
local AutoWalkTab = Window:Tab({
    Title = "Auto Walk",
    Icon = "bot"
})

local SettingsSection = AutoWalkTab:Section({
    Title = "Auto Walk (Settings)"
})

SettingsSection:Slider({
    Title = "Set Speed",
    Step = 0.10,
    Value = {
        Min = 0.5,
        Max = 0.9,
        Default = 0.9,
    },
    Callback = function(value)
        playbackSpeed = value
    end
})

-----| AUTO WALK LOOPING |-----
local LoopingSection = AutoWalkTab:Section({
    Title = "Auto Walk (Looping)"
})

LoopingSection:Toggle({
    Title = "Enable Looping",
    Desc = "Loop through all checkpoints",
    Default = false,
    Callback = function(Value)
        loopingEnabled = Value
        if Value then
            WindUI:Notify({
                Title = "Looping",
                Desc = "Fitur looping diaktifkan!",
                Icon = "repeat"
            })
        else
            WindUI:Notify({
                Title = "Looping",
                Desc = "Fitur looping dinonaktifkan!",
                Icon = "x"
            })
        end
    end
})

-----| AUTO WALK MANUAL |-----
local ManualSection = AutoWalkTab:Section({
    Title = "Auto Walk (Manual)"
})

local checkpointButtons = {
    {"Spawnpoint", "spawnpoint.json"},
    {"Checkpoint 1", "checkpoint_1.json"},
    {"Checkpoint 2", "checkpoint_2.json"},
    {"Checkpoint 4", "checkpoint_4.json"},
    {"Checkpoint 8", "checkpoint_8.json"},
    {"Checkpoint 9", "checkpoint_9.json"},
    {"Checkpoint 10", "checkpoint_10.json"},
    {"Checkpoint 11", "checkpoint_11.json"},
    {"Checkpoint 17", "checkpoint_17.json"},
    {"Checkpoint 19", "checkpoint_19.json"},
    {"Checkpoint 21", "checkpoint_21.json"},
    {"Checkpoint 24", "checkpoint_24.json"},
    {"Checkpoint 25", "checkpoint_25.json"},
    {"Checkpoint 26", "checkpoint_26.json"},
    {"Checkpoint 27", "checkpoint_27.json"},
    {"Water Checkpoint", "water_checkpoint.json"},
    {"Checkpoint 29", "checkpoint_29.json"},
    {"Checkpoint 32", "checkpoint_32.json"},
    {"Checkpoint 34", "checkpoint_34.json"},
    {"Checkpoint 35", "checkpoint_35.json"},
    {"Checkpoint 36", "checkpoint_36.json"},
    {"Checkpoint 37", "checkpoint_37.json"},
    {"Checkpoint 38", "checkpoint_38.json"},
    {"Checkpoint 39", "checkpoint_39.json"},
    {"Checkpoint 40", "checkpoint_40.json"},
    {"Checkpoint 42", "checkpoint_42.json"},
    {"Checkpoint 43", "checkpoint_43.json"},
}

for _, checkpoint in ipairs(checkpointButtons) do
    ManualSection:Button({
        Title = "Auto Walk (" .. checkpoint[1] .. ")",
        Icon = "walk",
        Callback = function()
            playSingleCheckpointFile(checkpoint[2], _)
        end
    })
end

-----| VISUAL TAB |-----
local VisualTab = Window:Tab({
    Title = "Visual",
    Icon = "layers"
})

local VisualSection = VisualTab:Section({
    Title = "Time Menu"
})

local Lighting = game:GetService("Lighting")

VisualSection:Slider({
    Title = "Time Changer",
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
    end
})

-----| CREDITS TAB |-----
local CreditsTab = Window:Tab({
    Title = "Credits",
    Icon = "scroll-text"
})

local CreditsSection = CreditsTab:Section({
    Title = "Credits List"
})

CreditsSection:Section({
    Title = "UI Library: WindUI",
    TextSize = 14,
})

CreditsSection:Section({
    Title = "Developer: RullzsyHUB",
    TextSize = 14,
})

CreditsSection:Section({
    Title = "Modified By: Community",
    TextSize = 14,
})

-----| FINALIZE |-----
WindUI:Notify({
    Title = "Welcome",
    Desc = "RullzsyHUB SIBUATAN loaded successfully!",
    Icon = "check"
})
