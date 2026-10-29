#!/bin/bash
# ------------------------------------------------------------------
# backup_dir.sh (CR-2 対応版)
# 用途: 指定ディレクトリを tar.gz 形式でバックアップ保存する
# 終了コード:
#   0: 正常終了（アーカイブ生成成功）
#   1: 異常終了（tar 圧縮処理自体の失敗）
#   2: 取得・実行前失敗（引数不足、対象不在、保存先書込不可）
# ------------------------------------------------------------------

TARGET_DIR="$1"
DEST_DIR="$2"

# 1. 引数チェック
if [ -z "$TARGET_DIR" ] || [ -z "$DEST_DIR" ]; then
    echo "[ERROR] 使用方法: $0 <バックアップ対象ディレクトリ> <保存先ディレクトリ>" >&2
    exit 2
fi

# 2. 対象ディレクトリの存在確認
if [ ! -d "$TARGET_DIR" ]; then
    echo "[FAIL] 対象ディレクトリが存在しません: $TARGET_DIR" >&2
    exit 2
fi

# 3. 保存先ディレクトリの作成と書込権限チェック
if [ ! -d "$DEST_DIR" ]; then
    mkdir -p "$DEST_DIR" 2>/dev/null
    if [ $? -ne 0 ]; then
        echo "[FAIL] 保存先ディレクトリを作成できません: $DEST_DIR" >&2
        exit 2
    fi
fi

# 保存先への書き込み権限テスト
if [ ! -w "$DEST_DIR" ]; then
    echo "[FAIL] 保存先ディレクトリへの書き込み権限がありません: $DEST_DIR" >&2
    exit 2
fi

# 4. アーカイブ作成
TIMESTAMP=$(date +%Y%m%d_%H%M%S)
TARGET_BASE=$(basename "$TARGET_DIR")
ARCHIVE_NAME="${TARGET_BASE}_backup_${TIMESTAMP}.tar.gz"
DEST_FILE="${DEST_DIR}/${ARCHIVE_NAME}"

tar -czf "$DEST_FILE" -C "$(dirname "$TARGET_DIR")" "$TARGET_BASE" 2>/dev/null
TAR_EXIT=$?

if [ $TAR_EXIT -ne 0 ]; then
    echo "[WARN] tar アーカイブ作成に失敗しました (終了コード: $TAR_EXIT)" >&2
    exit 1
fi

echo "[OK] バックアップ正常完了: $DEST_FILE"
exit 0
