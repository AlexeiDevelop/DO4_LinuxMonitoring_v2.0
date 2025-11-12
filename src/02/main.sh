#!/usr/bin/env bash
set -euo pipefail

# Подтягиваем функции
source "$(dirname "$0")/check_func.sh"
source "$(dirname "$0")/generator.sh"

# === 1) Валидация входа ===
if [[ $# -ne 3 ]]; then
  echo "Usage: $0 <dir_letters> <name.ext_letters> <sizeMB>" >&2
  echo "Example: $0 az az.az 3Mb" >&2
  exit 1
fi

DIR_LETTERS="$1"     # напр.: az
FILE_PATTERN="$2"    # напр.: az.az
SIZE_MB_RAW="$3"     # напр.: 3Mb

# Проверка текущего места запуска (запрещаем *bin/*sbin*)
CURR="$(pwd)"
if [[ "$CURR" == *bin* || "$CURR" == *sbin* ]]; then
    echo "Ошибка: путь запуска содержит 'bin' или 'sbin' ($CURR). Перейдите в другой каталог." >&2
    exit 1
fi

check_func "$DIR_LETTERS" "$FILE_PATTERN" "$SIZE_MB_RAW"

# === 2) Генерация ===
START_TS="$(date +%s)"
START_HUMAN="$(date '+%Y-%m-%d %H:%M:%S')"

generate_structure "$DIR_LETTERS" "$FILE_PATTERN" "$SIZE_MB_RAW"

END_TS="$(date +%s)"
END_HUMAN="$(date '+%Y-%m-%d %H:%M:%S')"
DUR="$(( END_TS - START_TS ))"

echo
echo "Start time  : $START_HUMAN"
echo "Finish time : $END_HUMAN"
echo "Duration    : ${DUR} sec"

# Допишем в лог финальные тайминги (удобно иметь в одном месте)
{
    echo "=== SUMMARY ==="
    echo "Start:  $START_HUMAN"
    echo "Finish: $END_HUMAN"
    echo "Duration: ${DUR} sec"
} >> create_v2.log