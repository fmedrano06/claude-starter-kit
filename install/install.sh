#!/usr/bin/env bash
# Claude Starter Kit installer (macOS / Linux / WSL).
#
# Reads install/lib/wizard-questions.json, prompts the user, backs up
# ~/.claude/, renders templates, copies selected skills, and merges
# settings.json. Idempotent via a marker comment in ~/.claude/CLAUDE.md.
#
# Usage:
#   bash install/install.sh            # interactive install
#   bash install/install.sh --dry-run  # print planned actions only
#   bash install/install.sh --force    # skip re-install confirmation

set -euo pipefail

DRY_RUN=0
FORCE=0
for arg in "$@"; do
    case "$arg" in
        --dry-run) DRY_RUN=1 ;;
        --force)   FORCE=1 ;;
        -h|--help)
            sed -n '2,12p' "$0"
            exit 0
            ;;
        *) echo "Unknown argument: $arg" >&2; exit 2 ;;
    esac
done

# ---------------------------------------------------------------------------
# Resolve repo paths
# ---------------------------------------------------------------------------
SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd -- "$SCRIPT_DIR/.." && pwd)"
WIZARD_JSON="$SCRIPT_DIR/lib/wizard-questions.json"

if [[ ! -f "$WIZARD_JSON" ]]; then
    echo "Cannot find wizard questions at $WIZARD_JSON" >&2
    exit 1
fi

CLAUDE_HOME="${HOME}/.claude"
MARKER='<!-- claude-starter-kit v0.1.0 -->'

# ---------------------------------------------------------------------------
# Dependencies
# ---------------------------------------------------------------------------
have() { command -v "$1" >/dev/null 2>&1; }

JSON_TOOL=""
if have jq; then
    JSON_TOOL="jq"
elif have python3; then
    JSON_TOOL="python3"
else
    echo "ERROR: this installer needs jq or python3 to parse JSON." >&2
    echo "Install one of:" >&2
    echo "  macOS:   brew install jq" >&2
    echo "  Debian:  sudo apt install jq" >&2
    echo "  Fedora:  sudo dnf install jq" >&2
    exit 1
fi

echo
echo "== Claude Starter Kit installer =="
echo "Repo:        $REPO_ROOT"
echo "Claude home: $CLAUDE_HOME"
[[ $DRY_RUN -eq 1 ]] && echo "Mode:        DRY RUN (no files will be written)"
echo

# ---------------------------------------------------------------------------
# Helpers
# ---------------------------------------------------------------------------
action() {
    local verb="$1" path="$2"
    printf '  %-8s %s\n' "$verb" "$path"
}

fs() {
    if [[ $DRY_RUN -eq 0 ]]; then
        "$@"
    fi
}

json_get() {
    # $1 = jq filter; reads $WIZARD_JSON
    if [[ "$JSON_TOOL" == "jq" ]]; then
        jq -r "$1" "$WIZARD_JSON"
    else
        python3 - "$1" <<'PY'
import json, sys
flt = sys.argv[1]
with open("__WIZARD__", encoding="utf-8") as f:
    data = json.load(f)
# minimal jq-like resolver for what install.sh actually queries
import re
def resolve(expr, ctx):
    if expr == ".":
        return ctx
    parts = re.findall(r"\.[A-Za-z0-9_]+|\[[0-9]+\]", expr)
    cur = ctx
    for p in parts:
        if p.startswith("."):
            cur = cur[p[1:]]
        else:
            cur = cur[int(p[1:-1])]
    return cur
out = resolve(flt, data)
if isinstance(out, (list, dict)):
    print(json.dumps(out))
else:
    print(out if out is not None else "")
PY
    fi
}

# Patch python3 fallback to use real path
if [[ "$JSON_TOOL" == "python3" ]]; then
    json_get() {
        python3 - "$WIZARD_JSON" "$1" <<'PY'
import json, sys, re
path, flt = sys.argv[1], sys.argv[2]
with open(path, encoding="utf-8") as f:
    data = json.load(f)
def resolve(expr, ctx):
    if expr.strip() == ".":
        return ctx
    cur = ctx
    for p in re.findall(r"\.[A-Za-z0-9_]+|\[[0-9]+\]", expr):
        cur = cur[p[1:]] if p.startswith(".") else cur[int(p[1:-1])]
    return cur
out = resolve(flt, data)
print(json.dumps(out) if isinstance(out, (list, dict)) else (out if out is not None else ""))
PY
    }
