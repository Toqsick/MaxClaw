#!/usr/bin/env bash
# =============================================================================
# maxclaw-config-check.sh — MaxClaw config.yaml Validator (v3.0)
# -----------------------------------------------------------------------------
# Prüft die zentralen Sicherheits-Invarianten der MaxClaw v3.0-Konfiguration.
# Standard-Deny-Philosophie, GreyHack-Track-Einstellungen, Heartbeat-Modell.
#
# Usage:
#   maxclaw-config-check.sh                       # prüft /tmp/maxclaw-clone/config/config.yaml
#   maxclaw-config-check.sh /path/to/config.yaml  # benutzerdefinierte Datei
#
# Exit-Codes:
#   0 = alle Checks bestanden
#   1 = kritischer Fehler (Blocker)
#   2 = Warnung (non-fatal)
# =============================================================================

set -uo pipefail

CONFIG="${1:-/tmp/maxclaw-clone/config/config.yaml}"
WARNINGS=0
ERRORS=0

# --- Helpers --------------------------------------------------------------
red()    { printf '\033[31m%s\033[0m\n' "$*"; }
green()  { printf '\033[32m%s\033[0m\n' "$*"; }
yellow() { printf '\033[33m%s\033[0m\n' "$*"; }
bold()   { printf '\033[1m%s\033[0m\n' "$*"; }

err()   { red   "  [✗] $*"; ERRORS=$((ERRORS+1)); }
warn()  { yellow "  [!] $*"; WARNINGS=$((WARNINGS+1)); }
ok()    { green "  [✓] $*"; }

heading() { bold ""; bold "=== $* ==="; }

# --- Pre-flight -----------------------------------------------------------
heading "MaxClaw config.yaml Validator v3.0"
echo "  Datei: $CONFIG"

if [ ! -f "$CONFIG" ]; then
    red "  [FATAL] config-Datei nicht gefunden: $CONFIG"
    exit 1
fi

# yq verfügbar? Sonst Python-yaml Fallback (vollständig nested-path-fähig).
HAS_YQ=false
if command -v yq >/dev/null 2>&1; then
    HAS_YQ=true
    echo "  yq: $(yq --version 2>&1 | head -1)"
elif python3 -c "import yaml" 2>/dev/null; then
    echo "  python-yaml: verfügbar (Fallback aktiv)"
else
    yellow "  [!] weder yq noch python-yaml verfügbar — rudimentärer grep-Fallback"
fi

# --- Helper für yq/python-yaml/grep-basierte Abfrage ----------------------
get_yaml() {
    local key="$1"
    if [ "$HAS_YQ" = "true" ]; then
        yq eval "$key" "$CONFIG" 2>/dev/null
    elif python3 -c "import yaml" 2>/dev/null; then
        python3 - "$CONFIG" "$key" <<'PYEOF'
import sys, yaml
cfg_path, key = sys.argv[1], sys.argv[2]
with open(cfg_path) as f:
    cfg = yaml.safe_load(f)
# key wie ".permissions.default" oder ".greyhack.build.use_flag"
parts = [p for p in key.lstrip('.').split('.') if p]
val = cfg
for p in parts:
    if isinstance(val, dict) and p in val:
        val = val[p]
    else:
        sys.exit(0)
if isinstance(val, bool):
    print(str(val).lower())
elif val is None:
    print('')
else:
    print(val)
PYEOF
    else
        # Sehr vereinfachter Fallback: nur top-level
        local first_part="${key%%.*}"
        grep -E "^${first_part}:" "$CONFIG" | head -1 | sed 's/^[^:]*:[[:space:]]*//'
    fi
}

# --- Check 1: DEFAULT-DENY als Grundphilosophie --------------------------
heading "1. Default-Deny-Philosophie"
default_mode=$(get_yaml '.permissions.default' 2>/dev/null | tr -d '[:space:]')
if [ "$default_mode" = "deny" ]; then
    ok "permissions.default = deny (Grundphilosophie erhalten)"
else
    err "permissions.default = '$default_mode' (ERWARTET: deny)"
fi

# --- Check 2: git push main Verbot ----------------------------------------
heading "2. Git-Push-Schutz (main tabu)"
if grep -qE 'git push.*main' "$CONFIG"; then
    ok "git push*main* in deny-Liste gefunden"
else
    err "git push*main* fehlt in deny-Liste — Bastis Regel verletzt!"
fi

# --- Check 3: greybel build Konfiguration --------------------------------
heading "3. Greybel-Build-Konfiguration"

# 3a: greybel build ist erlaubt
if grep -qE '^\s*-\s*"?greybel build' "$CONFIG"; then
    ok "greybel build in allow-Liste"
else
    err "greybel build fehlt in allow-Liste"
fi

# 3b: -u-Flag ist verboten (Inline-if-Bug)
if grep -qE 'greybel build -u\*|greybel build\*-u\*' "$CONFIG"; then
    ok "greybel build -u in deny-Liste (Inline-if-Bug-Schutz aktiv)"
else
    err "greybel build -u* fehlt in deny-Liste — Inline-if-Bug-Risiko!"
fi

# 3c: greyhack.use_flag muss false sein
use_flag=$(get_yaml '.greyhack.build.use_flag' 2>/dev/null | tr -d '[:space:]')
if [ "$use_flag" = "false" ]; then
    ok "greyhack.build.use_flag = false (kein -u Flag)"
