#!/bin/sh

# Устанавливаем права на файл cron
chmod 0644 /etc/cron.d/my-cron

# Применяем crontab
crontab /etc/cron.d/my-cron

# Создаем лог-файл и даем права
touch /var/log/cron.log
chmod 0666 /var/log/cron.log

# Запускаем cron в фоновом режиме
cron

# Запускаем основное приложение в основном потоке.
echo "Starting Node.js application..."
exec npm start
