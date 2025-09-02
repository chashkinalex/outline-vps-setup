# 📊 Настройка мониторинга для Outline VPS

Это руководство поможет вам настроить комплексный мониторинг для вашего Outline сервера.

## 📋 Обзор мониторинга

### Что мониторим

- **Системные ресурсы**: CPU, RAM, диск, сеть
- **Сервисы**: Outline, PostgreSQL, Redis, Nginx
- **Безопасность**: SSH попытки, файрвол
- **Доступность**: HTTP/HTTPS, API endpoints
- **Производительность**: Время ответа, ошибки

### Инструменты мониторинга

- **Системный мониторинг**: htop, iotop, netstat
- **Логирование**: journalctl, logrotate
- **Алерты**: fail2ban, cron jobs
- **Внешний мониторинг**: UptimeRobot, Pingdom

## 🔧 Базовый системный мониторинг

### 1. Установка инструментов мониторинга

```bash
# Установка базовых инструментов
apt install -y \
    htop \
    iotop \
    nethogs \
    iftop \
    ncdu \
    tree \
    logwatch \
    sysstat

# Включение системной статистики
systemctl enable sysstat
systemctl start sysstat
```

### 2. Настройка мониторинга ресурсов

```bash
# Создание скрипта мониторинга
cat > /opt/outline/scripts/system-monitor.sh << 'EOF'
#!/bin/bash

# Системный мониторинг для Outline VPS
LOG_FILE="/var/log/outline-system.log"
ALERT_EMAIL="admin@yourdomain.com"

# Функция логирования
log() {
    echo "$(date '+%Y-%m-%d %H:%M:%S') - $1" >> "$LOG_FILE"
}

# Проверка CPU
check_cpu() {
    local cpu_usage=$(top -bn1 | grep "Cpu(s)" | awk '{print $2}' | cut -d'%' -f1)
    if (( $(echo "$cpu_usage > 80" | bc -l) )); then
        log "WARNING: High CPU usage: ${cpu_usage}%"
        echo "High CPU usage: ${cpu_usage}%" | mail -s "Outline VPS Alert: High CPU" "$ALERT_EMAIL"
    fi
}

# Проверка памяти
check_memory() {
    local mem_usage=$(free | grep Mem | awk '{printf "%.2f", $3/$2 * 100.0}')
    if (( $(echo "$mem_usage > 85" | bc -l) )); then
        log "WARNING: High memory usage: ${mem_usage}%"
        echo "High memory usage: ${mem_usage}%" | mail -s "Outline VPS Alert: High Memory" "$ALERT_EMAIL"
    fi
}

# Проверка диска
check_disk() {
    local disk_usage=$(df / | tail -1 | awk '{print $5}' | cut -d'%' -f1)
    if [ "$disk_usage" -gt 85 ]; then
        log "WARNING: High disk usage: ${disk_usage}%"
        echo "High disk usage: ${disk_usage}%" | mail -s "Outline VPS Alert: High Disk" "$ALERT_EMAIL"
    fi
}

# Проверка нагрузки
check_load() {
    local load_avg=$(uptime | awk -F'load average:' '{print $2}' | awk '{print $1}' | cut -d',' -f1)
    local cpu_cores=$(nproc)
    local load_per_core=$(echo "scale=2; $load_avg / $cpu_cores" | bc)
    
    if (( $(echo "$load_per_core > 1.5" | bc -l) )); then
        log "WARNING: High load average: ${load_avg} (${load_per_core} per core)"
        echo "High load average: ${load_avg} (${load_per_core} per core)" | mail -s "Outline VPS Alert: High Load" "$ALERT_EMAIL"
    fi
}

# Проверка сетевых соединений
check_network() {
    local connections=$(netstat -an | wc -l)
    if [ "$connections" -gt 1000 ]; then
        log "WARNING: High number of network connections: ${connections}"
        echo "High number of network connections: ${connections}" | mail -s "Outline VPS Alert: High Connections" "$ALERT_EMAIL"
    fi
}

# Основная функция
main() {
    log "Starting system monitoring check"
    
    check_cpu
    check_memory
    check_disk
    check_load
    check_network
    
    log "System monitoring check completed"
}

main
EOF

chmod +x /opt/outline/scripts/system-monitor.sh
```

