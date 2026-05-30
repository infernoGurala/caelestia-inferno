#!/bin/bash

TIMER_FILE="/tmp/caelestia_super_timer_pid"

if [ -f "$TIMER_FILE" ]; then
    PID=$(cat "$TIMER_FILE")
    # Kill the pending single-tap action
    kill "$PID" 2>/dev/null
    rm -f "$TIMER_FILE"
    
    # Trigger the double-tap action (toggle taskbar)
    hyprctl dispatch global quickshell:toggle_taskbar
else
    # Start a background timer for single-tap
    (
        sleep 0.25
        # If we weren't killed, this was a single tap!
        rm -f "$TIMER_FILE"
        pkill fuzzel || fuzzel
    ) &
    echo $! > "$TIMER_FILE"
fi
