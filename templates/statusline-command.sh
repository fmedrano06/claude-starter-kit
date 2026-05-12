#!/usr/bin/env bash
# Claude Code status line — renders "<dir> | <model> | ctx: <pct>% used [!]".
# Wired up in settings.json under "statusLine". Requires bash.

input=$(cat)

get_val() {
    echo "$input" | grep -o "\"$1\"[[:space:]]*:[[:space:]]*\"[^\"]*\"" |
    head -1 | sed 's/.*:[[:space:]]*"//;s/"$//'
}

get_num() {
    echo "$input" | grep -o "\"$1\"[[:space:]]*:[[:space:]]*[0-9.]*" |
    head -1 | sed 's/.*:[[:space:]]*//'
}

cwd=$(get_val "current_dir")
[ -z "$cwd" ] && cwd=$(get_val "cwd")
[ -z "$cwd" ] && cwd="unknown"

model=$(get_val "display_name")
[ -z "$model" ] && model="unknown"

used=$(get_num "used_percentage")

dir=$(basename "$cwd")

if [ -n "$used" ]; then
    used_int=${used%.*}
    if [ "$used_int" -ge 90 ] 2>/dev/null; then
        ctx_display="ctx: ${used}% used [!!!]"
    elif [ "$used_int" -ge 75 ] 2>/dev/null; then
        ctx_display="ctx: ${used}% used [!!]"
    elif [ "$used_int" -ge 50 ] 2>/dev/null; then
        ctx_display="ctx: ${used}% used [!]"
    else
        ctx_display="ctx: ${used}% used"
    fi
    printf "%s | %s | %s" "$dir" "$model" "$ctx_display"
else
    printf "%s | %s | ctx: --" "$dir" "$model"
fi
