#!/bin/bash

# Цвета для вывода
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Функция для обработки сигнала завершения
cleanup() {
    echo -e "\n${YELLOW}🛑 Остановка приложения...${NC}"
    # Убиваем все дочерние процессы
    kill 0
    exit 0
}

# Устанавливаем обработчик сигналов
trap cleanup SIGINT SIGTERM

echo -e "${GREEN}🚀 Запуск DevBlog приложения...${NC}\n"

# Проверка наличия Node.js
if ! command -v node &> /dev/null; then
    echo -e "${RED}❌ Node.js не установлен. Пожалуйста, установите Node.js сначала.${NC}"
    exit 1
fi

# Проверка наличия npm
if ! command -v npm &> /dev/null; then
    echo -e "${RED}❌ npm не установлен. Пожалуйста, установите npm сначала.${NC}"
    exit 1
fi

echo -e "${GREEN}✅ Node.js версия: $(node --version)${NC}"
echo -e "${GREEN}✅ npm версия: $(npm --version)${NC}\n"

# Получаем путь к директории скрипта
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
cd "$SCRIPT_DIR"

# Проверка и установка зависимостей
echo -e "${YELLOW}📦 Проверка зависимостей...${NC}"

if [ ! -d "node_modules" ] || [ ! -d "server/node_modules" ] || [ ! -d "client/node_modules" ]; then
    echo -e "${YELLOW}📦 Установка зависимостей...${NC}"
    npm run install-all
    if [ $? -ne 0 ]; then
        echo -e "${RED}❌ Ошибка при установке зависимостей${NC}"
        exit 1
    fi
    echo -e "${GREEN}✅ Зависимости установлены${NC}\n"
else
    echo -e "${GREEN}✅ Зависимости уже установлены${NC}\n"
fi

# Проверка и создание .env файла
if [ ! -f "server/.env" ]; then
    echo -e "${YELLOW}⚙️  Создание файла .env...${NC}"
    cat > server/.env << EOF
PORT=5000
JWT_SECRET=dev-secret-key-change-in-production-$(date +%s)
NODE_ENV=development
EOF
    echo -e "${GREEN}✅ Файл .env создан${NC}\n"
else
    echo -e "${GREEN}✅ Файл .env уже существует${NC}\n"
fi

# Проверка наличия папки uploads
if [ ! -d "server/uploads" ]; then
    echo -e "${YELLOW}📁 Создание папки uploads...${NC}"
    mkdir -p server/uploads
    echo -e "${GREEN}✅ Папка uploads создана${NC}\n"
fi

# Запуск приложения
echo -e "${GREEN}🚀 Запуск приложения...${NC}\n"
echo -e "${BLUE}════════════════════════════════════════${NC}"
echo -e "${GREEN}📡 Backend:  ${NC}http://localhost:5000"
echo -e "${GREEN}🌐 Frontend: ${NC}http://localhost:3000"
echo -e "${BLUE}════════════════════════════════════════${NC}\n"
echo -e "${YELLOW}💡 Для остановки нажмите Ctrl+C${NC}\n"

# Запускаем приложение
npm run dev

