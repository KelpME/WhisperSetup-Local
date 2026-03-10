#!/bin/bash
# Whisper Uninstall Script
# Removes all Whisper-related files and configurations

set -e

BIN_DIR="$HOME/.local/bin"
MODEL_DIR="$HOME/whisper-models"
CONFIG_FILE="$HOME/.config/whisper-menu.conf"

echo "=== Whisper Uninstall ==="
echo ""

stop_services() {
    echo "[1/5] Stopping services..."
    if [ -f "$BIN_DIR/whisper-server-ctl" ]; then
        "$BIN_DIR/whisper-server-ctl" stop 2>/dev/null || true
    fi
    if [ -f "$BIN_DIR/whisper-ctl" ]; then
        "$BIN_DIR/whisper-ctl" stop 2>/dev/null || true
    fi
    rm -f /tmp/whisper-service.pid /tmp/whisper-server.pid
    rm -f /tmp/whisper-service.log /tmp/whisper-server.log
    echo "  ✓ Services stopped"
}

remove_binaries() {
    echo "[2/5] Removing binaries..."
    rm -f "$BIN_DIR/whisper-cli" "$BIN_DIR/whisper-server"
    rm -f "$BIN_DIR/whisper-ctl" "$BIN_DIR/whisper-server-ctl" "$BIN_DIR/whisper-menu"
    echo "  ✓ Binaries removed"
}

remove_models() {
    echo "[3/5] Removing models..."
    if [ -d "$MODEL_DIR" ]; then
        read -p "Remove model directory ($MODEL_DIR)? [y/N] " -n 1 -r
        echo
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            rm -rf "$MODEL_DIR"
            echo "  ✓ Models removed"
        else
            echo "  ✓ Models kept"
        fi
    else
        echo "  ✓ No model directory found"
    fi
}

remove_config() {
    echo "[4/5] Removing configuration..."
    rm -f "$CONFIG_FILE"
    echo "  ✓ Config removed"
}

remove_whisper_cpp() {
    echo "[5/5] Removing whisper.cpp source..."
    if [ -d /tmp/whisper.cpp ]; then
        read -p "Remove whisper.cpp source (/tmp/whisper.cpp)? [y/N] " -n 1 -r
        echo
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            rm -rf /tmp/whisper.cpp
            echo "  ✓ whisper.cpp source removed"
        else
            echo "  ✓ whisper.cpp source kept"
        fi
    else
        echo "  ✓ No whisper.cpp source found"
    fi
}

echo "This will remove:"
echo "  - Whisper binaries ($BIN_DIR/whisper-*)"
echo "  - Configuration ($CONFIG_FILE)"
echo ""
read -p "Continue? [y/N] " -n 1 -r
echo

if [[ $REPLY =~ ^[Yy]$ ]]; then
    stop_services
    remove_binaries
    remove_models
    remove_config
    remove_whisper_cpp
    echo ""
    echo "=== Uninstall Complete ==="
else
    echo "Cancelled."
fi