else
    err "greyhack.build.use_flag = '$use_flag' (ERWARTET: false)"
fi

# 3d: //command: Header ist Pflicht
if grep -q 'required_header.*//command' "$CONFIG"; then
    ok "greyhack.build.required_header = //command: (Pflicht-Header dokumentiert)"
else
    warn "greyhack.build.required_header nicht gesetzt — Pflicht-Header unklar"
fi

# --- Check 4: Sandbox-Konfiguration --------------------------------------
heading "4. Sandbox-Konfiguration"

if grep -qE 'sandbox_clone|/tmp/MaxClaw/greyhack-sandbox' "$CONFIG"; then
    ok "Sandbox-Pfad /tmp/MaxClaw/greyhack-sandbox/ definiert"
else
    err "Sandbox-Pfad fehlt — greyhack.sandbox nicht konfiguriert"
fi

network_iso=$(get_yaml '.greyhack.sandbox.network_isolation' 2>/dev/null | tr -d '[:space:]')
if [ "$network_iso" = "true" ]; then
    ok "greyhack.sandbox.network_isolation = true"
else
    err "greyhack.sandbox.network_isolation = '$network_iso' (ERWARTET: true — sonst prod-Risiko)"
fi

# --- Check 5: Greyhack-Block aktiv ---------------------------------------
heading "5. GreyHack-Block aktiv"

gh_enabled=$(get_yaml '.greyhack.enabled' 2>/dev/null | tr -d '[:space:]')
if [ "$gh_enabled" = "true" ]; then
    ok "greyhack.enabled = true"
else
    warn "greyhack.enabled = '$gh_enabled' — GreyHack-Track deaktiviert?"
fi

# Heavy-Tasks für GreyHack definiert?
if grep -qE 'greybel build validation|grey_script generation' "$CONFIG"; then
    ok "heavy_tasks für GreyHack definiert"
else
    warn "greyhack.heavy_tasks nicht definiert — heavy-Modell wird evtl. nie genutzt"
fi

# --- Check 6: Modell-Routing ---------------------------------------------
heading "6. Modell-Routing"

# Heartbeat muss günstig sein
hb_model=$(get_yaml '.models.heartbeat.model' 2>/dev/null)
if echo "$hb_model" | grep -qiE 'flash|nano|mini|haiku'; then
    ok "Heartbeat-Modell günstig: $hb_model"
else
    warn "Heartbeat-Modell '$hb_model' ist möglicherweise nicht das billigste"
fi

# Heavy-Modell definiert?
heavy_model=$(get_yaml '.models.heavy.model' 2>/dev/null)
if [ -n "$heavy_model" ] && [ "$heavy_model" != "null" ]; then
    ok "Heavy-Modell definiert: $heavy_model"
else
    err "models.heavy fehlt — keine starke Option für greybel validation"
fi

# --- Check 7: Write-Paths ------------------------------------------------
heading "7. Write-Paths (GreyHack)"

if grep -qE '~/greyhack-tools/greyhack-sandbox/' "$CONFIG"; then
    ok "greyhack-sandbox in write_paths"
else
    err "~/greyhack-tools/greyhack-sandbox/ fehlt in write_paths"
fi

if grep -qE '~/greyhack-tools/build/' "$CONFIG"; then
    ok "~/greyhack-tools/build/ in write_paths"
else
    warn "build/-Ordner nicht in write_paths — greybel-Output kann nicht gespeichert werden"
fi

# --- Check 8: Browser deaktiviert (Prompt-Injection) ---------------------
heading "8. Browser-Schutz (Prompt-Injection)"
browser_enabled=$(get_yaml '.permissions.tools.browser.enabled' 2>/dev/null | tr -d '[:space:]')
if [ "$browser_enabled" = "false" ]; then
    ok "permissions.tools.browser.enabled = false (Prompt-Injection-Schutz)"
else
    err "browser ist aktiviert — Prompt-Injection-Risiko!"
fi

# --- Check 9: Bestätigungspflichten --------------------------------------
heading "9. Bestätigungspflichten (HITL)"

for required in send_message delete_outside_workspace git_push_main greyhack_strike; do
    if grep -qE "^\s*-\s*${required}\b" "$CONFIG"; then
        ok "$required in confirmations.require_before"
    else
        err "$required fehlt in confirmations.require_before"
    fi
done

# --- Zusammenfassung ------------------------------------------------------
heading "Zusammenfassung"
TOTAL=$((ERRORS + WARNINGS))
echo "  Errors:   $ERRORS"
echo "  Warnings: $WARNINGS"
echo "  Total:    $TOTAL"
echo ""

if [ "$ERRORS" -gt 0 ]; then
    red "FAIL: $ERRORS kritische Fehler — config.yaml ist NICHT sicher!"
    echo ""
    echo "Manuelle Korrektur erforderlich. Siehe AGENT-UPGRADE-2026-07-04.md"
    exit 1
elif [ "$WARNINGS" -gt 0 ]; then
    yellow "PASS (mit Warnungen): $WARNINGS Warnungen — bitte manuell prüfen"
    exit 2
else
    green "OK: Alle Checks bestanden."
    exit 0
fi