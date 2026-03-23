local connectedPlayers = {}

-- Track player connections
AddEventHandler('playerConnecting', function(name, setKickReason, deferrals)
    local _source = source
    connectedPlayers[_source] = {
        name = name,
        source = _source,
    }
end)

AddEventHandler('playerDropped', function(reason)
    local _source = source
    connectedPlayers[_source] = nil
end)

-- Auto-join default radio channel when player is ready
RegisterNetEvent('nv-radio:playerReady')
AddEventHandler('nv-radio:playerReady', function()
    local _source = source
    local name = GetPlayerName(_source) or 'Unknown'
    connectedPlayers[_source] = {
        name = name,
        source = _source,
    }

    -- Add to default channel via nv-voice
    exports['nv-voice']:addPlayerRadioChannel(_source, Config.DefaultChannel)
end)

-- Staff: get player list
RegisterNetEvent('nv-radio:requestPlayerList')
AddEventHandler('nv-radio:requestPlayerList', function()
    local _source = source
    if not IsPlayerAceAllowed(_source, Config.StaffPermission) then
        return
    end

    local players = {}
    for src, data in pairs(connectedPlayers) do
        local proxState = Player(src).state.proximity
        local radioChannels = exports['nv-voice']:getPlayerRadioChannels(src)
        local mutedState = Player(src).state.muted or false
        players[#players + 1] = {
            source = src,
            name = data.name or GetPlayerName(src) or 'Unknown',
            proximity = proxState and proxState.distance or 15.0,
            proximityMode = proxState and proxState.mode or 'Normal',
            radioChannels = radioChannels or {},
            muted = mutedState,
        }
    end

    TriggerClientEvent('nv-radio:receivePlayerList', _source, players)
end)

-- Staff: move player to channel
RegisterNetEvent('nv-radio:staff:movePlayer')
AddEventHandler('nv-radio:staff:movePlayer', function(targetSource, channel)
    local _source = source
    targetSource = tonumber(targetSource)
    channel = tonumber(channel)
    if not targetSource or not channel or channel < 1 then return end

    if not IsPlayerAceAllowed(_source, Config.StaffPermission) then
        print(('[nv-radio] ^1Unauthorized staff action by %s^0'):format(_source))
        return
    end

    if not connectedPlayers[targetSource] then return end

    -- Set player to the new channel (replaces current)
    exports['nv-voice']:setPlayerRadio(targetSource, channel)

    -- Notify the staff member
    TriggerClientEvent('nv-radio:staffActionResult', _source, {
        action = 'move',
        target = targetSource,
        channel = channel,
        success = true,
    })
end)

-- Staff: set player proximity
RegisterNetEvent('nv-radio:staff:setProximity')
AddEventHandler('nv-radio:staff:setProximity', function(targetSource, distance)
    local _source = source
    targetSource = tonumber(targetSource)
    distance = tonumber(distance)
    if not targetSource or not distance or distance <= 0 then return end

    if not IsPlayerAceAllowed(_source, Config.StaffPermission) then
        print(('[nv-radio] ^1Unauthorized staff action by %s^0'):format(_source))
        return
    end

    if not connectedPlayers[targetSource] then return end

    -- Tell the target client to update their proximity
    TriggerClientEvent('nv-radio:setProximity', targetSource, distance)

    TriggerClientEvent('nv-radio:staffActionResult', _source, {
        action = 'proximity',
        target = targetSource,
        distance = distance,
        success = true,
    })
end)

-- Staff: mute/unmute player (server-side via Mumble native — cannot be bypassed)
RegisterNetEvent('nv-radio:staff:mutePlayer')
AddEventHandler('nv-radio:staff:mutePlayer', function(targetSource, shouldMute)
    local _source = source
    targetSource = tonumber(targetSource)
    if not targetSource then return end

    if not IsPlayerAceAllowed(_source, Config.StaffPermission) then
        print(('[nv-radio] ^1Unauthorized staff action by %s^0'):format(_source))
        return
    end

    if not connectedPlayers[targetSource] then return end

    -- Use nv-voice server export — calls MumbleSetPlayerMuted (server-side, unforgeable)
    exports['nv-voice']:setPlayerMuted(targetSource, shouldMute)

    -- Notify staff
    TriggerClientEvent('nv-radio:staffActionResult', _source, {
        action = shouldMute and 'mute' or 'unmute',
        target = targetSource,
        muted = shouldMute,
        success = true,
    })
end)

-- Check if player is staff (called from client)
RegisterNetEvent('nv-radio:checkStaff')
AddEventHandler('nv-radio:checkStaff', function()
    local _source = source
    local isStaff = IsPlayerAceAllowed(_source, Config.StaffPermission)
    TriggerClientEvent('nv-radio:staffStatus', _source, isStaff)
end)
