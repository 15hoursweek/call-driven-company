#!/bin/bash
# セッション冒頭に、放置されると滞留するTODOを提示する。
# SessionStart フックから sync-docs.sh の後に実行される。標準出力はそのままセッションのコンテキストに入る。
# 対象がなければ何も出力しない（静かに終了する）。
set -u
DOCS="$HOME/workspace/docs"

user_todos=$(find "$DOCS/user_todo" -maxdepth 1 -name '*.md' ! -name 'README.md' 2>/dev/null | sort)
talk_todos=$(find "$DOCS/ai_todo" -maxdepth 1 -name '*対話待ち*.md' 2>/dev/null | sort)

[ -z "$user_todos" ] && [ -z "$talk_todos" ] && exit 0

echo "=== 未消化TODOの引き渡し（session-handoff.sh） ==="

if [ -n "$talk_todos" ]; then
  echo ""
  echo "【対話待ちのAI TODO】無人実行では通らずClaudeの実行を待っているもの:"
  while IFS= read -r f; do
    echo "- docs/ai_todo/$(basename "$f")"
  done <<<"$talk_todos"
fi

if [ -n "$user_todos" ]; then
  echo ""
  echo "【本人TODO】本人の手が要るもの:"
  while IFS= read -r f; do
    echo "- docs/user_todo/$(basename "$f")"
    handoff=$(grep -m1 '^引き渡し先:' "$f" 2>/dev/null)
    [ -n "$handoff" ] && echo "  $handoff"
  done <<<"$user_todos"
fi

cat <<'EOS'

対話セッションであれば、ユーザーの最初の依頼に着手する前に次を行うこと（依頼と無関係でも放置しない。無人セッションではこの節を無視してよい）:
1. 対話待ちのAI TODOは、あなた自身がこのセッションで実行して完了させる（無人で止まった主因は権限分類器の拒否と画面ロックで、対話セッションにはどちらも無い）
2. 本人TODOは、引き渡し先の画面をブラウザで開いた状態にしてから本人に提示する。ファイルの記述を鵜呑みにせず、着手前に内容が現時点でも正しいか（完了済みでないか・URLが実在するか・本当に本人の作業か）を確認する
3. 本人の作業ではなかった場合はその場で是正する（`ai_todo/` の `対話待ち` へ移すか、不要なら削除する）
EOS
