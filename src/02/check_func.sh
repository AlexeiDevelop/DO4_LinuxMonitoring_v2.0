#!/usr/bin/env bash
set -euo pipefail

check_func() {
    local letters_dir="$1"
    local file_pat="$2"
    local size_raw="$3"

    if [[ ! "$letters_dir" =~ ^[a-z]{1,7}$ ]]; then
        echo "Ошибка: параметр 1 — только латинские строчные буквы, длина 1..7 (пример: 'az')." >&2
        exit 1
    fi

    if [[ ! "$file_pat" =~ ^([a-z]{1,7})\.([a-z]{1,3})$ ]]; then
        echo "Ошибка: параметр 2 — 'имя.расш' (имя 1..7; расширение 1..3; только [a-z]), напр.: 'az.az'." >&2
        exit 1
    fi

    local s="$size_raw"
    s="${s%MB}"; s="${s%mb}"; s="${s%Mb}"; s="${s%mB}"
    if [[ ! "$s" =~ ^([1-9][0-9]?|100)$ ]]; then
        echo "Ошибка: параметр 3 — целое 1..100 (в МБ), допустимы '10' или '10MB'." >&2
        exit 1
    fi

    local free_kb
    free_kb="$(df -k / | awk 'NR==2{print $4}')"
    if (( free_kb < 1048576 )); then
        echo "Стоп: на корневом разделе менее 1 ГБ свободно. Прерываю." >&2
        exit 1
    fi

    return 0
}