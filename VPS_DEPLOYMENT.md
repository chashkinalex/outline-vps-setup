# 🚀 Развертывание Outline на VPS

Это подробное руководство по развертыванию Outline Wiki на выделенном VPS сервере.

## 📋 Предварительные требования

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

### 3. Создание пользователя (опционально, но рекомендуется)

```bash
# Создание пользователя
adduser outline-user

# Добавление в группу sudo
usermod -aG sudo outline-user

# Переключение на пользователя
su - outline-user
```

## 📥 Установка проекта

### 1. Клонирование репозитория

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

## 🚀 Автоматическая установка

### 1. Быстрая установка (рекомендуется)

```bash
# Установка с автоматической настройкой SSL
./deploy.sh wiki.yourdomain.com

# Или без SSL
./deploy.sh wiki.yourdomain.com --no-ssl
```

### 2. Пошаговая установка

```bash
# Шаг 1: Базовая установка
./scripts/install.sh full

# Шаг 2: Настройка SSL
DOMAIN=wiki.yourdomain.com ./scripts/setup-ssl.sh

# Шаг 3: Запуск Outline
cd /opt/outline
./scripts/install.sh start
```

## ⚙️ Ручная настройка

### 1. Установка Docker

```bash
# Установка зависимостей
apt install -y \
    apt-transport-https \
    ca-certificates \
    curl \
    gnupg \
    lsb-release

# Добавление GPG ключа Docker
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg

# Добавление репозитория Docker
echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" | tee /etc/apt/sources.list.d/docker.list > /dev/null

# Установка Docker
apt update
apt install -y docker-ce docker-ce-cli containerd.io docker-compose-plugin

# Запуск и включение Docker
systemctl start docker
systemctl enable docker

# Добавление пользователя в группу docker
usermod -aG docker $USER
```

### 2. Установка Docker Compose

```bash
# Установка Docker Compose
curl -L "https://github.com/docker/compose/releases/latest/download/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
chmod +x /usr/local/bin/docker-compose

# Проверка установки
docker-compose --version
```

### 3. Установка Nginx

```bash
# Установка Nginx
apt install -y nginx

# Запуск и включение Nginx
systemctl start nginx
systemctl enable nginx

# Проверка статуса
systemctl status nginx
```

### 4. Установка Certbot

```bash
# Установка Certbot
apt install -y certbot python3-certbot-nginx

# Проверка установки
certbot --version
```

## 🔐 Настройка безопасности

### 1. Настройка файрвола (UFW)

```bash
# Установка UFW
apt install -y ufw

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

# Проверка статуса
ufw status
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

# Проверка статуса
fail2ban-client status
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

## 🌐 Настройка DNS

### 1. Настройка A-записи

В панели управления вашего домена создайте A-запись:

```
Тип: A
Имя: wiki (или поддомен по вашему выбору)
Значение: IP-адрес вашего VPS
TTL: 300 (или по умолчанию)
```

### 2. Проверка DNS

```bash
# Проверка с вашего сервера
nslookup wiki.yourdomain.com

# Проверка с внешнего сервера
dig wiki.yourdomain.com @8.8.8.8

# Проверка с внешнего сервера
nslookup wiki.yourdomain.com 8.8.8.8
```

## 📁 Создание структуры директорий

```bash
# Создание основных директорий
mkdir -p /opt/outline/{logs,backups,uploads,ssl}

# Установка прав доступа
chown -R $USER:$USER /opt/outline
chmod -R 755 /opt/outline

# Создание директории для логов
mkdir -p /var/log/outline
chown -R $USER:$USER /var/log/outline
```

## 🔧 Настройка переменных окружения

### 1. Создание .env файла

```bash
cd /opt/outline
cp env.example .env
nano .env
```

### 2. Основные переменные

```bash
# База данных
POSTGRES_PASSWORD=your_secure_password_here

# Секретные ключи (автоматически генерируются)
SECRET_KEY=your_secret_key_here_min_32_chars
UTILS_SECRET=your_utils_secret_here_min_32_chars
SESSION_SECRET=your_session_secret_here_min_32_chars
COOKIE_SECRET=your_cookie_secret_here_min_32_chars

# URL приложения
OUTLINE_URL=https://wiki.yourdomain.com

# Google OAuth
GOOGLE_CLIENT_ID=your_google_client_id_here
GOOGLE_CLIENT_SECRET=your_google_client_secret_here

