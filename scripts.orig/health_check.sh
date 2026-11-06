#!/usr/bin/env bash
# Usage: health_check.sh [URL]
set -u
url=${1:-http://127.0.0.1/portfolio/health.txt}
now=$(date -Iseconds)
code=$(curl --silent --show-error --output /dev/null --write-out '%{http_code}' "$url")
rc=$?
if (( rc != 0 )); then
    printf '%s UNKNOWN url=%s curl_rc=%s\n' "$now" "$url" "$rc" >&2
    exit 2
fi
if [[ "$code" != 200 ]]; then
    printf '%s NG url=%s http=%s\n' "$now" "$url" "$code" >&2
    exit 1
fi
printf '%s OK url=%s http=%s\n' "$now" "$url" "$code"
exit 0
