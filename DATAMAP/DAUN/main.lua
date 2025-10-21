
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
    Title = "AstrionHUB | MOUNT DAUN",
    Author = "by Jinho",
    Folder = "AstrionHUB_MountDaun",
    
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

-------------------------------------------------------------
-- IMPORT
-------------------------------------------------------------
local player = Players.LocalPlayer
local character = player.Character or player.CharacterAdded:Wait()
local humanoid = character:WaitForChild("Humanoid")
local humanoidRootPart = character:WaitForChild("HumanoidRootPart")

-------------------------------------------------------------
-- TAB SECTIONS
-------------------------------------------------------------
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
-- AUTO WALK TAB
-------------------------------------------------------------
local AutoWalkTab = AutoWalkSection:Tab({
    Title = "Auto Walk",
    Icon = "bot"
})

-----| AUTO WALK VARIABLES |-----
local mainFolder = "AstrionHUB"
local jsonFolder = mainFolder .. "/js_mount_daun"
if not isfolder(mainFolder) then
    makefolder(mainFolder)
end
if not isfolder(jsonFolder) then
    makefolder(jsonFolder)
end

local baseURL = "https://raw.githubusercontent.com/RullzsyHUB/roblox-scripts-json/refs/heads/main/json_mount_daun/"
local jsonFiles = {
    "spawnpoint.json",
    "checkpoint_1.json",
    "checkpoint_2.json",
    "checkpoint_3.json",
    "checkpoint_4.json",
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
                hrp.CFrame = targetCFrame
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
        
        local lerpFactor = math.clamp(1 - math.exp(-10 * actualDelta), 0, 1)
        hrp.CFrame = hrp.CFrame:Lerp(targetCFrame, lerpFactor)
        
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
        Max = 1.0,
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

local checkpoints = {
    {name = "Spawnpoint", file = "spawnpoint.json", index = 1},
    {name = "Checkpoint 1", file = "checkpoint_1.json", index = 2},
    {name = "Checkpoint 2", file = "checkpoint_2.json", index = 3},
    {name = "Checkpoint 3", file = "checkpoint_3.json", index = 4},
    {name = "Checkpoint 4", file = "checkpoint_4.json", index = 5},
}

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
-- PAUSE/RESUME UI
-------------------------------------------------------------
local BTN_COLOR = Color3.fromRGB(38, 38, 38)
local BTN_HOVER = Color3.fromRGB(55, 55, 55)
local TEXT_COLOR = Color3.fromRGB(230, 230, 230)
local SUCCESS_COLOR = Color3.fromRGB(0, 170, 85)

local function createPauseResumeUI()
    local ui = Instance.new("ScreenGui")
    ui.Name = "PauseResumeUI"
    ui.IgnoreGuiInset = true
    ui.ResetOnSpawn = false
    ui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    ui.Parent = CoreGui

    local mainFrame = Instance.new("Frame")
    mainFrame.Name = "PR_Main"
    mainFrame.BackgroundTransparency = 1
    mainFrame.BorderSizePixel = 0
    mainFrame.AnchorPoint = Vector2.new(0.5, 1)
    mainFrame.Position = UDim2.new(0.5, 0, 1, -120)
    mainFrame.AutomaticSize = Enum.AutomaticSize.XY
    mainFrame.Visible = false
    mainFrame.Parent = ui

    local layout = Instance.new("UIListLayout", mainFrame)
    layout.FillDirection = Enum.FillDirection.Horizontal
    layout.HorizontalAlignment = Enum.HorizontalAlignment.Center
    layout.VerticalAlignment = Enum.VerticalAlignment.Center
    layout.Padding = UDim.new(0, 10)

    local function createButton(text, icon)
        local btn = Instance.new("TextButton")
        btn.Size = UDim2.new(0, 110, 0, 34)
        btn.BackgroundColor3 = BTN_COLOR
        btn.BackgroundTransparency = 0.1
        btn.TextColor3 = TEXT_COLOR
        btn.Font = Enum.Font.GothamBold
        btn.TextSize = 14
        btn.Text = icon .. "  " .. text
        btn.AutoButtonColor = false
        btn.BorderSizePixel = 0
        btn.Parent = mainFrame

        local c = Instance.new("UICorner", btn)
        c.CornerRadius = UDim.new(0, 8)

        btn.MouseEnter:Connect(function()
            TweenService:Create(btn, TweenInfo.new(0.12, Enum.EasingStyle.Quad), {BackgroundColor3 = BTN_HOVER}):Play()
        end)
        btn.MouseLeave:Connect(function()
            TweenService:Create(btn, TweenInfo.new(0.12, Enum.EasingStyle.Quad), {BackgroundColor3 = BTN_COLOR}):Play()
        end)

        return btn
    end

    local pauseBtn = createButton("PAUSE", "⏸️")
    local resumeBtn = createButton("RESUME", "▶️")

    local tweenTime = 0.3
    local finalYOffset = -120
    local hiddenYOffset = 20

    local function showUI()
        mainFrame.Position = UDim2.new(0.5, 0, 1, hiddenYOffset)
        mainFrame.Visible = true
        TweenService:Create(mainFrame, TweenInfo.new(tweenTime, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
            Position = UDim2.new(0.5, 0, 1, finalYOffset)
        }):Play()
    end

    local function hideUI()
        TweenService:Create(mainFrame, TweenInfo.new(tweenTime, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {
            Position = UDim2.new(0.5, 0, 1, hiddenYOffset)
        }):Play()
        task.delay(tweenTime, function()
            mainFrame.Visible = false
        end)
    end

    pauseBtn.MouseButton1Click:Connect(function()
        if not isPlaying then
            WindUI:Notify({Title = "Auto Walk", Content = "Tidak ada auto walk yang sedang berjalan.", Icon = "alert-triangle"})
            return
        end
        if not isPaused then
            isPaused = true
            WindUI:Notify({Title = "Auto Walk", Content = "Auto walk dijeda.", Icon = "pause"})
        end
    end)

    resumeBtn.MouseButton1Click:Connect(function()
        if not isPlaying then
            WindUI:Notify({Title = "Auto Walk", Content = "Tidak ada auto walk yang sedang berjalan.", Icon = "alert-triangle"})
            return
        end
        if isPaused then
            isPaused = false
            WindUI:Notify({Title = "Auto Walk", Content = "Auto walk dilanjutkan.", Icon = "play"})
        end
    end)

    return {
        mainFrame = mainFrame,
        showUI = showUI,
        hideUI = hideUI
    }
end

local pauseResumeUI = createPauseResumeUI()

AutoWalkTab:Space()

AutoWalkTab:Toggle({
    Flag = "PauseResumeMenu",
    Title = "Pause/Resume Menu",
    Desc = "Show floating pause and resume buttons",
    Default = false,
    Callback = function(Value)
        if Value then
            pauseResumeUI.showUI()
        else
            pauseResumeUI.hideUI()
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
    Content = "Mount Daun script loaded successfully!",
    Icon = "check",
    Duration = 5
})
