# 🖥️ Hestia System Info - Кастомная команда для Hestia CP

Кастомная команда `v-system-info` для Hestia CP, которая собирает информацию о системе локально с красивым визуальным отображением.

## ✨ Возможности

- **🔧 Модель процессора** - полное название модели CPU
- **💾 Занятое место на диске** - в процентах и абсолютных значениях с прогресс-баром
- **🧠 Оперативная память** - общий объем, использовано, свободно с визуализацией
- **💾 Статус удаленного бекапа** - включен/выключен с цветными индикаторами
- **📁 Наличие папок в /root** - link-manager, google-auth, tc-api-site-details

## 📁 Структура проекта

```
Hestia CPU API/
├── v-system-info              # 🖥️ CLI команда (218 строк)
├── v-system-info.php          # 🔧 Локальный PHP обработчик (57 строк)
├── hestia-api-integration.php # 🔗 Расширенный локальный обработчик (146 строк)
├── install.sh                 # ⚙️ Автоматический установщик (201 строка)
└── lib/                       # 📚 Библиотеки
    ├── system_info.sh         # 🔧 Bash функции (165 строк)
    └── SystemInfo.php         # 🐘 PHP класс (116 строк)
```

**Общий объем**: 1031 строка кода | **Размер проекта**: ~45KB

## Установка

```bash
# Автоматическая установка
sudo ./install.sh

# Ручная установка
sudo cp v-system-info /usr/local/hestia/bin/
sudo chmod +x /usr/local/hestia/bin/v-system-info
sudo ln -s /usr/local/hestia/bin/v-system-info /usr/local/bin/v-system-info

sudo cp v-system-info.php /usr/local/hestia/web/
sudo cp hestia-api-integration.php /usr/local/hestia/web/

sudo mkdir -p /usr/local/hestia/lib/hestia-system-info
sudo cp lib/system_info.sh /usr/local/hestia/lib/hestia-system-info/
sudo cp lib/SystemInfo.php /usr/local/hestia/lib/hestia-system-info/

sudo chown www-data:www-data /usr/local/hestia/web/*.php
sudo chmod 644 /usr/local/hestia/web/*.php
```

## Использование

### CLI команда
```bash
v-system-info          # Текстовый вывод
v-system-info --json   # JSON вывод
v-system-info --help   # Справка
```

### Локальное использование
```bash
# Основная команда
v-system-info

# Дополнительные опции
v-system-info --json   # JSON вывод
v-system-info --help   # Справка
v-system-info --cpu    # Только информация о CPU
v-system-info --disk   # Только информация о диске
v-system-info --ram    # Только информация о RAM
```

## Архитектура

### Модульная структура
- **lib/system_info.sh** - Bash функции для CLI
- **lib/SystemInfo.php** - PHP класс для локальной обработки
- Автоматическое подключение библиотек
- Fallback функции для совместимости

### Безопасность
- Проверка административных привилегий
- Локальное выполнение команд
- Валидация входных данных

## Требования

- Hestia CP (любая версия)
- PHP 7.4+
- Bash shell
- Стандартные Unix утилиты (df, free, grep, awk, sed, stat)

## 📊 Пример вывода

### CLI (текстовый режим):
```
╔══════════════════════════════════════════════════════════════╗
║                    🖥️  ИНФОРМАЦИЯ О СИСТЕМЕ                    ║
╚══════════════════════════════════════════════════════════════╝

🔧 Модель процессора:
   ► AMD Ryzen 9 3900 12-Core Processor

💾 Использование диска:
   ► Использование: 1% [█░░░░░░░░░░░░░░░░░░░]
   ► Всего: 3.5T
   ► Использовано: 6.8G
   ► Доступно: 3.3T

🧠 Информация о RAM:
   ► Использование: 0.8% [█░░░░░░░░░░░░░░░░░░░]
   ► Всего: 125Gi
   ► Использовано: 1.1Gi
   ► Свободно: 121Gi

💾 Статус удаленного бекапа:
   ► Статус: ✅ активен

📁 Папки в /root:
   ► link-manager: ✅ СУЩЕСТВУЕТ
   ► google-auth: ✅ СУЩЕСТВУЕТ
   ► tc-api-site-details: ✅ СУЩЕСТВУЕТ

╔══════════════════════════════════════════════════════════════╗
║                      📊 КОНЕЦ ОТЧЕТА                          ║
╚══════════════════════════════════════════════════════════════╝
```

### JSON режим:
```json
{
  "cpu": {
    "model": "AMD Ryzen 9 3900 12-Core Processor"
  },
  "disk": {
    "usage_percent": 1,
    "total": "3.5T",
    "used": "6.8G",
    "available": "3.3T"
  },
  "ram": {
    "total": "125Gi",
    "used": "1.1Gi",
    "free": "121Gi",
    "usage_percent": 0.8
  },
  "remote_backup": {
    "enabled": true,
    "status": "активен"
  },
  "root_folders": {
    "link-manager": {
      "exists": true,
      "path": "/root/link-manager",
      "permissions": "755"
    },
    "google-auth": {
      "exists": true,
      "path": "/root/google-auth",
      "permissions": "755"
    },
    "tc-api-site-details": {
      "exists": true,
      "path": "/root/tc-api-site-details",
      "permissions": "755"
    }
  }
}
```

## Лицензия

MIT License
