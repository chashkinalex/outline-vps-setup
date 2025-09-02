#!/bin/bash

# Outline Backup Script
# Этот скрипт создает резервные копии базы данных и файлов Outline

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

# Конфигурация
BACKUP_DIR="/opt/outline/backups"
RETENTION_DAYS=30
DATE=$(date +%Y%m%d_%H%M%S)
BACKUP_NAME="outline_backup_$DATE"

# Проверка прав root
check_root() {
    if [[ $EUID -ne 0 ]]; then
        error "Этот скрипт должен быть запущен с правами root"
    fi
}

# Создание директории для резервных копий
create_backup_dir() {
    log "Создание директории для резервных копий..."
    
    mkdir -p "$BACKUP_DIR"
    chown -R $SUDO_USER:$SUDO_USER "$BACKUP_DIR"
    chmod -R 755 "$BACKUP_DIR"
}

# Резервное копирование базы данных
backup_database() {
    log "Создание резервной копии базы данных..."
    
    # Проверка доступности PostgreSQL
    if ! docker-compose exec -T postgres pg_isready -U outline > /dev/null 2>&1; then
        error "PostgreSQL недоступен"
    fi
    
    # Создание резервной копии
    docker-compose exec -T postgres pg_dump \
        -U outline \
        -d outline \
        --format=custom \
        --verbose \
        --file="/backups/$BACKUP_NAME.sql"
    
    # Копирование файла из контейнера
    docker cp outline_postgres:/backups/$BACKUP_NAME.sql "$BACKUP_DIR/"
    
    # Удаление файла из контейнера
    docker-compose exec postgres rm -f "/backups/$BACKUP_NAME.sql"
    
    log "Резервная копия базы данных создана: $BACKUP_DIR/$BACKUP_NAME.sql"
}

# Резервное копирование файлов
backup_files() {
    log "Создание резервной копии файлов..."
    
    # Создание архива с файлами
    tar -czf "$BACKUP_DIR/${BACKUP_NAME}_files.tar.gz" \
        -C /opt/outline \
        uploads \
        logs \
        2>/dev/null || warn "Некоторые файлы не удалось скопировать"
    
    log "Резервная копия файлов создана: $BACKUP_DIR/${BACKUP_NAME}_files.tar.gz"
}

# Резервное копирование конфигурации
backup_config() {
    log "Создание резервной копии конфигурации..."
    
    # Создание архива с конфигурацией
    tar -czf "$BACKUP_DIR/${BACKUP_NAME}_config.tar.gz" \
        -C /opt/outline \
        .env \
        docker-compose.yml \
        2>/dev/null || warn "Некоторые конфигурационные файлы не удалось скопировать"
    
    log "Резервная копия конфигурации создана: $BACKUP_DIR/${BACKUP_NAME}_config.tar.gz"
}

# Создание общего архива
create_archive() {
    log "Создание общего архива..."
    
    cd "$BACKUP_DIR"
    
    # Создание архива со всеми резервными копиями
    tar -czf "${BACKUP_NAME}_full.tar.gz" \
        "${BACKUP_NAME}.sql" \
        "${BACKUP_NAME}_files.tar.gz" \
        "${BACKUP_NAME}_config.tar.gz" \
        2>/dev/null || warn "Не удалось создать общий архив"
    
    # Удаление отдельных файлов
    rm -f "${BACKUP_NAME}.sql" \
           "${BACKUP_NAME}_files.tar.gz" \
           "${BACKUP_NAME}_config.tar.gz"
    
    log "Общий архив создан: $BACKUP_DIR/${BACKUP_NAME}_full.tar.gz"
}

# Очистка старых резервных копий
cleanup_old_backups() {
    log "Очистка старых резервных копий (старше $RETENTION_DAYS дней)..."
    
    find "$BACKUP_DIR" -name "outline_backup_*" -type f -mtime +$RETENTION_DAYS -delete
    
    log "Старые резервные копии удалены"
}

