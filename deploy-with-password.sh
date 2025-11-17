#!/bin/bash

# Цвета для вывода
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Конфигурация
SERVER_IP="45.137.151.98"
SERVER_USER="root"
SERVER_PASSWORD="zWfgWxfdEnB4Fs"
REMOTE_DIR="/var/www/devblog"
LOCAL_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

echo -e "${GREEN}🚀 Деплой DevBlog на сервер ${SERVER_IP}...${NC}\n"

# Проверка наличия sshpass
if ! command -v sshpass &> /dev/null; then
    echo -e "${YELLOW}📦 Установка sshpass...${NC}"
    if [[ "$OSTYPE" == "darwin"* ]]; then
        # macOS
        if command -v brew &> /dev/null; then
            brew install hudochenkov/sshpass/sshpass
        else
            echo -e "${RED}❌ Нужно установить sshpass. Выполните: brew install hudochenkov/sshpass/sshpass${NC}"
            exit 1
        fi
    else
        # Linux
        sudo apt-get update && sudo apt-get install -y sshpass
    fi
fi

# Функция для выполнения команд на сервере с паролем
ssh_with_password() {
    sshpass -p "$SERVER_PASSWORD" ssh -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null "$SERVER_USER@$SERVER_IP" "$@"
}

# Функция для копирования файлов на сервер с паролем
scp_with_password() {
    sshpass -p "$SERVER_PASSWORD" scp -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null "$@"
}

# Проверка подключения
echo -e "${YELLOW}🔍 Проверка подключения к серверу...${NC}"
if ! ssh_with_password "echo 'Connected'" > /dev/null 2>&1; then
    echo -e "${RED}❌ Не удалось подключиться к серверу${NC}"
    exit 1
fi
echo -e "${GREEN}✅ Подключение установлено${NC}\n"

# Сборка frontend
echo -e "${YELLOW}📦 Сборка frontend...${NC}"
cd "$LOCAL_DIR/client"
npm run build
if [ $? -ne 0 ]; then
    echo -e "${RED}❌ Ошибка при сборке frontend${NC}"
    exit 1
fi
echo -e "${GREEN}✅ Frontend собран${NC}\n"

# Создание временного архива
echo -e "${YELLOW}📦 Создание архива...${NC}"
cd "$LOCAL_DIR"
TEMP_DIR=$(mktemp -d)
ARCHIVE_NAME="devblog-deploy-$(date +%Y%m%d-%H%M%S).tar.gz"

mkdir -p "$TEMP_DIR/devblog"
cp -r server "$TEMP_DIR/devblog/"
cp -r client/dist "$TEMP_DIR/devblog/client/"
cp package.json "$TEMP_DIR/devblog/" 2>/dev/null || true

cd "$TEMP_DIR"
tar --exclude='node_modules' \
    --exclude='.git' \
    --exclude='*.log' \
    --exclude='.env' \
    -czf "$ARCHIVE_NAME" devblog/

echo -e "${GREEN}✅ Архив создан: ${ARCHIVE_NAME}${NC}\n"

# Загрузка на сервер
echo -e "${YELLOW}📤 Загрузка на сервер...${NC}"
scp_with_password "$TEMP_DIR/$ARCHIVE_NAME" "${SERVER_USER}@${SERVER_IP}:/tmp/"

if [ $? -ne 0 ]; then
    echo -e "${RED}❌ Ошибка при загрузке файлов${NC}"
    rm -rf "$TEMP_DIR"
    exit 1
fi
echo -e "${GREEN}✅ Файлы загружены${NC}\n"

# Развертывание на сервере
echo -e "${YELLOW}🔧 Развертывание на сервере...${NC}"
ssh_with_password << 'DEPLOY_SCRIPT'
    set -e
    
    # Создаем директорию если её нет
    mkdir -p /var/www/devblog
    cd /var/www/devblog
    
    # Создаем backup текущей версии
    if [ -d "server" ]; then
        echo "📦 Создание backup..."
        tar -czf backup-$(date +%Y%m%d-%H%M%S).tar.gz server/ client/ 2>/dev/null || true
    fi
    
    # Распаковываем новую версию
    echo "📦 Распаковка новой версии..."
    cd /tmp
    tar -xzf devblog-deploy-*.tar.gz -C /var/www/devblog --strip-components=1
    rm -f /tmp/devblog-deploy-*.tar.gz
    
    # Устанавливаем зависимости
    echo "📦 Установка зависимостей..."
    cd /var/www/devblog/server
    npm install --production
    
    # Создаем необходимые директории
    mkdir -p /var/www/devblog/server/uploads
    mkdir -p /var/www/devblog/client/dist
    
    # Проверяем .env файл
    if [ ! -f /var/www/devblog/server/.env ]; then
        echo "📝 Создание .env файла..."
        cat > /var/www/devblog/server/.env << ENVFILE
PORT=5000
JWT_SECRET=$(openssl rand -base64 32)
NODE_ENV=production
FRONTEND_URL=http://45.137.151.98
ENVFILE
        echo "✅ .env файл создан"
    else
        echo "✅ .env файл уже существует"
    fi
    
    # Перезапускаем приложение через PM2
    echo "🔄 Перезапуск приложения..."
    cd /var/www/devblog/server
    if command -v pm2 &> /dev/null; then
        pm2 restart devblog || pm2 start index.js --name devblog
        pm2 save
        echo "✅ Приложение перезапущено через PM2"
    else
        echo "⚠️  PM2 не установлен. Установите его: npm install -g pm2"
    fi
    
    echo "✅ Деплой завершен!"
DEPLOY_SCRIPT

if [ $? -ne 0 ]; then
    echo -e "${RED}❌ Ошибка при развертывании${NC}"
    rm -rf "$TEMP_DIR"
    exit 1
fi

# Очистка
rm -rf "$TEMP_DIR"

echo -e "\n${GREEN}════════════════════════════════════════${NC}"
echo -e "${GREEN}✅ Деплой успешно завершен!${NC}"
echo -e "${BLUE}════════════════════════════════════════${NC}"
echo -e "${GREEN}🌐 Сайт доступен по адресу: http://${SERVER_IP}${NC}\n"

