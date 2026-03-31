#!/bin/bash
# Whisper Setup Script
# This script automates the installation and configuration of Whisper for local/network use

set -e

WORK_DIR="$HOME/Work/WhisperSetup"
MODEL_DIR="$HOME/whisper-models"
BIN_DIR="$HOME/.local/bin"
PORT=4242

get_ip() {
    ip addr show | grep "inet " | awk '{print $2}' | cut -d'/' -f1 | grep -v "127.0.0.1" | head -1
}

echo "=== Whisper Setup Script ==="
echo "Working directory: $WORK_DIR"
echo "Server port: $PORT"
echo ""

# Create directories
mkdir -p "$WORK_DIR" "$MODEL_DIR" "$BIN_DIR"

# Step 1: Install whisper.cpp if not present
if [ ! -f "$BIN_DIR/whisper-cli" ]; then
    echo "[1/6] Installing whisper.cpp..."
    cd /tmp
    rm -rf whisper.cpp
    git clone https://github.com/ggerganov/whisper.cpp.git
    cd whisper.cpp
    cmake -B build -DBUILD_SHARED_LIBS=ON
    cmake --build build --config Release -j$(nproc)
    mkdir -p "$BIN_DIR/lib"
    cp build/src/*.so* "$BIN_DIR/lib/" 2>/dev/null || true
    cp build/ggml/src/*.so* "$BIN_DIR/lib/" 2>/dev/null || true
    cp build/bin/whisper-cli "$BIN_DIR/"
    cp build/bin/whisper-server "$BIN_DIR/"
    chmod +x "$BIN_DIR/whisper-cli" "$BIN_DIR/whisper-server"
    echo "  ✓ whisper.cpp installed"
else
    echo "[1/6] whisper.cpp already installed"
fi

# Step 2: Download model if not present
MODEL_FILE="$MODEL_DIR/whisper-large-v3-turbo.bin"
if [ ! -f "$MODEL_FILE" ]; then
    echo "[2/6] Downloading Whisper large-v3-turbo model..."
    cd "$MODEL_DIR"
    curl -L -o "$MODEL_FILE" https://huggingface.co/ggerganov/whisper.cpp/resolve/main/ggml-large-v3-turbo.bin
    echo "  ✓ Model downloaded"
else
    echo "[2/6] Model already present"
fi

# Step 3: Create whisper-status.sh and whisper-toggle.sh for waybar
echo "[3/7] Creating waybar control scripts..."
cp "$WORK_DIR/whisper-status.sh" "$BIN_DIR/"
cp "$WORK_DIR/whisper-toggle.sh" "$BIN_DIR/"
chmod +x "$BIN_DIR/whisper-status.sh" "$BIN_DIR/whisper-toggle.sh"
echo "  ✓ waybar scripts created"

# Step 4: Create whisper-ctl script
echo "[4/7] Creating whisper-ctl script..."
cat > "$BIN_DIR/whisper-ctl" << 'SCRIPT_EOF'
#!/bin/bash

PID_FILE="/tmp/whisper-service.pid"
LOG_FILE="/tmp/whisper-service.log"
MODEL_PATH="$HOME/whisper-models/whisper-large-v3-turbo.bin"

case "$1" in
    status)
        if [ -f "$PID_FILE" ] && kill -0 "$(cat "$PID_FILE")" 2>/dev/null; then
            echo "running"
        else
            echo "stopped"
        fi
        ;;
    start)
        if [ -f "$PID_FILE" ] && kill -0 "$(cat "$PID_FILE")" 2>/dev/null; then
            echo "Already running"
            exit 0
        fi
        nohup bash -c "while true; do sleep 2; done" > "$LOG_FILE" 2>&1 &
        echo $! > "$PID_FILE"
        echo "Started"
        ;;
    stop)
        if [ -f "$PID_FILE" ]; then
            kill "$(cat "$PID_FILE")" 2>/dev/null
            rm -f "$PID_FILE"
            echo "Stopped"
        else
            echo "Not running"
        fi
        ;;
    toggle)
        if [ -f "$PID_FILE" ] && kill -0 "$(cat "$PID_FILE")" 2>/dev/null; then
            "$0" stop
        else
            "$0" start
        fi
        ;;
    transcribe)
        shift
        if [ -z "$1" ]; then
            echo "Usage: $0 transcribe <audio_file>"
            exit 1
        fi
        whisper-cli -m "$MODEL_PATH" -f "$1" --fp16 2>&1 | tee -a "$LOG_FILE"
        ;;
    *)
        echo "Usage: $0 {status|start|stop|toggle|transcribe <file>}"
        exit 1
        ;;
esac
SCRIPT_EOF
chmod +x "$BIN_DIR/whisper-ctl"
echo "  ✓ whisper-ctl created"

# Step 4: Create whisper-server-ctl script
echo "[4/7] Creating whisper-server-ctl script..."
cat > "$BIN_DIR/whisper-server-ctl" << 'SERVER_EOF'
#!/bin/bash

PID_FILE="/tmp/whisper-server.pid"
LOG_FILE="/tmp/whisper-server.log"
MODEL_DIR="${MODEL_DIR:-$HOME/whisper-models}"
MODEL_FILE="${MODEL_FILE:-whisper-large-v3-turbo.bin}"
MODEL_PATH="$MODEL_DIR/$MODEL_FILE"
PORT="${PORT:-4242}"

get_ip() {
    ip addr show | grep "inet " | awk '{print $2}' | cut -d'/' -f1 | grep -v "127.0.0.1" | head -1
}

case "$1" in
    start)
        if [ -f "$PID_FILE" ] && kill -0 "$(cat "$PID_FILE")" 2>/dev/null; then
            echo "Already running on http://$(get_ip):$PORT"
            exit 0
        fi
        nohup "$BIN_DIR/whisper-server" \
            -m "$MODEL_PATH" \
            --host 0.0.0.0 \
            --port $PORT \
            --max-context -1 \
            --max-len 0 \
            --no-fallback \
            -l auto \
            > "$LOG_FILE" 2>&1 &
        echo $! > "$PID_FILE"
        sleep 2
        echo "Started on http://$(get_ip):$PORT"
        ;;
    stop)
        if [ -f "$PID_FILE" ]; then
            kill "$(cat "$PID_FILE")" 2>/dev/null
            rm -f "$PID_FILE"
            echo "Stopped"
        else
            echo "Not running"
        fi
        ;;
    status)
        if [ -f "$PID_FILE" ] && kill -0 "$(cat "$PID_FILE")" 2>/dev/null; then
            echo "Running on http://$(get_ip):$PORT"
        else
            echo "Stopped"
        fi
        ;;
    *)
        echo "Usage: $0 {start|stop|status}"
        exit 1
        ;;
esac
SERVER_EOF
chmod +x "$BIN_DIR/whisper-server-ctl"
echo "  ✓ whisper-server-ctl created"

# Step 5: Create whisper-menu script
echo "[5/7] Creating whisper-menu script..."
cat > "$BIN_DIR/whisper-menu" << 'MENU_EOF'
#!/bin/bash

CONFIG_FILE="$HOME/.config/whisper-menu.conf"

load_config() {
    if [ -f "$CONFIG_FILE" ]; then
        source "$CONFIG_FILE"
    else
        PORT=4242
        MODEL_DIR="$HOME/whisper-models"
        MODEL_FILE="whisper-large-v3-turbo.bin"
    fi
    MODEL_PATH="$MODEL_DIR/$MODEL_FILE"
}

save_config() {
    mkdir -p "$(dirname "$CONFIG_FILE")"
    cat > "$CONFIG_FILE" << CONFIG_EOF
PORT=$PORT
MODEL_DIR=$MODEL_DIR
MODEL_FILE=$MODEL_FILE
CONFIG_EOF
}

get_status() {
    if [ -f "/tmp/whisper-service.pid" ] && kill -0 "$(cat /tmp/whisper-service.pid)" 2>/dev/null; then
        echo "Service: Running"
    else
        echo "Service: Stopped"
    fi
}

get_server_status() {
    if [ -f "/tmp/whisper-server.pid" ] && kill -0 "$(cat /tmp/whisper-server.pid)" 2>/dev/null; then
        echo "Server: Running on port $PORT"
    else
        echo "Server: Stopped"
    fi
}

show_settings() {
    load_config
    
    CHOICE=$(echo -e "Change Port\nChange Model Directory\nChange Model File\nBack" | wofi --dmenu --prompt "Settings" --width 300)
    
    case "$CHOICE" in
        "Change Port")
            NEW_PORT=$(echo "$PORT" | wofi --dmenu --prompt "Enter port number" --width 200)
            if [ -n "$NEW_PORT" ]; then
                PORT="$NEW_PORT"
                save_config
                notify-send "Whisper" "Port changed to $PORT. Restart server to apply."
            fi
            ;;
        "Change Model Directory")
            NEW_DIR=$(echo "$MODEL_DIR" | wofi --dmenu --prompt "Enter model directory path" --width 400)
            if [ -n "$NEW_DIR" ]; then
                MODEL_DIR="$NEW_DIR"
                save_config
                notify-send "Whisper" "Model directory changed. Select a new model file."
                show_settings
            fi
            ;;
        "Change Model File")
            load_config
            if [ -d "$MODEL_DIR" ]; then
                MODEL_CHOICE=$(ls "$MODEL_DIR"/*.bin 2>/dev/null | xargs -n1 basename | wofi --dmenu --prompt "Select model" --width 400)
                if [ -n "$MODEL_CHOICE" ]; then
                    MODEL_FILE="$MODEL_CHOICE"
                    save_config
                    notify-send "Whisper" "Model changed to $MODEL_FILE. Restart server to apply."
                fi
            else
                notify-send "Whisper" "Model directory does not exist: $MODEL_DIR"
            fi
            ;;
    esac
}

show_menu() {
    load_config
    SVC_STATUS=$(get_status)
    SRV_STATUS=$(get_server_status)
    
    CHOICE=$(echo -e "Start Service\nStop Service\n---\nStart Server\nStop Server\nServer Status\n---\nTranscribe File\nView Log\n---\nSettings\nExit" | wofi --dmenu --prompt "Whisper" --width 300)

    case "$CHOICE" in
        "Start Service")
            "$HOME/.local/bin/whisper-ctl" start
            notify-send "Whisper" "Service started"
            ;;
        "Stop Service")
            "$HOME/.local/bin/whisper-ctl" stop
            notify-send "Whisper" "Service stopped"
            ;;
        "Start Server")
            load_config
            MODEL_DIR="$MODEL_DIR" MODEL_FILE="$MODEL_FILE" PORT="$PORT" "$HOME/.local/bin/whisper-server-ctl" start
            notify-send "Whisper" "Server started on port $PORT"
            ;;
        "Stop Server")
            "$HOME/.local/bin/whisper-server-ctl" stop
            notify-send "Whisper" "Server stopped"
            ;;
        "Server Status")
            STATUS=$("$HOME/.local/bin/whisper-server-ctl" status)
            notify-send "Whisper Server" "$STATUS"
            ;;
        "Transcribe File")
            FILE=$(wofi --dmenu --prompt "Select audio file" --file-filter "*.mp3 *.wav *.flac *.ogg *.m4a" --file-selector)
            if [ -n "$FILE" ]; then
                notify-send "Whisper" "Transcribing: $FILE"
                "$HOME/.local/bin/whisper-ctl" transcribe "$FILE"
                notify-send "Whisper" "Transcription complete"
            fi
            ;;
        "View Log")
            xdg-terminal-exec -e "tail -f /tmp/whisper-service.log"
            ;;
        "Settings")
            show_settings
            ;;
    esac
}

show_menu
MENU_EOF
chmod +x "$BIN_DIR/whisper-menu"
echo "  ✓ whisper-menu created"

# Step 6: Verify waybar config
echo "[6/7] Configuring waybar..."
CONFIG_FILE="$HOME/.config/waybar/config.jsonc"

# Check if whisper is in the tray group
if grep -q '"custom/whisper"' "$CONFIG_FILE"; then
    echo "  ✓ Waybar already configured"
else
    echo "  ! Waybar needs manual configuration"
fi

# Step 7: Add waybar config if not present
echo "[7/7] Adding waybar custom module..."
WAYBAR_MODULE='"custom/whisper": {
    "format": "{}",
    "spacing": 0,
    "return-type": "json",
    "exec": "$HOME/.local/bin/whisper-status.sh",
    "interval": 5,
    "on-click": "$HOME/.local/bin/whisper-toggle.sh"
}'

if [ -f "$CONFIG_FILE" ]; then
    if ! grep -q 'custom/whisper' "$CONFIG_FILE"; then
        echo "$WAYBAR_MODULE," >> "$CONFIG_FILE"
        echo "  ✓ Added whisper custom module to waybar"
    fi
fi

echo ""
echo "=== Setup Complete ==="
echo ""
echo "Usage:"
echo "  ~/.local/bin/whisper-status.sh           # Waybar status script"
echo "  ~/.local/bin/whisper-toggle.sh           # Waybar toggle script (click to toggle)"
echo "  ~/.local/bin/whisper-server-ctl start    # Start server manually"
echo "  ~/.local/bin/whisper-server-ctl stop     # Stop server manually"

if command -v omarchy-restart-waybar &>/dev/null; then
    echo ""
    echo "Restarting waybar..."
    omarchy-restart-waybar
fi
