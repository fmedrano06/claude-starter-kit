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
MARKER='<!-- claude-starter-kit v0.5.0 -->'

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
# Step 0: choose wizard language
# ---------------------------------------------------------------------------
read -r -p "Language / Idioma [EN/es]: " lang_input || true
case "${lang_input,,}" in
    es|spanish|español|espanol) LANG_CODE="es" ;;
    *) LANG_CODE="en" ;;
esac
echo

if [[ "$LANG_CODE" == "es" ]]; then
    T_WIZARD_HEADER="-- Asistente --"
    T_REINSTALL_Q="El starter kit ya está instalado. ¿Reinstalar?"
    T_ABORTED="Cancelado, no se cambió nada."
    T_INSTALL_DONE="== Instalación completa =="
    T_SKILLS_LABEL="  Skills:     "
    T_MCPS_LABEL="  MCPs:       "
    T_HOOK_LABEL="  Stop hook:  "
    T_BACKUP_LABEL="  Backup:     "
    T_GUIDE_LABEL="  Guide:      "
    T_OPEN_BROWSER_Q="¿Abrir la guía en tu navegador?"
    T_READY_BANNER="  ¿Listo para tu primera sesión guiada?"
    T_READY_STEP1="  1. Instala Obsidian (gratis) desde https://obsidian.md"
    T_READY_STEP2="  2. Elige una carpeta para tu vault de conocimiento. Ábrela en Obsidian."
    T_READY_STEP3="  3. Desde una terminal, corre:"
    T_READY_STEP3A="       cd <tu-carpeta-vault>"
    T_READY_STEP3B="       claude"
    T_READY_STEP4="  4. Pega esto como tu primer mensaje a Claude:"
    T_READY_STEP4A="       read ~/.claude/onboarding/first-session-prompt.md and walk me through it"
    T_READY_READ_SELF="  O léelo tú mismo en:"
    T_MULTI_BLANK="Ingresa números separados por coma (o vacío para ninguno): "
    T_VAULT_HINT_TITLE="Tu vault está listo en:"
    T_VAULT_HINT_L1="Para usarlo con Obsidian (recomendado):"
    T_VAULT_HINT_L2="  1. Descarga Obsidian gratis: https://obsidian.md"
    T_VAULT_HINT_L3="  2. Abre Obsidian → \"Open folder as vault\" → apunta a la ruta de arriba"
    T_VAULT_HINT_L4="  3. Plugins recomendados (Settings → Community plugins):"
    T_VAULT_HINT_L5="       - Templater  (snippets para daily notes)"
    T_VAULT_HINT_L6="       - Dataview   (queries SQL-style sobre wiki/)"
    T_VAULT_HINT_L7="El vault ya está conectado con Claude vía CLAUDE.md."
else
    T_WIZARD_HEADER="-- Wizard --"
    T_REINSTALL_Q="Starter kit is already installed. Re-install?"
    T_ABORTED="Aborted, nothing changed."
    T_INSTALL_DONE="== Install complete =="
    T_SKILLS_LABEL="  Skills:      "
    T_MCPS_LABEL="  MCPs:        "
    T_HOOK_LABEL="  Stop hook:   "
    T_BACKUP_LABEL="  Backup:      "
    T_GUIDE_LABEL="  Guide:       "
    T_OPEN_BROWSER_Q="Open the guide in your default browser?"
    T_READY_BANNER="  Ready for your first guided session?"
    T_READY_STEP1="  1. Install Obsidian (free) from https://obsidian.md"
    T_READY_STEP2="  2. Pick a folder to be your knowledge vault. Open it in Obsidian."
    T_READY_STEP3="  3. From a terminal, run:"
    T_READY_STEP3A="       cd <your-vault-folder>"
    T_READY_STEP3B="       claude"
    T_READY_STEP4="  4. Paste this as your first message to Claude:"
    T_READY_STEP4A="       read ~/.claude/onboarding/first-session-prompt.md and walk me through it"
    T_READY_READ_SELF="  Or read it yourself at:"
    T_MULTI_BLANK="Enter comma-separated numbers (or blank for none): "
    T_VAULT_HINT_TITLE="Your vault is ready at:"
    T_VAULT_HINT_L1="To use it with Obsidian (recommended):"
    T_VAULT_HINT_L2="  1. Download Obsidian (free): https://obsidian.md"
    T_VAULT_HINT_L3="  2. Open Obsidian → \"Open folder as vault\" → point to the path above"
    T_VAULT_HINT_L4="  3. Recommended plugins (Settings → Community plugins):"
    T_VAULT_HINT_L5="       - Templater  (snippets for daily notes)"
    T_VAULT_HINT_L6="       - Dataview   (SQL-style queries over wiki/)"
    T_VAULT_HINT_L7="The vault is already wired to Claude via CLAUDE.md."
