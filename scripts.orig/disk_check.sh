#!/usr/bin/env bash
# Usage: disk_check.sh [TARGET_PATH] [THRESHOLD_PERCENT]
set -u
target=${1:-/}
threshold=${2:-80}
if [[ ! "$threshold" =~ ^[0-9]{1,3}$ ]]; then
    echo 'UNKNOWN reason=invalid_threshold' >&2
    exit 2
fi
threshold=$((10#$threshold))
if (( threshold < 1 || threshold > 100 )); then
    echo 'UNKNOWN reason=threshold_out_of_range' >&2
    exit 2
fi
result=$(LC_ALL=C df -P -- "$target")
rc=$?
if (( rc != 0 )); then
    echo 'UNKNOWN reason=df_failed' >&2
    exit 2
fi
used=$(awk 'NR==2 {gsub(/%/, "", $5); print $5}' <<< "$result")
if [[ ! "$used" =~ ^[0-9]+$ ]]; then
    echo 'UNKNOWN reason=unreadable_usage' >&2
    exit 2
fi
now=$(date -Iseconds)
if (( used >= threshold )); then
    printf '%s WARN target=%s used=%s%% threshold=%s%%\n' \
        "$now" "$target" "$used" "$threshold" >&2
    exit 1
fi
printf '%s OK target=%s used=%s%% threshold=%s%%\n' \
    "$now" "$target" "$used" "$threshold"
exit 0
