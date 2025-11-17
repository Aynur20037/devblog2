#!/bin/bash

# Цвета для вывода
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Конфигурация
SERVER_IP="45.137.151.98"
SERVER_USER="${SERVER_USER:-root}"
REMOTE_DIR="/var/www/devblog"
LOCAL_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

echo -e "${GREEN}🚀 Деплой DevBlog на сервер ${SERVER_IP}...${NC}\n"

# Проверка наличия SSH ключа
if [ ! -f ~/.ssh/id_rsa ] && [ ! -f ~/.ssh/id_ed25519 ]; then
    echo -e "${YELLOW}⚠️  SSH ключ не найден. Убедитесь, что вы настроили SSH доступ к серверу.${NC}"
    read -p "Продолжить? (y/n): " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        exit 1
    fi
fi

# Проверка подключения к серверу
echo -e "${YELLOW}🔍 Проверка подключения к серверу...${NC}"
if ! ssh -o ConnectTimeout=5 -o BatchMode=yes "${SERVER_USER}@${SERVER_IP}" exit 2>/dev/null; then
    echo -e "${RED}❌ Не удалось подключиться к серверу ${SERVER_IP}${NC}"
    echo -e "${YELLOW}💡 Убедитесь, что:${NC}"
    echo -e "   - SSH ключ добавлен на сервер"
    echo -e "   - Сервер доступен"
    echo -e "   - Пользователь ${SERVER_USER} имеет доступ"
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

# Копируем необходимые файлы
mkdir -p "$TEMP_DIR/devblog"
cp -r server "$TEMP_DIR/devblog/"
cp -r client/dist "$TEMP_DIR/devblog/client/"
cp package.json "$TEMP_DIR/devblog/" 2>/dev/null || true
cp package-lock.json "$TEMP_DIR/devblog/" 2>/dev/null || true

# Исключаем ненужные файлы
cd "$TEMP_DIR"
tar --exclude='node_modules' \
    --exclude='.git' \
    --exclude='*.log' \
    --exclude='.env' \
    -czf "$ARCHIVE_NAME" devblog/

echo -e "${GREEN}✅ Архив создан: ${ARCHIVE_NAME}${NC}\n"

# Загрузка на сервер
echo -e "${YELLOW}📤 Загрузка на сервер...${NC}"
scp "$TEMP_DIR/$ARCHIVE_NAME" "${SERVER_USER}@${SERVER_IP}:/tmp/"

if [ $? -ne 0 ]; then
    echo -e "${RED}❌ Ошибка при загрузке файлов${NC}"
    rm -rf "$TEMP_DIR"
    exit 1
fi
echo -e "${GREEN}✅ Файлы загружены${NC}\n"

# Развертывание на сервере
echo -e "${YELLOW}🔧 Развертывание на сервере...${NC}"
ssh "${SERVER_USER}@${SERVER_IP}" << EOF
    set -e
    
    # Создаем директорию если её нет
    mkdir -p ${REMOTE_DIR}
    cd ${REMOTE_DIR}
    
    # Создаем backup текущей версии
    if [ -d "server" ]; then
        echo "📦 Создание backup..."
        tar -czf backup-\$(date +%Y%m%d-%H%M%S).tar.gz server/ client/ 2>/dev/null || true
    fi
    
    # Распаковываем новую версию
    echo "📦 Распаковка новой версии..."
    cd /tmp
    tar -xzf ${ARCHIVE_NAME} -C ${REMOTE_DIR} --strip-components=1
    
    # Устанавливаем зависимости
    echo "📦 Установка зависимостей..."
    cd ${REMOTE_DIR}/server
    npm install --production
    
    # Создаем необходимые директории
    mkdir -p ${REMOTE_DIR}/server/uploads
    mkdir -p ${REMOTE_DIR}/client/dist
    
    # Проверяем .env файл
    if [ ! -f ${REMOTE_DIR}/server/.env ]; then
        echo "⚠️  Файл .env не найден. Создайте его вручную!"
    fi
    
    # Перезапускаем приложение через PM2
    echo "🔄 Перезапуск приложения..."
    cd ${REMOTE_DIR}/server
    pm2 restart devblog || pm2 start index.js --name devblog
    pm2 save
    
    # Очистка
    rm -f /tmp/${ARCHIVE_NAME}
    
    echo "✅ Деплой завершен!"
EOF

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
echo -e "${GREEN}🌐 Сайт доступен по адресу: http://${SERVER_IP}${NC}"
echo -e "${YELLOW}💡 Не забудьте настроить nginx и .env файл на сервере${NC}\n"

