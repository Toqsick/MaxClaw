#!/usr/bin/env bash
# ==============================================================================
# greyhack-db-snapshot.sh — Sandbox-Snapshot für GreyHack DB
# ==============================================================================
# Erzeugt eine READ-ONLY-Kopie der GreyHack-DB, vergleicht mit Vorgänger,
# trackt Grösse und meldet nur bei Anomalie (Watchdog-Pattern).
#
# Usage:
#   greyhack-db-snapshot.sh              # Normallauf (silent on success)
#   greyhack-db-snapshot.sh --dry-run    # Trockentest mit Output
#   greyhack-db-snapshot.sh --force      # Mit Output erzwingen
#   greyhack-db-snapshot.sh --help       # Hilfe
# ==============================================================================
set -euo pipefail

# --- Konfiguration -----------------------------------------------------------
DB_SOURCE="/mnt/DATA/Programme/Steam/steamapps/common/Grey Hack/Grey Hack_Data/GreyHackDB.db"
BACKUP_DIR="$HOME/backups/greyhack"
SANDBOX_LINK="$BACKUP_DIR/sandbox-latest.db"
MAX_SNAPSHOTS=7
TIMESTAMP=$(date +%Y%m%d_%H%M%S)
SNAPSHOT_FILE="$BACKUP_DIR/GreyHackDB_${TIMESTAMP}.db"
TEMP_DIR=$(mktemp -d /tmp/greyhack-snapshot.XXXXXX)
ANOMALY_THRESHOLD_PCT=20  # Grössensprung >20% = Anomalie
VERBOSE=false

# --- Cleanup trap ------------------------------------------------------------
cleanup() {
    rm -rf "$TEMP_DIR"
}
trap cleanup EXIT

# --- Farben & Logging (nur wenn Verbose oder Fehler) -------------------------
info()   { $VERBOSE && echo -e "ℹ️  $*"; }
warn()   { echo -e "⚠️  $*" >&2; }
success(){ $VERBOSE && echo -e "✅ $*"; }
error()  { echo -e "❌ $*" >&2; }

# --- Argumente parsen --------------------------------------------------------
DRY_RUN=false
FORCE=false

usage() {
    cat <<EOF
Usage: $(basename "$0") [OPTIONS]

Erzeugt Sandbox-Snapshot der GreyHack-Datenbank.
Watchdog-Pattern: silent on success, alert on anomaly.

OPTIONS:
  --dry-run    Trockentest — nur prüfen, nichts speichern
  --force      Immer Output ausgeben (auch ohne Anomalie)
  --help       Diese Hilfe anzeigen
EOF
    exit 0
}

while [[ $# -gt 0 ]]; do
    case "$1" in
        --dry-run) DRY_RUN=true; VERBOSE=true ;;
        --force)   FORCE=true; VERBOSE=true ;;
        --help)    usage ;;
        *)         error "Unbekannte Option: $1"; usage ;;
    esac
    shift
done

# --- Voraussetzungen prüfen --------------------------------------------------
info "Prüfe Voraussetzungen..."

if ! command -v sqlite3 &>/dev/null; then
    error "sqlite3 nicht gefunden. Bitte installieren: sudo apt install sqlite3"
    exit 1
fi

if [[ ! -f "$DB_SOURCE" ]]; then
    error "Datenbank nicht gefunden: $DB_SOURCE"
    exit 1
fi

mkdir -p "$BACKUP_DIR"

# --- DB-Grösse ermitteln (read-only) -----------------------------------------
ORIG_SIZE=$(stat --format=%s "$DB_SOURCE" 2>/dev/null || stat -f%z "$DB_SOURCE" 2>/dev/null)
ORIG_SIZE_MB=$(awk "BEGIN {printf \"%.2f\", $ORIG_SIZE/1048576}")
info "Original-DB: $ORIG_SIZE_MB MB ($ORIG_SIZE Bytes)"