fi

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
    local prompt="$1" default_csv="$2"; shift 2
    echo "$prompt" >&2
    local i=1
    local default_idxs=""
    for opt in "$@"; do
        local id label desc
        id="$(echo "$opt" | cut -d'|' -f1)"
        label="$(echo "$opt" | cut -d'|' -f2)"
        desc="$(echo "$opt" | cut -d'|' -f3-)"
        if [[ ",$default_csv," == *",$id,"* ]]; then
            default_idxs+="${i},"
        fi
        printf '  %d. %s — %s\n' "$i" "$label" "$desc" >&2
        i=$((i + 1))
    done
    default_idxs="${default_idxs%,}"
    local label="${T_MULTI_BLANK%": "}"
    [[ -n "$default_idxs" ]] && label+=" [default: $default_idxs]"
    local reply=""
    read -r -p "$label: " reply || true
    if [[ -z "$reply" ]]; then
        # Use default
        reply="$default_idxs"
    fi
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

prompt_single() {
    local prompt="$1" default_id="$2"; shift 2
    echo "$prompt" >&2
    local i=1
    local default_idx=""
    for opt in "$@"; do
        local id label desc marker=" "
        id="$(echo "$opt" | cut -d'|' -f1)"
        label="$(echo "$opt" | cut -d'|' -f2)"
        desc="$(echo "$opt" | cut -d'|' -f3-)"
        [[ "$id" == "$default_id" ]] && { marker="*"; default_idx="$i"; }
        printf '  %s%d. %s — %s\n' "$marker" "$i" "$label" "$desc" >&2
        i=$((i + 1))
    done
    local reply=""
    if [[ -n "$default_idx" ]]; then
        read -r -p "Enter number [default: $default_idx]: " reply || true
    else
        read -r -p "Enter number: " reply || true
    fi
    if [[ -z "$reply" ]]; then echo "$default_id"; return; fi
    if [[ "$reply" =~ ^[0-9]+$ ]] && (( reply >= 1 && reply <= $# )); then
        local opt="${!reply}"
        echo "$(echo "$opt" | cut -d'|' -f1)"
    else
        echo "$default_id"
    fi
}

prompt_secret() {
    local prompt="$1" reply=""
    # -s suppresses echo
    read -r -s -p "$prompt: " reply || true
    echo >&2  # newline after suppressed read
    echo "$reply"
}

# Evaluates a conditional clause against current ANSWERS.
# $1 = idx into branch, $2 = branch name. Returns 0 (ask) or 1 (skip).
test_conditional() {
    local branch="$1" idx="$2"
    local cond
    cond=$(json_get ".branches.${branch}[$idx].conditional" 2>/dev/null || echo "null")
    if [[ -z "$cond" || "$cond" == "null" ]]; then return 0; fi
    local if_answer equals contains
    if_answer=$(echo "$cond" | (have jq && jq -r '.if_answer // empty' || python3 -c 'import json,sys; print(json.load(sys.stdin).get("if_answer",""))'))
    equals=$(echo "$cond" | (have jq && jq -r '.equals // empty' || python3 -c 'import json,sys; d=json.load(sys.stdin); print(d.get("equals","")) if "equals" in d else print("")'))
    contains=$(echo "$cond" | (have jq && jq -r '.contains // empty' || python3 -c 'import json,sys; d=json.load(sys.stdin); print(d.get("contains","")) if "contains" in d else print("")'))
    if [[ -z "$if_answer" ]]; then return 0; fi
    local actual="${ANSWERS[$if_answer]:-}"
    if [[ -n "$equals" ]]; then
        [[ "$actual" == "$equals" ]] && return 0 || return 1
    fi
    if [[ -n "$contains" ]]; then
        [[ ",${actual}," == *",${contains},"* ]] && return 0 || return 1
    fi
    return 0
}

cwd_slug() {
    local cwd
    cwd="$(pwd)"
    echo "$cwd" | sed -e 's|^/||' -e 's|[/ ]|-|g' | tr '[:upper:]' '[:lower:]'
}

# Compose the vault path from vault_name + vault_location (+ vault_custom_path).
# Echoes the path, or empty string if setup_vault != true.
resolve_vault_path() {
    [[ "${ANSWERS[setup_vault]:-false}" != "true" ]] && return 0
    local name="${ANSWERS[vault_name]:-brain}"
    [[ -z "$name" ]] && name="brain"
    local location="${ANSWERS[vault_location]:-desktop}"
    local base
    case "$location" in
        desktop)   base="$HOME/Desktop" ;;
        documents) base="$HOME/Documents" ;;
        home)      base="$HOME" ;;
        custom)
            local custom="${ANSWERS[vault_custom_path]:-}"
            if [[ -z "$custom" ]]; then
                base="$HOME/Desktop"
            else
                base="${custom/#\~/$HOME}"
            fi
            ;;
        *) base="$HOME/Desktop" ;;
    esac
    echo "$base/$name"
}

