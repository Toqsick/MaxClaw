#!/usr/bin/env bash
# =============================================================================
# register-workflows.sh — registriert alle MaxClaw-Workflows als Cron-Jobs
# =============================================================================
# Dieses Skript ist eine VORLAGE. Es zeigt, wie die Workflows aus workflows/
# als Cron-Jobs bei OpenClaw/Hermes registriert werden. Passe den CLI-Aufruf
# an deine Instanz an (openclaw vs. hermes).
#
# Wichtig (docs/05): Heartbeat-nahe Checks laufen im Heartbeat (HEARTBEAT.md),
# feste Zeitpunkte laufen als Cron-Job.
# =============================================================================

set -euo pipefail

# --- CLI-Kommando automatisch erkennen (openclaw oder hermes) ----------------
if command -v openclaw >/dev/null 2>&1; then
    CLI="openclaw"
elif command -v hermes >/dev/null 2>&1; then
    CLI="hermes"
else
    echo "FEHLER: weder 'openclaw' noch 'hermes' CLI gefunden." >&2
    echo "Registriere die Jobs manuell nach den Angaben in workflows/*.md" >&2
    exit 1
fi
echo "→ Nutze CLI: $CLI"

# --- Job-Definitionen: name | schedule | workflow-datei ----------------------
# Deliver-Ziel ist überall telegram (siehe config/config.yaml home_chat_id).
declare -a JOBS=(
    "daily-briefing|0 7 * * *|workflows/daily-briefing.md"
    "greyhack-ci-watch|0 * * * *|workflows/greyhack-ci-watch.md"
    "security-audit-weekly|0 9 * * 1|workflows/security-audit-weekly.md"
    "github-pr-monitor|0 9,17 * * *|workflows/github-pr-monitor.md"
)

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

for job in "${JOBS[@]}"; do
    IFS='|' read -r name schedule wf <<< "$job"
    prompt_file="$SCRIPT_DIR/$wf"
    if [[ ! -f "$prompt_file" ]]; then
        echo "  ⚠ übersprungen (fehlt): $wf" >&2
        continue
    fi
    echo "  + registriere '$name'  ($schedule)"
    # Beispielaufruf — an deine CLI anpassen:
    #   $CLI cron create --name "$name" --schedule "$schedule" \
    #        --prompt-file "$prompt_file" --deliver telegram
    echo "    $CLI cron create --name \"$name\" --schedule \"$schedule\" --prompt-file \"$prompt_file\" --deliver telegram"
done

echo ""
echo "✓ Fertig. Prüfe die Jobs mit:  $CLI cron list"
echo "  (Die \$CLI-Zeilen oben sind auskommentiert — aktivieren, sobald die CLI-Syntax passt.)"
