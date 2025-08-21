#!/bin/bash
#
# Автоматическая установка кастомной команды v-system-info для Hestia CP
#

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Hestia paths
HESTIA_BIN="/usr/local/hestia/bin"
HESTIA_WEB="/usr/local/hestia/web"
LOCAL_BIN="/usr/local/bin"
LIB_DIR="/usr/local/hestia/lib/hestia-system-info"

echo -e "${BLUE}=== Установка кастомной команды v-system-info для Hestia CP ===${NC}"
echo

# Check if running as root
if [ "$EUID" -ne 0 ]; then
    echo -e "${RED}Ошибка: Этот скрипт должен быть запущен с правами root${NC}"
    echo "Используйте: sudo $0"
    exit 1
fi

# Check if Hestia is installed
if [ ! -d "$HESTIA_BIN" ]; then
    echo -e "${RED}Ошибка: Hestia CP не найден в $HESTIA_BIN${NC}"
    echo "Убедитесь, что Hestia CP установлен на этом сервере"
    exit 1
fi

echo -e "${YELLOW}Проверка зависимостей...${NC}"

# Check required commands
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

# Install CLI command
echo -e "${YELLOW}Установка CLI команды...${NC}"

if [ -f "v-system-info" ]; then
    cp v-system-info "$HESTIA_BIN/"
    chmod +x "$HESTIA_BIN/v-system-info"
    
    # Create symbolic link
    if [ -L "$LOCAL_BIN/v-system-info" ]; then
        rm "$LOCAL_BIN/v-system-info"
    fi
    ln -s "$HESTIA_BIN/v-system-info" "$LOCAL_BIN/v-system-info"
    
    echo -e "${GREEN}✓ CLI команда установлена${NC}"
else
    echo -e "${RED}Ошибка: Файл v-system-info не найден${NC}"
    exit 1
fi

# Install PHP API files
echo -e "${YELLOW}Установка PHP API файлов...${NC}"

# Detect web server user
WEB_USER="www-data"
if command -v nginx &> /dev/null; then
    WEB_USER=$(ps aux | grep nginx | grep -v grep | head -1 | awk '{print $1}')
elif command -v apache2 &> /dev/null || command -v httpd &> /dev/null; then
    WEB_USER=$(ps aux | grep -E '(apache|httpd)' | grep -v grep | head -1 | awk '{print $1}')
fi

# Default to www-data if detection fails
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

# Install libraries
echo -e "${YELLOW}Установка библиотек...${NC}"
mkdir -p "$LIB_DIR"
if [ -f "lib/system_info.sh" ]; then
    cp lib/system_info.sh "$LIB_DIR/"
    chmod 644 "$LIB_DIR/system_info.sh"
    echo -e "${GREEN}✓ Bash библиотека установлена${NC}"
else
    echo -e "${YELLOW}⚠ Bash библиотека не найдена: lib/system_info.sh${NC}"
fi

if [ -f "lib/SystemInfo.php" ]; then
    cp lib/SystemInfo.php "$LIB_DIR/"
    chmod 644 "$LIB_DIR/SystemInfo.php"
    echo -e "${GREEN}✓ PHP библиотека установлена${NC}"
else
    echo -e "${YELLOW}⚠ PHP библиотека не найдена: lib/SystemInfo.php${NC}"
fi

echo

# Test installation
echo -e "${YELLOW}Тестирование установки...${NC}"

if command -v v-system-info &> /dev/null; then
    echo -e "${GREEN}✓ CLI команда работает${NC}"
    
    # Test command output
    echo -e "${BLUE}Пробный запуск команды:${NC}"
    echo
    v-system-info --help
    echo
else
    echo -e "${RED}Ошибка: CLI команда не найдена${NC}"
fi

# Create test script
echo -e "${YELLOW}Создание тестового скрипта...${NC}"

cat > test-v-system-info.sh << 'EOF'
#!/bin/bash
echo "=== Тест кастомной команды v-system-info ==="
echo

echo "1. Тест CLI команды:"
if command -v v-system-info &> /dev/null; then
    echo "✓ Команда найдена"
    echo "Вывод команды:"
    v-system-info --json | head -20
else
    echo "✗ Команда не найдена"
fi

echo
echo "2. Тест PHP API:"
if [ -f "/usr/local/hestia/web/v-system-info.php" ]; then
    echo "✓ PHP API файл найден"
    echo "URL: https://your-domain.com/v-system-info.php"
else
    echo "✗ PHP API файл не найден"
fi

echo
echo "3. Проверка прав доступа:"
ls -la /usr/local/hestia/bin/v-system-info 2>/dev/null || echo "Файл не найден"
ls -la /usr/local/bin/v-system-info 2>/dev/null || echo "Ссылка не найдена"

echo
echo "=== Тест завершен ==="
EOF

chmod +x test-v-system-info.sh
echo -e "${GREEN}✓ Тестовый скрипт создан: test-v-system-info.sh${NC}"

echo
echo -e "${BLUE}=== Установка завершена ===${NC}"
echo
echo -e "${GREEN}Использование:${NC}"
echo "  CLI команда: v-system-info [--json|--text]"
echo "  Веб API: https://your-domain.com/v-system-info.php"
echo "  Тест: ./test-v-system-info.sh"
echo
echo -e "${YELLOW}Документация:${NC}"
echo "  См. файл README.md для подробной информации"
echo
echo -e "${BLUE}Примеры:${NC}"
echo "  v-system-info          # Текстовый вывод"
echo "  v-system-info --json   # JSON вывод"
echo "  v-system-info --help   # Справка"
