#!/bin/bash

# Outline VPS Installation Script
# Этот скрипт автоматически устанавливает Outline на ваш VPS сервер

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
    echo -e "${RED}[$(date +'%%Y-%m-%d %H:%M:%S')] ERROR: $1${NC}"
    exit 1
}

# Проверка прав root
check_root() {
    if [[ $EUID -ne 0 ]]; then
        error "Этот скрипт должен быть запущен с правами root"
    fi
}

# Обновление системы
update_system() {
    log "Обновление системы..."
    apt update && apt upgrade -y
}

# Установка необходимых пакетов
install_packages() {
    log "Установка необходимых пакетов..."
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
}

# Установка Docker
install_docker() {
    log "Установка Docker..."
    
    if command -v docker &> /dev/null; then
        log "Docker уже установлен"
        return
    fi
    
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
    
    # Добавление текущего пользователя в группу docker
    usermod -aG docker $SUDO_USER
    
    log "Docker установлен успешно"
}

# Установка Docker Compose
install_docker_compose() {
    log "Установка Docker Compose..."
    
    if command -v docker-compose &> /dev/null; then
        log "Docker Compose уже установлен"
        return
    fi
    
    # Установка Docker Compose
    curl -L "https://github.com/docker/compose/releases/latest/download/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
    chmod +x /usr/local/bin/docker-compose
    
    log "Docker Compose установлен успешно"
}

# Настройка файрвола
setup_firewall() {
    log "Настройка файрвола..."
    
    ufw --force reset
    ufw default deny incoming
    ufw default allow outgoing
    
    # SSH
    ufw allow ssh
    
    # HTTP и HTTPS
    ufw allow 80/tcp
    ufw allow 443/tcp
    
    # Outline (только для локального доступа)
    ufw allow from 127.0.0.1 to any port 3000
    
    ufw --force enable
    log "Файрвол настроен"
}

# Настройка Nginx
setup_nginx() {
    log "Настройка Nginx..."
    
    # Создание конфигурации для Outline
    cat > /etc/nginx/sites-available/outline << 'EOF'
server {
    listen 80;
    server_name _;
    
    # Редирект на HTTPS
    return 301 https://$server_name$request_uri;
}

server {
    listen 443 ssl http2;
    server_name _;
    
    # SSL конфигурация будет добавлена certbot'ом
    
    # Проксирование на Outline
    location / {
        proxy_pass http://127.0.0.1:3000;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
        
        # WebSocket поддержка
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
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
}
EOF
    
    # Активация сайта
    ln -sf /etc/nginx/sites-available/outline /etc/nginx/sites-enabled/
    rm -f /etc/nginx/sites-enabled/default
    
    # Проверка конфигурации
    nginx -t
    
    # Перезапуск Nginx
    systemctl restart nginx
    systemctl enable nginx
    
    log "Nginx настроен"
}

# Создание директорий
create_directories() {
    log "Создание необходимых директорий..."
    
    mkdir -p /opt/outline/{logs,backups,uploads}
    mkdir -p /opt/outline/ssl
    
    # Установка прав
    chown -R $SUDO_USER:$SUDO_USER /opt/outline
    chmod -R 755 /opt/outline
}

# Генерация секретных ключей
generate_secrets() {
    log "Генерация секретных ключей..."
    
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
        
        log "Секретные ключи сгенерированы и сохранены в .env"
        warn "Пожалуйста, отредактируйте .env файл и настройте остальные переменные"
    else
        log "Файл .env уже существует"
    fi
}

# Запуск Outline
start_outline() {
    log "Запуск Outline..."
    
    # Остановка существующих контейнеров
    docker-compose down 2>/dev/null || true
    
    # Запуск сервисов
    docker-compose up -d
    
    log "Ожидание запуска сервисов..."
    sleep 30
    
    # Проверка статуса
    if docker-compose ps | grep -q "Up"; then
        log "Outline запущен успешно!"
        log "Приложение доступно по адресу: http://localhost:3000"
        log "База данных PostgreSQL доступна на localhost:5432"
        log "Redis доступен на localhost:6379"
    else
        error "Ошибка запуска Outline. Проверьте логи: docker-compose logs"
    fi
}

# Основная функция
main() {
    log "Начинаем установку Outline на VPS..."
    
    check_root
    update_system
    install_packages
    install_docker
    install_docker_compose
    setup_firewall
    setup_nginx
    create_directories
    generate_secrets
    
    log "Установка завершена!"
    log ""
    log "Следующие шаги:"
    log "1. Отредактируйте .env файл и настройте переменные"
    log "2. Настройте Google OAuth (см. docs/google-auth-setup.md)"
    log "3. Запустите: ./scripts/install.sh start"
    log "4. Настройте SSL сертификат: ./scripts/setup-ssl.sh"
    log ""
    log "Для получения помощи см. README.md"
}

# Обработка аргументов командной строки
case "${1:-}" in
    "start")
        start_outline
        ;;
    "full")
        main
        ;;
    *)
        main
        ;;
esac