# ---------------------------------------------------------------------------
# Step 2-3: adaptive wizard (schema 2.0)
# ---------------------------------------------------------------------------
echo "$T_WIZARD_HEADER"

declare -A ANSWERS
declare -a SKILLS=()
declare -a MCPS=()

# Helper to fetch a prompt/explainer in the active language.
get_localized() {
    # $1 = base value (English), $2 = _es value
    if [[ "$LANG_CODE" == "es" && -n "$2" && "$2" != "null" ]]; then
        echo "$2"
    else
        echo "$1"
    fi
}

ask_question() {
    # $1 = jq-style base path, e.g. ".level_question" or ".branches.beginner[3]"
    local base="$1"
    local q_id q_type q_prompt q_prompt_es q_default q_explainer q_explainer_es q_secret
    q_id=$(json_get "${base}.id")
    q_type=$(json_get "${base}.type")
    q_prompt=$(json_get "${base}.prompt")
    q_prompt_es=$(json_get "${base}.prompt_es" 2>/dev/null || echo "")
    q_default=$(json_get "${base}.default")
    q_explainer=$(json_get "${base}.explainer" 2>/dev/null || echo "")
    q_explainer_es=$(json_get "${base}.explainer_es" 2>/dev/null || echo "")
    q_secret=$(json_get "${base}.secret" 2>/dev/null || echo "false")
    local prompt explainer
    prompt=$(get_localized "$q_prompt" "$q_prompt_es")
    explainer=$(get_localized "$q_explainer" "$q_explainer_es")
    [[ -n "$explainer" && "$explainer" != "null" ]] && echo "    $explainer" >&2
    case "$q_type" in
        text)
            if [[ "$q_secret" == "true" ]]; then
                ANSWERS[$q_id]="$(prompt_secret "$prompt")"
                [[ -z "${ANSWERS[$q_id]}" ]] && ANSWERS[$q_id]="$q_default"
            else
                ANSWERS[$q_id]="$(prompt_text "$prompt" "$q_default")"
            fi
            ;;
        boolean)
            ANSWERS[$q_id]="$(prompt_bool "$prompt" "$q_default")"
            ;;
        multi-select)
            local opt_count
            opt_count=$(json_get "${base}.options" | (have jq && jq 'length' || python3 -c "import json,sys; print(len(json.load(sys.stdin)))"))
            local opts=()
            for (( o=0; o<opt_count; o++ )); do
                local o_id o_label o_label_es o_desc o_desc_es
                o_id=$(json_get "${base}.options[$o].id")
                o_label=$(json_get "${base}.options[$o].label")
                o_label_es=$(json_get "${base}.options[$o].label_es" 2>/dev/null || echo "")
                o_desc=$(json_get "${base}.options[$o].description")
                o_desc_es=$(json_get "${base}.options[$o].description_es" 2>/dev/null || echo "")
                o_label=$(get_localized "$o_label" "$o_label_es")
                o_desc=$(get_localized "$o_desc" "$o_desc_es")
                opts+=("$o_id|$o_label|$o_desc")
            done
            # Default CSV: jq returns ["a","b"] for arrays; convert.
            local default_csv
            default_csv=$(json_get "${base}.default" 2>/dev/null | (have jq && jq -r 'if type=="array" then join(",") else . end' || python3 -c 'import json,sys; d=json.load(sys.stdin); print(",".join(d) if isinstance(d,list) else d)'))
            mapfile -t selected < <(prompt_multi "$prompt" "$default_csv" "${opts[@]}")
            if [[ "$q_id" == "skills_to_install" ]]; then
                SKILLS=("${selected[@]+"${selected[@]}"}")
            elif [[ "$q_id" == "mcps_to_enable" ]]; then
                MCPS=("${selected[@]+"${selected[@]}"}")
            fi
            ANSWERS[$q_id]="$(IFS=,; echo "${selected[*]+"${selected[*]}"}")"
            ;;
        single-select)
            local opt_count
            opt_count=$(json_get "${base}.options" | (have jq && jq 'length' || python3 -c "import json,sys; print(len(json.load(sys.stdin)))"))
            local opts=()
            for (( o=0; o<opt_count; o++ )); do
                local o_id o_label o_label_es o_desc o_desc_es
                o_id=$(json_get "${base}.options[$o].id")
                o_label=$(json_get "${base}.options[$o].label")
                o_label_es=$(json_get "${base}.options[$o].label_es" 2>/dev/null || echo "")
                o_desc=$(json_get "${base}.options[$o].description")
                o_desc_es=$(json_get "${base}.options[$o].description_es" 2>/dev/null || echo "")
                o_label=$(get_localized "$o_label" "$o_label_es")
                o_desc=$(get_localized "$o_desc" "$o_desc_es")
                opts+=("$o_id|$o_label|$o_desc")
            done
            ANSWERS[$q_id]="$(prompt_single "$prompt" "$q_default" "${opts[@]}")"
            ;;
        *)
            echo "Unknown question type: $q_type (id=$q_id)" >&2; exit 1 ;;
    esac
    echo
}

