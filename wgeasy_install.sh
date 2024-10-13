#!/bin/bash

# Обновление пакетов и установка apache2-utils
sudo apt-get update
sudo apt-get install -y apache2-utils

# Убедимся, что утилита htpasswd установлена
if ! command -v htpasswd &> /dev/null
then
    echo "htpasswd не установлена. Установите с помощью: sudo apt-get install apache2-utils"
    exit
fi

# Запрос пароля у пользователя
read -sp "Введите пароль: " password
echo

# Генерация bcrypt-хеша
hash=$(htpasswd -nbBC 10 "" "$password" | tr -d ':\n')

# Вывод хеша
echo "Bcrypt хеш: $hash"

# Загрузка Docker Compose
sudo curl -L "https://github.com/docker/compose/releases/download/v2.29.2/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose

# Перемещение Docker Compose в /usr/bin/
sudo mv /usr/local/bin/docker-compose /usr/bin/docker-compose

# Присваивание прав на выполнение
sudo chmod +x /usr/bin/docker-compose

# Установка Docker
sudo apt install -y docker.io

# Проверка успешной установки Docker Compose
docker-compose --version

# Запуск контейнера с использованием сгенерированного хеша
docker run -d \
  --name=wg-easy \
  -e WG_HOST=5.42.106.52 \
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