# Администратор
ADMIN_EMAIL=admin@yourdomain.com

# Функции
ENABLE_REGISTRATION=false
ENABLE_ANALYTICS=false
```

### 3. Генерация секретных ключей

```bash
# Генерация случайных секретов
SECRET_KEY=$(openssl rand -hex 32)
UTILS_SECRET=$(openssl rand -hex 32)
SESSION_SECRET=$(openssl rand -hex 32)
COOKIE_SECRET=$(openssl rand -hex 32)
POSTGRES_PASSWORD=$(openssl rand -hex 16)

# Замена в .env файле
sed -i "s/your_secret_key_here_min_32_chars/$SECRET_KEY/g" .env
sed -i "s/your_utils_secret_here_min_32_chars/$UTILS_SECRET/g" .env
sed -i "s/your_session_secret_here_min_32_chars/$SESSION_SECRET/g" .env
sed -i "s/your_cookie_secret_here_min_32_chars/$COOKIE_SECRET/g" .env
sed -i "s/your_secure_postgres_password_here/$POSTGRES_PASSWORD/g" .env
```

## 🐳 Запуск Docker контейнеров

### 1. Копирование файлов

```bash
# Копирование docker-compose.yml
cp /opt/outline-setup/docker-compose.yml /opt/outline/

# Копирование скриптов
cp -r /opt/outline-setup/scripts /opt/outline/
cp -r /opt/outline-setup/docs /opt/outline/

