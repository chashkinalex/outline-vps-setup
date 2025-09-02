# 🚀 Полное руководство по развертыванию Outline на VPS

Это комплексное руководство поможет вам развернуть Outline Wiki на выделенном VPS сервере с нуля.

## 📋 Содержание

1. [Предварительные требования](#предварительные-требования)
2. [Подготовка VPS](#подготовка-vps)
3. [Быстрая установка](#быстрая-установка)
4. [Пошаговая установка](#пошаговая-установка)
5. [Настройка Google OAuth](#настройка-google-oauth)
6. [Настройка мониторинга](#настройка-мониторинга)
7. [Безопасность](#безопасность)
8. [Обслуживание](#обслуживание)
9. [Устранение неполадок](#устранение-неполадок)

## 🔍 Предварительные требования

### Системные требования

- **ОС**: Ubuntu 20.04+ или Debian 11+
- **RAM**: Минимум 2GB (рекомендуется 4GB+)
- **Диск**: Минимум 20GB (рекомендуется 50GB+)
- **CPU**: 2+ ядра
- **Сеть**: Статический IP адрес

### Сетевые требования

- **Домен**: Настроенный на ваш VPS
- **DNS**: A-запись, указывающая на IP вашего VPS
- **Порты**: 22 (SSH), 80 (HTTP), 443 (HTTPS)

### Доступ

- **SSH**: Доступ по SSH с правами root
- **Файрвол**: Возможность настройки правил

## 🔧 Подготовка VPS

### 1. Подключение к серверу

```bash
ssh root@your-server-ip
```

### 2. Обновление системы

```bash
# Обновление списка пакетов
apt update

# Обновление системы
apt upgrade -y

# Перезагрузка (если необходимо)
reboot
```

### 3. Создание пользователя (рекомендуется)

```bash
# Создание пользователя
adduser outline-user

# Добавление в группу sudo
usermod -aG sudo outline-user

# Переключение на пользователя
su - outline-user
```

## ⚡ Быстрая установка

### 1. Клонирование проекта

```bash
# Создание рабочей директории
mkdir -p /opt/outline-setup
cd /opt/outline-setup

# Клонирование проекта
git clone https://github.com/your-username/outline-vps-setup.git .

# Или загрузка архива
wget https://github.com/your-username/outline-vps-setup/archive/main.zip
unzip main.zip
mv outline-vps-setup-main/* .
rm -rf outline-vps-setup-main main.zip
```

### 2. Настройка прав доступа

```bash
# Сделать скрипты исполняемыми
chmod +x deploy.sh
chmod +x scripts/*.sh

# Установка владельца
chown -R $USER:$USER /opt/outline-setup
```

### 3. Запуск автоматической установки

```bash
# Установка с автоматической настройкой SSL
./deploy.sh wiki.yourdomain.com

# Или без SSL
./deploy.sh wiki.yourdomain.com --no-ssl
```

## 🔧 Пошаговая установка

### Шаг 1: Базовая установка

```bash
# Запуск базовой установки
./scripts/install.sh full
```

Этот скрипт автоматически:
- Устанавливает Docker и Docker Compose
- Устанавливает Nginx
- Настраивает файрвол
- Создает необходимые директории
- Генерирует секретные ключи

### Шаг 2: Настройка SSL

```bash
# Настройка SSL для вашего домена
DOMAIN=wiki.yourdomain.com ./scripts/setup-ssl.sh
```

Этот скрипт:
- Получает SSL сертификат от Let's Encrypt
- Настраивает Nginx с SSL
- Настраивает автообновление сертификатов

### Шаг 3: Запуск Outline

```bash
# Переход в директорию Outline
cd /opt/outline

# Запуск сервисов
./scripts/install.sh start
```

## ⚙️ Настройка Google OAuth

### 1. Создание проекта в Google Cloud Console

1. Перейдите в [Google Cloud Console](https://console.cloud.google.com/)
2. Создайте новый проект
3. Включите Google+ API
4. Создайте OAuth 2.0 учетные данные

**Настройки OAuth:**
- **Type**: Web application
- **Authorized JavaScript origins**: `https://wiki.yourdomain.com`
- **Authorized redirect URIs**: `https://wiki.yourdomain.com/auth/google.callback`

### 2. Настройка переменных окружения

```bash
cd /opt/outline
nano .env
```

Обновите следующие строки:
```bash
GOOGLE_CLIENT_ID=your_google_client_id_here
GOOGLE_CLIENT_SECRET=your_google_client_secret_here
OUTLINE_URL=https://wiki.yourdomain.com
ADMIN_EMAIL=admin@yourdomain.com
```

### 3. Перезапуск Outline

```bash
docker-compose restart
```

## 📊 Настройка мониторинга

### 1. Установка инструментов мониторинга

```bash
# Установка базовых инструментов
apt install -y htop iotop nethogs iftop ncdu tree logwatch sysstat

# Включение системной статистики
systemctl enable sysstat
systemctl start sysstat
```

### 2. Настройка автоматического мониторинга

```bash
cd /opt/outline

# Системный мониторинг (каждые 5 минут)
(crontab -l 2>/dev/null; echo "*/5 * * * * /opt/outline/scripts/system-monitor.sh") | crontab -

# Docker мониторинг (каждые 2 минуты)
(crontab -l 2>/dev/null; echo "*/2 * * * * /opt/outline/scripts/docker-monitor.sh") | crontab -

# Веб-мониторинг (каждую минуту)
(crontab -l 2>/dev/null; echo "* * * * * /opt/outline/scripts/web-monitor.sh") | crontab -

# Мониторинг безопасности (каждые 10 минут)
(crontab -l 2>/dev/null; echo "*/10 * * * * /opt/outline/scripts/security-monitor.sh") | crontab -

# Сбор статистики (каждый час)
(crontab -l 2>/dev/null; echo "0 * * * * /opt/outline/scripts/collect-stats.sh") | crontab -
```

### 3. Настройка email уведомлений

```bash
# Установка Postfix
apt install -y postfix mailutils

# Настройка Postfix (выберите "Internet Site")
# Настройте домен и другие параметры

# Тестовая отправка
echo "Test email from Outline VPS" | mail -s "Test Email" admin@yourdomain.com
```

## 🔒 Безопасность

### 1. Настройка файрвола

```bash
# Проверка статуса UFW
ufw status

# Настройка правил по умолчанию
ufw default deny incoming
ufw default allow outgoing

# Разрешение SSH
ufw allow ssh

# Разрешение HTTP и HTTPS
ufw allow 80/tcp
ufw allow 443/tcp

# Разрешение Outline (только локально)
ufw allow from 127.0.0.1 to any port 3000

# Включение файрвола
ufw --force enable
```

### 2. Настройка Fail2ban

```bash
# Установка Fail2ban
apt install -y fail2ban

# Копирование конфигурации
cp /etc/fail2ban/jail.conf /etc/fail2ban/jail.local

# Настройка SSH защита
cat >> /etc/fail2ban/jail.local << EOF

[sshd]
enabled = true
port = ssh
filter = sshd
logpath = /var/log/auth.log
maxretry = 3
bantime = 3600
findtime = 600
EOF

# Запуск и включение Fail2ban
systemctl start fail2ban
systemctl enable fail2ban
```

### 3. Настройка SSH

```bash
# Резервная копия конфигурации
cp /etc/ssh/sshd_config /etc/ssh/sshd_config.backup

# Редактирование конфигурации
nano /etc/ssh/sshd_config
```

Рекомендуемые настройки:
```bash
# Отключение входа по паролю
PasswordAuthentication no

# Отключение входа root
PermitRootLogin no

# Изменение порта SSH (опционально)
Port 2222

# Ограничение пользователей
AllowUsers outline-user

# Таймаут неактивности
ClientAliveInterval 300
ClientAliveCountMax 2
```

```bash
# Перезапуск SSH
systemctl restart ssh

# Проверка конфигурации
sshd -t
```

## 📊 Обслуживание

### 1. Резервное копирование

```bash
cd /opt/outline

# Создание резервной копии
./scripts/backup.sh

# Проверка резервных копий
ls -la backups/

# Автоматическое резервное копирование (каждый день в 2:00)
(crontab -l 2>/dev/null; echo "0 2 * * * /opt/outline/scripts/backup.sh") | crontab -
```

### 2. Обновление

```bash
# Обновление Outline
docker-compose pull outline
docker-compose up -d outline

# Обновление зависимостей
docker-compose pull
docker-compose up -d

# Обновление системы
apt update && apt upgrade -y
```

### 3. Мониторинг ресурсов

```bash
# Просмотр использования ресурсов
htop

# Просмотр Docker статистики
docker stats

# Просмотр логов
docker-compose logs -f outline
tail -f /var/log/nginx/error.log
```

## 🆘 Устранение неполадок

### Основные команды диагностики

```bash
# Проверка статуса сервисов
systemctl status nginx docker
docker-compose ps

# Проверка логов
docker-compose logs outline
tail -f /var/log/nginx/error.log

# Проверка конфигурации
nginx -t
docker-compose config

# Проверка портов
netstat -tlnp | grep -E "(80|443|3000)"
```

### Частые проблемы

1. **Outline не запускается**
   ```bash
   # Проверка логов
   docker-compose logs outline
   
   # Проверка переменных окружения
   docker-compose exec outline env | grep -E "(SECRET|GOOGLE|URL)"
   ```

2. **SSL ошибки**
   ```bash
   # Проверка SSL сертификата
   certbot certificates
   
   # Обновление сертификатов
   certbot renew --dry-run
   ```

3. **Google OAuth не работает**
   ```bash
   # Проверка переменных
   docker-compose exec outline env | grep -E "(GOOGLE|OUTLINE_URL)"
   
   # Перезапуск Outline
   docker-compose restart outline
   ```

4. **Nginx не проксирует**
   ```bash
   # Проверка конфигурации
   nginx -t
   
   # Перезапуск Nginx
   systemctl restart nginx
   ```

### Просмотр логов мониторинга

```bash
# Системные логи
tail -f /var/log/outline-system.log

# Docker логи
tail -f /var/log/outline-docker.log

# Веб-логи
tail -f /var/log/outline-web.log

# Логи безопасности
tail -f /var/log/outline-security.log

# Логи алертов
tail -f /var/log/outline-alerts.log
```

## 🌐 Проверка установки

### 1. Проверка доступности

```bash
# HTTP
curl -I http://wiki.yourdomain.com

# HTTPS
curl -I https://wiki.yourdomain.com

# Outline API
curl -I https://wiki.yourdomain.com/api/auth.config
```

### 2. Проверка SSL

```bash
# Проверка SSL сертификата
openssl s_client -connect wiki.yourdomain.com:443 -servername wiki.yourdomain.com

# Проверка с внешнего сервера
curl -I https://wiki.yourdomain.com
```

### 3. Проверка мониторинга

```bash
# Проверка cron задач
crontab -l

# Проверка логов мониторинга
ls -la /var/log/outline-*.log

# Проверка статистики
ls -la /opt/outline/stats/
```

## 🎯 Следующие шаги

После успешной установки:

1. **Настройте команды** в Outline
2. **Добавьте пользователей** в систему
3. **Настройте права доступа** к документам
4. **Создайте первую страницу** wiki
5. **Настройте регулярные резервные копии**
6. **Настройте мониторинг** доступности
7. **Добавьте внешний мониторинг** (UptimeRobot, Pingdom)

## 📚 Дополнительные ресурсы

- [Настройка Google OAuth](docs/google-auth-setup.md)
- [Устранение неполадок](docs/troubleshooting.md)
- [Настройка мониторинга](docs/monitoring-setup.md)
- [Быстрый старт](QUICK_START.md)
- [Настройка GitHub](GITHUB_SETUP.md)

## 🆘 Поддержка

Если у вас возникли проблемы:

1. **Проверьте логи** и статус сервисов
2. **Обратитесь к документации** по устранению неполадок
3. **Создайте issue** в репозитории проекта
4. **Проверьте системные требования** и совместимость

---

**🎉 Поздравляем!** Теперь у вас есть полноценный Outline сервер с мониторингом, безопасностью и автоматическим обслуживанием.

**🚀 Ваш Outline VPS готов к работе!**
