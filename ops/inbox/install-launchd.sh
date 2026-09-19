#!/bin/bash
# launchd定義の適用スクリプト(冪等)。正本は docs/ops/inbox/<ラベル>.plist で、
# 変更したらこのスクリプトを再実行すれば反映される。
# 引数でラベルを指定する(省略時は com.aicompany.periodic)。例: ./install-launchd.sh com.aicompany.periodic-weekly
set -eu
LABEL="${1:-com.aicompany.periodic}"
SRC="$HOME/workspace/docs/ops/inbox/$LABEL.plist"
DST="$HOME/Library/LaunchAgents/$LABEL.plist"
UID_N=$(id -u)
plutil -lint "$SRC" >/dev/null
mkdir -p "$HOME/Library/LaunchAgents"
cp "$SRC" "$DST"
launchctl bootout "gui/$UID_N/$LABEL" 2>/dev/null || true
launchctl bootstrap "gui/$UID_N" "$DST"
launchctl print "gui/$UID_N/$LABEL" | grep -E "state|program|minute" || true
echo "applied: $LABEL"
