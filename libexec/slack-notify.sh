#!/bin/bash
if [ "$PRODUCTION" == "true" ]; then
  msg="
:star: $EMOJI _$NAME Package Released_ $EMOJI\n
*Name:* \`$PACKAGE\`\n
*Repo:* <$REPO_S3_URL|\`$REPO\`>\n
*URL:* $PACKAGE_URL"
else
  msg="
:soon: $EMOJI _$NAME Dev Package Published_ $EMOJI\n
*Name:* \`$PACKAGE\`\n
*Repo:* <$REPO_S3_URL|\`$REPO\`>\n
*Tree:* https://github.com/$BUILDER_REPO/tree/$(git rev-parse --short HEAD)\n
*URL:* $PACKAGE_URL"
fi

cat <<EOF | curl --data @- -X POST -H "Authorization: Bearer $SLACK_TOKEN" -H 'Content-Type: application/json' https://slack.com/api/chat.postMessage
{
  "text": "$msg",
  "channel": "packaging",
  "as_user": true
}
EOF
echo