# Step 3a: experience level
ask_question ".level_question"
LEVEL="${ANSWERS[experience_level]}"
echo

# Step 3b: branch-specific questions
BRANCH_COUNT=$(json_get ".branches.${LEVEL}" | (have jq && jq 'length' || python3 -c "import json,sys; print(len(json.load(sys.stdin)))"))
for (( idx=0; idx<BRANCH_COUNT; idx++ )); do
    if ! test_conditional "$LEVEL" "$idx"; then
        continue
    fi
    ask_question ".branches.${LEVEL}[$idx]"
done

# ---------------------------------------------------------------------------
# Step 4: idempotency + backup
# ---------------------------------------------------------------------------
CLAUDE_MD="$CLAUDE_HOME/CLAUDE.md"
BACKUP_PATH=""

if [[ -f "$CLAUDE_MD" ]]; then
    if head -n 1 "$CLAUDE_MD" | grep -q -F "$MARKER" && [[ $FORCE -eq 0 ]]; then
        again=$(prompt_bool "$T_REINSTALL_Q" "false")
        [[ "$again" != "true" ]] && { echo "$T_ABORTED"; exit 0; }
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
    local today memory_dir slug
    today="$(date +%Y-%m-%d)"
    slug="$(cwd_slug)"
    memory_dir="$CLAUDE_HOME/projects/$slug/memory"

    # Derive variables
    local budget="${ANSWERS[monthly_ai_budget]:-under_100}"
    local default_model
    case "$budget" in
        none|under_20) default_model="haiku" ;;
        under_100)     default_model="sonnet" ;;
        over_100)      default_model="opus" ;;
        *)             default_model="sonnet" ;;
    esac
    local cost_threshold
    case "$budget" in
        none)      cost_threshold="5" ;;
        under_20)  cost_threshold="10" ;;
        under_100) cost_threshold="25" ;;
        over_100)  cost_threshold="100" ;;
        *)         cost_threshold="25" ;;
    esac
    local vault_path
    vault_path="$(resolve_vault_path)"
    [[ -z "$vault_path" ]] && vault_path="(none)"
    local primary_goal_human
    case "${ANSWERS[primary_goal]:-}" in
        learn_to_code)     primary_goal_human="learn to code" ;;
        personal_projects) primary_goal_human="build personal projects" ;;
        work_or_business)  primary_goal_human="do work or build a business" ;;
        *)                 primary_goal_human="work with Claude Code" ;;
    esac

    # Resolve conditional blocks via python (multiline regex)
    local resolved
    resolved=$(LEVEL="$LEVEL" SETUP_VAULT="${ANSWERS[setup_vault]:-false}" python3 - <<'PY'
import os, re, sys
content = sys.stdin.read()
level = os.environ.get("LEVEL", "intermediate")
setup_vault = os.environ.get("SETUP_VAULT", "false")
known_levels = {"beginner", "intermediate", "senior"}

def repl(m):
    spec, body = m.group(1), m.group(2)
    if ":" not in spec:
        levels = {x.strip() for x in spec.split("|")}
        return body if level in levels else ""
    key, expected = spec.split(":", 1)
    key, expected = key.strip(), expected.strip()
    actual = setup_vault if key == "setup_vault" else ""
    return body if str(actual) == expected else ""

print(re.sub(r"\{\{IF_LEVEL:([^}]+)\}\}([\s\S]*?)\{\{END\}\}", repl, content), end="")
PY
<<< "$tpl")

    # Placeholder substitution
    local out="$resolved"
    out="${out//\{\{USER_NAME\}\}/${ANSWERS[user_name]:-}}"
    out="${out//\{\{USER_ROLE\}\}/${ANSWERS[user_role]:-}}"
    out="${out//\{\{PRIMARY_LANGUAGE\}\}/${ANSWERS[primary_language]:-unsure}}"
    out="${out//\{\{COMMUNICATION_LANGUAGE\}\}/${ANSWERS[communication_language]:-English}}"
    out="${out//\{\{TODAY\}\}/$today}"
    out="${out//\{\{MEMORY_DIR\}\}/$memory_dir}"
    out="${out//\{\{LEVEL\}\}/$LEVEL}"
    out="${out//\{\{DEFAULT_MODEL\}\}/$default_model}"
    out="${out//\{\{COST_FLAG_THRESHOLD\}\}/$cost_threshold}"
    out="${out//\{\{VAULT_PATH\}\}/$vault_path}"
    out="${out//\{\{PRIMARY_GOAL_HUMAN\}\}/$primary_goal_human}"
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
        # Resolve {{STOP_HOOK_COMMAND}} per OS into a sibling temp template.
        # macOS and Linux both invoke notify-stop.sh via bash. Escape any
        # inner double quotes for JSON safety (none expected here, but cheap).
        STOP_HOOK_CMD='bash ~/.claude/hooks/notify-stop.sh'
        STOP_HOOK_CMD_JSON="${STOP_HOOK_CMD//\"/\\\"}"
        TPL_RESOLVED="$(mktemp -t csk-settings.XXXXXX)"
        sed -e "s|{{STOP_HOOK_COMMAND}}|${STOP_HOOK_CMD_JSON}|g" "$TPL_SETTINGS" > "$TPL_RESOLVED"

        enabled_csv="$(IFS=,; echo "${MCPS[*]+"${MCPS[*]}"}")"
        if have jq; then
            existing="{}"
            [[ -f "$DST_SETTINGS" ]] && existing="$(cat "$DST_SETTINGS")"
            enabled_json=$(jq -Rcn --arg s "$enabled_csv" '$s | split(",") | map(select(length>0))')
            echo "$existing" | jq \
                --slurpfile tpl <(cat "$TPL_RESOLVED") \
                --argjson enabled "$enabled_json" '
                . as $existing
                | $tpl[0] as $tpl
                | ($existing * ($tpl | del(.mcpServers)))
                | .mcpServers = (($existing.mcpServers // {}) +
                    (($tpl.mcpServers // {}) | with_entries(select(.key as $k | $enabled | index($k)))))
                ' > "$DST_SETTINGS.tmp"
            mv "$DST_SETTINGS.tmp" "$DST_SETTINGS"
        else
            python3 - "$DST_SETTINGS" "$TPL_RESOLVED" "$enabled_csv" <<'PY'
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
        # v0.4.0 — apply model / permission profile / status line / API keys / Stop-hook-opt-out.
        BUDGET="${ANSWERS[monthly_ai_budget]:-under_100}"
        case "$BUDGET" in
            none|under_20) DEFAULT_MODEL="haiku" ;;
            under_100)     DEFAULT_MODEL="sonnet" ;;
            over_100)      DEFAULT_MODEL="opus" ;;
            *)             DEFAULT_MODEL="sonnet" ;;
        esac
        PERM_PROFILE="${ANSWERS[permission_profile]:-balanced}"
        SL_PRESET="${ANSWERS[status_line]:-balanced}"
        STOP_OPTOUT="false"
        [[ "${ANSWERS[enable_stop_hook]:-true}" != "true" ]] && STOP_OPTOUT="true"

        DEFAULT_MODEL="$DEFAULT_MODEL" PERM_PROFILE="$PERM_PROFILE" SL_PRESET="$SL_PRESET" \
        STOP_OPTOUT="$STOP_OPTOUT" \
        CONTEXT7_KEY="${ANSWERS[context7_api_key]:-}" GITHUB_PAT="${ANSWERS[github_pat]:-}" \
        DST_SETTINGS="$DST_SETTINGS" \
        python3 - <<'PY'
