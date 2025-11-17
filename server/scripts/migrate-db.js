const sequelize = require('../config/database');

async function migrate() {
  try {
    console.log('🔄 Начало миграции базы данных...');
    
    // Добавляем колонки если их нет
    await sequelize.query(`
      ALTER TABLE Users ADD COLUMN resetPasswordToken TEXT;
    `).catch(err => {
      if (err.message.includes('duplicate column')) {
        console.log('✅ Колонка resetPasswordToken уже существует');
      } else {
        console.log('⚠️  resetPasswordToken:', err.message);
      }
    });
    
    await sequelize.query(`
      ALTER TABLE Users ADD COLUMN resetPasswordExpires DATETIME;
    `).catch(err => {
      if (err.message.includes('duplicate column')) {
        console.log('✅ Колонка resetPasswordExpires уже существует');
      } else {
        console.log('⚠️  resetPasswordExpires:', err.message);
      }
    });
    
    console.log('✅ Миграция завершена');
    process.exit(0);
  } catch (error) {
    console.error('❌ Ошибка миграции:', error);
    process.exit(1);
  }
}

migrate();

