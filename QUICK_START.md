# 🚀 Быстрый старт Outline на VPS

Это краткое руководство поможет вам быстро развернуть Outline на вашем VPS сервере.

## 📋 Предварительные требования

- **VPS сервер** с Ubuntu 20.04+ или Debian 11+
- **Домен**, настроенный на ваш VPS
- **SSH доступ** к серверу
- **Права root** на сервере

## ⚡ Быстрая установка

### 1. Подключение к серверу

```bash
ssh root@your-server-ip
```

### 2. Клонирование проекта

```bash
# Создание рабочей директории
mkdir -p /opt/outline-setup
cd /opt/outline-setup

# Клонирование проекта (замените на ваш репозиторий)
git clone https://github.com/your-username/outline-vps-setup.git .
```

### 3. Запуск автоматической установки

```bash
# Сделать скрипт исполняемым
chmod +x deploy.sh

# Запуск установки (замените на ваш домен)
./deploy.sh wiki.yourdomain.com
```

**Или для установки без SSL:**
```bash
./deploy.sh wiki.yourdomain.com --no-ssl
```

## 🔧 Пошаговая установка (альтернатива)

Если вы предпочитаете пошаговую установку:

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

## ⚙️ Настройка Google OAuth

После установки необходимо настроить аутентификацию:

### 1. Создание проекта в Google Cloud Console

1. Перейдите в [Google Cloud Console](https://console.cloud.google.com/)
2. Создайте новый проект
3. Включите Google+ API
4. Создайте OAuth 2.0 учетные данные

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

## 🌐 Доступ к приложению

После установки Outline будет доступен по адресу:
- **HTTP**: `http://wiki.yourdomain.com`
- **HTTPS**: `https://wiki.yourdomain.com`

## 📚 Дополнительные возможности

### Резервное копирование
```bash
# Создание резервной копии
./scripts/backup.sh

# Восстановление из резервной копии
./scripts/backup.sh restore backup_name
```

### Мониторинг
```bash
# Статус сервисов
docker-compose ps

# Просмотр логов
docker-compose logs -f outline

# Проверка ресурсов
docker stats
```

### Обновление
```bash
# Обновление Outline
docker-compose pull outline
docker-compose up -d outline

# Обновление зависимостей
docker-compose pull
docker-compose up -d
```

## 🆘 Устранение неполадок

### Основные команды диагностики

```bash
# Проверка статуса
systemctl status nginx docker

# Проверка портов
netstat -tlnp | grep -E "(80|443|3000)"

# Проверка логов
tail -f /var/log/nginx/error.log
docker-compose logs outline
```

### Частые проблемы

1. **Outline не запускается** → Проверьте логи: `docker-compose logs outline`
2. **SSL ошибки** → Проверьте сертификат: `certbot certificates`
3. **Google OAuth не работает** → Проверьте переменные в `.env`

Подробные инструкции см. в [docs/troubleshooting.md](docs/troubleshooting.md)

## 📖 Документация

- [Настройка Google OAuth](docs/google-auth-setup.md)
- [Устранение неполадок](docs/troubleshooting.md)
- [Резервное копирование](scripts/backup.sh --help)

## 🆘 Поддержка

Если у вас возникли проблемы:

1. Проверьте логи и статус сервисов
2. Обратитесь к документации по устранению неполадок
3. Создайте issue в репозитории проекта

## 🎯 Что дальше?

После успешной установки:

1. **Настройте команды** в Outline
2. **Добавьте пользователей** в систему
3. **Настройте права доступа** к документам
4. **Создайте первую страницу** wiki
5. **Настройте регулярные резервные копии**

---

**🎉 Поздравляем!** Теперь у вас есть собственный Outline сервер для командной работы с документами.
