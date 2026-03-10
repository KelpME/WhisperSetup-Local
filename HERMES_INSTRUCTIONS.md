# Hermes Whisper Skill Instructions

## Overview
This skill provides Whisper speech-to-text functionality for Hermes AI. It uses whisper.cpp to run locally with a network server for remote access.

## Prerequisites
- whisper.cpp binaries installed at `~/.local/bin/whisper-cli` and `~/.local/bin/whisper-server`
- Whisper model at `~/whisper-models/whisper-large-v3-turbo.bin`
- Control scripts: `whisper-ctl`, `whisper-server-ctl`, `whisper-menu`

## Quick Reference

### Start Whisper Server
```bash
~/.local/bin/whisper-server-ctl start
```
Server runs on port **4242**

### Stop Whisper Server
```bash
~/.local/bin/whisper-server-ctl stop
```

### Check Server Status
```bash
~/.local/bin/whisper-server-ctl status
```

### Transcribe Local Audio File
```bash
~/.local/bin/whisper-ctl transcribe /path/to/audio.mp3
```
Supported formats: mp3, wav, flac, ogg, m4a

### Open Whisper Menu
```bash
~/.local/bin/whisper-menu
```
Or click the 🎙 icon in the waybar

## Network Usage

### From Another Computer on Network
```bash
# Get the server IP first: ~/.local/bin/whisper-server-ctl status

# Transcribe a file
curl -X POST -F "audio_file=@audio.mp3" http://<SERVER_IP>:4242/inference

# Or open in browser for web interface
http://<SERVER_IP>:4242
```

### Python API Example
```python
import requests

# Transcribe file
with open("audio.mp3", "rb") as f:
    response = requests.post(
        "http://<SERVER_IP>:4242/inference",
        files={"audio_file": f}
    )
    print(response.json())
```

## Common Tasks for Hermes

### 1. Starting the Server
When user wants to use Whisper from another device:
1. Check if server is running: `~/.local/bin/whisper-server-ctl status`
2. If not running, start it: `~/.local/bin/whisper-server-ctl start`
3. Provide the IP address: `http://<SERVER_IP>:4242`

### 2. Transcribing Audio
When user wants to transcribe a file:
1. Ask for the audio file path
2. Run: `~/.local/bin/whisper-ctl transcribe <file_path>`
3. Display the transcription output

### 3. Troubleshooting

**Server won't start:**
- Check if model exists: `ls ~/whisper-models/`
- Check server log: `tail /tmp/whisper-server.log`

**Port already in use:**
- Check what's using the port: `lsof -i :4242`
- Stop existing server: `~/.local/bin/whisper-server-ctl stop`

**Model not found:**
- Re-run setup or download manually:
  ```bash
  cd ~/whisper-models
  curl -L -o whisper-large-v3-turbo.bin https://huggingface.co/ggerganov/whisper.cpp/resolve/main/ggml-large-v3-turbo.bin
  ```

## File Locations
| File | Path |
|------|------|
| Setup Script | `~/Work/WhisperSetup/setup-whisper.sh` |
| Control Script | `~/.local/bin/whisper-ctl` |
| Server Control | `~/.local/bin/whisper-server-ctl` |
| Menu Script | `~/.local/bin/whisper-menu` |
| Model | `~/whisper-models/whisper-large-v3-turbo.bin` |
| Server Log | `/tmp/whisper-server.log` |
| Service Log | `/tmp/whisper-service.log` |

## Re-run Setup
To re-run the full setup (installs binaries, downloads model, configures waybar):
```bash
~/Work/WhisperSetup/setup-whisper.sh
```
