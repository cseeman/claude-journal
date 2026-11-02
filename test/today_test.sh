#!/bin/bash
# Usage: bash test/today_test.sh [path/to/today.sh]
script="${1:-$(cd "$(dirname "$0")/.." && pwd)/plugins/journal/skills/journal/today.sh}"

tmp=$(mktemp -d)
trap 'rm -rf "$tmp"' EXIT
mkdir -p "$tmp/bin" "$tmp/empty" "$tmp/config/claude-journal" "$tmp/cwd"
touch "$tmp/cwd/a" "$tmp/cwd/b"
echo 'JOURNAL_DATA_SOURCE_ID="test-id"' > "$tmp/config/claude-journal/config"

cat > "$tmp/bin/date" <<'STUB'
#!/bin/bash
case "$1" in
  +%m) echo "$FAKE_MONTH" ;;
  +%u) echo "$FAKE_WEEKDAY" ;;
  +%Y-%m-%d) echo "2026-$FAKE_MONTH-15" ;;
  *) echo "Fake 2026" ;;
esac
STUB
chmod +x "$tmp/bin/date"

failures=0

run() {
  (cd "$tmp/cwd" && env -i PATH="$tmp/bin:$PATH" XDG_CONFIG_HOME="$tmp/config" \
    FAKE_MONTH=01 FAKE_WEEKDAY=1 "$@" bash "$script")
}

expect() {
  local name=$1 want=$2 got=$3
  if [[ "$got" == *"$want"* ]]; then
    echo "ok   $name"
  else
    echo "FAIL $name: wanted '$want' in: $got"
    failures=$((failures + 1))
  fi
}

season() { expect "$1" "Callout color: $2" "$(run FAKE_MONTH="$3" JOURNAL_HEMISPHERE="$4")"; }

season "north january is winter" blue_bg 01 north
season "north march is spring" green_bg 03 north
season "north august is summer, leading zero" yellow_bg 08 north
season "north september is autumn, leading zero" orange_bg 09 north
season "north december is winter" blue_bg 12 north
season "south january is summer" yellow_bg 01 south
season "south march is autumn" orange_bg 03 south
season "south june is winter" blue_bg 06 south
season "south september is spring" green_bg 09 south

expect "monday icon" "Callout icon: 🌙" "$(run FAKE_WEEKDAY=1)"
expect "sunday icon" "Callout icon: ☀️" "$(run FAKE_WEEKDAY=7)"
expect "iso date" "ISO date: 2026-08-15" "$(run FAKE_MONTH=08)"
expect "data source id" "Data source id: test-id" "$(run)"
expect "default server" "MCP server: notion" "$(run)"
expect "custom server" "MCP server: notion_personal" "$(run JOURNAL_MCP_SERVER=notion_personal)"

expect "missing config" "NOT CONFIGURED" "$(run XDG_CONFIG_HOME="$tmp/empty")"
expect "too few colors" "JOURNAL_COLORS needs 4 values (found 1)" "$(run JOURNAL_COLORS=red_bg)"
expect "too few icons" "JOURNAL_ICONS needs 7 values (found 2)" "$(run JOURNAL_ICONS="x y")"
expect "glob stays literal" "Callout icon: *" "$(run JOURNAL_ICONS="* * * * * * *")"

if [ "$failures" -ne 0 ]; then
  echo "$failures failed"
  exit 1
fi
echo "all passed"
