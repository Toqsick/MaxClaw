#!/usr/bin/env bash
# =============================================================================
# register-workflows.sh — registriert MaxClaw-Workflows als OpenClaw-Cron-Jobs
# =============================================================================
# Konkret auf Bastis Setup zugeschnitten:
#   - CLI: openclaw  (Flag-Namen ggf. mit `openclaw cron --help` gegen die
#          installierte Version verifizieren — OpenClaw ändert sich schnell)
#   - GreyHack-Skills angehängt, damit der Agent Build-Pipeline/Sandbox-Patterns kennt
#   - Deliver: telegram:7222661188 (Bastis DM, sonst geht's ins Default)
#   - Bestehende Jobs bleiben unberührt (z. B. yuno-morning-briefing 08:00)
#
# Aufruf:
#   ./register-workflows.sh              # alle 8 Jobs registrieren (idempotent)
#   ./register-workflows.sh --add NAME   # nur einen einzelnen Job registrieren
#   ./register-workflows.sh --list       # alle bekannten Jobs auflisten
#   ./register-workflows.sh --dry-run    # nur anzeigen, nichts anlegen
# =============================================================================

set -euo pipefail

GREEN='\033[0;32m'; YELLOW='\033[1;33m'; RED='\033[0;31m'; NC='\033[0m'
info() { echo -e "${GREEN}→${NC} $*"; }
warn() { echo -e "${YELLOW}⚠${NC} $*"; }
err()  { echo -e "${RED}✗${NC} $*" >&2; }

# --- Voraussetzungen prüfen --------------------------------------------------
if ! command -v openclaw >/dev/null 2>&1; then
    err "openclaw CLI nicht gefunden."; exit 1
fi

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
DELIVER="telegram:7222661188"   # Bastis DM — ohne chat_id ginge's ins Default
DRY_RUN="false"
ADD_ONLY=""

# --- Skills je Job (GreyHack-Fokus: Sandbox-Build + Debugging) ---------------
# greyhack              — Haupt-Skill (Build-Pipeline, Workflow, Pitfalls)
# greyhack-sandbox      — GreyScript AUSSERHALB des Spiels testen (= Claw-Sandbox)
# greyscript-compiler-debugging — Build-Errors systematisch lösen
# greyhack-greyscript   — GreScript-Sprachreferenz (für Mission-Tracker + DB-Watcher)
# skill-navigator       — Skill-Discovery (Knowledge-Distiller)
# multi-agent-orchestration — parallele Subagenten (Knowledge-Distiller)
# yuno-user-preferences — Bastis Schreibstil-Präferenzen (Check-in)
#
# Format: name|schedule|workflow-file|comma-separated-skills|model
# Modell-Werte: heartbeat (kein LLM), main (günstig), heavy (teuer)
# "shell" markiert deterministische Wrapper — werden als --command statt Prompt registriert.

declare -a JOBS=(
    # === Bestehende 3 Jobs (V1) ===
    "greyhack-ci-watch|0 * * * *|workflows/greyhack-ci-watch.md|greyhack,greyhack-sandbox,greyscript-compiler-debugging|heartbeat"
    "greyhack-tool-builder|0 */2 * * *|workflows/greyhack-tool-builder.md|greyhack,greyhack-sandbox,greyscript-compiler-debugging|heavy"
    "github-pr-monitor|0 9,17 * * *|workflows/github-pr-monitor.md||main"

    # === Neue 5 Jobs (V2) ===
    "greyhack-db-watcher|*/30 * * * *|workflows/greyhack-db-watcher.md|greyhack,greyhack-sandbox|heartbeat"
    "greyhack-mission-tracker|0 */4 * * *|workflows/greyhack-mission-tracker.md|greyhack,greyhack-greyscript|main"
    "greyhack-tool-backup-watch|0 */6 * * *|workflows/greyhack-tool-backup-watch.md||shell"
    "greyhack-knowledge-distiller|0 22 * * 0|workflows/greyhack-knowledge-distiller.md|skill-navigator,multi-agent-orchestration,greyhack|heavy"
    "greyhack-basti-checkin|0 20 * * 1,3,5|workflows/greyhack-basti-checkin.md|yuno-user-preferences,greyhack|main"
)

# Per-Job Override für DELIVER (falls ein Job lokal statt Telegram soll)
# Hintergrund: Telegram-Send-Timeout (>10KB Output, Pattern 2 daily-briefing).
# knowledge-distiller macht Wochen-Synthese > 10KB → besser lokal.
declare -A DELIVER_OVERRIDE=(
    ["greyhack-knowledge-distiller"]="local"
    ["greyhack-tool-backup-watch"]="local"
)
DEFAULT_DELIVER="$DELIVER"
get_deliver() {
    local n="$1"
    if [[ -n "${DELIVER_OVERRIDE[$n]:-}" ]]; then
        echo "${DELIVER_OVERRIDE[$n]}"
    else
        echo "$DEFAULT_DELIVER"
    fi
}

# --- CLI-Args parsen (braucht JOBS für --list) -------------------------------
while [[ $# -gt 0 ]]; do
    case "$1" in
        --add) ADD_ONLY="$2"; shift 2 ;;
        --list)
            echo "Bekannte MaxClaw-Workflows:"
            for entry in "${JOBS[@]}"; do
                IFS='|' read -r name sched wf _ _ <<< "$entry"
                printf "  - %-32s %-18s %s\n" "$name" "($sched)" "$wf"
            done
            exit 0
            ;;
        --dry-run) DRY_RUN="true"; shift ;;
        -h|--help)
            sed -n '2,18p' "$0"; exit 0
            ;;
        *) err "Unbekannte Option: $1"; exit 2 ;;
    esac