import json, os
p = os.environ["DST_SETTINGS"]
with open(p, encoding="utf-8") as f:
    d = json.load(f)

# model default
d["model"] = os.environ["DEFAULT_MODEL"]

# permission profile
prof = os.environ["PERM_PROFILE"]
if prof == "cautious":
    d["skipAutoPermissionPrompt"] = False
    d["skipDangerousModePermissionPrompt"] = False
elif prof == "balanced":
    d["skipAutoPermissionPrompt"] = True
    d["skipDangerousModePermissionPrompt"] = False
elif prof == "expert":
    d["skipAutoPermissionPrompt"] = True
    d["skipDangerousModePermissionPrompt"] = True

# status line preset
preset = os.environ["SL_PRESET"]
cmd = "bash ~/.claude/statusline-command.sh " + (preset if preset in ("minimal","balanced","verbose") else "balanced")
d.setdefault("statusLine", {})
d["statusLine"]["type"] = "command"
d["statusLine"]["command"] = cmd

# MCP API keys
ms = d.get("mcpServers", {})
c7 = os.environ.get("CONTEXT7_KEY", "")
if c7 and "context7" in ms:
    ms["context7"].setdefault("headers", {})["CONTEXT7_API_KEY"] = c7
gh = os.environ.get("GITHUB_PAT", "")
if gh and "github" in ms:
    ms["github"].setdefault("env", {})["GITHUB_PERSONAL_ACCESS_TOKEN"] = gh

