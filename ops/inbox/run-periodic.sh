#!/bin/bash
# 定期実行のエントリポイント。launchdから5分間隔で起動され、
# 正本リポジトリ(GitHub)の更新を検知したとき、または前回のフル実行から1時間経過したときだけ
# claude -p のヘッドレスセッションを走らせる(どちらでもなければ静かに終了する)。
# 多重起動はロックファイルで防止する(取得失敗は黙って終了し、次の周回に任せる)。
set -u
export PATH="$HOME/.local/bin:/opt/homebrew/bin:/usr/local/bin:/usr/bin:/bin:/usr/sbin:/sbin"
cd "$HOME/workspace" || exit 1

REPO_DIR="$HOME/workspace/docs"
LOG_DIR="$HOME/workspace/docs/ops/inbox/logs"
mkdir -p "$LOG_DIR"
LOG="$LOG_DIR/periodic-$(date +%Y-%m-%d).log"
LOCK="$LOG_DIR/run.lock"
STATE="$LOG_DIR/last-run-state"

# --- 多重起動防止 ---
if [ -e "$LOCK" ]; then
  lock_age=$(( $(date +%s) - $(stat -f %m "$LOCK" 2>/dev/null || echo 0) ))
  if [ "$lock_age" -lt 5400 ]; then
    exit 0  # 実行中(90分未満)とみなして何もしない
  fi
  echo "$(date '+%F %T') 古いロック(${lock_age}s経過)を無視して続行" >>"$LOG"
fi
echo "$$" >"$LOCK"
trap 'rm -f "$LOCK"' EXIT

# --- 実行要否の判定(リモート更新 or 前回フル実行から1時間経過) ---
remote_hash=$(cd "$REPO_DIR" && git ls-remote origin -h refs/heads/main 2>>"$LOG" | awk '{print $1}')
last_hash=""
last_full=0
[ -f "$STATE" ] && read -r last_hash last_full <"$STATE"
now=$(date +%s)
trigger=""
if [ "$(( now - ${last_full:-0} ))" -ge 3600 ]; then
  trigger="hourly"
fi
if [ -n "$remote_hash" ] && [ "$remote_hash" != "$last_hash" ]; then
  trigger="repo-update"
fi
# remote_hash取得失敗時(ネットワーク断など)は毎時ペースにフォールバックする
[ -z "$trigger" ] && exit 0

{
  echo "===== $(date '+%F %T') 開始 (trigger: $trigger) ====="
  claude -p "$(cat docs/ops/inbox/periodic-prompt.md)" \
    --chrome \
    --dangerously-skip-permissions \
    --output-format text
  echo "===== $(date '+%F %T') 終了 (exit $?) ====="
} >>"$LOG" 2>&1

# セッション自身のpushでリモートが進むため、実行後のハッシュを記録して即時の再発火を防ぐ
post_hash=$(cd "$REPO_DIR" && git ls-remote origin -h refs/heads/main 2>/dev/null | awk '{print $1}')
echo "${post_hash:-$remote_hash} $now" >"$STATE"
