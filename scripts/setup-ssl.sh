#!/bin/bash

# Outline SSL Setup Script
# Этот скрипт настраивает SSL сертификаты для Outline

set -e

# Цвета для вывода
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
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

# Проверка прав root
check_root() {
    if [[ $EUID -ne 0 ]]; then
        error "Этот скрипт должен быть запущен с правами root"
    fi
}

# Проверка наличия домена
check_domain() {
    if [ -z "$DOMAIN" ]; then
        error "Пожалуйста, укажите домен: DOMAIN=your-domain.com ./scripts/setup-ssl.sh"
    fi
    
    log "Настройка SSL для домена: $DOMAIN"
}

# Настройка Nginx для домена
setup_nginx_domain() {
    log "Настройка Nginx для домена $DOMAIN..."
    
    # Обновление конфигурации Nginx
    sed -i "s/server_name _;/server_name $DOMAIN;/g" /etc/nginx/sites-available/outline
    
    # Перезапуск Nginx
    nginx -t
    systemctl reload nginx
    
    log "Nginx настроен для домена $DOMAIN"
}

# Получение SSL сертификата
obtain_ssl_certificate() {
    log "Получение SSL сертификата от Let's Encrypt..."
    
    # Остановка Nginx для проверки домена
    systemctl stop nginx
    
    # Получение сертификата
    certbot certonly --standalone \
        --email admin@$DOMAIN \
        --agree-tos \
        --no-eff-email \
        -d $DOMAIN
    
    # Запуск Nginx
    systemctl start nginx
    
    log "SSL сертификат получен успешно"
}

# Настройка Nginx с SSL
configure_nginx_ssl() {
    log "Настройка Nginx с SSL..."
    
    # Создание конфигурации с SSL
    cat > /etc/nginx/sites-available/outline << EOF
server {
    listen 80;
    server_name $DOMAIN;
    
    # Редирект на HTTPS
    return 301 https://\$server_name\$request_uri;
}

server {
    listen 443 ssl http2;
    server_name $DOMAIN;
    
    # SSL конфигурация
    ssl_certificate /etc/letsencrypt/live/$DOMAIN/fullchain.pem;
    ssl_certificate_key /etc/letsencrypt/live/$DOMAIN/privkey.pem;
    
    # SSL настройки
    ssl_protocols TLSv1.2 TLSv1.3;
    ssl_ciphers ECDHE-RSA-AES128-GCM-SHA256:ECDHE-RSA-AES256-GCM-SHA384:ECDHE-RSA-AES128-SHA256:ECDHE-RSA-AES256-SHA384;
    ssl_prefer_server_ciphers off;
    ssl_session_cache shared:SSL:10m;
    ssl_session_timeout 10m;
    
    # HSTS
    add_header Strict-Transport-Security "max-age=31536000; includeSubDomains" always;
    
    # Проксирование на Outline
    location / {
        proxy_pass http://127.0.0.1:3000;
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto \$scheme;
        
        # WebSocket поддержка
        proxy_http_version 1.1;
        proxy_set_header Upgrade \$http_upgrade;
        proxy_set_header Connection "upgrade";
        
        # Таймауты
        proxy_connect_timeout 60s;
        proxy_send_timeout 60s;
        proxy_read_timeout 60s;
    }
    
    # Статические файлы
    location /static/ {
        proxy_pass http://127.0.0.1:3000;
        expires 1y;
        add_header Cache-Control "public, immutable";
    }
    
    # Загрузки
    location /uploads/ {
        proxy_pass http://127.0.0.1:3000;
        expires 1y;
        add_header Cache-Control "public, immutable";
    }
    
    # Let's Encrypt challenge
    location /.well-known/acme-challenge/ {
        root /var/www/html;
    }
}
EOF
    
    # Проверка конфигурации
    nginx -t
    
    # Перезапуск Nginx
    systemctl reload nginx
    
    log "Nginx настроен с SSL"
}

# Настройка автообновления сертификатов
setup_auto_renewal() {
    log "Настройка автообновления SSL сертификатов..."
    
    # Создание скрипта обновления
    cat > /opt/outline/scripts/renew-ssl.sh << 'EOF'
#!/bin/bash

# Обновление SSL сертификатов
certbot renew --quiet --nginx

# Перезапуск Nginx
systemctl reload nginx

# Логирование
echo "$(date): SSL сертификаты обновлены" >> /var/log/ssl-renewal.log
EOF
    
    chmod +x /opt/outline/scripts/renew-ssl.sh
    
    # Добавление в cron для ежедневной проверки
    (crontab -l 2>/dev/null; echo "0 12 * * * /opt/outline/scripts/renew-ssl.sh") | crontab -
    
    log "Автообновление SSL настроено"
}

# Проверка SSL
test_ssl() {
    log "Проверка SSL конфигурации..."
    
    # Проверка доступности по HTTPS
    if curl -s -I "https://$DOMAIN" | grep -q "200 OK"; then
        log "SSL работает корректно!"
        log "Outline доступен по адресу: https://$DOMAIN"
    else
        warn "SSL может работать некорректно. Проверьте логи Nginx"
    fi
    
    # Проверка SSL сертификата
    echo | openssl s_client -servername $DOMAIN -connect $DOMAIN:443 2>/dev/null | openssl x509 -noout -dates
}

# Основная функция
main() {
    log "Настройка SSL для Outline..."
    
    check_root
    check_domain
    setup_nginx_domain
    obtain_ssl_certificate
    configure_nginx_ssl
    setup_auto_renewal
    test_ssl
    
    log ""
    log "SSL настройка завершена!"
    log "Outline доступен по адресу: https://$DOMAIN"
    log ""
    log "Следующие шаги:"
    log "1. Обновите .env файл: OUTLINE_URL=https://$DOMAIN"
    log "2. Перезапустите Outline: docker-compose restart"
    log "3. Настройте Google OAuth для домена $DOMAIN"
}

# Проверка аргументов
if [ -z "$DOMAIN" ]; then
    echo "Использование: DOMAIN=your-domain.com ./scripts/setup-ssl.sh"
    echo ""
    echo "Пример:"
    echo "DOMAIN=wiki.example.com ./scripts/setup-ssl.sh"
    exit 1
fi

main
