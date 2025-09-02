

# 🚀 Outline VPS Setup

Автоматические скрипты и конфигурации для развертывания Outline Wiki на выделенном VPS сервере.

## ✨ Возможности

- 🐳 **Docker-based развертывание** с PostgreSQL и Redis
- 🔒 **Автоматическая настройка SSL** с Let's Encrypt
- 🔐 **Google OAuth аутентификация** для безопасного входа
- 🌐 **Nginx reverse proxy** с оптимизированной конфигурацией
- 🔥 **Файрвол и Fail2ban** для защиты от атак
- 📊 **Комплексный мониторинг** системы и сервисов
- 💾 **Автоматическое резервное копирование** базы данных и файлов
- 📧 **Email уведомления** о проблемах и алертах
- 🚀 **Быстрое развертывание** одним скриптом

## 📋 Требования

- **VPS сервер** с Ubuntu 20.04+ или Debian 11+
- **Минимум 2GB RAM** (рекомендуется 4GB+)
- **Минимум 20GB диска** (рекомендуется 50GB+)
- **Домен**, настроенный на ваш VPS
- **SSH доступ** с правами root

## 🚀 Быстрый старт

### 1. Клонирование проекта

```bash
git clone https://github.com/your-username/outline-vps-setup.git
cd outline-vps-setup
```

### 2. Автоматическая установка

```bash
# Сделать скрипт исполняемым
chmod +x deploy.sh

# Установка с автоматической настройкой SSL
./deploy.sh wiki.yourdomain.com

# Или без SSL
./deploy.sh wiki.yourdomain.com --no-ssl
```

### 3. Настройка Google OAuth

