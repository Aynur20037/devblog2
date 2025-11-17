# ✅ Финальная настройка сервера

## Что уже сделано:
- ✅ Node.js установлен
- ✅ PM2 установлен  
- ✅ Nginx установлен и настроен
- ✅ Файлы приложения загружены на сервер
- ✅ Зависимости установлены

## Что нужно сделать вручную:

### 1. Подключитесь к серверу:
```bash
ssh root@45.137.151.98
# Пароль: zWfgWxfdEnB4Fs
```

### 2. Создайте .env файл:
```bash
cd /var/www/devblog/server
cat > .env << 'EOF'
PORT=5000
JWT_SECRET=$(openssl rand -base64 32)
NODE_ENV=production
FRONTEND_URL=http://45.137.151.98
EOF
```

Или выполните команду для генерации JWT_SECRET:
```bash
cd /var/www/devblog/server
echo "PORT=5000" > .env
echo "JWT_SECRET=$(openssl rand -base64 32)" >> .env
echo "NODE_ENV=production" >> .env
echo "FRONTEND_URL=http://45.137.151.98" >> .env
```

### 3. Запустите приложение:
```bash
cd /var/www/devblog/server
pm2 start index.js --name devblog
pm2 save
pm2 startup
```

### 4. Проверьте статус:
```bash
pm2 status
pm2 logs devblog
```

### 5. Проверьте сайт:
Откройте в браузере: **http://45.137.151.98**

## Управление приложением:

```bash
# Просмотр статуса
pm2 status

# Просмотр логов
pm2 logs devblog

# Перезапуск
pm2 restart devblog

# Остановка
pm2 stop devblog
```

## Если что-то не работает:

1. Проверьте логи PM2: `pm2 logs devblog`
2. Проверьте логи Nginx: `tail -f /var/log/nginx/error.log`
3. Проверьте, что порт 5000 слушается: `netstat -tulpn | grep 5000`
4. Проверьте конфигурацию Nginx: `nginx -t`

