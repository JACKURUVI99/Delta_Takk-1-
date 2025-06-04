#!/bin/bash
# File: ncNotify.sh

# Ensure script is run by appropriate user or root
case "$1" in
    notify)
        if [ "$(id -u)" != "0" ] && ! groups | grep -q g_author; then
            echo "Only authors or root can send notifications" >&2
            exit 1
        fi
        ;;
    check)
        if [ "$(id -u)" != "0" ]; then
            echo "Check can only be run by root (via cron)" >&2
            exit 1
        fi
        ;;
    *)
        echo "Usage: $0 {notify <filename>|check}" >&2
        exit 1
        ;;
esac

USERNAME=$(whoami)
NOTIFY_PORT=12345

# Function to send notification
send_notification() {
    local author="$1"
    local filename="$2"
    local message="New article published by $author: $filename"
    subscribers=($(yq e ".subscriptions[] | select(.author == \"$author\").user" "/home/admin/subscriptions.yaml"))

    for user in "${subscribers[@]}"; do
        user_dir="/home/users/$user"
        if [ -d "$user_dir" ]; then
            echo "$message" >> "$user_dir/notifications.log"
            if who | grep -q "$user"; then
                echo "$message" | nc -w 1 localhost $NOTIFY_PORT 2>/dev/null
            fi
        fi
    done
}

# Function to check notifications
check_notifications() {
    for user_dir in /home/users/*; do
        if [ -d "$user_dir" ]; then
            user=$(basename "$user_dir")
            notify_file="$user_dir/notifications.log"
            if [ -f "$notify_file" ]; then
                if who | grep -q "$user"; then
                    unread=$(awk '/new_notifications/{p=1;next}p' "$notify_file" | wc -l)
                    if [ $unread -gt 0 ]; then
                        echo "You have $unread new notifications"
                        awk '/new_notifications/{p=1;next}p' "$notify_file"
                    fi
                    echo "new_notifications" >> "$notify_file"
                fi
            else
                echo "new_notifications" > "$notify_file"
                chown "$user:g_user" "$notify_file"
                chmod 600 "$notify_file"
            fi
        fi
    done
}

# Main execution
case "$1" in
    notify)
        send_notification "$USERNAME" "$2"
        ;;
    check)
        check_notifications
        ;;
    *)
        echo "Usage: $0 {notify <filename>|check}" >&2
        exit 1
        ;;
esac
