#!/bin/bash

# Налаштування версій та шляхів
BIN_DIR="$HOME/bin"
STATE_FILE="$HOME/.tailscale/tailscaled.state"
SOCKET="/var/run/tailscale/tailscaled.sock"
TS_VERSION="1.64.0"

echo "--- Перевірка середовища та створення папок ---"
mkdir -p "$BIN_DIR"
mkdir -p "$HOME/.tailscale"
sudo mkdir -p /var/run/tailscale

# 1. Автоматичне завантаження Tailscale, якщо його немає
if [ ! -f "$BIN_DIR/tailscaled" ]; then
    echo "--- Завантаження Tailscale ($TS_VERSION) ---"
    curl -L "https://pkgs.tailscale.com/stable/tailscale_${TS_VERSION}_amd64.tgz" | tar xzf - --strip-components=1 -C "$BIN_DIR"
    chmod +x "$BIN_DIR/tailscale" "$BIN_DIR/tailscaled"
fi

# 2. Автоматичне завантаження rclone, якщо його немає
if [ ! -f "$BIN_DIR/rclone" ]; then
    echo "--- Завантаження rclone ---"
    curl -L https://downloads.rclone.org/rclone-current-linux-amd64.zip -o /tmp/rclone.zip
    unzip -j /tmp/rclone.zip "rclone-v*-linux-amd64/rclone" -d "$BIN_DIR"
    rm /tmp/rclone.zip
    chmod +x "$BIN_DIR/rclone"
fi

# 3. Запуск tailscaled
echo "--- Запуск tailscaled ---"
if pgrep -f "tailscaled" > /dev/null; then
    sudo pkill -f tailscaled
    sleep 1
fi
sudo "$BIN_DIR/tailscaled" \
    --tun=userspace-networking \
    --socket="$SOCKET" \
    --state="$STATE_FILE" > /tmp/tailscaled.log 2>&1 &

sleep 2

# 4. Авторизація
echo "--- Авторизація Tailscale ---"
"$BIN_DIR/tailscale" --socket="$SOCKET" up --force-reauth

# 5. Монтування Google Drive
echo "--- Монтування Google Drive ---"
mkdir -p ~/google-drive
if [ -f "$HOME/.config/rclone/rclone.conf" ]; then
    # Перевіряємо чи вже не змонтовано
    if ! mountpoint -q ~/google-drive; then
        "$BIN_DIR/rclone" mount gdrive: ~/google-drive --vfs-cache-mode writes --daemon
        echo "Диск примонтовано у ~/google-drive"
    else
        echo "Диск вже змонтований."
    fi
else
    echo "------------------------------------------------------------"
    echo "УВАГА: Конфігурація rclone не знайдена!"
    echo "Будь ласка, запустіть цю команду зараз, щоб налаштувати Google Drive:"
    echo "   ~/bin/rclone config"
    echo "Вкажіть назву 'gdrive', тип 'drive' (Google Drive) та слідуйте інструкціям."
    echo "Після цього диск буде монтуватися автоматично."
    echo "------------------------------------------------------------"
fi

# 6. Запуск вартового (Keep-Alive)
echo "--- Запуск вартового (Keep-Alive) ---"
if pgrep -f "keep-alive-tailscale.sh" > /dev/null; then
    pkill -f "keep-alive-tailscale.sh"
fi
chmod +x ./keep-alive-tailscale.sh
nohup ./keep-alive-tailscale.sh > /tmp/keepalive.log 2>&1 &

echo "--- Статус Tailscale ---"
"$BIN_DIR/tailscale" --socket="$SOCKET" status
