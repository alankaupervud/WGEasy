#!/bin/bash



# Генерация случайного пароля
PASSWORD=$(< /dev/urandom tr -dc A-Z-a-z-0-9 | head -c${1:-16};echo;)

# Обновление пакетов и установка apache2-utils
sudo apt-get update
sudo apt-get install -y apache2-utils

# Проверим, существует ли утилита htpasswd
if [ ! -f /usr/bin/htpasswd ]; then
    echo "htpasswd не установлена. Установите с помощью: sudo apt-get install apache2-utils"
    exit
fi


# Генерация bcrypt-хеша
hash=$(htpasswd -nbBC 10 "" "$PASSWORD" | tr -d ':\n')

# Вывод хеша
echo "Bcrypt хеш: $hash"

# Установка Docker
sudo apt install -y docker.io docker-compose -y

# Иногда Docker установлен, но по какой-то причене он не запустился. Это поднимет его принудительно. 
sudo systemctl enable --now docker

# Проверка успешной установки Docker Compose
docker-compose --version
#IP=$(curl -s ifconfig.me)
IP=$(ip addr show ens3 | grep -oP 'inet \K[\d.]+')


# Запуск контейнера с использованием сгенерированного хеша
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

echo -e "http://$IP:51821\n$PASSWORD" > wg-out.txt
