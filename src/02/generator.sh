#!/usr/bin/env bash
set -euo pipefail

_make_name_part() {
    local pattern="$1" min_len="$2" max_len="$3"
    local out="$pattern"
    while (( ${#out} < min_len )); do
        out+="$pattern"
    done
    if (( ${#out} > max_len )); then
        out="${out:0:max_len}"
    fi
    printf "%s" "$out"
}

_parse_mb() {
    local s="$1"
    s="${s%MB}"; s="${s%mb}"; s="${s%Mb}"; s="${s%mB}"
    printf "%s" "$s"
}

_has_enough_space() {
    local free_kb
    free_kb="$(df -k / | awk 'NR==2{print $4}')"
    (( free_kb >= 1048576 ))
}

_log_create() {
    local path="$1" kind="$2" fsize="${3:-}"
    local now
    now="$(date '+%Y-%m-%d %H:%M:%S')"
    if [[ "$kind" == "dir" ]]; then
        printf "%s; %s; %s\n" "$path" "$now" "-" >> create_v2.log
    else
        printf "%s; %s; %s\n" "$path" "$now" "$fsize" >> create_v2.log
    fi
}

generate_structure() {
    local letters_dir="$1"
    local file_pat="$2"
    local size_raw="$3"

    local base
    base="$(pwd)"

    local name_letters ext_letters
    name_letters="${file_pat%%.*}"
    ext_letters="${file_pat##*.}"

    local D
    D="$(date +'%d%m%y')"

    local MB
    MB="$(_parse_mb "$size_raw")"

    local nfolders
    if command -v shuf >/dev/null 2>&1; then
        nfolders="$(shuf -i 1-100 -n 1)"
    else
        nfolders="$(( (RANDOM % 100) + 1 ))"
    fi

    echo "Будет создано папок: $nfolders (в каталоге: $base)"
    : > create_v2.log

    for ((i=1; i<=nfolders; i++)); do
        if ! _has_enough_space; then
            echo "Стоп: свободного места < 1 ГБ. Остановка генерации." >&2
            return 0
        fi

        local dir_part
        dir_part="$(_make_name_part "$letters_dir" 5 32)"
        local dir_name="${dir_part}_${D}"
        local dir_path="$base/$dir_name"
        [[ -e "$dir_path" ]] && dir_path="${dir_path}-${i}"

        mkdir -p -- "$dir_path"
        _log_create "$dir_path" "dir"

        local nfiles
        if command -v shuf >/dev/null 2>&1; then
            nfiles="$(shuf -i 1-10 -n 1)"
        else
            nfiles="$(( (RANDOM % 10) + 1 ))"
        fi

        for ((j=1; j<=nfiles; j++)); do
        if ! _has_enough_space; then
            echo "Стоп: свободного места < 1 ГБ. Остановка генерации." >&2
            return 0
        fi

        local fname_part ext_part
        fname_part="$(_make_name_part "$name_letters" 5 7)"
        ext_part="$(_make_name_part "$ext_letters" 1 3)"

        local fname="${fname_part}_${D}.${ext_part}"
        local fpath="$dir_path/$fname"
        [[ -e "$fpath" ]] && fpath="$dir_path/${fname_part}_${D}-${j}.${ext_part}"

        dd if=/dev/zero of="$fpath" bs=1M count="$MB" status=none

        _log_create "$fpath" "file" "${MB}MB"
        done
    done

    echo "Готово. Лог: $(readlink -f create_v2.log)"
}