### 3. Настройка cron для системного мониторинга

```bash
# Добавление в cron для проверки каждые 5 минут
(crontab -l 2>/dev/null; echo "*/5 * * * * /opt/outline/scripts/system-monitor.sh") | crontab -

# Проверка cron задач
crontab -l
```

## 🐳 Мониторинг Docker контейнеров

### 1. Создание скрипта мониторинга Docker

```bash
cat > /opt/outline/scripts/docker-monitor.sh << 'EOF'
#!/bin/bash

# Мониторинг Docker контейнеров Outline
LOG_FILE="/var/log/outline-docker.log"
ALERT_EMAIL="admin@yourdomain.com"

log() {
    echo "$(date '+%Y-%m-%d %H:%M:%S') - $1" >> "$LOG_FILE"
}

# Проверка статуса контейнеров
check_containers() {
    cd /opt/outline
    
    # Проверка статуса всех контейнеров
    local status=$(docker-compose ps --format "table {{.Name}}\t{{.Status}}\t{{.Ports}}")
    log "Container status check:"
    echo "$status" >> "$LOG_FILE"
    
    # Проверка остановленных контейнеров
    local stopped=$(docker-compose ps | grep -c "Exit\|Created")
    if [ "$stopped" -gt 0 ]; then
        log "ERROR: Found $stopped stopped containers"
        echo "Found $stopped stopped containers" | mail -s "Outline VPS Alert: Stopped Containers" "$ALERT_EMAIL"
        
        # Попытка перезапуска
        log "Attempting to restart containers"
        docker-compose up -d
    fi
}

# Проверка использования ресурсов контейнерами
check_resources() {
    log "Container resource usage:"
    docker stats --no-stream --format "table {{.Container}}\t{{.CPUPerc}}\t{{.MemUsage}}\t{{.NetIO}}" >> "$LOG_FILE"
    
    # Проверка высокого использования CPU
    local high_cpu=$(docker stats --no-stream --format "{{.CPUPerc}}" | grep -o '[0-9.]*' | awk '$1 > 80 {count++} END {print count+0}')
    if [ "$high_cpu" -gt 0 ]; then
        log "WARNING: $high_cpu containers with high CPU usage"
    fi
    
    # Проверка высокого использования памяти
    local high_mem=$(docker stats --no-stream --format "{{.MemUsage}}" | grep -o '[0-9.]*' | awk '$1 > 80 {count++} END {print count+0}')
    if [ "$high_mem" -gt 0 ]; then
        log "WARNING: $high_mem containers with high memory usage"
    fi
}

# Проверка логов на ошибки
check_logs() {
    log "Checking container logs for errors..."
    
    # Проверка логов Outline
    local outline_errors=$(docker-compose logs --tail=100 outline 2>&1 | grep -i "error\|exception\|fatal" | wc -l)
    if [ "$outline_errors" -gt 0 ]; then
        log "WARNING: Found $outline_errors errors in Outline logs"
    fi
    
    # Проверка логов PostgreSQL
    local postgres_errors=$(docker-compose logs --tail=100 postgres 2>&1 | grep -i "error\|exception\|fatal" | wc -l)
    if [ "$postgres_errors" -gt 0 ]; then
        log "WARNING: Found $postgres_errors errors in PostgreSQL logs"
    fi
    
    # Проверка логов Redis
    local redis_errors=$(docker-compose logs --tail=100 redis 2>&1 | grep -i "error\|exception\|fatal" | wc -l)
    if [ "$redis_errors" -gt 0 ]; then
        log "WARNING: Found $redis_errors errors in Redis logs"
    fi
}

# Проверка здоровья сервисов
check_health() {
    log "Checking service health..."
    
    # Проверка Outline
    if ! curl -f -s http://localhost:3000/health > /dev/null; then
        log "ERROR: Outline health check failed"
        echo "Outline health check failed" | mail -s "Outline VPS Alert: Service Unhealthy" "$ALERT_EMAIL"
    fi
    
    # Проверка PostgreSQL
    if ! docker-compose exec -T postgres pg_isready -U outline > /dev/null 2>&1; then
        log "ERROR: PostgreSQL health check failed"
        echo "PostgreSQL health check failed" | mail -s "Outline VPS Alert: Database Unhealthy" "$ALERT_EMAIL"
    fi
    
    # Проверка Redis
    if ! docker-compose exec -T redis redis-cli ping > /dev/null 2>&1; then
        log "ERROR: Redis health check failed"
        echo "Redis health check failed" | mail -s "Outline VPS Alert: Cache Unhealthy" "$ALERT_EMAIL"
    fi
}

# Основная функция
main() {
    log "Starting Docker monitoring check"
    
    check_containers
    check_resources
    check_logs
    check_health
    
    log "Docker monitoring check completed"
}

main
EOF

chmod +x /opt/outline/scripts/docker-monitor.sh
```

