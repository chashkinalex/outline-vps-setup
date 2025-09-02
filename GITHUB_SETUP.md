# 🚀 Настройка GitHub для Outline VPS Setup

Это руководство поможет вам создать GitHub репозиторий и настроить автоматическое развертывание на ваш VPS сервер.

## 📋 Создание репозитория

### 1. Создание нового репозитория

1. Перейдите на [GitHub](https://github.com/)
2. Нажмите "New repository"
3. Заполните форму:
   - **Repository name**: `outline-vps-setup`
   - **Description**: `Outline Wiki VPS deployment scripts and configuration`
   - **Visibility**: Public или Private (по вашему выбору)
   - **Initialize with**: ✅ Add a README file
4. Нажмите "Create repository"

### 2. Клонирование репозитория

```bash
# Клонирование в локальную директорию
git clone https://github.com/your-username/outline-vps-setup.git
cd outline-vps-setup

# Или если репозиторий уже существует
git remote add origin https://github.com/your-username/outline-vps-setup.git
```

## 📁 Структура проекта

Убедитесь, что у вас есть следующая структура файлов:

```
outline-vps-setup/
├── README.md
├── QUICK_START.md
├── GITHUB_SETUP.md
├── docker-compose.yml
├── env.example
├── deploy.sh
├── scripts/
│   ├── install.sh
│   ├── setup-ssl.sh
│   └── backup.sh
└── docs/
    ├── google-auth-setup.md
    └── troubleshooting.md
```

## 🔧 Настройка Git

### 1. Инициализация Git (если не инициализирован)

```bash
git init
git add .
git commit -m "Initial commit: Outline VPS setup scripts"
```

### 2. Настройка .gitignore

Создайте файл `.gitignore`:

```bash
# Переменные окружения
.env
.env.local
.env.production

# Логи
*.log
logs/

# Резервные копии
backups/
*.sql
*.tar.gz

# Временные файлы
*.tmp
*.temp
.DS_Store
Thumbs.db

# Docker
.dockerignore

# IDE
.vscode/
.idea/
*.swp
*.swo

# Системные файлы
*.pid
*.lock
```

### 3. Первый коммит

```bash
git add .gitignore
git add .
git commit -m "Add Outline VPS setup project files"
git push -u origin main
```

## 🚀 Автоматическое развертывание

### 1. Настройка GitHub Actions (опционально)

Создайте файл `.github/workflows/deploy.yml`:

```yaml
name: Deploy to VPS

on:
  push:
    branches: [ main ]
  workflow_dispatch:

jobs:
  deploy:
    runs-on: ubuntu-latest
    
    steps:
    - name: Deploy to VPS
      uses: appleboy/ssh-action@master
      with:
        host: ${{ secrets.VPS_HOST }}
        username: ${{ secrets.VPS_USERNAME }}
        key: ${{ secrets.VPS_SSH_KEY }}
        script: |
          cd /opt/outline-setup
          git pull origin main
          chmod +x deploy.sh
          ./deploy.sh ${{ secrets.DOMAIN }} --ssl-only
```

### 2. Настройка секретов GitHub

В настройках репозитория (`Settings` → `Secrets and variables` → `Actions`):

- `VPS_HOST`: IP адрес вашего VPS
- `VPS_USERNAME`: имя пользователя на VPS (обычно `root`)
- `VPS_SSH_KEY`: приватный SSH ключ для доступа к VPS
- `DOMAIN`: ваш домен (например, `wiki.example.com`)

## 🔐 Настройка SSH ключей

### 1. Генерация SSH ключа (если нет)

```bash
# Генерация нового ключа
ssh-keygen -t ed25519 -C "your-email@example.com"

# Копирование публичного ключа
cat ~/.ssh/id_ed25519.pub
```

### 2. Добавление ключа на VPS

```bash
# На вашем VPS сервере
mkdir -p ~/.ssh
echo "your-public-key-here" >> ~/.ssh/authorized_keys
chmod 700 ~/.ssh
chmod 600 ~/.ssh/authorized_keys
```

## 📝 Обновление документации

### 1. Обновление README.md

Убедитесь, что `README.md` содержит актуальную информацию:

```markdown
# Outline VPS Setup

Автоматические скрипты для развертывания Outline Wiki на VPS сервере.

## Быстрый старт

```bash
git clone https://github.com/your-username/outline-vps-setup.git
cd outline-vps-setup
chmod +x deploy.sh
./deploy.sh your-domain.com
```

## Документация

- [Быстрый старт](QUICK_START.md)
- [Настройка GitHub](GITHUB_SETUP.md)
- [Настройка Google OAuth](docs/google-auth-setup.md)
- [Устранение неполадок](docs/troubleshooting.md)
```

### 2. Добавление информации о лицензии

Создайте файл `LICENSE` (например, MIT):

```text
MIT License

Copyright (c) 2024 Your Name

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
```

## 🔄 Рабочий процесс разработки

### 1. Создание ветки для изменений

```bash
# Создание новой ветки
git checkout -b feature/new-feature

# Внесение изменений
# ...

# Коммит изменений
git add .
git commit -m "Add new feature: description"

# Отправка ветки
git push origin feature/new-feature
```

### 2. Создание Pull Request

1. Перейдите на GitHub
2. Нажмите "Compare & pull request"
3. Заполните описание изменений
4. Нажмите "Create pull request"

### 3. Слияние изменений

После проверки и одобрения:
1. Нажмите "Merge pull request"
2. Удалите ветку
3. Обновите локальный репозиторий: `git pull origin main`

## 📊 Мониторинг и аналитика

### 1. GitHub Insights

Используйте встроенные инструменты GitHub:
- **Traffic**: Просмотры и клонирования
- **Contributors**: Активность участников
- **Commits**: История изменений

### 2. GitHub Pages (опционально)

Настройте GitHub Pages для документации:

1. Перейдите в `Settings` → `Pages`
2. Выберите источник: `Deploy from a branch`
3. Выберите ветку: `main`
4. Нажмите "Save"

## 🆘 Поддержка и сообщество

### 1. Issues

Создавайте issues для:
- Сообщений об ошибках
- Предложений по улучшению
- Вопросов по использованию

### 2. Discussions

Используйте Discussions для:
- Обсуждения идей
- Вопросов и ответов
- Обмена опытом

### 3. Wiki

Создайте Wiki для:
- Дополнительной документации
- FAQ
- Примеров использования

## 🔒 Безопасность

### 1. Проверка зависимостей

```bash
# Проверка уязвимостей в зависимостях
npm audit
# или
yarn audit
```

### 2. Сканирование секретов

Используйте GitHub Secret Scanning для автоматического обнаружения секретов в коде.

### 3. Обновления безопасности

Регулярно обновляйте зависимости и проверяйте уведомления о безопасности.

## 📈 Развитие проекта

### 1. Roadmap

Создайте файл `ROADMAP.md` с планами развития:

```markdown
# Roadmap

## v1.0.0 - Базовая функциональность
- [x] Автоматическая установка Outline
- [x] Настройка SSL
- [x] Настройка Google OAuth

## v1.1.0 - Дополнительные возможности
- [ ] Мониторинг и алерты
- [ ] Автоматическое резервное копирование
- [ ] Масштабирование

## v2.0.0 - Enterprise функции
- [ ] Кластеризация
- [ ] Load balancing
- [ ] High availability
```

### 2. Версионирование

Используйте [Semantic Versioning](https://semver.org/):

```bash
# Создание тега
git tag -a v1.0.0 -m "Release version 1.0.0"
git push origin v1.0.0

# Создание release на GitHub
# Перейдите в Releases → Create a new release
```

## 🎯 Заключение

Теперь у вас есть полноценный GitHub репозиторий для проекта Outline VPS Setup с:

- ✅ Автоматическим развертыванием
- ✅ Подробной документацией
- ✅ Системой контроля версий
- ✅ Возможностью совместной работы
- ✅ Мониторингом и аналитикой

**Следующие шаги:**
1. Настройте автоматическое развертывание на VPS
2. Добавьте тесты и CI/CD
3. Привлеките сообщество к развитию проекта
4. Создайте документацию на разных языках

---

**🚀 Удачи с вашим проектом!**
