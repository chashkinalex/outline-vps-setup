# Настройка Google OAuth для Outline

Это руководство поможет вам настроить аутентификацию через Google для вашего Outline сервера.

## Предварительные требования

1. Домен, настроенный на ваш VPS сервер
2. SSL сертификат (рекомендуется Let's Encrypt)
3. Outline, запущенный и доступный по HTTPS

## Шаг 1: Создание проекта в Google Cloud Console

### 1.1 Переход в Google Cloud Console

1. Откройте [Google Cloud Console](https://console.cloud.google.com/)
2. Войдите в свой Google аккаунт
3. Создайте новый проект или выберите существующий

### 1.2 Включение Google+ API

1. В меню слева выберите "APIs & Services" → "Library"
2. Найдите "Google+ API" или "Google+ Domains API"
3. Нажмите "Enable"

### 1.3 Создание OAuth 2.0 учетных данных

1. Перейдите в "APIs & Services" → "Credentials"
2. Нажмите "Create Credentials" → "OAuth client ID"
3. Выберите тип приложения: "Web application"
4. Заполните форму:

**Name:** Outline Wiki (или любое другое название)

**Authorized JavaScript origins:**
```
https://your-domain.com
http://localhost:3000 (для локальной разработки)
```

**Authorized redirect URIs:**
```
https://your-domain.com/auth/google.callback
http://localhost:3000/auth/google.callback (для локальной разработки)
```

5. Нажмите "Create"

### 1.4 Получение учетных данных

После создания вы получите:
- **Client ID** (например: `123456789-abcdef.apps.googleusercontent.com`)
- **Client Secret** (например: `GOCSPX-abcdefghijklmnop`)

**⚠️ Важно:** Сохраните эти данные в безопасном месте!

## Шаг 2: Настройка Outline

### 2.1 Обновление переменных окружения

Отредактируйте файл `.env` в корне проекта Outline:

```bash
# Google OAuth
GOOGLE_CLIENT_ID=your_google_client_id_here
GOOGLE_CLIENT_SECRET=your_google_client_secret_here

# App URL (должен совпадать с доменом в Google OAuth)
OUTLINE_URL=https://your-domain.com
```

### 2.2 Перезапуск Outline

```bash
# Остановка сервисов
docker-compose down

# Запуск с новыми переменными
docker-compose up -d

# Проверка статуса
docker-compose ps
```

## Шаг 3: Настройка домена в Google

### 3.1 Добавление домена в Google Workspace (рекомендуется)

Если у вас есть Google Workspace:

1. Перейдите в [Google Admin Console](https://admin.google.com/)
2. Выберите "Security" → "Authentication" → "SSO with Google"
3. Добавьте ваш домен в список разрешенных доменов

### 3.2 Альтернативный способ (без Google Workspace)

Если у вас нет Google Workspace, вы можете:

1. Создать Google аккаунт с вашим доменом
2. Или использовать существующий Google аккаунт

## Шаг 4: Тестирование аутентификации

### 4.1 Проверка доступности

1. Откройте `https://your-domain.com` в браузере
2. Убедитесь, что Outline загружается
3. Нажмите "Sign in with Google"

### 4.2 Проверка процесса входа

1. Выберите Google аккаунт
2. Разрешите доступ приложению
3. Должны быть перенаправлены обратно в Outline

## Шаг 5: Настройка администратора

### 5.1 Первый вход

При первом входе через Google:

1. Войдите в Outline через Google
2. Перейдите в настройки пользователя
3. Установите роль "Admin"

### 5.2 Создание команды

1. В админ-панели создайте команду
2. Добавьте пользователей в команду
3. Настройте права доступа

## Устранение неполадок

### Проблема: "Error: redirect_uri_mismatch"

**Причина:** URI перенаправления в Google OAuth не совпадает с настройками Outline.

**Решение:**
1. Проверьте `OUTLINE_URL` в `.env` файле
2. Убедитесь, что в Google OAuth указан правильный `redirect_uri`
3. Перезапустите Outline

### Проблема: "Google OAuth is not configured"

**Причина:** Переменные окружения не загружены или неверны.

**Решение:**
1. Проверьте `.env` файл
2. Убедитесь, что `GOOGLE_CLIENT_ID` и `GOOGLE_CLIENT_SECRET` установлены
3. Перезапустите Outline

### Проблема: "Access denied"

**Причина:** Домен не добавлен в Google Workspace или не авторизован.

**Решение:**
1. Добавьте домен в Google Admin Console
2. Или используйте Google аккаунт с другим доменом

### Проблема: SSL ошибки

**Причина:** Проблемы с SSL сертификатом.

**Решение:**
1. Проверьте SSL сертификат: `openssl s_client -connect your-domain.com:443`
2. Убедитесь, что Nginx правильно настроен
3. Проверьте логи Nginx: `tail -f /var/log/nginx/error.log`

## Проверка конфигурации

### Проверка переменных окружения

```bash
# Проверка загруженных переменных
docker-compose exec outline env | grep -E "(GOOGLE|OUTLINE_URL)"

# Проверка логов Outline
docker-compose logs outline | grep -i "google\|oauth"
```

### Проверка доступности

```bash
# Проверка HTTP
curl -I http://your-domain.com

# Проверка HTTPS
curl -I https://your-domain.com

# Проверка Outline API
curl -I https://your-domain.com/api/auth.config
```

## Безопасность

### Рекомендации

1. **Используйте HTTPS:** Всегда используйте SSL для production
2. **Ограничьте доступ:** Настройте файрвол на VPS
3. **Регулярные обновления:** Обновляйте Outline и зависимости
4. **Резервное копирование:** Настройте автоматическое резервное копирование
5. **Мониторинг:** Настройте мониторинг доступности сервиса

### Ограничения доступа

В файрволе VPS разрешите только необходимые порты:

```bash
# SSH
ufw allow ssh

# HTTP/HTTPS
ufw allow 80/tcp
ufw allow 443/tcp

# Outline (только локально)
ufw allow from 127.0.0.1 to any port 3000
```

## Дополнительные настройки

### Настройка SMTP для уведомлений

```bash
# В .env файле
SMTP_HOST=smtp.gmail.com
SMTP_PORT=587
SMTP_USERNAME=your-email@gmail.com
SMTP_PASSWORD=your-app-password
SMTP_FROM_EMAIL=noreply@your-domain.com
```

### Настройка S3 для файлов

```bash
# В .env файле
AWS_S3_BUCKET=your-outline-bucket
AWS_S3_REGION=us-east-1
AWS_ACCESS_KEY_ID=your-access-key
AWS_SECRET_ACCESS_KEY=your-secret-key
```

## Поддержка

Если у вас возникли проблемы:

1. Проверьте логи: `docker-compose logs outline`
2. Проверьте статус сервисов: `docker-compose ps`
3. Проверьте конфигурацию Nginx: `nginx -t`
4. Проверьте SSL сертификат: `certbot certificates`

## Полезные команды

```bash
# Перезапуск Outline
docker-compose restart outline

# Просмотр логов в реальном времени
docker-compose logs -f outline

# Проверка статуса всех сервисов
docker-compose ps

# Обновление Outline
docker-compose pull outline
docker-compose up -d outline

# Резервное копирование базы данных
docker-compose exec postgres pg_dump -U outline outline > backup.sql

# Восстановление базы данных
docker-compose exec -T postgres psql -U outline outline < backup.sql
```
