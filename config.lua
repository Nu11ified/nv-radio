Config = {}

-- The default radio channel all players auto-join
Config.DefaultChannel = 1

-- Ace permission required for staff actions
Config.StaffPermission = 'nv-radio.staff'

-- Keybind to open the radio UI
Config.OpenKey = 'F7'

-- Command to open the radio UI
Config.OpenCommand = 'radio'

-- Proximity distance presets (name + distance in game units)
-- These are the options shown in the player UI
Config.ProximityModes = {
    { name = 'Whisper', distance = 5.0 },
    { name = 'Normal', distance = 15.0 },
    { name = 'Shout', distance = 30.0 },
}

-- Default proximity mode index (1-based)
Config.DefaultProximityMode = 2
