#!/bin/bash

# Outline VPS Quick Deploy Script
# Этот скрипт быстро разворачивает Outline на вашем VPS сервере

set -e

# Цвета для вывода
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Функция для логирования
log() {
    echo -e "${GREEN}[$(date +'%Y-%m-%d %H:%M:%S')] $1${NC}"
}

warn() {
    echo -e "${YELLOW}[$(date +'%Y-%m-%d %H:%M:%S')] WARNING: $1${NC}"
}

error() {
    echo -e "${RED}[$(date +'%Y-%m-%d %H:%M:%S')] ERROR: $1${NC}"
    exit 1
}

info() {
    echo -e "${BLUE}[$(date +'%Y-%m-%d %H:%M:%S')] INFO: $1${NC}"
}

# Проверка аргументов
if [ $# -eq 0 ]; then
    echo "Использование: $0 <domain> [options]"
    echo ""
    echo "Примеры:"
    echo "  $0 wiki.example.com                    # Базовая установка"
    echo "  $0 wiki.example.com --ssl-only        # Только настройка SSL"
    echo "  $0 wiki.example.com --full            # Полная установка с SSL"
    echo ""
    echo "Опции:"
    echo "  --ssl-only     Настроить только SSL (Outline уже установлен)"
    echo "  --full         Полная установка с SSL"
    echo "  --no-ssl       Установка без SSL"
    echo "  --help         Показать эту справку"
    exit 1
fi

# Парсинг аргументов
DOMAIN="$1"
SSL_ONLY=false
FULL_INSTALL=false
NO_SSL=false

shift
while [[ $# -gt 0 ]]; do
    case $1 in
        --ssl-only)
            SSL_ONLY=true
            shift
            ;;
        --full)
            FULL_INSTALL=true
            shift
            ;;
        --no-ssl)
            NO_SSL=true
            shift
            ;;
        --help)
            echo "Использование: $0 <domain> [options]"
            echo "См. справку выше"
            exit 0
            ;;
        *)
            error "Неизвестная опция: $1"
            ;;
    esac
    shift
done

# Проверка прав root
if [[ $EUID -ne 0 ]]; then
    error "Этот скрипт должен быть запущен с правами root"
fi

# Проверка домена
if [[ ! "$DOMAIN" =~ ^[a-zA-Z0-9][a-zA-Z0-9-]{1,61}[a-zA-Z0-9]\.[a-zA-Z]{2,}$ ]]; then
    error "Неверный формат домена: $DOMAIN"
fi