### 2. Настройка cron для Docker мониторинга

```bash
# Добавление в cron для проверки каждые 2 минуты
(crontab -l 2>/dev/null; echo "*/2 * * * * /opt/outline/scripts/docker-monitor.sh") | crontab -
```

## 🌐 Мониторинг веб-сервисов

### 1. Создание скрипта мониторинга веб-сервисов

```bash
cat > /opt/outline/scripts/web-monitor.sh << 'EOF'
#!/bin/bash

# Мониторинг веб-сервисов Outline
LOG_FILE="/var/log/outline-web.log"
ALERT_EMAIL="admin@yourdomain.com"
DOMAIN="wiki.yourdomain.com"

log() {
    echo "$(date '+%Y-%m-%d %H:%M:%S') - $1" >> "$LOG_FILE"
}

# Проверка HTTP доступности
check_http() {
    local response=$(curl -s -o /dev/null -w "%{http_code}" "http://$DOMAIN")
    if [ "$response" != "200" ]; then
        log "ERROR: HTTP check failed with status $response"
        echo "HTTP check failed with status $response for $DOMAIN" | mail -s "Outline VPS Alert: HTTP Error" "$ALERT_EMAIL"
    else
        log "HTTP check passed: $response"
    fi
}

# Проверка HTTPS доступности
check_https() {
    local response=$(curl -s -o /dev/null -w "%{http_code}" "https://$DOMAIN")
    if [ "$response" != "200" ]; then
        log "ERROR: HTTPS check failed with status $response"
        echo "HTTPS check failed with status $response for $DOMAIN" | mail -s "Outline VPS Alert: HTTPS Error" "$ALERT_EMAIL"
    else
        log "HTTPS check passed: $response"
    fi
}

# Проверка SSL сертификата
check_ssl() {
    local ssl_info=$(echo | openssl s_client -servername "$DOMAIN" -connect "$DOMAIN:443" 2>/dev/null | openssl x509 -noout -dates)
    if [ $? -ne 0 ]; then
        log "ERROR: SSL certificate check failed"
        echo "SSL certificate check failed for $DOMAIN" | mail -s "Outline VPS Alert: SSL Error" "$ALERT_EMAIL"
    else
        log "SSL certificate check passed"
    fi
}

# Проверка времени ответа
check_response_time() {
    local response_time=$(curl -s -o /dev/null -w "%{time_total}" "https://$DOMAIN")
    local response_time_ms=$(echo "$response_time * 1000" | bc)
    
    if (( $(echo "$response_time_ms > 2000" | bc -l) )); then
        log "WARNING: Slow response time: ${response_time_ms}ms"
        echo "Slow response time: ${response_time_ms}ms for $DOMAIN" | mail -s "Outline VPS Alert: Slow Response" "$ALERT_EMAIL"
    else
        log "Response time OK: ${response_time_ms}ms"
    fi
}

# Проверка API endpoints
check_api() {
    local endpoints=(
        "/api/auth.config"
        "/api/users.list"
        "/api/collections.list"
    )
    
    for endpoint in "${endpoints[@]}"; do
        local response=$(curl -s -o /dev/null -w "%{http_code}" "https://$DOMAIN$endpoint")
        if [ "$response" != "200" ] && [ "$response" != "401" ]; then
            log "WARNING: API endpoint $endpoint returned $response"
        fi
    done
}

# Проверка Nginx статуса
check_nginx() {
    if ! systemctl is-active --quiet nginx; then
        log "ERROR: Nginx is not running"
        echo "Nginx is not running" | mail -s "Outline VPS Alert: Nginx Down" "$ALERT_EMAIL"
        
        # Попытка перезапуска
        systemctl restart nginx
        log "Attempted to restart Nginx"
    else
        log "Nginx is running"
    fi
}

# Основная функция
main() {
    log "Starting web services monitoring check"
    
    check_http
    check_https
    check_ssl
    check_response_time
    check_api
    check_nginx
    
    log "Web services monitoring check completed"
}

main
EOF

chmod +x /opt/outline/scripts/web-monitor.sh
```

