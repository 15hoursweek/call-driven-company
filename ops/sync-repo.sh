#!/bin/bash
# 指定したローカル作業コピーとGitHub正本を同期する汎用版。
# 使い方: sync-repo.sh <リポジトリのローカルパス>（例: sync-repo.sh "$HOME/workspace/call-driven-company"）
# ローカル変更を自動コミット → pull --rebase → push。競合時は失敗ログを残して非0終了する
# （リポジトリはrebase途中の状態で止まるので、コンフリクト解消後に再実行する）。
# docs/ の同期は従来どおり sync-docs.sh を使う（このスクリプトはそれ以外のリポジトリ用）。
set -euo pipefail
export PATH="/opt/homebrew/bin:/usr/local/bin:/usr/bin:/bin"

if [ $# -ne 1 ]; then
  echo "使い方: $0 <リポジトリのローカルパス>" >&2
  exit 1
fi

LOCAL="$1"
if [ ! -d "$LOCAL/.git" ]; then
  echo "エラー: $LOCAL はgitリポジトリではない" >&2
  exit 1
fi

NAME="$(basename "$LOCAL")"
LOG="$HOME/workspace/docs/ops/inbox/logs/sync-$NAME.log"

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
