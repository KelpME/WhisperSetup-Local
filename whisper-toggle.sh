#!/bin/bash

export LD_LIBRARY_PATH="$HOME/.local/bin/lib:$LD_LIBRARY_PATH"

PID_FILE="/tmp/whisper-server.pid"
LOG_FILE="/tmp/whisper-server.log"
MODEL_DIR="$HOME/whisper-models"
MODEL_FILE="whisper-large-v3-turbo.bin"
MODEL_PATH="$MODEL_DIR/$MODEL_FILE"
BIN_DIR="$HOME/.local/bin"
PORT=4242

get_ip() {
    ip addr show | grep "inet " | awk '{print $2}' | cut -d'/' -f1 | grep -v "127.0.0.1" | head -1
}

if [ -f "$PID_FILE" ] && kill -0 "$(cat "$PID_FILE")" 2>/dev/null; then
    if curl -sf "http://localhost:$PORT" >/dev/null 2>&1; then
        kill "$(cat "$PID_FILE")" 2>/dev/null
        rm -f "$PID_FILE"
        notify-send "Whisper" "Server stopped"
    else
        notify-send "Whisper" "Server not responding on port $PORT"
    fi
else
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
    notify-send "Whisper" "Server started on http://$(get_ip):$PORT"
fi
