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

echo -e "${GREEN}🔧 Настройка сервера для DevBlog...${NC}\n"

# Проверка подключения
echo -e "${YELLOW}🔍 Проверка подключения к серверу...${NC}"
if ! ssh -o ConnectTimeout=5 "${SERVER_USER}@${SERVER_IP}" exit 2>/dev/null; then
    echo -e "${RED}❌ Не удалось подключиться к серверу${NC}"
    exit 1
fi
echo -e "${GREEN}✅ Подключение установлено${NC}\n"

# Выполнение настройки на сервере
ssh "${SERVER_USER}@${SERVER_IP}" << 'EOF'
    set -e
    
    echo "📦 Обновление системы..."
    export DEBIAN_FRONTEND=noninteractive
    apt-get update -qq
    
    echo "📦 Установка Node.js..."
    if ! command -v node &> /dev/null; then
        curl -fsSL https://deb.nodesource.com/setup_20.x | bash -
        apt-get install -y nodejs
    else
        echo "✅ Node.js уже установлен: $(node --version)"
    fi
    
    echo "📦 Установка PM2..."
    if ! command -v pm2 &> /dev/null; then
        npm install -g pm2
    else
        echo "✅ PM2 уже установлен"
    fi
    
    echo "📦 Установка Nginx..."
    if ! command -v nginx &> /dev/null; then
        apt-get install -y nginx
        systemctl enable nginx
    else
        echo "✅ Nginx уже установлен"
    fi
    
    echo "📁 Создание директорий..."
    mkdir -p /var/www/devblog
    mkdir -p /var/www/devblog/server/uploads
    mkdir -p /var/www/devblog/client/dist
    
    echo "✅ Базовая настройка завершена!"
EOF

if [ $? -ne 0 ]; then
    echo -e "${RED}❌ Ошибка при настройке сервера${NC}"
    exit 1
fi

# Создание конфигурации nginx
echo -e "\n${YELLOW}📝 Создание конфигурации Nginx...${NC}"
cat > /tmp/nginx-devblog.conf << NGINXCONF
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

# Загрузка конфигурации на сервер
scp /tmp/nginx-devblog.conf "${SERVER_USER}@${SERVER_IP}:/tmp/nginx-devblog.conf"

# Установка конфигурации
ssh "${SERVER_USER}@${SERVER_IP}" << EOF
    set -e
    
    echo "📝 Настройка Nginx..."
    mv /tmp/nginx-devblog.conf /etc/nginx/sites-available/devblog
    
    # Создаем симлинк если его нет
    if [ ! -L /etc/nginx/sites-enabled/devblog ]; then
        ln -s /etc/nginx/sites-available/devblog /etc/nginx/sites-enabled/
    fi
    
    # Удаляем default конфиг если он есть
    rm -f /etc/nginx/sites-enabled/default
    
    # Проверяем конфигурацию
    nginx -t
    
    # Перезапускаем nginx
    systemctl restart nginx
    
    echo "✅ Nginx настроен!"
EOF

# Создание .env файла на сервере (если его нет)
echo -e "\n${YELLOW}⚙️  Настройка .env файла...${NC}"
ssh "${SERVER_USER}@${SERVER_IP}" << EOF
    set -e
    
    if [ ! -f ${REMOTE_DIR}/server/.env ]; then
        echo "📝 Создание .env файла..."
        cat > ${REMOTE_DIR}/server/.env << ENVFILE
PORT=5000
JWT_SECRET=$(openssl rand -base64 32)
NODE_ENV=production
FRONTEND_URL=http://${SERVER_IP}
ENVFILE
        echo "✅ .env файл создан"
        echo "⚠️  Не забудьте добавить GMAIL_USER и GMAIL_APP_PASSWORD если нужна отправка email!"
    else
        echo "✅ .env файл уже существует"
    fi
EOF

# Настройка firewall
echo -e "\n${YELLOW}🔥 Настройка firewall...${NC}"
ssh "${SERVER_USER}@${SERVER_IP}" << 'EOF'
    set -e
    
    if command -v ufw &> /dev/null; then
        echo "🔥 Настройка UFW..."
        ufw allow 22/tcp
        ufw allow 80/tcp
        ufw allow 443/tcp
        ufw --force enable || true
        echo "✅ Firewall настроен"
    else
        echo "⚠️  UFW не установлен, пропускаем настройку firewall"
    fi
EOF

echo -e "\n${GREEN}════════════════════════════════════════${NC}"
echo -e "${GREEN}✅ Настройка сервера завершена!${NC}"
echo -e "${BLUE}════════════════════════════════════════${NC}"
echo -e "${YELLOW}📋 Следующие шаги:${NC}"
echo -e "   1. Запустите ./deploy.sh для деплоя приложения"
echo -e "   2. Проверьте .env файл на сервере: ${REMOTE_DIR}/server/.env"
echo -e "   3. Откройте http://${SERVER_IP} в браузере"
echo -e "\n"

