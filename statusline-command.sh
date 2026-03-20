#!/usr/bin/env bash
# claude-statusline - Custom status line for Claude Code
# https://github.com/pelligrag/claude-statusline
#
# Output (2 lines):
#   📁 ~/project | 🌿 main +2 ~1 | 🤖 Sonnet 4.6 | 🔥 $4.72/hr 🟢 (Normal) | 🧠 84,000 (42%)
#   ████░░░░░░░░░░░░░░░░ 24% of 5h limit | Resets 13:00 IT
#
# Requirements: python3, ccusage (npm i -g ccusage)
# Timezone: set STATUSLINE_TZ env var (default: UTC)
#           e.g. export STATUSLINE_TZ="Europe/Rome"

input=$(cat)

# ── Config ────────────────────────────────────────────────────────────────────
TZ_NAME="${STATUSLINE_TZ:-UTC}"

# ── Extract JSON data ─────────────────────────────────────────────────────────
read -r CWD FIVE_PCT FIVE_RESET <<< "$(echo "$input" | python3 -c "
import json, sys, datetime
d = json.loads(sys.stdin.read())
ws  = d.get('workspace') or {}
cwd = ws.get('current_dir') or d.get('cwd', '')
rl  = d.get('rate_limits') or {}
fh  = rl.get('five_hour') or {}
pct = int(fh.get('used_percentage') or 0)
ts  = fh.get('resets_at') or 0
if ts:
    import os, zoneinfo
    tz_name = os.environ.get('STATUSLINE_TZ', 'UTC')
    dt = datetime.datetime.fromtimestamp(ts, tz=datetime.timezone.utc)
    local = dt.astimezone(zoneinfo.ZoneInfo(tz_name))
    tz_label = tz_name.split('/')[-1].replace('_',' ')
    reset_str = local.strftime('%-H:%M') + ' ' + tz_label
else:
    reset_str = '-'
print(cwd, pct, reset_str)
")"

# ── Shorten home dir ──────────────────────────────────────────────────────────
CWD_DISPLAY="${CWD/#$HOME/\~}"

# ── Git branch (cached 5s) ────────────────────────────────────────────────────
GIT_INFO=""
if git -C "$CWD" rev-parse --git-dir > /dev/null 2>&1; then
    CACHE_KEY=$(printf '%s' "$CWD" | python3 -c "import sys,hashlib; print(hashlib.md5(sys.stdin.read().encode()).hexdigest()[:8])")
    CACHE="/tmp/sl-git-${CACHE_KEY}"
    AGE=$(( $(date +%s) - $(stat -c %Y "$CACHE" 2>/dev/null || echo 0) ))
    if [ ! -f "$CACHE" ] || [ "$AGE" -gt 5 ]; then
        BR=$(git -C "$CWD" branch --show-current 2>/dev/null)
        ST=$(git -C "$CWD" diff --cached --numstat 2>/dev/null | wc -l | tr -d ' ')
        MO=$(git -C "$CWD" diff --numstat 2>/dev/null | wc -l | tr -d ' ')
        printf '%s|%s|%s\n' "$BR" "$ST" "$MO" > "$CACHE"
    fi
    IFS='|' read -r BR ST MO < "$CACHE"
    GIT_INFO=" | 🌿 ${BR}"
    [ "${ST:-0}" -gt 0 ] && GIT_INFO="${GIT_INFO} +${ST}"
    [ "${MO:-0}" -gt 0 ] && GIT_INFO="${GIT_INFO} ~${MO}"
fi

# ── ccusage statusline (strip cost section 💰) ────────────────────────────────
USAGE=$(echo "$input" | ccusage statusline --visual-burn-rate emoji-text 2>/dev/null \
    | python3 -c "
import sys, re
line = sys.stdin.read().strip()
line = re.sub(r'\s*\|\s*💰[^|]+\s*\|', ' |', line)
print(line)
")

# ── 5h rate limit bar ─────────────────────────────────────────────────────────
PCT=${FIVE_PCT:-0}
BAR_WIDTH=20
FILLED=$(( PCT * BAR_WIDTH / 100 ))
EMPTY=$(( BAR_WIDTH - FILLED ))
BAR=""
[ "$FILLED" -gt 0 ] && printf -v F "%${FILLED}s" && BAR="${F// /█}"
[ "$EMPTY"  -gt 0 ] && printf -v E "%${EMPTY}s"  && BAR="${BAR}${E// /░}"

if   [ "$PCT" -ge 80 ]; then BAR_COLOR='\033[31m'   # red
elif [ "$PCT" -ge 50 ]; then BAR_COLOR='\033[33m'   # yellow
else                          BAR_COLOR='\033[32m'; fi  # green
RESET='\033[0m'; BOLD='\033[1m'; DIM='\033[2m'

# ══ OUTPUT ════════════════════════════════════════════════════════════════════
printf '%b\n' "📁 ${BOLD}${CWD_DISPLAY}${RESET}${GIT_INFO} | ${USAGE}"
printf '%b\n' "${BAR_COLOR}${BAR}${RESET} ${BOLD}${PCT}%${RESET} ${DIM}of 5h limit${RESET} | Resets ${BOLD}${FIVE_RESET}${RESET}"
