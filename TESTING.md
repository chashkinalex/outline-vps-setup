# 🧪 Тестирование установки Outline

Это руководство поможет вам протестировать установку Outline и убедиться, что все работает корректно.

## 📋 Предварительные проверки

### 1. Проверка системных требований

```bash
# Проверка ОС
cat /etc/os-release

# Проверка RAM
free -h

# Проверка диска
df -h

# Проверка CPU
nproc
lscpu | grep "Model name"

# Проверка сети
ip addr show
ping -c 3 8.8.8.8
```

### 2. Проверка установленных сервисов

```bash
# Проверка Docker
docker --version
docker-compose --version
systemctl status docker

# Проверка Nginx
nginx -v
systemctl status nginx

# Проверка SSL сертификатов
certbot --version
certbot certificates
```

## 🐳 Тестирование Docker контейнеров

### 1. Проверка статуса контейнеров

```bash
cd /opt/outline

# Проверка статуса всех контейнеров
docker-compose ps

# Детальная информация о контейнерах
docker-compose ps --format "table {{.Name}}\t{{.Status}}\t{{.Ports}}\t{{.Size}}"
```

**Ожидаемый результат:**
```
Name              Status    Ports                    Size
outline_app       Up        0.0.0.0:3000->3000/tcp  123MB
outline_postgres  Up        127.0.0.1:5432->5432/tcp 45MB
outline_redis     Up        127.0.0.1:6379->6379/tcp 32MB
```

### 2. Проверка логов контейнеров

```bash
# Логи Outline
docker-compose logs outline --tail=20

# Логи PostgreSQL
docker-compose logs postgres --tail=20

# Логи Redis
docker-compose logs redis --tail=20

# Все логи в реальном времени
docker-compose logs -f
```

**Что искать:**
- ✅ Outline: "Server started on port 3000"
- ✅ PostgreSQL: "database system is ready to accept connections"
- ✅ Redis: "Ready to accept connections"

### 3. Проверка здоровья контейнеров

```bash
# Проверка Outline
curl -f http://localhost:3000/health

# Проверка PostgreSQL
docker-compose exec postgres pg_isready -U outline

# Проверка Redis
docker-compose exec redis redis-cli ping
```

## 🌐 Тестирование веб-сервисов

### 1. Проверка HTTP доступности

```bash
# Проверка HTTP
curl -I http://wiki.yourdomain.com

# Ожидаемый результат:
# HTTP/1.1 301 Moved Permanently
# Location: https://wiki.yourdomain.com/
```

### 2. Проверка HTTPS доступности

```bash
# Проверка HTTPS
curl -I https://wiki.yourdomain.com

# Ожидаемый результат:
# HTTP/1.1 200 OK
# Content-Type: text/html; charset=utf-8
```

### 3. Проверка SSL сертификата

```bash
# Проверка SSL
openssl s_client -connect wiki.yourdomain.com:443 -servername wiki.yourdomain.com

# Проверка с внешнего сервера
curl -I https://wiki.yourdomain.com
```

### 4. Проверка API endpoints

```bash
# Проверка конфигурации аутентификации
curl -I https://wiki.yourdomain.com/api/auth.config

# Проверка списка пользователей (должен вернуть 401 без аутентификации)
curl -I https://wiki.yourdomain.com/api/users.list

# Проверка списка коллекций (должен вернуть 401 без аутентификации)
curl -I https://wiki.yourdomain.com/api/collections.list
```

## 🔐 Тестирование аутентификации

### 1. Проверка Google OAuth

```bash
# Проверка переменных окружения
docker-compose exec outline env | grep -E "(GOOGLE|OUTLINE_URL)"

# Проверка логов аутентификации
docker-compose logs outline | grep -i "google\|oauth\|auth"
```

### 2. Тестирование входа

1. Откройте `https://wiki.yourdomain.com` в браузере
2. Нажмите "Sign in with Google"
3. Выберите Google аккаунт
4. Разрешите доступ приложению
5. Должны быть перенаправлены обратно в Outline

