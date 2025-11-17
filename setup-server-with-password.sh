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

echo -e "${GREEN}🔧 Настройка сервера для DevBlog...${NC}\n"

# Проверка наличия sshpass
if ! command -v sshpass &> /dev/null; then
    echo -e "${YELLOW}📦 Установка sshpass...${NC}"
    if [[ "$OSTYPE" == "darwin"* ]]; then
        if command -v brew &> /dev/null; then
            brew install hudochenkov/sshpass/sshpass
        else
            echo -e "${RED}❌ Нужно установить sshpass. Выполните: brew install hudochenkov/sshpass/sshpass${NC}"
            exit 1
        fi
    else
        sudo apt-get update && sudo apt-get install -y sshpass
    fi
fi

# Функция для выполнения команд на сервере
ssh_with_password() {
    sshpass -p "$SERVER_PASSWORD" ssh -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null "$SERVER_USER@$SERVER_IP" "$@"
}

# Выполнение настройки на сервере
ssh_with_password << 'SETUP_SCRIPT'
    set -e
    
    echo "📦 Обновление системы..."
    export DEBIAN_FRONTEND=noninteractive
    apt-get update -qq
    
    echo "📦 Установка Node.js..."
    if ! command -v node &> /dev/null; then
        curl -fsSL https://deb.nodesource.com/setup_20.x | bash -
        apt-get install -y nodejs
        echo "✅ Node.js установлен: $(node --version)"
    else
        echo "✅ Node.js уже установлен: $(node --version)"
    fi
    
    echo "📦 Установка PM2..."
    if ! command -v pm2 &> /dev/null; then
        npm install -g pm2
        echo "✅ PM2 установлен"
    else
        echo "✅ PM2 уже установлен"
    fi
    
    echo "📦 Установка Nginx..."
    if ! command -v nginx &> /dev/null; then
        apt-get install -y nginx
        systemctl enable nginx
        echo "✅ Nginx установлен"
    else
        echo "✅ Nginx уже установлен"
    fi
    
    echo "📁 Создание директорий..."
    mkdir -p /var/www/devblog
    mkdir -p /var/www/devblog/server/uploads
    mkdir -p /var/www/devblog/client/dist
    echo "✅ Директории созданы"
    
    echo "📝 Настройка Nginx..."
    cat > /etc/nginx/sites-available/devblog << NGINXCONF
server {
    listen 80;
    server_name 45.137.151.98;
    client_max_body_size 10M;
    location / {
        root /var/www/devblog/client/dist;
        try_files \$uri \$uri/ /index.html;
        add_header Cache-Control "no-cache, no-store, must-revalidate";
    }
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
    location /uploads {
        proxy_pass http://localhost:5000;
        proxy_http_version 1.1;
        proxy_set_header Host \$host;
        expires 30d;
        add_header Cache-Control "public, immutable";
    }
}
NGINXCONF
    
    if [ ! -L /etc/nginx/sites-enabled/devblog ]; then
        ln -s /etc/nginx/sites-available/devblog /etc/nginx/sites-enabled/
        echo "✅ Симлинк создан"
    fi
    
    rm -f /etc/nginx/sites-enabled/default
    
    echo "🔍 Проверка конфигурации Nginx..."
    nginx -t
    
    systemctl restart nginx
    echo "✅ Nginx настроен и перезапущен"
    
    if [ ! -f /var/www/devblog/server/.env ]; then
        echo "📝 Создание .env файла..."
        mkdir -p /var/www/devblog/server
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
    
    echo "🔥 Настройка firewall..."
    if command -v ufw &> /dev/null; then
        ufw allow 22/tcp
        ufw allow 80/tcp
        ufw allow 443/tcp
        ufw --force enable || true
        echo "✅ Firewall настроен"
    fi
    
    echo "✅ Настройка сервера завершена!"
SETUP_SCRIPT

if [ $? -ne 0 ]; then
    echo -e "${RED}❌ Ошибка при настройке сервера${NC}"
    exit 1
fi

echo -e "\n${GREEN}════════════════════════════════════════${NC}"
echo -e "${GREEN}✅ Настройка сервера завершена!${NC}"
echo -e "${BLUE}════════════════════════════════════════${NC}"
echo -e "${YELLOW}📋 Следующие шаги:${NC}"
echo -e "   1. Запустите: ./deploy-with-password.sh"
echo -e "   2. Откройте: http://${SERVER_IP}"
echo -e "\n"

