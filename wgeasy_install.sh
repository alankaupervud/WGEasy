#!/bin/bash

# Генерация случайного пароля (16 символов)
PASSWORD=$(< /dev/urandom tr -dc A-Za-z0-9 | head -c${1:-16})
echo

# Обновление пакетов и установка apache2-utils
sudo apt-get update
sudo apt-get install -y apache2-utils

# Проверим, существует ли утилита htpasswd
if [ ! -f /usr/bin/htpasswd ]; then
    echo "htpasswd не установлена. Установите с помощью: sudo apt-get install apache2-utils"
    exit 1
fi

# Генерация bcrypt-хеша
hash=$(htpasswd -nbBC 10 "" "$PASSWORD" | tr -d ':\n')

# Вывод хеша
echo "Bcrypt хеш: $hash"

# Установка Docker и docker-compose
sudo apt install -y docker.io docker-compose

# Включаем и запускаем docker
sudo systemctl enable --now docker

# Проверка docker-compose
docker-compose --version

# Определяем IP (сначала внешний, если нет - берем локальный)
IP=$(curl -s ifconfig.me)
if [ -z "$IP" ]; then
    IP=$(hostname -I | awk '{print $1}')
fi
echo "Detected IP: $IP"

# Запуск контейнера wg-easy
docker run -d \
  --name=wg-easy \
  -e WG_HOST=$IP \
  -e PASSWORD_HASH="$hash" \
  -e WG_MTU=1280 \
  -v ~/.wg-easy:/etc/wireguard \
  -p 51820:51820/udp \
  -p 51821:51821/tcp \
  --cap-add=NET_ADMIN \
  --cap-add=SYS_MODULE \
  --sysctl="net.ipv4.conf.all.src_valid_mark=1" \
  --sysctl="net.ipv4.ip_forward=1" \
  --restart unless-stopped \
  ghcr.io/wg-easy/wg-easy

# Запишем URL панели и пароль в файл
echo -e "http://$IP:51821\n$PASSWORD" > wg-out.txt

echo "Готово. Админка и пароль записаны в wg-out.txt"