## 📊 Тестирование мониторинга

### 1. Проверка скриптов мониторинга

```bash
# Проверка системного мониторинга
/opt/outline/scripts/system-monitor.sh

# Проверка Docker мониторинга
/opt/outline/scripts/docker-monitor.sh

# Проверка веб-мониторинга
/opt/outline/scripts/web-monitor.sh

# Проверка мониторинга безопасности
/opt/outline/scripts/security-monitor.sh
```

### 2. Проверка cron задач

```bash
# Просмотр всех cron задач
crontab -l

# Проверка логов cron
grep CRON /var/log/syslog
```

### 3. Проверка логов мониторинга

```bash
# Проверка наличия логов
ls -la /var/log/outline-*.log

# Просмотр последних записей
tail -20 /var/log/outline-system.log
tail -20 /var/log/outline-docker.log
tail -20 /var/log/outline-web.log
tail -20 /var/log/outline-security.log
```

## 🔒 Тестирование безопасности

### 1. Проверка файрвола

```bash
# Статус UFW
ufw status

# Проверка правил
ufw status numbered

# Проверка открытых портов
netstat -tlnp | grep LISTEN
ss -tlnp
```

**Ожидаемые открытые порты:**
- 22 (SSH)
- 80 (HTTP)
- 443 (HTTPS)
- 3000 (только локально)

### 2. Проверка Fail2ban

```bash
# Статус Fail2ban
systemctl status fail2ban

# Статус jail'ов
fail2ban-client status

# Проверка заблокированных IP
fail2ban-client status sshd
```

### 3. Проверка SSH безопасности

```bash
# Проверка конфигурации SSH
sshd -t

# Проверка настроек
grep -E "(PasswordAuthentication|PermitRootLogin|AllowUsers)" /etc/ssh/sshd_config
```

## 💾 Тестирование резервного копирования

### 1. Создание тестовой резервной копии

```bash
cd /opt/outline

# Создание резервной копии
./scripts/backup.sh

# Проверка создания файла
ls -la backups/
```

### 2. Проверка целостности резервной копии

```bash
# Проверка архива
cd backups
tar -tzf outline_backup_*.tar.gz

# Проверка размера
ls -lh outline_backup_*.tar.gz
```

### 3. Тестирование восстановления (опционально)

```bash
# ВНИМАНИЕ: Это перезапишет текущие данные!
# Выполняйте только в тестовой среде

# ./scripts/backup.sh restore backup_name
```

## 📈 Тестирование производительности

### 1. Проверка системных ресурсов

```bash
# Мониторинг в реальном времени
htop

# Docker статистика
docker stats

# Проверка нагрузки
uptime
```

### 2. Тестирование времени ответа

```bash
# Тест времени ответа
curl -w "@-" -o /dev/null -s "https://wiki.yourdomain.com" << 'EOF'
     time_namelookup:  %{time_namelookup}\n
        time_connect:  %{time_connect}\n
     time_appconnect:  %{time_appconnect}\n
    time_pretransfer:  %{time_pretransfer}\n
       time_redirect:  %{time_redirect}\n
  time_starttransfer:  %{time_starttransfer}\n
                     ----------\n
          time_total:  %{time_total}\n
EOF
```

### 3. Нагрузочное тестирование (опционально)

```bash
# Установка Apache Bench
apt install -y apache2-utils

# Тест с 10 запросами и 5 параллельными соединениями
ab -n 10 -c 5 https://wiki.yourdomain.com/
```

## 🧹 Тестирование очистки

### 1. Проверка ротации логов

```bash
# Проверка logrotate
logrotate -d /etc/logrotate.d/outline

# Проверка размера логов
du -sh /var/log/outline-*.log
```

### 2. Проверка очистки резервных копий

```bash
# Проверка политики хранения
find /opt/outline/backups -name "outline_backup_*" -mtime +30

# Проверка статистики
find /opt/outline/stats -name "system-stats-*" -mtime +30
```