1. Создайте проект в [Google Cloud Console](https://console.cloud.google.com/)
2. Настройте OAuth 2.0 учетные данные
3. Обновите `.env` файл
4. Перезапустите Outline

## 📁 Структура проекта

```
outline-vps-setup/
├── README.md                 # Основная документация
├── QUICK_START.md           # Быстрый старт
├── DEPLOYMENT_GUIDE.md      # Полное руководство по развертыванию
├── GITHUB_SETUP.md          # Настройка GitHub репозитория
├── VPS_DEPLOYMENT.md        # Детальные инструкции по VPS
├── docker-compose.yml       # Docker Compose конфигурация
├── env.example              # Пример переменных окружения
├── deploy.sh                # Основной скрипт развертывания
├── .gitignore               # Git ignore файл
├── scripts/                 # Скрипты установки и настройки
│   ├── install.sh          # Скрипт установки
│   ├── setup-ssl.sh        # Настройка SSL
│   └── backup.sh           # Резервное копирование
└── docs/                    # Документация
    ├── google-auth-setup.md # Настройка Google OAuth
    ├── troubleshooting.md   # Устранение неполадок
    └── monitoring-setup.md  # Настройка мониторинга
```

## 🔧 Пошаговая установка

### Шаг 1: Базовая установка

```bash
chmod +x scripts/install.sh
./scripts/install.sh full
```

### Шаг 2: Настройка SSL

```bash
chmod +x scripts/setup-ssl.sh
DOMAIN=wiki.yourdomain.com ./scripts/setup-ssl.sh
```

### Шаг 3: Запуск Outline

```bash
cd /opt/outline
./scripts/install.sh start
```

## ⚙️ Конфигурация

### Основные переменные окружения

```bash
# База данных
POSTGRES_PASSWORD=your_secure_password

# Секретные ключи (автоматически генерируются)
SECRET_KEY=your_secret_key
UTILS_SECRET=your_utils_secret
SESSION_SECRET=your_session_secret
COOKIE_SECRET=your_cookie_secret

# URL приложения
OUTLINE_URL=https://wiki.yourdomain.com

# Google OAuth
GOOGLE_CLIENT_ID=your_client_id
GOOGLE_CLIENT_SECRET=your_client_secret

# Администратор
ADMIN_EMAIL=admin@yourdomain.com
```

### Настройка Google OAuth

1. Перейдите в [Google Cloud Console](https://console.cloud.google.com/)
2. Создайте новый проект
3. Включите Google+ API
4. Создайте OAuth 2.0 учетные данные:
   - **Type**: Web application
   - **Authorized JavaScript origins**: `https://wiki.yourdomain.com`
   - **Authorized redirect URIs**: `https://wiki.yourdomain.com/auth/google.callback`

## 📊 Мониторинг

### Автоматический мониторинг

```bash
# Системный мониторинг (каждые 5 минут)
(crontab -l 2>/dev/null; echo "*/5 * * * * /opt/outline/scripts/system-monitor.sh") | crontab -

# Docker мониторинг (каждые 2 минуты)
(crontab -l 2>/dev/null; echo "*/2 * * * * /opt/outline/scripts/docker-monitor.sh") | crontab -

# Веб-мониторинг (каждую минуту)
(crontab -l 2>/dev/null; echo "* * * * * /opt/outline/scripts/web-monitor.sh") | crontab -
```

### Просмотр логов

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

## 🔒 Безопасность

### Файрвол (UFW)

```bash
# Настройка правил
ufw default deny incoming
ufw default allow outgoing
ufw allow ssh
ufw allow 80/tcp
ufw allow 443/tcp
ufw allow from 127.0.0.1 to any port 3000
ufw --force enable
```

### Fail2ban

```bash
# Установка и настройка
apt install -y fail2ban
systemctl start fail2ban
systemctl enable fail2ban
```

### SSH безопасность

```bash
# Рекомендуемые настройки
PasswordAuthentication no
PermitRootLogin no
AllowUsers outline-user
```

## 💾 Резервное копирование

### Автоматическое резервное копирование

```bash
# Создание резервной копии
./scripts/backup.sh

# Восстановление
./scripts/backup.sh restore backup_name

# Автоматическое резервное копирование (каждый день в 2:00)
(crontab -l 2>/dev/null; echo "0 2 * * * /opt/outline/scripts/backup.sh") | crontab -
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
```

### Частые проблемы

1. **Outline не запускается** → Проверьте логи: `docker-compose logs outline`
2. **SSL ошибки** → Проверьте сертификат: `certbot certificates`
3. **Google OAuth не работает** → Проверьте переменные в `.env`
4. **Nginx не проксирует** → Проверьте конфигурацию: `nginx -t`

## 📚 Документация

- [🚀 Быстрый старт](QUICK_START.md) - Быстрое развертывание
- [📖 Полное руководство](DEPLOYMENT_GUIDE.md) - Детальные инструкции
- [🔐 Настройка Google OAuth](docs/google-auth-setup.md) - Аутентификация
- [🆘 Устранение неполадок](docs/troubleshooting.md) - Решение проблем
- [📊 Настройка мониторинга](docs/monitoring-setup.md) - Система мониторинга
- [🌐 Развертывание на VPS](VPS_DEPLOYMENT.md) - VPS настройка
- [📝 Настройка GitHub](GITHUB_SETUP.md) - GitHub интеграция

## 🔄 Обновление

### Обновление Outline

```bash
cd /opt/outline
docker-compose pull outline
docker-compose up -d outline
```

### Обновление зависимостей

```bash
docker-compose pull
docker-compose up -d
```

## 🌐 Доступ

После установки Outline будет доступен по адресу:
- **HTTP**: `http://wiki.yourdomain.com`
- **HTTPS**: `https://wiki.yourdomain.com`

## 🎯 Следующие шаги

После успешной установки:

1. **Настройте команды** в Outline
2. **Добавьте пользователей** в систему
3. **Настройте права доступа** к документам
4. **Создайте первую страницу** wiki
5. **Настройте регулярные резервные копии**
6. **Настройте мониторинг** доступности
7. **Добавьте внешний мониторинг** (UptimeRobot, Pingdom)

## 🤝 Вклад в проект

Мы приветствуем вклад в развитие проекта! Пожалуйста:

1. Форкните репозиторий
2. Создайте ветку для новой функции
3. Внесите изменения
4. Создайте Pull Request

## 📄 Лицензия

Этот проект распространяется под лицензией MIT. См. файл [LICENSE](LICENSE) для получения дополнительной информации.

## 🆘 Поддержка

Если у вас возникли проблемы:

1. **Проверьте документацию** по устранению неполадок
2. **Создайте issue** в репозитории проекта
3. **Проверьте системные требования** и совместимость

## 🙏 Благодарности

- [Outline Team](https://github.com/outline/outline) - За отличное приложение
- [Docker](https://docker.com/) - За контейнеризацию
- [Let's Encrypt](https://letsencrypt.org/) - За бесплатные SSL сертификаты
- [Nginx](https://nginx.org/) - За веб-сервер

---

**🎉 Поздравляем!** Теперь у вас есть собственный Outline сервер для командной работы с документами.

**⭐ Если проект вам понравился, поставьте звездочку!**

---

**🚀 Outline VPS Setup - Профессиональное развертывание wiki в один клик!**
