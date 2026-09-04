# workspace（AI会社の作業場）

個人で運営するAI会社の作業ディレクトリ。`GITHUB_USERNAME` を自分のGitHubユーザー名に置き換えて、`~/workspace/CLAUDE.md` として配置する（配置後はこの行と見出し下の説明を削除してよい）。

- `docs/` は正本リポジトリ（GitHub `GITHUB_USERNAME/docs`・mainブランチ）の作業コピー。会社の理念・ルール・事業一覧の正本は `docs/COMPANY.md` で、会社レベルの判断に迷ったらまず読むこと
- セッション冒頭に `docs/ops/sync-docs.sh` を実行して正本と同期する。`docs/` を編集したときも同スクリプトで書き戻すこと
- 運用ループの設計は `docs/LOOP_DESIGN.md`、定期実行の手順は `docs/ops/inbox/RUNBOOK.md` が正本
