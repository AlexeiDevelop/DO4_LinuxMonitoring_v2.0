#!/usr/bin/env bash
set -euo pipefail

check_func() {

    local base="$1"          # абсолютный путь
    local nfolders="$2"      # кол-во вложенных папок
    local letters_dir="$3"   # буквы для имён папок (до 7, только a-z)
    local nfiles="$4"        # кол-во файлов в каждой папке
    local file_pat="$5"      # буквы для имени и расширения файла: имя.расш (до 7 и до 3)
    local fsize="$6"         # размер файлов: Nkb, 1..100


    if [[ ! "$base" = /* ]]; then
        echo "Ошибка: параметр 1 должен быть абсолютным путём (начинаться с '/')." >&2
        return 1
    fi

    base="${base%/}"

    if [[ "$base" =~ //+ ]]; then
        echo "Ошибка: параметр 1 не должен содержать несколько подряд '/'" >&2
        return 1
    fi

    if [[ "$base" =~ (^|/)bin(/|$) || "$base" =~ (^|/)sbin(/|$) ]]; then
        echo "Ошибка: путь '$base' содержит 'bin' или 'sbin'. Создание там запрещено!" >&2
        return 1
    fi

    local parent
    parent="$(dirname -- "$base")"
    if [[ ! -d "$parent" ]]; then
        echo "Ошибка: директория-родитель '$parent' не существует." >&2
        return 1
    fi
    
    if [[ ! -w "$parent" ]]; then
        echo "Ошибка: нет прав на запись в '$parent'." >&2
        return 1
    fi

    if [[ ! "$nfolders" =~ ^[0-9]+$ ]] || (( nfolders < 1 )); then
        echo "Ошибка: параметр 2 (кол-во папок) должен быть положительным целым." >&2
        return 1
    fi

    if [[ ! "$letters_dir" =~ ^[a-z]{1,7}$ ]]; then
        echo "Ошибка: параметр 3 — только латинские строчные буквы, длина 1..7 (пример: 'az')." >&2
        return 1
    fi

    if [[ ! "$nfiles" =~ ^[0-9]+$ ]] || (( nfiles < 1 )); then
        echo "Ошибка: параметр 4 (кол-во файлов) должен быть положительным целым." >&2
        return 1
    fi

    if [[ ! "$file_pat" =~ ^([a-z]{1,7})\.([a-z]{1,3})$ ]]; then
        echo "Ошибка: параметр 5 должен быть в виде 'имя.расш' (только [a-z], имя 1..7, расширение 1..3), напр.: 'az.az'." >&2
        return 1
    fi

    if [[ ! "$fsize" =~ ^([1-9][0-9]?|100)([Kk][Bb])?$ ]]; then
        echo "Ошибка: параметр 6 — целое 1..100 (в КБ), допустимы формы '10' или '10kb'." >&2
        return 1
    fi

    local free_kb
    free_kb="$(df -k / | awk 'NR==2{print $4}')"
    if (( free_kb < 1048576 )); then  # 1 ГБ = 1024*1024 КБ
        echo "Стоп: на корневом разделе меньше 1 ГБ свободно. Прерываю работу." >&2
        return 1
    fi

    return 0
}
