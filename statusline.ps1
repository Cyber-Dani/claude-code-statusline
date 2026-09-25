# Claude Code status line: model + effort, context usage, plan rate limits.
# Windows version. Parses stdin JSON with PowerShell's built-in ConvertFrom-Json (no jq needed).
#
# Output:  Opus 5.5 (medium) | Ctx: 35306 tok (4%) | 5h: 1% (resets Fri 14:10)  7d: 0% (resets Thu 09:00)

$ESC    = [char]27
$RED    = "$ESC[31m"
$YELLOW = "$ESC[33m"
$DIM    = "$ESC[2m"
$RESET  = "$ESC[0m"

# Percent thresholds for colouring context and rate-limit usage.
$WARN_PCT = 50
$CRIT_PCT = 75
# Context also turns yellow from this many tokens, even if the window is far from full.
$WARN_TOKENS = 100000

$raw = [Console]::In.ReadToEnd()

try {
    $data = $raw | ConvertFrom-Json
} catch {
    Write-Output "${DIM}statusline: invalid JSON input${RESET}"
    exit 0
}

function Get-PctColor($pct) {
    if ($null -eq $pct)       { return $DIM }
    if ($pct -ge $CRIT_PCT)   { return $RED }
    if ($pct -ge $WARN_PCT)   { return $YELLOW }
    return $DIM
}

function Format-ResetTime($epochSeconds) {
    if (-not $epochSeconds) { return $null }
    try {
        $dt = [DateTimeOffset]::FromUnixTimeSeconds([int64]$epochSeconds).ToLocalTime()
        return $dt.ToString("ddd HH:mm", [Globalization.CultureInfo]::InvariantCulture)
    } catch {
        return $null
    }
}

# --- Model + effort level ---
$modelName = $data.model.display_name
if (-not $modelName) { $modelName = "?" }
$effort = $data.effort.level
$modelStr = if ($effort) { "${modelName} (${effort})" } else { $modelName }

# --- Context usage (current conversation) ---
$usedTokens = $data.context_window.total_input_tokens
$ctxPct     = $data.context_window.used_percentage

if ($null -ne $usedTokens) {
    $color   = Get-PctColor $ctxPct
    if ($color -eq $DIM -and $usedTokens -ge $WARN_TOKENS) { $color = $YELLOW }
    $pctPart = if ($null -ne $ctxPct) { " ({0:0}%)" -f $ctxPct } else { "" }
    $ctxStr  = "${color}Ctx: ${usedTokens} tok${pctPart}${RESET}"
} else {
    $ctxStr = "${DIM}Ctx: n/a${RESET}"
}

# --- Rate limits (Claude.ai plan usage limits) ---
function Format-Limit($label, $limit) {
    $pct = $limit.used_percentage
    if ($null -eq $pct) { return $null }
    $color    = Get-PctColor $pct
    $resetStr = Format-ResetTime $limit.resets_at
    $text     = "{0}: {1:0}%" -f $label, $pct
    if ($resetStr) { $text += " (resets ${resetStr})" }
    return "${color}${text}${RESET}"
}

$limitParts = @(
    (Format-Limit "5h" $data.rate_limits.five_hour),
    (Format-Limit "7d" $data.rate_limits.seven_day)
) | Where-Object { $_ }

$limitStr = if ($limitParts.Count -gt 0) { $limitParts -join "  " } else { "${DIM}limits: n/a${RESET}" }

Write-Output "${DIM}${modelStr}${RESET} | ${ctxStr} | ${limitStr}"
