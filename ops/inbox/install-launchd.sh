#!/bin/bash
# launchd定義の適用スクリプト(冪等)。正本は docs/ops/inbox/com.aicompany.periodic.plist で、
# 変更したらこのスクリプトを再実行すれば反映される
set -eu
LABEL="com.aicompany.periodic"
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
