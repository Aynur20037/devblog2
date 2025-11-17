#!/bin/bash

# Скрипт для просмотра статистики посещений сайта

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

SERVER_IP="45.137.151.98"
SERVER_USER="root"
SERVER_PASSWORD="zWfgWxfdEnB4Fs"

echo -e "${GREEN}📊 Статистика посещений DevBlog${NC}\n"

expect << 'EOF'
set timeout 30
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
send "cd /var/www/devblog/server && node scripts/view-stats.js\r"
expect "# "
send "exit\r"
expect eof
EOF

