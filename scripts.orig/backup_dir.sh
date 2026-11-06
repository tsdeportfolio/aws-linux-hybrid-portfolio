#!/usr/bin/env bash
# Usage: backup_dir.sh SOURCE_DIRECTORY [SUBDIR_NAME]
set -u
source_dir="${1:-/etc/nginx}"
subdir="${2:-$(basename "$source_dir")}"
dest_dir="/home/user/portfolio-lab/backups/${subdir}"
mkdir -p "$dest_dir"
archive="$dest_dir/backup-$(date +%Y%m%d-%H%M%S)-$$.tar.gz"
if ! tar -czf "$archive" "$source_dir" 2>/dev/null; then
    echo 'NG reason=archive_failed' >&2
    exit 1
fi
printf '%s OK archive=%s\n' "$(date -Iseconds)" "$archive"
