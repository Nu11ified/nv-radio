-- Thin wrapper for NUI communication
NUIBridge = {}

function NUIBridge.send(data)
    SendNUIMessage(data)
end

function NUIBridge.register(name, cb)
    RegisterNUICallback(name, function(data, resultCb)
        cb(data)
        resultCb('ok')
    end)
end

function NUIBridge.open(payload)
    SetNuiFocus(true, true)
    NUIBridge.send({
        type = 'open',
        payload = payload,
    })
end

function NUIBridge.close()
    SetNuiFocus(false, false)
    NUIBridge.send({ type = 'close' })
end
