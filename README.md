# Whisper Setup

## Quick Start

Run the setup script:
```bash
~/Work/WhisperSetup/setup-whisper.sh
```

## Commands

### Server (port 4242)
```bash
~/.local/bin/whisper-server-ctl start   # Start server
~/.local/bin/whisper-server-ctl stop    # Stop server
~/.local/bin/whisper-server-ctl status  # Check status
```

### Local Transcription
```bash
~/.local/bin/whisper-ctl transcribe /path/to/audio.mp3
```

### Menu
```bash
~/.local/bin/whisper-menu
```

## Network Access

Once the server is running, access from other computers:
```bash
# Get the server IP: ~/.local/bin/whisper-server-ctl status

# Transcribe a file
curl -X POST -F "audio_file=@audio.mp3" http://<SERVER_IP>:4242/inference

# Or use the web interface
# Open http://<SERVER_IP>:4242 in a browser
```

## Model Location
- Model: `~/whisper-models/whisper-large-v3-turbo.bin`
- Downloaded from: https://huggingface.co/ggerganov/whisper.cpp/resolve/main/ggml-large-v3-turbo.bin
