#!/usr/bin/env bash
set -euo pipefail

clean_by_log() {
    local log="create_v2.log"
    if [[ ! -f "$log" ]]; then
        echo "Ошибка: лог-файл '$log' не найден в $(pwd)" >&2
        return 1
    fi

    echo "Удаление по логу ($log)..."
    while IFS=';' read -r path date size; do
        path="$(echo "$path" | xargs)"
        if [[ -e "$path" ]]; then
            rm -rf -- "$path"
            echo "Удалено: $path"
        fi
    done < "$log"

    echo "Готово: все объекты из лога удалены."
}

clean_by_date() {
    echo "Введите начальную дату и время (YYYY-MM-DD HH:MM):"
    read -r START
    echo "Введите конечную дату и время (YYYY-MM-DD HH:MM):"
    read -r END

    local start_ts end_ts
    start_ts="$(date -d "$START" +%s 2>/dev/null || true)"
    end_ts="$(date -d "$END" +%s 2>/dev/null || true)"

    if [[ -z "$start_ts" || -z "$end_ts" ]]; then
        echo "Ошибка: неверный формат даты." >&2
        return 1
    fi

    echo "Удаляем объекты, созданные между $START и $END..."

    local log="create_v2.log"
    if [[ ! -f "$log" ]]; then
        echo "Ошибка: лог '$log' не найден." >&2
        return 1
    fi

    while IFS=';' read -r path date size; do
        path="$(echo "$path" | xargs)"
        date="$(echo "$date" | xargs)"
        [[ -z "$path" || -z "$date" ]] && continue

        local file_ts
        file_ts="$(date -d "$date" +%s 2>/dev/null || true)"

        if (( file_ts >= start_ts && file_ts <= end_ts )); then
            if [[ -e "$path" ]]; then
                rm -rf -- "$path"
                echo "Удалено: $path ($date)"
            fi
        fi
    done < "$log"

    echo "Очистка по дате завершена."
}

clean_by_mask() {
    echo "Введите маску (например az_021125):"
    read -r MASK
    [[ -z "$MASK" ]] && { echo "Маска пуста."; return 1; }

    echo "Удаление по маске '$MASK'..."
    find . -type d -name "*${MASK}*" -exec rm -rf {} + 2>/dev/null
    find . -type f -name "*${MASK}*" -exec rm -f {} + 2>/dev/null

    echo "Очистка по маске завершена."
}