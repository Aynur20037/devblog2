const sequelize = require('../config/database');
const { User } = require('../models');
const fs = require('fs');

async function viewStats() {
  try {
    console.log('════════════════════════════════════════');
    console.log('📊 СТАТИСТИКА DEV BLOG');
    console.log('════════════════════════════════════════\n');

    // Зарегистрированные пользователи
    console.log('👥 ЗАРЕГИСТРИРОВАННЫЕ ПОЛЬЗОВАТЕЛИ:');
    console.log('────────────────────────────────────────');
    const users = await User.findAll({
      attributes: ['id', 'username', 'email', 'role', 'createdAt'],
      order: [['createdAt', 'DESC']]
    });
    
    console.log(`Всего пользователей: ${users.length}\n`);
    users.forEach(u => {
      const date = new Date(u.createdAt).toLocaleString('ru-RU');
      console.log(`ID: ${u.id} | ${u.username.padEnd(20)} | ${u.email.padEnd(30)} | ${u.role.padEnd(8)} | ${date}`);
    });

    // Статистика из логов nginx
    console.log('\n════════════════════════════════════════');
    console.log('🌐 СТАТИСТИКА ПОСЕЩЕНИЙ (Nginx):');
    console.log('════════════════════════════════════════\n');

    try {
      const logPath = '/var/log/nginx/access.log';
      if (fs.existsSync(logPath)) {
        const logContent = fs.readFileSync(logPath, 'utf8');
        const lines = logContent.trim().split('\n');
        const lastLines = lines.slice(-100);

        // Топ IP адресов
        const ipCounts = {};
        lastLines.forEach(line => {
          const ip = line.split(' ')[0];
          ipCounts[ip] = (ipCounts[ip] || 0) + 1;
        });

        const topIPs = Object.entries(ipCounts)
          .sort((a, b) => b[1] - a[1])
          .slice(0, 10);

        console.log('Топ IP адресов (последние 100 запросов):');
        topIPs.forEach(([ip, count]) => {
          console.log(`  ${ip.padEnd(20)} - ${count} запросов`);
        });

        // Статистика по кодам ответов
        const statusCounts = {};
        lastLines.forEach(line => {
          const parts = line.split(' ');
          if (parts.length > 8) {
            const status = parts[8];
            statusCounts[status] = (statusCounts[status] || 0) + 1;
          }
        });

        console.log('\nКоды ответов:');
        Object.entries(statusCounts)
          .sort((a, b) => b[1] - a[1])
          .forEach(([status, count]) => {
            console.log(`  ${status.padEnd(5)} - ${count} раз`);
          });

        // Популярные страницы
        const pageCounts = {};
        lastLines.forEach(line => {
          const parts = line.split(' ');
          if (parts.length > 6) {
            const page = parts[6].split('?')[0];
            if (!page.includes('assets') && !page.includes('vite.svg')) {
              pageCounts[page] = (pageCounts[page] || 0) + 1;
            }
          }
        });

        console.log('\nПопулярные страницы:');
        Object.entries(pageCounts)
          .sort((a, b) => b[1] - a[1])
          .slice(0, 10)
          .forEach(([page, count]) => {
            console.log(`  ${page.padEnd(40)} - ${count} раз`);
          });
      } else {
        console.log('Лог файл не найден');
      }
    } catch (err) {
      console.log('Ошибка чтения логов:', err.message);
    }

    console.log('\n════════════════════════════════════════');
    process.exit(0);
  } catch (error) {
    console.error('Ошибка:', error);
    process.exit(1);
  }
}

viewStats();


