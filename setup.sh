#!/bin/bash

echo "=== Настройка v-system-info для HestiaCP ==="

# --- Константы ---
REPO_URL="https://github.com/Traffic-Connect/Hestia-System-Info.git"
BRANCH="main"
REPO_DIR="/root/hestia-system-info"             # куда клонируем репозиторий
PLUGIN_REL_PATH="v-system-info"                  # путь к файлу плагина в репозитории
UPDATER_REL_PATH="update-v-system-info.sh"       # путь к апдейтеру внутри репозитория
DEST_PATH="/usr/local/hestia/bin/v-system-info"  # финальное расположение плагина
LOG_FILE="/var/log/v-system-info.log"            # лог фиксировано в /var/log

# --- Проверка прав ---
if [ "$EUID" -ne 0 ]; then
  echo "Ошибка: скрипт должен запускаться от root"
  exit 1
fi

# --- Подготовка директорий ---
mkdir -p "$REPO_DIR"
mkdir -p "$(dirname "$DEST_PATH")"

# --- Клонирование/обновление репозитория ---
if [ -d "$REPO_DIR/.git" ]; then
  echo "Обновляю репозиторий в $REPO_DIR"
  git -C "$REPO_DIR" fetch --prune origin
  git -C "$REPO_DIR" checkout "$BRANCH" >/dev/null 2>&1 || git -C "$REPO_DIR" checkout -b "$BRANCH" "origin/$BRANCH"
  git -C "$REPO_DIR" reset --hard "origin/$BRANCH"
else
  echo "Клонирую $REPO_URL в $REPO_DIR (ветка $BRANCH)"
  git clone --branch "$BRANCH" --single-branch "$REPO_URL" "$REPO_DIR"
fi

# --- Проверяем файлы ---
if [ ! -f "$REPO_DIR/$PLUGIN_REL_PATH" ]; then
  echo "Ошибка: в репозитории не найден файл плагина '$PLUGIN_REL_PATH'"
  exit 1
fi

if [ ! -f "$REPO_DIR/$UPDATER_REL_PATH" ]; then
  echo "Ошибка: в репозитории не найден апдейтер '$UPDATER_REL_PATH'"
  exit 1
fi

# --- Установка плагина ---
echo "Устанавливаю плагин в $DEST_PATH"
tmpfile="$(mktemp)"
cp "$REPO_DIR/$PLUGIN_REL_PATH" "$tmpfile"
install -o root -g root -m 750 "$tmpfile" "$DEST_PATH"
rm -f "$tmpfile"
echo "✓ Плагин установлен: $DEST_PATH (root:root, 750)"

# --- Подготовка апдейтера ---
UPDATER_PATH="$REPO_DIR/$UPDATER_REL_PATH"
chmod 700 "$UPDATER_PATH"
chown root:root "$UPDATER_PATH"
echo "✓ Апдейтер найден и подготовлен: $UPDATER_PATH"

# --- Создаём лог ---
touch "$LOG_FILE"
chmod 644 "$LOG_FILE"
chown root:root "$LOG_FILE"
echo "✓ Лог-файл создан: $LOG_FILE"

# --- Cron ---
CRON_CMD="25 2 * * * /bin/bash $UPDATER_PATH"
echo "Обновляю cron root..."

# Проверяем, есть ли уже такая запись
if crontab -l 2>/dev/null | grep -qF "$CRON_CMD"; then
  echo "✓ Cron задача уже существует: $CRON_CMD"
else
  ( crontab -l 2>/dev/null; echo "$CRON_CMD" ) | crontab -
  echo "✓ Cron задача добавлена: $CRON_CMD"
fi

echo ""
echo "=== Готово ==="
echo "✓ Репозиторий: $REPO_DIR (ветка $BRANCH)"
echo "✓ Плагин: $DEST_PATH"
echo "✓ Updater: $UPDATER_PATH"
echo "✓ Cron: ежедневно в 02:25"
echo "✓ Лог: $LOG_FILE"
echo ""
echo "Для ручного запуска обновления:"
echo "sudo bash $UPDATER_PATH"
echo ""
echo "Для просмотра логов:"
echo "tail -f $LOG_FILE"
