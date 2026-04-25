#!/bin/bash

# Шляхи до персистентних бінарників та даних
BIN_DIR="$HOME/bin"
STATE_FILE="$HOME/.tailscale/tailscaled.state"
SOCKET="/var/run/tailscale/tailscaled.sock"

echo "--- Перевірка середовища ---"
mkdir -p "$HOME/.tailscale"
sudo mkdir -p /var/run/tailscale

# Запуск tailscaled з персистентним станом
echo "--- Запуск tailscaled ---"
sudo "$BIN_DIR/tailscaled" \
    --tun=userspace-networking \
    --socket="$SOCKET" \
    --state="$STATE_FILE" > /tmp/tailscaled.log 2>&1 &

sleep 2

# Авторизація (якщо файл стану порожній, попросить лінк)
echo "--- Авторизація Tailscale ---"
"$BIN_DIR/tailscale" --socket="$SOCKET" up --force-reauth

echo "--- Монтування Google Drive ---"
mkdir -p ~/google-drive
# Використовуємо локальний rclone
if [ -f "$HOME/.config/rclone/rclone.conf" ]; then
    "$BIN_DIR/rclone" mount gdrive: ~/google-drive --vfs-cache-mode writes --daemon
else
    echo "УВАГА: Конфігурація rclone не знайдена. Запустіть 'rclone config' або додайте rclone.conf"
fi

echo "--- Запуск вартового (Keep-Alive) ---"
chmod +x ./keep-alive-tailscale.sh
nohup ./keep-alive-tailscale.sh > /tmp/keepalive.log 2>&1 &

echo "--- Статус системи ---"
"$BIN_DIR/tailscale" --socket="$SOCKET" status