## 📝 Создание отчета о тестировании

### 1. Автоматический отчет

```bash
cat > /opt/outline/scripts/generate-test-report.sh << 'EOF'
#!/bin/bash

# Генерация отчета о тестировании
REPORT_FILE="/opt/outline/test-report-$(date +%Y%m%d_%H%M%S).txt"

echo "=== Outline VPS Test Report ===" > "$REPORT_FILE"
echo "Date: $(date)" >> "$REPORT_FILE"
echo "Hostname: $(hostname)" >> "$REPORT_FILE"
echo "" >> "$REPORT_FILE"

echo "=== System Information ===" >> "$REPORT_FILE"
uname -a >> "$REPORT_FILE"
echo "" >> "$REPORT_FILE"

echo "=== Docker Status ===" >> "$REPORT_FILE"
cd /opt/outline
docker-compose ps >> "$REPORT_FILE"
echo "" >> "$REPORT_FILE"

echo "=== Service Status ===" >> "$REPORT_FILE"
systemctl status nginx docker fail2ban --no-pager -l >> "$REPORT_FILE"
echo "" >> "$REPORT_FILE"

echo "=== Network Status ===" >> "$REPORT_FILE"
netstat -tlnp | grep -E "(80|443|3000)" >> "$REPORT_FILE"
echo "" >> "$REPORT_FILE"

echo "=== SSL Certificate ===" >> "$REPORT_FILE"
certbot certificates >> "$REPORT_FILE"
echo "" >> "$REPORT_FILE"

echo "=== Recent Logs ===" >> "$REPORT_FILE"
tail -50 /var/log/outline-system.log >> "$REPORT_FILE"
echo "" >> "$REPORT_FILE"

echo "Report generated: $REPORT_FILE"
EOF

chmod +x /opt/outline/scripts/generate-test-report.sh
```

### 2. Запуск генерации отчета

```bash
cd /opt/outline
./scripts/generate-test-report.sh

# Просмотр отчета
cat test-report-*.txt
```

## 🎯 Критерии успешного тестирования

### ✅ Обязательные проверки

- [ ] Все Docker контейнеры запущены и работают
- [ ] Outline доступен по HTTPS
- [ ] SSL сертификат действителен
- [ ] Google OAuth настроен и работает
- [ ] Файрвол активен и правильно настроен
- [ ] Fail2ban работает
- [ ] Мониторинг активен и собирает данные
- [ ] Резервное копирование работает

### ✅ Рекомендуемые проверки

- [ ] Время ответа < 2 секунд
- [ ] Все API endpoints отвечают корректно
- [ ] Логи ротируются автоматически
- [ ] Старые резервные копии удаляются
- [ ] Email уведомления работают
- [ ] Система выдерживает базовую нагрузку

## 🆘 Устранение проблем тестирования

### Проблема: Контейнеры не запускаются

```bash
# Проверка логов
docker-compose logs

# Проверка переменных окружения
docker-compose config

# Перезапуск
docker-compose down
docker-compose up -d
```

### Проблема: SSL не работает

```bash
# Проверка сертификата
certbot certificates

# Получение нового сертификата
certbot certonly --standalone -d wiki.yourdomain.com

# Перезапуск Nginx
systemctl restart nginx
```

### Проблема: Мониторинг не работает

```bash
# Проверка cron задач
crontab -l

# Проверка прав на скрипты
ls -la /opt/outline/scripts/

# Ручной запуск скриптов
/opt/outline/scripts/system-monitor.sh
```

## 🎉 Заключение

После успешного прохождения всех тестов ваш Outline VPS готов к продакшену!

**Следующие шаги:**
1. Настройте команды и пользователей в Outline
2. Создайте первую документацию
3. Настройте регулярные резервные копии
4. Добавьте внешний мониторинг
5. Документируйте конфигурацию

---

**🧪 Тестирование завершено успешно! Ваш Outline VPS работает корректно.**
