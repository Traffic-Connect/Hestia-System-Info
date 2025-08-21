#!/bin/bash
#
# Автоматическая установка кастомной команды v-system-info для Hestia CP
#

# Цвета для вывода
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # Без цвета

# Пути Hestia
HESTIA_BIN="/usr/local/hestia/bin"
HESTIA_WEB="/usr/local/hestia/web"
LOCAL_BIN="/usr/local/bin"
LIB_DIR="/usr/local/hestia/lib/hestia-system-info"

echo -e "${BLUE}=== Установка кастомной команды v-system-info для Hestia CP ===${NC}"
echo

# Проверяем, запущен ли скрипт от root
if [ "$EUID" -ne 0 ]; then
    echo -e "${RED}Ошибка: Этот скрипт должен быть запущен с правами root${NC}"
    echo "Используйте: sudo $0"
    exit 1
fi

# Проверяем, установлен ли Hestia
if [ ! -d "$HESTIA_BIN" ]; then
    echo -e "${RED}Ошибка: Hestia CP не найден в $HESTIA_BIN${NC}"
    echo "Убедитесь, что Hestia CP установлен на этом сервере"
    exit 1
fi

echo -e "${YELLOW}Проверка зависимостей...${NC}"

# Проверяем необходимые команды
required_commands=("df" "free" "grep" "awk" "sed" "stat")
missing_commands=()

for cmd in "${required_commands[@]}"; do
    if ! command -v "$cmd" &> /dev/null; then
        missing_commands+=("$cmd")
    fi
done

if [ ${#missing_commands[@]} -ne 0 ]; then
    echo -e "${RED}Ошибка: Отсутствуют необходимые команды:${NC}"
    for cmd in "${missing_commands[@]}"; do
        echo "  - $cmd"
    done
    echo "Установите недостающие пакеты и повторите установку"
    exit 1
fi

echo -e "${GREEN}✓ Все зависимости найдены${NC}"
echo

# Устанавливаем CLI команду
echo -e "${YELLOW}Установка CLI команды...${NC}"

if [ -f "v-system-info" ]; then
    cp v-system-info "$HESTIA_BIN/"
    chmod +x "$HESTIA_BIN/v-system-info"
    
    # Создаем символическую ссылку
    if [ -L "$LOCAL_BIN/v-system-info" ]; then
        rm "$LOCAL_BIN/v-system-info"
    fi
    ln -s "$HESTIA_BIN/v-system-info" "$LOCAL_BIN/v-system-info"
    
    echo -e "${GREEN}✓ CLI команда установлена${NC}"
else
    echo -e "${RED}Ошибка: Файл v-system-info не найден${NC}"
    exit 1
fi

# Устанавливаем PHP API файлы
echo -e "${YELLOW}Установка PHP API файлов...${NC}"

# Определяем пользователя веб-сервера
WEB_USER="www-data"
if command -v nginx &> /dev/null; then
    WEB_USER=$(ps aux | grep nginx | grep -v grep | head -1 | awk '{print $1}')
elif command -v apache2 &> /dev/null || command -v httpd &> /dev/null; then
    WEB_USER=$(ps aux | grep -E '(apache|httpd)' | grep -v grep | head -1 | awk '{print $1}')
fi

# По умолчанию www-data если определение не удалось
if [ -z "$WEB_USER" ] || [ "$WEB_USER" = "root" ]; then
    WEB_USER="www-data"
fi

if [ -f "v-system-info.php" ]; then
    cp v-system-info.php "$HESTIA_WEB/"
    chown $WEB_USER:$WEB_USER "$HESTIA_WEB/v-system-info.php" 2>/dev/null || chown root:root "$HESTIA_WEB/v-system-info.php"
    chmod 644 "$HESTIA_WEB/v-system-info.php"
    echo -e "${GREEN}✓ Основной API файл установлен${NC}"
else
    echo -e "${YELLOW}⚠ Файл v-system-info.php не найден, пропускаем${NC}"
fi

if [ -f "hestia-api-integration.php" ]; then
    cp hestia-api-integration.php "$HESTIA_WEB/"
    chown $WEB_USER:$WEB_USER "$HESTIA_WEB/hestia-api-integration.php" 2>/dev/null || chown root:root "$HESTIA_WEB/hestia-api-integration.php"
    chmod 644 "$HESTIA_WEB/hestia-api-integration.php"
    echo -e "${GREEN}✓ Расширенный API файл установлен${NC}"
else
    echo -e "${YELLOW}⚠ Файл hestia-api-integration.php не найден, пропускаем${NC}"
fi

# Устанавливаем файлы библиотеки
echo -e "${YELLOW}Установка файлов библиотеки...${NC}"
mkdir -p "$LIB_DIR"

if [ -f "lib/system_info.sh" ]; then
    cp "lib/system_info.sh" "$LIB_DIR/"
    chmod 644 "$LIB_DIR/system_info.sh"
    echo -e "${GREEN}✓ Bash библиотека установлена${NC}"
else
    echo -e "${YELLOW}⚠ Файл lib/system_info.sh не найден, пропускаем${NC}"
fi

if [ -f "lib/SystemInfo.php" ]; then
    cp "lib/SystemInfo.php" "$LIB_DIR/"
    chown $WEB_USER:$WEB_USER "$LIB_DIR/SystemInfo.php" 2>/dev/null || chown root:root "$LIB_DIR/SystemInfo.php"
    chmod 644 "$LIB_DIR/SystemInfo.php"
    echo -e "${GREEN}✓ PHP библиотека установлена${NC}"
else
    echo -e "${YELLOW}⚠ Файл lib/SystemInfo.php не найден, пропускаем${NC}"
fi

echo

# Проверяем установку
echo -e "${YELLOW}Проверка установки...${NC}"

if command -v v-system-info &> /dev/null; then
    echo -e "${GREEN}✓ Команда v-system-info доступна${NC}"
else
    echo -e "${RED}✗ Команда v-system-info не найдена${NC}"
fi

if [ -f "$HESTIA_WEB/v-system-info.php" ]; then
    echo -e "${GREEN}✓ API файл установлен в $HESTIA_WEB/v-system-info.php${NC}"
else
    echo -e "${YELLOW}⚠ API файл не найден${NC}"
fi

if [ -f "$LIB_DIR/system_info.sh" ]; then
    echo -e "${GREEN}✓ Bash библиотека установлена в $LIB_DIR/system_info.sh${NC}"
else
    echo -e "${YELLOW}⚠ Bash библиотека не найдена${NC}"
fi

if [ -f "$LIB_DIR/SystemInfo.php" ]; then
    echo -e "${GREEN}✓ PHP библиотека установлена в $LIB_DIR/SystemInfo.php${NC}"
else
    echo -e "${YELLOW}⚠ PHP библиотека не найдена${NC}"
fi

echo

# Информация об использовании
echo -e "${BLUE}=== Информация об использовании ===${NC}"
echo -e "${GREEN}CLI команда:${NC}"
echo "  v-system-info          # Текстовый вывод"
echo "  v-system-info --json   # JSON вывод"
echo "  v-system-info --help   # Справка"
echo

echo -e "${GREEN}Веб API:${NC}"
echo "  https://your-domain.com:8083/v-system-info.php"
echo "  https://your-domain.com:8083/hestia-api-integration.php"
echo

echo -e "${GREEN}Авторизация:${NC}"
echo "  Используйте логин/пароль от Hestia CP"
echo

echo -e "${BLUE}=== Установка завершена! ===${NC}"
echo -e "${GREEN}Теперь вы можете использовать команду v-system-info для получения информации о системе${NC}"
