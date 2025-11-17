#!/bin/bash

# Автоматический деплой с использованием expect для ввода пароля

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

SERVER_IP="45.137.151.98"
SERVER_USER="root"
SERVER_PASSWORD="zWfgWxfdEnB4Fs"
REMOTE_DIR="/var/www/devblog"

cd "$(dirname "$0")"

# Проверка наличия архива
if [ ! -f "devblog-deploy.tar.gz" ]; then
    echo -e "${YELLOW}📦 Создание архива...${NC}"
    ./quick-deploy.sh > /dev/null 2>&1
    ARCHIVE_PATH=$(find /var/folders -name "devblog.tar.gz" -type f 2>/dev/null | head -1)
    if [ -n "$ARCHIVE_PATH" ]; then
        cp "$ARCHIVE_PATH" devblog-deploy.tar.gz
    else
        echo -e "${RED}❌ Не удалось найти архив${NC}"
        exit 1
    fi
fi

echo -e "${GREEN}🚀 Загрузка на сервер...${NC}"

# Используем expect для автоматического ввода пароля
expect << EOF
set timeout 30
spawn scp devblog-deploy.tar.gz ${SERVER_USER}@${SERVER_IP}:/tmp/
expect {
    "password:" {
        send "${SERVER_PASSWORD}\r"
        exp_continue
    }
    "yes/no" {
        send "yes\r"
        exp_continue
    }
    eof
}
EOF

if [ $? -eq 0 ]; then
    echo -e "${GREEN}✅ Файл загружен${NC}\n"
    
    echo -e "${GREEN}🔧 Развертывание на сервере...${NC}"
    
    expect << 'DEPLOY_SCRIPT'
set timeout 60
spawn ssh root@45.137.151.98
expect {
    "password:" {
        send "zWfgWxfdEnB4Fs\r"
    }
    "yes/no" {
        send "yes\r"
        exp_continue
    }
}
expect "# "
send "mkdir -p /var/www/devblog\r"
expect "# "
send "cd /var/www/devblog\r"
expect "# "
send "tar -xzf /tmp/devblog-deploy.tar.gz --strip-components=1\r"
expect "# "
send "cd server && npm install --production\r"
expect "# "
send "pm2 restart devblog || pm2 start index.js --name devblog\r"
expect "# "
send "pm2 save\r"
expect "# "
send "exit\r"
expect eof
DEPLOY_SCRIPT

    echo -e "\n${GREEN}✅ Деплой завершен!${NC}"
    echo -e "${GREEN}🌐 Сайт доступен: http://${SERVER_IP}${NC}\n"
else
    echo -e "${RED}❌ Ошибка при загрузке${NC}"
    exit 1
fi
