#!/bin/bash
# Stop hook: keeps each project's STATUS.md current.
#
# When Claude is about to finish, this checks every project in projects/.
# If a project's files changed after its STATUS.md, Claude is stopped ONCE
# and asked to update STATUS.md and log/log.md before it finishes.
#
# Safety:
#  - Never loops: if Claude is already continuing because of this hook
#    (stop_hook_active = true), it lets Claude stop.
#  - Throttled: a project is skipped if its STATUS.md changed in the last
#    THROTTLE_MIN minutes, and the hook nags at most once per THROTTLE_MIN.
#  - Local only. Reads file dates, never file contents. No network.

ROOT="${CLAUDE_PROJECT_DIR:-$(cd "$(dirname "$0")/.." && pwd)}"
THROTTLE_MIN="${JARVIS_STATUS_THROTTLE_MIN:-120}"
STATE="$ROOT/.state"
INPUT="$(cat)"

json_get() {  # json_get <key>  (reads $INPUT)
  printf '%s' "$INPUT" | python3 -c 'import sys,json
try: v=json.load(sys.stdin).get(sys.argv[1],"")
except Exception: v=""
print(str(v).lower() if isinstance(v,bool) else v)' "$1" 2>/dev/null
}

# 1. Never loop.
[ "$(json_get stop_hook_active)" = "true" ] && exit 0

# 2. Nag at most once per throttle window.
mkdir -p "$STATE"
stamp="$STATE/status-check.last"
[ -n "$(find "$stamp" -mmin -"$THROTTLE_MIN" 2>/dev/null)" ] && exit 0

# 3. Find projects whose files are newer than their STATUS.md.
stale=""
for dir in "$ROOT"/projects/*/; do
  [ -d "$dir" ] || continue
  name="$(basename "$dir")"
  status="${dir}STATUS.md"
  if [ ! -f "$status" ]; then
    stale="$stale $name(no STATUS.md)"; continue
  fi
  [ -n "$(find "$status" -mmin -"$THROTTLE_MIN" 2>/dev/null)" ] && continue
  changed="$(find "$dir" -type f -newer "$status" \
    -not -name STATUS.md -not -name ACTIVITY.md -not -name .DS_Store \
    -not -path '*/.git/*' -not -path '*/node_modules/*' 2>/dev/null | head -1)"
  [ -n "$changed" ] && stale="$stale $name"
done

[ -z "$stale" ] && exit 0
touch "$stamp"
today="$(date +%Y-%m-%d)"
reason="Status rule: these projects changed since their STATUS.md was updated:$stale. Before finishing, run the /log skill (or by hand: in each STATUS.md set Last updated = $today, refresh Now / Next / Blockers, add today's line at the top of the Daily log; then add one line to log/log.md). Meaning only, no file lists, no secrets. Keep it short, then finish."
python3 -c 'import sys,json; print(json.dumps({"decision":"block","reason":sys.argv[1]}))' "$reason"
exit 0
