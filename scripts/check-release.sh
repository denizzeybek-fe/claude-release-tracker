#!/bin/bash
set -euo pipefail

REPO="anthropics/claude-code"
TELEGRAM_API="https://api.telegram.org/bot${TELEGRAM_BOT_TOKEN}/sendMessage"

echo "Checking latest release for ${REPO}..."

RELEASE_JSON=$(curl -s "https://api.github.com/repos/${REPO}/releases/latest")

TAG=$(echo "$RELEASE_JSON" | jq -r '.tag_name')
NAME=$(echo "$RELEASE_JSON" | jq -r '.name')
PUBLISHED_AT=$(echo "$RELEASE_JSON" | jq -r '.published_at')
HTML_URL=$(echo "$RELEASE_JSON" | jq -r '.html_url')
BODY=$(echo "$RELEASE_JSON" | jq -r '.body' | head -c 500)

if [ "$TAG" = "null" ] || [ -z "$TAG" ]; then
  echo "No release found or API error."
  exit 0
fi

PUBLISHED_TS=$(date -d "$PUBLISHED_AT" +%s 2>/dev/null || date -j -f "%Y-%m-%dT%H:%M:%SZ" "$PUBLISHED_AT" +%s 2>/dev/null)
NOW_TS=$(date +%s)
DIFF=$(( NOW_TS - PUBLISHED_TS ))
HOURS_24=86400

if [ "$DIFF" -gt "$HOURS_24" ]; then
  echo "Latest release '${TAG}' is older than 24 hours. No notification needed."
  exit 0
fi

echo "New release detected: ${TAG} (published ${PUBLISHED_AT})"

TRIMMED_BODY=$(echo "$BODY" | sed '/^[[:space:]]*$/d' | head -c 500)

if [ -n "$TRIMMED_BODY" ]; then
  CHANGELOG_PREVIEW=$(echo "$TRIMMED_BODY" | sed 's/&/\&amp;/g; s/</\&lt;/g; s/>/\&gt;/g' | head -c 300)
  CHANGELOG_SECTION="
<b>Changelog Preview:</b>
<pre>${CHANGELOG_PREVIEW}</pre>"
else
  CHANGELOG_SECTION="
<i>No changelog provided in this release.</i>"
fi

MESSAGE="<b>New Claude Code Release! 🚀</b>

<b>Version:</b> ${NAME} (${TAG})
<b>Published:</b> ${PUBLISHED_AT}
${CHANGELOG_SECTION}

<a href=\"${HTML_URL}\">📎 View Full Release Notes</a>"

RESPONSE=$(curl -s -X POST "$TELEGRAM_API" \
  -d chat_id="${TELEGRAM_CHAT_ID}" \
  -d parse_mode="HTML" \
  --data-urlencode "text=${MESSAGE}")

SUCCESS=$(echo "$RESPONSE" | jq -r '.ok')

if [ "$SUCCESS" = "true" ]; then
  echo "Telegram notification sent successfully!"
else
  echo "Failed to send Telegram notification:"
  echo "$RESPONSE"
  exit 1
fi
