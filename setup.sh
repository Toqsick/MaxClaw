#!/usr/bin/env bash
# =============================================================================
# setup.sh — MaxClaw One-Command-Setup
# Kopiert die Vorlagen (agent/, config/, skills/) in den MaxClaw-Workspace.
# Sicher by design: überschreibt NICHTS ohne Nachfrage, legt Backups an.
# =============================================================================

set -euo pipefail

# --- Farben für lesbare Ausgabe ----------------------------------------------
GREEN='\033[0;32m'; YELLOW='\033[1;33m'; RED='\033[0;31m'; NC='\033[0m'
info()  { echo -e "${GREEN}→${NC} $*"; }
warn()  { echo -e "${YELLOW}⚠${NC} $*"; }
err()   { echo -e "${RED}✗${NC} $*" >&2; }

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# --- Workspace-Ort bestimmen (OpenClaw) --------------------------------------
if [[ -d "$HOME/.openclaw" ]]; then
    WORKSPACE="$HOME/.openclaw/agent"
else
    warn "Kein bestehender OpenClaw-Workspace gefunden."
    read -rp "Workspace-Pfad angeben [$HOME/.openclaw/agent]: " WORKSPACE
    WORKSPACE="${WORKSPACE:-$HOME/.openclaw/agent}"
fi
info "Workspace: $WORKSPACE"
mkdir -p "$WORKSPACE"

# --- Backup-Ordner für den Fall der Fälle ------------------------------------
BACKUP="$WORKSPACE/.maxclaw-backup-$(date +%Y%m%d-%H%M%S)"

# --- Core-Dateien kopieren (mit Nachfrage bei Konflikt) ----------------------
copy_safe() {
    local src="$1" dst="$2"
    if [[ -f "$dst" ]]; then
        warn "existiert schon: $(basename "$dst")"
        read -rp "    überschreiben? (Backup wird angelegt) [y/N] " ans
        if [[ "${ans,,}" != "y" ]]; then
            info "    übersprungen."
            return
        fi
        mkdir -p "$BACKUP"
        cp "$dst" "$BACKUP/"
        info "    Backup → $BACKUP/$(basename "$dst")"
    fi
    cp "$src" "$dst"
    info "    kopiert: $(basename "$dst")"
}

info "Kopiere Core-Dateien nach $WORKSPACE ..."
for f in SOUL IDENTITY AGENTS USER TOOLS MEMORY HEARTBEAT; do
    [[ -f "$REPO_DIR/agent/$f.md" ]] && copy_safe "$REPO_DIR/agent/$f.md" "$WORKSPACE/$f.md"
done

# --- Beispiel-Skill installieren ---------------------------------------------
SKILL_DST="$WORKSPACE/skills"
mkdir -p "$SKILL_DST"
if [[ -d "$REPO_DIR/skills/project-doc-sync" ]]; then
    cp -r "$REPO_DIR/skills/project-doc-sync" "$SKILL_DST/"
    info "Skill installiert: project-doc-sync"
fi

# --- OpenClaw-Config als Vorlage (NICHT automatisch aktivieren) --------------
# OpenClaw-Config-Root ist der Parent des agent/-Workspace (z.B. ~/.openclaw/).
CFG_ROOT="$(dirname "$WORKSPACE")"
for cfg in openclaw.json exec-approvals.json greyhack.yaml; do
    if [[ -f "$REPO_DIR/config/$cfg" ]]; then
        cp "$REPO_DIR/config/$cfg" "$CFG_ROOT/$cfg.example"
        warn "$cfg als $cfg.example abgelegt — vor Aktivierung prüfen (docs/07)!"
    fi
done

echo ""
info "Fertig. Nächste Schritte:"
echo "   1. Core-Dateien in $WORKSPACE anpassen (Namen, Secrets via 'openclaw secrets')."
echo "   2. openclaw.json.example + exec-approvals.json.example prüfen → ohne .example aktivieren."
echo "      Danach:  openclaw config validate && openclaw doctor --fix"
echo "   3. Workflows registrieren:  ./workflows/register-workflows.sh"
echo "   4. Security-Block lesen:    docs/07-security.md"
