#!/usr/bin/env bash
set -euo pipefail

source "$(dirname "$0")/check_func.sh"

check_mode "$@"

MODE="$1"

LOGDIR="$(ask_logs_dir)"   # внутри проверяется наличие .log

LOG_INPUT=$(cat "$LOGDIR"/*.log)

OUTPUT_FILE="$(dirname "$0")/04_logs.log"

case "$MODE" in
  1)
    # Все записи, отсортированные по коду ответа
    # В combined-формате удобно выцеплять код regex-ом: он идёт ПОСЛЕ закрывающей кавычки запроса.
    # Препендим код в начало строки -> сортируем -> убираем префикс кода.
    printf "%s\n" "$LOG_INPUT" \
    | awk 'match($0, /" ([0-9]{3}) /, m){ print m[1] " " $0 }' \
    | sort -k1,1n \
    | cut -d" " -f2- > "$OUTPUT_FILE"
    ;;
  2)
    # Все уникальные IP
    printf "%s\n" "$LOG_INPUT" \
    | awk '{print $1}' \
    | sort -u > "$OUTPUT_FILE"
    ;;
  3)
    # Все запросы с ошибками (код 4xx или 5xx)
    printf "%s\n" "$LOG_INPUT" \
    | awk 'match($0, /" ([0-9]{3}) /, m){ c=m[1]+0; if (c>=400) print }' > "$OUTPUT_FILE"
    ;;
  4)
    # Все уникальные IP среди ошибочных запросов
    printf "%s\n" "$LOG_INPUT" \
    | awk 'match($0, /" ([0-9]{3}) /, m){ c=m[1]+0; if (c>=400) print $1 }' \
    | sort -u > "$OUTPUT_FILE"
    ;;
esac