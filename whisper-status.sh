#!/bin/bash

PID_FILE="/tmp/whisper-server.pid"
PORT=4242

if [ -f "$PID_FILE" ] && kill -0 "$(cat "$PID_FILE")" 2>/dev/null; then
    echo "🎙"
else
    echo "◌"
fi
