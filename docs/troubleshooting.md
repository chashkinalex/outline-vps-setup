# Устранение неполадок Outline

Это руководство поможет решить наиболее распространенные проблемы при установке и настройке Outline на VPS сервере.

## Общие проблемы

### 1. Outline не запускается

#### Симптомы:
- Контейнер Outline не поднимается
- Ошибки в логах Docker
- Приложение недоступно по адресу

#### Диагностика:
```bash
# Проверка статуса контейнеров
docker-compose ps

# Просмотр логов Outline
docker-compose logs outline

# Проверка логов PostgreSQL
docker-compose logs postgres

# Проверка логов Redis
docker-compose logs redis
```

#### Решения:

**Проблема с базой данных:**
```bash
# Проверка подключения к PostgreSQL
docker-compose exec postgres pg_isready -U outline

# Перезапуск PostgreSQL
docker-compose restart postgres

# Проверка переменных окружения
docker-compose exec outline env | grep DATABASE_URL
```

**Проблема с Redis:**
```bash
# Проверка подключения к Redis
docker-compose exec redis redis-cli ping

# Перезапуск Redis
docker-compose restart redis
```

**Проблема с переменными окружения:**
```bash
# Проверка .env файла
cat .env

# Проверка загруженных переменных
docker-compose exec outline env | grep -E "(SECRET|GOOGLE|URL)"
```

### 2. Проблемы с Google OAuth

#### Симптомы:
- "Google OAuth is not configured"
- "Error: redirect_uri_mismatch"
- "Access denied"

#### Диагностика:
```bash
# Проверка переменных Google OAuth
docker-compose exec outline env | grep -E "(GOOGLE|OUTLINE_URL)"

# Проверка логов аутентификации
docker-compose logs outline | grep -i "google\|oauth\|auth"
```

#### Решения:

**Проверьте настройки в Google Cloud Console:**
1. Убедитесь, что `redirect_uri` в Google OAuth совпадает с `OUTLINE_URL/auth/google.callback`
2. Проверьте, что домен добавлен в "Authorized JavaScript origins"
3. Убедитесь, что API включен

**Проверьте переменные окружения:**
```bash
# В .env файле должны быть:
GOOGLE_CLIENT_ID=your_client_id
GOOGLE_CLIENT_SECRET=your_client_secret
OUTLINE_URL=https://your-domain.com
```

**Перезапустите Outline:**
```bash
docker-compose down
docker-compose up -d
```

### 3. Проблемы с SSL

#### Симптомы:
- "SSL certificate error"
- "Mixed content" ошибки
- Редирект не работает

#### Диагностика:
```bash
# Проверка SSL сертификата
openssl s_client -connect your-domain.com:443 -servername your-domain.com

# Проверка конфигурации Nginx
nginx -t

# Проверка логов Nginx
tail -f /var/log/nginx/error.log
```

#### Решения:

**Проверьте SSL сертификат:**
```bash
# Проверка статуса сертификатов Let's Encrypt
certbot certificates

# Обновление сертификатов
certbot renew --dry-run

# Получение нового сертификата
certbot certonly --standalone -d your-domain.com
```

**Проверьте конфигурацию Nginx:**
```bash
# Проверка синтаксиса
nginx -t

# Перезапуск Nginx
systemctl reload nginx
```

### 4. Проблемы с производительностью

#### Симптомы:
- Медленная загрузка страниц
- Таймауты
- Высокое потребление ресурсов

#### Диагностика:
```bash
# Проверка использования ресурсов
docker stats

# Проверка логов производительности
docker-compose logs outline | grep -i "slow\|timeout\|error"

# Проверка размера базы данных
docker-compose exec postgres psql -U outline -c "SELECT pg_size_pretty(pg_database_size('outline'));"
```

#### Решения:

**Оптимизация базы данных:**
```bash
# Анализ и вакуум базы данных
docker-compose exec postgres psql -U outline -c "VACUUM ANALYZE;"

# Проверка индексов
docker-compose exec postgres psql -U outline -c "SELECT schemaname, tablename, indexname FROM pg_indexes WHERE schemaname = 'public';"
```

**Оптимизация Redis:**
```bash
# Проверка памяти Redis
docker-compose exec redis redis-cli info memory

# Очистка кэша Redis
docker-compose exec redis redis-cli FLUSHALL
```

**Мониторинг ресурсов:**
```bash
# Установка htop для мониторинга
apt install htop

# Запуск мониторинга
htop
```

## Проблемы с базой данных

### 1. PostgreSQL не запускается

```bash
# Проверка логов PostgreSQL
docker-compose logs postgres

# Проверка прав доступа к директории данных
ls -la /opt/outline/

# Исправление прав доступа
chown -R 999:999 /opt/outline/
```

### 2. Ошибки подключения к базе данных

```bash
# Проверка переменных окружения
echo $DATABASE_URL

# Проверка доступности PostgreSQL
docker-compose exec postgres pg_isready -U outline

# Создание пользователя и базы данных
docker-compose exec postgres psql -U postgres -c "CREATE USER outline WITH PASSWORD 'your_password';"
docker-compose exec postgres psql -U postgres -c "CREATE DATABASE outline OWNER outline;"
```