# Установка прав
chmod +x /opt/outline/scripts/*.sh
```

### 2. Запуск сервисов

```bash
cd /opt/outline

# Запуск в фоновом режиме
docker-compose up -d

# Проверка статуса
docker-compose ps

# Просмотр логов
docker-compose logs -f
```

### 3. Проверка запуска

```bash
# Проверка контейнеров
docker-compose ps

# Проверка логов
docker-compose logs outline

# Проверка доступности
curl -I http://localhost:3000
```

## 🌐 Настройка Nginx

### 1. Создание конфигурации

```bash
# Создание конфигурации для Outline
cat > /etc/nginx/sites-available/outline << 'EOF'
server {
    listen 80;
    server_name wiki.yourdomain.com;
    
    location / {
        proxy_pass http://127.0.0.1:3000;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
        
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection "upgrade";
        
        proxy_connect_timeout 60s;
        proxy_send_timeout 60s;
        proxy_read_timeout 60s;
    }
    
    location /static/ {
        proxy_pass http://127.0.0.1:3000;
        expires 1y;
        add_header Cache-Control "public, immutable";
    }
    
    location /uploads/ {
        proxy_pass http://127.0.0.1:3000;
        expires 1y;
        add_header Cache-Control "public, immutable";
    }
}
EOF
```

### 2. Активация сайта

```bash
# Активация сайта
ln -sf /etc/nginx/sites-available/outline /etc/nginx/sites-enabled/

# Удаление дефолтного сайта
rm -f /etc/nginx/sites-enabled/default

# Проверка конфигурации
nginx -t

# Перезапуск Nginx
systemctl reload nginx
```

## 🔒 Настройка SSL

### 1. Получение сертификата

```bash
# Остановка Nginx для проверки домена
systemctl stop nginx

# Получение SSL сертификата
certbot certonly --standalone \
    --email admin@yourdomain.com \
    --agree-tos \
    --no-eff-email \
    -d wiki.yourdomain.com

# Запуск Nginx
systemctl start nginx
```

### 2. Обновление конфигурации Nginx

```bash
# Создание конфигурации с SSL
cat > /etc/nginx/sites-available/outline << 'EOF'
server {
    listen 80;
    server_name wiki.yourdomain.com;
    return 301 https://$server_name$request_uri;
}

server {
    listen 443 ssl http2;
    server_name wiki.yourdomain.com;
    
    ssl_certificate /etc/letsencrypt/live/wiki.yourdomain.com/fullchain.pem;
    ssl_certificate_key /etc/letsencrypt/live/wiki.yourdomain.com/privkey.pem;
    
    ssl_protocols TLSv1.2 TLSv1.3;
    ssl_ciphers ECDHE-RSA-AES128-GCM-SHA256:ECDHE-RSA-AES256-GCM-SHA384:ECDHE-RSA-AES128-SHA256:ECDHE-RSA-AES256-SHA384;
    ssl_prefer_server_ciphers off;
    ssl_session_cache shared:SSL:10m;
    ssl_session_timeout 10m;
    
    add_header Strict-Transport-Security "max-age=31536000; includeSubDomains" always;
    
    location / {
        proxy_pass http://127.0.0.1:3000;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
        
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection "upgrade";
        
        proxy_connect_timeout 60s;
        proxy_send_timeout 60s;
        proxy_read_timeout 60s;
    }
    
    location /static/ {
        proxy_pass http://127.0.0.1:3000;
        expires 1y;
        add_header Cache-Control "public, immutable";
    }
    
    location /uploads/ {
        proxy_pass http://127.0.0.1:3000;
        expires 1y;
        add_header Cache-Control "public, immutable";
    }
    
    location /.well-known/acme-challenge/ {
        root /var/www/html;
    }
}
EOF
```

### 3. Применение конфигурации

```bash
# Проверка конфигурации
nginx -t

# Перезапуск Nginx
systemctl reload nginx

# Настройка автообновления
echo "0 12 * * * /usr/bin/certbot renew --quiet --nginx" | crontab -
```

## ✅ Проверка установки

### 1. Проверка сервисов

```bash
# Статус всех сервисов
systemctl status nginx docker

# Статус Docker контейнеров
docker-compose ps

# Проверка портов
netstat -tlnp | grep -E "(80|443|3000)"
```

### 2. Проверка доступности

```bash
# HTTP
curl -I http://wiki.yourdomain.com

# HTTPS
curl -I https://wiki.yourdomain.com

# Outline API
curl -I https://wiki.yourdomain.com/api/auth.config
```

### 3. Проверка SSL

```bash
# Проверка SSL сертификата
openssl s_client -connect wiki.yourdomain.com:443 -servername wiki.yourdomain.com

# Проверка с внешнего сервера
curl -I https://wiki.yourdomain.com
```

## 🔧 Настройка Google OAuth

### 1. Создание проекта в Google Cloud Console

1. Перейдите в [Google Cloud Console](https://console.cloud.google.com/)
2. Создайте новый проект
3. Включите Google+ API
4. Создайте OAuth 2.0 учетные данные

### 2. Настройка переменных

```bash
cd /opt/outline
nano .env
```

Обновите:
```bash
GOOGLE_CLIENT_ID=your_client_id
GOOGLE_CLIENT_SECRET=your_client_secret
OUTLINE_URL=https://wiki.yourdomain.com
```

### 3. Перезапуск Outline

```bash
docker-compose restart outline
```

## 📊 Мониторинг и обслуживание

### 1. Просмотр логов

```bash
# Логи Outline
docker-compose logs -f outline

# Логи Nginx
tail -f /var/log/nginx/access.log
tail -f /var/log/nginx/error.log

# Логи системы
journalctl -u nginx -f
journalctl -u docker -f
```

### 2. Резервное копирование

```bash
# Создание резервной копии
cd /opt/outline
./scripts/backup.sh

# Проверка резервных копий
ls -la backups/
```

### 3. Обновление

```bash
# Обновление Outline
docker-compose pull outline
docker-compose up -d outline

# Обновление системы
apt update && apt upgrade -y
```

## 🆘 Устранение неполадок

### Основные команды диагностики

```bash
# Проверка статуса
systemctl status nginx docker
docker-compose ps

# Проверка логов
docker-compose logs outline
tail -f /var/log/nginx/error.log

# Проверка конфигурации
nginx -t
docker-compose config
```

### Частые проблемы

1. **Outline не запускается** → Проверьте логи: `docker-compose logs outline`
2. **SSL ошибки** → Проверьте сертификат: `certbot certificates`
3. **Google OAuth не работает** → Проверьте переменные в `.env`
4. **Nginx не проксирует** → Проверьте конфигурацию: `nginx -t`

## 🎯 Следующие шаги

После успешной установки:

1. **Настройте команды** в Outline
2. **Добавьте пользователей** в систему
3. **Настройте права доступа** к документам
4. **Создайте первую страницу** wiki
5. **Настройте регулярные резервные копии**
6. **Настройте мониторинг** доступности

---

**🎉 Поздравляем!** Теперь у вас есть собственный Outline сервер для командной работы с документами.