# --- Letzten Snapshot finden -------------------------------------------------
LAST_SNAPSHOT=""
SNAPSHOT_GLOB=("$BACKUP_DIR"/GreyHackDB_*.db)
if [[ -f "${SNAPSHOT_GLOB[0]}" ]]; then
    LAST_SNAPSHOT=$(ls -t "${SNAPSHOT_GLOB[@]}" | head -1 2>/dev/null || true)
fi
LAST_SIZE=0
if [[ -n "$LAST_SNAPSHOT" ]]; then
    LAST_SIZE=$(stat --format=%s "$LAST_SNAPSHOT" 2>/dev/null || stat -f%z "$LAST_SNAPSHOT" 2>/dev/null)
    LAST_SIZE_MB=$(awk "BEGIN {printf \"%.2f\", $LAST_SIZE/1048576}")
    info "Letzter Snapshot: $(basename "$LAST_SNAPSHOT") ($LAST_SIZE_MB MB)"
else
    info "Kein vorheriger Snapshot gefunden — erster Lauf."
fi

# --- Größen-Trend prüfen (Anomalieerkennung) ---------------------------------
ANOMALY=false
ANOMALY_REASONS=()

if [[ $LAST_SIZE -gt 0 ]]; then
    GROWTH=$(( ORIG_SIZE - LAST_SIZE ))
    if [[ $GROWTH -ge 0 ]]; then
        PCT=$(awk "BEGIN {printf \"%.1f\", ($GROWTH/$LAST_SIZE)*100}")
    else
        PCT=$(awk "BEGIN {printf \"%.1f\", (($LAST_SIZE-ORIG_SIZE)/$LAST_SIZE)*100}")
    fi
    info "Größenveränderung zum letzten Snapshot: ${PCT}% ($GROWTH Bytes)"

    if (( $(echo "$PCT > $ANOMALY_THRESHOLD_PCT" | bc -l 2>/dev/null || echo "0") )); then
        ANOMALY=true
        ANOMALY_REASONS+=("Größensprung ${PCT}% (Schwelle: ${ANOMALY_THRESHOLD_PCT}%)")
    fi
fi