fi

prompt_text() {
    local prompt="$1" default="$2" suffix=""
    [[ -n "$default" ]] && suffix=" [$default]"
    local reply=""
    read -r -p "$prompt$suffix: " reply || true
    echo "${reply:-$default}"
}

prompt_bool() {
    local prompt="$1" default="$2" label="y/N" reply=""
    [[ "$default" == "true" ]] && label="Y/n"
    read -r -p "$prompt [$label]: " reply || true
    if [[ -z "$reply" ]]; then
        echo "$default"
    else
        case "$reply" in
            y|Y|yes|YES|true|1) echo "true" ;;
            *) echo "false" ;;
        esac
    fi
}

prompt_multi() {
    local prompt="$1"; shift
    echo "$prompt" >&2
    local i=1
    for opt in "$@"; do
        local id label desc
        id="$(echo "$opt" | cut -d'|' -f1)"
        label="$(echo "$opt" | cut -d'|' -f2)"
        desc="$(echo "$opt" | cut -d'|' -f3-)"
        printf '  %d. %s — %s\n' "$i" "$label" "$desc" >&2
        i=$((i + 1))
    done
    local reply=""
    read -r -p "Enter comma-separated numbers (or blank for none): " reply || true
    local result=()
    if [[ -n "$reply" ]]; then
        IFS=',' read -ra tokens <<< "$reply"
        for t in "${tokens[@]}"; do
            t="${t// /}"
            if [[ "$t" =~ ^[0-9]+$ ]] && (( t >= 1 && t <= $# )); then
                local opt="${!t}"
                result+=("$(echo "$opt" | cut -d'|' -f1)")
            fi
        done
    fi
    printf '%s\n' "${result[@]+"${result[@]}"}"
}

cwd_slug() {
    local cwd
    cwd="$(pwd)"
    echo "$cwd" | sed -e 's|^/||' -e 's|[/ ]|-|g' | tr '[:upper:]' '[:lower:]'
}

# ---------------------------------------------------------------------------
# Step 2-3: load and prompt
# ---------------------------------------------------------------------------
echo "-- Wizard --"

Q_COUNT=$(json_get '.questions' | (have jq && jq 'length' || python3 -c "import json,sys; print(len(json.load(sys.stdin)))"))

declare -A ANSWERS
declare -a SKILLS=()
declare -a MCPS=()

for (( idx=0; idx<Q_COUNT; idx++ )); do
    q_id=$(json_get ".questions[$idx].id")
    q_type=$(json_get ".questions[$idx].type")
    q_prompt=$(json_get ".questions[$idx].prompt")
    q_default=$(json_get ".questions[$idx].default")
    case "$q_type" in
        text)
            ANSWERS[$q_id]="$(prompt_text "$q_prompt" "$q_default")"
            ;;
        boolean)
            ANSWERS[$q_id]="$(prompt_bool "$q_prompt" "$q_default")"
            ;;
        multi-select)
            opt_count=$(json_get ".questions[$idx].options" | (have jq && jq 'length' || python3 -c "import json,sys; print(len(json.load(sys.stdin)))"))
            opts=()
            for (( o=0; o<opt_count; o++ )); do
                o_id=$(json_get ".questions[$idx].options[$o].id")
                o_label=$(json_get ".questions[$idx].options[$o].label")
                o_desc=$(json_get ".questions[$idx].options[$o].description")
                opts+=("$o_id|$o_label|$o_desc")
            done
            mapfile -t selected < <(prompt_multi "$q_prompt" "${opts[@]}")
            if [[ "$q_id" == "skills_to_install" ]]; then
                SKILLS=("${selected[@]+"${selected[@]}"}")
            elif [[ "$q_id" == "mcps_to_enable" ]]; then
                MCPS=("${selected[@]+"${selected[@]}"}")
            fi
            ANSWERS[$q_id]="$(IFS=,; echo "${selected[*]+"${selected[*]}"}")"
            ;;
        single-select)
            ANSWERS[$q_id]="$(prompt_text "$q_prompt" "$q_default")"
            ;;
        *)
            echo "Unknown question type: $q_type" >&2; exit 1 ;;
    esac
