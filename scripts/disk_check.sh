#!/usr/bin/env bash
# disk_check.sh(CR-3適応版)
set -u
CONF_FILE="/etc/ops/disk_check.conf"

# 【バリデーション1】設定ファイルが存在するか
if [ ! -f "$CONF_FILE" ]; then
    echo "[UNKNOWN] Config file not found: $CONF_FILE" >&2
    exit 2 # 判定不能
fi

# 【バリデーション1-2】設定ファイルを読めるか（600 root のため sudo 実行が前提）
if [ ! -r "$CONF_FILE" ]; then
    echo "[UNKNOWN] Config file not readable: $CONF_FILE (run with sudo)" >&2
    exit 2
fi

# 【安全な読み込み】余計なコマンド実行を許さず、KEY=VALUE形式のみ取り込む
while IFS='=' read -r key value; do
    # コメント行や空行をスキップ
    [[ "$key" =~ ^[[:space:]]*# ]] && continue
    [[ -z "$key" ]] && continue
    
    # 必要なキーのみを安全に変数へ代入
    case "$key" in
        TARGET_MOUNT)   TARGET_MOUNT="$value" ;;
        WARN_THRESHOLD) WARN_THRESHOLD="$value" ;;
        CRIT_THRESHOLD) CRIT_THRESHOLD="$value" ;;
    esac
done < "$CONF_FILE"

# 【バリデーション2】必須変数がセットされているか
if [ -z "${TARGET_MOUNT:-}" ] || [ -z "${WARN_THRESHOLD:-}" ] || [ -z "${CRIT_THRESHOLD:-}" ]; then
    echo "[UNKNOWN] Missing required parameters in config." >&2
    exit 2
fi

# 【バリデーション3】閾値が正の整数値になっているか
if ! [[ "$WARN_THRESHOLD" =~ ^[0-9]+$ ]] || ! [[ "$CRIT_THRESHOLD" =~ ^[0-9]+$ ]]; then
    echo "[UNKNOWN] Thresholds must be integers." >&2
    exit 2
fi

# （以降、既存のディスク使用率チェックと終了コード判定ロジック）
target="${1:-$TARGET_MOUNT}"
threshold="${2:-$WARN_THRESHOLD}"
crit_threshold="${3:-$CRIT_THRESHOLD}"
if [[ ! "$threshold" =~ ^[0-9]{1,3}$ ]] || [[ ! "$crit_threshold" =~ ^[0-9]{1,3}$ ]]; then
    echo 'UNKNOWN reason=invalid_threshold' >&2
    exit 2
fi
threshold=$((10#$threshold))
crit_threshold=$((10#$crit_threshold))
if (( threshold < 1 || threshold > 100 || crit_threshold < 1 || crit_threshold > 100 )); then
    echo 'UNKNOWN reason=threshold_out_of_range' >&2
    exit 2
fi
# 警告閾値は重大閾値より小さくなければならない（設定ファイル・引数どちらの指定でも検査）
if (( threshold >= crit_threshold )); then
    echo 'UNKNOWN reason=warn_not_less_than_crit' >&2
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
if (( used >= crit_threshold )); then
    printf '%s CRIT target=%s used=%s%% threshold=%s%%\n' \
        "$now" "$target" "$used" "$crit_threshold" >&2
    exit 1
fi
if (( used >= threshold )); then
    printf '%s WARN target=%s used=%s%% threshold=%s%%\n' \
        "$now" "$target" "$used" "$threshold" >&2
    exit 1
fi
printf '%s OK target=%s used=%s%% threshold=%s%%\n' \
    "$now" "$target" "$used" "$threshold"
exit 0
