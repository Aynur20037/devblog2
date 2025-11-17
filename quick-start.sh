#!/bin/bash

# Быстрый запуск DevBlog

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

echo -e "${GREEN}🚀 Быстрый запуск DevBlog...${NC}\n"

cd "$(dirname "$0")"

# Проверка портов
if lsof -ti:3000 > /dev/null 2>&1; then
    echo -e "${YELLOW}⚠️  Порт 3000 уже занят${NC}"
    echo -e "${YELLOW}Остановите процесс или используйте другой порт${NC}\n"
fi

if ! lsof -ti:5000 > /dev/null 2>&1; then
    echo -e "${YELLOW}⚠️  Backend не запущен. Запускаю...${NC}"
    cd server
    npm run dev > /tmp/devblog-server.log 2>&1 &
    SERVER_PID=$!
    cd ..
    sleep 2
    echo -e "${GREEN}✅ Backend запущен (PID: $SERVER_PID)${NC}\n"
fi

# Запуск frontend
echo -e "${GREEN}🌐 Запуск Frontend на http://localhost:3000${NC}\n"
cd client
npm run dev

