# Инструкция по деплою DevBlog на сервер

## Быстрый старт

### 1. Первоначальная настройка сервера (выполнить один раз)

```bash
./setup-server.sh
```

Этот скрипт:
- Установит Node.js, PM2, Nginx
- Настроит конфигурацию Nginx
- Создаст необходимые директории
- Настроит firewall

### 2. Деплой приложения

```bash
./deploy.sh
```

Этот скрипт:
- Соберет frontend
- Загрузит файлы на сервер
- Установит зависимости
- Перезапустит приложение через PM2

## Ручная настройка

### Настройка SSH доступа

Если у вас еще нет SSH ключа:

```bash
ssh-keygen -t ed25519 -C "your_email@example.com"
ssh-copy-id root@45.137.151.98
```

Или добавьте ключ вручную:
```bash
cat ~/.ssh/id_ed25519.pub | ssh root@45.137.151.98 "mkdir -p ~/.ssh && cat >> ~/.ssh/authorized_keys"
```

### Настройка переменных окружения

На сервере отредактируйте файл `/var/www/devblog/server/.env`:

```bash
ssh root@45.137.151.98
nano /var/www/devblog/server/.env
```

Добавьте:
```env
PORT=5000
JWT_SECRET=your-very-secret-key-change-this
NODE_ENV=production
FRONTEND_URL=http://45.137.151.98

# Опционально, для отправки email
GMAIL_USER=your-email@gmail.com
GMAIL_APP_PASSWORD=your-app-password
```

### Управление приложением через PM2

```bash
# Подключитесь к серверу
ssh root@45.137.151.98

# Управление приложением
cd /var/www/devblog/server
pm2 start index.js --name devblog    # Запуск
pm2 restart devblog                  # Перезапуск
pm2 stop devblog                     # Остановка
pm2 delete devblog                   # Удаление
pm2 logs devblog                     # Просмотр логов
pm2 status                           # Статус всех процессов
pm2 save                             # Сохранить конфигурацию
pm2 startup                          # Автозапуск при перезагрузке
```

### Управление Nginx

```bash
# Проверка конфигурации
sudo nginx -t

# Перезапуск
sudo systemctl restart nginx

# Статус
sudo systemctl status nginx

# Логи
sudo tail -f /var/log/nginx/error.log
sudo tail -f /var/log/nginx/access.log
```

## Структура на сервере

```
/var/www/devblog/
├── server/              # Backend
│   ├── .env            # Переменные окружения
│   ├── index.js        # Точка входа
│   ├── uploads/        # Загруженные изображения
│   └── node_modules/   # Зависимости
└── client/
    └── dist/           # Собранный frontend
```

## Проверка работы

После деплоя проверьте:

1. **Backend API**: `http://45.137.151.98/api/articles`
2. **Frontend**: `http://45.137.151.98`
3. **Логи PM2**: `ssh root@45.137.151.98 "pm2 logs devblog"`
4. **Логи Nginx**: `ssh root@45.137.151.98 "tail -f /var/log/nginx/error.log"`

## Обновление приложения

Для обновления просто запустите:

```bash
./deploy.sh
```

Скрипт автоматически:
- Создаст backup текущей версии
- Загрузит новую версию
- Перезапустит приложение

## Решение проблем

### Приложение не запускается

1. Проверьте логи PM2:
   ```bash
   ssh root@45.137.151.98 "pm2 logs devblog"
   ```

2. Проверьте .env файл:
   ```bash
   ssh root@45.137.151.98 "cat /var/www/devblog/server/.env"
   ```

3. Проверьте порт:
   ```bash
   ssh root@45.137.151.98 "netstat -tulpn | grep 5000"
   ```

### Nginx не работает

1. Проверьте конфигурацию:
   ```bash
   ssh root@45.137.151.98 "nginx -t"
   ```

2. Проверьте логи:
   ```bash
   ssh root@45.137.151.98 "tail -f /var/log/nginx/error.log"
   ```

3. Проверьте статус:
   ```bash
   ssh root@45.137.151.98 "systemctl status nginx"
   ```

### Изображения не загружаются

1. Проверьте права доступа:
   ```bash
   ssh root@45.137.151.98 "ls -la /var/www/devblog/server/uploads"
   ```

2. Установите правильные права:
   ```bash
   ssh root@45.137.151.98 "chmod -R 755 /var/www/devblog/server/uploads"
   ```

## Настройка домена (опционально)

Если у вас есть домен:

1. Настройте DNS записи для домена на IP `45.137.151.98`

2. Обновите конфигурацию Nginx:
   ```bash
   ssh root@45.137.151.98
   nano /etc/nginx/sites-available/devblog
   ```
   
   Измените `server_name`:
   ```nginx
   server_name yourdomain.com www.yourdomain.com;
   ```

3. Перезапустите Nginx:
   ```bash
   nginx -t
   systemctl restart nginx
   ```

4. Настройте SSL (Let's Encrypt):
   ```bash
   apt install certbot python3-certbot-nginx
   certbot --nginx -d yourdomain.com -d www.yourdomain.com
   ```

## Безопасность

- ✅ Измените `JWT_SECRET` на сложный случайный ключ
- ✅ Используйте сильные пароли для пользователей
- ✅ Настройте firewall (UFW)
- ✅ Регулярно обновляйте систему: `apt update && apt upgrade`
- ✅ Настройте SSL для HTTPS
- ✅ Ограничьте доступ к SSH (измените порт, используйте ключи)

