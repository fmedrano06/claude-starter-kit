#!/usr/bin/env bash
# Claude Code status line — preset-driven, fed via stdin JSON.
#
# Usage in settings.json:
#   "statusLine": {
#     "type": "command",
#     "command": "bash ~/.claude/statusline-command.sh <preset>"
#   }
#
# Presets (chosen by the install wizard):
#   minimal   ->  <dir>
#   balanced  ->  <dir> | <branch> | <model>           (branch omitted outside a git repo)
#   verbose   ->  <dir> | <branch> | <model> | ctx: <pct>% used [marks]
#
# Threshold marks on context usage: [!] >=50, [!!] >=75, [!!!] >=90.

preset="${1:-balanced}"
case "$preset" in
    minimal|balanced|verbose) ;;
    *) preset="balanced" ;;
esac

input=$(cat)

# Pull a string field from the flat-ish JSON Claude Code feeds us. Avoids a
# jq dependency — the input shape is stable enough for grep/sed.
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
dir=$(basename "$cwd")

model=$(get_val "display_name")
[ -z "$model" ] && model="unknown"

# minimal: just the folder name, done.
if [ "$preset" = "minimal" ]; then
    printf "%s" "$dir"
    exit 0
fi

# balanced + verbose need the branch.
branch=""
if [ -d "$cwd/.git" ] || git -C "$cwd" rev-parse --git-dir >/dev/null 2>&1; then
    branch=$(git -C "$cwd" branch --show-current 2>/dev/null)
fi

# Compose the middle segment. branch omitted when empty (not a git repo).
if [ -n "$branch" ]; then
    middle="$dir | $branch | $model"
else
    middle="$dir | $model"
fi

if [ "$preset" = "balanced" ]; then
    printf "%s" "$middle"
    exit 0
fi

# verbose: append context usage with threshold marks.
used=$(get_num "used_percentage")
if [ -n "$used" ]; then
    used_int=${used%.*}
    if [ "$used_int" -ge 90 ] 2>/dev/null; then
        ctx="ctx: ${used}% used [!!!]"
    elif [ "$used_int" -ge 75 ] 2>/dev/null; then
        ctx="ctx: ${used}% used [!!]"
    elif [ "$used_int" -ge 50 ] 2>/dev/null; then
        ctx="ctx: ${used}% used [!]"
    else
        ctx="ctx: ${used}% used"
    fi
    printf "%s | %s" "$middle" "$ctx"
else
    printf "%s | ctx: --" "$middle"
fi