# --- Dry-Run: nur Analyse, kein Backup ----------------------------------------
if $DRY_RUN; then
    echo ""
    echo "═════════════════════════════════════════════════"
    echo "  DRY-RUN — keine Änderungen"
    echo "═════════════════════════════════════════════════"
    echo ""
    echo "  DB-Pfad:         $DB_SOURCE"
    echo "  Backup-Verz.:    $BACKUP_DIR/"
    echo "  Aktuelle Grösse: $ORIG_SIZE_MB MB"
    if [[ -n "$LAST_SNAPSHOT" ]]; then
        LAST_NAME="$(basename "$LAST_SNAPSHOT")"
        echo "  Letzter Snapshot: $LAST_NAME (${LAST_SIZE_MB} MB)"
    else
        echo "  Letzter Snapshot: keiner"
    fi
    echo "  Ziel-Snapshot:   $(basename "$SNAPSHOT_FILE")"
    echo "  Sandbox-Link:    $SANDBOX_LINK"
    echo "  Max Snapshots:   $MAX_SNAPSHOTS"
    echo "  Anomalie-Schwelle: ${ANOMALY_THRESHOLD_PCT}%"
    echo ""

    # Diff-Analyse (read-only!) auf der Original-DB
    echo "  --- Diff-Analyse (read-only) ---"
    if [[ -n "$LAST_SNAPSHOT" ]] && [[ -f "$LAST_SNAPSHOT" ]]; then
        # Cross-DB-Diff (Dry-Run)
        sqlite3 -readonly "$DB_SOURCE" "
            ATTACH DATABASE '$LAST_SNAPSHOT' AS snap;
            SELECT 'NEU: Computer ' || c.ID || ' (IsPlayer=' || c.IsPlayer || ', IsRouter=' || c.IsRouter || ', IsCTF=' || c.IsCTF || ')'
            FROM Computer c LEFT JOIN snap.Computer s ON c.ID = s.ID WHERE s.ID IS NULL;
            SELECT 'NEU: Bank ' || b.User
            FROM BankAccounts b LEFT JOIN snap.BankAccounts s ON b.User = s.User WHERE s.User IS NULL;
            SELECT 'NEU: Mail ' || m.User
            FROM MailAccounts m LEFT JOIN snap.MailAccounts s ON m.User = s.User WHERE s.User IS NULL;
            SELECT 'NEU: Passwort ' || p.ID
            FROM Passwords p LEFT JOIN snap.Passwords s ON p.ID = s.ID WHERE s.ID IS NULL;
            SELECT 'NEU: Map-IP ' || m.IpAddress
            FROM Map m LEFT JOIN snap.Map s ON m.IpAddress = s.IpAddress WHERE s.IpAddress IS NULL;
            SELECT 'NEU: WebPage ' || wp.PublicIp || ':' || wp.LocalIp
            FROM WebPages wp LEFT JOIN snap.WebPages s ON wp.PublicIp = s.PublicIp AND wp.LocalIp = s.LocalIp WHERE s.PublicIp IS NULL;
            DETACH DATABASE snap;
        " 2>/dev/null || error "Cross-DB-Diff (Dry-Run) fehlgeschlagen."

        # Counts vergleichen
        echo ""
        echo "  Tabellen-Vergleich (Original → Vorgänger):"
        for tbl in Computer Files Map BankAccounts MailAccounts WebPages Passwords Logs InfoGen; do
            src_cnt=$(sqlite3 -readonly "$DB_SOURCE" "SELECT COUNT(*) FROM $tbl;" 2>/dev/null || echo "?")
            snp_cnt=$(sqlite3 -readonly "$LAST_SNAPSHOT" "SELECT COUNT(*) FROM $tbl;" 2>/dev/null || echo "?")
            if [[ "$src_cnt" != "$snp_cnt" ]]; then
                echo "    ⚠️  $tbl: $src_cnt (vorher: $snp_cnt)"
            else
                echo "    ✅ $tbl: $src_cnt (unverändert)"
            fi
        done

    else
        echo "    (kein Vorgänger-Snapshot für Diff vorhanden)"
    fi

    echo ""
    echo "  Anomalie: $($ANOMALY && echo '⚠️  JA' || echo '✅ NEIN')"
    for reason in "${ANOMALY_REASONS[@]}"; do
        echo "    → $reason"
    done
    echo ""
    echo "  Ergebnis: $ORIG_SIZE_MB MB | Snapshot: $(basename "$SNAPSHOT_FILE")"
    echo "═════════════════════════════════════════════════"
    echo ""
    info "Dry-Run beendet. Keine Änderungen vorgenommen."
    exit 0
fi

# --- Snapshot erstellen (sqlite3 .backup = READ-ONLY auf Source) -------------
info "Erstelle Snapshot: $(basename "$SNAPSHOT_FILE")"

# sqlite3 .backup ist der SICHERE Weg — es liest die Source-DB nur und schreibt
# eine atomare, konsistente Kopie. Kein Spiel-Corrupt-Risiko.
sqlite3 -readonly "$DB_SOURCE" ".backup '$SNAPSHOT_FILE'"

if [[ ! -f "$SNAPSHOT_FILE" ]]; then
    error "Snapshot konnte nicht erstellt werden!"
    exit 1
fi

SNAP_SIZE=$(stat --format=%s "$SNAPSHOT_FILE" 2>/dev/null || stat -f%z "$SNAPSHOT_FILE" 2>/dev/null)
SNAP_SIZE_MB=$(awk "BEGIN {printf \"%.2f\", $SNAP_SIZE/1048576}")
success "Snapshot erstellt: $(basename "$SNAPSHOT_FILE") ($SNAP_SIZE_MB MB)"

# --- Sandbox-Symlink aktualisieren -------------------------------------------
ln -sf "$SNAPSHOT_FILE" "$SANDBOX_LINK"
info "Sandbox-Link: $SANDBOX_LINK → $(basename "$SNAPSHOT_FILE")"