### 3. Проблемы с миграциями

```bash
# Проверка статуса миграций
docker-compose exec outline npm run db:migrate:status

# Запуск миграций
docker-compose exec outline npm run db:migrate

# Откат миграций
docker-compose exec outline npm run db:migrate:rollback
```

## Проблемы с сетью

### 1. Файрвол блокирует доступ

```bash
# Проверка статуса UFW
ufw status

# Разрешение необходимых портов
ufw allow 80/tcp
ufw allow 443/tcp
ufw allow ssh

# Проверка правил
ufw status numbered
```

### 2. Nginx не проксирует запросы

```bash
# Проверка конфигурации Nginx
nginx -t

# Проверка статуса Nginx
systemctl status nginx

# Проверка логов ошибок
tail -f /var/log/nginx/error.log

# Перезапуск Nginx
systemctl restart nginx
```

### 3. Проблемы с DNS

```bash
# Проверка DNS записи
nslookup your-domain.com

# Проверка с внешнего сервера
dig your-domain.com @8.8.8.8

# Проверка локального резолвера
cat /etc/resolv.conf
```

## Проблемы с Docker

### 1. Docker не запускается

```bash
# Проверка статуса Docker
systemctl status docker

# Запуск Docker
systemctl start docker

# Проверка прав пользователя
groups $USER

# Добавление пользователя в группу docker
usermod -aG docker $USER
```

### 2. Проблемы с образами

```bash
# Очистка неиспользуемых образов
docker system prune -a

# Принудительное обновление образов
docker-compose pull --force

# Пересборка контейнеров
docker-compose up -d --build
```

### 3. Проблемы с томами

```bash
# Проверка томов
docker volume ls

# Проверка содержимого тома
docker run --rm -v outline_postgres_data:/data alpine ls -la /data

# Очистка томов
docker volume prune
```

## Проблемы с резервным копированием

### 1. Ошибки при создании резервных копий

```bash
# Проверка прав доступа
ls -la /opt/outline/backups/

# Создание директории для резервных копий
mkdir -p /opt/outline/backups
chown -R $USER:$USER /opt/outline/backups

# Проверка свободного места
df -h /opt/outline/
```

### 2. Проблемы с восстановлением

```bash
# Проверка целостности резервной копии
tar -tzf backup_file.tar.gz

# Проверка размера файла
ls -lh backup_file.tar.gz

# Проверка прав доступа к файлу
ls -la backup_file.tar.gz
```

## Мониторинг и логирование

### 1. Настройка логирования

```bash
# Создание директории для логов
mkdir -p /opt/outline/logs

# Настройка ротации логов
cat > /etc/logrotate.d/outline << EOF
/opt/outline/logs/*.log {
    daily
    missingok
    rotate 7
    compress
    delaycompress
    notifempty
    create 644 outline outline
}
EOF
```

### 2. Мониторинг доступности

```bash
# Создание скрипта проверки
cat > /opt/outline/scripts/health-check.sh << 'EOF'
#!/bin/bash
if ! curl -f -s http://localhost:3000/health > /dev/null; then
    echo "$(date): Outline недоступен" >> /var/log/outline-health.log
    docker-compose restart outline
fi
EOF

chmod +x /opt/outline/scripts/health-check.sh

# Добавление в cron
(crontab -l 2>/dev/null; echo "*/5 * * * * /opt/outline/scripts/health-check.sh") | crontab -
```

## Полезные команды для диагностики

### Системная информация
```bash
# Информация о системе
uname -a
cat /etc/os-release
free -h
df -h

# Информация о Docker
docker version
docker-compose version
docker info
```

### Проверка сервисов
```bash
# Статус всех сервисов
systemctl status nginx docker postgresql redis

# Проверка портов
netstat -tlnp
ss -tlnp

# Проверка процессов
ps aux | grep -E "(nginx|docker|outline)"
```

### Логи и отладка
```bash
# Логи в реальном времени
docker-compose logs -f
tail -f /var/log/nginx/access.log
tail -f /var/log/nginx/error.log

# Отладка Docker
docker-compose config
docker-compose ps
docker-compose top
```

## Получение помощи

Если проблема не решается:

1. **Соберите информацию:**
   - Логи ошибок
   - Конфигурационные файлы
   - Версии программного обеспечения

2. **Проверьте документацию:**
   - [Outline Documentation](https://docs.getoutline.com/)
   - [Docker Documentation](https://docs.docker.com/)
   - [Nginx Documentation](https://nginx.org/en/docs/)

3. **Обратитесь к сообществу:**
   - [Outline GitHub Issues](https://github.com/outline/outline/issues)
   - [Stack Overflow](https://stackoverflow.com/questions/tagged/outline-wiki)

4. **Создайте минимальный пример:**
   - Упростите конфигурацию
   - Уберите необязательные компоненты
   - Проверьте на чистой системе
