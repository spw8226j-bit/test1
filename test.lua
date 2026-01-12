-- ========================================
-- NEBULA SOFTWARE MENU
-- ========================================
-- This file demonstrates available features of the Nebula Software Menu
-- Uses DUI (Direct UI) for optimal performance and integration
-- Includes: Playerlist, Theme Switcher, All Menu Types, Notifications, and more!
local dui = nil
local duiTexture = nil
local duiTxd = nil
local activeMenu = {}
local activeIndex = 1
local originalMenu = {}

-- Loading screen variables
local loadingActive = true
local loadingStartTime = GetGameTimer()
local loadingDuration = 12000 -- 12 seconds loading time
local loadingProgress = 0

local keyMap = {
    ["ESC"] = 322, ["F1"] = 288, ["F2"] = 289, ["F3"] = 170, ["F5"] = 166, ["F6"] = 167, ["F7"] = 168, ["F8"] = 169, ["F9"] = 56, ["F10"] = 57, ["F11"] = 288, ["F12"] = 289,
    ["~"] = 243, ["1"] = 157, ["2"] = 158, ["3"] = 160, ["4"] = 164, ["5"] = 165, ["6"] = 159, ["7"] = 161, ["8"] = 162, ["9"] = 163, ["0"] = 157, ["-"] = 84, ["="] = 83, ["BACKSPACE"] = 177,
    ["TAB"] = 37, ["Q"] = 44, ["W"] = 32, ["E"] = 38, ["R"] = 45, ["T"] = 245, ["Y"] = 246, ["U"] = 303, ["I"] = 303, ["O"] = 303, ["P"] = 199, ["["] = 39, ["]"] = 40, ["ENTER"] = 18,
    ["CAPS"] = 137, ["A"] = 34, ["S"] = 8, ["D"] = 9, ["F"] = 23, ["G"] = 47, ["H"] = 74, ["J"] = 74, ["K"] = 311, ["L"] = 182,
    ["LEFTSHIFT"] = 21, ["Z"] = 20, ["X"] = 73, ["C"] = 26, ["V"] = 0, ["B"] = 29, ["N"] = 249, ["M"] = 244, [","] = 82, ["."] = 81, ["/"] = 81,
    ["LEFTCTRL"] = 36, ["LEFTALT"] = 19, ["SPACE"] = 22, ["RIGHTCTRL"] = 70,
    ["HOME"] = 213, ["PAGEUP"] = 10, ["PAGEDOWN"] = 11, ["DELETE"] = 178, ["INSERT"] = 178,
    ["LEFT"] = 174, ["RIGHT"] = 175, ["TOP"] = 27, ["DOWN"] = 173,
    ["NENTER"] = 201, ["N4"] = 108, ["N5"] = 60, ["N6"] = 107, ["N+"] = 96, ["N-"] = 97, ["N7"] = 117, ["N8"] = 61, ["N9"] = 118
}

-- Menu state tracking
local menuInitialized = false
local keybindSetup = false
local menuOpenKey = 178 -- Default to Page Down

-- DUI texture names
local txdName = "NebulaSoftwareTxd"
local txtName = "NebulaSoftwareTex"


-- Available themes
local availableThemes = {
    "purple", "blue", "orange", "pink"
}

-- Player modification state tracking
local playerModStates = {
    infiniteStamina = false
}

-- ESP state tracking
local espActive = false
local espThread = nil
local espSettings = {
    snapLines = true,
    boxes = true,
    skeletons = false,
    wallPenetration = true
}

local playerModThreads = {
    infiniteStamina = nil
}

-- Weapon modification state tracking
local weaponModStates = {
    explosiveAmmo = false,
    rapidFire = false,
    oneShotKill = false,
    noRecoil = false
}

local weaponModThreads = {
    explosiveAmmo = nil,
    rapidFire = nil,
    oneShotKill = nil,
    noRecoil = nil
}

-- Performance monitoring and optimization
local performanceStats = {
    frameCount = 0,
    lastFPSUpdate = 0,
    averageFPS = 60,
    menuOpenTime = 0,
    lastOptimizationCheck = 0
}

-- Cleanup function to reset all modifications
local function cleanupAllModifications()
    -- Reset weapon modifications
    weaponModStates.explosiveAmmo = false
    weaponModStates.rapidFire = false
    weaponModStates.oneShotKill = false
    weaponModStates.noRecoil = false
    
    -- Reset player modifications
    playerModStates.infiniteStamina = false
    
    -- Stop freecam if active
    if freecamActive then
        stopFreecam()
    end
    
    -- Stop ESP if active
    if espActive then
        stopESP()
    end
    
    -- Clear all threads
    weaponModThreads.explosiveAmmo = nil
    weaponModThreads.rapidFire = nil
    weaponModThreads.oneShotKill = nil
    weaponModThreads.noRecoil = nil
    playerModThreads.infiniteStamina = nil
    
    -- Reset weapon damage to normal
    local ped = PlayerPedId()
    local weapon = GetSelectedPedWeapon(ped)
    if weapon ~= GetHashKey('WEAPON_UNARMED') then
        SetWeaponDamageModifier(weapon, 1.0)
        SetPedInfiniteAmmo(ped, false)
        SetPedInfiniteAmmoClip(ped, false)
        SetPedAccuracy(ped, 50)
    end
    
    print("All modifications cleaned up")
end

-- Menu position and transparency settings
local menuPosition = { x = 0.5, y = 0.5 } -- Center position (0.0 to 1.0)
local menuOpacity = 1.0 -- Full opacity (0.0 to 1.0)
local menuScale = 1.0 -- Scale factor (0.5 to 2.0)

-- UI positioning system - separate positioning for different elements
local uiPositions = {
    menu = { x = 0.5, y = 0.5 },      -- Menu position (can be moved)
    notifications = { x = 0.5, y = 0.1 },  -- Fixed notification position (top center)
    playerList = { x = 0.5, y = 0.5 },     -- Player list follows menu
    settings = { x = 0.5, y = 0.5 }        -- Settings follow menu
}

-- Send notification with fixed positioning (notifications stay in place when menu moves)
local function sendFixedNotification(message, type)
    if dui then
        MachoSendDuiMessage(dui, json.encode({
            action = 'notify',
            message = message,
            type = type,
            position = 'fixed',
            fixedPosition = { x = uiPositions.notifications.x, y = uiPositions.notifications.y }
        }))
    end
end

-- Notification system variables
local notificationQueue = {}
local lastNotificationTime = 0
local notificationCooldown = 100 -- Minimum 100ms between notifications

local function sendOptimizedNotification(message, type)
    local currentTime = GetGameTimer()
    
    if currentTime - lastNotificationTime >= notificationCooldown then
        -- Send notification with fixed positioning
        sendFixedNotification(message, type or 'info')
        lastNotificationTime = currentTime
    else
        -- Queue notification if too frequent
        table.insert(notificationQueue, {message = message, type = type})
    end
end

-- Process queued notifications
CreateThread(function()
    while true do
        if #notificationQueue > 0 and GetGameTimer() - lastNotificationTime >= notificationCooldown then
            local notification = table.remove(notificationQueue, 1)
            sendFixedNotification(notification.message, notification.type)
            lastNotificationTime = GetGameTimer()
        end
        Wait(50)
    end
end)

-- Loading screen drawing function
local function drawLoadingScreen()
    if not loadingActive then return end
    
    local currentTime = GetGameTimer()
    local elapsedTime = currentTime - loadingStartTime
    loadingProgress = math.min(elapsedTime / loadingDuration, 1.0)
    
    -- Background overlay
    DrawRect(0.0, 0.0, 2.0, 2.0, 0, 0, 0, 200)
    
    -- Title
    SetTextFont(4)
    SetTextScale(0.8, 0.8)
    SetTextColour(255, 255, 255, 255)
    SetTextCentre(true)
    SetTextEntry("STRING")
    AddTextComponentString("NEBULA SOFTWARE")
    DrawText(0.5, 0.35)
    
    -- Subtitle
    SetTextFont(4)
    SetTextScale(0.4, 0.4)
    SetTextColour(200, 200, 200, 255)
    SetTextCentre(true)
    SetTextEntry("STRING")
    AddTextComponentString("[beta] 1.0.0")
    DrawText(0.5, 0.4)
    
    -- Loading text
    SetTextFont(4)
    SetTextScale(0.3, 0.3)
    SetTextColour(255, 255, 255, 255)
    SetTextCentre(true)
    SetTextEntry("STRING")
    AddTextComponentString("Loading...")
    DrawText(0.5, 0.5)
    
    -- Progress bar background
    DrawRect(0.5, 0.55, 0.4, 0.02, 50, 50, 50, 255)
    
    -- Progress bar fill
    local barWidth = 0.4 * loadingProgress
    DrawRect(0.5 - 0.2 + (barWidth / 2), 0.55, barWidth, 0.02, 0, 150, 255, 255)
    
    -- Progress percentage
    local percentage = math.floor(loadingProgress * 100)
    SetTextFont(4)
    SetTextScale(0.25, 0.25)
    SetTextColour(255, 255, 255, 255)
    SetTextCentre(true)
    SetTextEntry("STRING")
    AddTextComponentString(percentage .. "%")
    DrawText(0.5, 0.58)
    
    -- Loading dots animation
    local dots = ""
    local dotCount = math.floor((currentTime / 500) % 4)
    for i = 1, dotCount do
        dots = dots .. "."
    end
    
    SetTextFont(4)
    SetTextScale(0.25, 0.25)
    SetTextColour(150, 150, 150, 255)
    SetTextCentre(true)
    SetTextEntry("STRING")
    AddTextComponentString("Initializing" .. dots)
    DrawText(0.5, 0.62)
    
    -- Check if loading is complete
    if elapsedTime >= loadingDuration then
        loadingActive = false
        -- Show completion message
        sendOptimizedNotification("Nebula Software <span class=\"notification-key\">[beta] 1.0.0</span> loaded successfully!", 'success')
    end
end

-- Start loading screen thread
CreateThread(function()
    while loadingActive do
        local currentTime = GetGameTimer()
        local elapsedTime = currentTime - loadingStartTime
        loadingProgress = math.min(elapsedTime / loadingDuration, 1.0)
        
        -- Background overlay
        DrawRect(0.0, 0.0, 2.0, 2.0, 0, 0, 0, 200)
        
        -- Title
        SetTextFont(4)
        SetTextScale(0.8, 0.8)
        SetTextColour(255, 255, 255, 255)
        SetTextCentre(true)
        SetTextEntry("STRING")
        AddTextComponentString("NEBULA SOFTWARE")
        DrawText(0.5, 0.35)
        
        -- Subtitle
        SetTextFont(4)
        SetTextScale(0.4, 0.4)
        SetTextColour(200, 200, 200, 255)
        SetTextCentre(true)
        SetTextEntry("STRING")
        AddTextComponentString("[beta] 1.0.0")
        DrawText(0.5, 0.4)
        
        -- Loading text
        SetTextFont(4)
        SetTextScale(0.3, 0.3)
        SetTextColour(255, 255, 255, 255)
        SetTextCentre(true)
        SetTextEntry("STRING")
        AddTextComponentString("Loading...")
        DrawText(0.5, 0.5)
        
        -- Progress bar background
        DrawRect(0.5, 0.55, 0.4, 0.02, 50, 50, 50, 255)
        
        -- Progress bar fill
        local barWidth = 0.4 * loadingProgress
        DrawRect(0.5 - 0.2 + (barWidth / 2), 0.55, barWidth, 0.02, 0, 150, 255, 255)
        
        -- Progress percentage
        local percentage = math.floor(loadingProgress * 100)
        SetTextFont(4)
        SetTextScale(0.25, 0.25)
        SetTextColour(255, 255, 255, 255)
        SetTextCentre(true)
        SetTextEntry("STRING")
        AddTextComponentString(percentage .. "%")
        DrawText(0.5, 0.58)
        
        -- Loading dots animation
        local dots = ""
        local dotCount = math.floor((currentTime / 500) % 4)
        for i = 1, dotCount do
            dots = dots .. "."
        end
        
        SetTextFont(4)
        SetTextScale(0.25, 0.25)
        SetTextColour(150, 150, 150, 255)
        SetTextCentre(true)
        SetTextEntry("STRING")
        AddTextComponentString("Initializing" .. dots)
        DrawText(0.5, 0.62)
        
        -- Check if loading is complete
        if elapsedTime >= loadingDuration then
            loadingActive = false
            -- Show completion message
            sendOptimizedNotification("Nebula Software <span class=\"notification-key\">[beta] 1.0.0</span> loaded successfully!", 'success')
        end
        
        Wait(0)
    end
end)

-- Freecam functions
local function startFreecam()
    if freecamActive then return end
    
    local ped = PlayerPedId()
    local camPos = GetEntityCoords(ped)
    local camRot = GetGameplayCamRot(2)

    freecamCam = CreateCam("DEFAULT_SCRIPTED_CAMERA", true)
    SetCamCoord(freecamCam, camPos)
    SetCamRot(freecamCam, camRot, 2)
    SetCamActive(freecamCam, true)
    RenderScriptCams(true, false, 0, true, true)
    
    -- Freeze player and hide them
    FreezeEntityPosition(ped, true)
    SetEntityVisible(ped, false, false)
    SetEntityCollision(ped, false, false)
    
    freecamActive = true
    
    -- Show control instructions
    sendOptimizedNotification("Freecam Controls:<br><span class=\"notification-key\">WASD</span> - Move camera<br><span class=\"notification-key\">Q/E</span> - Up/Down<br><span class=\"notification-key\">Mouse</span> - Look around<br><span class=\"notification-key\">Shift</span> - Speed boost<br><span class=\"notification-key\">Player frozen</span>", 'info')
    
    -- Freecam control thread
    CreateThread(function()
        while freecamActive do
            if not freecamCam then break end
            
            -- Disable only player movement controls, keep freecam controls enabled
            -- Disable player movement (but keep freecam WASD, QE, Shift, Mouse)
            DisableControlAction(0, 22, true) -- Space (jump)
            DisableControlAction(0, 36, true) -- Ctrl (crouch)
            DisableControlAction(0, 257, true) -- Attack
            DisableControlAction(0, 263, true) -- Melee attack
            DisableControlAction(0, 264, true) -- Melee light attack
            DisableControlAction(0, 140, true) -- Melee attack light
            DisableControlAction(0, 141, true) -- Melee attack heavy
            DisableControlAction(0, 142, true) -- Melee attack alternate
            DisableControlAction(0, 143, true) -- Melee block
            DisableControlAction(0, 75, true) -- Exit vehicle
            DisableControlAction(27, 75, true) -- Exit vehicle
            DisableControlAction(0, 23, true) -- Enter vehicle
            DisableControlAction(0, 47, true) -- Weapon
            DisableControlAction(0, 58, true) -- Weapon
            
            local pos = GetCamCoord(freecamCam)
            local rot = GetCamRot(freecamCam, 2)
            local moveSpeed = freecamSpeed

            if IsControlPressed(0, 21) then moveSpeed = moveSpeed * 3 end

            local heading = math.rad(rot.z)
            local pitch = math.rad(rot.x)
            local camDir = vector3(
                -math.sin(heading) * math.cos(pitch),
                 math.cos(heading) * math.cos(pitch),
                 math.sin(pitch)
            )

            local move = vector3(0, 0, 0)

            if IsControlPressed(0, 32) then -- W forward
                move = move + camDir * moveSpeed
            end
            if IsControlPressed(0, 33) then -- S backward
                move = move - camDir * moveSpeed
            end
            if IsControlPressed(0, 34) then -- A left
                local leftDir = vector3(-camDir.y, camDir.x, 0)
                move = move + leftDir * moveSpeed
            end
            if IsControlPressed(0, 35) then -- D right
                local rightDir = vector3(camDir.y, -camDir.x, 0)
                move = move + rightDir * moveSpeed
            end
            if IsControlPressed(0, 44) then -- Q down
                move = move - vector3(0, 0, moveSpeed)
            end
            if IsControlPressed(0, 38) then -- E up
                move = move + vector3(0, 0, moveSpeed)
            end

            SetCamCoord(freecamCam, pos + move)

            local dx = GetControlNormal(0, 1) * -5.0
            local dy = GetControlNormal(0, 2) * -5.0

            local newRotX = rot.x + dy
            local newRotZ = rot.z + dx
            newRotX = math.max(-89.0, math.min(89.0, newRotX))

            SetCamRot(freecamCam, vector3(newRotX, rot.y, newRotZ), 2)
            
            -- Draw crosshair
            DrawRect(0.5, 0.5, 0.002, 0.02, 255, 255, 255, 255) -- Vertical line
            DrawRect(0.5, 0.5, 0.02, 0.002, 255, 255, 255, 255) -- Horizontal line
            
            Wait(0)
        end
    end)
end

local function stopFreecam()
    if not freecamActive then return end
    
    RenderScriptCams(false, false, 0, true, true)
    DestroyCam(freecamCam, false)
    freecamCam = nil
    
    -- Restore player
    local ped = PlayerPedId()
    FreezeEntityPosition(ped, false)
    SetEntityVisible(ped, true, false)
    SetEntityCollision(ped, true, false)
    
    freecamActive = false
end

-- Helper function to get camera direction vector
function GetCamDirection(rotation)
    local z = math.rad(rotation.z)
    local x = math.rad(rotation.x)
    local num = math.abs(math.cos(x))
    return vector3(-math.sin(z) * num, math.cos(z) * num, math.sin(x))
end

-- Helper function to get camera right vector
function GetCamRightVector(rotation)
    local z = math.rad(rotation.z)
    return vector3(math.cos(z), math.sin(z), 0.0)
end

-- ESP functions
local function RGBRainbow(frequency)
    local result = {}
    local curtime = GetGameTimer() / 1000
    result.r = math.floor(math.sin(curtime * frequency + 0) * 127 + 128)
    result.g = math.floor(math.sin(curtime * frequency + 2) * 127 + 128)
    result.b = math.floor(math.sin(curtime * frequency + 4) * 127 + 128)
    return result
end

local function DrawLineWithCoords(beginCoords, endCoords, r, g, b, a)
    if espSettings.wallPenetration then
        -- Enhanced wall penetration method
        SetDrawOrigin(beginCoords.x, beginCoords.y, beginCoords.z, 0)
        DrawLine(0.0, 0.0, 0.0, endCoords.x - beginCoords.x, endCoords.y - beginCoords.y, endCoords.z - beginCoords.z, r, g, b, a)
        ClearDrawOrigin()
        
        -- Additional line for better wall penetration
        SetDrawOrigin(endCoords.x, endCoords.y, endCoords.z, 0)
        DrawLine(0.0, 0.0, 0.0, beginCoords.x - endCoords.x, beginCoords.y - endCoords.y, beginCoords.z - endCoords.z, r, g, b, a)
        ClearDrawOrigin()
    else
        -- Normal drawing with depth testing
        DrawLine(beginCoords.x, beginCoords.y, beginCoords.z, endCoords.x, endCoords.y, endCoords.z, r, g, b, a)
    end
end

local function GetOffset(ped, offsetX, offsetY, offsetZ)
    return GetOffsetFromEntityInWorldCoords(ped, offsetX, offsetY, offsetZ)
end

local function drawSkeleton(ped, r, g, b)
    -- Real bone IDs for accurate skeleton
    local boneIds = {
        head = 31086,
        neck = 39317,
        spine0 = 24818,
        spine1 = 24817,
        spine2 = 24816,
        spine3 = 24815,
        pelvis = 11816,
        leftShoulder = 18905,
        leftElbow = 57005,
        leftHand = 18905,
        rightShoulder = 40269,
        rightElbow = 28252,
        rightHand = 40269,
        leftHip = 58271,
        leftKnee = 63931,
        leftFoot = 14201,
        rightHip = 51826,
        rightKnee = 14201,
        rightFoot = 14201
    }
    
    -- Get bone position with fallback
    local function getBonePos(boneId, fallbackOffset)
        local coords = GetPedBoneCoords(ped, boneId, 0.0, 0.0, 0.0)
        if coords and coords.x ~= 0 and coords.y ~= 0 and coords.z ~= 0 then
            return coords
        end
        -- Use fallback offset if bone coords fail
        return GetOffsetFromEntityInWorldCoords(ped, fallbackOffset.x, fallbackOffset.y, fallbackOffset.z)
    end
    
    -- Get all bone positions
    local bones = {
        head = getBonePos(boneIds.head, vector3(0.0, 0.0, 0.8)),
        neck = getBonePos(boneIds.neck, vector3(0.0, 0.0, 0.6)),
        spine0 = getBonePos(boneIds.spine0, vector3(0.0, 0.0, 0.4)),
        spine1 = getBonePos(boneIds.spine1, vector3(0.0, 0.0, 0.2)),
        spine2 = getBonePos(boneIds.spine2, vector3(0.0, 0.0, 0.0)),
        spine3 = getBonePos(boneIds.spine3, vector3(0.0, 0.0, -0.1)),
        pelvis = getBonePos(boneIds.pelvis, vector3(0.0, 0.0, -0.2)),
        
        -- Left arm
        leftShoulder = getBonePos(boneIds.leftShoulder, vector3(-0.2, 0.0, 0.5)),
        leftElbow = getBonePos(boneIds.leftElbow, vector3(-0.4, 0.0, 0.3)),
        leftHand = getBonePos(boneIds.leftHand, vector3(-0.6, 0.0, 0.1)),
        
        -- Right arm
        rightShoulder = getBonePos(boneIds.rightShoulder, vector3(0.2, 0.0, 0.5)),
        rightElbow = getBonePos(boneIds.rightElbow, vector3(0.4, 0.0, 0.3)),
        rightHand = getBonePos(boneIds.rightHand, vector3(0.6, 0.0, 0.1)),
        
        -- Left leg
        leftHip = getBonePos(boneIds.leftHip, vector3(-0.1, 0.0, -0.2)),
        leftKnee = getBonePos(boneIds.leftKnee, vector3(-0.1, 0.0, -0.6)),
        leftFoot = getBonePos(boneIds.leftFoot, vector3(-0.1, 0.0, -0.9)),
        
        -- Right leg
        rightHip = getBonePos(boneIds.rightHip, vector3(0.1, 0.0, -0.2)),
        rightKnee = getBonePos(boneIds.rightKnee, vector3(0.1, 0.0, -0.6)),
        rightFoot = getBonePos(boneIds.rightFoot, vector3(0.1, 0.0, -0.9))
    }
    
    -- Draw skeleton connections with enhanced visibility
    local function drawConnection(point1, point2)
        if point1 and point2 then
            -- Draw main line
            DrawLineWithCoords(point1, point2, r, g, b, 255)
            
            -- Draw thicker lines for better visibility through peds
            local offsets = {
                {0.02, 0.0, 0.0}, {-0.02, 0.0, 0.0},
                {0.0, 0.02, 0.0}, {0.0, -0.02, 0.0},
                {0.01, 0.01, 0.0}, {-0.01, -0.01, 0.0}
            }
            
            for _, offset in ipairs(offsets) do
                local offset1 = vector3(point1.x + offset[1], point1.y + offset[2], point1.z + offset[3])
                local offset2 = vector3(point2.x + offset[1], point2.y + offset[2], point2.z + offset[3])
                DrawLineWithCoords(offset1, offset2, r, g, b, 180)
            end
        end
    end
    
    -- Head and spine
    drawConnection(bones.head, bones.neck)
    drawConnection(bones.neck, bones.spine0)
    drawConnection(bones.spine0, bones.spine1)
    drawConnection(bones.spine1, bones.spine2)
    drawConnection(bones.spine2, bones.spine3)
    drawConnection(bones.spine3, bones.pelvis)
    
    -- Left arm
    drawConnection(bones.neck, bones.leftShoulder)
    drawConnection(bones.leftShoulder, bones.leftElbow)
    drawConnection(bones.leftElbow, bones.leftHand)
    
    -- Right arm
    drawConnection(bones.neck, bones.rightShoulder)
    drawConnection(bones.rightShoulder, bones.rightElbow)
    drawConnection(bones.rightElbow, bones.rightHand)
    
    -- Left leg
    drawConnection(bones.pelvis, bones.leftHip)
    drawConnection(bones.leftHip, bones.leftKnee)
    drawConnection(bones.leftKnee, bones.leftFoot)
    
    -- Right leg
    drawConnection(bones.pelvis, bones.rightHip)
    drawConnection(bones.rightHip, bones.rightKnee)
    drawConnection(bones.rightKnee, bones.rightFoot)
end

local function startESP()
    if espActive then return end
    
    espActive = true
    
    espThread = CreateThread(function()
        while espActive do
            -- Use white color instead of rainbow
            local r, g, b = 255, 255, 255
            local playerCoords = GetEntityCoords(PlayerPedId())
            
            -- Debug: Draw a test line to verify colors are working
            if espSettings.boxes or espSettings.snapLines or espSettings.skeletons then
                -- Draw a small test line near player to verify white colors
                local testPos = GetOffsetFromEntityInWorldCoords(PlayerPedId(), 0.0, 0.0, 2.0)
                local testEnd = GetOffsetFromEntityInWorldCoords(PlayerPedId(), 1.0, 0.0, 2.0)
                DrawLineWithCoords(testPos, testEnd, r, g, b, 255)
            end
            
            for _, ped in ipairs(GetGamePool('CPed')) do
                if ped ~= PlayerPedId() then -- Don't draw ESP on yourself
                    local pedCoords = GetEntityCoords(ped)

                    -- Draw 3D boxes if enabled
                    if espSettings.boxes then
                        local offsets = {
                            {-0.3, -0.3, -0.9}, {0.3, -0.3, -0.9}, {0.3, 0.3, -0.9}, {-0.3, 0.3, -0.9},
                            {-0.3, -0.3, 0.8},  {0.3, -0.3, 0.8},  {0.3, 0.3, 0.8},  {-0.3, 0.3, 0.8},
                        }

                        for i = 1, #offsets - 1 do
                            local beginCoords = GetOffset(ped, table.unpack(offsets[i]))
                            local endCoords   = GetOffset(ped, table.unpack(offsets[i + 1]))
                            DrawLineWithCoords(beginCoords, endCoords, r, g, b, 255)
                        end

                        local connectors = {
                            {-0.3, 0.3, 0.8},  {-0.3, 0.3, -0.9},
                            {0.3, 0.3, 0.8},   {0.3, 0.3, -0.9},
                            {-0.3, -0.3, 0.8}, {-0.3, -0.3, -0.9},
                            {0.3, -0.3, 0.8},  {0.3, -0.3, -0.9}
                        }

                        for i = 1, #connectors, 2 do
                            local beginCoords = GetOffset(ped, table.unpack(connectors[i]))
                            local endCoords   = GetOffset(ped, table.unpack(connectors[i + 1]))
                            DrawLineWithCoords(beginCoords, endCoords, r, g, b, 255)
                        end
                    end

                    -- Draw snap lines if enabled
                    if espSettings.snapLines then
                        if espSettings.wallPenetration then
                            -- Enhanced wall penetration for snap lines
                            SetDrawOrigin(playerCoords.x, playerCoords.y, playerCoords.z, 0)
                            DrawLine(0.0, 0.0, 0.0, pedCoords.x - playerCoords.x, pedCoords.y - playerCoords.y, pedCoords.z - playerCoords.z, r, g, b, 255)
                            ClearDrawOrigin()
                            
                            -- Additional line for better wall penetration
                            SetDrawOrigin(pedCoords.x, pedCoords.y, pedCoords.z, 0)
                            DrawLine(0.0, 0.0, 0.0, playerCoords.x - pedCoords.x, playerCoords.y - pedCoords.y, playerCoords.z - pedCoords.z, r, g, b, 255)
                            ClearDrawOrigin()
                        else
                            -- Normal drawing with depth testing
                            DrawLine(playerCoords.x, playerCoords.y, playerCoords.z, pedCoords.x, pedCoords.y, pedCoords.z, r, g, b, 255)
                        end
                    end

                    -- Draw skeleton if enabled
                    if espSettings.skeletons then
                        drawSkeleton(ped, r, g, b)
                    end
                end
            end
            Wait(0)
        end
    end)
end

local function stopESP()
    if not espActive then return end
    
    espActive = false
    if espThread then
        espThread = nil
    end
end

-- Vehicle spawning function
local function spawnVehicle(vehicleName, isAirVehicle)
    local model = GetHashKey(vehicleName)
    RequestModel(model)
    local timeout = 0
    while not HasModelLoaded(model) and timeout < 100 do
        Wait(10)
        timeout = timeout + 1
    end
    
    if HasModelLoaded(model) then
        local coords = GetEntityCoords(PlayerPedId())
        local zOffset = isAirVehicle and 10 or 0
        local vehicle = CreateVehicle(model, coords.x, coords.y, coords.z + zOffset, GetEntityHeading(PlayerPedId()), true, false)
        SetPedIntoVehicle(PlayerPedId(), vehicle, -1)
        SetModelAsNoLongerNeeded(model)
        sendOptimizedNotification("Spawned <span class=\"notification-key\">" .. vehicleName:gsub("^%l", string.upper) .. "</span>", 'success')
    else
        sendOptimizedNotification("Failed to load vehicle <span class=\"notification-key\">" .. vehicleName .. "</span>", 'error')
    end
end

-- Performance optimization function
local function optimizePerformance()
    local currentTime = GetGameTimer()
    
    -- Update FPS counter every second
    if currentTime - performanceStats.lastFPSUpdate >= 1000 then
        performanceStats.averageFPS = performanceStats.frameCount
        performanceStats.frameCount = 0
        performanceStats.lastFPSUpdate = currentTime
        
        -- Adaptive optimization based on FPS
        if performanceStats.averageFPS < 30 then
            -- Reduce update frequency when FPS is low
            return true
        end
    end
    
    performanceStats.frameCount = performanceStats.frameCount + 1
    return false
end

-- Update menu position when user changes it
local function updateMenuPosition(x, y)
    uiPositions.menu.x = x
    uiPositions.menu.y = y
    uiPositions.playerList.x = x
    uiPositions.playerList.y = y
    uiPositions.settings.x = x
    uiPositions.settings.y = y
end

