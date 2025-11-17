#!/bin/bash

# Цвета для вывода
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Конфигурация
SERVER_IP="45.137.151.98"
REMOTE_DIR="/var/www/devblog"

echo -e "${GREEN}🔧 Настройка сервера для DevBlog...${NC}\n"

set -e

echo "📦 Обновление системы..."
export DEBIAN_FRONTEND=noninteractive
apt-get update -qq

echo "📦 Установка Node.js..."
if ! command -v node &> /dev/null; then
    curl -fsSL https://deb.nodesource.com/setup_20.x | bash -
    apt-get install -y nodejs
    echo -e "${GREEN}✅ Node.js установлен: $(node --version)${NC}"
else
    echo -e "${GREEN}✅ Node.js уже установлен: $(node --version)${NC}"
fi

echo "📦 Установка PM2..."
if ! command -v pm2 &> /dev/null; then
    npm install -g pm2
    echo -e "${GREEN}✅ PM2 установлен${NC}"
else
    echo -e "${GREEN}✅ PM2 уже установлен${NC}"
fi

echo "📦 Установка Nginx..."
if ! command -v nginx &> /dev/null; then
    apt-get install -y nginx
    systemctl enable nginx
    echo -e "${GREEN}✅ Nginx установлен${NC}"
else
    echo -e "${GREEN}✅ Nginx уже установлен${NC}"
fi

echo "📁 Создание директорий..."
mkdir -p ${REMOTE_DIR}
mkdir -p ${REMOTE_DIR}/server/uploads
mkdir -p ${REMOTE_DIR}/client/dist
echo -e "${GREEN}✅ Директории созданы${NC}"

# Создание конфигурации nginx
echo "📝 Настройка Nginx..."
cat > /etc/nginx/sites-available/devblog << NGINXCONF
server {
    listen 80;
    server_name ${SERVER_IP};

    # Увеличение размера загружаемых файлов
    client_max_body_size 10M;

    # Frontend - статические файлы
    location / {
        root /var/www/devblog/client/dist;
        try_files \$uri \$uri/ /index.html;
        add_header Cache-Control "no-cache, no-store, must-revalidate";
    }

    # Backend API
    location /api {
        proxy_pass http://localhost:5000;
        proxy_http_version 1.1;
        proxy_set_header Upgrade \$http_upgrade;
        proxy_set_header Connection 'upgrade';
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto \$scheme;
        proxy_cache_bypass \$http_upgrade;
        proxy_read_timeout 300s;
        proxy_connect_timeout 75s;
    }

    # Загруженные изображения
    location /uploads {
        proxy_pass http://localhost:5000;
        proxy_http_version 1.1;
        proxy_set_header Host \$host;
        expires 30d;
        add_header Cache-Control "public, immutable";
    }
}
NGINXCONF

# Создаем симлинк если его нет
if [ ! -L /etc/nginx/sites-enabled/devblog ]; then
    ln -s /etc/nginx/sites-available/devblog /etc/nginx/sites-enabled/
    echo -e "${GREEN}✅ Симлинк создан${NC}"
fi

# Удаляем default конфиг если он есть
rm -f /etc/nginx/sites-enabled/default

# Проверяем конфигурацию
echo "🔍 Проверка конфигурации Nginx..."
nginx -t

# Перезапускаем nginx
systemctl restart nginx
echo -e "${GREEN}✅ Nginx настроен и перезапущен${NC}"

# Создание .env файла (если его нет)
if [ ! -f ${REMOTE_DIR}/server/.env ]; then
    echo "📝 Создание .env файла..."
    mkdir -p ${REMOTE_DIR}/server
    cat > ${REMOTE_DIR}/server/.env << ENVFILE
PORT=5000
JWT_SECRET=$(openssl rand -base64 32)
NODE_ENV=production
FRONTEND_URL=http://${SERVER_IP}
ENVFILE
    echo -e "${GREEN}✅ .env файл создан${NC}"
    echo -e "${YELLOW}⚠️  Не забудьте добавить GMAIL_USER и GMAIL_APP_PASSWORD если нужна отправка email!${NC}"
else
    echo -e "${GREEN}✅ .env файл уже существует${NC}"
fi

# Настройка firewall
echo "🔥 Настройка firewall..."
if command -v ufw &> /dev/null; then
    ufw allow 22/tcp
    ufw allow 80/tcp
    ufw allow 443/tcp
    ufw --force enable || true
    echo -e "${GREEN}✅ Firewall настроен${NC}"
else
    echo -e "${YELLOW}⚠️  UFW не установлен, пропускаем настройку firewall${NC}"
fi

echo -e "\n${GREEN}════════════════════════════════════════${NC}"
echo -e "${GREEN}✅ Настройка сервера завершена!${NC}"
echo -e "${BLUE}════════════════════════════════════════${NC}"
echo -e "${YELLOW}📋 Следующие шаги:${NC}"
echo -e "   1. Загрузите приложение на сервер (используйте deploy.sh с локальной машины)"
echo -e "   2. Проверьте .env файл: ${REMOTE_DIR}/server/.env"
echo -e "   3. Откройте http://${SERVER_IP} в браузере"
echo -e "\n"