# Stop hook opt-out
if os.environ["STOP_OPTOUT"] == "true":
    if isinstance(d.get("hooks"), dict):
        d["hooks"].pop("Stop", None)

with open(p, "w", encoding="utf-8") as f:
    json.dump(d, f, indent=2)
PY
        rm -f "$TPL_RESOLVED"
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
    HOOK_TPL="$REPO_ROOT/templates/hooks/notify-stop.sh.example"
    HOOK_DST="$CLAUDE_HOME/hooks/notify-stop.sh"
    if [[ -f "$HOOK_TPL" ]]; then
        action COPY "$HOOK_DST"
        if [[ $DRY_RUN -eq 0 ]]; then
            mkdir -p "$(dirname "$HOOK_DST")"
            cp "$HOOK_TPL" "$HOOK_DST"
            chmod +x "$HOOK_DST"
        fi
        CREATED_PATHS+=("$HOOK_DST")
    else
        echo "  SKIP    Stop hook (template not present at $HOOK_TPL)"
    fi
fi

# ---------------------------------------------------------------------------
# Step 9.5 (v0.4.1): knowledge vault scaffold — Obsidian-native
# ---------------------------------------------------------------------------
VAULT_PATH_FINAL="$(resolve_vault_path)"
if [[ -n "$VAULT_PATH_FINAL" ]]; then
    action VAULT "$VAULT_PATH_FINAL"
    if [[ $DRY_RUN -eq 0 ]]; then
        for sub in raw wiki outputs projects _daily _session-handoffs; do
            mkdir -p "$VAULT_PATH_FINAL/$sub"
        done
        VAULT_TODAY="$(date +%Y-%m-%d)"
        # Heredoc with quoted EOF — literal text, no interpolation, no backtick escaping
        cat > "$VAULT_PATH_FINAL/CLAUDE.md" <<'VAULT_CLAUDE_MD_EOF'
<!-- claude-starter-kit vault — generated __VAULT_TODAY__ -->

# Knowledge vault — Claude's second memory