-- Special function for input that records all key presses
local function startInputRecording(question, placeholder, maxLength, inputType, callback)
    if not dui then return end
    
    _G.inputRecordingActive = true
    _G.inputBuffer = ""
    _G.inputMaxLength = maxLength or 100
    _G.inputCallback = callback
    
    MachoSendDuiMessage(dui, json.encode({
        action = 'openTextInput',
        question = question or 'Enter text:',
        placeholder = placeholder or 'Type here...',
        maxLength = _G.inputMaxLength,
        inputType = inputType or 'general'
    }))
    
    print("Macho: Input recording started")
end

local function stopInputRecording()
    _G.inputRecordingActive = false
    _G.inputBuffer = ""
    _G.inputCallback = nil
    print("Macho: Input recording stopped")
end

-- Generic input prompt function for any menu item
local function promptInput(question, placeholder, maxLength, inputType, callback)
    startInputRecording(question, placeholder, maxLength, inputType, callback)
end

-- Function to stop input recording and re-enable controls
local function stopInputRecording()
    _G.inputRecordingActive = false
    _G.inputBuffer = ""
    _G.inputCallback = nil
    print("Lua: Input recording stopped and state reset")
end

-- Function to force reset input state (for recovery)
local function resetInputState()
    _G.inputRecordingActive = false
    _G.inputBuffer = ""
    _G.inputCallback = nil
    if dui then
        MachoSendDuiMessage(dui, json.encode({
            action = 'closeTextInput'
        }))
    end
    print("Lua: Input state force reset")
end

-- Keybind setup function
local function setupKeybind()
    if not keybindSetup and dui then
        keybindSetup = true
        _G.keybindSetupActive = true
        
        -- Close the menu first
        MachoSendDuiMessage(dui, json.encode({
            action = 'setMenuVisible',
            visible = false
        }))
        _G.clientMenuShowing = false
        
        -- Then open key selection
        MachoSendDuiMessage(dui, json.encode({
            action = 'openKeySelection',
            title = 'Menu Keybind Setup',
            instruction = 'Press any key to set as the menu open key',
            hint = 'ESC to use default (Page Down)'
        }))
        print("Lua: Keybind setup activated")
    else
        print("Lua: Keybind setup already active or DUI not available")
    end
end

-- Nebula Software Client-Side Menu

-- Vehicle Spawn Function
function spawnVehicle(modelName)
    local model = GetHashKey(modelName)
    RequestModel(model)
    while not HasModelLoaded(model) do
        Wait(0)
    end
    
    local playerPed = PlayerPedId()
    local coords = GetEntityCoords(playerPed)
    local vehicle = CreateVehicle(model, coords.x, coords.y, coords.z, GetEntityHeading(playerPed), true, false)
    
    -- Apply spawn settings
    if _G.spawnInVehicle then
        SetPedIntoVehicle(playerPed, vehicle, -1)
    end
    
    if _G.maxOutOnSpawn then
        maxOutVehicle(vehicle)
    end
    
    if _G.easyHandlingOnSpawn then
        applyEasyHandling(vehicle)
    end
    
    if _G.godModeOnSpawn then
        SetEntityInvincible(vehicle, true)
        SetVehicleCanBeVisiblyDamaged(vehicle, false)
        SetVehicleCanBreak(vehicle, false)
    end
    
    SetModelAsNoLongerNeeded(model)
    
                                MachoSendDuiMessage(dui, json.encode({
                                    action = 'notify',
        message = "Spawned: <span class=\"notification-key\">" .. modelName .. "</span>",
                                    type = 'success'
                                }))
end

-- Max Out Vehicle Function
function maxOutVehicle(vehicle)
    SetVehicleModKit(vehicle, 0)
    SetVehicleMod(vehicle, 11, GetNumVehicleMods(vehicle, 11) - 1, false) -- Engine
    SetVehicleMod(vehicle, 12, GetNumVehicleMods(vehicle, 12) - 1, false) -- Brakes
    SetVehicleMod(vehicle, 13, GetNumVehicleMods(vehicle, 13) - 1, false) -- Transmission
    SetVehicleMod(vehicle, 15, GetNumVehicleMods(vehicle, 15) - 1, false) -- Suspension
    SetVehicleMod(vehicle, 16, GetNumVehicleMods(vehicle, 16) - 1, false) -- Armor
    ToggleVehicleMod(vehicle, 18, true) -- Turbo
    SetVehicleMod(vehicle, 23, GetNumVehicleMods(vehicle, 23) - 1, false) -- Front Wheels
    SetVehicleMod(vehicle, 24, GetNumVehicleMods(vehicle, 24) - 1, false) -- Back Wheels
end

-- Easy Handling Function
function applyEasyHandling(vehicle)
    SetVehicleModKit(vehicle, 0)
    SetVehicleMod(vehicle, 15, GetNumVehicleMods(vehicle, 15) - 1, false) -- Max Suspension
    SetVehicleMod(vehicle, 12, GetNumVehicleMods(vehicle, 12) - 1, false) -- Max Brakes
    
    -- Set handling values for better control
    SetVehicleHandlingFloat(vehicle, "CHandlingData", "fMass", 1000.0)
    SetVehicleHandlingFloat(vehicle, "CHandlingData", "fInitialDragCoeff", 10.0)
    SetVehicleHandlingFloat(vehicle, "CHandlingData", "fDownforceModifier", 0.0)
    SetVehicleHandlingFloat(vehicle, "CHandlingData", "fCentreOfMassOffset", 0.0)
    SetVehicleHandlingFloat(vehicle, "CHandlingData", "fInertiaMultiplier", 1.0)
    SetVehicleHandlingFloat(vehicle, "CHandlingData", "fDriveBiasFront", 0.0)
    SetVehicleHandlingFloat(vehicle, "CHandlingData", "fInitialDriveGears", 6.0)
    SetVehicleHandlingFloat(vehicle, "CHandlingData", "fInitialDriveForce", 0.5)
    SetVehicleHandlingFloat(vehicle, "CHandlingData", "fDriveInertia", 1.0)
    SetVehicleHandlingFloat(vehicle, "CHandlingData", "fClutchChangeRateScaleUpShift", 2.0)
    SetVehicleHandlingFloat(vehicle, "CHandlingData", "fClutchChangeRateScaleDownShift", 2.0)
    SetVehicleHandlingFloat(vehicle, "CHandlingData", "fInitialDriveMaxFlatVel", 200.0)
    SetVehicleHandlingFloat(vehicle, "CHandlingData", "fBrakeForce", 1.0)
    SetVehicleHandlingFloat(vehicle, "CHandlingData", "fBrakeBiasFront", 0.5)
    SetVehicleHandlingFloat(vehicle, "CHandlingData", "fHandBrakeForce", 1.0)
    SetVehicleHandlingFloat(vehicle, "CHandlingData", "fSteeringLock", 35.0)
    SetVehicleHandlingFloat(vehicle, "CHandlingData", "fTractionCurveMax", 2.5)
    SetVehicleHandlingFloat(vehicle, "CHandlingData", "fTractionCurveMin", 2.0)
    SetVehicleHandlingFloat(vehicle, "CHandlingData", "fTractionCurveLateral", 22.5)
    SetVehicleHandlingFloat(vehicle, "CHandlingData", "fTractionSpringDeltaMax", 0.15)
    SetVehicleHandlingFloat(vehicle, "CHandlingData", "fLowSpeedTractionLossMult", 1.0)
    SetVehicleHandlingFloat(vehicle, "CHandlingData", "fCamberStiffnesss", 0.0)
    SetVehicleHandlingFloat(vehicle, "CHandlingData", "fTractionBiasFront", 0.5)
    SetVehicleHandlingFloat(vehicle, "CHandlingData", "fTractionLossMult", 1.0)
    SetVehicleHandlingFloat(vehicle, "CHandlingData", "fSuspensionForce", 2.0)
    SetVehicleHandlingFloat(vehicle, "CHandlingData", "fSuspensionDamping", 1.0)
    SetVehicleHandlingFloat(vehicle, "CHandlingData", "fSuspensionUpperLimit", 0.1)
    SetVehicleHandlingFloat(vehicle, "CHandlingData", "fSuspensionLowerLimit", -0.15)
    SetVehicleHandlingFloat(vehicle, "CHandlingData", "fSuspensionRaise", 0.0)
    SetVehicleHandlingFloat(vehicle, "CHandlingData", "fSuspensionBiasFront", 0.5)
    SetVehicleHandlingFloat(vehicle, "CHandlingData", "fAntiRollBarForce", 0.0)
    SetVehicleHandlingFloat(vehicle, "CHandlingData", "fAntiRollBarBiasFront", 0.5)
    SetVehicleHandlingFloat(vehicle, "CHandlingData", "fRollCentreHeightFront", 0.0)
    SetVehicleHandlingFloat(vehicle, "CHandlingData", "fRollCentreHeightRear", 0.0)
end

-- Helper function to create dynamic vehicle mod sliders
function createVehicleModSlider(label, icon, modType)
    return {
        label = label,
        type = 'slider',
        icon = icon,
        min = -1,
        max = 10,
        value = -1,
        step = 1,
        onConfirm = function(val)
            local vehicle = GetVehiclePedIsIn(PlayerPedId(), false)
            if vehicle ~= 0 then
                SetVehicleModKit(vehicle, 0)
                local maxMods = GetNumVehicleMods(vehicle, modType) - 1
                
                -- Clamp the value to valid range
                if val > maxMods then 
                    val = maxMods
                elseif val < -1 then
                    val = -1
                end
                
                -- Apply the mod
                SetVehicleMod(vehicle, modType, val, false)
                
                -- Get current mod for display
                local currentMod = GetVehicleMod(vehicle, modType)
                local modName = currentMod == -1 and "Stock" or "Style " .. (currentMod + 1)
                
                MachoSendDuiMessage(dui, json.encode({
                    action = 'notify',
                    message = label .. ": <span class=\"notification-key\">" .. modName .. "</span> (" .. (maxMods + 1) .. " options)",
                    type = 'success'
                }))
            else
                MachoSendDuiMessage(dui, json.encode({
                    action = 'notify',
                    message = "You must be in a vehicle!",
                    type = 'error'
                }))
            end
        end,
        onChange = function(val)
            local vehicle = GetVehiclePedIsIn(PlayerPedId(), false)
            if vehicle ~= 0 then
                SetVehicleModKit(vehicle, 0)
                local maxMods = GetNumVehicleMods(vehicle, modType) - 1
                
                -- Clamp the value to valid range
                if val > maxMods then 
                    val = maxMods
                elseif val < -1 then
                    val = -1
                end
                
                -- Apply the mod
                SetVehicleMod(vehicle, modType, val, false)
            end
        end
    }
end

-- Alternative: Create vehicle mod sliders with proper max values from the start
function createSmartVehicleModSlider(label, icon, modType)
    local vehicle = GetVehiclePedIsIn(PlayerPedId(), false)
    local maxMods = 10 -- Default fallback
    
    if vehicle ~= 0 then
        SetVehicleModKit(vehicle, 0)
        maxMods = GetNumVehicleMods(vehicle, modType) - 1
    end
    
    return {
        label = label,
        type = 'slider',
        icon = icon,
        min = -1,
        max = maxMods,
        value = -1,
        step = 1,
        onConfirm = function(val)
            local vehicle = GetVehiclePedIsIn(PlayerPedId(), false)
            if vehicle ~= 0 then
                SetVehicleModKit(vehicle, 0)
                local currentMaxMods = GetNumVehicleMods(vehicle, modType) - 1
                
                -- Clamp the value to valid range
                if val > currentMaxMods then 
                    val = currentMaxMods
                elseif val < -1 then
                    val = -1
                end
                
                -- Apply the mod
                SetVehicleMod(vehicle, modType, val, false)
                
                -- Get current mod for display
                local currentMod = GetVehicleMod(vehicle, modType)
                local modName = currentMod == -1 and "Stock" or "Style " .. (currentMod + 1)
                
                MachoSendDuiMessage(dui, json.encode({
                    action = 'notify',
                    message = label .. ": <span class=\"notification-key\">" .. modName .. "</span> (" .. (currentMaxMods + 1) .. " options)",
                    type = 'success'
                }))
            else
                MachoSendDuiMessage(dui, json.encode({
                    action = 'notify',
                    message = "You must be in a vehicle!",
                    type = 'error'
                }))
            end
        end,
        onChange = function(val)
            local vehicle = GetVehiclePedIsIn(PlayerPedId(), false)
            if vehicle ~= 0 then
                SetVehicleModKit(vehicle, 0)
                local currentMaxMods = GetNumVehicleMods(vehicle, modType) - 1
                
                -- Clamp the value to valid range
                if val > currentMaxMods then 
                    val = currentMaxMods
                elseif val < -1 then
                    val = -1
                end
                
                -- Apply the mod
                SetVehicleMod(vehicle, modType, val, false)
            end
        end
    }
end

-- Weapon name lookup function
local function getWeaponName(weaponHash)
    local weaponNames = {
        [GetHashKey("WEAPON_RAILGUN")] = "Railgun",
        [GetHashKey("WEAPON_ASSAULTSHOTGUN")] = "Assault Shotgun",
        [GetHashKey("WEAPON_SMG")] = "SMG",
        [GetHashKey("WEAPON_FIREWORK")] = "Firework Launcher",
        [GetHashKey("WEAPON_MOLOTOV")] = "Molotov Cocktail",
        [GetHashKey("WEAPON_APPISTOL")] = "AP Pistol",
        [GetHashKey("WEAPON_STUNGUN")] = "Stun Gun",
        [GetHashKey("WEAPON_ASSAULTRIFLE")] = "Assault Rifle",
        [GetHashKey("WEAPON_ASSAULTRIFLE_MK2")] = "Assault Rifle MK2",
        [GetHashKey("WEAPON_ASSAULTSMG")] = "Assault SMG",
        [GetHashKey("WEAPON_AUTOSHOTGUN")] = "Auto Shotgun",
        [GetHashKey("WEAPON_BULLPUPRIFLE")] = "Bullpup Rifle",
        [GetHashKey("WEAPON_BULLPUPRIFLE_MK2")] = "Bullpup Rifle MK2",
        [GetHashKey("WEAPON_BULLPUPSHOTGUN")] = "Bullpup Shotgun",
        [GetHashKey("WEAPON_BZGAS")] = "BZ Gas",
        [GetHashKey("WEAPON_CARBINERIFLE")] = "Carbine Rifle",
        [GetHashKey("WEAPON_CARBINERIFLE_MK2")] = "Carbine Rifle MK2",
        [GetHashKey("WEAPON_COMBATMG")] = "Combat MG",
        [GetHashKey("WEAPON_COMBATMG_MK2")] = "Combat MG MK2",
        [GetHashKey("WEAPON_COMBATPDW")] = "Combat PDW",
        [GetHashKey("WEAPON_COMBATPISTOL")] = "Combat Pistol",
        [GetHashKey("WEAPON_COMPACTLAUNCHER")] = "Compact Launcher",
        [GetHashKey("WEAPON_COMPACTRIFLE")] = "Compact Rifle",
        [GetHashKey("WEAPON_DBSHOTGUN")] = "Double Barrel Shotgun",
        [GetHashKey("WEAPON_DOUBLEACTION")] = "Double Action Revolver",
        [GetHashKey("WEAPON_FIREEXTINGUISHER")] = "Fire Extinguisher",
        [GetHashKey("WEAPON_FLARE")] = "Flare",
        [GetHashKey("WEAPON_FLAREGUN")] = "Flare Gun",
        [GetHashKey("WEAPON_GRENADE")] = "Grenade",
        [GetHashKey("WEAPON_GUSENBERG")] = "Gusenberg Sweeper",
        [GetHashKey("WEAPON_HEAVYPISTOL")] = "Heavy Pistol",
        [GetHashKey("WEAPON_HEAVYSHOTGUN")] = "Heavy Shotgun",
        [GetHashKey("WEAPON_HEAVYSNIPER")] = "Heavy Sniper",
        [GetHashKey("WEAPON_HEAVYSNIPER_MK2")] = "Heavy Sniper MK2",
        [GetHashKey("WEAPON_HOMINGLAUNCHER")] = "Homing Launcher",
        [GetHashKey("WEAPON_MACHINEPISTOL")] = "Machine Pistol",
        [GetHashKey("WEAPON_MARKSMANPISTOL")] = "Marksman Pistol",
        [GetHashKey("WEAPON_MARKSMANRIFLE")] = "Marksman Rifle",
        [GetHashKey("WEAPON_MARKSMANRIFLE_MK2")] = "Marksman Rifle MK2",
        [GetHashKey("WEAPON_MG")] = "MG",
        [GetHashKey("WEAPON_MICROSMG")] = "Micro SMG",
        [GetHashKey("WEAPON_MINIGUN")] = "Minigun",
        [GetHashKey("WEAPON_MINISMG")] = "Mini SMG",
        [GetHashKey("WEAPON_MUSKET")] = "Musket",
        [GetHashKey("WEAPON_NAVYREVOLVER")] = "Navy Revolver",
        [GetHashKey("WEAPON_PIPEBOMB")] = "Pipe Bomb",
        [GetHashKey("WEAPON_PISTOL")] = "Pistol",
        [GetHashKey("WEAPON_PISTOL50")] = "Pistol .50",
        [GetHashKey("WEAPON_PISTOL_MK2")] = "Pistol MK2",
        [GetHashKey("WEAPON_POOLCUE")] = "Pool Cue",
        [GetHashKey("WEAPON_PROXMINE")] = "Proximity Mine",
        [GetHashKey("WEAPON_PUMPSHOTGUN")] = "Pump Shotgun",
        [GetHashKey("WEAPON_PUMPSHOTGUN_MK2")] = "Pump Shotgun MK2",
        [GetHashKey("WEAPON_RAYCARBINE")] = "Ray Carbine",
        [GetHashKey("WEAPON_RAYMINIGUN")] = "Ray Minigun",
        [GetHashKey("WEAPON_RAYPISTOL")] = "Ray Pistol",
        [GetHashKey("WEAPON_REVOLVER")] = "Revolver",
        [GetHashKey("WEAPON_REVOLVER_MK2")] = "Revolver MK2",
        [GetHashKey("WEAPON_SAWNOFFSHOTGUN")] = "Sawed-Off Shotgun",
        [GetHashKey("WEAPON_RPG")] = "RPG",
        [GetHashKey("WEAPON_SMG_MK2")] = "SMG MK2",
        [GetHashKey("WEAPON_SMOKEGRENADE")] = "Smoke Grenade",
        [GetHashKey("WEAPON_SNIPERRIFLE")] = "Sniper Rifle",
        [GetHashKey("WEAPON_SNOWBALL")] = "Snowball",
        [GetHashKey("WEAPON_SNSPISTOL")] = "SNS Pistol",
        [GetHashKey("WEAPON_SNSPISTOL_MK2")] = "SNS Pistol MK2",
        [GetHashKey("WEAPON_SPECIALCARBINE")] = "Special Carbine",
        [GetHashKey("WEAPON_SPECIALCARBINE_MK2")] = "Special Carbine MK2",
        [GetHashKey("WEAPON_STICKYBOMB")] = "Sticky Bomb",
        [GetHashKey("WEAPON_VINTAGEPISTOL")] = "Vintage Pistol"
    }
    
    return weaponNames[weaponHash] or "Unknown Weapon"
end

-- Get Players function (from replix_main.lua)
function GetPlayers()
    local players = {}

    for i = 0, 999 do
        if IsPedAPlayer(GetPlayerPed(i)) then
            table.insert(players, i)
        end
    end

    -- check if player is double
    for i = 1, #players do
        for j = 1, #players do
            if i ~= j then
                if GetPlayerServerId(players[i]) == GetPlayerServerId(players[j]) then
                    table.remove(players, j)
                end
            end
        end
    end

    return players
end

-- Network control function (from replix_main.lua)
local function RequestNetworkControl(Request)
    local hasControl = false
    while hasControl == false do
        hasControl = NetworkRequestControlOfEntity(Request)
        if hasControl == true or hasControl == 1 then
            break
        end
        if
            NetworkHasControlOfEntity(Request) == true and hasControl == true or
                NetworkHasControlOfEntity(Request) == true and hasControl == 1
         then
            return true
        else
            return false
        end
    end
end

-- Make ped hostile function (from replix_main.lua)
local function makePedHostile(target, ped, swat, clone)
    if swat == 1 or swat == true then
        RequestNetworkControl(ped)
        TaskCombatPed(ped, GetPlayerPed(selectedPlayer), 0, 16)
        SetPedCanSwitchWeapon(ped, true)
    else
        if clone == 1 or clone == true then
            local Hash = GetEntityModel(ped)
            if DoesEntityExist(ped) then
                DeletePed(ped)
                RequestModel(Hash)
                local coords = GetEntityCoords(GetPlayerPed(target), true)
                if HasModelLoaded(Hash) then
                    local newPed = CreatePed(21, Hash, coords.x, coords.y, coords.z, 0, 1, 0)
                    if GetEntityHealth(newPed) == GetEntityMaxHealth(newPed) then
                        SetModelAsNoLongerNeeded(Hash)
                        RequestNetworkControl(newPed)
                        TaskCombatPed(newPed, GetPlayerPed(target), 0, 16)
                        SetPedCanSwitchWeapon(ped, true)
                    end
                end
            end
        else
            local TargetHandle = GetPlayerPed(target)
            RequestNetworkControl(ped)
            TaskCombatPed(ped, TargetHandle, 0, 16)
        end
    end
end

-- Player Info Functions (improved from replix_main.lua)
function getPlayerRealTimeData(localId)
    if not localId then return nil end
    
    local playerPed = GetPlayerPed(localId)
    if not playerPed or playerPed == 0 then return nil end
    
    -- Get current weapon
    local currentWeapon = "None"
    local weaponHash = GetSelectedPedWeapon(playerPed)
    if weaponHash ~= GetHashKey("WEAPON_UNARMED") then
        currentWeapon = getWeaponName(weaponHash)
    end
    
    -- Get vehicle info
    local vehicle = GetVehiclePedIsIn(playerPed, false)
    local vehicleName = "NONE"
    local speed = "0"
    local isInVehicle = false
    if vehicle ~= 0 then
        isInVehicle = true
        vehicleName = GetDisplayNameFromVehicleModel(GetEntityModel(vehicle))
        local speedMs = GetEntitySpeed(vehicle)
        speed = math.floor(speedMs * 3.6) .. " km/h" -- Convert m/s to km/h
    end
    
    -- Get distance from local player
    local playerCoords = GetEntityCoords(playerPed)
    local localPlayerCoords = GetEntityCoords(PlayerPedId())
    local distance = math.floor(GetDistanceBetweenCoords(playerCoords.x, playerCoords.y, playerCoords.z, localPlayerCoords.x, localPlayerCoords.y, localPlayerCoords.z, true))
    
    -- Get player ping safely
    local playerPing = 0
    if GetPlayerPing then
        playerPing = GetPlayerPing(localId)
    else
        playerPing = math.random(30, 150) -- Fallback to random ping
    end
    
    -- Check if player is alive
    local isAlive = GetEntityHealth(playerPed) > 0
    
    return {
        health = GetEntityHealth(playerPed),
        armor = GetPedArmour(playerPed),
        weapon = currentWeapon,
        isInVehicle = isInVehicle,
        vehicleName = vehicleName,
        speed = speed,
        distance = distance .. ".0",
        isAlive = isAlive,
        ping = playerPing
    }
end

-- Function to get real player data (from replix_main.lua)
local function getRealPlayerData()
    local players = {}
    local playerList = GetPlayers()
    
    for i = 1, #playerList do
        local currPlayer = playerList[i]
        local playerPed = GetPlayerPed(currPlayer)
        local playerCoords = GetEntityCoords(playerPed)
        
        -- Get player ping safely
        local playerPing = 0
        if GetPlayerPing then
            playerPing = GetPlayerPing(currPlayer)
        else
            playerPing = math.random(30, 150) -- Fallback to random ping
        end
        
        -- Get additional player data
        local playerCoords = GetEntityCoords(playerPed)
        local localPlayerCoords = GetEntityCoords(PlayerPedId())
        local distance = math.floor(GetDistanceBetweenCoords(playerCoords.x, playerCoords.y, playerCoords.z, localPlayerCoords.x, localPlayerCoords.y, localPlayerCoords.z, true))
        
        -- Get current weapon
        local currentWeapon = "None"
        local weaponHash = GetSelectedPedWeapon(playerPed)
        if weaponHash ~= GetHashKey("WEAPON_UNARMED") then
            currentWeapon = getWeaponName(weaponHash)
        end
        
        -- Get vehicle info
        local vehicle = GetVehiclePedIsIn(playerPed, false)
        local vehicleName = "None"
        local speed = "0 km/h"
        local isInVehicle = false
        if vehicle ~= 0 then
            isInVehicle = true
            vehicleName = GetDisplayNameFromVehicleModel(GetEntityModel(vehicle))
            local speedMs = GetEntitySpeed(vehicle)
            speed = math.floor(speedMs * 3.6) -- Convert m/s to km/h
        end
        
        -- Check if player is alive
        local isAlive = GetEntityHealth(playerPed) > 0
        
        table.insert(players, {
            id = GetPlayerServerId(currPlayer),
            name = GetPlayerName(currPlayer),
            localId = currPlayer, -- Local player ID
            ping = playerPing,
            health = GetEntityHealth(playerPed),
            armor = GetPedArmour(playerPed),
            weapon = currentWeapon,
            isInVehicle = isInVehicle,
            vehicleName = vehicleName,
            speed = speed .. " km/h",
            distance = distance .. ".0",
            isAlive = isAlive,
        })
    end
    
    return players
end