done
echo

# ---------------------------------------------------------------------------
# Step 4: idempotency + backup
# ---------------------------------------------------------------------------
CLAUDE_MD="$CLAUDE_HOME/CLAUDE.md"
BACKUP_PATH=""

if [[ -f "$CLAUDE_MD" ]]; then
    if head -n 1 "$CLAUDE_MD" | grep -q -F "$MARKER" && [[ $FORCE -eq 0 ]]; then
        again=$(prompt_bool "Starter kit is already installed. Re-install?" "false")
        [[ "$again" != "true" ]] && { echo "Aborted, nothing changed."; exit 0; }
    fi
    stamp=$(date -u +"%Y-%m-%dT%H-%M-%S")
    BACKUP_PATH="$CLAUDE_HOME/.backup-$stamp"
    action BACKUP "$BACKUP_PATH"
    if [[ $DRY_RUN -eq 0 ]]; then
        mkdir -p "$BACKUP_PATH"
        if have rsync; then
            rsync -a --exclude projects --exclude sessions --exclude cache --exclude '.backup-*' "$CLAUDE_HOME/" "$BACKUP_PATH/"
        else
            (cd "$CLAUDE_HOME" && find . -mindepth 1 -maxdepth 1 \
                ! -name projects ! -name sessions ! -name cache ! -name '.backup-*' \
                -exec cp -R {} "$BACKUP_PATH/" \;)
        fi
    fi
fi

# ---------------------------------------------------------------------------
# Rollback helper
# ---------------------------------------------------------------------------
CREATED_PATHS=()
restore_backup() {
    [[ -z "$BACKUP_PATH" || ! -d "$BACKUP_PATH" ]] && return
    echo "Restoring backup..." >&2
    for p in "${CREATED_PATHS[@]+"${CREATED_PATHS[@]}"}"; do
        rm -rf "$p" 2>/dev/null || true
    done
    if have rsync; then
        rsync -a "$BACKUP_PATH/" "$CLAUDE_HOME/"
    else
        cp -R "$BACKUP_PATH/." "$CLAUDE_HOME/"
    fi
}

trap 'rc=$?; if [[ $rc -ne 0 && $DRY_RUN -eq 0 ]]; then restore_backup; fi' EXIT

render_template() {
    local tpl="$1"
    local out="$tpl"
    out="${out//\{\{USER_NAME\}\}/${ANSWERS[user_name]:-}}"
    out="${out//\{\{USER_ROLE\}\}/${ANSWERS[user_role]:-}}"
    out="${out//\{\{PRIMARY_LANGUAGE\}\}/${ANSWERS[primary_language]:-}}"
    out="${out//\{\{COMMUNICATION_LANGUAGE\}\}/${ANSWERS[communication_language]:-English}}"
    printf '%s' "$out"
}

# ---------------------------------------------------------------------------
# Step 5: CLAUDE.md
# ---------------------------------------------------------------------------
TPL_CLAUDE="$REPO_ROOT/templates/CLAUDE.md.template"
if [[ -f "$TPL_CLAUDE" ]]; then
    rendered="$(render_template "$(cat "$TPL_CLAUDE")")"
    if ! grep -q -F "$MARKER" <<< "$rendered"; then
        rendered="$MARKER"$'\n'"$rendered"
    fi
    action WRITE "$CLAUDE_MD"
    if [[ $DRY_RUN -eq 0 ]]; then
        mkdir -p "$CLAUDE_HOME"
        printf '%s' "$rendered" > "$CLAUDE_MD"
    fi
    CREATED_PATHS+=("$CLAUDE_MD")
else
    echo "  SKIP    CLAUDE.md (template not present yet at $TPL_CLAUDE)"
fi