# --- Rotation: alte Snapshots löschen (nur die letzten MAX_SNAPSHOTS behalten) -
SNAPSHOTS_COUNT=$(ls -1 "$BACKUP_DIR"/GreyHackDB_*.db 2>/dev/null | wc -l)
if [[ $SNAPSHOTS_COUNT -gt $MAX_SNAPSHOTS ]]; then
    TO_DELETE=$(( SNAPSHOTS_COUNT - MAX_SNAPSHOTS ))
    info "Rotation: Lösche $TO_DELETE alte Snapshots (Limit: $MAX_SNAPSHOTS)"
    ls -t "$BACKUP_DIR"/GreyHackDB_*.db 2>/dev/null | tail -n "$TO_DELETE" | while read -r OLD; do
        rm -f "$OLD"
        info "  Gelöscht: $(basename "$OLD")"
    done
    success "Rotation abgeschlossen. $MAX_SNAPSHOTS Snapshots verbleiben."
fi

# --- Diff-Analyse zwischen Original und letztem Snapshot (vor diesem Lauf) ----
DIFF_REPORT="$TEMP_DIR/diff_report.txt"
: > "$DIFF_REPORT"

if [[ -n "$LAST_SNAPSHOT" ]] && [[ -f "$LAST_SNAPSHOT" ]]; then
    info "Vergleiche mit Vorgänger: $(basename "$LAST_SNAPSHOT")"

    for tbl in Computer Files Map BankAccounts MailAccounts WebPages Passwords Logs; do
        src_cnt=$(sqlite3 -readonly "$DB_SOURCE" "SELECT COUNT(*) FROM $tbl;" 2>/dev/null || echo "?")
        snp_cnt=$(sqlite3 -readonly "$LAST_SNAPSHOT" "SELECT COUNT(*) FROM $tbl;" 2>/dev/null || echo "?")
        if [[ "$src_cnt" != "$snp_cnt" ]]; then
            echo "CHANGE $tbl: $snp_cnt → $src_cnt" >> "$DIFF_REPORT"
        fi
    done

    # Cross-DB-Diff: Vorgänger-Snapshot als 'snap' attach
    sqlite3 -readonly "$DB_SOURCE" "
        ATTACH DATABASE '$LAST_SNAPSHOT' AS snap;
        SELECT 'NEW_COMPUTER: ' || c.ID || ' (IsPlayer=' || c.IsPlayer || ', IsRouter=' || c.IsRouter || ', IsCTF=' || c.IsCTF || ')'
        FROM Computer c LEFT JOIN snap.Computer s ON c.ID = s.ID WHERE s.ID IS NULL;
        SELECT 'NEW_BANK: ' || b.User
        FROM BankAccounts b LEFT JOIN snap.BankAccounts s ON b.User = s.User WHERE s.User IS NULL;
        SELECT 'NEW_MAIL: ' || m.User
        FROM MailAccounts m LEFT JOIN snap.MailAccounts s ON m.User = s.User WHERE s.User IS NULL;
        SELECT 'NEW_PASSWORD: ' || p.ID
        FROM Passwords p LEFT JOIN snap.Passwords s ON p.ID = s.ID WHERE s.ID IS NULL;
        SELECT 'NEW_MAP_IP: ' || m.IpAddress
        FROM Map m LEFT JOIN snap.Map s ON m.IpAddress = s.IpAddress WHERE s.IpAddress IS NULL;
        SELECT 'NEW_WEBPAGE: ' || wp.PublicIp || ':' || wp.LocalIp
        FROM WebPages wp LEFT JOIN snap.WebPages s ON wp.PublicIp = s.PublicIp AND wp.LocalIp = s.LocalIp WHERE s.PublicIp IS NULL;
        DETACH DATABASE snap;
    " >> "$DIFF_REPORT" 2>/dev/null || error "Cross-DB-Diff fehlgeschlagen."

    if [[ -s "$DIFF_REPORT" ]]; then
        DIFF_COUNT=$(wc -l < "$DIFF_REPORT")
        info "$DIFF_COUNT Änderungen festgestellt."
        if $FORCE || $ANOMALY; then
            echo "" >&2
            echo "=== Diff-Report ===" >&2
            cat "$DIFF_REPORT" >&2
            echo "===================" >&2
        fi
    else
        success "Keine Änderungen zum Vorgänger-Snapshot."
    fi
