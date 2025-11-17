#!/bin/bash

# Упрощенный скрипт деплоя (требует ручного ввода пароля при первом подключении)

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

SERVER_IP="45.137.151.98"
SERVER_USER="root"
REMOTE_DIR="/var/www/devblog"

echo -e "${GREEN}🚀 Быстрый деплой DevBlog${NC}\n"
echo -e "${YELLOW}Пароль для сервера: zWfgWxfdEnB4Fs${NC}\n"

cd "$(dirname "$0")"

# Сборка frontend
echo -e "${YELLOW}📦 Сборка frontend...${NC}"
cd client
npm run build
if [ $? -ne 0 ]; then
    echo -e "${RED}❌ Ошибка при сборке${NC}"
    exit 1
fi
cd ..

# Создание архива
echo -e "${YELLOW}📦 Создание архива...${NC}"
TEMP_DIR=$(mktemp -d)
mkdir -p "$TEMP_DIR/devblog"
cp -r server "$TEMP_DIR/devblog/"
cp -r client/dist "$TEMP_DIR/devblog/client/"
cd "$TEMP_DIR"
tar -czf devblog.tar.gz devblog/

# Инструкции для ручного деплоя
echo -e "\n${GREEN}════════════════════════════════════════${NC}"
echo -e "${GREEN}📋 Инструкции для деплоя:${NC}"
echo -e "${BLUE}════════════════════════════════════════${NC}\n"
echo -e "1. Скопируйте архив на сервер:"
echo -e "   ${YELLOW}scp $TEMP_DIR/devblog.tar.gz root@${SERVER_IP}:/tmp/${NC}\n"
echo -e "2. Подключитесь к серверу:"
echo -e "   ${YELLOW}ssh root@${SERVER_IP}${NC}"
echo -e "   Пароль: ${YELLOW}zWfgWxfdEnB4Fs${NC}\n"
echo -e "3. На сервере выполните:"
echo -e "   ${YELLOW}cd /var/www/devblog${NC}"
echo -e "   ${YELLOW}tar -xzf /tmp/devblog.tar.gz --strip-components=1${NC}"
echo -e "   ${YELLOW}cd server && npm install --production${NC}"
echo -e "   ${YELLOW}pm2 restart devblog || pm2 start index.js --name devblog${NC}\n"
echo -e "${GREEN}Архив находится в: ${TEMP_DIR}/devblog.tar.gz${NC}\n"

