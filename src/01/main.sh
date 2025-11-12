#!/usr/bin/env bash
set -euo pipefail

# запуск: ./main.sh /opt/test 4 az 5 az.az 3kb

SCRIPT_DIR="$(cd -- "$(dirname -- "$0")" && pwd)"

source "$SCRIPT_DIR/check_func.sh"
source "$SCRIPT_DIR/generator.sh"

if ! check_func "$@"; then
  exit 1
fi

generate_structure "$@"