This folder is your **second memory**. Claude reads it at the start of
every session in this directory, and writes back to it during and after
sessions. It is Obsidian-compatible out of the box.

The contract below tells Claude exactly how to use this vault. Follow
it — these rules exist to prevent the two failure modes that kill
note-systems: (1) infinite looping rediscovery, (2) silent duplication.

---

## Folder map

Karpathy 3-folder layout + utilities:

- `raw/` — unprocessed notes, dumps, transcripts, paste-ins. Cheap to
  write, no quality bar. Filename: `YYYY-MM-DD-<slug>.md`.
- `wiki/` — distilled, durable knowledge written for future-self. One
  idea per note. Filename: `<topic>.md` (kebab-case).
- `outputs/` — finished artifacts produced from raw + wiki (decks,
  reports, code, posts). Filename: `<project>/<slug>.<ext>`.
- `projects/` — one folder per active project. Each may contain its
  own `CLAUDE.md` that overrides this file for that subtree.
- `_daily/` — daily notes. Filename: `YYYY-MM-DD.md` (one per day).
- `_session-handoffs/` — Claude session handoffs. Filename:
  `YYYY-MM-DD-HHMM-<slug>.md`.

---

## Obsidian conventions

This vault uses three Obsidian-native conventions. Apply them every time
you write a note here.

1. **Wiki-links.** Link related concepts with `[[double-brackets]]`.
   Example: in `wiki/prompt-caching.md`, when mentioning Sonnet, write
   `[[claude-sonnet]]`. This activates Obsidian's graph view and lets
   future-Claude traverse the knowledge by relevance, not by filename.
2. **Atomic notes.** One note = one idea. If a note covers 3 ideas,
   split into 3 notes and link them. A note titled
   `wiki/everything-about-x.md` is an anti-pattern — refactor it.
3. **Daily notes.** Open `_daily/YYYY-MM-DD.md` at the start of every
   working session and append to it at the end. The daily is the
   chronological log; `wiki/` is the topical encyclopedia.

---

## Search-before-write protocol (anti-duplication)

Before creating any note in `wiki/` or `raw/`:

1. **Grep the vault.** Search for keywords from the note's topic across
   `wiki/`, `raw/`, and `_daily/`. Use Grep, not memory.
2. **If a related note exists:** open it. Decide one of:
   - **Update in place** — append a section, refine wording. Preferred.
   - **Link from the existing note** to a new sister note covering a
     different facet (only if the new content is genuinely a distinct
     atomic idea).
   - **Refactor** — split the old note if it's grown non-atomic.
3. **Only if nothing relevant exists,** create the new note. Add at
   least one `[[link]]` to a related note on creation — orphans rot.

**Do not** create `wiki/notes-on-x.md` when `wiki/x.md` exists.
**Do not** trust a sense of "I haven't seen this before" — grep first.

---

## Where to put what (routing rules)

When the user says "save this", "remember this", or "note this", route by
intent, not by filename:

| User intent | Goes to | Filename pattern |
|---|---|---|
| Quick capture, in-progress thinking, paste-in | `raw/` | `YYYY-MM-DD-<slug>.md` |
| Reusable lesson, pattern, reference, decision | `wiki/` | `<topic>.md` |
| Finished artifact (deck, report, code, post) | `outputs/<project>/` | `<slug>.<ext>` |
| Project-specific work-in-progress | `projects/<name>/` | per-project |
| Today's chronological log entry | `_daily/` | `YYYY-MM-DD.md` |
| End-of-session summary for the next agent | `_session-handoffs/` | `YYYY-MM-DD-HHMM-<slug>.md` |

If unsure between `raw/` and `wiki/`: pick `raw/`. Promote to
`wiki/` later, after the idea has settled.

---

## Closing protocol (let Claude write back)

At the end of every working session in this vault, before saying goodbye:

1. **Open the daily note** for today: `_daily/YYYY-MM-DD.md`. Create
   it from the seed if missing.
2. **Append a "Session — HH:MM" section** with:
   - 2-3 bullet points of what was done.
   - `[[wiki-links]]` to every wiki note touched or created today.
   - Any open question or next-step.
3. **If a durable pattern emerged** (a decision, a reusable recipe, an
   anti-pattern worth remembering), create `wiki/<topic>.md` and link
   to it from the daily.
4. **If the session was about a specific project**, also drop a handoff
   in `_session-handoffs/` (the project may have its own protocol —
   check `projects/<name>/CLAUDE.md` first).

