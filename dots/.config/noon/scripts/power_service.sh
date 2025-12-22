#!/bin/bash
# power_service.sh <update|set> [mode]

ACTION=$1
MODE=$2
STATE_FILE="$HOME/.local/state/noon/states.json"

# Ensure state directory and file exist
mkdir -p "$(dirname "$STATE_FILE")"
if [ ! -f "$STATE_FILE" ]; then
    echo '{}' > "$STATE_FILE"
fi

get_controller() {
    if command -v powerprofilesctl >/dev/null 2>&1; then
        echo "power-profiles-daemon"
    elif command -v tlp >/dev/null 2>&1; then
        echo "tlp"
    else
        echo "none"
    fi
}

update_json() {
    local controller="$1"
    local mode="$2"
    local modes="$3"
    
    temp_file="${STATE_FILE}.tmp"
    jq --arg ctrl "$controller" \
       --arg m "$mode" \
       --argjson mds "$modes" \
       '.services.power.controller = $ctrl | 
        .services.power.mode = $m | 
        .services.power.modes = $mds' \
       "$STATE_FILE" > "$temp_file" && mv "$temp_file" "$STATE_FILE"
}

case "$ACTION" in
    update)
        CONTROLLER=$(get_controller)
        
        case "$CONTROLLER" in
            power-profiles-daemon)
                MODE=$(powerprofilesctl get 2>/dev/null || echo "balanced")
                MODES='["power-saver","balanced","performance"]'
                ;;
                
            tlp)
                MODE=$(pkexec tlp-stat -m 2>/dev/null | awk -F'/' '{print tolower($1)}')
                
                case "$MODE" in
                    performance) MODE="performance" ;;
                    powersave|power-saver) MODE="power-saver" ;;
                    balanced) MODE="balanced" ;;
                    *) MODE="balanced" ;;
                esac
                
                MODES='["power-saver","balanced","performance"]'
                ;;
                
            *)
                MODE="power-saver"
                MODES='["power-saver"]'
                ;;
        esac
        
        update_json "$CONTROLLER" "$MODE" "$MODES"
        ;;
        
    set)
        CONTROLLER=$(get_controller)
        case "$CONTROLLER" in
            tlp)
                # Single pkexec call: set mode AND get new status
                NEW_MODE=$(pkexec bash -c "tlp '$MODE' >/dev/null 2>&1 && tlp-stat -m 2>/dev/null" | awk -F'/' '{print tolower($1)}')
                
                case "$NEW_MODE" in
                    performance) NEW_MODE="performance" ;;
                    powersave|power-saver) NEW_MODE="power-saver" ;;
                    balanced) NEW_MODE="balanced" ;;
                    *) NEW_MODE="$MODE" ;;
                esac
                
                update_json "tlp" "$NEW_MODE" '["power-saver","balanced","performance"]'
                ;;
                
            power-profiles-daemon)
                powerprofilesctl set "$MODE" && \
                NEW_MODE=$(powerprofilesctl get 2>/dev/null || echo "$MODE")
                update_json "power-profiles-daemon" "$NEW_MODE" '["power-saver","balanced","performance"]'
                ;;
                
            none)
                exit 1
                ;;
        esac
        ;;
        
    status)
        "$0" update
        cat "$STATE_FILE" | jq -r '.services.power | "\(.controller)|\(.mode)|\(.modes | join(","))"'
        ;;
        
    *)
        echo "Usage: $0 <update|set|status> [mode]"
        exit 1
        ;;
esac
