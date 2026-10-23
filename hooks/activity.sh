#!/bin/bash
# Activity hook: records WHICH files changed in each project, automatically.
# Writes projects/<name>/ACTIVITY.md, one line per check.
# File names only, never contents. Secret files (.env, keys) are never listed.
# Silent (prints nothing), local only, no network.
#
# Run on SessionStart and Stop. It catches changes made by Claude AND by you.

ROOT="${CLAUDE_PROJECT_DIR:-$(cd "$(dirname "$0")/.." && pwd)}"
STATE="$ROOT/.state"
cat > /dev/null   # hook JSON arrives on stdin; this hook doesn't need it
mkdir -p "$STATE"
now="$(date '+%Y-%m-%d %H:%M')"

for dir in "$ROOT"/projects/*/; do
  [ -d "$dir" ] || continue
  dir="${dir%/}"
  name="$(basename "$dir")"
  marker="$STATE/activity-$name.last"
  log="$dir/ACTIVITY.md"
  if [ ! -f "$log" ]; then
    printf '# ACTIVITY: %s\n\n> Written automatically by hooks/activity.sh. File names only. Do not edit by hand.\n\n' "$name" > "$log"
  fi
  if [ ! -f "$marker" ]; then
    touch "$marker"; echo "- $now · tracking started" >> "$log"; continue
  fi
  next="$marker.next"; touch "$next"
  files="$(find "$dir/" -type f -newer "$marker" \
    -not -name ACTIVITY.md -not -name .DS_Store -not -name '*.swp' \
    -not -name '.env*' -not -name '*.pem' -not -name '*.key' -not -name '*.p12' -not -name 'id_rsa*' \
    -not -path '*/.git/*' -not -path '*/node_modules/*' -not -path '*/__pycache__/*' \
    2>/dev/null | sed "s|^$dir/*||" | sort)"
  mv "$next" "$marker"
  [ -z "$files" ] && continue
  count="$(printf '%s\n' "$files" | wc -l | tr -d ' ')"
  list="$(printf '%s\n' "$files" | head -8 | paste -sd ',' - | sed 's/,/, /g')"
  [ "$count" -gt 8 ] && list="$list, ..."
  echo "- $now · $count file(s) · $list" >> "$log"
  # keep the newest 100 lines
  if [ "$(grep -c '^- ' "$log")" -gt 100 ]; then
    { grep -v '^- ' "$log"; grep '^- ' "$log" | tail -100; } > "$log.tmp" && mv "$log.tmp" "$log"
  fi
done
exit 0