This is what makes the vault a real second memory instead of a folder
full of files: every session compounds.

---

## Naming conventions

- `kebab-case.md` for all wiki notes. No spaces, no underscores.
- No dates in filenames **except** `_daily/` and `_session-handoffs/`.
- No version suffixes (`-v2`, `-final`, `-old`). Edit in place.
- English filenames. Content may be in any language.

---

## What NOT to do (anti-patterns)

- **Do not re-summarize the daily at the start of every session.** Read
  the latest daily and the relevant wiki notes; do not regenerate them.
- **Do not create `wiki/notes-about-x.md` and `wiki/x-notes.md`** —
  these are the same note. Grep first, then write.
- **Do not move notes between folders without updating incoming
  `[[links]]`.** Use Obsidian's rename (or grep+sed) to update links
  before moving.
- **Do not write multi-topic notes.** If you find one, split it on next
  edit.
- **Do not use the vault as a chat log.** Daily notes are summaries, not
  transcripts. If raw transcript is needed, `raw/` is the place.

---

## How Claude should treat this file

Read this CLAUDE.md at the start of every session in this directory.
Treat it as a contract, not a suggestion. If a rule here contradicts a
rule in a parent CLAUDE.md (e.g. `~/.claude/CLAUDE.md`), the
parent wins — but flag the contradiction to the user so it can be
reconciled.
VAULT_CLAUDE_MD_EOF
        # Inject today's date in-place (literal heredoc didn't expand it)
        sed -i.bak "s/__VAULT_TODAY__/$VAULT_TODAY/" "$VAULT_PATH_FINAL/CLAUDE.md" && rm -f "$VAULT_PATH_FINAL/CLAUDE.md.bak"

        DAILY="$VAULT_PATH_FINAL/_daily/$VAULT_TODAY.md"
        [[ ! -f "$DAILY" ]] && printf '# %s\n\n## Today'"'"'s intent\n\n## Notes\n\n## Sessions\n\n## Tomorrow\n' "$VAULT_TODAY" > "$DAILY"
    fi
fi

# ---------------------------------------------------------------------------
# Step 10: summary + open guide
# ---------------------------------------------------------------------------
echo
echo "$T_INSTALL_DONE"
echo "  CLAUDE.md:   $CLAUDE_MD"
echo "${T_SKILLS_LABEL}${SKILLS[*]+"${SKILLS[*]}"}"
echo "${T_MCPS_LABEL}${MCPS[*]+"${MCPS[*]}"}"
echo "${T_HOOK_LABEL}${ANSWERS[enable_stop_hook]:-false}"
[[ -n "$BACKUP_PATH" ]] && echo "${T_BACKUP_LABEL}${BACKUP_PATH}"
GUIDE="$REPO_ROOT/guide/index.html"
echo "${T_GUIDE_LABEL}${GUIDE}"

# Obsidian hint — only when a vault was actually scaffolded
if [[ -n "$VAULT_PATH_FINAL" ]]; then
    echo
    echo "$T_VAULT_HINT_TITLE"
    echo "    $VAULT_PATH_FINAL"
    echo
    echo "$T_VAULT_HINT_L1"
    echo "$T_VAULT_HINT_L2"
    echo "$T_VAULT_HINT_L3"
    echo "$T_VAULT_HINT_L4"
    echo "$T_VAULT_HINT_L5"
    echo "$T_VAULT_HINT_L6"
    echo
    echo "$T_VAULT_HINT_L7"
fi

if [[ $DRY_RUN -eq 0 && -f "$GUIDE" ]]; then
    open_it=$(prompt_bool "$T_OPEN_BROWSER_Q" "true")
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
        echo "$T_READY_BANNER"
        echo "=============================================================="
        echo
        echo "$T_READY_STEP1"
        echo "$T_READY_STEP2"
        echo "$T_READY_STEP3"
        echo "$T_READY_STEP3A"
        echo "$T_READY_STEP3B"
        echo "$T_READY_STEP4"
        echo "$T_READY_STEP4A"
        echo
        echo "$T_READY_READ_SELF"
        echo "    $ONBOARDING_DST"
        echo
    else
        echo "  SKIP    onboarding (template not present at $ONBOARDING_SRC)"
    fi
fi

trap - EXIT
exit 0
