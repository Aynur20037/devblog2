#!/bin/bash

# Скрипт для исправления отсутствующих файлов на сервере

expect << 'ENDOFEXPECT'
set timeout 120
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
send "cd /var/www/devblog/server\r"
expect "# "
send "cat > middleware/auth.js << 'AUTHEND'\r"
send "const jwt = require('jsonwebtoken');\r"
send "const { User } = require('../models');\r"
send "\r"
send "const auth = async (req, res, next) => {\r"
send "  try {\r"
send "    const token = req.header('Authorization')?.replace('Bearer ', '');\r"
send "    if (!token) {\r"
send "      return res.status(401).json({ message: 'Токен не предоставлен' });\r"
send "    }\r"
send "    const decoded = jwt.verify(token, process.env.JWT_SECRET || 'dev-secret-key');\r"
send "    const user = await User.findByPk(decoded.userId, {\r"
send "      attributes: { exclude: ['password'] }\r"
send "    });\r"
send "    if (!user) {\r"
send "      return res.status(401).json({ message: 'Пользователь не найден' });\r"
send "    }\r"
send "    req.user = user;\r"
send "    next();\r"
send "  } catch (error) {\r"
send "    res.status(401).json({ message: 'Недействительный токен' });\r"
send "  }\r"
send "};\r"
send "\r"
send "const isAuthor = (req, res, next) => {\r"
send "  if (req.user.role !== 'author' && req.user.role !== 'admin') {\r"
send "    return res.status(403).json({ message: 'Требуются права автора' });\r"
send "  }\r"
send "  next();\r"
send "};\r"
send "\r"
send "const isAdmin = (req, res, next) => {\r"
send "  if (req.user.role !== 'admin') {\r"
send "    return res.status(403).json({ message: 'Требуются права администратора' });\r"
send "  }\r"
send "  next();\r"
send "};\r"
send "\r"
send "module.exports = { auth, isAuthor, isAdmin };\r"
send "AUTHEND\r"
expect "# "
send "pm2 restart devblog\r"
expect "# "
send "sleep 5\r"
expect "# "
send "pm2 status\r"
expect "# "
send "curl -s http://localhost:5000/api/articles\r"
expect "# "
send "exit\r"
expect eof
ENDOFEXPECT

