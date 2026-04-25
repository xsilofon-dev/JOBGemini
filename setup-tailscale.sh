#!/bin/bash

# Скрипт для встановлення та запуску Tailscale у Google Cloud Shell
# (використовує userspace-networking, оскільки Cloud Shell не має TUN/TAP)

echo "--- Встановлення Tailscale ---"
curl -fsSL https://tailscale.com/install.sh | sudo sh

echo "--- Налаштування директорії для сокета ---"
sudo mkdir -p /var/run/tailscale

# Запуск tailscaled у фоновому режимі (userspace)
sudo tailscaled --tun=userspace-networking --socket=/var/run/tailscale/tailscaled.sock > /tmp/tailscaled.log 2>&1 &
sleep 2

echo "--- Авторизація Tailscale ---"
sudo tailscale --socket=/var/run/tailscale/tailscaled.sock up --force-reauth

echo "--- Монтування Google Drive (2TB+) ---"
export PATH=$PATH:~/bin
if [ ! -L /usr/bin/fusermount3 ]; then
    sudo ln -s /usr/bin/fusermount /usr/bin/fusermount3
fi
mkdir -p ~/google-drive
# Монтуємо у фоні з кешем для великих файлів
rclone mount gdrive: ~/google-drive --vfs-cache-mode writes --daemon

echo "--- Запуск вартового (Keep-Alive) ---"
chmod +x ~/tailscale-setup/keep-alive-tailscale.sh
nohup ~/tailscale-setup/keep-alive-tailscale.sh > /tmp/keepalive.log 2>&1 &

echo "--- Статус системи ---"
sudo tailscale --socket=/var/run/tailscale/tailscaled.sock status
df -h ~/google-drive