# Проверка размера резервных копий
check_backup_size() {
    log "Проверка размера резервных копий..."
    
    total_size=$(du -sh "$BACKUP_DIR" | cut -f1)
    backup_count=$(find "$BACKUP_DIR" -name "outline_backup_*" -type f | wc -l)
    
    log "Общий размер резервных копий: $total_size"
    log "Количество резервных копий: $backup_count"
}

# Проверка целостности резервной копии
verify_backup() {
    log "Проверка целостности резервной копии..."
    
    cd "$BACKUP_DIR"
    
    if tar -tzf "${BACKUP_NAME}_full.tar.gz" > /dev/null 2>&1; then
        log "Резервная копия создана успешно и не повреждена"
    else
        error "Резервная копия повреждена!"
    fi
}

# Отправка уведомления (опционально)
send_notification() {
    # Здесь можно добавить отправку уведомлений
    # Например, через email, Slack, Telegram и т.д.
    log "Резервное копирование завершено успешно"
}

# Основная функция
main() {
    log "Начинаем резервное копирование Outline..."
    
    check_root
    create_backup_dir
    backup_database
    backup_files
    backup_config
    create_archive
    cleanup_old_backups
    verify_backup
    check_backup_size
    send_notification
    
    log ""
    log "Резервное копирование завершено!"
    log "Файл: $BACKUP_DIR/${BACKUP_NAME}_full.tar.gz"
    log ""
    log "Для восстановления используйте:"
    log "./scripts/restore.sh $BACKUP_NAME"
}

# Функция восстановления
restore() {
    local backup_name="$1"
    
    if [ -z "$backup_name" ]; then
        error "Укажите имя резервной копии для восстановления"
    fi
    
    local backup_file="$BACKUP_DIR/${backup_name}_full.tar.gz"
    
    if [ ! -f "$backup_file" ]; then
        error "Резервная копия $backup_name не найдена"
    fi
    
    log "Начинаем восстановление из резервной копии: $backup_name"
    
    # Остановка Outline
    log "Остановка Outline..."
    docker-compose down
    
    # Извлечение резервной копии
    log "Извлечение резервной копии..."
    cd "$BACKUP_DIR"
    tar -xzf "${backup_name}_full.tar.gz"
    
    # Восстановление базы данных
    log "Восстановление базы данных..."
    docker-compose up -d postgres
    sleep 10
    
    docker-compose exec -T postgres psql -U outline -d outline -c "DROP SCHEMA public CASCADE; CREATE SCHEMA public;"
    docker-compose exec -T postgres pg_restore -U outline -d outline "/backups/${backup_name}.sql"
    
    # Восстановление файлов
    log "Восстановление файлов..."
    tar -xzf "${backup_name}_files.tar.gz" -C /opt/outline/
    
    # Восстановление конфигурации
    log "Восстановление конфигурации..."
    tar -xzf "${backup_name}_config.tar.gz" -C /opt/outline/
    
    # Очистка временных файлов
    rm -f "${backup_name}.sql" \
           "${backup_name}_files.tar.gz" \
           "${backup_name}_config.tar.gz"
    
    # Запуск Outline
    log "Запуск Outline..."
    docker-compose up -d
    
    log "Восстановление завершено!"
    log "Outline должен быть доступен через несколько минут"
}

# Обработка аргументов командной строки
case "${1:-}" in
    "restore")
        restore "$2"
        ;;
    "cleanup")
        check_root
        create_backup_dir
        cleanup_old_backups
        check_backup_size
        ;;
    "verify")
        if [ -z "$2" ]; then
            error "Укажите имя резервной копии для проверки"
        fi
        cd "$BACKUP_DIR"
        if tar -tzf "${2}_full.tar.gz" > /dev/null 2>&1; then
            log "Резервная копия $2 не повреждена"
        else
            error "Резервная копия $2 повреждена!"
        fi
        ;;
    *)
        main
        ;;
esac
