#!/usr/bin/env bash

set -euo pipefail

# Combined формат: 
# "%h %l %u %t \"%r\" %>s %b \"%{Referer}i\" \"%{User-agent}i\""

# где:

#   %h  — IP клиента
#   %l  — RFC1413 идентификатор (обычно "-")
#   %u  — имя пользователя (обычно "-")
#   %t  — дата/время в [12/Dec/2012:12:12:12 +0000]
#   %r  — запрос в кавычках: "METHOD /path HTTP/1.1"
#   %>s — HTTP статус
#   %b  — размер ответа в байтах (или "-" для 304, но 304 мы не используем)
#   "Referer" — откуда пришёл пользователь
#   "User-Agent" — строка клиента (браузер/бот/библиотека)

# Коды ответа (что означают):
#   200 OK      — успешный запрос, ответ в теле
#   201 Created — ресурс успешно создан (обычно для POST)
#   400 Bad Request      — синтаксическая ошибка в запросе
#   401 Unauthorized     — требуется аутентификация
#   403 Forbidden        — доступ запрещён
#   404 Not Found        — ресурс не найден
#   500 Internal Server Error — внутренняя ошибка сервера
#   501 Not Implemented       — метод/функция не поддерживаются
#   502 Bad Gateway           — ошибка шлюза (проксируемого бэкенда)
#   503 Service Unavailable   — сервер временно недоступен/перегружен

# ---------------------------------------------------------

# Настройки
OUT_DIR="$(dirname "$0")"   # Логи в директории скрипта
DAYS=5                      # Кол-во дней
MIN_LINES=100
MAX_LINES=1000

# Наборы значений
STATUSES=(200 201 400 401 403 404 500 501 502 503)
METHODS=(GET POST PUT PATCH DELETE)
AGENTS=(
    "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 Chrome/124.0 Safari/537.36"
    "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/605.1.15 Version/17.0 Safari/605.1.15"
    "Mozilla/5.0 (X11; Linux x86_64) Gecko/20100101 Firefox/125.0"
    "Mozilla/5.0 (Windows NT 10.0; Win64; x64) Edg/124.0"
    "Opera/9.80 (Windows NT 6.1; WOW64) Presto/2.12 Version/12.18"
    "Mozilla/5.0 (compatible; Googlebot/2.1; +http://www.google.com/bot.html)"
    "curl/8.5.0"
    "Wget/1.21.4 (linux-gnu)"
    "PostmanRuntime/7.39.0"
)

# Несколько наборов сегментов для красивых URL
URL_SEG_A=(api v1 v2 users items products orders search auth files images posts news profile settings stats)
URL_SEG_B=(list get show update delete create info details upload download feed recent popular top)

# Возможные рефереры
REFS=(
    "-"  # чаще всего пустой
    "https://www.google.com/"
    "https://www.bing.com/"
    "https://example.com/"
    "https://news.ycombinator.com/"
    "https://github.com/"
    "https://www.youtube.com/"
)

# === Помощники ===
rand_between() { # rand_between MIN MAX -> echo int
    local min="$1" max="$2"
    echo $(( RANDOM % (max - min + 1) + min ))
}

random_ip() {    # валидный IPv4: A(1..254).B(0..255).C(0..255).D(1..254)
    local a b c d

    a=$(rand_between 1 254)
    b=$(rand_between 0 255)
    c=$(rand_between 0 255)
    d=$(rand_between 1 254)
    echo "${a}.${b}.${c}.${d}"
}

pick_from() {    # pick_from ARRAY... -> echo element
    # вызывает как: pick_from "${ARRAY[@]}"
    local arr=( "$@" )
    local idx=$(( RANDOM % ${#arr[@]} ))
    echo "${arr[$idx]}"
}

random_url_path() {
    # Собираем что-то вроде: /api/v1/users/list?id=123&sort=desc
    local a b id sortord
    a=$(pick_from "${URL_SEG_A[@]}")
    b=$(pick_from "${URL_SEG_B[@]}")
    id=$(rand_between 1 9999)
    sortord=$(pick_from asc desc)
    echo "/${a}/${b}?id=${id}&sort=${sortord}"
}

random_size_for_status() {
    # Примерная логика: ошибки 4xx/5xx обычно <= 10KB,
    # успешные 2xx могут быть крупнее, 1..200KB
    local st="$1"

    if [[ "$st" -ge 400 ]]; then
        echo $(( $(rand_between 200 10000) ))
    else
        echo $(( $(rand_between 500 200000) ))
    fi
}

# Формат даты для лога: [12/Dec/2012:12:12:12 +0000]
fmt_log_time() { # fmt_log_time <unix_ts>
    local ts="$1"
    date -u -d "@${ts}" '+[%d/%b/%Y:%H:%M:%S +0000]'
}

generate_day_log() {
    local day_shift="$1"   # 0 = сегодня, 1 = вчера, и т.д.
    local base_day_ts
    base_day_ts=$(date -d "-${day_shift} day 00:00:00" +%s)

    # Сколько строк в этом дневном файле
    local lines
    lines=$(rand_between "$MIN_LINES" "$MAX_LINES")

    # Файл лога, например: access-2025-10-31.log
    local fname
    fname="access-$(date -d "-${day_shift} day" +%Y-%m-%d).log"

    local fpath="${OUT_DIR}/${fname}"

    # Сгенерим N случайных секунд от 0..86399, отсортируем — получится возрастающая временная шкала
    local -a secs=()

    for ((i=0; i<lines; i++)); do
        secs+=( "$(rand_between 0 86399)" )
    done

    # сортировка
    IFS=$'\n' secs=( $(printf '%s\n' "${secs[@]}" | sort -n) )
    unset IFS

    # Генерация самих записей
    : > "$fpath"  # очистить файл

    for s in "${secs[@]}"; do
        local ip method path status bytes ref ua ts req
        ip=$(random_ip)
        method=$(pick_from "${METHODS[@]}")
        path=$(random_url_path)
        status=$(pick_from "${STATUSES[@]}")
        bytes=$(random_size_for_status "$status")
        ref=$(pick_from "${REFS[@]}")
        ua=$(pick_from "${AGENTS[@]}")

        ts=$(fmt_log_time $(( base_day_ts + s )))
        req="${method} ${path} HTTP/1.1"

        # Combined format:
        # %h %l %u %t "%r" %>s %b "Referer" "User-Agent"
        printf '%s - - %s "%s" %d %d "%s" "%s"\n' \
            "$ip" "$ts" "$req" "$status" "$bytes" "$ref" "$ua" >> "$fpath"
    done
    echo "Сгенерирован лог: $fpath  (строк: $lines)"
}

main() {
    echo "== Генерация 5 access-логов nginx (combined) =="
    for ((d=0; d< DAYS; d++)); do
        generate_day_log "$d"
    done
    echo "Готово."
}

main "$@"