# Основная функция установки
install_outline() {
    log "Начинаем установку Outline на домен: $DOMAIN"
    
    # Обновление системы
    info "Обновление системы..."
    apt update && apt upgrade -y
    
    # Установка необходимых пакетов
    info "Установка необходимых пакетов..."
    apt install -y \
        curl \
        wget \
        git \
        unzip \
        software-properties-common \
        apt-transport-https \
        ca-certificates \
        gnupg \
        lsb-release \
        ufw \
        fail2ban \
        nginx \
        certbot \
        python3-certbot-nginx
    
    # Установка Docker
    info "Установка Docker..."
    if ! command -v docker &> /dev/null; then
        curl -fsSL https://download.docker.com/linux/ubuntu/gpg | gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg
        echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" | tee /etc/apt/sources.list.d/docker.list > /dev/null
        apt update
        apt install -y docker-ce docker-ce-cli containerd.io docker-compose-plugin
        systemctl start docker
        systemctl enable docker
        usermod -aG docker $SUDO_USER
    fi
    
    # Установка Docker Compose
    info "Установка Docker Compose..."
    if ! command -v docker-compose &> /dev/null; then
        curl -L "https://github.com/docker/compose/releases/latest/download/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
        chmod +x /usr/local/bin/docker-compose
    fi
    
    # Настройка файрвола
    info "Настройка файрвола..."
    ufw --force reset
    ufw default deny incoming
    ufw default allow outgoing
    ufw allow ssh
    ufw allow 80/tcp
    ufw allow 443/tcp
    ufw allow from 127.0.0.1 to any port 3000
    ufw --force enable
    
    # Создание директорий
    info "Создание директорий..."
    mkdir -p /opt/outline/{logs,backups,uploads,ssl}
    chown -R $SUDO_USER:$SUDO_USER /opt/outline
    chmod -R 755 /opt/outline
    
    # Копирование файлов проекта
    info "Копирование файлов проекта..."
    cp docker-compose.yml /opt/outline/
    cp env.example /opt/outline/
    cp -r scripts /opt/outline/
    cp -r docs /opt/outline/
    
    # Переход в директорию проекта
    cd /opt/outline
    
    # Генерация секретных ключей
    info "Генерация секретных ключей..."
    if [ ! -f .env ]; then
        cp env.example .env
        
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
        sed -i "s|https://your-domain.com|https://$DOMAIN|g" .env
        
        log "Секретные ключи сгенерированы и сохранены в .env"
    fi
    
    # Настройка Nginx
    info "Настройка Nginx..."
    cat > /etc/nginx/sites-available/outline << EOF
server {
    listen 80;
    server_name $DOMAIN;
    
    location / {
        proxy_pass http://127.0.0.1:3000;
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto \$scheme;
        
        proxy_http_version 1.1;
        proxy_set_header Upgrade \$http_upgrade;
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
    
    ln -sf /etc/nginx/sites-available/outline /etc/nginx/sites-enabled/
    rm -f /etc/nginx/sites-enabled/default
    nginx -t
    systemctl restart nginx
    systemctl enable nginx
    
    # Запуск Outline
    info "Запуск Outline..."
    docker-compose up -d
    
    log "Ожидание запуска сервисов..."
    sleep 30
    
    if docker-compose ps | grep -q "Up"; then
        log "Outline запущен успешно!"
    else
        error "Ошибка запуска Outline. Проверьте логи: docker-compose logs"
    fi
}

# Функция настройки SSL
setup_ssl() {
    log "Настройка SSL для домена: $DOMAIN"
    
    # Остановка Nginx для проверки домена
    systemctl stop nginx
    
    # Получение SSL сертификата
    info "Получение SSL сертификата от Let's Encrypt..."
    certbot certonly --standalone \
        --email admin@$DOMAIN \
        --agree-tos \
        --no-eff-email \
        -d $DOMAIN
    
    # Запуск Nginx
    systemctl start nginx
    
    # Настройка Nginx с SSL
    info "Настройка Nginx с SSL..."
    cat > /etc/nginx/sites-available/outline << EOF
server {
    listen 80;
    server_name $DOMAIN;
    return 301 https://\$server_name\$request_uri;
}

server {
    listen 443 ssl http2;
    server_name $DOMAIN;
    
    ssl_certificate /etc/letsencrypt/live/$DOMAIN/fullchain.pem;
    ssl_certificate_key /etc/letsencrypt/live/$DOMAIN/privkey.pem;
    
    ssl_protocols TLSv1.2 TLSv1.3;
    ssl_ciphers ECDHE-RSA-AES128-GCM-SHA256:ECDHE-RSA-AES256-GCM-SHA384:ECDHE-RSA-AES128-SHA256:ECDHE-RSA-AES256-SHA384;
    ssl_prefer_server_ciphers off;
    ssl_session_cache shared:SSL:10m;
    ssl_session_timeout 10m;
    
    add_header Strict-Transport-Security "max-age=31536000; includeSubDomains" always;
    
    location / {
        proxy_pass http://127.0.0.1:3000;
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto \$scheme;
        
        proxy_http_version 1.1;
        proxy_set_header Upgrade \$http_upgrade;
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
    
    nginx -t
    systemctl reload nginx
    
    # Настройка автообновления SSL
    info "Настройка автообновления SSL..."
    cat > /opt/outline/scripts/renew-ssl.sh << 'EOF'
#!/bin/bash
certbot renew --quiet --nginx
systemctl reload nginx
echo "$(date): SSL сертификаты обновлены" >> /var/log/ssl-renewal.log
EOF
    
    chmod +x /opt/outline/scripts/renew-ssl.sh
    (crontab -l 2>/dev/null; echo "0 12 * * * /opt/outline/scripts/renew-ssl.sh") | crontab -
    
    log "SSL настроен успешно!"
}

# Функция проверки
verify_installation() {
    log "Проверка установки..."
    
    # Проверка статуса сервисов
    info "Проверка статуса сервисов..."
    docker-compose ps
    
    # Проверка доступности
    info "Проверка доступности..."
    if curl -s -I "http://$DOMAIN" | grep -q "200 OK"; then
        log "Outline доступен по HTTP"
    else
        warn "Outline недоступен по HTTP"
    fi
    
    if [ "$NO_SSL" = false ]; then
        if curl -s -I "https://$DOMAIN" | grep -q "200 OK"; then
            log "Outline доступен по HTTPS"
        else
            warn "Outline недоступен по HTTPS"
        fi
    fi
    
    # Проверка SSL сертификата
    if [ "$NO_SSL" = false ]; then
        info "Проверка SSL сертификата..."
        echo | openssl s_client -servername $DOMAIN -connect $DOMAIN:443 2>/dev/null | openssl x509 -noout -dates
    fi
}

# Основная логика
main() {
    log "Outline VPS Quick Deploy Script"
    log "Домен: $DOMAIN"
    log "Режим: $([ "$SSL_ONLY" = true ] && echo "Только SSL" || ([ "$FULL_INSTALL" = true ] && echo "Полная установка" || echo "Базовая установка"))"
    log ""
    
    if [ "$SSL_ONLY" = true ]; then
        # Только настройка SSL
        if [ ! -f "/opt/outline/docker-compose.yml" ]; then
            error "Outline не установлен. Сначала выполните полную установку."
        fi
        cd /opt/outline
        setup_ssl
    else
        # Установка Outline
        install_outline
        
        if [ "$NO_SSL" = false ]; then
            setup_ssl
        fi
    fi
    
    verify_installation
    
    log ""
    log "🎉 Установка завершена!"
    log ""
    log "Outline доступен по адресу:"
    if [ "$NO_SSL" = false ]; then
        log "  https://$DOMAIN"
    else
        log "  http://$DOMAIN"
    fi
    log ""
    log "Следующие шаги:"
    log "1. Отредактируйте .env файл и настройте Google OAuth"
    log "2. См. docs/google-auth-setup.md для настройки аутентификации"
    log "3. Перезапустите Outline: docker-compose restart"
    log ""
    log "Полезные команды:"
    log "  docker-compose logs -f          # Просмотр логов"
    log "  docker-compose ps               # Статус сервисов"
    log "  docker-compose restart          # Перезапуск"
    log "  ./scripts/backup.sh            # Резервное копирование"
    log ""
    log "Для получения помощи см. docs/troubleshooting.md"
}

# Запуск основной функции
main