-- Function to create individual player submenu (from replix_main.lua)
local function createPlayerSubmenu(playerData)
    return {
        {
            label = "Spectate Player",
            type = 'checkbox',
            icon = 'fas fa-eye',
            onConfirm = function(setToggle)
                if setToggle then
                    TriggerEvent('txcl:spectate:start', playerData.id, GetEntityCoords(GetPlayerPed(playerData.localId)))
                else
                    TriggerEvent('txcl:spectate:stop')
                end
            end
        },
        {
            label = "Teleport to Player",
                        type = 'button',
            icon = 'fas fa-map-marker-alt',
                        onConfirm = function() 
                            if dui then
                    SetEntityCoords(PlayerPedId(), GetEntityCoords(GetPlayerPed(playerData.localId)))
                    SetEntityHeading(PlayerPedId(), GetEntityHeading(GetPlayerPed(playerData.localId)))
                                MachoSendDuiMessage(dui, json.encode({
                                    action = 'notify',
                        message = "Teleporting to " .. playerData.name,
                        type = 'info'
                                }))
                            end
                        end 
                    },
                    { 
            label = "Kill Player",
                        type = 'button',
            icon = 'fas fa-skull',
                        onConfirm = function() 
                            if dui then
                    local playerPed = GetPlayerPed(playerData.localId)
                    if playerPed and playerPed ~= 0 then
                        SetEntityHealth(playerPed, 0)
                                MachoSendDuiMessage(dui, json.encode({
                                    action = 'notify',
                            message = "Killed " .. playerData.name,
                                    type = 'success'
                                }))
                    end
                            end
                        end 
                    },
                    { 
            label = "Heal Player",
                        type = 'button',
            icon = 'fas fa-heart',
                        onConfirm = function() 
                            if dui then
                    local playerPed = GetPlayerPed(playerData.localId)
                    if playerPed and playerPed ~= 0 then
                        SetEntityHealth(playerPed, GetEntityMaxHealth(playerPed))
                        SetPedArmour(playerPed, 100)
                                MachoSendDuiMessage(dui, json.encode({
                                    action = 'notify',
                            message = "Healed " .. playerData.name,
                                    type = 'success'
                                }))
                            end
                        end 
                        end
                    },
                    {
            label = "Give Weapon",
            type = 'scroll',
            icon = 'fas fa-gun',
            options = {
                {label = 'Pistol', value = 'weapon_pistol'},
                {label = 'Assault Rifle', value = 'weapon_assaultrifle'},
                {label = 'SMG', value = 'weapon_smg'},
                {label = 'Shotgun', value = 'weapon_shotgun'},
                {label = 'Sniper Rifle', value = 'weapon_sniperrifle'},
                {label = 'RPG', value = 'weapon_rpg'},
                {label = 'Minigun', value = 'weapon_minigun'}
            },
            selected = 1,
            onConfirm = function(option)
                if dui then
                    local playerPed = GetPlayerPed(playerData.localId)
                    if playerPed and playerPed ~= 0 then
                        local weaponHash = GetHashKey(option.value)
                        GiveWeaponToPed(playerPed, weaponHash, 250, false, true)
                        MachoSendDuiMessage(dui, json.encode({
                            action = 'notify',
                            message = "Gave " .. option.label .. " to " .. playerData.name,
                            type = 'success'
                        }))
                    end
                end
                        end
                    },
                    {
            label = "Remove All Weapons",
            type = 'button',
            icon = 'fas fa-trash',
                        onConfirm = function()
                if dui then
                    local playerPed = GetPlayerPed(playerData.localId)
                    if playerPed and playerPed ~= 0 then
                        RemoveAllPedWeapons(playerPed, true)
                        MachoSendDuiMessage(dui, json.encode({
                            action = 'notify',
                            message = "Removed weapons from " .. playerData.name,
                            type = 'success'
                        }))
                    end
                end
                        end
                    },
                    {
            label = "Bring Player",
                        type = 'button',
            icon = 'fas fa-hand-paper',
                        onConfirm = function()
                                if dui then
                    local playerPed = GetPlayerPed(playerData.localId)
                    if playerPed and playerPed ~= 0 then
                        local coords = GetEntityCoords(PlayerPedId())
                        SetEntityCoords(playerPed, coords.x, coords.y, coords.z, false, false, false, true)
                                    MachoSendDuiMessage(dui, json.encode({
                                        action = 'notify',
                            message = "Brought " .. playerData.name,
                                        type = 'success'
                                    }))
                                end
                end
                        end
                    },
                    {
            label = "Crash Exploit 1",
            type = "button",
            icon = "fas fa-wifi-slash",
                        onConfirm = function()
                local currPlayer = playerData.localId
                for i = 0, 32 do
                    local coords = GetEntityCoords(GetPlayerPed(currPlayer))
                    RequestModel(GetHashKey('ig_wade'))
                    Citizen.Wait(50)
                    if HasModelLoaded(GetHashKey('ig_wade')) then
                        local ped = CreatePed(21, GetHashKey('ig_wade'), coords.x, coords.y, coords.z, 0, true, false)
                        CreatePed(21, GetHashKey('ig_wade'), coords.x, coords.y, coords.z, 0, true, false)
                        CreatePed(21, GetHashKey('ig_wade'), coords.x, coords.y, coords.z, 0, true, false)
                        CreatePed(21, GetHashKey('ig_wade'), coords.x, coords.y, coords.z, 0, true, false)
                        CreatePed(21, GetHashKey('ig_wade'), coords.x, coords.y, coords.z, 0, true, false)
                        if DoesEntityExist(ped) and not IsEntityDead(GetPlayerPed(currPlayer)) then
                            RequestNetworkControl(ped)
                            GiveWeaponToPed(ped, GetHashKey('WEAPON_RPG'), 9999, 1, 1)
                            SetPedCanSwitchWeapon(ped, true)
                            makePedHostile(ped, currPlayer, 0, 0)
                            TaskCombatPed(ped, GetPlayerPed(currPlayer), 0, 16)
                        elseif IsEntityDead(GetPlayerPed(currPlayer)) then
                            TaskCombatHatedTargetsInArea(ped, coords.x, coords.y, coords.z, 500)
                        else
                            Citizen.Wait(10)
                        end
                    else
                        Citizen.Wait(10)
                    end
                end
                                        if dui then
                                            MachoSendDuiMessage(dui, json.encode({
                                                action = 'notify',
                        message = "crashed ".. playerData.name,
                                                type = 'success'
                                            }))
                                        end
            end
        },
        {
            label = "Crash Exploit 2",
            type = "button",
            icon = "fas fa-wifi-slash",
            onConfirm = function() 
                local currPlayer = playerData.localId
                for i = 0, 32 do
                    local coords = GetEntityCoords(GetPlayerPed(currPlayer))
                    RequestModel(GetHashKey('mp_m_freemode_01'))
                    Citizen.Wait(50)
                    if HasModelLoaded(GetHashKey('mp_m_freemode_01')) then
                        local ped = CreatePed(21, GetHashKey('mp_m_freemode_01'), coords.x, coords.y, coords.z, 0, true, false)
                        CreatePed(21, GetHashKey('mp_m_freemode_01'), coords.x, coords.y, coords.z, 0, true, false)
                        CreatePed(21, GetHashKey('mp_m_freemode_01'), coords.x, coords.y, coords.z, 0, true, false)
                        CreatePed(21, GetHashKey('mp_m_freemode_01'), coords.x, coords.y, coords.z, 0, true, false)
                        CreatePed(21, GetHashKey('mp_m_freemode_01'), coords.x, coords.y, coords.z, 0, true, false)
                        CreatePed(21, GetHashKey('mp_m_freemode_01'), coords.x, coords.y, coords.z, 0, true, false)
                        CreatePed(21, GetHashKey('mp_m_freemode_01'), coords.x, coords.y, coords.z, 0, true, false)
                        CreatePed(21, GetHashKey('mp_m_freemode_01'), coords.x, coords.y, coords.z, 0, true, false)
                        CreatePed(21, GetHashKey('mp_m_freemode_01'), coords.x, coords.y, coords.z, 0, true, false)
                        CreatePed(21, GetHashKey('mp_m_freemode_01'), coords.x, coords.y, coords.z, 0, true, false)
                        CreatePed(21, GetHashKey('mp_m_freemode_01'), coords.x, coords.y, coords.z, 0, true, false)
                        CreatePed(21, GetHashKey('mp_m_freemode_01'), coords.x, coords.y, coords.z, 0, true, false)
                        CreatePed(21, GetHashKey('mp_m_freemode_01'), coords.x, coords.y, coords.z, 0, true, false)
                        CreatePed(21, GetHashKey('mp_m_freemode_01'), coords.x, coords.y, coords.z, 0, true, false)
                        CreatePed(21, GetHashKey('mp_m_freemode_01'), coords.x, coords.y, coords.z, 0, true, false)
                        CreatePed(21, GetHashKey('mp_m_freemode_01'), coords.x, coords.y, coords.z, 0, true, false)
                        CreatePed(21, GetHashKey('mp_m_freemode_01'), coords.x, coords.y, coords.z, 0, true, false)
                        CreatePed(21, GetHashKey('mp_m_freemode_01'), coords.x, coords.y, coords.z, 0, true, false)
                        CreatePed(21, GetHashKey('mp_m_freemode_01'), coords.x, coords.y, coords.z, 0, true, false)
                        CreatePed(21, GetHashKey('mp_m_freemode_01'), coords.x, coords.y, coords.z, 0, true, false)
                        CreatePed(21, GetHashKey('mp_m_freemode_01'), coords.x, coords.y, coords.z, 0, true, false)
                        CreatePed(21, GetHashKey('mp_m_freemode_01'), coords.x, coords.y, coords.z, 0, true, false)
                        CreatePed(21, GetHashKey('mp_m_freemode_01'), coords.x, coords.y, coords.z, 0, true, false)
                        CreatePed(21, GetHashKey('mp_m_freemode_01'), coords.x, coords.y, coords.z, 0, true, false)
                        CreatePed(21, GetHashKey('mp_m_freemode_01'), coords.x, coords.y, coords.z, 0, true, false)
                        CreatePed(21, GetHashKey('mp_m_freemode_01'), coords.x, coords.y, coords.z, 0, true, false)
                        CreatePed(21, GetHashKey('mp_m_freemode_01'), coords.x, coords.y, coords.z, 0, true, false)
                        CreatePed(21, GetHashKey('mp_m_freemode_01'), coords.x, coords.y, coords.z, 0, true, false)
                        if DoesEntityExist(ped) and not IsEntityDead(GetPlayerPed(currPlayer)) then
                            RequestNetworkControl(ped)
                            GiveWeaponToPed(ped, GetHashKey('WEAPON_RPG'), 9999, 1, 1)
                            SetPedCanSwitchWeapon(ped, true)
                            makePedHostile(ped, currPlayer, 0, 0)
                            TaskCombatPed(ped, GetPlayerPed(currPlayer), 0, 16)
                        elseif IsEntityDead(GetPlayerPed(currPlayer)) then
                            TaskCombatHatedTargetsInArea(ped, coords.x, coords.y, coords.z, 500)
                        else
                            Citizen.Wait(10)
                        end
                    else
                        Citizen.Wait(10)
                    end
                end
                                        if dui then
                                            MachoSendDuiMessage(dui, json.encode({
                                                action = 'notify',
                        message = "crashed ".. playerData.name,
                        type = 'success'
                                            }))
                                        end
            end
        },
        {
            label = "Crash Exploit 3",
            type = "button",
            icon = "fas fa-wifi-slash",
            onConfirm = function() 
                local currPlayer = playerData.localId
                for i = 0, 32 do
                    local coords = GetEntityCoords(GetPlayerPed(currPlayer))
                    RequestModel(GetHashKey('mp_f_freemode_01'))
                    Citizen.Wait(50)
                    if HasModelLoaded(GetHashKey('mp_f_freemode_01')) then
                        local ped = CreatePed(21, GetHashKey('mp_f_freemode_01'), coords.x, coords.y, coords.z, 0, true, false)
                        CreatePed(21, GetHashKey('mp_f_freemode_01'), coords.x, coords.y, coords.z, 0, true, false)
                        CreatePed(21, GetHashKey('mp_f_freemode_01'), coords.x, coords.y, coords.z, 0, true, false)
                        CreatePed(21, GetHashKey('mp_f_freemode_01'), coords.x, coords.y, coords.z, 0, true, false)
                        CreatePed(21, GetHashKey('mp_f_freemode_01'), coords.x, coords.y, coords.z, 0, true, false)
                        if DoesEntityExist(ped) and not IsEntityDead(GetPlayerPed(currPlayer)) then
                            RequestNetworkControl(ped)
                            GiveWeaponToPed(ped, GetHashKey('WEAPON_PISTOL'), 9999, 1, 1)
                            SetPedCanSwitchWeapon(ped, true)
                            makePedHostile(ped, currPlayer, 0, 0)
                            TaskCombatPed(ped, GetPlayerPed(currPlayer), 0, 16)
                        elseif IsEntityDead(GetPlayerPed(currPlayer)) then
                            TaskCombatHatedTargetsInArea(ped, coords.x, coords.y, coords.z, 500)
                        else
                            Citizen.Wait(10)
                        end
                    else
                        Citizen.Wait(10)
                    end
                end
                                    if dui then
                                        MachoSendDuiMessage(dui, json.encode({
                                            action = 'notify',
                        message = "crashed ".. playerData.name,
                        type = 'success'
                                        }))
                                    end
                        end
                    },
                    {
            label = "Ban Player",
            type = "button",
            icon = "fas fa-ban",
                        onConfirm = function()
                local currPlayer = playerData.localId
                local weapons = {
                    "PICKUP_WEAPON_PISTOL",
                    "PICKUP_WEAPON_PISTOL_MK2",
                    "PICKUP_WEAPON_COMBATPISTOL",
                    "PICKUP_WEAPON_APPISTOL",
                    "PICKUP_WEAPON_PISTOL50",
                    "PICKUP_WEAPON_SNSPISTOL",
                    "PICKUP_WEAPON_SNSPISTOL_MK2",
                    "PICKUP_WEAPON_HEAVYPISTOL",
                    "PICKUP_WEAPON_VINTAGEPISTOL",
                    "PICKUP_WEAPON_FLAREGUN",
                    "PICKUP_WEAPON_MARKSMANPISTOL",
                    "PICKUP_WEAPON_REVOLVER",
                    "PICKUP_WEAPON_REVOLVER_MK2",
                    "PICKUP_WEAPON_DOUBLEACTION",
                    "PICKUP_WEAPON_RAYPISTOL",
                    "PICKUP_WEAPON_CERAMICPISTOL",
                    "PICKUP_WEAPON_NAVYREVOLVER",
                    "PICKUP_WEAPON_MACHINEPISTOL",
                    "PICKUP_WEAPON_MICROSMG",
                    "PICKUP_WEAPON_SMG",
                    "PICKUP_WEAPON_SMG_MK2",
                    "PICKUP_WEAPON_ASSAULTSMG",
                    "PICKUP_WEAPON_COMBATPDW",
                    "PICKUP_WEAPON_GUSENBERG",
                    "PICKUP_WEAPON_MINISMG",
                    "PICKUP_WEAPON_MG",
                    "PICKUP_WEAPON_COMBATMG",
                    "PICKUP_WEAPON_COMBATMG_MK2",
                    "PICKUP_WEAPON_GUSENBERG",
                    "PICKUP_WEAPON_ASSAULTRIFLE",
                    "PICKUP_WEAPON_ASSAULTRIFLE_MK2",
                    "PICKUP_WEAPON_CARBINERIFLE",
                    "PICKUP_WEAPON_CARBINERIFLE_MK2",
                    "PICKUP_WEAPON_ADVANCEDRIFLE",
                    "PICKUP_WEAPON_SPECIALCARBINE",
                    "PICKUP_WEAPON_SPECIALCARBINE_MK2",
                    "PICKUP_WEAPON_BULLPUPRIFLE",
                    "PICKUP_WEAPON_BULLPUPRIFLE_MK2",
                }

                local playerPed = GetPlayerPed(currPlayer)
                local playerCoords = GetEntityCoords(playerPed)
                
                -- Create pickups for the player
                for i = 1, #weapons do
                    local pickupHash = GetHashKey(weapons[i])
                    local pickup = CreatePickup(pickupHash, playerCoords.x, playerCoords.y, playerCoords.z + 1, 0.0, 0.0, 0.0, 512, 100)
                end

                -- Remove all pickups
                local pickups = GetGamePool('CPickup')
                for i = 1, #pickups do
                    local pickup = pickups[i]
                    if DoesPickupExist(pickup) then
                        RemovePickup(pickup)
                    end
                end
                                if dui then
                                    MachoSendDuiMessage(dui, json.encode({
                                        action = 'notify',
                        message = "banned ".. playerData.name,
                        type = 'success'
                                    }))
                                end
            end
        },
    }
end

-- Function to create player list submenu
local function createPlayerListSubmenu()
    local players = getRealPlayerData()
    local playerMenuItems = {}
    
    for _, player in ipairs(players) do
        table.insert(playerMenuItems, {
            label = player.name,
            type = 'submenu',
            icon = 'fas fa-user',
            submenu = createPlayerSubmenu(player),
            -- Store player data for info panel
            playerData = player
        })
    end
    
    return playerMenuItems
end

-- Initialize player list submenu
local playerListSubmenu = createPlayerListSubmenu()

