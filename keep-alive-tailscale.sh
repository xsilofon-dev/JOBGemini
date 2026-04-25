#!/bin/bash
# Скрипт для підтримки життя Tailscale в Cloud Shell

BIN_DIR="$HOME/bin"
STATE_FILE="$HOME/.tailscale/tailscaled.state"
SOCKET="/var/run/tailscale/tailscaled.sock"
LOG=/tmp/tailscaled_keepalive.log

echo "Keep-alive loop started at $(date)" >> $LOG

while true; do
    if ! pgrep -f "tailscaled" > /dev/null; then
        echo "$(date): Tailscaled died. Restarting..." >> $LOG
        sudo "$BIN_DIR/tailscaled" --tun=userspace-networking --socket="$SOCKET" --state="$STATE_FILE" >> /tmp/tailscaled.log 2>&1 &
        sleep 2
        
        if ! mountpoint -q ~/google-drive; then
            echo "$(date): Google Drive unmounted. Remounting..." >> $LOG
            "$BIN_DIR/rclone" mount gdrive: ~/google-drive --vfs-cache-mode writes --daemon
        fi
    fi
    sleep 15
done
