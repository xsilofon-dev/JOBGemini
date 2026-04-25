#!/bin/bash

# Скрипт для встановлення та запуску Tailscale у Google Cloud Shell
# (використовує userspace-networking, оскільки Cloud Shell не має TUN/TAP)

echo "--- Встановлення Tailscale ---"
curl -fsSL https://tailscale.com/install.sh | sudo sh

echo "--- Налаштування директорії для сокета ---"
sudo mkdir -p /var/run/tailscale

echo "--- Запуск tailscaled у фоновому режимі (userspace) ---"
# Запускаємо демон у фоні
sudo tailscaled --tun=userspace-networking --socket=/var/run/tailscale/tailscaled.sock > /tmp/tailscaled.log 2>&1 &

# Чекаємо 2 секунди для запуску
sleep 2

echo "--- Авторизація ---"
echo "Будь ласка, перейдіть за посиланням нижче для авторизації:"
sudo tailscale --socket=/var/run/tailscale/tailscaled.sock up --force-reauth

echo "--- Статус ---"
sudo tailscale --socket=/var/run/tailscale/tailscaled.sock status
