#!/bin/bash

# Запрос пароля у пользователя (без использования sudo)
echo "Пожалуйста, введите пароль для генерации хеша:"
read -sp "Введите пароль: " password
echo

# Генерация bcrypt-хеша (до выполнения команд под sudo)
hash=$(htpasswd -nbBC 10 "" "$password" | tr -d ':\n')

# Вывод хеша для отладки (можете убрать позже)
echo "Сгенерированный bcrypt хеш: $hash"

# Теперь начнем выполнение команд с sudo
sudo bash <<EOF
# Отключение IPv6
sysctl -w net.ipv6.conf.all.disable_ipv6=1
sysctl -w net.ipv6.conf.default.disable_ipv6=1
sysctl -w net.ipv6.conf.lo.disable_ipv6=1
sysctl -p

# Обновление пакетов и установка apache2-utils
apt-get update
apt-get install -y apache2-utils

# Загрузка Docker Compose
curl -L "https://github.com/docker/compose/releases/download/v2.29.2/docker-compose-\$(uname -s)-\$(uname -m)" -o /usr/local/bin/docker-compose

# Перемещение Docker Compose в /usr/bin/
mv /usr/local/bin/docker-compose /usr/bin/docker-compose

# Присваивание прав на выполнение
chmod +x /usr/bin/docker-compose

# Установка Docker
apt install -y docker.io

# Проверка успешной установки Docker Compose
docker-compose --version

# Получение IP адреса
IP=\$(curl -s ifconfig.me)

# Запуск контейнера с использованием сгенерированного хеша
docker run -d \
  --name=wg-easy \
  -e WG_HOST=\$IP \
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

# Запись результата в файл
echo "http://\$IP:51821\n$PASSWORD" > wg-out.txt
EOF