fi

# --- Anomalie erkennen und Alarm auslösen ------------------------------------
# Prüfe auf kritische Änderungen
if [[ -s "$DIFF_REPORT" ]]; then
    if grep -q "NEW_COMPUTER" "$DIFF_REPORT" && grep -q "IsPlayer=1" "$DIFF_REPORT"; then
        ANOMALY=true
        ANOMALY_REASONS+=("Neuer Spieler-Computer entdeckt!")
    fi
    if grep -q "NEW_BANK" "$DIFF_REPORT"; then
        ANOMALY=true
        ANOMALY_REASONS+=("Neue BankAccounts entdeckt!")
    fi
    if grep -q "NEW_COMPUTER.*IsCTF=1" "$DIFF_REPORT"; then
        ANOMALY=true
        ANOMALY_REASONS+=("Neue CTF-Computer entdeckt!")
    fi
fi

# --- Ausgabe: nur bei Anomalie oder --force ----------------------------------
if $ANOMALY || $FORCE; then
    echo ""
    echo "═════════════════════════════════════════════════"
    echo "  GREYHACK DB SNAPSHOT — REPORT"
    echo "═════════════════════════════════════════════════"
    echo ""
    echo "  Snapshot:  $(basename "$SNAPSHOT_FILE")"
    echo "  Datum:     $(date '+%Y-%m-%d %H:%M:%S')"
    echo "  Grösse:    $ORIG_SIZE_MB MB (Source) / $SNAP_SIZE_MB MB (Snapshot)"
    echo "  Wachstum:  ${PCT}% ($(numfmt --to=iec $GROWTH 2>/dev/null || echo "$GROWTH Bytes"))"
    echo ""

    if $ANOMALY; then
        echo "  ⚠️  ANOMALIE ERKANNT:"
        for reason in "${ANOMALY_REASONS[@]}"; do
            echo "    → $reason"
        done
        echo ""
    fi

    if [[ -s "$DIFF_REPORT" ]]; then
        echo "  Änderungen seit letztem Snapshot:"
        cat "$DIFF_REPORT" | sed 's/^/    /'
        echo ""
    fi

    echo "  Snapshots gesamt: $((SNAPSHOTS_COUNT < MAX_SNAPSHOTS ? SNAPSHOTS_COUNT + 1 : MAX_SNAPSHOTS))"
    echo "  Nächste Rotation: $((SNAPSHOTS_COUNT >= MAX_SNAPSHOTS ? 'jetzt' : "in $((MAX_SNAPSHOTS - SNAPSHOTS_COUNT)) Snapshots"))"
    echo "═════════════════════════════════════════════════"
    echo ""
fi

# --- Größen-Tracking-Log -----------------------------------------------------
SIZE_LOG="$BACKUP_DIR/size-history.csv"
if [[ ! -f "$SIZE_LOG" ]]; then
    echo "timestamp,source_bytes,snapshot_file,snapshot_bytes,diff_bytes,growth_pct,anomaly" > "$SIZE_LOG"
fi
echo "${TIMESTAMP},${ORIG_SIZE},$(basename "$SNAPSHOT_FILE"),${SNAP_SIZE},$(( SNAP_SIZE - LAST_SIZE )),${PCT},${ANOMALY}" >> "$SIZE_LOG"
info "Grössen-Log aktualisiert: $SIZE_LOG"

if ! $ANOMALY && ! $FORCE; then
    # Watchdog: silent on success
    info "OK — Keine Anomalien. Silent exit."
fi

exit $($ANOMALY && echo 1 || echo 0)
