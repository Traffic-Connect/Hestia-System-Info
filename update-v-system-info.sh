#!/bin/bash
set -euo pipefail

# === Настройки ===
REPO_DIR="/root/hestia-system-info"             # путь к локальному клону репозитория
BRANCH="main"
PLUGIN_REL_PATH="v-system-info"                  # путь к файлу плагина внутри репо
DEST_PATH="/usr/local/hestia/bin/v-system-info"  # куда устанавливаем плагин
STATE_FILE="$REPO_DIR/.last_commit"              # хранит последний применённый commit
LOG_FILE="/var/log/v-system-info.log"            # общий лог

# === Логгер ===
log() {
  if [ ! -e "$LOG_FILE" ]; then
    touch "$LOG_FILE" 2>/dev/null || true
    chmod 644 "$LOG_FILE" 2>/dev/null || true
  fi
  echo "[$(date -Is)] $*" | tee -a "$LOG_FILE"
}

# === Проверки окружения ===
if [ "${EUID:-$(id -u)}" -ne 0 ]; then
  echo "Этот скрипт нужно запускать от root" >&2
  exit 1
fi

if [ ! -d "$REPO_DIR/.git" ]; then
  log "Ошибка: репозиторий не найден по пути $REPO_DIR (.git отсутствует). Пропускаю."
  exit 0
fi

# === Обновляем локальный репозиторий ===
log "Обновляю репозиторий в $REPO_DIR"
git -C "$REPO_DIR" fetch --prune origin
git -C "$REPO_DIR" checkout "$BRANCH" >/dev/null 2>&1 || git -C "$REPO_DIR" checkout -b "$BRANCH" "origin/$BRANCH"
git -C "$REPO_DIR" reset --hard "origin/$BRANCH"

LATEST_COMMIT="$(git -C "$REPO_DIR" rev-parse origin/$BRANCH)"
PREV_COMMIT="$(cat "$STATE_FILE" 2>/dev/null || echo "")"

chmod 700 "$REPO_DIR/update-v-system-info.sh" 2>/dev/null || true

# === Проверяем наличие файла плагина ===
PLUGIN_PATH="$REPO_DIR/$PLUGIN_REL_PATH"
if [ ! -f "$PLUGIN_PATH" ]; then
  log "Файл плагина '$PLUGIN_REL_PATH' не найден в репозитории — пропуск обновления."
  exit 0
fi

NEED_UPDATE=true
if [ -n "$PREV_COMMIT" ] && [ "$PREV_COMMIT" = "$LATEST_COMMIT" ]; then
  if [ -f "$DEST_PATH" ] && cmp -s "$PLUGIN_PATH" "$DEST_PATH"; then
    NEED_UPDATE=false
  fi
fi

if [ "$NEED_UPDATE" = true ]; then
  log "Обнаружено обновление main: ${PREV_COMMIT:-none} → $LATEST_COMMIT. Обновляю плагин..."
  tmpfile="$(mktemp)"
  cp "$PLUGIN_PATH" "$tmpfile"
  install -o root -g root -m 750 "$tmpfile" "$DEST_PATH"
  rm -f "$tmpfile"
  echo "$LATEST_COMMIT" > "$STATE_FILE"
  log "Плагин обновлён: $DEST_PATH (root:root, 750)"
else
  log "Обновлений нет."
fi
