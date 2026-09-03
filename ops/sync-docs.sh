#!/bin/bash
# docs/（ローカル作業コピー）と GitHub GITHUB_USERNAME/docs（正本）を同期する。
# 運用: セッション冒頭と、docs/ を編集した後に叩く。定期実行(③)も処理前後に叩く。
# ローカル変更を自動コミット → pull --rebase → push。競合時は失敗ログを残して非0終了する
# （リポジトリはrebase途中の状態で止まるので、コンフリクト解消後に再実行する）。
set -euo pipefail
export PATH="/opt/homebrew/bin:/usr/local/bin:/usr/bin:/bin"

LOCAL="$HOME/workspace/docs"
LOG="$HOME/workspace/docs/ops/inbox/logs/sync-docs.log"

mkdir -p "$(dirname "$LOG")"
cd "$LOCAL"

{
  echo "===== $(date '+%F %T') sync 開始 ====="
  git add -A
  if ! git diff --cached --quiet; then
    git commit -m "sync: ローカル変更を反映 ($(date '+%F %T'))"
  fi
  git pull --rebase origin main
  git push origin main
  echo "===== $(date '+%F %T') sync 完了 ====="
} >>"$LOG" 2>&1
