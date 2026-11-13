#!/usr/bin/env bash
set -euo pipefail

# Directory containing this script
BASE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

BIN="$BASE_DIR/cliproxyapi"
CONFIG="$BASE_DIR/config.yaml"
LOG_DIR="$BASE_DIR/logs"
LOG_FILE="$LOG_DIR/cliproxyapi.log"
PID_FILE="$BASE_DIR/cliproxyapi.pid"

start() {
    if [[ -f "$PID_FILE" ]]; then
        pid=$(cat "$PID_FILE")
        if kill -0 "$pid" 2>/dev/null; then
            echo "CLIProxyAPI is already running (PID: $pid)"
            return
        fi
        rm -f "$PID_FILE"
    fi

    [[ -x "$BIN" ]] || { echo "Executable not found: $BIN"; exit 1; }
    [[ -f "$CONFIG" ]] || { echo "Config not found: $CONFIG"; exit 1; }

    mkdir -p "$LOG_DIR"

    cd "$BASE_DIR"
    nohup "$BIN" --config "$CONFIG" >> "$LOG_FILE" 2>&1 < /dev/null &
    pid=$!
    echo "$pid" > "$PID_FILE"

    sleep 1
    if kill -0 "$pid" 2>/dev/null; then
        echo "CLIProxyAPI started (PID: $pid)"
        echo "Log: $LOG_FILE"
    else
        rm -f "$PID_FILE"
        echo "CLIProxyAPI failed to start. Check: $LOG_FILE"
        exit 1
    fi
}

stop() {
    if [[ ! -f "$PID_FILE" ]]; then
        echo "CLIProxyAPI is not running (PID file missing)"
        return
    fi

    pid=$(cat "$PID_FILE")
    if kill -0 "$pid" 2>/dev/null; then
        kill "$pid"
        echo "Stopping CLIProxyAPI (PID: $pid)"
    else
        echo "CLIProxyAPI process not found"
    fi

    rm -f "$PID_FILE"
}

status() {
    if [[ -f "$PID_FILE" ]]; then
        pid=$(cat "$PID_FILE")
        if kill -0 "$pid" 2>/dev/null; then
            echo "CLIProxyAPI is running (PID: $pid)"
            return
        fi
    fi
    echo "CLIProxyAPI is not running"
}

case "${1:-start}" in
    start)
        start
        ;;
    stop)
        stop
        ;;
    restart)
        stop
        sleep 1
        start
        ;;
    status)
        status
        ;;
    logs)
        touch "$LOG_FILE"
        tail -n 100 -f "$LOG_FILE"
        ;;
    *)
        echo "Usage: $0 {start|stop|restart|status|logs}"
        exit 1
        ;;
esac
