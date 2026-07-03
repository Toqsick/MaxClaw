#!/usr/bin/env bash
# =============================================================================
# register-workflows.sh — registriert MaxClaw-Workflows als Hermes-Cron-Jobs
# =============================================================================
# Konkret auf Bastis Setup zugeschnitten:
#   - CLI: hermes (openclaw-CLI gibt's auf dieser Instanz nicht)
#   - GreyHack-Skills angehängt, damit der Agent Build-Pipeline/Sandbox-Patterns kennt
#   - Deliver: telegram:7222661188 (Bastis DM, sonst geht's ins Default)
#   - Bestehende Jobs bleiben unberührt (z. B. yuno-morning-briefing 08:00)
# =============================================================================

set -euo pipefail

GREEN='\033[0;32m'; YELLOW='\033[1;33m'; RED='\033[0;31m'; NC='\033[0m'
info() { echo -e "${GREEN}→${NC} $*"; }
warn() { echo -e "${YELLOW}⚠${NC} $*"; }
err()  { echo -e "${RED}✗${NC} $*" >&2; }

# --- Voraussetzungen prüfen --------------------------------------------------
if ! command -v hermes >/dev/null 2>&1; then
    err "hermes CLI nicht gefunden."; exit 1
fi

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
DELIVER="telegram:7222661188"   # Bastis DM — ohne chat_id ginge's ins Default

# --- Skills je Job (GreyHack-Fokus: Sandbox-Build + Debugging) ---------------
# greyhack              — Haupt-Skill (Build-Pipeline, Workflow, Pitfalls)
# greyhack-sandbox      — GreyScript AUSSERHALB des Spiels testen (= Claw-Sandbox)
# greyscript-compiler-debugging — Build-Errors systematisch lösen

declare -a JOBS=(
    "greyhack-ci-watch|0 * * * *|workflows/greyhack-ci-watch.md|greyhack,greyhack-sandbox,greyscript-compiler-debugging"
    "greyhack-tool-builder|0 */2 * * *|workflows/greyhack-tool-builder.md|greyhack,greyhack-sandbox,greyscript-compiler-debugging"
    "github-pr-monitor|0 9,17 * * *|workflows/github-pr-monitor.md|"
)

info "Registriere ${#JOBS[@]} Cron-Jobs (Deliver: $DELIVER)"
echo ""

created_ids=()
for entry in "${JOBS[@]}"; do
    IFS='|' read -r name schedule wf skills_csv <<< "$entry"
    prompt_file="$REPO_DIR/$wf"
    if [[ ! -f "$prompt_file" ]]; then
        warn "Prompt-Datei fehlt: $wf — übersprungen."
        continue
    fi
    info "  + $name  ($schedule)"
    # Skills als wiederholte --skill flags
    skill_args=()
    if [[ -n "$skills_csv" ]]; then
        IFS=',' read -ra sks <<< "$skills_csv"
        for s in "${sks[@]}"; do
            skill_args+=(--skill "$s")
        done
    fi
    # Job anlegen — Output einfangen, ID extrahieren
    out="$(hermes cron create "$schedule" "$(cat "$prompt_file")" \
            --name "$name" --deliver "$DELIVER" \
            --workdir "$REPO_DIR" \
            "${skill_args[@]}" 2>&1)" || { err "    Fehler bei $name: $out"; continue; }
    # Hermes gibt typisch 'Created job X' oder die ID aus
    jid="$(echo "$out" | grep -oE '[a-f0-9]{12,}' | head -1)"
    [[ -n "$jid" ]] && created_ids+=("$jid") && info "    → $jid" || info "    → $out"
done

echo ""
info "Fertig. Übersicht: hermes cron list"
echo ""

# --- Falls neue Jobs angelegt wurden: ID-Notiz ins Repo schreiben ------------
if [[ ${#created_ids[@]} -gt 0 ]]; then
    note="$REPO_DIR/cron-jobs.md"
    {
        echo "# Aktive MaxClaw Cron-Jobs"
        echo ""
        echo "Automatisch von \`./workflows/register-workflows.sh\` generiert — nicht von Hand pflegen."
        echo ""
        echo "Letzte Registrierung: $(date +%Y-%m-%d\ %H:%M:%S)"
        echo ""
        for j in "${JOBS[@]}"; do
            IFS='|' read -r name schedule wf _ <<< "$j"
            echo "- **$name** (\`$schedule\`) → \`$wf\`"
        done
        echo ""
        echo "Verifizieren: \`hermes cron list\`"
    } > "$note"
    info "→ $note aktualisiert."
fi