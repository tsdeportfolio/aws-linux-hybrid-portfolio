#!/usr/bin/env bash
# ------------------------------------------------------------------
# health_check.sh (CR-1 対応版)
# 用途: 指定URLの疎通および応答本文の妥当性を検証する
# 終了コード:
#   0: 正常（HTTP 200 かつ 期待文字列が存在）
#   1: 異常検知（HTTP 4xx/5xx、または 200 だが期待文字列が不一致）
#   2: 取得失敗（引数不正、接続タイムアウト、名前解決不可、接続拒否）
# ------------------------------------------------------------------

URL="$1"
EXPECTED_BODY="$2"

# 1. 引数チェック（指定がない場合は判定不能として終了コード 2）
if [ -z "$URL" ] || [ -z "$EXPECTED_BODY" ]; then
    echo "[ERROR] 使用方法: $0 <URL> <期待する本文文字列>" >&2
    exit 2
fi

# 2. curl 実行（タイムアウト指定 + 本文とステータスコードを同時取得）
#   --connect-timeout 3: TCPハンドシェイク上限3秒
#   --max-time 5       : 全体処理上限5秒
#   -s -S              : 進捗メーター非表示、エラーメッセージは標準エラーへ出力
TEMP_RESPONSE=$(mktemp)
HTTP_STATUS=$(curl -s -S \
    --connect-timeout 3 \
    --max-time 5 \
    -o "$TEMP_RESPONSE" \
    -w "%{http_code}" \
    "$URL" 2>/dev/null)
CURL_EXIT=$?

# 3. 一次判定: curl 自体の実行成否（ネットワーク・名前解決・タイムアウト）
if [ $CURL_EXIT -ne 0 ]; then
    echo "[FAIL] 通信失敗: 接続拒否またはタイムアウト (curl終了コード: $CURL_EXIT)" >&2
    rm -f "$TEMP_RESPONSE"
    exit 2
fi

# 4. 二次判定: HTTP ステータスコードの確認
if [ "$HTTP_STATUS" != "200" ]; then
    echo "[WARN] 異常検知: HTTP ステータスコード $HTTP_STATUS" >&2
    rm -f "$TEMP_RESPONSE"
    exit 1
fi

# 5. 三次判定: 期待する本文文字列が含まれているか
if ! grep -q "$EXPECTED_BODY" "$TEMP_RESPONSE"; then
    echo "[WARN] 異常検知: HTTP 200 ですが期待文字列 '$EXPECTED_BODY' が本文に含まれません" >&2
    rm -f "$TEMP_RESPONSE"
    exit 1
fi

# 正常終了
echo "[OK] 正常稼働: HTTP 200 かつ 本文に '$EXPECTED_BODY' を確認"
rm -f "$TEMP_RESPONSE"
exit 0