# ---------------------------------------------------------------------------
# Step 6: skills
# ---------------------------------------------------------------------------
SKILLS_SRC="$REPO_ROOT/skills"
SKILLS_DST="$CLAUDE_HOME/skills"
for s in "${SKILLS[@]+"${SKILLS[@]}"}"; do
    src="$SKILLS_SRC/$s"
    dst="$SKILLS_DST/$s"
    if [[ ! -d "$src" ]]; then
        echo "  SKIP    skills/$s (not in repo yet)"
        continue
    fi
    action COPY "$dst"
    if [[ $DRY_RUN -eq 0 ]]; then
        mkdir -p "$SKILLS_DST"
        cp -R "$src" "$SKILLS_DST/"
    fi
    CREATED_PATHS+=("$dst")
done

# ---------------------------------------------------------------------------
# Step 7: settings.json merge
# ---------------------------------------------------------------------------
TPL_SETTINGS="$REPO_ROOT/templates/settings.json.template"
DST_SETTINGS="$CLAUDE_HOME/settings.json"
if [[ -f "$TPL_SETTINGS" ]]; then
    action WRITE "$DST_SETTINGS"
    if [[ $DRY_RUN -eq 0 ]]; then
        enabled_csv="$(IFS=,; echo "${MCPS[*]+"${MCPS[*]}"}")"
        if have jq; then
            existing="{}"
            [[ -f "$DST_SETTINGS" ]] && existing="$(cat "$DST_SETTINGS")"
            enabled_json=$(jq -Rcn --arg s "$enabled_csv" '$s | split(",") | map(select(length>0))')
            echo "$existing" | jq \
                --slurpfile tpl <(cat "$TPL_SETTINGS") \
                --argjson enabled "$enabled_json" '
                . as $existing
                | $tpl[0] as $tpl
                | ($existing * ($tpl | del(.mcpServers)))
                | .mcpServers = (($existing.mcpServers // {}) +
                    (($tpl.mcpServers // {}) | with_entries(select(.key as $k | $enabled | index($k)))))
                ' > "$DST_SETTINGS.tmp"
            mv "$DST_SETTINGS.tmp" "$DST_SETTINGS"
        else
            python3 - "$DST_SETTINGS" "$TPL_SETTINGS" "$enabled_csv" <<'PY'
import json, os, sys
dst, tpl_path, enabled_csv = sys.argv[1], sys.argv[2], sys.argv[3]
enabled = [x for x in enabled_csv.split(',') if x]
existing = {}
if os.path.exists(dst):
    with open(dst, encoding="utf-8") as f:
        existing = json.load(f)
with open(tpl_path, encoding="utf-8") as f:
    tpl = json.load(f)
for k, v in tpl.items():
    if k == "mcpServers":
        continue
    existing.setdefault(k, v)
tpl_mcps = tpl.get("mcpServers", {}) or {}
existing_mcps = existing.get("mcpServers", {}) or {}
for name, conf in tpl_mcps.items():
    if name in enabled:
        existing_mcps[name] = conf
existing["mcpServers"] = existing_mcps
with open(dst, "w", encoding="utf-8") as f:
    json.dump(existing, f, indent=2)
PY
        fi
        # Replace ~/.claude/ tokens in the merged file with the resolved
        # absolute path so the Claude Code runtime never has to expand ~.
        # Delimiter is | so we only escape backslash, pipe, and ampersand
        # in the replacement.
        claude_home_escaped="$(printf '%s' "$CLAUDE_HOME" | sed -e 's/[\\|&]/\\&/g')"
        if [[ "$(uname -s)" == "Darwin" ]]; then
            sed -i '' "s|~/\.claude/|${claude_home_escaped}/|g" "$DST_SETTINGS"
        else
            sed -i "s|~/\.claude/|${claude_home_escaped}/|g" "$DST_SETTINGS"
        fi
    fi
    CREATED_PATHS+=("$DST_SETTINGS")
else
    echo "  SKIP    settings.json (template not present yet at $TPL_SETTINGS)"
fi

# ---------------------------------------------------------------------------
# Step 8: seed memory
# ---------------------------------------------------------------------------
MEM_TPL="$REPO_ROOT/templates/memory/MEMORY.md.template"
if [[ -f "$MEM_TPL" ]]; then
    slug="$(cwd_slug)"
    MEM_DST="$CLAUDE_HOME/projects/$slug/memory/MEMORY.md"
    if [[ ! -f "$MEM_DST" ]]; then
        action WRITE "$MEM_DST"
        if [[ $DRY_RUN -eq 0 ]]; then
            mkdir -p "$(dirname "$MEM_DST")"
            cp "$MEM_TPL" "$MEM_DST"
        fi
        CREATED_PATHS+=("$MEM_DST")
    fi
fi

# ---------------------------------------------------------------------------
# Step 9: stop hook
# ---------------------------------------------------------------------------
if [[ "${ANSWERS[enable_stop_hook]:-false}" == "true" ]]; then
    case "$(uname -s)" in
        Darwin) HOOK_TPL="$REPO_ROOT/templates/hooks/notify-stop.sh.macos.example" ;;
        Linux)  HOOK_TPL="$REPO_ROOT/templates/hooks/notify-stop.sh.linux.example" ;;
        *)      HOOK_TPL="" ;;
    esac
    HOOK_DST="$CLAUDE_HOME/hooks/notify-stop.sh"
    if [[ -n "$HOOK_TPL" && -f "$HOOK_TPL" ]]; then
        action COPY "$HOOK_DST"
        if [[ $DRY_RUN -eq 0 ]]; then
            mkdir -p "$(dirname "$HOOK_DST")"
            cp "$HOOK_TPL" "$HOOK_DST"
            chmod +x "$HOOK_DST"
        fi
        CREATED_PATHS+=("$HOOK_DST")
    else
        echo "  SKIP    Stop hook (no template for $(uname -s) yet)"
    fi
fi

# ---------------------------------------------------------------------------
# Step 10: summary + open guide
# ---------------------------------------------------------------------------
echo
echo "== Install complete =="
echo "  CLAUDE.md:   $CLAUDE_MD"
echo "  Skills:      ${SKILLS[*]+"${SKILLS[*]}"}"
echo "  MCPs:        ${MCPS[*]+"${MCPS[*]}"}"
echo "  Stop hook:   ${ANSWERS[enable_stop_hook]:-false}"
[[ -n "$BACKUP_PATH" ]] && echo "  Backup:      $BACKUP_PATH"
GUIDE="$REPO_ROOT/guide/index.html"
echo "  Guide:       $GUIDE"

if [[ $DRY_RUN -eq 0 && -f "$GUIDE" ]]; then
    open_it=$(prompt_bool "Open the guide in your default browser?" "true")
    if [[ "$open_it" == "true" ]]; then
        case "$(uname -s)" in
            Darwin) open "$GUIDE" ;;
            Linux)  have xdg-open && xdg-open "$GUIDE" >/dev/null 2>&1 || true ;;
        esac
    fi