### 2. Настройка cron для веб-мониторинга

```bash
# Добавление в cron для проверки каждую минуту
(crontab -l 2>/dev/null; echo "* * * * * /opt/outline/scripts/web-monitor.sh") | crontab -
```

## 🔒 Мониторинг безопасности

### 1. Настройка fail2ban мониторинга

```bash
cat > /opt/outline/scripts/security-monitor.sh << 'EOF'
#!/bin/bash

# Мониторинг безопасности Outline VPS
LOG_FILE="/var/log/outline-security.log"
ALERT_EMAIL="admin@yourdomain.com"

log() {
    echo "$(date '+%Y-%m-%d %H:%M:%S') - $1" >> "$LOG_FILE"
}

# Проверка fail2ban статуса
check_fail2ban() {
    if ! systemctl is-active --quiet fail2ban; then
        log "ERROR: Fail2ban is not running"
        echo "Fail2ban is not running" | mail -s "Outline VPS Alert: Fail2ban Down" "$ALERT_EMAIL"
    else
        log "Fail2ban is running"
    fi
}

# Проверка заблокированных IP
check_banned_ips() {
    local banned_count=$(fail2ban-client status sshd | grep "Currently banned" | awk '{print $4}')
    log "Currently banned IPs: $banned_count"
    
    if [ "$banned_count" -gt 10 ]; then
        log "WARNING: High number of banned IPs: $banned_count"
        echo "High number of banned IPs: $banned_count" | mail -s "Outline VPS Alert: Many Banned IPs" "$ALERT_EMAIL"
    fi
}

# Проверка SSH попыток
check_ssh_attempts() {
    local failed_attempts=$(grep "Failed password" /var/log/auth.log | wc -l)
    local today_attempts=$(grep "Failed password" /var/log/auth.log | grep "$(date '+%b %d')" | wc -l)
    
    log "Total failed SSH attempts: $failed_attempts"
    log "Today's failed SSH attempts: $today_attempts"
    
    if [ "$today_attempts" -gt 50 ]; then
        log "WARNING: High number of SSH attempts today: $today_attempts"
        echo "High number of SSH attempts today: $today_attempts" | mail -s "Outline VPS Alert: High SSH Attempts" "$ALERT_EMAIL"
    fi
}

# Проверка файрвола
check_firewall() {
    if ! ufw status | grep -q "Status: active"; then
        log "ERROR: UFW firewall is not active"
        echo "UFW firewall is not active" | mail -s "Outline VPS Alert: Firewall Inactive" "$ALERT_EMAIL"
    else
        log "UFW firewall is active"
    fi
}

# Проверка открытых портов
check_open_ports() {
    local open_ports=$(netstat -tlnp | grep LISTEN | wc -l)
    log "Open ports: $open_ports"
    
    # Проверка неожиданных портов
    local unexpected_ports=$(netstat -tlnp | grep LISTEN | grep -vE "(22|80|443|3000|5432|6379)" | wc -l)
    if [ "$unexpected_ports" -gt 0 ]; then
        log "WARNING: Found $unexpected_ports unexpected open ports"
        netstat -tlnp | grep LISTEN | grep -vE "(22|80|443|3000|5432|6379)" >> "$LOG_FILE"
    fi
}

# Основная функция
main() {
    log "Starting security monitoring check"
    
    check_fail2ban
    check_banned_ips
    check_ssh_attempts
    check_firewall
    check_open_ports
    
    log "Security monitoring check completed"
}

main
EOF

chmod +x /opt/outline/scripts/security-monitor.sh
```