done

# --- Wenn --add NAME: nur diesen einen Job behalten ---------------------------
if [[ -n "$ADD_ONLY" ]]; then
    filtered=()
    found="false"
    for entry in "${JOBS[@]}"; do
        name="${entry%%|*}"
        if [[ "$name" == "$ADD_ONLY" ]]; then
            filtered+=("$entry")
            found="true"
        fi
    done
    if [[ "$found" == "false" ]]; then
        err "Unbekannter Job-Name: $ADD_ONLY"
        echo "Verfügbar:"
        for entry in "${JOBS[@]}"; do echo "  - ${entry%%|*}"; done
        exit 2
    fi
    JOBS=("${filtered[@]}")
    info "Modus --add: registriere nur '$ADD_ONLY'"
fi

info "Registriere ${#JOBS[@]} Cron-Job(s) (Deliver: $DEFAULT_DELIVER, dry-run=$DRY_RUN)"
echo ""

created_ids=()
for entry in "${JOBS[@]}"; do
    IFS='|' read -r name schedule wf skills_csv model <<< "$entry"
    prompt_file="$REPO_DIR/$wf"
    if [[ ! -f "$prompt_file" ]]; then
        warn "Prompt-Datei fehlt: $wf — übersprungen."
        continue
    fi

    # --- Idempotenz: prüfen, ob Job mit gleichem Namen schon existiert ----------
    if openclaw cron list 2>/dev/null | grep -qE "[[:space:]]${name}[[:space:]]"; then
        info "  = $name  ($schedule) — bereits vorhanden, übersprungen (idempotent)"
        continue
    fi

    # Per-Job deliver-Wert (override oder default)
    job_deliver="$(get_deliver "$name")"
    info "  + $name  ($schedule)  model=$model  deliver=$job_deliver"

    if [[ "$DRY_RUN" == "true" ]]; then
        info "    [dry-run] würde registrieren: $wf"
        continue
    fi

    # Skills als wiederholte --skill flags
    skill_args=()
    if [[ -n "$skills_csv" ]]; then
        IFS=',' read -ra sks <<< "$skills_csv"
        for s in "${sks[@]}"; do
            skill_args+=(--skill "$s")
        done
    fi

    # Modell setzen
    # ACHTUNG: `openclaw cron add` setzt das Modell nicht zuverlässig per Ad-hoc-Flag
    # (siehe Skill openclaw-cli-quirks, Pitfall #1). Modell wird nachträglich über den
    # Job-/Session-Provider gepinnt. Wir sammeln model_args nur für die zweite Stufe.
    model_args=()
    if [[ -n "$model" && "$model" != "shell" ]]; then
        model_args+=("$model")
    fi

    # Für "shell"-Jobs wird der File-Inhalt als --command registriert; sonst als
    # --message (Prompt). Flag-Namen ggf. mit `openclaw cron --help` verifizieren.
    if [[ "$model" == "shell" ]]; then
        payload_args=(--command "$(cat "$prompt_file")")
    else
        payload_args=(--message "$(cat "$prompt_file")")
    fi

    # Job anlegen — Output einfangen, ID extrahieren
    out="$(openclaw cron add --cron "$schedule" "${payload_args[@]}" \
            --name "$name" --deliver "$job_deliver" \
            --workdir "$REPO_DIR" \
            "${skill_args[@]}" 2>&1)" \
        || { err "    Fehler bei $name: $out"; continue; }

    # OpenClaw gibt typisch 'Created job X' oder die ID aus
    jid="$(echo "$out" | grep -oE '[a-f0-9]{12,}' | head -1)"
    [[ -n "$jid" ]] && created_ids+=("$jid") && info "    → $jid" || info "    → $out"
done

echo ""

# Falls neue Jobs angelegt wurden: ID-Notiz ins Repo schreiben
note="$REPO_DIR/cron-jobs.md"
{
    echo "# Aktive MaxClaw Cron-Jobs"
    echo ""
    echo "Automatisch von \`./workflows/register-workflows.sh\` generiert — nicht von Hand pflegen."
    echo ""
    echo "Letzte Registrierung: $(date +%Y-%m-%d\ %H:%M:%S)"
    echo ""
    for j in "${JOBS[@]}"; do
        IFS='|' read -r name schedule wf _ _ <<< "$j"
        echo "- **$name** (\`$schedule\`) → \`$wf\`"
    done
    echo ""
    echo "Verifizieren: \`openclaw cron list\`"
    echo ""
    echo "## Hilfe"
    echo '```bash'
    echo "./workflows/register-workflows.sh              # alle 8 Jobs registrieren (idempotent)"
    echo "./workflows/register-workflows.sh --add NAME   # nur einen Job registrieren"
    echo "./workflows/register-workflows.sh --list       # alle Jobs auflisten"
    echo "./workflows/register-workflows.sh --dry-run    # nur anzeigen, nichts anlegen"
    echo '```'
} > "$note"

info "→ $note aktualisiert."
info "Fertig. Übersicht: openclaw cron list"