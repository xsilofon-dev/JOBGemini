#!/bin/bash
# Скрипт для підтримки життя Tailscale в Cloud Shell

SOCKET=/var/run/tailscale/tailscaled.sock
LOG=/tmp/tailscaled_keepalive.log

echo "Keep-alive loop started at $(date)" >> $LOG

while true; do
    if ! pgrep -x "tailscaled" > /dev/null; then
        echo "$(date): Tailscaled died. Restarting..." >> $LOG
        sudo tailscaled --tun=userspace-networking --socket=$SOCKET >> /tmp/tailscaled.log 2>&1 &
        sleep 2
        # Також перевіряємо чи примонтований диск
        if ! mountpoint -q ~/google-drive; then
            echo "$(date): Google Drive unmounted. Remounting..." >> $LOG
            export PATH=$PATH:~/bin
            rclone mount gdrive: ~/google-drive --vfs-cache-mode writes --daemon
        fi
    fi
    sleep 15
done
