#!/usr/bin/env bash
# Claude Code status line: model + effort, context usage, plan rate limits.
# macOS / Linux version. Requires jq.
#
# Output:  Opus 5.5 (medium) | Ctx: 35306 tok (4%) | 5h: 1% (resets Fri 14:10)  7d: 0% (resets Thu 09:00)

ESC=$'\033'
RED="${ESC}[31m"
YELLOW="${ESC}[33m"
DIM="${ESC}[2m"
RESET="${ESC}[0m"

# Percent thresholds for colouring context and rate-limit usage.
WARN_PCT=50
CRIT_PCT=75
# Context also turns yellow from this many tokens, even if the window is far from full.
WARN_TOKENS=100000

if ! command -v jq >/dev/null 2>&1; then
    echo "${DIM}statusline: jq not found${RESET}"
    exit 0
fi

input=$(cat)

if ! echo "$input" | jq -e . >/dev/null 2>&1; then
    echo "${DIM}statusline: invalid JSON input${RESET}"
    exit 0
fi

# Read all fields in one jq call; empty string means missing.
# Fields are joined with the ASCII unit separator (not tab), because read
# collapses consecutive whitespace delimiters and would shift empty fields.
IFS=$'\x1f' read -r model effort used_tokens ctx_pct five_pct five_reset week_pct week_reset < <(
    echo "$input" | jq -r '[
        (.model.display_name // "?"),
        (.effort.level // ""),
        (.context_window.total_input_tokens // ""),
        (.context_window.used_percentage // ""),
        (.rate_limits.five_hour.used_percentage // ""),
        (.rate_limits.five_hour.resets_at // ""),
        (.rate_limits.seven_day.used_percentage // ""),
        (.rate_limits.seven_day.resets_at // "")
    ] | map(tostring) | join("\u001f")'
)

pct_color() {
    local pct=${1%.*}
    if [ -z "$pct" ]; then echo "$DIM"
    elif [ "$pct" -ge "$CRIT_PCT" ]; then echo "$RED"
    elif [ "$pct" -ge "$WARN_PCT" ]; then echo "$YELLOW"
    else echo "$DIM"
    fi
}

format_reset() {
    [ -z "$1" ] && return
    # GNU date uses -d @epoch, BSD/macOS date uses -r epoch.
    LC_TIME=C date -d "@$1" +"%a %H:%M" 2>/dev/null || LC_TIME=C date -r "$1" +"%a %H:%M" 2>/dev/null
}

format_limit() {
    local label=$1 pct=$2 reset=$3
    [ -z "$pct" ] && return
    local text reset_str
    text=$(printf "%s: %.0f%%" "$label" "$pct")
    reset_str=$(format_reset "$reset")
    [ -n "$reset_str" ] && text="$text (resets $reset_str)"
    printf "%s%s%s" "$(pct_color "$pct")" "$text" "$RESET"
}

# --- Model + effort level ---
model_str=$model
[ -n "$effort" ] && model_str="$model ($effort)"

# --- Context usage (current conversation) ---
if [ -n "$used_tokens" ]; then
    pct_part=""
    [ -n "$ctx_pct" ] && pct_part=$(printf " (%.0f%%)" "$ctx_pct")
    color=$(pct_color "$ctx_pct")
    [ "$color" = "$DIM" ] && [ "${used_tokens%.*}" -ge "$WARN_TOKENS" ] && color=$YELLOW
    ctx_str="${color}Ctx: ${used_tokens} tok${pct_part}${RESET}"
else
    ctx_str="${DIM}Ctx: n/a${RESET}"
fi

# --- Rate limits (Claude.ai plan usage limits) ---
five=$(format_limit "5h" "$five_pct" "$five_reset")
week=$(format_limit "7d" "$week_pct" "$week_reset")

if [ -n "$five" ] && [ -n "$week" ]; then limit_str="$five  $week"
elif [ -n "$five$week" ]; then limit_str="$five$week"
else limit_str="${DIM}limits: n/a${RESET}"
fi

echo "${DIM}${model_str}${RESET} | ${ctx_str} | ${limit_str}"
