#!/usr/bin/env bash
set -euo pipefail

_make_name_part() {
  local pattern="$1" min_len="$2" max_len="$3"
  local out=""

  while (( ${#out} < min_len )); do
    out+="$pattern"
  done

  if (( ${#out} > max_len )); then
    out="${out:0:max_len}"
  fi
  echo -n "$out"
}

_parse_kb() {
  local s="$1"
  s="${s%KB}"; s="${s%kb}"; s="${s%Kb}"; s="${s%kB}"
  echo -n "$s"
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
    printf "%s; %s; %s\n" "$path" "$now" "-" >> create.log
  else
    printf "%s; %s; %s\n" "$path" "$now" "$fsize" >> create.log
  fi
}

generate_structure() {
  local base="$1" nfolders="$2" letters_dir="$3" nfiles="$4" file_pat="$5" fsize_raw="$6"

  base="${base%/}"
  mkdir -p -- "$base"

  local name_letters ext_letters
  name_letters="${file_pat%%.*}"
  ext_letters="${file_pat##*.}"

  local D
  D="$(date +'%d%m%y')"

  local K
  K="$(_parse_kb "$fsize_raw")"

  for ((i=1; i<=nfolders; i++)); do
    if ! _has_enough_space; then
      echo "Останов: свободного места < 1 ГБ. Дальше не создаю." >&2
      return 0
    fi

    local dir_part
    dir_part="$(_make_name_part "$letters_dir" 4 32)"
    local dir_name="${dir_part}_${D}"
    local dir_path="$base/$dir_name"

    if [[ -e "$dir_path" ]]; then
      dir_path="${dir_path}-$i"
    fi

    mkdir -p -- "$dir_path"
    _log_create "$dir_path" "dir"

    for ((j=1; j<=nfiles; j++)); do
      if ! _has_enough_space; then
        echo "Останов: свободного места < 1 ГБ. Дальше не создаю." >&2
        return 0
      fi

      local fname_part ext_part
      fname_part="$(_make_name_part "$name_letters" 4 7)"
      ext_part="$(_make_name_part "$ext_letters" 1 3)"

      local fname="${fname_part}_${D}.${ext_part}"
      local fpath="$dir_path/$fname"

      if [[ -e "$fpath" ]]; then
        fpath="$dir_path/${fname_part}_${D}-${j}.${ext_part}"
      fi

      dd if=/dev/zero of="$fpath" bs=1K count="$K" status=none

      _log_create "$fpath" "file" "${K}KB"
    done
  done

  echo "Готово. Лог: $(readlink -f create.log)"
}