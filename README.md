# nv-radio

Radio and proximity voice management UI for FiveM. Depends on [nv-voice](https://github.com/Nu11ified/nv-repo).

## Features

### All Players
- Auto-joins a default radio channel on connect
- Proximity distance picker (Whisper / Normal / Shout)
- Open with F7 keybind or /radio command

### Staff (ace permission `nv-radio.staff`)
- View all connected players with their current proximity and channel
- Move any player to a different radio channel
- Set any player's proximity distance
- Mute/unmute any player (server-side, cannot be bypassed)

## Installation

1. Place nv-radio in your server's resources/ directory
2. Ensure nv-voice is installed and running
3. Add to server.cfg:
```cfg
ensure nv-voice
ensure nv-radio
```
4. Grant staff permissions:
```cfg
add_ace group.admin nv-radio.staff allow
```

## Configuration

| Setting | Default | Description |
|---------|---------|-------------|
| Config.DefaultChannel | 1 | Radio channel all players auto-join |
| Config.StaffPermission | nv-radio.staff | Ace permission for staff actions |
| Config.OpenKey | F7 | Keybind to open the UI |
| Config.OpenCommand | radio | Chat command to open the UI |
| Config.ProximityModes | Whisper/Normal/Shout | Available proximity presets |
| Config.DefaultProximityMode | 2 (Normal) | Default proximity on spawn |

All config values are located in `config.lua`.

## Dependencies

**nv-voice** — handles all audio routing (proximity, radio channels, muting)

## How It Works

nv-radio does not handle any audio directly. It is a management UI that calls nv-voice exports:

- **Proximity:** MumbleSetAudioInputDistance / MumbleSetAudioOutputDistance
- **Radio channels:** exports['nv-voice']:setPlayerRadio()
- **Muting:** exports['nv-voice']:setPlayerMuted() (server-side MumbleSetPlayerMuted)

All staff actions are validated server-side using FiveM ace permissions.