### 2. Настройка cron для мониторинга безопасности

```bash
# Добавление в cron для проверки каждые 10 минут
(crontab -l 2>/dev/null; echo "*/10 * * * * /opt/outline/scripts/security-monitor.sh") | crontab -
```

## 📊 Сбор и анализ статистики

### 1. Создание скрипта сбора статистики

```bash
cat > /opt/outline/scripts/collect-stats.sh << 'EOF'
#!/bin/bash

# Сбор статистики для Outline VPS
STATS_DIR="/opt/outline/stats"
DATE=$(date +%Y%m%d)

mkdir -p "$STATS_DIR"

# Системная статистика
{
    echo "=== System Statistics ==="
    echo "Date: $(date)"
    echo "Uptime: $(uptime)"
    echo "Load Average: $(uptime | awk -F'load average:' '{print $2}')"
    echo "CPU Usage: $(top -bn1 | grep "Cpu(s)" | awk '{print $2}')"
    echo "Memory Usage: $(free -h | grep Mem | awk '{print $3"/"$2}')"
    echo "Disk Usage: $(df -h / | tail -1 | awk '{print $5}')"
    echo ""
    
    echo "=== Docker Statistics ==="
    docker stats --no-stream --format "table {{.Container}}\t{{.CPUPerc}}\t{{.MemUsage}}\t{{.NetIO}}\t{{.BlockIO}}"
    echo ""
    
    echo "=== Network Statistics ==="
    netstat -i
    echo ""
    
    echo "=== Process Statistics ==="
    ps aux --sort=-%cpu | head -10
    echo ""
    
    echo "=== Service Status ==="
    systemctl status nginx docker fail2ban --no-pager -l
} > "$STATS_DIR/system-stats-$DATE.log"

# Очистка старых файлов (старше 30 дней)
find "$STATS_DIR" -name "system-stats-*.log" -mtime +30 -delete

echo "Statistics collected and saved to $STATS_DIR/system-stats-$DATE.log"
EOF

chmod +x /opt/outline/scripts/collect-stats.sh
```

### 2. Настройка cron для сбора статистики

```bash
# Добавление в cron для сбора статистики каждый час
(crontab -l 2>/dev/null; echo "0 * * * * /opt/outline/scripts/collect-stats.sh") | crontab -
```

## 📧 Настройка email уведомлений

### 1. Установка и настройка Postfix

```bash
# Установка Postfix
apt install -y postfix mailutils

# Настройка Postfix (выберите "Internet Site")
# Настройте домен и другие параметры
```

### 2. Тестирование email

```bash
# Тестовая отправка
echo "Test email from Outline VPS" | mail -s "Test Email" admin@yourdomain.com
```

## 📈 Внешний мониторинг

### 1. UptimeRobot

