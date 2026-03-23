# Whisper Setup

## Quick Start

Run the setup script:
```bash
~/Work/WhisperSetup/setup-whisper.sh
```

## Waybar Integration

After setup, add this to your waybar config:
```json
"custom/whisper": {
    "format": "{}",
    "exec": "$HOME/.local/bin/whisper-status.sh",
    "exec-if": "true",
    "on-click": "$HOME/.local/bin/whisper-toggle.sh",
    "return-type": "json"
}
```

Click the whisper icon in waybar to toggle the server on/off.

## Manual Commands

```bash
~/.local/bin/whisper-server-ctl start   # Start server
~/.local/bin/whisper-server-ctl stop     # Stop server
~/.local/bin/whisper-server-ctl status   # Check status
```

## Network Access

Once running, access from other computers:
```bash
curl -X POST -F "audio_file=@audio.mp3" http://<SERVER_IP>:4242/inference
```

Server runs on port 4242.