-- Debug function to check player list
local function debugPlayerList()
    print("=== PLAYER LIST DEBUG ===")
    print("PlayerListSubmenu items: " .. #playerListSubmenu)
    for i, player in ipairs(playerListSubmenu) do
        print("Player " .. i .. ": " .. player.label)
    end
    print("========================")
end

-- Call debug function
debugPlayerList()

-- Function to update playerlist in menu
local function updatePlayerlistData()
    local realPlayers = getRealPlayerData()
    
    -- Update the player list submenu with new player data
    local newPlayerListSubmenu = {}
    for _, player in ipairs(realPlayers) do
        table.insert(newPlayerListSubmenu, {
            label = player.name,
            type = 'submenu',
            icon = 'fas fa-user',
            submenu = createPlayerSubmenu(player),
            -- Store player data for info panel
            playerData = player
        })
    end
    
    -- Update the main menu's player list submenu
    for i, menuItem in ipairs(originalMenu) do
        if menuItem.label == "Online Players" and menuItem.type == 'submenu' then
            originalMenu[i].submenu = newPlayerListSubmenu
            break
        end
    end
    
    -- Update active menu if it's the same as original
    if activeMenu == originalMenu then
        for i, menuItem in ipairs(activeMenu) do
            if menuItem.label == "Online Players" and menuItem.type == 'submenu' then
                activeMenu[i].submenu = newPlayerListSubmenu
                break
            end
        end
    end
end

originalMenu = {
    {
        label = "Player",
        type = 'submenu',
        icon = 'fas fa-user',
        submenu = {
            {
                label = 'Health & Protection', 
                type = 'submenu',
                icon = 'fas fa-heart-pulse',
                submenu = {
                    {
                        label = 'Health', 
                        type = 'slider', 
                        icon = 'fas fa-heart',
                        min = 0,
                        max = 200,
                        value = 100,
                        step = 5,
                        onConfirm = function(val)
                            local ped = PlayerPedId()
                            local maxHealth = GetEntityMaxHealth(ped)
                            local healthValue = math.floor((val / 100) * maxHealth)
                            SetEntityHealth(ped, healthValue)
                                MachoSendDuiMessage(dui, json.encode({
                                    action = 'notify',
                                message = "Health set to: <span class=\"notification-key\">" .. val .. "%</span>",
                                    type = 'success'
                                }))
                        end,
                        onChange = function(val)
                            local ped = PlayerPedId()
                            local maxHealth = GetEntityMaxHealth(ped)
                            local healthValue = math.floor((val / 100) * maxHealth)
                            SetEntityHealth(ped, healthValue)
                        end
                    },
                    {
                        label = 'Armor', 
                        type = 'slider', 
                        icon = 'fas fa-shield-halved',
                        min = 0,
                        max = 100,
                        value = 0,
                        step = 5,
                        onConfirm = function(val)
                            SetPedArmour(PlayerPedId(), val)
                                MachoSendDuiMessage(dui, json.encode({
                                    action = 'notify',
                                message = "Armor set to: <span class=\"notification-key\">" .. val .. "</span>",
                                    type = 'success'
                                }))
                        end,
                        onChange = function(val)
                            SetPedArmour(PlayerPedId(), val)
                            end
                    },
                    {
                        label = 'God Mode',
                        type = 'checkbox',
                        icon = 'fas fa-shield-virus',
                        checked = false,
                        onConfirm = function(toggle)
                            local ped = PlayerPedId()
                            SetEntityInvincible(ped, toggle)
                            SetPlayerInvincible(PlayerId(), toggle)
                            MachoSendDuiMessage(dui, json.encode({
                                action = 'notify',
                                message = "God Mode: <span class=\"notification-key\">" .. (toggle and "ON" or "OFF") .. "</span>",
                                type = toggle and 'success' or 'info'
                            }))
                        end
                    },
                    {
                        label = 'Invisible',
                        type = 'checkbox',
                        icon = 'fas fa-eye-slash',
                        checked = false,
                        onConfirm = function(toggle)
                            local ped = PlayerPedId()
                            SetEntityVisible(ped, not toggle, 0)
                                MachoSendDuiMessage(dui, json.encode({
                                    action = 'notify',
                                message = "Invisible: <span class=\"notification-key\">" .. (toggle and "ON" or "OFF") .. "</span>",
                                type = toggle and 'success' or 'info'
                                }))
                            end
                    },
                    {
                        label = 'No Ragdoll',
                        type = 'checkbox',
                        icon = 'fas fa-user-slash',
                        checked = false,
                        onConfirm = function(toggle)
                            local ped = PlayerPedId()
                            SetPedCanRagdoll(ped, not toggle)
                            MachoSendDuiMessage(dui, json.encode({
                                action = 'notify',
                                message = "No Ragdoll: <span class=\"notification-key\">" .. (toggle and "ON" or "OFF") .. "</span>",
                                type = toggle and 'success' or 'info'
                            }))
                        end
                    }
                },
            },
            {
                label = 'Stamina & Movement',
                type = 'submenu',
                icon = 'fas fa-running',
                submenu = {
                    {
                        label = 'Stamina',
                        type = 'slider',
                        icon = 'fas fa-lungs',
                        min = 0,
                        max = 100,
                        value = 100,
                        step = 5,
                        onConfirm = function(val)
                            local playerId = PlayerId()
                            local staminaValue = val * 10.0 -- Convert to game stamina value (0-1000)
                            SetPlayerStamina(playerId, staminaValue)
                                MachoSendDuiMessage(dui, json.encode({
                                    action = 'notify',
                                message = "Stamina set to: <span class=\"notification-key\">" .. val .. "%</span>",
                                type = 'success'
                                }))
                        end,
                        onChange = function(val)
                            local playerId = PlayerId()
                            local staminaValue = val * 10.0 -- Convert to game stamina value (0-1000)
                            SetPlayerStamina(playerId, staminaValue)
                            end
                    },
                    {
                        label = 'Infinite Stamina',
                        type = 'checkbox',
                        icon = 'fas fa-infinity',
                        checked = false,
                        onConfirm = function(toggle)
                            playerModStates.infiniteStamina = toggle
                            local playerId = PlayerId()
                            
                            if toggle then
                                -- Stop existing thread if running
                                if playerModThreads.infiniteStamina then
                                    playerModThreads.infiniteStamina = nil
                                end
                                
                                playerModThreads.infiniteStamina = CreateThread(function()
                                    while playerModStates.infiniteStamina do
                                        if GetPlayerStamina(playerId) < 1000.0 then
                                            SetPlayerStamina(playerId, 1000.0)
                                        end
                                        Wait(100)
                                    end
                                end)
                            else
                                playerModThreads.infiniteStamina = nil
                            end
                            
                            sendOptimizedNotification("Infinite Stamina: <span class=\"notification-key\">" .. (toggle and "ON" or "OFF") .. "</span>", toggle and 'success' or 'info')
                        end
                    }
                }
            },
            {
                label = 'Teleportation',
                type = 'submenu',
                icon = 'fas fa-location-arrow',
                submenu = {
                    {
                        label = 'Teleport to Waypoint',
                        type = 'button',
                        icon = 'fas fa-map-marker-alt',
                        onConfirm = function()
                            local waypoint = GetFirstBlipInfoId(8)
                            if DoesBlipExist(waypoint) then
                                local waypointCoords = GetBlipInfoIdCoord(waypoint)
                                local groundZ = 0.0
                                local foundGround, groundZ = GetGroundZFor_3dCoord(waypointCoords.x, waypointCoords.y, waypointCoords.z + 1000.0, false)
                                
                                if foundGround then
                                    SetEntityCoords(PlayerPedId(), waypointCoords.x, waypointCoords.y, groundZ + 1.0, false, false, false, true)
                                        MachoSendDuiMessage(dui, json.encode({
                                            action = 'notify',
                                        message = "Teleported to <span class=\"notification-key\">Waypoint</span>",
                                            type = 'success'
                                        }))
                                else
                                        MachoSendDuiMessage(dui, json.encode({
                                            action = 'notify',
                                        message = "Could not find ground at waypoint!",
                                            type = 'error'
                                        }))
                                end
                            else
                                    MachoSendDuiMessage(dui, json.encode({
                                        action = 'notify',
                                        message = "No waypoint set!",
                                        type = 'error'
                                    }))
                            end
                        end
                    },
                    {
                        label = 'Teleport to Airport',
                        type = 'button',
                        icon = 'fas fa-plane',
                        onConfirm = function()
                            local coords = vector3(-1037.0, -2737.0, 20.0)
                            SetEntityCoords(PlayerPedId(), coords.x, coords.y, coords.z, false, false, false, true)
                                MachoSendDuiMessage(dui, json.encode({
                                    action = 'notify',
                                message = "Teleported to <span class=\"notification-key\">Airport</span>",
                                    type = 'success'
                                }))
                            end
                    },
                    {
                        label = 'Teleport to City',
                        type = 'button',
                        icon = 'fas fa-city',
                        onConfirm = function()
                            local coords = vector3(-269.0, -955.0, 31.0)
                            SetEntityCoords(PlayerPedId(), coords.x, coords.y, coords.z, false, false, false, true)
                            MachoSendDuiMessage(dui, json.encode({
                                action = 'notify',
                                message = "Teleported to <span class=\"notification-key\">City Center</span>",
                                type = 'success'
                            }))
                        end
                    },
                    {
                        label = 'Teleport to Hospital',
                        type = 'button',
                        icon = 'fas fa-hospital',
                        onConfirm = function()
                            local coords = vector3(298.0, -584.0, 43.0)
                            SetEntityCoords(PlayerPedId(), coords.x, coords.y, coords.z, false, false, false, true)
                                MachoSendDuiMessage(dui, json.encode({
                                    action = 'notify',
                                message = "Teleported to <span class=\"notification-key\">Hospital</span>",
                                    type = 'success'
                                }))
                        end
                    },
                    {
                        label = 'Teleport to Police Station',
                        type = 'button',
                        icon = 'fas fa-shield-alt',
                        onConfirm = function()
                            local coords = vector3(425.0, -979.0, 30.0)
                            SetEntityCoords(PlayerPedId(), coords.x, coords.y, coords.z, false, false, false, true)
                                MachoSendDuiMessage(dui, json.encode({
                                    action = 'notify',
                                message = "Teleported to <span class=\"notification-key\">Police Station</span>",
                                    type = 'success'
                                }))
                            end
                    }
                }
            },
            {
                label = 'Speed Modifier',
                type = 'submenu',
                icon = 'fas fa-tachometer-alt',
                submenu = {
                    {
                        label = 'Run Speed',
                        type = 'slider',
                        icon = 'fas fa-running',
                        min = 0,
                        max = 200,
                        value = 100,
                        step = 5,
                        onConfirm = function(val)
                            local ped = PlayerPedId()
                            local speedMultiplier = val / 100.0
                            SetRunSprintMultiplierForPlayer(PlayerId(), speedMultiplier)
                                MachoSendDuiMessage(dui, json.encode({
                                    action = 'notify',
                                message = "Run Speed set to: <span class=\"notification-key\">" .. val .. "%</span>",
                                    type = 'success'
                                }))
                        end,
                        onChange = function(val)
                            local speedMultiplier = val / 100.0
                            SetRunSprintMultiplierForPlayer(PlayerId(), speedMultiplier)
                        end
                    },
                    {
                        label = 'Swim Speed',
                        type = 'slider',
                        icon = 'fas fa-swimmer',
                        min = 0,
                        max = 200,
                        value = 100,
                        step = 5,
                        onConfirm = function(val)
                            local ped = PlayerPedId()
                            local speedMultiplier = val / 100.0
                            SetSwimMultiplierForPlayer(PlayerId(), speedMultiplier)
                                MachoSendDuiMessage(dui, json.encode({
                                    action = 'notify',
                                message = "Swim Speed set to: <span class=\"notification-key\">" .. val .. "%</span>",
                                    type = 'success'
                                }))
                        end,
                        onChange = function(val)
                            local speedMultiplier = val / 100.0
                            SetSwimMultiplierForPlayer(PlayerId(), speedMultiplier)
                        end
                    },
                    {
                        label = 'Walk Speed',
                        type = 'slider',
                        icon = 'fas fa-walking',
                        min = 0,
                        max = 200,
                        value = 100,
                        step = 5,
                        onConfirm = function(val)
                            local ped = PlayerPedId()
                            local speedMultiplier = val / 100.0
                            SetPedMoveRateOverride(ped, speedMultiplier)
                                MachoSendDuiMessage(dui, json.encode({
                                    action = 'notify',
                                message = "Walk Speed set to: <span class=\"notification-key\">" .. val .. "%</span>",
                                    type = 'success'
                                }))
                        end,
                        onChange = function(val)
                            local ped = PlayerPedId()
                            local speedMultiplier = val / 100.0
                            SetPedMoveRateOverride(ped, speedMultiplier)
                        end
                    },
                    {
                        label = 'Super Jump',
                        type = 'checkbox',
                        icon = 'fas fa-rocket',
                        checked = false,
                        onConfirm = function(toggle)
                            local ped = PlayerPedId()
                            if toggle then
                                SetSuperJumpThisFrame(PlayerId())
                                CreateThread(function()
                                    while true do
                                        SetSuperJumpThisFrame(PlayerId())
                                        Wait(0)
                                    end
                                end)
                            end
                                    MachoSendDuiMessage(dui, json.encode({
                                        action = 'notify',
                                message = "Super Jump: <span class=\"notification-key\">" .. (toggle and "ON" or "OFF") .. "</span>",
                                type = toggle and 'success' or 'info'
                                    }))
                                end
                    }
                }
            },
            {
                label = "HUD & Map",
                type = 'submenu',
                icon = 'fas fa-eye',
                submenu = {
                    {
                        label = 'Weapon Wheel',
                        type = 'checkbox',
                        icon = 'fas fa-eye',
                        checked = false,
                        onConfirm = function(toggle)
                            DisplayHud(toggle)
                                    MachoSendDuiMessage(dui, json.encode({
                                        action = 'notify',
                                message = "HUD: <span class=\"notification-key\">" .. (toggle and "ON" or "OFF") .. "</span>",
                                type = toggle and 'success' or 'info'
                                    }))
                                end
                    },
                    {
                        label = 'Map',
                        type = 'checkbox',
                        icon = 'fas fa-map',
                        checked = true,
                        onConfirm = function(toggle)
                            DisplayRadar(toggle)
                            MachoSendDuiMessage(dui, json.encode({
                                action = 'notify',
                                message = "Radar: <span class=\"notification-key\">" .. (toggle and "ON" or "OFF") .. "</span>",
                                type = toggle and 'success' or 'info'
                            }))
                        end
                    }
                }
            },
            {
                label = 'Combat Movement',
                type = 'submenu',
                icon = 'fas fa-fist-raised',
                submenu = {
                    {
                        label = 'Fake Combat Roll',
                        type = 'checkbox',
                        icon = 'fas fa-dice',
                        checked = false,
                        onConfirm = function(toggle)
                            if toggle then
                                -- Speed boost for fake combat roll (spoofed - others see it)
                                CreateThread(function()
                                    while true do
                                        local ped = PlayerPedId()
                                        if IsControlPressed(0, 22) then -- Space key
                                            -- Apply speed boost during roll
                                            SetRunSprintMultiplierForPlayer(PlayerId(), 2.0)
                                            SetSwimMultiplierForPlayer(PlayerId(), 2.0)
                                            Wait(100)
                                            SetRunSprintMultiplierForPlayer(PlayerId(), 1.0)
                                            SetSwimMultiplierForPlayer(PlayerId(), 1.0)
                                        end
                                        Wait(0)
                                    end
                                end)
                            end
                            
                                    MachoSendDuiMessage(dui, json.encode({
                                        action = 'notify',
                                message = "Fake Combat Roll: <span class=\"notification-key\">" .. (toggle and "ON" or "OFF") .. "</span>",
                                type = toggle and 'success' or 'info'
                                    }))
                                end
                    },
                    {
                        label = 'Fake Combat Crouch',
                        type = 'checkbox',
                        icon = 'fas fa-user-secret',
                        checked = false,
                        onConfirm = function(toggle)
                            local ped = PlayerPedId()
                            if toggle then
                                -- Request crouch clipset (spoofed - others see it)
                                RequestAnimSet("move_ped_crouched")
                                while not HasAnimSetLoaded("move_ped_crouched") do
                                    Wait(0)
                                end
                                
                                -- Apply crouch movement (spoofed - others see it)
                                SetPedMovementClipset(ped, "move_ped_crouched", 0.25)
                                SetPedStrafeClipset(ped, "move_ped_crouched_strafing")
                            else
                                -- Reset back to normal
                                ResetPedMovementClipset(ped, 0.25)
                                ResetPedStrafeClipset(ped)
                            end
                            
                                    MachoSendDuiMessage(dui, json.encode({
                                        action = 'notify',
                                message = "Fake Combat Crouch: <span class=\"notification-key\">" .. (toggle and "ON" or "OFF") .. "</span>",
                                type = toggle and 'success' or 'info'
                                    }))
                        end
                    },
                    {
                        label = 'Infinite Combat Roll',
                        type = 'checkbox',
                        icon = 'fas fa-infinity',
                        checked = false,
                        onConfirm = function(toggle)
                            local ped = PlayerPedId()
                            InfiniteCombatRoll = toggle -- keep track of toggle state
                            
                            if toggle then
                                CreateThread(function()
                                    while InfiniteCombatRoll do
                                        -- Continuous speed boost for infinite combat roll (spoofed - others see it)
                                        if IsControlPressed(0, 22) then -- Space key
                                            SetRunSprintMultiplierForPlayer(PlayerId(), 2.5)
                                            SetSwimMultiplierForPlayer(PlayerId(), 2.5)
                                            Wait(200)
                                            SetRunSprintMultiplierForPlayer(PlayerId(), 1.0)
                                            SetSwimMultiplierForPlayer(PlayerId(), 1.0)
                                        end
                                        Wait(0)
                                    end
                                end)
                            end
                            
                                    MachoSendDuiMessage(dui, json.encode({
                                        action = 'notify',
                                message = "Infinite Combat Roll: <span class=\"notification-key\">" .. (toggle and "ON" or "OFF") .. "</span>",
                                type = toggle and 'success' or 'info'
                                    }))
                                end
                    },
                    {
                        label = 'Combat Stance Disable',
                        type = 'checkbox',
                        icon = 'fas fa-shield',
                        checked = false,
                        onConfirm = function(toggle)
                            local ped = PlayerPedId()
                            if toggle then
                                -- Disable combat stance (spoofed - others see it)
                                ResetPedMovementClipset(ped, 0.0)
                                ResetPedStrafeClipset(ped)
                                SetPedCanSwitchWeapon(ped, true)
                            else
                                -- Restore normal combat behavior
                                ResetPedMovementClipset(ped, 0.0)
                                ResetPedStrafeClipset(ped)
                                SetPedCanSwitchWeapon(ped, true)
                            end
                            
                                    MachoSendDuiMessage(dui, json.encode({
                                        action = 'notify',
                                message = "Combat Stance Disable: <span class=\"notification-key\">" .. (toggle and "ON" or "OFF") .. "</span>",
                                type = toggle and 'success' or 'info'
                                    }))
                                end
                    },
                    {
                        label = 'Combat Roll Cooldown',
                        type = 'checkbox',
                        icon = 'fas fa-clock',
                        checked = false,
                        onConfirm = function(toggle)
                            if toggle then
                                -- Set combat roll cooldown to 120 (2 minutes) - spoofed
                                local cooldown = 120
                                for i = 0, 3 do
                                    StatSetInt(GetHashKey("mp" .. i .. "_shooting_ability"), cooldown, true)
                                    StatSetInt(GetHashKey("sp" .. i .. "_shooting_ability"), cooldown, true)
                                end
                                
                                MachoSendDuiMessage(dui, json.encode({
                                    action = 'notify',
                                    message = "Combat Roll Cooldown: <span class=\"notification-key\">SET</span> to 2 minutes",
                                    type = 'success'
                                }))
                            else
                                -- Reset cooldown to 0
                                for i = 0, 3 do
                                    StatSetInt(GetHashKey("mp" .. i .. "_shooting_ability"), 0, true)
                                    StatSetInt(GetHashKey("sp" .. i .. "_shooting_ability"), 0, true)
                                end
                                
                                MachoSendDuiMessage(dui, json.encode({
                                    action = 'notify',
                                    message = "Combat Roll Cooldown: <span class=\"notification-key\">RESET</span>",
                                    type = 'info'
                                }))
                            end
                        end
                    },
                    {
                        label = 'No Ragdoll',
                        type = 'checkbox',
                        icon = 'fas fa-user-slash',
                        checked = false,
                        onConfirm = function(toggle)
                            local ped = PlayerPedId()
                            SetPedCanRagdoll(ped, not toggle)
                                MachoSendDuiMessage(dui, json.encode({
                                    action = 'notify',
                                message = "No Ragdoll: <span class=\"notification-key\">" .. (toggle and "ON" or "OFF") .. "</span>",
                                type = toggle and 'success' or 'info'
                                }))
                        end
                    },
                    {
                        label = 'No Fall Damage',
                        type = 'checkbox',
                        icon = 'fas fa-shield-alt',
                        checked = false,
                        onConfirm = function(toggle)
                            local ped = PlayerPedId()
                            if toggle then
                                CreateThread(function()
                                    while true do
                                        if GetEntityHeightAboveGround(ped) > 1.0 then
                                            SetPedCanRagdoll(ped, false)
                                        end
                                        Wait(100)
                                    end
                                end)
                            end
                                    MachoSendDuiMessage(dui, json.encode({
                                        action = 'notify',
                                message = "No Fall Damage: <span class=\"notification-key\">" .. (toggle and "ON" or "OFF") .. "</span>",
                                type = toggle and 'success' or 'info'
                                    }))
                                end
                    }
                }
            }
        }
    },
    {
        label = "Weapons",
        type = 'submenu',
        icon = 'fas fa-gun',
        submenu = {
            {
                label = 'Give Weapons',
                type = 'submenu',
                icon = 'fas fa-plus-circle',
                submenu = {
                    {
                        label = 'Pistols',
                        type = 'submenu',
                        icon = 'fas fa-gun',
                        submenu = {
                            {
                                label = 'Pistol',
                                type = 'button',
                                icon = 'fas fa-gun',
                                onConfirm = function()
                                    local ped = PlayerPedId()
                                    GiveWeaponToPed(ped, GetHashKey('WEAPON_PISTOL'), 250, false, true)
                                    SetCurrentPedWeapon(ped, GetHashKey('WEAPON_PISTOL'), true)
                                    sendOptimizedNotification("Gave <span class=\"notification-key\">Pistol</span>", 'success')
                                end
                            },
                            {
                                label = 'Combat Pistol',
                                type = 'button',
                                icon = 'fas fa-gun',
                                onConfirm = function()
                                    local ped = PlayerPedId()
                                    GiveWeaponToPed(ped, GetHashKey('WEAPON_COMBATPISTOL'), 250, false, true)
                                    SetCurrentPedWeapon(ped, GetHashKey('WEAPON_COMBATPISTOL'), true)
                                    sendOptimizedNotification("Gave <span class=\"notification-key\">Combat Pistol</span>", 'success')
                                end
                            },
                            {
                                label = 'AP Pistol',
                                type = 'button',
                                icon = 'fas fa-gun',
                                onConfirm = function()
                                    local ped = PlayerPedId()
                                    GiveWeaponToPed(ped, GetHashKey('WEAPON_APPISTOL'), 250, false, true)
                                    MachoSendDuiMessage(dui, json.encode({
                                        action = 'notify',
                                        message = "Gave <span class=\"notification-key\">AP Pistol</span>",
                                        type = 'success'
                                    }))
                                end
                            },
                            {
                                label = 'Heavy Pistol',
                                type = 'button',
                                icon = 'fas fa-gun',
                                onConfirm = function()
                                    local ped = PlayerPedId()
                                    GiveWeaponToPed(ped, GetHashKey('WEAPON_HEAVYPISTOL'), 250, false, true)
                                    MachoSendDuiMessage(dui, json.encode({
                                        action = 'notify',
                                        message = "Gave <span class=\"notification-key\">Heavy Pistol</span>",
                                        type = 'success'
                                    }))
                                end
                            }
                        }
                    },
                    {
                        label = 'Rifles',
                        type = 'submenu',
                        icon = 'fas fa-crosshairs',
                        submenu = {
                            {
                                label = 'Assault Rifle',
                                type = 'button',
                                icon = 'fas fa-crosshairs',
                                onConfirm = function()
                                    local ped = PlayerPedId()
                                    GiveWeaponToPed(ped, GetHashKey('WEAPON_ASSAULTRIFLE'), 250, false, true)
                                    MachoSendDuiMessage(dui, json.encode({
                                        action = 'notify',
                                        message = "Gave <span class=\"notification-key\">Assault Rifle</span>",
                                        type = 'success'
                                    }))
                                end
                            },
                            {
                                label = 'Carbine Rifle',
                                type = 'button',
                                icon = 'fas fa-crosshairs',
                                onConfirm = function()
                                    local ped = PlayerPedId()
                                    GiveWeaponToPed(ped, GetHashKey('WEAPON_CARBINERIFLE'), 250, false, true)
                                    MachoSendDuiMessage(dui, json.encode({
                                        action = 'notify',
                                        message = "Gave <span class=\"notification-key\">Carbine Rifle</span>",
                                        type = 'success'
                                    }))
                                end
                            },
                            {
                                label = 'Special Carbine',
                                type = 'button',
                                icon = 'fas fa-crosshairs',
                                onConfirm = function()
                                    local ped = PlayerPedId()
                                    GiveWeaponToPed(ped, GetHashKey('WEAPON_SPECIALCARBINE'), 250, false, true)
                                    MachoSendDuiMessage(dui, json.encode({
                                        action = 'notify',
                                        message = "Gave <span class=\"notification-key\">Special Carbine</span>",
                                        type = 'success'
                                    }))
                                end
                            },
                            {
                                label = 'Bullpup Rifle',
                                type = 'button',
                                icon = 'fas fa-crosshairs',
                                onConfirm = function()
                                    local ped = PlayerPedId()
                                    GiveWeaponToPed(ped, GetHashKey('WEAPON_BULLPUPRIFLE'), 250, false, true)
                                    MachoSendDuiMessage(dui, json.encode({
                                        action = 'notify',
                                        message = "Gave <span class=\"notification-key\">Bullpup Rifle</span>",
                                        type = 'success'
                                    }))
                                end
                            }
                        }
                    },
                    {
                        label = 'Heavy Weapons',
                        type = 'submenu',
                        icon = 'fas fa-bomb',
                        submenu = {
                            {
                                label = 'RPG',
                                type = 'button',
                                icon = 'fas fa-rocket',
                                onConfirm = function()
                                    local ped = PlayerPedId()
                                    GiveWeaponToPed(ped, GetHashKey('WEAPON_RPG'), 10, false, true)
                                    MachoSendDuiMessage(dui, json.encode({
                                        action = 'notify',
                                        message = "Gave <span class=\"notification-key\">RPG</span>",
                                        type = 'success'
                                    }))
                                end
                            },
                            {
                                label = 'Minigun',
                                type = 'button',
                                icon = 'fas fa-bomb',
                                onConfirm = function()
                                    local ped = PlayerPedId()
                                    GiveWeaponToPed(ped, GetHashKey('WEAPON_MINIGUN'), 1000, false, true)
                                    MachoSendDuiMessage(dui, json.encode({
                                        action = 'notify',
                                        message = "Gave <span class=\"notification-key\">Minigun</span>",
                                        type = 'success'
                                    }))
                                end
                            },
                            {
                                label = 'Grenade Launcher',
                                type = 'button',
                                icon = 'fas fa-bomb',
                                onConfirm = function()
                                    local ped = PlayerPedId()
                                    GiveWeaponToPed(ped, GetHashKey('WEAPON_GRENADELAUNCHER'), 25, false, true)
                                    MachoSendDuiMessage(dui, json.encode({
                                        action = 'notify',
                                        message = "Gave <span class=\"notification-key\">Grenade Launcher</span>",
                                        type = 'success'
                                    }))
                                end
                            }
                        }
                    }
                }
            },
            {
                label = 'Remove All Weapons',
                type = 'button',
                icon = 'fas fa-trash',
                onConfirm = function()
                    local ped = PlayerPedId()
                    RemoveAllPedWeapons(ped, true)
                    MachoSendDuiMessage(dui, json.encode({
                        action = 'notify',
                        message = "Removed <span class=\"notification-key\">ALL WEAPONS</span>",
                        type = 'success'
                    }))
                end
            },
            {
                label = 'Infinite Ammo',
                type = 'checkbox',
                icon = 'fas fa-infinity',
                checked = false,
                onConfirm = function(toggle)
                    if toggle then
                        CreateThread(function()
                            while true do
                                local ped = PlayerPedId()
                                local weapon = GetSelectedPedWeapon(ped)
                                if weapon ~= GetHashKey('WEAPON_UNARMED') then
                                    SetPedAmmo(ped, weapon, 999)
                                end
                                Wait(100)
                            end
                        end)
                    end
                    MachoSendDuiMessage(dui, json.encode({
                        action = 'notify',
                        message = "Infinite Ammo: <span class=\"notification-key\">" .. (toggle and "ON" or "OFF") .. "</span>",
                        type = toggle and 'success' or 'info'
                    }))
                end
            },
            {
                label = 'No Reload',
                type = 'checkbox',
                icon = 'fas fa-sync-alt',
                checked = false,
                onConfirm = function(toggle)
                    local ped = PlayerPedId()
                    if toggle then
                        SetPedInfiniteAmmo(ped, true)
                        SetPedInfiniteAmmoClip(ped, true)
                    else
                        SetPedInfiniteAmmo(ped, false)
                        SetPedInfiniteAmmoClip(ped, false)
                    end
                    MachoSendDuiMessage(dui, json.encode({
                        action = 'notify',
                        message = "No Reload: <span class=\"notification-key\">" .. (toggle and "ON" or "OFF") .. "</span>",
                        type = toggle and 'success' or 'info'
                    }))
                end
            },
            {
                label = 'Weapon Modifications',
                type = 'submenu',
                icon = 'fas fa-cogs',
                submenu = {
                    {
                        label = 'Explosive Ammo',
                        type = 'checkbox',
                        icon = 'fas fa-bomb',
                        checked = false,
                        onConfirm = function(toggle)
                            weaponModStates.explosiveAmmo = toggle
                            
                            if toggle then
                                -- Stop existing thread if running
                                if weaponModThreads.explosiveAmmo then
                                    weaponModThreads.explosiveAmmo = nil
                                end
                                
                                weaponModThreads.explosiveAmmo = CreateThread(function()
                                    while weaponModStates.explosiveAmmo do
                                        local ped = PlayerPedId()
                                        local weapon = GetSelectedPedWeapon(ped)
                                        if weapon ~= GetHashKey('WEAPON_UNARMED') then
                                            SetWeaponDamageModifier(weapon, 10.0)
                                            -- Use correct native for weapon damage
                                            SetWeaponDamageModifier(weapon, 10.0)
                                        end
                                        Wait(100)
                                    end
                                end)
                            else
                                -- Reset weapon damage when disabled
                                local ped = PlayerPedId()
                                local weapon = GetSelectedPedWeapon(ped)
                                if weapon ~= GetHashKey('WEAPON_UNARMED') then
                                    SetWeaponDamageModifier(weapon, 1.0)
                                end
                                weaponModThreads.explosiveAmmo = nil
                            end
                            
                            sendOptimizedNotification("Explosive Ammo: <span class=\"notification-key\">" .. (toggle and "ON" or "OFF") .. "</span>", toggle and 'success' or 'info')
                        end
                    },
                    {
                        label = 'Rapid Fire',
                        type = 'checkbox',
                        icon = 'fas fa-bolt',
                        checked = false,
                        onConfirm = function(toggle)
                            weaponModStates.rapidFire = toggle
                            
                            if toggle then
                                -- Stop existing thread if running
                                if weaponModThreads.rapidFire then
                                    weaponModThreads.rapidFire = nil
                                end
                                
                                weaponModThreads.rapidFire = CreateThread(function()
                                    while weaponModStates.rapidFire do
                                        local ped = PlayerPedId()
                                        local weapon = GetSelectedPedWeapon(ped)
                                        if weapon ~= GetHashKey('WEAPON_UNARMED') then
                                            -- Use SetPedInfiniteAmmo for rapid fire effect
                                            SetPedInfiniteAmmo(ped, true)
                                            SetPedInfiniteAmmoClip(ped, true)
                                        end
                                        Wait(100)
                                    end
                                end)
                            else
                                -- Reset weapon settings when disabled
                                local ped = PlayerPedId()
                                local weapon = GetSelectedPedWeapon(ped)
                                if weapon ~= GetHashKey('WEAPON_UNARMED') then
                                    SetPedInfiniteAmmo(ped, false)
                                    SetPedInfiniteAmmoClip(ped, false)
                                end
                                weaponModThreads.rapidFire = nil
                            end
                            
                            sendOptimizedNotification("Rapid Fire: <span class=\"notification-key\">" .. (toggle and "ON" or "OFF") .. "</span>", toggle and 'success' or 'info')
                        end
                    },
                    {
                        label = 'One Shot Kill',
                        type = 'checkbox',
                        icon = 'fas fa-crosshairs',
                        checked = false,
                        onConfirm = function(toggle)
                            weaponModStates.oneShotKill = toggle
                            
                            if toggle then
                                -- Stop existing thread if running
                                if weaponModThreads.oneShotKill then
                                    weaponModThreads.oneShotKill = nil
                                end
                                
                                weaponModThreads.oneShotKill = CreateThread(function()
                                    while weaponModStates.oneShotKill do
                                        local ped = PlayerPedId()
                                        local weapon = GetSelectedPedWeapon(ped)
                                        if weapon ~= GetHashKey('WEAPON_UNARMED') then
                                            SetWeaponDamageModifier(weapon, 1000.0)
                                        end
                                        Wait(100)
                                    end
                                end)
                            else
                                -- Reset weapon damage when disabled
                                local ped = PlayerPedId()
                                local weapon = GetSelectedPedWeapon(ped)
                                if weapon ~= GetHashKey('WEAPON_UNARMED') then
                                    SetWeaponDamageModifier(weapon, 1.0)
                                end
                                weaponModThreads.oneShotKill = nil
                            end
                            
                            sendOptimizedNotification("One Shot Kill: <span class=\"notification-key\">" .. (toggle and "ON" or "OFF") .. "</span>", toggle and 'success' or 'info')
                        end
                    },
                    {
                        label = 'No Recoil',
                        type = 'checkbox',
                        icon = 'fas fa-hand-rock',
                        checked = false,
                        onConfirm = function(toggle)
                            weaponModStates.noRecoil = toggle
                            
                            if toggle then
                                -- Stop existing thread if running
                                if weaponModThreads.noRecoil then
                                    weaponModThreads.noRecoil = nil
                                end
                                
                                weaponModThreads.noRecoil = CreateThread(function()
                                    while weaponModStates.noRecoil do
                                        local ped = PlayerPedId()
                                        local weapon = GetSelectedPedWeapon(ped)
                                        if weapon ~= GetHashKey('WEAPON_UNARMED') then
                                            -- Use SetPedAccuracy for no recoil effect
                                            SetPedAccuracy(ped, 100)
                                        end
                                        Wait(100)
                                    end
                                end)
                            else
                                -- Reset weapon recoil when disabled
                                local ped = PlayerPedId()
                                local weapon = GetSelectedPedWeapon(ped)
                                if weapon ~= GetHashKey('WEAPON_UNARMED') then
                                    SetPedAccuracy(ped, 50) -- Reset to normal accuracy
                                end
                                weaponModThreads.noRecoil = nil
                            end
                            
                            sendOptimizedNotification("No Recoil: <span class=\"notification-key\">" .. (toggle and "ON" or "OFF") .. "</span>", toggle and 'success' or 'info')
                        end
                    }
                }
            },
            {
                label = 'Special Weapons',
                type = 'submenu',
                icon = 'fas fa-rocket',
                submenu = {
                    {
                        label = 'Railgun',
                        type = 'button',
                        icon = 'fas fa-bolt',
                        onConfirm = function()
                            local ped = PlayerPedId()
                            GiveWeaponToPed(ped, GetHashKey('WEAPON_RAILGUN'), 50, false, true)
                            SetCurrentPedWeapon(ped, GetHashKey('WEAPON_RAILGUN'), true)
                            sendOptimizedNotification("Gave <span class=\"notification-key\">Railgun</span>", 'success')
                        end
                    },
                    {
                        label = 'Minigun',
                        type = 'button',
                        icon = 'fas fa-crosshairs',
                        onConfirm = function()
                            local ped = PlayerPedId()
                            GiveWeaponToPed(ped, GetHashKey('WEAPON_MINIGUN'), 1000, false, true)
                            SetCurrentPedWeapon(ped, GetHashKey('WEAPON_MINIGUN'), true)
                            sendOptimizedNotification("Gave <span class=\"notification-key\">Minigun</span>", 'success')
                        end
                    },
                    {
                        label = 'Firework Launcher',
                        type = 'button',
                        icon = 'fas fa-fire',
                        onConfirm = function()
                            local ped = PlayerPedId()
                            GiveWeaponToPed(ped, GetHashKey('WEAPON_FIREWORK'), 20, false, true)
                            SetCurrentPedWeapon(ped, GetHashKey('WEAPON_FIREWORK'), true)
                            sendOptimizedNotification("Gave <span class=\"notification-key\">Firework Launcher</span>", 'success')
                        end
                    },
                    {
                        label = 'RPG',
                        type = 'button',
                        icon = 'fas fa-rocket',
                        onConfirm = function()
                            local ped = PlayerPedId()
                            GiveWeaponToPed(ped, GetHashKey('WEAPON_RPG'), 10, false, true)
                            SetCurrentPedWeapon(ped, GetHashKey('WEAPON_RPG'), true)
                            sendOptimizedNotification("Gave <span class=\"notification-key\">RPG</span>", 'success')
                        end
                    },
                    {
                        label = 'Grenade Launcher',
                        type = 'button',
                        icon = 'fas fa-bomb',
                        onConfirm = function()
                            local ped = PlayerPedId()
                            GiveWeaponToPed(ped, GetHashKey('WEAPON_GRENADELAUNCHER'), 20, false, true)
                            SetCurrentPedWeapon(ped, GetHashKey('WEAPON_GRENADELAUNCHER'), true)
                            sendOptimizedNotification("Gave <span class=\"notification-key\">Grenade Launcher</span>", 'success')
                        end
                    },
                    {
                        label = 'Homing Launcher',
                        type = 'button',
                        icon = 'fas fa-bullseye',
                        onConfirm = function()
                            local ped = PlayerPedId()
                            GiveWeaponToPed(ped, GetHashKey('WEAPON_HOMINGLAUNCHER'), 5, false, true)
                            SetCurrentPedWeapon(ped, GetHashKey('WEAPON_HOMINGLAUNCHER'), true)
                            sendOptimizedNotification("Gave <span class=\"notification-key\">Homing Launcher</span>", 'success')
                        end
                    },
                    {
                        label = 'Compact Launcher',
                        type = 'button',
                        icon = 'fas fa-rocket',
                        onConfirm = function()
                            local ped = PlayerPedId()
                            GiveWeaponToPed(ped, GetHashKey('WEAPON_COMPACTLAUNCHER'), 20, false, true)
                            SetCurrentPedWeapon(ped, GetHashKey('WEAPON_COMPACTLAUNCHER'), true)
                            sendOptimizedNotification("Gave <span class=\"notification-key\">Compact Launcher</span>", 'success')
                        end
                    },
                    {
                        label = 'Heavy Sniper',
                        type = 'button',
                        icon = 'fas fa-crosshairs',
                        onConfirm = function()
                            local ped = PlayerPedId()
                            GiveWeaponToPed(ped, GetHashKey('WEAPON_HEAVYSNIPER'), 50, false, true)
                            SetCurrentPedWeapon(ped, GetHashKey('WEAPON_HEAVYSNIPER'), true)
                            sendOptimizedNotification("Gave <span class=\"notification-key\">Heavy Sniper</span>", 'success')
                        end
                    }
                }
            },
            {
                label = 'Melee Weapons',
                type = 'submenu',
                icon = 'fas fa-fist-raised',
                submenu = {
                    {
                        label = 'Knife',
                        type = 'button',
                        icon = 'fas fa-cut',
                        onConfirm = function()
                            local ped = PlayerPedId()
                            GiveWeaponToPed(ped, GetHashKey('WEAPON_KNIFE'), 1, false, true)
                            SetCurrentPedWeapon(ped, GetHashKey('WEAPON_KNIFE'), true)
                            sendOptimizedNotification("Gave <span class=\"notification-key\">Knife</span>", 'success')
                        end
                    },
                    {
                        label = 'Baseball Bat',
                        type = 'button',
                        icon = 'fas fa-baseball-ball',
                        onConfirm = function()
                            local ped = PlayerPedId()
                            GiveWeaponToPed(ped, GetHashKey('WEAPON_BAT'), 1, false, true)
                            SetCurrentPedWeapon(ped, GetHashKey('WEAPON_BAT'), true)
                            sendOptimizedNotification("Gave <span class=\"notification-key\">Baseball Bat</span>", 'success')
                        end
                    },
                    {
                        label = 'Crowbar',
                        type = 'button',
                        icon = 'fas fa-tools',
                        onConfirm = function()
                            local ped = PlayerPedId()
                            GiveWeaponToPed(ped, GetHashKey('WEAPON_CROWBAR'), 1, false, true)
                            SetCurrentPedWeapon(ped, GetHashKey('WEAPON_CROWBAR'), true)
                            sendOptimizedNotification("Gave <span class=\"notification-key\">Crowbar</span>", 'success')
                        end
                    },
                    {
                        label = 'Machete',
                        type = 'button',
                        icon = 'fas fa-cut',
                        onConfirm = function()
                            local ped = PlayerPedId()
                            GiveWeaponToPed(ped, GetHashKey('WEAPON_MACHETE'), 1, false, true)
                            SetCurrentPedWeapon(ped, GetHashKey('WEAPON_MACHETE'), true)
                            sendOptimizedNotification("Gave <span class=\"notification-key\">Machete</span>", 'success')
                        end
                    },
                    {
                        label = 'Switchblade',
                        type = 'button',
                        icon = 'fas fa-cut',
                        onConfirm = function()
                            local ped = PlayerPedId()
                            GiveWeaponToPed(ped, GetHashKey('WEAPON_SWITCHBLADE'), 1, false, true)
                            SetCurrentPedWeapon(ped, GetHashKey('WEAPON_SWITCHBLADE'), true)
                            sendOptimizedNotification("Gave <span class=\"notification-key\">Switchblade</span>", 'success')
                        end
                    },
                    {
                        label = 'Hammer',
                        type = 'button',
                        icon = 'fas fa-hammer',
                        onConfirm = function()
                            local ped = PlayerPedId()
                            GiveWeaponToPed(ped, GetHashKey('WEAPON_HAMMER'), 1, false, true)
                            SetCurrentPedWeapon(ped, GetHashKey('WEAPON_HAMMER'), true)
                            sendOptimizedNotification("Gave <span class=\"notification-key\">Hammer</span>", 'success')
                        end
                    },
                    {
                        label = 'Hatchet',
                        type = 'button',
                        icon = 'fas fa-cut',
                        onConfirm = function()
                            local ped = PlayerPedId()
                            GiveWeaponToPed(ped, GetHashKey('WEAPON_HATCHET'), 1, false, true)
                            SetCurrentPedWeapon(ped, GetHashKey('WEAPON_HATCHET'), true)
                            sendOptimizedNotification("Gave <span class=\"notification-key\">Hatchet</span>", 'success')
                        end
                    },
                    {
                        label = 'Golf Club',
                        type = 'button',
                        icon = 'fas fa-golf-ball',
                        onConfirm = function()
                            local ped = PlayerPedId()
                            GiveWeaponToPed(ped, GetHashKey('WEAPON_GOLFCLUB'), 1, false, true)
                            SetCurrentPedWeapon(ped, GetHashKey('WEAPON_GOLFCLUB'), true)
                            sendOptimizedNotification("Gave <span class=\"notification-key\">Golf Club</span>", 'success')
                        end
                    }
                }
            },
            {
                label = 'Weapon Utilities',
                type = 'submenu',
                icon = 'fas fa-tools',
                submenu = {
                    {
                        label = 'Give All Weapons',
                        type = 'button',
                        icon = 'fas fa-gift',
                        onConfirm = function()
                            local ped = PlayerPedId()
                            local weapons = {
                                'WEAPON_PISTOL', 'WEAPON_COMBATPISTOL', 'WEAPON_APPISTOL', 'WEAPON_PISTOL50',
                                'WEAPON_MICROSMG', 'WEAPON_SMG', 'WEAPON_ASSAULTSMG', 'WEAPON_COMBATMG',
                                'WEAPON_ASSAULTRIFLE', 'WEAPON_CARBINERIFLE', 'WEAPON_ADVANCEDRIFLE', 'WEAPON_MG',
                                'WEAPON_COMBATMG', 'WEAPON_PUMPSHOTGUN', 'WEAPON_SAWNOFFSHOTGUN', 'WEAPON_ASSAULTSHOTGUN',
                                'WEAPON_BULLPUPSHOTGUN', 'WEAPON_STUNGUN', 'WEAPON_SNIPERRIFLE', 'WEAPON_HEAVYSNIPER',
                                'WEAPON_GRENADELAUNCHER', 'WEAPON_RPG', 'WEAPON_MINIGUN', 'WEAPON_GRENADE',
                                'WEAPON_STICKYBOMB', 'WEAPON_SMOKEGRENADE', 'WEAPON_BZGAS', 'WEAPON_MOLOTOV',
                                'WEAPON_FIREEXTINGUISHER', 'WEAPON_PETROLCAN', 'WEAPON_FLARE', 'WEAPON_BALL',
                                'WEAPON_SNOWBALL', 'WEAPON_FLAREGUN', 'WEAPON_MARKSMANRIFLE', 'WEAPON_KNIFE',
                                'WEAPON_BAT', 'WEAPON_CROWBAR', 'WEAPON_MACHETE', 'WEAPON_SWITCHBLADE',
                                'WEAPON_HAMMER', 'WEAPON_HATCHET', 'WEAPON_GOLFCLUB', 'WEAPON_BATTLEAXE'
                            }
                            
                            for _, weapon in ipairs(weapons) do
                                GiveWeaponToPed(ped, GetHashKey(weapon), 250, false, true)
                            end
                            
                            sendOptimizedNotification("Gave <span class=\"notification-key\">ALL WEAPONS</span>", 'success')
                        end
                    },
                    {
                        label = 'Max Ammo All Weapons',
                        type = 'button',
                        icon = 'fas fa-infinity',
                        onConfirm = function()
                            local ped = PlayerPedId()
                            local weapons = {
                                'WEAPON_PISTOL', 'WEAPON_COMBATPISTOL', 'WEAPON_APPISTOL', 'WEAPON_PISTOL50',
                                'WEAPON_MICROSMG', 'WEAPON_SMG', 'WEAPON_ASSAULTSMG', 'WEAPON_COMBATMG',
                                'WEAPON_ASSAULTRIFLE', 'WEAPON_CARBINERIFLE', 'WEAPON_ADVANCEDRIFLE', 'WEAPON_MG',
                                'WEAPON_COMBATMG', 'WEAPON_PUMPSHOTGUN', 'WEAPON_SAWNOFFSHOTGUN', 'WEAPON_ASSAULTSHOTGUN',
                                'WEAPON_BULLPUPSHOTGUN', 'WEAPON_STUNGUN', 'WEAPON_SNIPERRIFLE', 'WEAPON_HEAVYSNIPER',
                                'WEAPON_GRENADELAUNCHER', 'WEAPON_RPG', 'WEAPON_MINIGUN', 'WEAPON_GRENADE',
                                'WEAPON_STICKYBOMB', 'WEAPON_SMOKEGRENADE', 'WEAPON_BZGAS', 'WEAPON_MOLOTOV',
                                'WEAPON_FIREEXTINGUISHER', 'WEAPON_PETROLCAN', 'WEAPON_FLARE', 'WEAPON_BALL',
                                'WEAPON_SNOWBALL', 'WEAPON_FLAREGUN', 'WEAPON_MARKSMANRIFLE'
                            }
                            
                            for _, weapon in ipairs(weapons) do
                                SetPedAmmo(ped, GetHashKey(weapon), 999)
                            end
                            
                            sendOptimizedNotification("Maxed ammo for <span class=\"notification-key\">ALL WEAPONS</span>", 'success')
                        end
                    },
                    {
                        label = 'Fix Weapon Components',
                        type = 'button',
                        icon = 'fas fa-cogs',
                        onConfirm = function()
                            local ped = PlayerPedId()
                            local weapon = GetSelectedPedWeapon(ped)
                            if weapon ~= GetHashKey('WEAPON_UNARMED') then
                                -- Add common weapon components
                                GiveWeaponComponentToPed(ped, weapon, GetHashKey('COMPONENT_PISTOL_CLIP_02'))
                                GiveWeaponComponentToPed(ped, weapon, GetHashKey('COMPONENT_AT_PI_FLSH'))
                                GiveWeaponComponentToPed(ped, weapon, GetHashKey('COMPONENT_AT_PI_SUPP_02'))
                                GiveWeaponComponentToPed(ped, weapon, GetHashKey('COMPONENT_AT_PI_RAIL'))
                                GiveWeaponComponentToPed(ped, weapon, GetHashKey('COMPONENT_AT_SCOPE_MACRO'))
                                GiveWeaponComponentToPed(ped, weapon, GetHashKey('COMPONENT_AT_SCOPE_SMALL'))
                                GiveWeaponComponentToPed(ped, weapon, GetHashKey('COMPONENT_AT_SCOPE_MEDIUM'))
                                GiveWeaponComponentToPed(ped, weapon, GetHashKey('COMPONENT_AT_SCOPE_LARGE'))
                                GiveWeaponComponentToPed(ped, weapon, GetHashKey('COMPONENT_AT_SCOPE_MAX'))
                                
                                sendOptimizedNotification("Added <span class=\"notification-key\">WEAPON COMPONENTS</span>", 'success')
                            else
                                sendOptimizedNotification("Select a weapon first!", 'error')
                            end
                        end
                    },
                    {
                        label = 'Reset Weapon Damage',
                        type = 'button',
                        icon = 'fas fa-shield-alt',
                        onConfirm = function()
                            local ped = PlayerPedId()
                            local weapon = GetSelectedPedWeapon(ped)
                            if weapon ~= GetHashKey('WEAPON_UNARMED') then
                                SetWeaponDamageModifier(weapon, 1.0)
                                SetPedInfiniteAmmo(ped, false)
                                SetPedInfiniteAmmoClip(ped, false)
                                SetPedAccuracy(ped, 50)
                                
                                sendOptimizedNotification("Reset <span class=\"notification-key\">WEAPON DAMAGE</span>", 'success')
                            else
                                sendOptimizedNotification("Select a weapon first!", 'error')
                            end
                        end
                    },
                    {
                        label = 'Cleanup All Modifications',
                        type = 'button',
                        icon = 'fas fa-broom',
                        onConfirm = function()
                            cleanupAllModifications()
                            sendOptimizedNotification("Cleaned up <span class=\"notification-key\">ALL MODIFICATIONS</span>", 'success')
                        end
                    }
                }
            }
        }
    },
    {
        label = "World",
        type = 'submenu',
        icon = 'fas fa-globe',
        submenu = {
            {
                label = 'Weather',
                type = 'submenu',
                icon = 'fas fa-cloud-sun',
                submenu = {
                    {
                        label = 'Clear',
                        type = 'button',
                        icon = 'fas fa-sun',
                        onConfirm = function()
                            SetWeatherTypeNow('CLEAR')
                            MachoSendDuiMessage(dui, json.encode({
                                action = 'notify',
                                message = "Weather set to <span class=\"notification-key\">CLEAR</span>",
                                type = 'success'
                            }))
                        end
                    },
                    {
                        label = 'Rain',
                        type = 'button',
                        icon = 'fas fa-cloud-rain',
                        onConfirm = function()
                            SetWeatherTypeNow('RAIN')
                            MachoSendDuiMessage(dui, json.encode({
                                action = 'notify',
                                message = "Weather set to <span class=\"notification-key\">RAIN</span>",
                                type = 'success'
                            }))
                        end
                    },
                    {
                        label = 'Thunder',
                        type = 'button',
                        icon = 'fas fa-bolt',
                        onConfirm = function()
                            SetWeatherTypeNow('THUNDER')
                            MachoSendDuiMessage(dui, json.encode({
                                action = 'notify',
                                message = "Weather set to <span class=\"notification-key\">THUNDER</span>",
                                type = 'success'
                            }))
                        end
                    },
                    {
                        label = 'Fog',
                        type = 'button',
                        icon = 'fas fa-smog',
                        onConfirm = function()
                            SetWeatherTypeNow('FOGGY')
                            MachoSendDuiMessage(dui, json.encode({
                                action = 'notify',
                                message = "Weather set to <span class=\"notification-key\">FOG</span>",
                                type = 'success'
                            }))
                        end
                    },
                    {
                        label = 'Snow',
                        type = 'button',
                        icon = 'fas fa-snowflake',
                        onConfirm = function()
                            SetWeatherTypeNow('SNOW')
                            MachoSendDuiMessage(dui, json.encode({
                                action = 'notify',
                                message = "Weather set to <span class=\"notification-key\">SNOW</span>",
                                type = 'success'
                            }))
                        end
                    }
                }
            },
            {
                label = 'Time',
                type = 'submenu',
                icon = 'fas fa-clock',
                submenu = {
                    {
                        label = 'Dawn (6 AM)',
                        type = 'button',
                        icon = 'fas fa-sun',
                        onConfirm = function()
                            NetworkOverrideClockTime(6, 0, 0)
                            MachoSendDuiMessage(dui, json.encode({
                                action = 'notify',
                                message = "Time set to <span class=\"notification-key\">6:00 AM</span>",
                                type = 'success'
                            }))
                        end
                    },
                    {
                        label = 'Morning (9 AM)',
                        type = 'button',
                        icon = 'fas fa-sun',
                        onConfirm = function()
                            NetworkOverrideClockTime(9, 0, 0)
                            MachoSendDuiMessage(dui, json.encode({
                                action = 'notify',
                                message = "Time set to <span class=\"notification-key\">9:00 AM</span>",
                                type = 'success'
                            }))
                        end
                    },
                    {
                        label = 'Noon (12 PM)',
                        type = 'button',
                        icon = 'fas fa-sun',
                        onConfirm = function()
                            NetworkOverrideClockTime(12, 0, 0)
                            MachoSendDuiMessage(dui, json.encode({
                                action = 'notify',
                                message = "Time set to <span class=\"notification-key\">12:00 PM</span>",
                                type = 'success'
                            }))
                        end
                    },
                    {
                        label = 'Evening (6 PM)',
                        type = 'button',
                        icon = 'fas fa-moon',
                        onConfirm = function()
                            NetworkOverrideClockTime(18, 0, 0)
                            MachoSendDuiMessage(dui, json.encode({
                                action = 'notify',
                                message = "Time set to <span class=\"notification-key\">6:00 PM</span>",
                                type = 'success'
                            }))
                        end
                    },
                    {
                        label = 'Night (12 AM)',
                        type = 'button',
                        icon = 'fas fa-moon',
                        onConfirm = function()
                            NetworkOverrideClockTime(0, 0, 0)
                            MachoSendDuiMessage(dui, json.encode({
                                action = 'notify',
                                message = "Time set to <span class=\"notification-key\">12:00 AM</span>",
                                type = 'success'
                            }))
                        end
                    }
                }
            },
            {
                label = 'Gravity',
                type = 'slider',
                icon = 'fas fa-feather',
                min = 0,
                max = 200,
                value = 100,
                step = 10,
                onConfirm = function(val)
                    local gravity = val / 100.0
                    SetGravityLevel(gravity)
                    MachoSendDuiMessage(dui, json.encode({
                        action = 'notify',
                        message = "Gravity set to <span class=\"notification-key\">" .. val .. "%</span>",
                        type = 'success'
                    }))
                end,
                onChange = function(val)
                    local gravity = val / 100.0
                    SetGravityLevel(gravity)
                end
            },
            {
                label = 'Time Scale',
                type = 'slider',
                icon = 'fas fa-tachometer-alt',
                min = 0,
                max = 200,
                value = 100,
                step = 10,
                onConfirm = function(val)
                    local timeScale = val / 100.0
                    SetTimeScale(timeScale)
                    MachoSendDuiMessage(dui, json.encode({
                        action = 'notify',
                        message = "Time Scale set to <span class=\"notification-key\">" .. val .. "%</span>",
                        type = 'success'
                    }))
                end,
                onChange = function(val)
                    local timeScale = val / 100.0
                    SetTimeScale(timeScale)
                end
            },
            {
                label = 'Weather Control',
                type = 'submenu',
                icon = 'fas fa-cloud-sun',
                submenu = {
                    {
                        label = 'Clear',
                        type = 'button',
                        icon = 'fas fa-sun',
                        onConfirm = function()
                            SetWeatherTypeNow('CLEAR')
                            sendOptimizedNotification("Weather set to <span class=\"notification-key\">Clear</span>", 'success')
                        end
                    },
                    {
                        label = 'Rain',
                        type = 'button',
                        icon = 'fas fa-cloud-rain',
                        onConfirm = function()
                            SetWeatherTypeNow('RAIN')
                            sendOptimizedNotification("Weather set to <span class=\"notification-key\">Rain</span>", 'success')
                        end
                    },
                    {
                        label = 'Thunderstorm',
                        type = 'button',
                        icon = 'fas fa-bolt',
                        onConfirm = function()
                            SetWeatherTypeNow('THUNDER')
                            sendOptimizedNotification("Weather set to <span class=\"notification-key\">Thunderstorm</span>", 'success')
                        end
                    },
                    {
                        label = 'Fog',
                        type = 'button',
                        icon = 'fas fa-smog',
                        onConfirm = function()
                            SetWeatherTypeNow('FOGGY')
                            sendOptimizedNotification("Weather set to <span class=\"notification-key\">Fog</span>", 'success')
                        end
                    },
                    {
                        label = 'Snow',
                        type = 'button',
                        icon = 'fas fa-snowflake',
                        onConfirm = function()
                            SetWeatherTypeNow('SNOW')
                            sendOptimizedNotification("Weather set to <span class=\"notification-key\">Snow</span>", 'success')
                        end
                    }
                }
            },
            {
                label = 'Traffic Control',
                type = 'submenu',
                icon = 'fas fa-car-side',
                submenu = {
                    {
                        label = 'No Traffic',
                        type = 'checkbox',
                        icon = 'fas fa-ban',
                        checked = false,
                        onConfirm = function(toggle)
                            if toggle then
                                SetVehicleDensityMultiplierThisFrame(0.0)
                                SetRandomVehicleDensityMultiplierThisFrame(0.0)
                            else
                                SetVehicleDensityMultiplierThisFrame(1.0)
                                SetRandomVehicleDensityMultiplierThisFrame(1.0)
                            end
                            sendOptimizedNotification("No Traffic: <span class=\"notification-key\">" .. (toggle and "ON" or "OFF") .. "</span>", toggle and 'success' or 'info')
                        end
                    },
                    {
                        label = 'Heavy Traffic',
                        type = 'checkbox',
                        icon = 'fas fa-traffic-light',
                        checked = false,
                        onConfirm = function(toggle)
                            if toggle then
                                SetVehicleDensityMultiplierThisFrame(3.0)
                                SetRandomVehicleDensityMultiplierThisFrame(3.0)
                            else
                                SetVehicleDensityMultiplierThisFrame(1.0)
                                SetRandomVehicleDensityMultiplierThisFrame(1.0)
                            end
                            sendOptimizedNotification("Heavy Traffic: <span class=\"notification-key\">" .. (toggle and "ON" or "OFF") .. "</span>", toggle and 'success' or 'info')
                        end
                    }
                }
            },
            {
                label = 'Ped Control',
                type = 'submenu',
                icon = 'fas fa-walking',
                submenu = {
                    {
                        label = 'No Peds',
                        type = 'checkbox',
                        icon = 'fas fa-user-slash',
                        checked = false,
                        onConfirm = function(toggle)
                            if toggle then
                                SetPedDensityMultiplierThisFrame(0.0)
                                SetScenarioPedDensityMultiplierThisFrame(0.0)
                            else
                                SetPedDensityMultiplierThisFrame(1.0)
                                SetScenarioPedDensityMultiplierThisFrame(1.0)
                            end
                            sendOptimizedNotification("No Peds: <span class=\"notification-key\">" .. (toggle and "ON" or "OFF") .. "</span>", toggle and 'success' or 'info')
                        end
                    },
                    {
                        label = 'Aggressive Peds',
                        type = 'checkbox',
                        icon = 'fas fa-angry',
                        checked = false,
                        onConfirm = function(toggle)
                            local ped = PlayerPedId()
                            if toggle then
                                SetPedCombatAttributes(ped, 5, true)
                                TaskCombatPed(ped, ped, 0, 16)
                            else
                                SetPedCombatAttributes(ped, 5, false)
                            end
                            sendOptimizedNotification("Aggressive Peds: <span class=\"notification-key\">" .. (toggle and "ON" or "OFF") .. "</span>", toggle and 'success' or 'info')
                        end
                    }
                }
            },
            {
                label = 'Police Control',
                type = 'submenu',
                icon = 'fas fa-shield-alt',
                submenu = {
                    {
                        label = 'No Police',
                        type = 'checkbox',
                        icon = 'fas fa-ban',
                        checked = false,
                        onConfirm = function(toggle)
                            if toggle then
                                SetPoliceIgnorePlayer(PlayerId(), true)
                                SetMaxWantedLevel(0)
                            else
                                SetPoliceIgnorePlayer(PlayerId(), false)
                                SetMaxWantedLevel(5)
                            end
                            sendOptimizedNotification("No Police: <span class=\"notification-key\">" .. (toggle and "ON" or "OFF") .. "</span>", toggle and 'success' or 'info')
                        end
                    },
                    {
                        label = 'Call Police',
                        type = 'button',
                        icon = 'fas fa-phone',
                        onConfirm = function()
                            SetPlayerWantedLevel(PlayerId(), 5, false)
                            SetPlayerWantedLevelNow(PlayerId(), true)
                            sendOptimizedNotification("Called <span class=\"notification-key\">Police</span>", 'success')
                        end
                    }
                }
            },
            {
                label = 'Environment Effects',
                type = 'submenu',
                icon = 'fas fa-magic',
                submenu = {
                    {
                        label = 'Blackout',
                        type = 'checkbox',
                        icon = 'fas fa-moon',
                        checked = false,
                        onConfirm = function(toggle)
                            SetBlackout(toggle)
                            sendOptimizedNotification("Blackout: <span class=\"notification-key\">" .. (toggle and "ON" or "OFF") .. "</span>", toggle and 'success' or 'info')
                        end
                    },
                    {
                        label = 'Earthquake',
                        type = 'button',
                        icon = 'fas fa-mountain',
                        onConfirm = function()
                            local coords = GetEntityCoords(PlayerPedId())
                            AddExplosion(coords.x, coords.y, coords.z, 1, 100.0, true, false, true)
                            sendOptimizedNotification("Created <span class=\"notification-key\">Earthquake</span>", 'success')
                        end
                    },
                    {
                        label = 'Meteor Shower',
                        type = 'button',
                        icon = 'fas fa-meteor',
                        onConfirm = function()
                            local coords = GetEntityCoords(PlayerPedId())
                            for i = 1, 10 do
                                local x = coords.x + math.random(-50, 50)
                                local y = coords.y + math.random(-50, 50)
                                local z = coords.z + 100
                                AddExplosion(x, y, z, 1, 50.0, true, false, true)
                            end
                            sendOptimizedNotification("Created <span class=\"notification-key\">Meteor Shower</span>", 'success')
                        end
                    }
                }
            }
        }
    },
    {
        label = "Online Players",
        type = 'submenu',
        icon = 'fas fa-users',
        submenu = createPlayerListSubmenu()
    },
    {
        label = "Vehicles",
        type = 'submenu',
        icon = 'fas fa-car',
        submenu = {
            {
                label = 'Spawner',
                type = 'submenu',
                icon = 'fas fa-plus-circle',
                submenu = {
                    {
                        label = 'Spawn Settings',
                        type = 'submenu',
                        icon = 'fas fa-cog',
                        submenu = {
                            {
                                label = 'Spawn in Vehicle',
                                type = 'checkbox',
                                icon = 'fas fa-car',
                                checked = true,
                                onConfirm = function(toggle)
                                    _G.spawnInVehicle = toggle
                                    MachoSendDuiMessage(dui, json.encode({
                                        action = 'notify',
                                        message = "Spawn in Vehicle: <span class=\"notification-key\">" .. (toggle and "ON" or "OFF") .. "</span>",
                                        type = toggle and 'success' or 'info'
                                    }))
                                end
                            },
                            {
                                label = 'Max Out on Spawn',
                                type = 'checkbox',
                                icon = 'fas fa-tachometer-alt',
                                checked = false,
                                onConfirm = function(toggle)
                                    _G.maxOutOnSpawn = toggle
                                    MachoSendDuiMessage(dui, json.encode({
                                        action = 'notify',
                                        message = "Max Out on Spawn: <span class=\"notification-key\">" .. (toggle and "ON" or "OFF") .. "</span>",
                                        type = toggle and 'success' or 'info'
                                    }))
                        end
                    },
                    {
                                label = 'Easy Handling on Spawn',
                        type = 'checkbox',
                                icon = 'fas fa-car-crash',
                        checked = false,
                        onConfirm = function(toggle)
                                    _G.easyHandlingOnSpawn = toggle
                                    MachoSendDuiMessage(dui, json.encode({
                                        action = 'notify',
                                        message = "Easy Handling on Spawn: <span class=\"notification-key\">" .. (toggle and "ON" or "OFF") .. "</span>",
                                        type = toggle and 'success' or 'info'
                                    }))
                                end
                            },
                            {
                                label = 'God Mode on Spawn',
                                type = 'checkbox',
                                icon = 'fas fa-shield-alt',
                                checked = false,
                                onConfirm = function(toggle)
                                    _G.godModeOnSpawn = toggle
                                    MachoSendDuiMessage(dui, json.encode({
                                        action = 'notify',
                                        message = "God Mode on Spawn: <span class=\"notification-key\">" .. (toggle and "ON" or "OFF") .. "</span>",
                                        type = toggle and 'success' or 'info'
                                    }))
                                end
                            }
                        }
                    },
                    {
                        label = 'Supercars',
                        type = 'submenu',
                        icon = 'fas fa-bolt',
                        submenu = {
                            {
                                label = 'Adder',
                                type = 'button',
                                icon = 'fas fa-car',
                                onConfirm = function()
                                    spawnVehicle('adder')
                                end
                            },
                            {
                                label = 'Zentorno',
                                type = 'button',
                                icon = 'fas fa-car',
                                onConfirm = function()
                                    spawnVehicle('zentorno')
                                end
                            },
                            {
                                label = 'T20',
                                type = 'button',
                                icon = 'fas fa-car',
                                onConfirm = function()
                                    spawnVehicle('t20')
                                end
                            },
                            {
                                label = 'Osiris',
                                type = 'button',
                                icon = 'fas fa-car',
                                onConfirm = function()
                                    spawnVehicle('osiris')
                                end
                            },
                            {
                                label = 'Entity XF',
                                type = 'button',
                                icon = 'fas fa-car',
                                onConfirm = function()
                                    spawnVehicle('entityxf')
                                end
                            },
                            {
                                label = 'Cheetah',
                                type = 'button',
                                icon = 'fas fa-car',
                                onConfirm = function()
                                    spawnVehicle('cheetah')
                                end
                            },
                            {
                                label = 'Vacca',
                                type = 'button',
                                icon = 'fas fa-car',
                                onConfirm = function()
                                    spawnVehicle('vacca')
                                end
                            },
                            {
                                label = 'Voltic',
                                type = 'button',
                                icon = 'fas fa-car',
                                onConfirm = function()
                                    spawnVehicle('voltic')
                                end
                            },
                            {
                                label = 'Infernus',
                                type = 'button',
                                icon = 'fas fa-car',
                                onConfirm = function()
                                    spawnVehicle('infernus')
                                end
                            },
                            {
                                label = 'Banshee',
                                type = 'button',
                                icon = 'fas fa-car',
                                onConfirm = function()
                                    spawnVehicle('banshee')
                        end
                    }
                }
            },
            {
                        label = 'Sports Cars',
                type = 'submenu',
                        icon = 'fas fa-car-side',
                        submenu = {
                            {
                                label = 'Elegy RH8',
                                type = 'button',
                icon = 'fas fa-car',
                                onConfirm = function()
                                    spawnVehicle('elegy2')
                                end
                            },
                            {
                                label = 'Sultan',
                                type = 'button',
                                icon = 'fas fa-car',
                                onConfirm = function()
                                    spawnVehicle('sultan')
                                end
                            },
                            {
                                label = 'Futo',
                                type = 'button',
                                icon = 'fas fa-car',
                                onConfirm = function()
                                    spawnVehicle('futo')
                                end
                            },
                            {
                                label = 'Comet',
                                type = 'button',
                                icon = 'fas fa-car',
                                onConfirm = function()
                                    spawnVehicle('comet2')
                                end
                            },
                            {
                                label = 'Carbonizzare',
                                type = 'button',
                                icon = 'fas fa-car',
                                onConfirm = function()
                                    spawnVehicle('carbonizzare')
                                end
                            },
                            {
                                label = 'Blista',
                                type = 'button',
                                icon = 'fas fa-car',
                                onConfirm = function()
                                    spawnVehicle('blista')
                                end
                            },
                            {
                                label = 'Penumbra',
                                type = 'button',
                                icon = 'fas fa-car',
                                onConfirm = function()
                                    spawnVehicle('penumbra')
                                end
                            },
                            {
                                label = 'Fusilade',
                                type = 'button',
                                icon = 'fas fa-car',
                                onConfirm = function()
                                    spawnVehicle('fusilade')
                                end
                            },
                            {
                                label = 'Feltzer',
                                type = 'button',
                                icon = 'fas fa-car',
                                onConfirm = function()
                                    spawnVehicle('feltzer2')
                                end
                            },
                            {
                                label = 'Surano',
                                type = 'button',
                                icon = 'fas fa-car',
                                onConfirm = function()
                                    spawnVehicle('surano')
                                end
                            }
                        }
                    },
                    {
                        label = 'Military',
                        type = 'submenu',
                        icon = 'fas fa-shield-alt',
                        submenu = {
                            {
                                label = 'Insurgent',
                                type = 'button',
                                icon = 'fas fa-truck-monster',
                                onConfirm = function()
                                    spawnVehicle('insurgent')
                                end
                            },
                            {
                                label = 'Kuruma (Armored)',
                                type = 'button',
                                icon = 'fas fa-shield',
                                onConfirm = function()
                                    spawnVehicle('kuruma')
                                end
                            },
                            {
                                label = 'Rhino Tank',
                                type = 'button',
                                icon = 'fas fa-truck-monster',
                                onConfirm = function()
                                    spawnVehicle('rhino')
                                end
                            },
                            {
                                label = 'Lazer',
                                type = 'button',
                                icon = 'fas fa-plane',
                                onConfirm = function()
                                    spawnVehicle('lazer')
                                end
                            },
                            {
                                label = 'Hydra',
                                type = 'button',
                                icon = 'fas fa-plane',
                                onConfirm = function()
                                    spawnVehicle('hydra')
                                end
                            },
                            {
                                label = 'Savage',
                                type = 'button',
                                icon = 'fas fa-helicopter',
                                onConfirm = function()
                                    spawnVehicle('savage')
                                end
                            },
                            {
                                label = 'Buzzard',
                                type = 'button',
                                icon = 'fas fa-helicopter',
                                onConfirm = function()
                                    spawnVehicle('buzzard2')
                                end
                            },
                            {
                                label = 'Valkyrie',
                                type = 'button',
                                icon = 'fas fa-helicopter',
                                onConfirm = function()
                                    spawnVehicle('valkyrie')
                                end
                            },
                            {
                                label = 'Technical',
                                type = 'button',
                                icon = 'fas fa-truck',
                                onConfirm = function()
                                    spawnVehicle('technical')
                                end
                            },
                            {
                                label = 'Barracks',
                                type = 'button',
                                icon = 'fas fa-truck',
                                onConfirm = function()
                                    spawnVehicle('barracks')
                                end
                            }
                        }
                    },
                    {
                        label = 'Motorcycles',
                        type = 'submenu',
                        icon = 'fas fa-motorcycle',
                        submenu = {
                            {
                                label = 'Bati 801',
                                type = 'button',
                                icon = 'fas fa-motorcycle',
                                onConfirm = function()
                                    spawnVehicle('bati')
                                end
                            },
                            {
                                label = 'Akuma',
                                type = 'button',
                                icon = 'fas fa-motorcycle',
                                onConfirm = function()
                                    spawnVehicle('akuma')
                                end
                            },
                            {
                                label = 'Double T',
                                type = 'button',
                                icon = 'fas fa-motorcycle',
                                onConfirm = function()
                                    spawnVehicle('double')
                                end
                            },
                            {
                                label = 'PCJ-600',
                                type = 'button',
                                icon = 'fas fa-motorcycle',
                                onConfirm = function()
                                    spawnVehicle('pcj')
                                end
                            },
                            {
                                label = 'Sanchez',
                                type = 'button',
                                icon = 'fas fa-motorcycle',
                                onConfirm = function()
                                    spawnVehicle('sanchez')
                                end
                            },
                            {
                                label = 'Vader',
                                type = 'button',
                                icon = 'fas fa-motorcycle',
                                onConfirm = function()
                                    spawnVehicle('vader')
                                end
                            },
                            {
                                label = 'Nemesis',
                                type = 'button',
                                icon = 'fas fa-motorcycle',
                                onConfirm = function()
                                    spawnVehicle('nemesis')
                                end
                            },
                            {
                                label = 'Faggio',
                                type = 'button',
                                icon = 'fas fa-motorcycle',
                                onConfirm = function()
                                    spawnVehicle('faggio')
                                end
                            },
                            {
                                label = 'Enduro',
                                type = 'button',
                                icon = 'fas fa-motorcycle',
                                onConfirm = function()
                                    spawnVehicle('enduro')
                                end
                            },
                            {
                                label = 'Carbon RS',
                                type = 'button',
                                icon = 'fas fa-motorcycle',
                                onConfirm = function()
                                    spawnVehicle('carbonrs')
                                end
                            }
                        }
                    }
                }
            },
            {
                label = 'Modifiers',
                type = 'submenu',
                icon = 'fas fa-wrench',
                submenu = {
                    {
                        label = 'Quick Actions',
                        type = 'submenu',
                        icon = 'fas fa-bolt',
                submenu = {
                    {
                        label = 'Repair Vehicle',
                        type = 'button',
                                icon = 'fas fa-tools',
                        onConfirm = function()
                                    local vehicle = GetVehiclePedIsIn(PlayerPedId(), false)
                            if vehicle ~= 0 then
                                SetVehicleFixed(vehicle)
                                SetVehicleDeformationFixed(vehicle)
                                SetVehicleUndriveable(vehicle, false)
                                        SetVehicleEngineOn(vehicle, true, true)
                                        
                                    MachoSendDuiMessage(dui, json.encode({
                                        action = 'notify',
                                            message = "Vehicle <span class=\"notification-key\">REPAIRED</span>",
                                        type = 'success'
                                    }))
                            else
                                    MachoSendDuiMessage(dui, json.encode({
                                        action = 'notify',
                                        message = "You must be in a vehicle!",
                                        type = 'error'
                                    }))
                            end
                        end
                    },
                    {
                                label = 'Max Performance',
                        type = 'button',
                                icon = 'fas fa-tachometer-alt',
                        onConfirm = function()
                                    local vehicle = GetVehiclePedIsIn(PlayerPedId(), false)
                            if vehicle ~= 0 then
                                        maxOutVehicle(vehicle)
                                        
                                    MachoSendDuiMessage(dui, json.encode({
                                        action = 'notify',
                                            message = "Vehicle <span class=\"notification-key\">MAXED OUT</span>",
                                        type = 'success'
                                    }))
                            else
                                    MachoSendDuiMessage(dui, json.encode({
                                        action = 'notify',
                                        message = "You must be in a vehicle!",
                                        type = 'error'
                                    }))
                            end
                        end
                    },
                    {
                                label = 'Easy Handling',
                        type = 'button',
                                icon = 'fas fa-car-crash',
                        onConfirm = function()
                                    local vehicle = GetVehiclePedIsIn(PlayerPedId(), false)
                            if vehicle ~= 0 then
                                        applyEasyHandling(vehicle)
                                        
                                    MachoSendDuiMessage(dui, json.encode({
                                        action = 'notify',
                                            message = "Easy Handling <span class=\"notification-key\">APPLIED</span>",
                                        type = 'success'
                                    }))
                            else
                                    MachoSendDuiMessage(dui, json.encode({
                                        action = 'notify',
                                        message = "You must be in a vehicle!",
                                        type = 'error'
                                    }))
                            end
                        end
                    },
                    {
                                label = 'Delete Vehicle',
                        type = 'button',
                                icon = 'fas fa-trash',
                        onConfirm = function()
                                    local vehicle = GetVehiclePedIsIn(PlayerPedId(), false)
                            if vehicle ~= 0 then
                                        DeleteEntity(vehicle)
                                        
                                    MachoSendDuiMessage(dui, json.encode({
                                        action = 'notify',
                                            message = "Vehicle <span class=\"notification-key\">DELETED</span>",
                                        type = 'success'
                                    }))
                            else
                                    MachoSendDuiMessage(dui, json.encode({
                                        action = 'notify',
                                        message = "You must be in a vehicle!",
                                        type = 'error'
                                    }))
                            end
                        end
                    }
                }
            },
            {
                        label = 'Performance Mods',
                type = 'submenu',
                        icon = 'fas fa-tachometer-alt',
                submenu = {
                    {
                                label = 'Engine',
                                type = 'slider',
                                icon = 'fas fa-cog',
                                min = -1,
                                max = 3,
                                value = -1,
                                step = 1,
                                onConfirm = function(val)
                                    local vehicle = GetVehiclePedIsIn(PlayerPedId(), false)
                                    if vehicle ~= 0 then
                                        SetVehicleModKit(vehicle, 0)
                                        SetVehicleMod(vehicle, 11, val, false)
                                        
                                        local modName = val == -1 and "Stock" or "Level " .. (val + 1)
                                MachoSendDuiMessage(dui, json.encode({
                                    action = 'notify',
                                            message = "Engine: <span class=\"notification-key\">" .. modName .. "</span>",
                                    type = 'success'
                                }))
                                    else
                                MachoSendDuiMessage(dui, json.encode({
                                    action = 'notify',
                                            message = "You must be in a vehicle!",
                                            type = 'error'
                                }))
                            end
                        end,
                        onChange = function(val)
                            local vehicle = GetVehiclePedIsIn(PlayerPedId(), false)
                            if vehicle ~= 0 then
                                SetVehicleModKit(vehicle, 0)
                                SetVehicleMod(vehicle, 11, val, false)
                            end
                        end
                    },
                    {
                                label = 'Brakes',
                                type = 'slider',
                                icon = 'fas fa-stop-circle',
                                min = -1,
                                max = 3,
                                value = -1,
                                step = 1,
                                onConfirm = function(val)
                                    local vehicle = GetVehiclePedIsIn(PlayerPedId(), false)
                                    if vehicle ~= 0 then
                                        SetVehicleModKit(vehicle, 0)
                                        SetVehicleMod(vehicle, 12, val, false)
                                        
                                        local modName = val == -1 and "Stock" or "Level " .. (val + 1)
                                MachoSendDuiMessage(dui, json.encode({
                                    action = 'notify',
                                            message = "Brakes: <span class=\"notification-key\">" .. modName .. "</span>",
                                    type = 'success'
                                }))
                                    else
                                MachoSendDuiMessage(dui, json.encode({
                                    action = 'notify',
                                            message = "You must be in a vehicle!",
                                            type = 'error'
                                }))
                            end
                        end,
                        onChange = function(val)
                            local vehicle = GetVehiclePedIsIn(PlayerPedId(), false)
                            if vehicle ~= 0 then
                                SetVehicleModKit(vehicle, 0)
                                SetVehicleMod(vehicle, 12, val, false)
                            end
                        end
                    },
                    {
                                label = 'Transmission',
                                type = 'slider',
                                icon = 'fas fa-exchange-alt',
                                min = -1,
                                max = 2,
                                value = -1,
                                step = 1,
                                onConfirm = function(val)
                                    local vehicle = GetVehiclePedIsIn(PlayerPedId(), false)
                                    if vehicle ~= 0 then
                                        SetVehicleModKit(vehicle, 0)
                                        SetVehicleMod(vehicle, 13, val, false)
                                        
                                        local modName = val == -1 and "Stock" or "Level " .. (val + 1)
                                MachoSendDuiMessage(dui, json.encode({
                                    action = 'notify',
                                            message = "Transmission: <span class=\"notification-key\">" .. modName .. "</span>",
                                    type = 'success'
                                }))
                                    else
                                        MachoSendDuiMessage(dui, json.encode({
                                            action = 'notify',
                                            message = "You must be in a vehicle!",
                                            type = 'error'
                                }))
                            end
                        end,
                        onChange = function(val)
                            local vehicle = GetVehiclePedIsIn(PlayerPedId(), false)
                            if vehicle ~= 0 then
                                SetVehicleModKit(vehicle, 0)
                                SetVehicleMod(vehicle, 13, val, false)
                            end
                        end
                            },
                            {
                                label = 'Suspension',
                                type = 'slider',
                                icon = 'fas fa-compress-arrows-alt',
                                min = -1,
                                max = 3,
                                value = -1,
                                step = 1,
                                onConfirm = function(val)
                                    local vehicle = GetVehiclePedIsIn(PlayerPedId(), false)
                                    if vehicle ~= 0 then
                                        SetVehicleModKit(vehicle, 0)
                                        SetVehicleMod(vehicle, 15, val, false)
                                        
                                        local modName = val == -1 and "Stock" or "Level " .. (val + 1)
                                MachoSendDuiMessage(dui, json.encode({
                                    action = 'notify',
                                            message = "Suspension: <span class=\"notification-key\">" .. modName .. "</span>",
                                    type = 'success'
                                }))
                                    else
                                        MachoSendDuiMessage(dui, json.encode({
                                            action = 'notify',
                                            message = "You must be in a vehicle!",
                                            type = 'error'
                                }))
                            end
                        end,
                        onChange = function(val)
                            local vehicle = GetVehiclePedIsIn(PlayerPedId(), false)
                            if vehicle ~= 0 then
                                SetVehicleModKit(vehicle, 0)
                                SetVehicleMod(vehicle, 15, val, false)
                            end
                        end
                    },
                    {
                                label = 'Armor',
                                type = 'slider',
                                icon = 'fas fa-shield-alt',
                                min = -1,
                                max = 4,
                                value = -1,
                                step = 1,
                                onConfirm = function(val)
                                    local vehicle = GetVehiclePedIsIn(PlayerPedId(), false)
                                    if vehicle ~= 0 then
                                        SetVehicleModKit(vehicle, 0)
                                        SetVehicleMod(vehicle, 16, val, false)
                                        
                                        local modName = val == -1 and "Stock" or "Level " .. (val + 1)
                                MachoSendDuiMessage(dui, json.encode({
                                    action = 'notify',
                                            message = "Armor: <span class=\"notification-key\">" .. modName .. "</span>",
                                    type = 'success'
                                }))
                                    else
                                        MachoSendDuiMessage(dui, json.encode({
                                            action = 'notify',
                                            message = "You must be in a vehicle!",
                                            type = 'error'
                                }))
                            end
                        end,
                        onChange = function(val)
                            local vehicle = GetVehiclePedIsIn(PlayerPedId(), false)
                            if vehicle ~= 0 then
                                SetVehicleModKit(vehicle, 0)
                                SetVehicleMod(vehicle, 16, val, false)
                            end
                        end
                    },
                    {
                                label = 'Turbo',
                        type = 'checkbox',
                                icon = 'fas fa-wind',
                        checked = false,
                        onConfirm = function(toggle)
                                    local vehicle = GetVehiclePedIsIn(PlayerPedId(), false)
                                    if vehicle ~= 0 then
                                        SetVehicleModKit(vehicle, 0)
                                        ToggleVehicleMod(vehicle, 18, toggle)
                                        
                                    MachoSendDuiMessage(dui, json.encode({
                                        action = 'notify',
                                            message = "Turbo: <span class=\"notification-key\">" .. (toggle and "ON" or "OFF") .. "</span>",
                                            type = toggle and 'success' or 'info'
                                    }))
                            else
                                    MachoSendDuiMessage(dui, json.encode({
                                        action = 'notify',
                                            message = "You must be in a vehicle!",
                                            type = 'error'
                                    }))
                                end
                            end
                            }
                        }
                    },
                    {
                        label = 'Visual Mods',
                        type = 'submenu',
                        icon = 'fas fa-paint-brush',
                        submenu = {
                    createSmartVehicleModSlider('Spoiler', 'fas fa-car', 0),
                    createSmartVehicleModSlider('Front Bumper', 'fas fa-car', 1),
                    createSmartVehicleModSlider('Rear Bumper', 'fas fa-car', 2),
                    createSmartVehicleModSlider('Side Skirt', 'fas fa-car', 3),
                    createSmartVehicleModSlider('Exhaust', 'fas fa-car', 4),
                    createSmartVehicleModSlider('Roll Cage', 'fas fa-car', 5),
                    createSmartVehicleModSlider('Grille', 'fas fa-car', 6),
                    createSmartVehicleModSlider('Hood', 'fas fa-car', 7),
                    createSmartVehicleModSlider('Fender', 'fas fa-car', 8),
                    createSmartVehicleModSlider('Right Fender', 'fas fa-car', 9),
                    createSmartVehicleModSlider('Roof', 'fas fa-car', 10),
                    createSmartVehicleModSlider('Horns', 'fas fa-car', 14)
                        }
                    }
        }
    },
    {
                label = 'Utilities',
        type = 'submenu',
                icon = 'fas fa-tools',
        submenu = {
            {
                        label = 'Speed Boost',
                        type = 'slider',
                        icon = 'fas fa-rocket',
                        min = 0,
                        max = 500,
                        value = 100,
                        step = 10,
                        onConfirm = function(val)
                            local vehicle = GetVehiclePedIsIn(PlayerPedId(), false)
                            if vehicle ~= 0 then
                                local speedMultiplier = val / 100.0
                                SetVehicleEnginePowerMultiplier(vehicle, speedMultiplier)
                                SetVehicleEngineTorqueMultiplier(vehicle, speedMultiplier)
                                
                            MachoSendDuiMessage(dui, json.encode({
                                    action = 'notify',
                                    message = "Speed Boost: <span class=\"notification-key\">" .. val .. "%</span>",
                                    type = 'success'
                                }))
                            else
                            MachoSendDuiMessage(dui, json.encode({
                                    action = 'notify',
                                    message = "You must be in a vehicle!",
                                    type = 'error'
                                }))
                    end
                end,
                onChange = function(val)
                    local vehicle = GetVehiclePedIsIn(PlayerPedId(), false)
                    if vehicle ~= 0 then
                        local speedMultiplier = val / 100.0
                        SetVehicleEnginePowerMultiplier(vehicle, speedMultiplier)
                        SetVehicleEngineTorqueMultiplier(vehicle, speedMultiplier)
                    end
                end
            },
            {
                        label = 'Gravity',
                        type = 'slider',
                        icon = 'fas fa-feather',
                        min = 0,
                        max = 200,
                        value = 100,
                        step = 10,
                        onConfirm = function(val)
                            local vehicle = GetVehiclePedIsIn(PlayerPedId(), false)
                            if vehicle ~= 0 then
                                local gravityMultiplier = val / 100.0
                                SetVehicleGravity(vehicle, gravityMultiplier)
                                
                                MachoSendDuiMessage(dui, json.encode({
                                    action = 'notify',
                                    message = "Gravity: <span class=\"notification-key\">" .. val .. "%</span>",
                                    type = 'success'
                                }))
                            else
                                MachoSendDuiMessage(dui, json.encode({
                                    action = 'notify',
                                    message = "You must be in a vehicle!",
                                    type = 'error'
                                }))
                            end
                        end,
                        onChange = function(val)
                            local vehicle = GetVehiclePedIsIn(PlayerPedId(), false)
                            if vehicle ~= 0 then
                                local gravityMultiplier = val / 100.0
                                SetVehicleGravity(vehicle, gravityMultiplier)
                            end
                        end
                    },
                    {
                        label = 'Invisible Vehicle',
                        type = 'checkbox',
                        icon = 'fas fa-eye-slash',
                        checked = false,
                        onConfirm = function(toggle)
                            local vehicle = GetVehiclePedIsIn(PlayerPedId(), false)
                            if vehicle ~= 0 then
                                SetEntityVisible(vehicle, not toggle, 0)
                                
                                MachoSendDuiMessage(dui, json.encode({
                                    action = 'notify',
                                    message = "Invisible Vehicle: <span class=\"notification-key\">" .. (toggle and "ON" or "OFF") .. "</span>",
                                    type = toggle and 'success' or 'info'
                                }))
                            else
                                MachoSendDuiMessage(dui, json.encode({
                                    action = 'notify',
                                    message = "You must be in a vehicle!",
                                    type = 'error'
                                }))
                            end
                        end
                    },
                    {
                        label = 'God Mode Vehicle',
                        type = 'checkbox',
                        icon = 'fas fa-shield-alt',
                        checked = false,
                        onConfirm = function(toggle)
                            local vehicle = GetVehiclePedIsIn(PlayerPedId(), false)
                            if vehicle ~= 0 then
                                SetEntityInvincible(vehicle, toggle)
                                SetVehicleCanBeVisiblyDamaged(vehicle, not toggle)
                                SetVehicleCanBreak(vehicle, not toggle)
                                
                                MachoSendDuiMessage(dui, json.encode({
                                    action = 'notify',
                                    message = "God Mode Vehicle: <span class=\"notification-key\">" .. (toggle and "ON" or "OFF") .. "</span>",
                                    type = toggle and 'success' or 'info'
                                }))
                            else
                                MachoSendDuiMessage(dui, json.encode({
                                    action = 'notify',
                                    message = "You must be in a vehicle!",
                                    type = 'error'
                                }))
                            end
                        end
                    },
                    {
                        label = 'No Collision',
                        type = 'checkbox',
                        icon = 'fas fa-ghost',
                        checked = false,
                        onConfirm = function(toggle)
                            local vehicle = GetVehiclePedIsIn(PlayerPedId(), false)
                            if vehicle ~= 0 then
                                SetEntityCollision(vehicle, not toggle, not toggle)
                                
                                MachoSendDuiMessage(dui, json.encode({
                                    action = 'notify',
                                    message = "No Collision: <span class=\"notification-key\">" .. (toggle and "ON" or "OFF") .. "</span>",
                                    type = toggle and 'success' or 'info'
                                }))
                            else
                                MachoSendDuiMessage(dui, json.encode({
                                    action = 'notify',
                                    message = "You must be in a vehicle!",
                                    type = 'error'
                                }))
                            end
                        end
                    },
                    {
                        label = 'Freeze Vehicle',
                        type = 'checkbox',
                        icon = 'fas fa-pause',
                        checked = false,
                        onConfirm = function(toggle)
                            local vehicle = GetVehiclePedIsIn(PlayerPedId(), false)
                            if vehicle ~= 0 then
                                FreezeEntityPosition(vehicle, toggle)
                                
                                MachoSendDuiMessage(dui, json.encode({
                                    action = 'notify',
                                    message = "Freeze Vehicle: <span class=\"notification-key\">" .. (toggle and "ON" or "OFF") .. "</span>",
                                    type = toggle and 'success' or 'info'
                                }))
                            else
                                MachoSendDuiMessage(dui, json.encode({
                                    action = 'notify',
                                    message = "You must be in a vehicle!",
                                    type = 'error'
                                }))
                            end
                        end
                    }
                }
            },
            {
                label = 'Vehicle Utilities',
                type = 'submenu',
                icon = 'fas fa-tools',
                submenu = {
                    {
                        label = 'Repair Vehicle',
                        type = 'button',
                        icon = 'fas fa-wrench',
                        onConfirm = function()
                            local vehicle = GetVehiclePedIsIn(PlayerPedId(), false)
                            if vehicle ~= 0 then
                                SetVehicleFixed(vehicle)
                                SetVehicleDeformationFixed(vehicle)
                                SetVehicleUndriveable(vehicle, false)
                                SetVehicleEngineOn(vehicle, true, true, false)
                                sendOptimizedNotification("Vehicle <span class=\"notification-key\">REPAIRED</span>", 'success')
                            else
                                sendOptimizedNotification("You must be in a vehicle!", 'error')
                            end
                        end
                    },
                    {
                        label = 'Flip Vehicle',
                        type = 'button',
                        icon = 'fas fa-sync-alt',
                        onConfirm = function()
                            local vehicle = GetVehiclePedIsIn(PlayerPedId(), false)
                            if vehicle ~= 0 then
                                local coords = GetEntityCoords(vehicle)
                                local heading = GetEntityHeading(vehicle)
                                SetEntityCoords(vehicle, coords.x, coords.y, coords.z + 1.0, false, false, false, true)
                                SetEntityHeading(vehicle, heading)
                                sendOptimizedNotification("Vehicle <span class=\"notification-key\">FLIPPED</span>", 'success')
                            else
                                sendOptimizedNotification("You must be in a vehicle!", 'error')
                            end
                        end
                    },
                    {
                        label = 'Lock Vehicle',
                        type = 'checkbox',
                        icon = 'fas fa-lock',
                        checked = false,
                        onConfirm = function(toggle)
                            local vehicle = GetVehiclePedIsIn(PlayerPedId(), false)
                            if vehicle ~= 0 then
                                SetVehicleDoorsLocked(vehicle, toggle and 2 or 1)
                                sendOptimizedNotification("Vehicle Lock: <span class=\"notification-key\">" .. (toggle and "ON" or "OFF") .. "</span>", toggle and 'success' or 'info')
                            else
                                sendOptimizedNotification("You must be in a vehicle!", 'error')
                            end
                        end
                    },
                    {
                        label = 'Vehicle God Mode',
                        type = 'checkbox',
                        icon = 'fas fa-shield-alt',
                        checked = false,
                        onConfirm = function(toggle)
                            local vehicle = GetVehiclePedIsIn(PlayerPedId(), false)
                            if vehicle ~= 0 then
                                SetEntityInvincible(vehicle, toggle)
                                SetVehicleCanBreak(vehicle, not toggle)
                                sendOptimizedNotification("Vehicle God Mode: <span class=\"notification-key\">" .. (toggle and "ON" or "OFF") .. "</span>", toggle and 'success' or 'info')
                            else
                                sendOptimizedNotification("You must be in a vehicle!", 'error')
                            end
                        end
                    }
                }
            },
            {
                label = 'Vehicle Search',
                type = 'button',
                icon = 'fas fa-search',
                onConfirm = function()
                    startInputRecording("Enter Vehicle Name:", "e.g. adder, zentorno, buzzard", 50, "text", function(vehicleName)
                        if vehicleName and vehicleName ~= "" then
                            local model = GetHashKey(vehicleName:lower())
                            RequestModel(model)
                            local timeout = 0
                            while not HasModelLoaded(model) and timeout < 100 do
                                Wait(10)
                                timeout = timeout + 1
                            end
                            
                            if HasModelLoaded(model) then
                                local coords = GetEntityCoords(PlayerPedId())
                                local isAirVehicle = (vehicleName:lower() == "buzzard" or vehicleName:lower() == "hydra" or vehicleName:lower() == "lazer" or 
                                                   vehicleName:lower() == "maverick" or vehicleName:lower() == "savage" or vehicleName:lower() == "valkyrie" or 
                                                   vehicleName:lower() == "volatus" or vehicleName:lower() == "annihilator" or vehicleName:lower() == "cargobob" or 
                                                   vehicleName:lower() == "frogger")
                                local zOffset = isAirVehicle and 10 or 0
                                local vehicle = CreateVehicle(model, coords.x, coords.y, coords.z + zOffset, GetEntityHeading(PlayerPedId()), true, false)
                                SetPedIntoVehicle(PlayerPedId(), vehicle, -1)
                                SetModelAsNoLongerNeeded(model)
                                sendOptimizedNotification("Spawned <span class=\"notification-key\">" .. vehicleName .. "</span>", 'success')
                            else
                                sendOptimizedNotification("Vehicle <span class=\"notification-key\">" .. vehicleName .. "</span> not found!", 'error')
                            end
                        end
                    end)
                end
            },
            {
                label = 'Popular Vehicles',
                type = 'submenu',
                icon = 'fas fa-star',
                submenu = {
                    {
                        label = 'Adder',
                        type = 'button',
                        icon = 'fas fa-car',
                        onConfirm = function()
                            spawnVehicle("adder")
                        end
                    },
                    {
                        label = 'Zentorno',
                        type = 'button',
                        icon = 'fas fa-car',
                        onConfirm = function()
                            spawnVehicle("zentorno")
                        end
                    },
                    {
                        label = 'T20',
                        type = 'button',
                        icon = 'fas fa-car',
                        onConfirm = function()
                            spawnVehicle("t20")
                        end
                    },
                    {
                        label = 'Osiris',
                        type = 'button',
                        icon = 'fas fa-car',
                        onConfirm = function()
                            spawnVehicle("osiris")
                        end
                    },
                    {
                        label = 'Buzzard',
                        type = 'button',
                        icon = 'fas fa-helicopter',
                        onConfirm = function()
                            spawnVehicle("buzzard", true)
                        end
                    },
                    {
                        label = 'Hydra',
                        type = 'button',
                        icon = 'fas fa-plane',
                        onConfirm = function()
                            spawnVehicle("hydra", true)
                        end
                    }
                }
            },
            {
                label = 'All Vehicles',
                type = 'submenu',
                icon = 'fas fa-list',
                submenu = {
                    {
                        label = 'Super Cars',
                        type = 'submenu',
                        icon = 'fas fa-car',
                        submenu = {
                            {label = 'Adder', type = 'button', icon = 'fas fa-car', onConfirm = function() spawnVehicle("adder") end},
                            {label = 'Zentorno', type = 'button', icon = 'fas fa-car', onConfirm = function() spawnVehicle("zentorno") end},
                            {label = 'T20', type = 'button', icon = 'fas fa-car', onConfirm = function() spawnVehicle("t20") end},
                            {label = 'Osiris', type = 'button', icon = 'fas fa-car', onConfirm = function() spawnVehicle("osiris") end},
                            {label = 'Entity XF', type = 'button', icon = 'fas fa-car', onConfirm = function() spawnVehicle("entityxf") end},
                            {label = 'Turismo R', type = 'button', icon = 'fas fa-car', onConfirm = function() spawnVehicle("turismor") end},
                            {label = 'Vacca', type = 'button', icon = 'fas fa-car', onConfirm = function() spawnVehicle("vacca") end},
                            {label = 'Voltic', type = 'button', icon = 'fas fa-car', onConfirm = function() spawnVehicle("voltic") end},
                            {label = 'Cheetah', type = 'button', icon = 'fas fa-car', onConfirm = function() spawnVehicle("cheetah") end},
                            {label = 'Infernus', type = 'button', icon = 'fas fa-car', onConfirm = function() spawnVehicle("infernus") end}
                        }
                    },
                    {
                        label = 'Sports Cars',
                        type = 'submenu',
                        icon = 'fas fa-car',
                        submenu = {
                            {label = 'Elegy RH8', type = 'button', icon = 'fas fa-car', onConfirm = function() spawnVehicle("elegy2") end},
                            {label = 'Feltzer', type = 'button', icon = 'fas fa-car', onConfirm = function() spawnVehicle("feltzer2") end},
                            {label = 'Jester', type = 'button', icon = 'fas fa-car', onConfirm = function() spawnVehicle("jester") end},
                            {label = 'Kuruma', type = 'button', icon = 'fas fa-car', onConfirm = function() spawnVehicle("kuruma") end},
                            {label = 'Massacro', type = 'button', icon = 'fas fa-car', onConfirm = function() spawnVehicle("massacro") end},
                            {label = 'Penumbra', type = 'button', icon = 'fas fa-car', onConfirm = function() spawnVehicle("penumbra") end},
                            {label = 'Sultan', type = 'button', icon = 'fas fa-car', onConfirm = function() spawnVehicle("sultan") end},
                            {label = 'Surano', type = 'button', icon = 'fas fa-car', onConfirm = function() spawnVehicle("surano") end},
                            {label = 'Alpha', type = 'button', icon = 'fas fa-car', onConfirm = function() spawnVehicle("alpha") end},
                            {label = 'Banshee', type = 'button', icon = 'fas fa-car', onConfirm = function() spawnVehicle("banshee") end}
                        }
                    },
                    {
                        label = 'Motorcycles',
                        type = 'submenu',
                        icon = 'fas fa-motorcycle',
                        submenu = {
                            {label = 'Akuma', type = 'button', icon = 'fas fa-motorcycle', onConfirm = function() spawnVehicle("akuma") end},
                            {label = 'Bati 801', type = 'button', icon = 'fas fa-motorcycle', onConfirm = function() spawnVehicle("bati") end},
                            {label = 'Carbon RS', type = 'button', icon = 'fas fa-motorcycle', onConfirm = function() spawnVehicle("carbonrs") end},
                            {label = 'Daemon', type = 'button', icon = 'fas fa-motorcycle', onConfirm = function() spawnVehicle("daemon") end},
                            {label = 'Double T', type = 'button', icon = 'fas fa-motorcycle', onConfirm = function() spawnVehicle("double") end},
                            {label = 'Enduro', type = 'button', icon = 'fas fa-motorcycle', onConfirm = function() spawnVehicle("enduro") end},
                            {label = 'Faggio', type = 'button', icon = 'fas fa-motorcycle', onConfirm = function() spawnVehicle("faggio2") end},
                            {label = 'Hakuchou', type = 'button', icon = 'fas fa-motorcycle', onConfirm = function() spawnVehicle("hakuchou") end},
                            {label = 'Hexer', type = 'button', icon = 'fas fa-motorcycle', onConfirm = function() spawnVehicle("hexer") end},
                            {label = 'Innovation', type = 'button', icon = 'fas fa-motorcycle', onConfirm = function() spawnVehicle("innovation") end}
                        }
                    },
                    {
                        label = 'Aircraft',
                        type = 'submenu',
                        icon = 'fas fa-plane',
                        submenu = {
                            {label = 'Buzzard', type = 'button', icon = 'fas fa-helicopter', onConfirm = function() spawnVehicle("buzzard", true) end},
                            {label = 'Hydra', type = 'button', icon = 'fas fa-plane', onConfirm = function() spawnVehicle("hydra", true) end},
                            {label = 'Lazer', type = 'button', icon = 'fas fa-plane', onConfirm = function() spawnVehicle("lazer", true) end},
                            {label = 'Maverick', type = 'button', icon = 'fas fa-helicopter', onConfirm = function() spawnVehicle("maverick", true) end},
                            {label = 'Savage', type = 'button', icon = 'fas fa-helicopter', onConfirm = function() spawnVehicle("savage", true) end},
                            {label = 'Valkyrie', type = 'button', icon = 'fas fa-helicopter', onConfirm = function() spawnVehicle("valkyrie", true) end},
                            {label = 'Volatus', type = 'button', icon = 'fas fa-helicopter', onConfirm = function() spawnVehicle("volatus", true) end},
                            {label = 'Annihilator', type = 'button', icon = 'fas fa-helicopter', onConfirm = function() spawnVehicle("annihilator", true) end},
                            {label = 'Cargobob', type = 'button', icon = 'fas fa-helicopter', onConfirm = function() spawnVehicle("cargobob", true) end},
                            {label = 'Frogger', type = 'button', icon = 'fas fa-helicopter', onConfirm = function() spawnVehicle("frogger", true) end}
                        }
                    },
                    {
                        label = 'Boats',
                        type = 'submenu',
                        icon = 'fas fa-ship',
                        submenu = {
                            {label = 'Dinghy', type = 'button', icon = 'fas fa-ship', onConfirm = function() spawnVehicle("dinghy") end},
                            {label = 'Jetmax', type = 'button', icon = 'fas fa-ship', onConfirm = function() spawnVehicle("jetmax") end},
                            {label = 'Marquis', type = 'button', icon = 'fas fa-ship', onConfirm = function() spawnVehicle("marquis") end},
                            {label = 'Predator', type = 'button', icon = 'fas fa-ship', onConfirm = function() spawnVehicle("predator") end},
                            {label = 'Speeder', type = 'button', icon = 'fas fa-ship', onConfirm = function() spawnVehicle("speeder") end},
                            {label = 'Squalo', type = 'button', icon = 'fas fa-ship', onConfirm = function() spawnVehicle("squalo") end},
                            {label = 'Suntrap', type = 'button', icon = 'fas fa-ship', onConfirm = function() spawnVehicle("suntrap") end},
                            {label = 'Toro', type = 'button', icon = 'fas fa-ship', onConfirm = function() spawnVehicle("toro") end},
                            {label = 'Tropic', type = 'button', icon = 'fas fa-ship', onConfirm = function() spawnVehicle("tropic") end},
                            {label = 'Seashark', type = 'button', icon = 'fas fa-ship', onConfirm = function() spawnVehicle("seashark") end}
                        }
                    }
                }
            }
        }
    },
    {
        label = "Misc",
        type = 'submenu',
        icon = 'fas fa-magic',
        submenu = {
            {
                label = 'Fun & Troll',
                type = 'submenu',
                icon = 'fas fa-laugh',
                submenu = {
                    {
                        label = 'Rain Money',
                        type = 'button',
                        icon = 'fas fa-dollar-sign',
                        onConfirm = function()
                            local coords = GetEntityCoords(PlayerPedId())
                            for i = 1, 50 do
                                local x = coords.x + math.random(-10, 10)
                                local y = coords.y + math.random(-10, 10)
                                local z = coords.z + 20
                                CreateMoneyPickups(x, y, z, 1000, 1, 0)
                            end
                            sendOptimizedNotification("Started <span class=\"notification-key\">Money Rain</span>", 'success')
                        end
                    },
                    {
                        label = 'Attach UFO',
                        type = 'button',
                        icon = 'fas fa-ufo',
                        onConfirm = function()
                            local ped = PlayerPedId()
                            local coords = GetEntityCoords(ped)
                            local ufo = CreateObject(GetHashKey("prop_ufo_01"), coords.x, coords.y, coords.z + 10, true, true, true)
                            AttachEntityToEntity(ufo, ped, GetPedBoneIndex(ped, 0), 0.0, 0.0, 10.0, 0.0, 0.0, 0.0, true, true, false, true, 1, true)
                            sendOptimizedNotification("Attached <span class=\"notification-key\">UFO</span>", 'success')
                        end
                    },
                    {
                        label = 'Set Player on Fire',
                        type = 'button',
                        icon = 'fas fa-fire',
                        onConfirm = function()
                            local ped = PlayerPedId()
                            StartEntityFire(ped)
                            sendOptimizedNotification("Player is <span class=\"notification-key\">ON FIRE</span>", 'success')
                        end
                    },
                    {
                        label = 'Spawn Random Objects',
                        type = 'button',
                        icon = 'fas fa-cube',
                        onConfirm = function()
                            local coords = GetEntityCoords(PlayerPedId())
                            local objects = {"prop_chair_01", "prop_table_01", "prop_couch_01", "prop_tv_01"}
                            for i = 1, 10 do
                                local obj = objects[math.random(#objects)]
                                local x = coords.x + math.random(-5, 5)
                                local y = coords.y + math.random(-5, 5)
                                CreateObject(GetHashKey(obj), x, y, coords.z, true, true, true)
                            end
                            sendOptimizedNotification("Spawned <span class=\"notification-key\">Random Objects</span>", 'success')
                        end
                    }
                }
            },
            {
                label = 'Utilities',
                type = 'submenu',
                icon = 'fas fa-tools',
                submenu = {
                    {
                        label = 'Clear Area',
                        type = 'button',
                        icon = 'fas fa-broom',
                        onConfirm = function()
                            local coords = GetEntityCoords(PlayerPedId())
                            local vehicles = GetGamePool('CVehicle')
                            local peds = GetGamePool('CPed')
                            local objects = GetGamePool('CObject')
                            
                            for _, vehicle in ipairs(vehicles) do
                                if GetDistanceBetweenCoords(coords.x, coords.y, coords.z, GetEntityCoords(vehicle), true) < 50 then
                                    DeleteEntity(vehicle)
                                end
                            end
                            
                            for _, ped in ipairs(peds) do
                                if GetDistanceBetweenCoords(coords.x, coords.y, coords.z, GetEntityCoords(ped), true) < 50 and ped ~= PlayerPedId() then
                                    DeleteEntity(ped)
                                end
                            end
                            
                            for _, obj in ipairs(objects) do
                                if GetDistanceBetweenCoords(coords.x, coords.y, coords.z, GetEntityCoords(obj), true) < 50 then
                                    DeleteEntity(obj)
                                end
                            end
                            
                            sendOptimizedNotification("Cleared <span class=\"notification-key\">Area</span>", 'success')
                        end
                    },
                    {
                        label = 'Explode Area',
                        type = 'button',
                        icon = 'fas fa-bomb',
                        onConfirm = function()
                            local coords = GetEntityCoords(PlayerPedId())
                            for i = 1, 20 do
                                local x = coords.x + math.random(-20, 20)
                                local y = coords.y + math.random(-20, 20)
                                AddExplosion(x, y, coords.z, 1, 50.0, true, false, true)
                            end
                            sendOptimizedNotification("Exploded <span class=\"notification-key\">Area</span>", 'success')
                        end
                    },
                    {
                        label = 'Heal All Players',
                        type = 'button',
                        icon = 'fas fa-heart',
                        onConfirm = function()
                            local players = GetActivePlayers()
                            for _, player in ipairs(players) do
                                local ped = GetPlayerPed(player)
                                SetEntityHealth(ped, GetEntityMaxHealth(ped))
                                SetPedArmour(ped, 100)
                            end
                            sendOptimizedNotification("Healed <span class=\"notification-key\">All Players</span>", 'success')
                        end
                    },
                    {
                        label = 'Kill All Players',
                        type = 'button',
                        icon = 'fas fa-skull',
                        onConfirm = function()
                            local players = GetActivePlayers()
                            for _, player in ipairs(players) do
                                if player ~= PlayerId() then
                                    local ped = GetPlayerPed(player)
                                    SetEntityHealth(ped, 0)
                                end
                            end
                            sendOptimizedNotification("Killed <span class=\"notification-key\">All Players</span>", 'success')
                        end
                    }
                }
            },
            {
                label = 'Information',
                type = 'submenu',
                icon = 'fas fa-info-circle',
                submenu = {
                    {
                        label = 'Server Info',
                        type = 'button',
                        icon = 'fas fa-server',
                        onConfirm = function()
                            local players = GetActivePlayers()
                            local playerCount = #players
                            local maxPlayers = 32 -- Default value, avoid GetConvarInt
                            local serverName = "Nebula Software Server" -- Use fixed name instead of GetConvar
                            
                            -- Get additional server info safely
                            local gameTime = GetClockHours() .. ":" .. string.format("%02d", GetClockMinutes())
                            local weather = "Clear" -- Default weather
                            
                            local infoMessage = "Server: <span class=\"notification-key\">" .. serverName .. "</span><br>" ..
                                              "Players: <span class=\"notification-key\">" .. playerCount .. "/" .. maxPlayers .. "</span><br>" ..
                                              "Time: <span class=\"notification-key\">" .. gameTime .. "</span><br>" ..
                                              "Weather: <span class=\"notification-key\">" .. weather .. "</span>"
                            
                            sendOptimizedNotification(infoMessage, 'info')
                        end
                    },
                    {
                        label = 'Position Info',
                        type = 'button',
                        icon = 'fas fa-map-marker-alt',
                        onConfirm = function()
                            local coords = GetEntityCoords(PlayerPedId())
                            local heading = GetEntityHeading(PlayerPedId())
                            sendOptimizedNotification("Position: <span class=\"notification-key\">" .. math.floor(coords.x) .. ", " .. math.floor(coords.y) .. ", " .. math.floor(coords.z) .. "</span><br>Heading: <span class=\"notification-key\">" .. math.floor(heading) .. "°</span>", 'info')
                        end
                    },
                    {
                        label = 'Vehicle Info',
                        type = 'button',
                        icon = 'fas fa-car',
                        onConfirm = function()
                            local vehicle = GetVehiclePedIsIn(PlayerPedId(), false)
                            if vehicle ~= 0 then
                                local model = GetEntityModel(vehicle)
                                local speed = GetEntitySpeed(vehicle)
                                local health = GetEntityHealth(vehicle)
                                local maxHealth = GetEntityMaxHealth(vehicle)
                                
                                sendOptimizedNotification("Vehicle Model: <span class=\"notification-key\">" .. model .. "</span><br>Speed: <span class=\"notification-key\">" .. math.floor(speed * 3.6) .. " km/h</span><br>Health: <span class=\"notification-key\">" .. health .. "/" .. maxHealth .. "</span>", 'info')
                            else
                                sendOptimizedNotification("You must be in a vehicle!", 'error')
                            end
                        end
                    },
                    {
                        label = 'Player Info',
                        type = 'button',
                        icon = 'fas fa-user',
                        onConfirm = function()
                            local ped = PlayerPedId()
                            local health = GetEntityHealth(ped)
                            local maxHealth = GetEntityMaxHealth(ped)
                            local armor = GetPedArmour(ped)
                            local wantedLevel = GetPlayerWantedLevel(PlayerId())
                            
                            sendOptimizedNotification("Health: <span class=\"notification-key\">" .. health .. "/" .. maxHealth .. "</span><br>Armor: <span class=\"notification-key\">" .. armor .. "</span><br>Wanted Level: <span class=\"notification-key\">" .. wantedLevel .. "</span>", 'info')
                        end
                    }
                }
            },
            {
                label = 'Teleportation',
                type = 'submenu',
                icon = 'fas fa-map-marked-alt',
                submenu = {
                    {
                        label = 'Los Santos Airport',
                        type = 'button',
                        icon = 'fas fa-plane',
                        onConfirm = function()
                            SetEntityCoords(PlayerPedId(), -1037.0, -2737.0, 20.0, false, false, false, true)
                            sendOptimizedNotification("Teleported to <span class=\"notification-key\">Los Santos Airport</span>", 'success')
                        end
                    },
                    {
                        label = 'Mount Chiliad',
                        type = 'button',
                        icon = 'fas fa-mountain',
                        onConfirm = function()
                            SetEntityCoords(PlayerPedId(), 501.0, 5600.0, 797.0, false, false, false, true)
                            sendOptimizedNotification("Teleported to <span class=\"notification-key\">Mount Chiliad</span>", 'success')
                        end
                    },
                    {
                        label = 'Vinewood Sign',
                        type = 'button',
                        icon = 'fas fa-sign',
                        onConfirm = function()
                            SetEntityCoords(PlayerPedId(), 700.0, 1200.0, 350.0, false, false, false, true)
                            sendOptimizedNotification("Teleported to <span class=\"notification-key\">Vinewood Sign</span>", 'success')
                        end
                    },
                    {
                        label = 'Sandy Shores',
                        type = 'button',
                        icon = 'fas fa-desert',
                        onConfirm = function()
                            SetEntityCoords(PlayerPedId(), 1900.0, 3700.0, 32.0, false, false, false, true)
                            sendOptimizedNotification("Teleported to <span class=\"notification-key\">Sandy Shores</span>", 'success')
                        end
                    }
                }
            }
        }
    },
    {
        label = "Freecam",
        type = 'submenu',
        icon = 'fas fa-video',
        submenu = {
            {
                label = 'Freecam Toggle',
                type = 'checkbox',
                icon = 'fas fa-video',
                checked = false,
                onConfirm = function(toggle)
                    if toggle then
                        startFreecam()
                        sendOptimizedNotification("Freecam: <span class=\"notification-key\">ON</span>", 'success')
                    else
                        stopFreecam()
                        sendOptimizedNotification("Freecam: <span class=\"notification-key\">OFF</span>", 'info')
                    end
                end
            },
            {
                label = 'Freecam Speed',
                type = 'slider',
                icon = 'fas fa-tachometer-alt',
                min = 0.1,
                max = 3.0,
                value = 1.0,
                step = 0.1,
                onConfirm = function(value)
                    freecamSpeed = value
                    sendOptimizedNotification("Freecam Speed: <span class=\"notification-key\">" .. string.format("%.1f", value) .. "x</span>", 'info')
                end
            },
            {
                label = 'Freecam Controls',
                type = 'button',
                icon = 'fas fa-gamepad',
                onConfirm = function()
                    sendOptimizedNotification("Freecam Controls:<br><span class=\"notification-key\">WASD</span> - Move<br><span class=\"notification-key\">Q/E</span> - Up/Down<br><span class=\"notification-key\">Mouse</span> - Look around<br><span class=\"notification-key\">Shift</span> - Speed boost", 'info')
                end
            }
        }
    },
    {
        label = "ESP [Testing]",
        type = 'submenu',
        icon = 'fas fa-eye',
        submenu = {
            {
                label = 'ESP Toggle',
                type = 'checkbox',
                icon = 'fas fa-eye',
                checked = false,
                onConfirm = function(toggle)
                    if toggle then
                        startESP()
                        sendOptimizedNotification("ESP: <span class=\"notification-key\">ON</span><br>Rainbow ESP active", 'success')
                    else
                        stopESP()
                        sendOptimizedNotification("ESP: <span class=\"notification-key\">OFF</span>", 'info')
                    end
                end
            },
            {
                label = 'Snap Lines',
                type = 'checkbox',
                icon = 'fas fa-project-diagram',
                checked = true,
                onConfirm = function(toggle)
                    espSettings.snapLines = toggle
                    sendOptimizedNotification("Snap Lines: <span class=\"notification-key\">" .. (toggle and "ON" or "OFF") .. "</span>", toggle and 'success' or 'info')
                end
            },
            {
                label = '3D Boxes',
                type = 'checkbox',
                icon = 'fas fa-cube',
                checked = true,
                onConfirm = function(toggle)
                    espSettings.boxes = toggle
                    sendOptimizedNotification("3D Boxes: <span class=\"notification-key\">" .. (toggle and "ON" or "OFF") .. "</span>", toggle and 'success' or 'info')
                end
            },
            {
                label = 'Skeletons',
                type = 'checkbox',
                icon = 'fas fa-bone',
                checked = false,
                onConfirm = function(toggle)
                    espSettings.skeletons = toggle
                    sendOptimizedNotification("Skeletons: <span class=\"notification-key\">" .. (toggle and "ON" or "OFF") .. "</span>", toggle and 'success' or 'info')
                end
            },
            {
                label = 'Wall Penetration',
                type = 'checkbox',
                icon = 'fas fa-eye-slash',
                checked = true,
                onConfirm = function(toggle)
                    espSettings.wallPenetration = toggle
                    sendOptimizedNotification("Wall Penetration: <span class=\"notification-key\">" .. (toggle and "ON" or "OFF") .. "</span>", toggle and 'success' or 'info')
                end
            },
            {
                label = 'ESP Info',
                type = 'button',
                icon = 'fas fa-info-circle',
                onConfirm = function()
                    sendOptimizedNotification("ESP Features:<br><span class=\"notification-key\">Snap Lines</span> - Lines to all players<br><span class=\"notification-key\">3D Boxes</span> - White boxes around players<br><span class=\"notification-key\">Skeletons</span> - Bone structure overlay<br><span class=\"notification-key\">Wall Penetration</span> - See through walls<br><span class=\"notification-key\">White Colors</span> - Clean white visibility", 'info')
                end
            }
        }
    },
    {
        -- settings menu
        label = "Settings",
        type = 'submenu',
        icon = 'fas fa-cog',
        submenu = {
            --  {
            --     label = "Themes",
            --     type = 'scroll',
            --     icon = 'fas fa-palette',
            --     selected = -1, -- <- was 1, made 0 for zero-based widgets
            --     options = {
            --       { label = "Default", value = "blue", banner = "https://downloads.replix.xyz/replixblue.png" },
            --       { label = "Purple",  value = "purple", banner = "https://downloads.replix.xyz/REPLIX_BANNER.gif" },
            --       { label = "Pink",    value = "pink", banner = "https://downloads.replix.xyz/replixpink.gif" },
            --       { label = "Orange",  value = "orange", banner = "https://downloads.replix.xyz/replixorange.gif" },
            --       { label = "Dark",    value = "dark", banner = "https://downloads.replix.xyz/REPLIX_BANNER.png" },
            --       { label = "Green",   value = "green", banner = "https://downloads.replix.xyz/REPLIX_BANNER.png" },
            --       { label = "Red",     value = "red", banner = "https://downloads.replix.xyz/REPLIX_BANNER.png" },
            --     },
            --     onConfirm = function(selectedOption)
            --         if selectedOption and selectedOption.value then
            --             print("Selected theme:", selectedOption.value)
            --             print("Banner URL:", selectedOption.banner)
            --             MachoSendDuiMessage(dui, json.encode({
            --                 action = 'setTheme',
            --                 theme = selectedOption.value
            --             }))
            --             MachoSendDuiMessage(dui, json.encode({
            --                 action = 'setBannerImage',
            --                 url = selectedOption.banner
            --             }))
            --         else
            --             print("Error: selectedOption is nil or missing value")
            --         end
            --     end
            -- },
            {
                label = "Theme Switcher",
                type = 'submenu',
                icon = 'fas fa-palette',
                submenu = {
                    {
                        label = 'Default Theme',
                        type = 'button',
                        onConfirm = function()
                            if dui then
                                MachoSendDuiMessage(dui, json.encode({
                                    action = 'setTheme',
                                    theme = 'blue'
                                }))
                                MachoSendDuiMessage(dui, json.encode({
                                    action = 'setBannerImage',
                                    url = 'https://cdn.discordapp.com/attachments/1404009821908504616/1415079678263431339/PROFILE-BANNER.gif?ex=68db9c66&is=68da4ae6&hm=67b6e50f3d7150a884b6e423476f733abf261cf7e98716e4b98dfe7aadd3cf4b&'
                                }))
                                MachoSendDuiMessage(dui, json.encode({
                                    action = 'notify',
                                    message = "Theme changed to <span class=\"notification-key\">Blue</span>",
                                    type = 'success'
                                }))
                            end
                        end
                    },
                    {
                        label = 'Purple Theme',
                        type = 'button',
                        onConfirm = function()
                            if dui then
                                MachoSendDuiMessage(dui, json.encode({
                                    action = 'setTheme',
                                    theme = 'purple'
                                }))
                                MachoSendDuiMessage(dui, json.encode({
                                    action = 'setBannerImage',
                                    url = 'https://cdn.discordapp.com/attachments/1404009821908504616/1415079678263431339/PROFILE-BANNER.gif?ex=68db9c66&is=68da4ae6&hm=67b6e50f3d7150a884b6e423476f733abf261cf7e98716e4b98dfe7aadd3cf4b&'
                                }))
                                MachoSendDuiMessage(dui, json.encode({
                                    action = 'notify',
                                    message = "Theme changed to <span class=\"notification-key\">Purple</span>",
                                    type = 'success'
                                }))
                            end
                        end
                    },
                    {
                        label = 'Orange Theme',
                        type = 'button',
                        onConfirm = function()
                            if dui then
                                MachoSendDuiMessage(dui, json.encode({
                                    action = 'setTheme',
                                    theme = 'orange'
                                }))
                                MachoSendDuiMessage(dui, json.encode({
                                    action = 'setBannerImage',
                                    url = 'https://cdn.discordapp.com/attachments/1404009821908504616/1415079678263431339/PROFILE-BANNER.gif?ex=68db9c66&is=68da4ae6&hm=67b6e50f3d7150a884b6e423476f733abf261cf7e98716e4b98dfe7aadd3cf4b&'
                                }))
                                MachoSendDuiMessage(dui, json.encode({
                                    action = 'notify',
                                    message = "Theme changed to <span class=\"notification-key\">Orange</span>",
                                    type = 'success'
                                }))
                            end
                        end
                    },
                    -- pink theme
                    {
                        label = 'Pink Theme',
                        type = 'button',
                        onConfirm = function()
                            if dui then
                                MachoSendDuiMessage(dui, json.encode({
                                    action = 'setTheme',
                                    theme = 'pink'
                                }))
                                MachoSendDuiMessage(dui, json.encode({
                                    action = 'setBannerImage',
                                    url = 'https://cdn.discordapp.com/attachments/1404009821908504616/1415079678263431339/PROFILE-BANNER.gif?ex=68db9c66&is=68da4ae6&hm=67b6e50f3d7150a884b6e423476f733abf261cf7e98716e4b98dfe7aadd3cf4b&'
                                }))
                                MachoSendDuiMessage(dui, json.encode({
                                    action = 'notify',
                                    message = "Theme changed to <span class=\"notification-key\">Pink</span>",
                                    type = 'success'
                                }))
                            end
                        end
                    },
                    -- dark theme
                    {
                        label = 'Dark Theme',
                        type = 'button',
                        onConfirm = function()
                            if dui then
                                MachoSendDuiMessage(dui, json.encode({
                                    action = 'setTheme',
                                    theme = 'dark'
                                }))
                                MachoSendDuiMessage(dui, json.encode({
                                    action = 'setBannerImage',
                                    url = 'https://cdn.discordapp.com/attachments/1404009821908504616/1415079678263431339/PROFILE-BANNER.gif?ex=68db9c66&is=68da4ae6&hm=67b6e50f3d7150a884b6e423476f733abf261cf7e98716e4b98dfe7aadd3cf4b&'
                                }))
                                MachoSendDuiMessage(dui, json.encode({
                                    action = 'notify',
                                    message = "Theme changed to <span class=\"notification-key\">Dark</span>",
                                    type = 'success'
                                }))
                            end
                        end
                    },
                    -- red theme
                    {
                        label = 'Red Theme',
                        type = 'button',
                        onConfirm = function()
                            if dui then
                                MachoSendDuiMessage(dui, json.encode({
                                    action = 'setTheme',
                                    theme = 'red'
                                }))
                                MachoSendDuiMessage(dui, json.encode({
                                    action = 'setBannerImage',
                                    url = 'https://cdn.discordapp.com/attachments/1404009821908504616/1415079678263431339/PROFILE-BANNER.gif?ex=68db9c66&is=68da4ae6&hm=67b6e50f3d7150a884b6e423476f733abf261cf7e98716e4b98dfe7aadd3cf4b&'
                                }))
                                MachoSendDuiMessage(dui, json.encode({
                                    action = 'notify',
                                    message = "Theme changed to <span class=\"notification-key\">Red</span>",
                                    type = 'success'
                                }))
                            end
                        end
                    }
                }
            },
            {
                label = 'Menu Position',
                type = 'submenu',
                icon = 'fas fa-arrows-alt',
                submenu = {
                    {
                        label = 'X Position',
                        type = 'slider',
                        icon = 'fas fa-arrows-alt-h',
                        min = 0,
                        max = 100,
                        value = math.floor(menuPosition.x * 100),
                        step = 1,
                        onConfirm = function(val)
                            menuPosition.x = val / 100.0
                            updateMenuPosition(menuPosition.x, menuPosition.y)
                            sendOptimizedNotification("Menu X Position: <span class=\"notification-key\">" .. val .. "%</span>", 'success')
                        end,
                        onChange = function(val)
                            menuPosition.x = val / 100.0
                            updateMenuPosition(menuPosition.x, menuPosition.y)
                        end
                    },
                    {
                        label = 'Y Position',
                        type = 'slider',
                        icon = 'fas fa-arrows-alt-v',
                        min = 0,
                        max = 100,
                        value = math.floor(menuPosition.y * 100),
                        step = 1,
                        onConfirm = function(val)
                            menuPosition.y = val / 100.0
                            updateMenuPosition(menuPosition.x, menuPosition.y)
                            sendOptimizedNotification("Menu Y Position: <span class=\"notification-key\">" .. val .. "%</span>", 'success')
                        end,
                        onChange = function(val)
                            menuPosition.y = val / 100.0
                            updateMenuPosition(menuPosition.x, menuPosition.y)
                        end
                    },
                    {
                        label = 'Reset to Center',
                        type = 'button',
                        icon = 'fas fa-crosshairs',
                        onConfirm = function()
                            menuPosition.x = 0.5
                            menuPosition.y = 0.5
                            updateMenuPosition(menuPosition.x, menuPosition.y)
                            MachoSendDuiMessage(dui, json.encode({
                                action = 'notify',
                                message = "Menu position <span class=\"notification-key\">reset to center</span>",
                                type = 'success'
                            }))
                        end
                    }
                }
            },
            {
                label = 'Menu Transparency',
                type = 'submenu',
                icon = 'fas fa-eye',
                submenu = {
                    {
                        label = 'Opacity',
                        type = 'slider',
                        icon = 'fas fa-adjust',
                        min = 10,
                        max = 100,
                        value = math.floor(menuOpacity * 100),
                        step = 5,
                        onConfirm = function(val)
                            menuOpacity = val / 100.0
                            sendOptimizedNotification("Menu Opacity: <span class=\"notification-key\">" .. val .. "%</span>", 'success')
                        end,
                        onChange = function(val)
                            menuOpacity = val / 100.0
                        end
                    },
                    {
                        label = 'Fully Transparent',
                        type = 'checkbox',
                        icon = 'fas fa-eye-slash',
                        checked = menuOpacity == 0.0,
                        onConfirm = function(toggle)
                            if toggle then
                                menuOpacity = 0.0
                            else
                                menuOpacity = 1.0
                            end
                            MachoSendDuiMessage(dui, json.encode({
                                action = 'notify',
                                message = "Menu Transparency: <span class=\"notification-key\">" .. (toggle and "ON" or "OFF") .. "</span>",
                                type = toggle and 'success' or 'info'
                            }))
                        end
                    }
                }
            },
            {
                label = 'Menu Size',
                type = 'submenu',
                icon = 'fas fa-expand-arrows-alt',
                submenu = {
                    {
                        label = 'Scale',
                        type = 'slider',
                        icon = 'fas fa-search-plus',
                        min = 50,
                        max = 200,
                        value = math.floor(menuScale * 100),
                        step = 10,
                        onConfirm = function(val)
                            menuScale = val / 100.0
                            sendOptimizedNotification("Menu Scale: <span class=\"notification-key\">" .. val .. "%</span>", 'success')
                        end,
                        onChange = function(val)
                            menuScale = val / 100.0
                        end
                    },
                    {
                        label = 'Reset Size',
                        type = 'button',
                        icon = 'fas fa-undo',
                        onConfirm = function()
                            menuScale = 1.0
                            MachoSendDuiMessage(dui, json.encode({
                                action = 'notify',
                                message = "Menu size <span class=\"notification-key\">reset to default</span>",
                                type = 'success'
                            }))
                        end
                    }
                }
            },
            {
                label = 'Reset All Settings',
                type = 'button',
                icon = 'fas fa-redo',
                onConfirm = function()
                    menuPosition.x = 0.5
                    menuPosition.y = 0.5
                    menuOpacity = 1.0
                    menuScale = 1.0
                    updateMenuPosition(menuPosition.x, menuPosition.y)
                    MachoSendDuiMessage(dui, json.encode({
                        action = 'notify',
                        message = "All menu settings <span class=\"notification-key\">reset to default</span>",
                        type = 'success'
                    }))
                end
            }
        }
    }
}

activeMenu = originalMenu


-- Safe copy for DUI
local function safeMenuCopy(menu)
    local copy = {}
    for i, v in ipairs(menu) do
        local item = {
            label = v.label or "",
            type = v.type or ""
        }
        if v.icon then item.icon = v.icon end

        if v.type == "scroll" then
            item.options = {}
            for _, opt in ipairs(v.options or {}) do
                if type(opt) == "table" then
                    table.insert(item.options, {
                        label = tostring(opt.label or ""),
                        value = tostring(opt.value or "")
                    })
                else
                    table.insert(item.options, tostring(opt))
                end
            end
            item.selected = v.selected or 1
        elseif v.type == "slider" then
            item.min = v.min or 0
            item.max = v.max or 100
            item.value = v.value or 50
            item.step = v.step or 1
        elseif v.type == "checkbox" then
            item.checked = v.checked or false
        elseif v.type == "submenu" then
            item.submenu = safeMenuCopy(v.submenu or {})
        end

        table.insert(copy, item)
    end
    return copy
end
-- Initialize PlayerList menu with current players
updatePlayerlistData()

-- Thread to update playerlist data periodically (from replix_main.lua)
-- Optimized player list update thread
CreateThread(function()
    local lastPlayerCount = 0
    local lastUpdateTime = 0
    local updateInterval = 5000 -- 5 seconds
    
    while true do
        local currentTime = GetGameTimer()
        
        -- Only update if enough time has passed and menu is showing
        if currentTime - lastUpdateTime >= updateInterval and _G.clientMenuShowing then
            local currentPlayerCount = #GetActivePlayers()
            
            -- Only update if player count changed or forced update
            if currentPlayerCount ~= lastPlayerCount then
            updatePlayerlistData()
                lastPlayerCount = currentPlayerCount
                
            -- Send updated data to NUI
            if dui then
                MachoSendDuiMessage(dui, json.encode({
                    action = 'setCurrent',
                    current = activeIndex,
                    menu = safeMenuCopy(activeMenu)
                }))
            end
        end
            
            lastUpdateTime = currentTime
        end
        
        -- Adaptive wait time based on menu visibility
        Wait(_G.clientMenuShowing and 1000 or 5000)
    end
end)

-- Thread to update selected player data in real-time
CreateThread(function()
    while true do
        Wait(500) -- Update every 500ms
        if _G.clientMenuShowing and currentSelectedPlayer then
            -- Get fresh player data
            local freshPlayerData = nil
            local players = getRealPlayerData()
            
            -- Find the current selected player in the fresh data
            for _, player in ipairs(players) do
                if player.id == currentSelectedPlayer.id then
                    freshPlayerData = player
                    break
                end
            end
            
            -- Update the selected player data if found
            if freshPlayerData then
                currentSelectedPlayer = freshPlayerData
                -- Send updated player data to frontend
                if dui then
                    MachoSendDuiMessage(dui, json.encode({
                        action = 'setSelectedPlayer',
                        playerData = currentSelectedPlayer
                    }))
                end
            end
        elseif not _G.clientMenuShowing and currentSelectedPlayer then
            -- Clear selected player when menu is hidden
            currentSelectedPlayer = nil
            if dui then
                MachoSendDuiMessage(dui, json.encode({
                    action = 'setSelectedPlayer',
                    playerData = nil
                }))
            end
        end
    end
end)

function setCurrent()
    if dui and menuInitialized then
        -- Sending setCurrent message
        MachoSendDuiMessage(dui, json.encode({
            action = 'setCurrent',
            current = activeIndex,
            menu = safeMenuCopy(activeMenu)
        }))
    else
        -- setCurrent failed
    end
end

local function isControlJustPressed(control)
    return IsControlJustPressed(0, control) or IsDisabledControlJustPressed(0, control)
end

local function initializeMenu()
    if not menuInitialized and dui then
        menuInitialized = true
        activeMenu = originalMenu
        activeIndex = 1
        
        MachoSendDuiMessage(dui, json.encode({
            action = 'setFooterText',
            text = 'Nebula Software [Macho] 1.0.0'
        }))
        
        MachoSendDuiMessage(dui, json.encode({
            action = 'setMenuVisible',
            visible = _G.clientMenuShowing
        }))
        
        setCurrent()
    end
end

function setCurrent()
    if dui and menuInitialized then
        MachoSendDuiMessage(dui, json.encode({
            action = 'setCurrent',
            current = activeIndex,
            menu = safeMenuCopy(activeMenu)
        }))
    end
end

-- Make these global so they can be accessed from different threads
_G.keybindSetupActive = false
_G.inputRecordingActive = false
_G.inputBuffer = ""
_G.inputMaxLength = 100

-- Player info management variables
currentSelectedPlayer = nil
nestedMenus = {}

-- Function to send selected player data to NUI
function sendSelectedPlayerData()
    if not dui or not menuInitialized then return end
    
    local currentItem = activeMenu[activeIndex]
    if not currentItem then return end
    
    -- Check if we're on a player submenu item
    if currentItem.playerData then
        currentSelectedPlayer = currentItem.playerData
        MachoSendDuiMessage(dui, json.encode({
            action = 'setSelectedPlayer',
            playerData = currentItem.playerData
        }))
    -- Check if we're on the Online Players main menu
    elseif currentItem.label == 'Online Players' and currentItem.type == 'submenu' and currentItem.submenu and #currentItem.submenu > 0 then
        -- Auto-select first player when on Online Players main menu
        local firstPlayerItem = currentItem.submenu[1]
        if firstPlayerItem.playerData then
            currentSelectedPlayer = firstPlayerItem.playerData
            MachoSendDuiMessage(dui, json.encode({
                action = 'setSelectedPlayer',
                playerData = firstPlayerItem.playerData
            }))
        end
    -- Check if we're in a player's submenu (actions like Teleport, Bring, etc.)
    elseif currentSelectedPlayer and isInPlayerSubmenu() then
        -- Keep the selected player when in their submenu
        MachoSendDuiMessage(dui, json.encode({
            action = 'setSelectedPlayer',
            playerData = currentSelectedPlayer
        }))
    -- Fallback: if we have a selected player and we're in any submenu, keep it
    elseif currentSelectedPlayer and #nestedMenus > 0 then
        -- Keep the selected player when in any submenu if we have one selected
        MachoSendDuiMessage(dui, json.encode({
            action = 'setSelectedPlayer',
            playerData = currentSelectedPlayer
        }))
    else
        -- Clear selected player when not on any player-related menu
        currentSelectedPlayer = nil
        MachoSendDuiMessage(dui, json.encode({
            action = 'setSelectedPlayer',
            playerData = nil
        }))
    end
end

-- Function to check if we're currently in a player's submenu
function isInPlayerSubmenu()
    -- Check if any of the nested menus contain player data
    for i = 1, #nestedMenus do
        local nestedMenu = nestedMenus[i]
        if nestedMenu.menu and nestedMenu.menu[nestedMenu.index] then
            local menuItem = nestedMenu.menu[nestedMenu.index]
            if menuItem.playerData then
                return true
            end
        end
    end

    -- Also check if we're in a submenu that was created from a player item
    -- This handles the case where we entered a player's submenu from PlayerList
    if #nestedMenus > 0 then
        local lastNestedMenu = nestedMenus[#nestedMenus]
        if lastNestedMenu.menu and lastNestedMenu.menu[lastNestedMenu.index] then
            local parentItem = lastNestedMenu.menu[lastNestedMenu.index]
            if parentItem.playerData then
                return true
            end
        end
    end

    return false
end

-- Function to handle input key recording
local function handleInputKeyRecording()
    if not _G.inputRecordingActive then return end
    
    -- Disable game controls during text input to prevent interference
    DisableAllControlActions(0)
    EnableControlAction(0, 1, true) -- Mouse
    EnableControlAction(0, 2, true) -- Mouse wheel
    
    -- Specifically disable ESC and BACKSPACE to prevent menu/pause interference
    DisableControlAction(0, 322, true) -- ESC
    DisableControlAction(0, 177, true) -- BACKSPACE
    
    -- Key mapping for input
    local inputKeyMap = {
        ["A"] = "a", ["B"] = "b", ["C"] = "c", ["D"] = "d", ["E"] = "e", ["F"] = "f", ["G"] = "g", ["H"] = "h",
        ["I"] = "i", ["J"] = "j", ["K"] = "k", ["L"] = "l", ["M"] = "m", ["N"] = "n", ["O"] = "o", ["P"] = "p",
        ["Q"] = "q", ["R"] = "r", ["S"] = "s", ["T"] = "t", ["U"] = "u", ["V"] = "v", ["W"] = "w", ["X"] = "x",
        ["Y"] = "y", ["Z"] = "z",
        ["1"] = "1", ["2"] = "2", ["3"] = "3", ["4"] = "4", ["5"] = "5", ["6"] = "6", ["7"] = "7", ["8"] = "8", ["9"] = "9", ["0"] = "0",
        ["SPACE"] = " ", ["-"] = "-", ["="] = "=", ["["] = "[", ["]"] = "]", ["\\"] = "\\", [";"] = ";", ["'"] = "'",
        [","] = ",", ["."] = ".", ["/"] = "/", ["`"] = "`"
    }
    
    for keyName, char in pairs(inputKeyMap) do
        local controlId = nil
        -- Map key names to control IDs (correct FiveM control IDs)
        if keyName == "A" then controlId = 34
        elseif keyName == "B" then controlId = 29
        elseif keyName == "C" then controlId = 26
        elseif keyName == "D" then controlId = 9
        elseif keyName == "E" then controlId = 38
        elseif keyName == "F" then controlId = 23
        elseif keyName == "G" then controlId = 47
        elseif keyName == "H" then controlId = 74
        elseif keyName == "I" then controlId = 73
        elseif keyName == "J" then controlId = 74
        elseif keyName == "K" then controlId = 311
        elseif keyName == "L" then controlId = 182
        elseif keyName == "M" then controlId = 244
        elseif keyName == "N" then controlId = 249
        elseif keyName == "O" then controlId = 73
        elseif keyName == "P" then controlId = 199
        elseif keyName == "Q" then controlId = 44
        elseif keyName == "R" then controlId = 45
        elseif keyName == "S" then controlId = 8
        elseif keyName == "T" then controlId = 245
        elseif keyName == "U" then controlId = 73
        elseif keyName == "V" then controlId = 0
        elseif keyName == "W" then controlId = 32
        elseif keyName == "X" then controlId = 73
        elseif keyName == "Y" then controlId = 246
        elseif keyName == "Z" then controlId = 20
        elseif keyName == "1" then controlId = 157
        elseif keyName == "2" then controlId = 158
        elseif keyName == "3" then controlId = 160
        elseif keyName == "4" then controlId = 164
        elseif keyName == "5" then controlId = 165
        elseif keyName == "6" then controlId = 159
        elseif keyName == "7" then controlId = 161
        elseif keyName == "8" then controlId = 162
        elseif keyName == "9" then controlId = 163
        elseif keyName == "0" then controlId = 157
        elseif keyName == "SPACE" then controlId = 22
        elseif keyName == "-" then controlId = 84
        elseif keyName == "=" then controlId = 83
        elseif keyName == "[" then controlId = 39
        elseif keyName == "]" then controlId = 40
        elseif keyName == "\\" then controlId = 40
        elseif keyName == ";" then controlId = 40
        elseif keyName == "'" then controlId = 40
        elseif keyName == "," then controlId = 82
        elseif keyName == "." then controlId = 81
        elseif keyName == "/" then controlId = 81
        elseif keyName == "`" then controlId = 40
        end
        
        if controlId and (IsControlJustPressed(0, controlId) or IsDisabledControlJustPressed(0, controlId)) then
            -- Add character to buffer
            print("Lua: Character key pressed:", keyName, "char:", char, "controlId:", controlId)
            if #_G.inputBuffer < _G.inputMaxLength then
                _G.inputBuffer = _G.inputBuffer .. char
                print("Lua: Character added - new buffer:", _G.inputBuffer)
                MachoSendDuiMessage(dui, json.encode({
                    action = 'updateTextInput',
                    value = _G.inputBuffer
                }))
            else
                print("Lua: Buffer is full, cannot add character")
            end
            break
        end
    end
    
    -- Check for special keys separately (ESC, ENTER, BACKSPACE)
    if IsControlJustPressed(0, 322) or IsDisabledControlJustPressed(0, 322) then -- ESC - Cancel input
        stopInputRecording()
        MachoSendDuiMessage(dui, json.encode({
            action = 'cancelTextInput'
        }))
        -- Close the text input modal
        MachoSendDuiMessage(dui, json.encode({
            action = 'closeTextInput'
        }))
        print("Lua: Input cancelled")
        -- Add a small delay to prevent menu from processing the same ESC press
        Wait(200)
        return
    elseif IsControlJustPressed(0, 18) or IsDisabledControlJustPressed(0, 18) then -- ENTER - Submit input
        stopInputRecording()
        
        -- Handle input submission
        if _G.inputCallback then
            -- Use callback function if provided
            _G.inputCallback(_G.inputBuffer)
        else
            -- Fallback to menu item handling
            local activeData = activeMenu[activeIndex]
            if activeData and activeData.type == 'input' then
                activeData.value = _G.inputBuffer
                setCurrent() -- Refresh the menu display
                
                -- Handle specific input types
                if activeData.originalLabel == 'Set Plate' then
                    -- Set the vehicle's license plate
                    local playerPed = PlayerPedId()
                    local vehicle = GetVehiclePedIsIn(playerPed, false)
                    
                    if vehicle ~= 0 then
                        -- Set the license plate text
                        SetVehicleNumberPlateText(vehicle, _G.inputBuffer)
                        
                        -- Send notification
                        if dui then
                            MachoSendDuiMessage(dui, json.encode({
                                action = 'notify',
                                message = "License plate set to: <span class=\"notification-key\">" .. _G.inputBuffer .. "</span>",
                                type = 'success'
                            }))
                        end
                        print("Lua: License plate set to:", _G.inputBuffer)
                    else
                        -- Player is not in a vehicle
                        if dui then
                            MachoSendDuiMessage(dui, json.encode({
                                action = 'notify',
                                message = "You must be in a vehicle to set the license plate!",
                                type = 'error'
                            }))
                        end
                        print("Lua: Player is not in a vehicle")
                    end
                elseif activeData.originalLabel == 'Enter Player Name' then
                    -- Handle player name input
                    if dui then
                        MachoSendDuiMessage(dui, json.encode({
                            action = 'notify',
                            message = "Player name set to: <span class=\"notification-key\">" .. _G.inputBuffer .. "</span>",
                            type = 'success'
                        }))
                    end
                    print("Lua: Player name set to:", _G.inputBuffer)
                elseif activeData.originalLabel == 'Enter Money Amount' then
                    -- Handle money amount input
                    local amount = tonumber(_G.inputBuffer)
                    if amount then
                        if dui then
                            MachoSendDuiMessage(dui, json.encode({
                                action = 'notify',
                                message = "Money amount set to: <span class=\"notification-key\">$" .. amount .. "</span>",
                                type = 'success'
                            }))
                        end
                        print("Lua: Money amount set to:", amount)
                    else
                        if dui then
                            MachoSendDuiMessage(dui, json.encode({
                                action = 'notify',
                                message = "Invalid money amount!",
                                type = 'error'
                            }))
                        end
                        print("Lua: Invalid money amount")
                    end
                end
            end
        end
        
        -- Clear the callback
        _G.inputCallback = nil
        
        MachoSendDuiMessage(dui, json.encode({
            action = 'submitTextInput',
            value = _G.inputBuffer
        }))
        print("Lua: Input submitted:", _G.inputBuffer)
        -- Wait a moment to show the submitted text before closing
        Wait(1000)
        -- Close the text input modal
        MachoSendDuiMessage(dui, json.encode({
            action = 'closeTextInput'
        }))
        -- Add a small delay to prevent menu from processing the same ENTER press
        Wait(200)
        return
    elseif IsControlJustPressed(0, 177) or IsDisabledControlJustPressed(0, 177) then -- BACKSPACE - Remove last character
        print("Lua: BACKSPACE pressed, current buffer length:", #_G.inputBuffer)
        if #_G.inputBuffer > 0 then
            _G.inputBuffer = string.sub(_G.inputBuffer, 1, #_G.inputBuffer - 1)
            print("Lua: BACKSPACE - new buffer:", _G.inputBuffer)
            MachoSendDuiMessage(dui, json.encode({
                action = 'updateTextInput',
                value = _G.inputBuffer
            }))
        else
            print("Lua: BACKSPACE - buffer is empty, nothing to delete")
        end
        return
    end
end

local function setupKeybind()
    if not keybindSetup and dui then
        keybindSetup = true
        _G.keybindSetupActive = true
        
        MachoSendDuiMessage(dui, json.encode({
            action = 'setMenuVisible',
            visible = false
        }))
        _G.clientMenuShowing = false
        
        MachoSendDuiMessage(dui, json.encode({
            action = 'openKeySelection',
            title = 'Menu Keybind Setup',
            instruction = 'Press any key to set as the menu open key',
            hint = 'ESC to use default (Page Down)'
        }))
        print("Macho: Keybind setup activated")
    end
end


local function closeMenu()
    if dui then
        MachoSendDuiMessage(dui, json.encode({
            action = 'setMenuVisible',
            visible = false
        }))
    end
    
    menuInitialized = false
end

-- Handle text input responses via DUI commands
-- This function will be called when the frontend executes: ExecuteCommand('dui_textInputResponse true "value" "inputId"')
function handleTextInputResponse(data)
    local success = data.success
    local value = data.value
    local inputId = data.inputId
    
    if success then
        -- Handle successful input
        if inputId == 'player_name' then
            -- Player name entered
            if dui then
                MachoSendDuiMessage(dui, json.encode({
                    action = 'notify',
                    message = "Name set to: " .. value,
                    type = 'success'
                }))
            end
        elseif inputId == 'give_money' then
            local amount = tonumber(value)
            if amount then
                -- Money amount entered
                if dui then
                    MachoSendDuiMessage(dui, json.encode({
                        action = 'notify',
                        message = "Giving $" .. amount .. " to player",
                        type = 'success'
                    }))
                end
            end
        else
            -- Handle general text input (like vehicle search)
            if _G.inputCallback then
                _G.inputCallback(value)
                _G.inputCallback = nil -- Clear callback after use
            end
        end
    else
        -- Handle cancelled input
        -- Text input cancelled
        if dui then
            MachoSendDuiMessage(dui, json.encode({
                action = 'notify',
                message = "Input cancelled",
                type = 'warn'
            }))
        end
    end
    
    -- Always stop input recording and reset state
    _G.inputRecordingActive = false
    _G.inputBuffer = ""
    _G.inputCallback = nil
    print("Lua: Input recording stopped and state reset")
end
    


-- Main thread
CreateThread(function()
    -- Create DUI using Macho API
    dui = MachoCreateDui("https://five-m-menu-framework.vercel.app/")
    
    if dui then
        print("Macho DUI created successfully")
        
        -- Set theme and banner
        MachoSendDuiMessage(dui, json.encode({
            action = 'setTheme',
            theme = 'blue'
        }))
        
        MachoSendDuiMessage(dui, json.encode({
            action = 'setBannerImage',
            url = 'https://cdn.discordapp.com/attachments/1404009821908504616/1415079678263431339/PROFILE-BANNER.gif'
        }))
        
        _G.clientMenuShowing = false
        setupKeybind()
        
        -- Show DUI (Macho handles rendering automatically)
        MachoShowDui(dui)
    else
        print("Failed to create Macho DUI")
        return
    end

    -- Menu toggle thread - uses custom keybind with injection
    CreateThread(function()
        local lastPress = 0
        print("Lua: Menu toggle thread started with menuOpenKey:", menuOpenKey)
        while true do
            -- Use the custom menu open key with injection method
            if IsControlJustPressed(0, menuOpenKey) or IsDisabledControlJustPressed(0, menuOpenKey) then
                print("Lua: Menu open key pressed - Control ID:", menuOpenKey)
                local currentTime = GetGameTimer()
                if currentTime - lastPress > 200 then
                    if _G.clientMenuShowing then
                        -- Send hide message to frontend instead of setting global to false
                        if dui then
                            MachoSendDuiMessage(dui, json.encode({
                                action = 'setMenuVisible',
                                visible = false
                            }))
                        end
                        _G.clientMenuShowing = false
                        -- Menu closed - cleanup modifications
                        cleanupAllModifications()
                    else
                        _G.clientMenuShowing = true
                        -- Menu opened
                        if dui then
                            MachoSendDuiMessage(dui, json.encode({
                                action = 'setMenuVisible',
                                visible = true
                            }))
                        end
                    end
                    lastPress = currentTime
                end
            end
            
            -- Handle F9 keybind setup globally (even when menu is closed) with injection
            if IsControlJustPressed(0, keyMap["F9"]) or IsDisabledControlJustPressed(0, keyMap["F9"]) then -- F9 key
                if _G.clientMenuShowing then
                    -- Menu is open, trigger menu keybind setup
                    if dui then
                        MachoSendDuiMessage(dui, json.encode({
                            action = 'openKeySelection',
                            title = 'Menu Keybind Setup',
                            instruction = 'Press any key to set as the menu open key',
                            hint = 'ESC to use default (Page Down)'
                        }))
                        _G.keybindSetupActive = true
                        keybindSetup = true
                    end
                else
                    -- Menu is closed, open it first then trigger keybind setup
                    _G.clientMenuShowing = true
                    -- Menu opened for keybind setup
                    if dui then
                        MachoSendDuiMessage(dui, json.encode({
                            action = 'setMenuVisible',
                            visible = true
                        }))
                    end
                    -- Small delay to ensure menu is initialized
                    Wait(100)
                    if dui then
                        MachoSendDuiMessage(dui, json.encode({
                            action = 'openKeySelection',
                            title = 'Menu Keybind Setup',
                            instruction = 'Press any key to set as the menu open key',
                            hint = 'ESC to use default (Page Down)'
                        }))
                        _G.keybindSetupActive = true
                        keybindSetup = true
                    end
                end
            end
            
            Wait(0)
        end
    end)


    -- Main menu loop
    local showing = false
    -- Use global nestedMenus instead of local
    _G.clientMenuShowing = false
    
    -- Keybind setup state
    local keybindSetupKey = nil
    local keybindSetupKeyName = ""

    while true do
        if _G.clientMenuShowing and not showing then
            showing = true
            initializeMenu()
            nestedMenus = {} -- Reset global nestedMenus
        elseif not _G.clientMenuShowing and showing then
            showing = false
            closeMenu()
        end
        
        -- Handle input recording globally
        handleInputKeyRecording()
        
        -- Handle keybind setup globally (even when menu is not showing)
        if _G.keybindSetupActive then
            -- Key mapping for better detection
            local keyMap = {
                ["ESC"] = 322, ["F1"] = 288, ["F2"] = 289, ["F3"] = 170, ["F5"] = 166, ["F6"] = 167, ["F7"] = 168, ["F8"] = 169, ["F9"] = 56, ["F10"] = 57, ["F11"] = 288, ["F12"] = 289,
                ["~"] = 243, ["1"] = 157, ["2"] = 158, ["3"] = 160, ["4"] = 164, ["5"] = 165, ["6"] = 159, ["7"] = 161, ["8"] = 162, ["9"] = 163, ["0"] = 157, ["-"] = 84, ["="] = 83, ["BACKSPACE"] = 177,
                ["TAB"] = 37, ["Q"] = 44, ["W"] = 32, ["E"] = 38, ["R"] = 45, ["T"] = 245, ["Y"] = 246, ["U"] = 303, ["I"] = 303, ["O"] = 303, ["P"] = 199, ["["] = 39, ["]"] = 40, ["ENTER"] = 18,
                ["CAPS"] = 137, ["A"] = 34, ["S"] = 8, ["D"] = 9, ["F"] = 23, ["G"] = 47, ["H"] = 74, ["J"] = 74, ["K"] = 311, ["L"] = 182,
                ["LEFTSHIFT"] = 21, ["Z"] = 20, ["X"] = 73, ["C"] = 26, ["V"] = 0, ["B"] = 29, ["N"] = 249, ["M"] = 244, [","] = 82, ["."] = 81, ["/"] = 81,
                ["LEFTCTRL"] = 36, ["LEFTALT"] = 19, ["SPACE"] = 22, ["RIGHTCTRL"] = 70,
                ["HOME"] = 213, ["PAGEUP"] = 10, ["PAGEDOWN"] = 11, ["DELETE"] = 178, ["INSERT"] = 178,
                ["LEFT"] = 174, ["RIGHT"] = 175, ["TOP"] = 27, ["DOWN"] = 173,
                ["NENTER"] = 201, ["N4"] = 108, ["N5"] = 60, ["N6"] = 107, ["N+"] = 96, ["N-"] = 97, ["N7"] = 117, ["N8"] = 61, ["N9"] = 118
            }
            
            -- Check for key presses using the key map
            for keyName, controlId in pairs(keyMap) do
                if IsControlJustPressed(0, controlId) or IsDisabledControlJustPressed(0, controlId) then
                    print("Lua: Key pressed during global keybind setup - Key:", keyName, "Control ID:", controlId)
                    if controlId == 322 then -- ESC key
                        -- Cancel keybind setup
                        _G.keybindSetupActive = false
                        keybindSetup = false
                        print("Lua: keybindSetupActive set to false (cancelled)")
                        
                        if dui then
                            MachoSendDuiMessage(dui, json.encode({
                                action = 'closeKeySelection'
                            }))
                            MachoSendDuiMessage(dui, json.encode({
                                action = 'notify',
                                message = "Keybind setup cancelled",
                                type = 'info'
                            }))
                            -- Show the menu after cancelling keybind setup
                            MachoSendDuiMessage(dui, json.encode({
                                action = 'setMenuVisible',
                                visible = true
                            }))
                        end
                    else
                        -- Check if this key is bindable
                        if controlId == 18 then -- ENTER key
                            -- Control ID 18 (ENTER) is not bindable
                            _G.keybindSetupActive = false
                            keybindSetup = false
                            
                            if dui then
                                MachoSendDuiMessage(dui, json.encode({
                                    action = 'closeKeySelection'
                                }))
                                MachoSendDuiMessage(dui, json.encode({
                                    action = 'notify',
                                    message = "This key is <span class=\"notification-key\">Not Bindable</span>",
                                    type = 'warn'
                                }))
                                -- Show the menu after trying to bind ENTER
                                MachoSendDuiMessage(dui, json.encode({
                                    action = 'setMenuVisible',
                                    visible = true
                                }))
                            end
                        else
                            -- Set the keybind using injection method
                            _G.keybindSetupActive = false
                            keybindSetup = false
                            menuOpenKey = controlId
                            print("Lua: menuOpenKey updated to:", menuOpenKey)
                            print("Lua: keybindSetupActive set to false")
                            
                            -- Use the key name from the key map
                            local displayKeyName = keyName
                        
                            -- Update the keybind display in the menu
                            for i, item in ipairs(originalMenu) do
                                if item.type == 'submenu' and item.label == 'Settings' then
                                    for j, subItem in ipairs(item.submenu) do
                                        if subItem.label == 'Menu Keybind' then
                                            subItem.currentKey = displayKeyName
                                            break
                                        end
                                    end
                                    break
                                end
                            end
                            
                            -- Menu keybind set
                            print("Lua: Menu keybind successfully set to Control ID:", controlId, "Key Name:", displayKeyName)
                            if dui then
                                MachoSendDuiMessage(dui, json.encode({
                                    action = 'closeKeySelection'
                                }))
                                MachoSendDuiMessage(dui, json.encode({
                                    action = 'notify',
                                    message = "Menu keybind set to: <span class=\"notification-key\">" .. displayKeyName .. "</span>",
                                    type = 'success'
                                }))
                                -- Show the menu after setting keybind
                                MachoSendDuiMessage(dui, json.encode({
                                    action = 'setMenuVisible',
                                    visible = true
                                }))
                                -- Update the menu to show the new key
                                setCurrent()
                            end
                        end
                    end
                    break
                end
            end
            -- Wait(100) -- Small delay to prevent rapid key detection
            
        end

        if showing then
            EnableControlAction(0, 1, true) -- Mouse
            EnableControlAction(0, 2, true) -- Mouse
            DisableControlAction(0, 11, true) -- Page Down

            if isControlJustPressed(187) then -- Arrow Down
                -- Don't process navigation if text input is active
                if _G.inputRecordingActive then
                    Wait(100)
                    return
                end
                
                activeIndex = activeIndex + 1
                if activeIndex > #activeMenu then activeIndex = 1 end
                setCurrent()
                sendSelectedPlayerData()
                Wait(100)
            elseif isControlJustPressed(188) then -- Arrow Up
                -- Don't process navigation if text input is active
                if _G.inputRecordingActive then
                    Wait(100)
                    return
                end
                
                activeIndex = activeIndex - 1
                if activeIndex < 1 then activeIndex = #activeMenu end
                setCurrent()
                sendSelectedPlayerData()
                Wait(100)
            elseif IsControlPressed(0, 189) then -- Left Arrow (held)
                -- Don't process navigation if text input is active
                if _G.inputRecordingActive then
                    Wait(100)
                    return
                end
                
                local activeData = activeMenu[activeIndex]
                if activeData.type == 'scroll' then
                    -- For scroll, only change on press, not hold
                    if isControlJustPressed(189) then
                    activeData.selected = activeData.selected - 1
                    if activeData.selected < 1 then activeData.selected = #activeData.options end
                    setCurrent()
                    if activeData.onChange then
                        activeData.onChange(activeData.options[activeData.selected])
                        end
                        Wait(100)
                    end
                elseif activeData.type == 'slider' then
                    -- For slider, allow continuous change when held
                    activeData.value = math.max(activeData.min, activeData.value - (activeData.step or 1))
                    setCurrent()
                    if activeData.onChange then
                        activeData.onChange(activeData.value)
                    end
                    Wait(50) -- Faster response for sliders
                end
            elseif IsControlPressed(0, 190) then -- Right Arrow (held)
                -- Don't process navigation if text input is active
                if _G.inputRecordingActive then
                    Wait(100)
                    return
                end
                
                local activeData = activeMenu[activeIndex]
                if activeData.type == 'scroll' then
                    -- For scroll, only change on press, not hold
                    if isControlJustPressed(190) then
                    activeData.selected = activeData.selected + 1
                    if activeData.selected > #activeData.options then activeData.selected = 1 end
                    setCurrent()
                    if activeData.onChange then
                        activeData.onChange(activeData.options[activeData.selected])
                        end
                        Wait(100)
                    end
                elseif activeData.type == 'slider' then
                    -- For slider, allow continuous change when held
                    activeData.value = math.min(activeData.max, activeData.value + (activeData.step or 1))
                    setCurrent()
                    if activeData.onChange then
                        activeData.onChange(activeData.value)
                    end
                    Wait(50) -- Faster response for sliders
                end
            elseif isControlJustPressed(191) then -- Enter
                -- Don't process ENTER if text input is active
                if _G.inputRecordingActive then
                    Wait(100)
                    return
                end
                
                local activeData = activeMenu[activeIndex]
                
                if activeData.type == 'submenu' then
                    if activeData.submenu then
                        nestedMenus[#nestedMenus + 1] = { index = activeIndex, menu = activeMenu }
                        activeIndex = 1
                        activeMenu = activeData.submenu
                        -- Update breadcrumb with full path
                        if dui then
                            local breadcrumb = "Main Menu"
                            for i, nestedMenu in ipairs(nestedMenus) do
                                breadcrumb = breadcrumb .. " > " .. nestedMenu.menu[nestedMenu.index].label
                            end
                            MachoSendDuiMessage(dui, json.encode({
                                action = 'updateBreadcrumb',
                                breadcrumb = breadcrumb
                            }))
                        end
                        setCurrent()
                        sendSelectedPlayerData()
                    end
                elseif activeData.type == 'button' then
                    if activeData.onConfirm then
                        activeData.onConfirm()
                    end
                elseif activeData.type == 'checkbox' then
                    activeData.checked = not activeData.checked
                    setCurrent()
                    if activeData.onConfirm then
                        activeData.onConfirm(activeData.checked)
                    end
                elseif activeData.type == 'scroll' then
                    if activeData.onConfirm then
                        local selectedIndex = activeData.selected
                        activeData.onConfirm(activeData.options[selectedIndex])
                    end
                    setCurrent()
                elseif activeData.type == 'slider' then
                    if activeData.onConfirm then
                        activeData.onConfirm(activeData.value)
                    end
                    setCurrent()
                elseif activeData.type == 'input' then
                    if activeData.onConfirm then
                        activeData.onConfirm()
                    end
                elseif activeData.type == 'keybind' then
                    if activeData.onConfirm then
                        activeData.onConfirm()
                    end
                elseif activeData.type == 'playerlist' then
                    if activeData.onConfirm then
                        activeData.onConfirm()
                    end
                end
            elseif isControlJustPressed(75) then -- F9 keybind setup
                local activeData = activeMenu[activeIndex]
                if activeData and activeData.canBind then
                    if dui then
                        MachoSendDuiMessage(dui, json.encode({
                            action = 'openKeybindSetup',
                            featureName = activeData.bindName or activeData.label
                        }))
                    end
                end
            elseif isControlJustPressed(194) then -- Backspace
                -- Don't process BACKSPACE if text input is active
                if _G.inputRecordingActive then
                    Wait(100)
                    return
                end
                
                local lastMenu = nestedMenus[#nestedMenus]
                if lastMenu then
                    table.remove(nestedMenus)
                    activeIndex = lastMenu.index
                    activeMenu = lastMenu.menu
                    -- Update breadcrumb with full path
                    if dui then
                        local breadcrumb = "Main Menu"
                        for i, nestedMenu in ipairs(nestedMenus) do
                            breadcrumb = breadcrumb .. " > " .. nestedMenu.menu[nestedMenu.index].label
                        end
                        MachoSendDuiMessage(dui, json.encode({
                            action = 'updateBreadcrumb',
                            breadcrumb = breadcrumb
                        }))
                    end
                    setCurrent()
                    sendSelectedPlayerData()
                else
                    -- Hide menu via frontend but keep DrawSprite visible
                    if dui then
                        MachoSendDuiMessage(dui, json.encode({
                            action = 'setMenuVisible',
                            visible = false
                        }))
                        -- Clear selected player when hiding menu
                        MachoSendDuiMessage(dui, json.encode({
                            action = 'setSelectedPlayer',
                            playerData = nil
                        }))
                    end
                    _G.clientMenuShowing = false
                    currentSelectedPlayer = nil
                end
            end
        end
        Wait(0)
    end
end)


-- DUI Drawing thread - Optimized drawing with conditional updates
CreateThread(function()
    local lastPosition = { x = uiPositions.menu.x, y = uiPositions.menu.y }
    local lastScale = menuScale
    local lastOpacity = menuOpacity
    local needsRedraw = true
    
    while true do
        if duiTexture then
            -- Only redraw if something changed or menu is visible
            if needsRedraw or _G.clientMenuShowing then
                -- Calculate alpha based on opacity setting
                local alpha = math.floor(255 * menuOpacity)
                
                -- Draw the DUI texture on screen with menu position (notifications stay fixed)
                DrawSprite(txdName, txtName, uiPositions.menu.x, uiPositions.menu.y, menuScale, menuScale, 0.0, 255, 255, 255, alpha)
                
                -- Check if settings changed
                if lastPosition.x ~= uiPositions.menu.x or lastPosition.y ~= uiPositions.menu.y or 
                   lastScale ~= menuScale or lastOpacity ~= menuOpacity then
                    lastPosition.x = uiPositions.menu.x
                    lastPosition.y = uiPositions.menu.y
                    lastScale = menuScale
                    lastOpacity = menuOpacity
                else
                    needsRedraw = false
                end
            end
        end
        
        -- Reduce CPU usage when menu is not showing
        Wait(_G.clientMenuShowing and 0 or 100)
    end
end)

-- Memory cleanup and optimization thread
CreateThread(function()
    while true do
        -- Run cleanup every 30 seconds
        Wait(30000)
        
        -- Force garbage collection
        collectgarbage("collect")
        
        -- Clear any unused textures or resources
        if duiTexture and not _G.clientMenuShowing then
            -- Menu is closed, we can optimize further
            local currentTime = GetGameTimer()
            if currentTime - performanceStats.menuOpenTime > 60000 then -- 1 minute
                -- Menu has been closed for a while, reduce memory usage
                performanceStats.menuOpenTime = currentTime
            end
        end
        
        -- Log performance stats (optional)
        if performanceStats.averageFPS < 30 then
            print("Nebula Menu: Low FPS detected (" .. performanceStats.averageFPS .. "), optimizations active")
        end
    end
end)

print("NEBULA SOFTWARE MENU LOADED - OPTIMIZED")
