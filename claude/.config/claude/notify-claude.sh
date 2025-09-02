#!/bin/bash

# Claude Code Notification Script
# This script provides different types of notifications for Claude Code events

# Configuration
NOTIFICATION_TIME=5000  # 5 seconds
SOUND_ENABLED=true

# Function to send desktop notification
send_notification() {
    local title="$1"
    local message="$2"
    local urgency="$3"
    local icon="$4"
    
    # Use notify-send for desktop notifications
    if command -v notify-send &> /dev/null; then
        notify-send \
            --urgency="$urgency" \
            --expire-time="$NOTIFICATION_TIME" \
            --icon="$icon" \
            "$title" \
            "$message"
    fi
    
    # Terminal bell as fallback
    if [ "$SOUND_ENABLED" = true ]; then
        echo -e "\a"
    fi
    
    # Log the notification
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $title: $message" >> ~/.config/claude/notifications.log
}

# Notification types based on the event
case "$1" in
    "input_needed")
        send_notification \
            "Claude Code - Input Required" \
            "Claude is waiting for your feedback or input" \
            "normal" \
            "dialog-question"
        ;;
    "process_complete")
        send_notification \
            "Claude Code - Process Complete" \
            "${2:-Task completed successfully}" \
            "low" \
            "dialog-information"
        ;;
    "error_occurred")
        send_notification \
            "Claude Code - Error" \
            "${2:-An error occurred during execution}" \
            "critical" \
            "dialog-error"
        ;;
    "session_end")
        send_notification \
            "Claude Code - Session Ended" \
            "Claude Code session has ended" \
            "low" \
            "dialog-information"
        ;;
    "tool_complete")
        send_notification \
            "Claude Code - Tool Complete" \
            "${2:-Tool execution finished}" \
            "low" \
            "dialog-information"
        ;;
    "long_running")
        send_notification \
            "Claude Code - Long Running Task" \
            "${2:-Task is taking longer than expected}" \
            "normal" \
            "dialog-warning"
        ;;
    *)
        send_notification \
            "Claude Code - Notification" \
            "${2:-General notification from Claude Code}" \
            "normal" \
            "dialog-information"
        ;;
esac