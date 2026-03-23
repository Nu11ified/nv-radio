local isUIOpen = false
local isStaff = false
local currentProxMode = Config.DefaultProximityMode

-- Wait for player to be fully loaded, then notify server
CreateThread(function()
    while not NetworkIsPlayerActive(PlayerId()) do
        Wait(500)
    end

    -- Tell server we're ready (triggers auto-join to default channel)
    TriggerServerEvent('nv-radio:playerReady')

    -- Check if we're staff
    TriggerServerEvent('nv-radio:checkStaff')
end)

-- Receive staff status from server
RegisterNetEvent('nv-radio:staffStatus')
AddEventHandler('nv-radio:staffStatus', function(staff)
    isStaff = staff
end)

-- Open the radio UI
function openRadioUI()
    if isUIOpen then
        closeRadioUI()
        return
    end

    isUIOpen = true

    -- Get current proximity state
    local proxState = LocalPlayer.state.proximity
    local currentDistance = proxState and proxState.distance or Config.ProximityModes[Config.DefaultProximityMode].distance
    local currentModeName = proxState and proxState.mode or Config.ProximityModes[Config.DefaultProximityMode].name

    NUIBridge.open({
        isStaff = isStaff,
        proximityModes = Config.ProximityModes,
        currentProximity = {
            distance = currentDistance,
            mode = currentModeName,
        },
        defaultChannel = Config.DefaultChannel,
    })

    -- If staff, also request player list
    if isStaff then
        TriggerServerEvent('nv-radio:requestPlayerList')
    end
end

function closeRadioUI()
    isUIOpen = false
    NUIBridge.close()
end

-- Register command and keybind
RegisterCommand(Config.OpenCommand, function()
    openRadioUI()
end, false)

RegisterKeyMapping(Config.OpenCommand, 'Open Radio Panel', 'keyboard', Config.OpenKey)

-- NUI Callbacks

-- Close UI
NUIBridge.register('close', function(data)
    closeRadioUI()
end)

-- Player: set own proximity
NUIBridge.register('setProximity', function(data)
    local distance = tonumber(data.distance)
    if not distance then return end

    -- Find matching mode name
    local modeName = 'Custom'
    for i = 1, #Config.ProximityModes do
        if Config.ProximityModes[i].distance == distance then
            modeName = Config.ProximityModes[i].name
            currentProxMode = i
            break
        end
    end

    MumbleSetAudioInputDistance(distance)
    MumbleSetAudioOutputDistance(distance)

    LocalPlayer.state:set('proximity', {
        index = currentProxMode,
        distance = distance,
        mode = modeName,
    }, true)

    TriggerEvent('nv-voice:proximityChanged', currentProxMode, distance)
end)

-- Staff: move player to channel
NUIBridge.register('staffMovePlayer', function(data)
    if not isStaff then return end
    local targetSource = tonumber(data.targetSource)
    local channel = tonumber(data.channel)
    if targetSource and channel then
        TriggerServerEvent('nv-radio:staff:movePlayer', targetSource, channel)
    end
end)

-- Staff: set player proximity
NUIBridge.register('staffSetProximity', function(data)
    if not isStaff then return end
    local targetSource = tonumber(data.targetSource)
    local distance = tonumber(data.distance)
    if targetSource and distance then
        TriggerServerEvent('nv-radio:staff:setProximity', targetSource, distance)
    end
end)

-- Staff: mute player
NUIBridge.register('staffMutePlayer', function(data)
    if not isStaff then return end
    local targetSource = tonumber(data.targetSource)
    local shouldMute = data.mute and true or false
    if targetSource then
        TriggerServerEvent('nv-radio:staff:mutePlayer', targetSource, shouldMute)
    end
end)

-- Staff: refresh player list
NUIBridge.register('refreshPlayerList', function(data)
    if not isStaff then return end
    TriggerServerEvent('nv-radio:requestPlayerList')
end)

-- Receive player list from server (staff only)
RegisterNetEvent('nv-radio:receivePlayerList')
AddEventHandler('nv-radio:receivePlayerList', function(players)
    NUIBridge.send({
        type = 'playerList',
        players = players,
    })
end)

-- Receive staff action results
RegisterNetEvent('nv-radio:staffActionResult')
AddEventHandler('nv-radio:staffActionResult', function(result)
    NUIBridge.send({
        type = 'actionResult',
        result = result,
    })
    -- Refresh player list after action
    TriggerServerEvent('nv-radio:requestPlayerList')
end)

-- Server forced proximity change (staff set our prox)
RegisterNetEvent('nv-radio:setProximity')
AddEventHandler('nv-radio:setProximity', function(distance)
    MumbleSetAudioInputDistance(distance)
    MumbleSetAudioOutputDistance(distance)

    local modeName = 'Custom'
    for i = 1, #Config.ProximityModes do
        if Config.ProximityModes[i].distance == distance then
            modeName = Config.ProximityModes[i].name
            currentProxMode = i
            break
        end
    end

    LocalPlayer.state:set('proximity', {
        index = currentProxMode,
        distance = distance,
        mode = modeName,
    }, true)

    TriggerEvent('nv-voice:proximityChanged', currentProxMode, distance)
end)

-- Note: Staff muting is handled entirely server-side via
-- exports['nv-voice']:setPlayerMuted() which calls MumbleSetPlayerMuted.
-- No client-side mute event needed — the server-side native is authoritative.
