#!/bin/bash
# Runs as dynamic context before the skill loads, so the model receives
# computed values. Config keys are documented in the README.

config="${XDG_CONFIG_HOME:-$HOME/.config}/claude-journal/config"
[ -f "$config" ] && . "$config"

if [ -z "$JOURNAL_DATA_SOURCE_ID" ]; then
  cat <<MSG
- NOT CONFIGURED. Create $config containing:
  JOURNAL_DATA_SOURCE_ID="<uuid of your Work Journal data source>"
  Find the uuid by fetching your journal database with the Notion MCP and
  reading the collection:// url of its data source. See the plugin README.
MSG
  exit 0
fi

colors=(${JOURNAL_COLORS:-blue_bg green_bg yellow_bg orange_bg})
icons=(${JOURNAL_ICONS:-🌙 ⚔️ 🪶 ⚡ 🌸 🪐 ☀️})

month=$((10#$(date +%m)))
[ "${JOURNAL_HEMISPHERE:-north}" = "south" ] && month=$(( (month + 5) % 12 + 1 ))
case $month in
  12|1|2) color=${colors[0]} ;;
  3|4|5)  color=${colors[1]} ;;
  6|7|8)  color=${colors[2]} ;;
  *)      color=${colors[3]} ;;
esac

weekday=$(( $(date +%u) - 1 ))
icon=${icons[$weekday]}

echo "- ISO date: $(date +%Y-%m-%d)"
echo "- Month label: $(date '+%B %Y')"
echo "- Callout icon: $icon"
echo "- Callout color: $color"
echo "- Data source id: $JOURNAL_DATA_SOURCE_ID"
echo "- MCP server: ${JOURNAL_MCP_SERVER:-notion}"
