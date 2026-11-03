#!/bin/bash
# Скрипт развертывания OpenVPN-клиента на Debian с интерактивным вводом ссылки

set -e  # остановка при любой ошибке

# Проверка прав суперпользователя
if [ "$EUID" -ne 0 ]; then
    echo "❌ Запустите скрипт с sudo или от root"
    exit 1
fi

# Запрашиваем ссылку у пользователя
echo "🔗 Введите прямую ссылку на ZIP-архив с конфигурацией OpenVPN:"
read -r VPN_URL

# Проверяем, что ссылка не пустая
if [ -z "$VPN_URL" ]; then
    echo "❌ Ссылка не может быть пустой. Запустите скрипт заново."
    exit 1
fi

# Рабочая директория
WORK_DIR="/tmp/openvpn_setup"
mkdir -p "$WORK_DIR"
cd "$WORK_DIR"

# 1. Установка пакетов
echo "📦 Устанавливаем openvpn и unzip..."
apt update
apt install -y openvpn unzip

# 2. Скачиваем архив по ссылке
echo "⬇️  Скачиваем конфигурацию из: $VPN_URL"
wget -O config.zip "$VPN_URL"

# 3. Распаковываем единственный zip-архив
echo "📂 Распаковываем архив..."
unzip config.zip

# 4. Находим единственный .ovpn-файл в текущей папке
OVPN_FILE=$(find . -maxdepth 1 -type f -name "*.ovpn" | head -n 1)
if [ -z "$OVPN_FILE" ]; then
    echo "❌ Не найден .ovpn-файл в папке $WORK_DIR"
    exit 1
fi
echo "🔍 Найден файл: $OVPN_FILE"

# 5. Копируем его в /etc/openvpn/client/geco.conf
cp "$OVPN_FILE" /etc/openvpn/client/geco.conf

# 6. Включаем и запускаем сервис
systemctl enable openvpn-client@geco
systemctl start openvpn-client@geco

echo "✅ OpenVPN-клиент успешно настроен и запущен!"

ip addr show tun0