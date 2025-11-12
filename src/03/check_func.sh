#!/usr/bin/env bash
set -euo pipefail

check_func() {
  local mode="$1"
  if [[ ! "$mode" =~ ^[123]$ ]]; then
    echo "Ошибка: параметр должен быть 1, 2 или 3." >&2
    exit 1
  fi
  return 0
}