fi

# ---------------------------------------------------------------------------
# Step 11: optional onboarding hand-off
# ---------------------------------------------------------------------------
if [[ "${ANSWERS[show_onboarding_after_install]:-false}" == "true" ]]; then
    ONBOARDING_SRC="$REPO_ROOT/templates/first-session-prompt.md"
    ONBOARDING_DST_DIR="$CLAUDE_HOME/onboarding"
    ONBOARDING_DST="$ONBOARDING_DST_DIR/first-session-prompt.md"
    if [[ -f "$ONBOARDING_SRC" ]]; then
        action COPY "$ONBOARDING_DST"
        if [[ $DRY_RUN -eq 0 ]]; then
            mkdir -p "$ONBOARDING_DST_DIR"
            cp "$ONBOARDING_SRC" "$ONBOARDING_DST"
        fi
        CREATED_PATHS+=("$ONBOARDING_DST")

        echo
        echo "=============================================================="
        echo "  Ready for your first guided session?"
        echo "=============================================================="
        echo
        echo "  1. Install Obsidian (free) from https://obsidian.md"
        echo "  2. Pick a folder to be your knowledge vault. Open it in Obsidian."
        echo "  3. From a terminal, run:"
        echo "       cd <your-vault-folder>"
        echo "       claude"
        echo "  4. Paste this as your first message to Claude:"
        echo "       read ~/.claude/onboarding/first-session-prompt.md and walk me through it"
        echo
        echo "  Or read it yourself at:"
        echo "    $ONBOARDING_DST"
        echo
    else
        echo "  SKIP    onboarding (template not present at $ONBOARDING_SRC)"
    fi
fi

trap - EXIT
exit 0
