#!/usr/bin/env bash
set -euo pipefail

source "$(dirname "$0")/check_func.sh"
source "$(dirname "$0")/clean_func.sh"

if [[ $# -ne 1 ]]; then
    echo "Usage: $0 <mode>"
    echo "1 - удалить по логу"
    echo "2 - удалить по дате и времени"
    echo "3 - удалить по маске имени"
    exit 1
fi

MODE="$1"
check_func "$MODE"

START_TS="$(date +%s)"
START_HUMAN="$(date '+%Y-%m-%d %H:%M:%S')"

case "$MODE" in
    1) clean_by_log ;;
    2) clean_by_date ;;
    3) clean_by_mask ;;
esac

END_TS="$(date +%s)"
END_HUMAN="$(date '+%Y-%m-%d %H:%M:%S')"
DUR="$(( END_TS - START_TS ))"

echo
echo "Start time  : $START_HUMAN"
echo "Finish time : $END_HUMAN"
echo "Duration    : ${DUR} sec"