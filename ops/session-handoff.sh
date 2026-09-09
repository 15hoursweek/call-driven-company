#!/bin/bash
# セッション冒頭に、放置されると滞留するTODOを提示する。
# SessionStart フックから sync-docs.sh の後に実行される。標準出力はそのままセッションのコンテキストに入る。
# 対象がなければ何も出力しない（静かに終了する）。
set -u
DOCS="$HOME/workspace/docs"

user_todos=$(find "$DOCS/user_todo" -maxdepth 1 -name '*.md' ! -name 'README.md' 2>/dev/null | sort)
talk_todos=$(find "$DOCS/ai_todo" -maxdepth 1 -name '*対話待ち*.md' 2>/dev/null | sort)
wait_todos=$(find "$DOCS/ai_todo" -maxdepth 1 -name '*人間待ち*.md' 2>/dev/null | sort)

# 本人依頼が出ていない `人間待ち` は、誰も拾わないまま滞留するので警告する
orphan_waits=""
if [ -n "$wait_todos" ] && [ -z "$user_todos" ]; then
  orphan_waits="$wait_todos"
fi

[ -z "$user_todos" ] && [ -z "$talk_todos" ] && [ -z "$orphan_waits" ] && exit 0

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

if [ -n "$orphan_waits" ]; then
  echo ""
  echo '【滞留のおそれ】「人間待ち」だが本人依頼（user_todo）が出ていないもの:'
  while IFS= read -r f; do
    echo "- docs/ai_todo/$(basename "$f")"
  done <<<"$orphan_waits"
  echo "  → 本人の判断・対応が要るなら user_todo を作って引き渡す。要らないなら状態を戻すか削除する"
fi

cat <<'EOS'

対話セッションであれば、ユーザーの最初の依頼に着手する前に次を行うこと（依頼と無関係でも放置しない。無人セッションではこの節を無視してよい）:
1. 対話待ちのAI TODOは、あなた自身がこのセッションで実行して完了させる（無人で止まった主因は権限分類器の拒否と画面ロックで、対話セッションにはどちらも無い）
2. 本人TODOは、引き渡し先の画面をブラウザで開いた状態にしてから本人に提示する。ファイルの記述を鵜呑みにせず、着手前に内容が現時点でも正しいか（完了済みでないか・URLが実在するか・本当に本人の作業か）を確認する
3. 本人の作業ではなかった場合はその場で是正する（`ai_todo/` の `対話待ち` へ移すか、不要なら削除する）
EOS
