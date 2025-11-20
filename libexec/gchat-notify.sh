#!/bin/bash
if [ "$PRODUCTION" == "true" ]; then
  emoji="⭐️"
  TITLE="$emoji $NAME Packaged Released"
else
  emoji="🔜"
  TITLE="$emoji $NAME Dev Package Published"
  TREE_URL="https://github.com/$BUILDER_REPO/tree/$(git rev-parse --short HEAD)"
  TREE="<b>Tree:</b> <a href="$TREE_URL">$TREE_URL</a>"
fi

MESSAGE="<b>Name:</b> <code>$PACKAGE</code>
<b>Repo:</b> <a href="$REPO_S3_URL">$REPO</a>
<b>URL:</b> <a href="$PACKAGE_URL">$PACKAGE_URL</a>
$TREE"

CARD=$(jq -n \
  --arg ttl "$TITLE" \
  --arg msg "$MESSAGE" \
  '{"header": { "title": $ttl },"sections": [{ "widgets": [{ "textParagraph": {"text": $msg} }] }]}'
)

curl -X POST -H 'Content-Type: application/json' $GCHAT_WEBHOOK -d "{\"cards\":[$CARD]}"