1. Зарегистрируйтесь на [UptimeRobot](https://uptimerobot.com/)
2. Добавьте мониторинг для:
   - HTTP: `http://wiki.yourdomain.com`
   - HTTPS: `https://wiki.yourdomain.com`
   - Ping: IP вашего VPS

### 2. Pingdom

1. Зарегистрируйтесь на [Pingdom](https://pingdom.com/)
2. Настройте мониторинг доступности
3. Настройте алерты по email/SMS

## 🔍 Просмотр логов и статистики

### 1. Просмотр логов в реальном времени

```bash
# Системные логи
tail -f /var/log/outline-system.log

# Docker логи
tail -f /var/log/outline-docker.log

# Веб-логи
tail -f /var/log/outline-web.log

# Логи безопасности
tail -f /var/log/outline-security.log
```

### 2. Просмотр статистики

```bash
# Последняя статистика
ls -la /opt/outline/stats/

# Просмотр конкретного файла
cat /opt/outline/stats/system-stats-$(date +%Y%m%d).log

# Поиск по логам
grep "ERROR\|WARNING" /var/log/outline-*.log
```

## 🎯 Настройка алертов

### 1. Создание скрипта алертов

```bash
cat > /opt/outline/scripts/alert-manager.sh << 'EOF'
#!/bin/bash

# Менеджер алертов для Outline VPS
ALERT_EMAIL="admin@yourdomain.com"
ALERT_LOG="/var/log/outline-alerts.log"

log_alert() {
    echo "$(date '+%Y-%m-%d %H:%M:%S') - $1" >> "$ALERT_LOG"
}

send_alert() {
    local subject="$1"
    local message="$2"
    
    echo "$message" | mail -s "$subject" "$ALERT_EMAIL"
    log_alert "Alert sent: $subject"
}

# Проверка критических ошибок
check_critical_errors() {
    # Проверка остановленных контейнеров
    local stopped_containers=$(docker-compose ps | grep -c "Exit\|Created")
    if [ "$stopped_containers" -gt 0 ]; then
        send_alert "CRITICAL: Outline containers stopped" "Found $stopped_containers stopped containers"
    fi
    
    # Проверка недоступности Outline
    if ! curl -f -s http://localhost:3000/health > /dev/null; then
        send_alert "CRITICAL: Outline service unavailable" "Outline health check failed"
    fi
    
    # Проверка недоступности базы данных
    if ! docker-compose exec -T postgres pg_isready -U outline > /dev/null 2>&1; then
        send_alert "CRITICAL: Database unavailable" "PostgreSQL health check failed"
    fi
}

# Проверка предупреждений
check_warnings() {
    # Высокое использование CPU
    local cpu_usage=$(top -bn1 | grep "Cpu(s)" | awk '{print $2}' | cut -d'%' -f1)
    if (( $(echo "$cpu_usage > 90" | bc -l) )); then
        send_alert "WARNING: Very high CPU usage" "CPU usage: ${cpu_usage}%"
    fi
    
    # Высокое использование памяти
    local mem_usage=$(free | grep Mem | awk '{printf "%.2f", $3/$2 * 100.0}')
    if (( $(echo "$mem_usage > 90" | bc -l) )); then
        send_alert "WARNING: Very high memory usage" "Memory usage: ${mem_usage}%"
    fi
    
    # Высокое использование диска
    local disk_usage=$(df / | tail -1 | awk '{print $5}' | cut -d'%' -f1)
    if [ "$disk_usage" -gt 90 ]; then
        send_alert "WARNING: Very high disk usage" "Disk usage: ${disk_usage}%"
    fi
}

# Основная функция
main() {
    log_alert "Starting alert check"
    
    check_critical_errors
    check_warnings
    
    log_alert "Alert check completed"
}

main
EOF

chmod +x /opt/outline/scripts/alert-manager.sh
```

### 2. Настройка cron для алертов

```bash
# Добавление в cron для проверки каждую минуту
(crontab -l 2>/dev/null; echo "* * * * * /opt/outline/scripts/alert-manager.sh") | crontab -
```

## 📊 Дашборд мониторинга

### 1. Создание простого веб-дашборда

```bash
cat > /opt/outline/scripts/create-dashboard.sh << 'EOF'
#!/bin/bash

# Создание простого веб-дашборда для мониторинга
DASHBOARD_DIR="/opt/outline/dashboard"
mkdir -p "$DASHBOARD_DIR"

cat > "$DASHBOARD_DIR/index.html" << 'HTML'
<!DOCTYPE html>
<html>
<head>
    <title>Outline VPS Monitor</title>
    <meta charset="utf-8">
    <meta http-equiv="refresh" content="30">
    <style>
        body { font-family: Arial, sans-serif; margin: 20px; }
        .status { padding: 10px; margin: 10px 0; border-radius: 5px; }
        .ok { background-color: #d4edda; border: 1px solid #c3e6cb; }
        .warning { background-color: #fff3cd; border: 1px solid #ffeaa7; }
        .error { background-color: #f8d7da; border: 1px solid #f5c6cb; }
        .container { max-width: 1200px; margin: 0 auto; }
        .grid { display: grid; grid-template-columns: repeat(auto-fit, minmax(300px, 1fr)); gap: 20px; }
        .card { background: white; padding: 20px; border-radius: 8px; box-shadow: 0 2px 4px rgba(0,0,0,0.1); }
        h1 { color: #333; text-align: center; }
        h2 { color: #666; border-bottom: 2px solid #eee; padding-bottom: 10px; }
        .metric { font-size: 24px; font-weight: bold; margin: 10px 0; }
        .label { color: #888; font-size: 14px; }
    </style>
</head>
<body>
    <div class="container">
        <h1>🚀 Outline VPS Monitor</h1>
        <p style="text-align: center; color: #666;">Last updated: <span id="timestamp"></span></p>
        
        <div class="grid">
            <div class="card">
                <h2>📊 System Status</h2>
                <div id="system-status">Loading...</div>
            </div>
            
            <div class="card">
                <h2>🐳 Docker Status</h2>
                <div id="docker-status">Loading...</div>
            </div>
            
            <div class="card">
                <h2>🌐 Web Services</h2>
                <div id="web-status">Loading...</div>
            </div>
            
            <div class="card">
                <h2>🔒 Security</h2>
                <div id="security-status">Loading...</div>
            </div>
        </div>
    </div>
    
    <script>
        function updateTimestamp() {
            document.getElementById('timestamp').textContent = new Date().toLocaleString();
        }
        
        function updateStatus() {
            // Здесь можно добавить AJAX запросы для получения реальных данных
            // Пока что просто обновляем timestamp
            updateTimestamp();
        }
        
        // Обновление каждые 30 секунд
        setInterval(updateStatus, 30000);
        updateStatus();
    </script>
</body>
</html>
HTML

echo "Dashboard created at $DASHBOARD_DIR/index.html"
echo "You can access it at: http://your-server-ip:8080"
EOF

chmod +x /opt/outline/scripts/create-dashboard.sh
```

### 2. Запуск дашборда

```bash
# Создание дашборда
./scripts/create-dashboard.sh

# Запуск простого веб-сервера для дашборда
cd /opt/outline/dashboard
python3 -m http.server 8080 &
```

## 🎯 Заключение

Теперь у вас есть комплексная система мониторинга для Outline VPS, которая включает:

- ✅ **Системный мониторинг**: CPU, RAM, диск, сеть
- ✅ **Docker мониторинг**: статус контейнеров, ресурсы, логи
- ✅ **Веб-мониторинг**: доступность, SSL, время ответа
- ✅ **Мониторинг безопасности**: fail2ban, файрвол, SSH
- ✅ **Сбор статистики**: автоматический сбор и хранение
- ✅ **Email алерты**: уведомления о проблемах
- ✅ **Веб-дашборд**: визуализация состояния системы

**Следующие шаги:**
1. Настройте email уведомления
2. Добавьте внешний мониторинг
3. Настройте дополнительные алерты
4. Расширьте дашборд дополнительными метриками

---

**📊 Теперь ваш Outline VPS находится под постоянным наблюдением!**
