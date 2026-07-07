#!/usr/bin/env bash
# =============================================================================
# maxclaw-security-audit.sh
# =============================================================================
# Täglicher READ-ONLY Security-Audit für MaxClaw auf Bastis Host.
# Inspiriert von GreyHacks hardening_audit.src, adaptiert auf Linux.
#
# GreyHack-Mapping:
#   PHASE 0  Backup-Admin   →  check_secretref_backup
#   PHASE 1  User-Audit      →  check_user_context
#   PHASE 2  Port-Audit      →  check_gateway_bind, check_open_ports
#   PHASE 3  Firewall        →  check_egress_allowlist (best-effort)
#   PHASE 4  Permission-Check →  check_write_paths, check_secret_perms,
#                                check_world_writable, check_config_perms
#   PHASE 5  Trace-Monitoring → check_cron, check_git_status, check_running_procs
#
# Output: JSON-Report → ~/logs/maxclaw-security-audit-LAST.json
# Alte Reports: ~/logs/maxclaw-security-audit-YYYYMMDD-HHMM.json (rolling 30)
#
# Bei P0: Telegram-Alert an Basti (falls OpenClaw-Gateway erreichbar).
# Bei P1: nur im Log + Daily-Digest-Hook (nicht inline).
# Bei P2: nur im Log.
#
# Wichtig: NUR LESEN, NIE SCHREIBEN (außer Log-Output). Fixes nur nach Bastis
# expliziter Freigabe — siehe security/policies.md.
# =============================================================================

set -uo pipefail   # pipefail aus, damit grep "no match" nicht crasht

# -----------------------------------------------------------------------------
# Konstanten
# -----------------------------------------------------------------------------
readonly SCRIPT_NAME="maxclaw-security-audit"
readonly VERSION="1.0.0"
readonly TIMESTAMP="$(date -u +%Y-%m-%dT%H:%M:%SZ)"
readonly DATE_STAMP="$(date +%Y%m%d-%H%M)"
readonly HOME_DIR="${HOME:-/home/bratan}"
readonly LOG_DIR="${HOME_DIR}/logs"
readonly REPORT_LAST="${LOG_DIR}/${SCRIPT_NAME}-LAST.json"
readonly REPORT_HIST="${LOG_DIR}/${SCRIPT_NAME}-${DATE_STAMP}.json"
readonly MAXCLAW_REPO="${MAXCLAW_REPO:-/tmp/maxclaw-clone}"
readonly AUDIT_CONFIG="${MAXCLAW_REPO}/security/hardening_audit_maxclaw.yaml"
readonly OPENCLAW_CFG="${HOME_DIR}/.openclaw/openclaw.json"   # OpenClaw-Runtime-Config
readonly TG_CHAT="7222661188"

# Farben (falls interaktiv)
if [[ -t 1 ]]; then
    readonly RED=$'\033[0;31m'; readonly YELLOW=$'\033[1;33m'
    readonly GREEN=$'\033[0;32m'; readonly NC=$'\033[0m'
else
    readonly RED=''; readonly YELLOW=''; readonly GREEN=''; readonly NC=''
fi

# Findings-Array (JSON-Items werden hier gesammelt)
FINDINGS_JSON=""
SEVERITY_COUNTS='{"P0":0,"P1":0,"P2":0,"OK":0}'
OVERALL_SCORE=100   # wird mit jedem P0/P1/P2 abgezogen

# -----------------------------------------------------------------------------
# Helpers
# -----------------------------------------------------------------------------
log()    { echo -e "${GREEN}[*]${NC} $*" >&2; }
warn()   { echo -e "${YELLOW}[!]${NC} $*" >&2; }
err()    { echo -e "${RED}[X]${NC} $*" >&2; }

# Severity ablegen
add_finding() {
    local id="$1" severity="$2" title="$3" detail="$4" remediation="${5:-}"
    local points=0
    case "$severity" in
        P0) points=25 ;;
        P1) points=10 ;;
        P2) points=3 ;;
        OK) points=0 ;;
    esac
    OVERALL_SCORE=$((OVERALL_SCORE - points))
    (( OVERALL_SCORE < 0 )) && OVERALL_SCORE=0

    # Count inkrementieren
    SEVERITY_COUNTS=$(echo "$SEVERITY_COUNTS" | python3 -c "
import json,sys
d=json.load(sys.stdin)
d['$severity']=d.get('$severity',0)+1
print(json.dumps(d))
")

    # Finding als JSONL-Zeile in Temp-Datei anhängen (vermeidet Shell-Escaping)
    local tmp_findings="/tmp/.audit-findings-$$.jsonl"
    # Datei nur einmal pro Run initial leer anlegen
    [[ ! -f "$tmp_findings" ]] && : > "$tmp_findings"
    python3 - "$tmp_findings" "$id" "$severity" "$title" "$detail" "$remediation" <<'PY'
import json, sys
path, fid, sev, title, detail, rem = sys.argv[1:]
rec = {"id": fid, "severity": sev, "title": title,
       "detail": detail, "remediation": rem}
with open(path, "a", encoding="utf-8") as f:
    f.write(json.dumps(rec, ensure_ascii=False) + "\n")
PY
    FINDINGS_FILE="$tmp_findings"

    # Konsolen-Output
    case "$severity" in
        P0) err "[$severity] $id: $title — $detail" ;;
        P1) warn "[$severity] $id: $title — $detail" ;;
        P2) warn "[$severity] $id: $title — $detail" ;;
        OK) log "[OK]  $id: $title" ;;
    esac
}

close_findings_json() { :; }   # legacy stub — Findings liegen in Datei

# -----------------------------------------------------------------------------
# PHASE 0 — Backup / SecretRef
# -----------------------------------------------------------------------------
check_phase0_backup() {
    log "PHASE 0 — Backup / SecretRef"

    if [[ -d "${HOME_DIR}/.openclaw/out" ]]; then
        add_finding "P0.backup.secretref_exists" "OK" \
            "SecretRef-Verzeichnis vorhanden" \
            "${HOME_DIR}/.openclaw/out existiert."
    else
        add_finding "P0.backup.secretref_exists" "P0" \
            "SecretRef-Verzeichnis fehlt" \
            "${HOME_DIR}/.openclaw/out existiert nicht." \
            "OpenClaw-Workspace initialisieren."
    fi

    # Backup-Aktualität
    local latest_backup
    latest_backup=$(find "${HOME_DIR}/.openclaw" -name 'openclaw.json.bak.*' -printf '%T@\n' 2>/dev/null | sort -n | tail -1)
    if [[ -n "$latest_backup" ]]; then
        local now latest_days_old
        now=$(date +%s)
        latest_days_old=$(( (now - ${latest_backup%.*}) / 86400 ))
        if (( latest_days_old <= 14 )); then
            add_finding "P0.backup.recent" "OK" \
                "Letzte Config-Sicherung ${latest_days_old} Tage alt" \
                "Innerhalb des 14-Tage-Schwellwerts."
        else
            add_finding "P0.backup.recent" "P1" \
                "Letzte Config-Sicherung ${latest_days_old} Tage alt" \
                "Älter als 14 Tage." \
                "Snapshot der openclaw.json anlegen."
        fi
    else
        add_finding "P0.backup.recent" "P2" \
            "Keine openclaw.json.bak gefunden" \
            "Backup-Strategie fehlt möglicherweise." \
            "Pre-Commit-Hook für Snapshots einrichten."
    fi
}

# -----------------------------------------------------------------------------
# PHASE 1 — User-Audit
# -----------------------------------------------------------------------------
check_phase1_user() {
    log "PHASE 1 — User-Audit"

    # uid != root?
    if [[ "${UID:-$(id -u)}" == "0" ]]; then
        add_finding "P1.user.not_root" "P0" \
            "Agent läuft als root (uid=0)" \
            "UID=$UID" \
            "MaxClaw als User bratan ausführen."
    else
        add_finding "P1.user.not_root" "OK" \
            "Agent läuft nicht als root" \
            "UID=${UID:-$(id -u)}."
    fi

    # ~/bin-Ownership
    if [[ -d "${HOME_DIR}/bin" ]]; then
        local owner
        owner=$(stat -c '%U:%G' "${HOME_DIR}/bin")
        if [[ "$owner" == "bratan:bratan" ]]; then
            add_finding "P1.user.bin_owner" "OK" \
                "~/bin-Ownership korrekt" \
                "$owner"
        else
            add_finding "P1.user.bin_owner" "P1" \
                "~/bin-Ownership falsch" \
                "owner=$owner (erwartet bratan:bratan)" \
                "chown -R bratan:bratan ~/bin/"
        fi
    fi
}

# -----------------------------------------------------------------------------
# PHASE 2 — Ports
# -----------------------------------------------------------------------------
check_phase2_ports() {
    log "PHASE 2 — Port-Audit"

    if ! command -v ss >/dev/null 2>&1; then
        add_finding "P2.tool.ss" "P2" \
            "ss nicht verfügbar" \
            "Port-Audit eingeschränkt." \
            "iproute2 installieren."
        return
    fi

    # MaxClaw-Gateway
    local gw_line
    gw_line=$(ss -ltn 2>/dev/null | awk '$4 ~ /:18789$/')
    if [[ -z "$gw_line" ]]; then
        add_finding "P2.port.gateway" "OK" \
            "Gateway-Port 18789 nicht aktiv" \
            "Kein Listener — entweder gestoppt oder normal."
    elif echo "$gw_line" | grep -q '0\.0\.0\.0:18789'; then
        add_finding "P2.port.gateway" "P0" \
            "Gateway-Port 18789 auf 0.0.0.0 gebunden!" \
            "Weltweit erreichbar. KRITISCH." \
            "Sofort OpenClaw-Gateway stoppen, dann gateway.bind = 127.0.0.1."
    elif echo "$gw_line" | grep -q '127\.0\.0\.1:18789'; then
        add_finding "P2.port.gateway" "OK" \
            "Gateway-Port 18789 nur auf loopback" \
            "Korrekt konfiguriert."
    else
        add_finding "P2.port.gateway" "P1" \
            "Gateway-Port 18789 auf unerwartetem Interface" \
            "$gw_line" \
            "Bind-Adresse auf 127.0.0.1 festlegen."
    fi

    # world-listening
    local world_listeners
    world_listeners=$(ss -ltn 2>/dev/null | awk '$4 ~ /^0\.0\.0\.0:/')
    if [[ -z "$world_listeners" ]]; then
        add_finding "P2.port.world_listeners" "OK" \
            "Keine 0.0.0.0-Listener" \
            "Sauber."
    else
        local n
        n=$(echo "$world_listeners" | wc -l)
        add_finding "P2.port.world_listeners" "P2" \
            "${n} Listener auf 0.0.0.0" \
            "$(echo "$world_listeners" | head -3 | tr '\n' ';')" \
            "Liste prüfen — sshd (22) ist normal, andere bewerten."
    fi
}

# -----------------------------------------------------------------------------
# PHASE 3 — Egress / Firewall (best-effort)
# -----------------------------------------------------------------------------
check_phase3_egress() {
    log "PHASE 3 — Egress / Firewall"

    if command -v ufw >/dev/null 2>&1; then
        local ufw_status
        ufw_status=$(ufw status 2>/dev/null | head -1)
        if echo "$ufw_status" | grep -q "Status: active"; then
            add_finding "P3.fw.ufw_active" "OK" \
                "ufw aktiv" \
                "$ufw_status"
        else
            add_finding "P3.fw.ufw_active" "P2" \
                "ufw nicht aktiv" \
                "$ufw_status" \
                "sudo ufw enable (nach Allowlist-Definition)."
        fi
    else
        add_finding "P3.fw.ufw_active" "P2" \
            "ufw nicht installiert" \
            "Egress-Isolation nur per iptables/nftables möglich." \
            "ufw installieren oder nftables-Regeln dokumentieren."
    fi

    # DNS-Test
    if getent hosts api.telegram.org >/dev/null 2>&1; then
        add_finding "P3.dns.resolution" "OK" \
            "DNS funktioniert (api.telegram.org auflösbar)" \
            "Allowlist-Host erreichbar."
    else
        add_finding "P3.dns.resolution" "P2" \
            "DNS-Problem" \
            "api.telegram.org nicht auflösbar." \
            "Resolver prüfen (systemd-resolved / DoH)."
    fi
}

# -----------------------------------------------------------------------------
# PHASE 4 — Permissions
# -----------------------------------------------------------------------------
check_phase4_perms() {
    log "PHASE 4 — Permission-Check"

    # OpenClaw-Runtime-Config finden (Host bevorzugt, sonst Repo-Vorlage)
    local found_config=""
    for cf in "${OPENCLAW_CFG}" "${MAXCLAW_REPO}/config/openclaw.json"; do
        if [[ -f "$cf" ]]; then found_config="$cf"; break; fi
    done

    # Exec-Policy finden (Command-Allowlist/Denylist)
    local exec_policy=""
    for ef in "${HOME_DIR}/.openclaw/exec-approvals.json" "${MAXCLAW_REPO}/config/exec-approvals.json"; do
        if [[ -f "$ef" ]]; then exec_policy="$ef"; break; fi
    done

    if [[ -n "$found_config" ]]; then
        # Default-Deny via Exec-Allowlist-Modus?
        if grep -qE 'mode:\s*"?allowlist"?' "$found_config" 2>/dev/null; then
            add_finding "P4.exec.allowlist" "OK" \
                "tools.exec.mode = allowlist (Default-Deny)" \
                "Konfig: $found_config"
        else
            add_finding "P4.exec.allowlist" "P1" \
                "tools.exec.mode nicht 'allowlist'" \
                "Default-Deny für Kommandos nicht spezifiziert." \
                "tools.exec.mode: allowlist + askFallback: deny setzen."
        fi

        # browser deaktiviert (Prompt-Injection)?
        if grep -qE '"?browser"?' "$found_config" 2>/dev/null && grep -qE 'deny:\s*\[[^]]*browser' "$found_config" 2>/dev/null; then
            add_finding "P4.browser.deny" "OK" \
                "browser in tools.deny" \
                "Prompt-Injection-Vektor geschlossen."
        else
            add_finding "P4.browser.deny" "P1" \
                "browser nicht sicher in tools.deny" \
                "Prompt-Injection-Risiko." \
                "tools.deny um 'browser' erweitern."
        fi

        # config-Welt-Lesbarkeit? (nur für Host-Config sinnvoll)
        if [[ "$found_config" == "${OPENCLAW_CFG}" ]]; then
            local perm
            perm=$(stat -c '%a' "$found_config" 2>/dev/null)
            if [[ "$perm" == "600" || "$perm" == "400" ]]; then
                add_finding "P4.config.perm" "OK" \
                    "openclaw.json restriktiv (${perm})" \
                    "Nur Eigentümer."
            else
                add_finding "P4.config.perm" "P1" \
                    "openclaw.json zu lesbar (${perm})" \
                    "Andere User können Config einsehen." \
                    "chmod 600 $found_config"
            fi
        fi
    else
        add_finding "P4.config.found" "P1" \
            "Keine aktive openclaw.json gefunden" \
            "Weder ~/.openclaw/openclaw.json noch Repo-Vorlage." \
            "Pfad prüfen oder MAXCLAW_REPO setzen."
    fi

    # git-push-main + sudo in Exec-Denylist?
    if [[ -n "$exec_policy" ]]; then
        if grep -qE 'git push.*main' "$exec_policy" 2>/dev/null; then
            add_finding "P4.git.main_push_denied" "OK" \
                "git push auf main in exec-approvals.json deny" \
                "Default-Deny-Regel aktiv."
        else
            add_finding "P4.git.main_push_denied" "P1" \
                "git push auf main nicht in deny" \
                "Risiko: versehentlicher main-Push nicht abgefangen." \
                "exec-approvals.json deny um 'git push* main*' erweitern."
        fi
        if grep -qE '"sudo\*"' "$exec_policy" 2>/dev/null; then
            add_finding "P4.sudo.deny" "OK" \
                "sudo in exec-approvals.json deny" \
                "Rechte-Eskalation unterbunden."
        else
            add_finding "P4.sudo.deny" "P1" \
                "sudo nicht explizit verboten" \
                "Bash-Wildcard erlaubt versehentlich sudo-Aufrufe." \
                "exec-approvals.json deny um 'sudo*' erweitern."
        fi
    else
        add_finding "P4.exec.found" "P1" \
            "Keine exec-approvals.json gefunden" \
            "Command-Policy nicht prüfbar." \
            "config/exec-approvals.json nach ~/.openclaw/ deployen."
    fi

    # World-writable in Workspaces
    local ww
    ww=$(find "${HOME_DIR}/greyhack-tools" "${HOME_DIR}/.openclaw" \
            -type f -perm -o+w 2>/dev/null | head -5)
    if [[ -z "$ww" ]]; then
        add_finding "P4.fs.world_writable" "OK" \
            "Keine world-writable Dateien in Workspaces" \
            "Sauber."
    else
        add_finding "P4.fs.world_writable" "P0" \
            "World-writable Dateien gefunden!" \
            "$(echo "$ww" | head -3 | tr '\n' ';')" \
            "chmod o-w <files> — sonst kann jeder User sie überschreiben."
    fi

    # SSH dir perms
    if [[ -d "${HOME_DIR}/.ssh" ]]; then
        local ssh_perm
        ssh_perm=$(stat -c '%a' "${HOME_DIR}/.ssh")
        if [[ "$ssh_perm" == "700" ]]; then
            add_finding "P4.ssh.dir_perm" "OK" \
                "~/.ssh ist 700" \
                "Korrekt."
        else
            add_finding "P4.ssh.dir_perm" "P1" \
                "~/.ssh ist ${ssh_perm} (sollte 700)" \
                "ssh-keygen warnt." \
                "chmod 700 ~/.ssh"
        fi
    fi
}

# -----------------------------------------------------------------------------
# PHASE 5 — Cron / Git / Processes
# -----------------------------------------------------------------------------
check_phase5_traces() {
    log "PHASE 5 — Trace-Monitoring"

    # Cron als root?
    if [[ -f /etc/crontab ]]; then
        if grep -qE '^[^#].*bratan|^[^#].*root' /etc/crontab 2>/dev/null; then
            # root-Cron = NICHT user
            local root_jobs
            root_jobs=$(grep -vE '^\s*(#|$)' /etc/crontab 2>/dev/null | head -3)
            if [[ -n "$root_jobs" ]]; then
                add_finding "P5.cron.root" "P1" \
                    "Einträge in /etc/crontab gefunden" \
                    "$(echo "$root_jobs" | head -2 | tr '\n' ';')" \
                    "User-Cron statt System-Cron verwenden."
            fi
        fi
    fi

    # User-Crontab vorhanden?
    local cron_content
    cron_content=$(crontab -l 2>/dev/null)
    if [[ -n "$cron_content" ]]; then
        # systemd-user bevorzugt; crontab ist okay, wenn keine sudo-Zeile
        if echo "$cron_content" | grep -qE '\bsudo\b'; then
            add_finding "P5.cron.sudo" "P0" \
                "sudo in User-Crontab gefunden!" \
                "Privilege-Escalation-Pfad." \
                "Job umstellen, damit er ohne sudo läuft."
        else
            local n_jobs
            n_jobs=$(echo "$cron_content" | grep -cE '^[^#]')
            add_finding "P5.cron.user_jobs" "OK" \
                "${n_jobs} User-Cron-Einträge (kein sudo)" \
                "Sauber."
        fi
    else
        add_finding "P5.cron.user_jobs" "OK" \
            "Kein User-Crontab" \
            "Cron läuft via systemd-user oder gar nicht."
    fi

    # Git-Branch im Repo
    if [[ -d "${MAXCLAW_REPO}/.git" ]]; then
        local branch
        branch=$(git -C "${MAXCLAW_REPO}" branch --show-current 2>/dev/null)
        if [[ "$branch" == "main" ]]; then
            add_finding "P5.git.branch" "OK" \
                "Repo-Branch: main (read-only erwartet)" \
                "Agent arbeitet nicht aktiv auf main."
        else
            add_finding "P5.git.branch" "P2" \
                "Repo-Branch: ${branch}" \
                "Aktive Arbeit auf Branch — sicherstellen, dass kein Push auf main erfolgt."
        fi

        # Uncommitted changes?
        local dirty
        dirty=$(git -C "${MAXCLAW_REPO}" status --porcelain 2>/dev/null | wc -l)
        if (( dirty > 0 )); then
            add_finding "P5.git.uncommitted" "P2" \
                "${dirty} uncommitted Änderungen" \
                "Audit-Report selbst könnte uncommitted sein." \
                "git add + commit nach Review."
        fi
    fi

    # Laufen OpenClaw/MaxClaw-Prozesse?
    local procs
    procs=$(ps -eo pid,etime,user,comm 2>/dev/null | grep -E 'openclaw' | grep -v grep | head -5)
    if [[ -n "$procs" ]]; then
        add_finding "P5.proc.running" "OK" \
            "Bekannte Agent-Prozesse aktiv" \
            "$(echo "$procs" | wc -l) Prozesse."
    fi
}

# -----------------------------------------------------------------------------
# Modell-Limits prüfen (GreyHack: Heartbeat = billig)
# -----------------------------------------------------------------------------
check_model_limits() {
    log "MODELLE — Limits & Routing"

    local config="${OPENCLAW_CFG}"
    [[ ! -f "$config" ]] && config="${MAXCLAW_REPO}/config/openclaw.json"
    [[ ! -f "$config" ]] && {
        add_finding "M.config.missing" "P2" \
            "Keine openclaw.json für Modell-Check gefunden" \
            "Modell-Routing nicht prüfbar." \
            "Pfad setzen."
        return
    }

    # Subagenten/Heartbeat billig? (Schwarm = flash/mini/nano/haiku)
    if grep -qE '(flash|mini|nano|haiku)' "$config" 2>/dev/null; then
        add_finding "M.swarm.cheap" "OK" \
            "Günstiges Schwarm-/Heartbeat-Modell im Routing (flash/mini/…)" \
            "Watchdog-/Subagent-Kosten niedrig."
    else
        add_finding "M.swarm.cheap" "P1" \
            "Kein günstiges Modell im Routing gefunden" \
            "Heartbeat/Subagenten evtl. auf teurem Modell → Kostenfalle." \
            "recon/subagents auf gemini-2.5-flash o.ä. setzen."
    fi

    # Kostenbremse: cacheRetention/contextPruning deklariert?
    if grep -qE 'cacheRetention|contextPruning' "$config" 2>/dev/null; then
        add_finding "M.cost.controls" "OK" \
            "cacheRetention/contextPruning deklariert" \
            "Prompt-Caching-Kostenkontrolle aktiv."
    else
        add_finding "M.cost.controls" "P1" \
            "Keine Caching-/Pruning-Kostenkontrolle" \
            "Cache-Writes/Kontext laufen ungebremst." \
            "params.cacheRetention + contextPruning in agents.defaults setzen."
    fi
}

# -----------------------------------------------------------------------------
# Telegram-Alert für P0
# -----------------------------------------------------------------------------
maybe_send_telegram() {
    local p0_count
    p0_count=$(echo "$SEVERITY_COUNTS" | python3 -c "import json,sys; print(json.load(sys.stdin).get('P0',0))")
    if (( p0_count == 0 )); then
        return
    fi
    if [[ ! -f "${HOME_DIR}/.openclaw/out/telegram.key" ]]; then
        warn "P0-Befunde, aber kein Telegram-Token → nur Log"
        return
    fi

    # Bewusst NICHT automatisch senden — der Audit-Skript ist read-only by policy.
    # Stattdessen: Hook für OpenClaw/Telegram-Notifier hinterlassen.
    warn "P0-Befunde: ${p0_count} — siehe ${REPORT_LAST}"
    warn "(Auto-Telegram würde Policy verletzen; Hook in OpenClaw manuell triggern.)"
}

# -----------------------------------------------------------------------------
# JSON-Report schreiben
# -----------------------------------------------------------------------------
write_report() {
    close_findings_json
    mkdir -p "${LOG_DIR}"

    local findings_path="${FINDINGS_FILE:-}"
    [[ -z "$findings_path" || ! -f "$findings_path" ]] && findings_path="/tmp/.audit-findings-empty.jsonl"

    FINDINGS_FILE_PATH="$findings_path" \
    OVERALL_SCORE_VAL="$OVERALL_SCORE" \
    SEVERITY_COUNTS_JSON="$SEVERITY_COUNTS" \
    REPORT_LAST_PATH="$REPORT_LAST" \
    REPORT_HIST_PATH="$REPORT_HIST" \
    python3 - <<'PY'
import json, os, sys
findings = []
path = os.environ.get("FINDINGS_FILE_PATH", "")
if os.path.exists(path):
    with open(path, encoding="utf-8") as f:
        for line in f:
            line = line.strip()
            if line:
                findings.append(json.loads(line))
    try: os.unlink(path)
    except OSError: pass

report = {
    "script": os.environ.get("SCRIPT_NAME", "maxclaw-security-audit"),
    "version": os.environ.get("VERSION", "1.0.0"),
    "timestamp": os.environ.get("TIMESTAMP", ""),
    "host": os.uname().nodename,
    "user": os.environ.get("USER", "unknown"),
    "overall_score": int(os.environ.get("OVERALL_SCORE_VAL", "0")),
    "severity_counts": json.loads(os.environ.get("SEVERITY_COUNTS_JSON", "{}")),
    "findings": findings,
}
out_last = os.environ["REPORT_LAST_PATH"]
out_hist = os.environ["REPORT_HIST_PATH"]
tmp = out_last + ".tmp"
with open(tmp, "w", encoding="utf-8") as f:
    json.dump(report, f, ensure_ascii=False, indent=2)
os.replace(tmp, out_last)
with open(out_hist, "w", encoding="utf-8") as f:
    json.dump(report, f, ensure_ascii=False, indent=2)
PY

    # Alte Reports aufräumen (rolling 30, ohne LAST)
    ls -1t "${LOG_DIR}/${SCRIPT_NAME}-"*.json 2>/dev/null \
        | grep -v "${SCRIPT_NAME}-LAST.json" \
        | tail -n +31 \
        | xargs -r rm -f

    log "Report: ${REPORT_LAST}"
}

# -----------------------------------------------------------------------------
# Main
# -----------------------------------------------------------------------------
main() {
    log "===== ${SCRIPT_NAME} v${VERSION} ====="
    log "Host: $(uname -n) | User: $(id -un) | TS: ${TIMESTAMP}"
    log "Repo: ${MAXCLAW_REPO}"
    log "Config: ${AUDIT_CONFIG}"

    check_phase0_backup
    check_phase1_user
    check_phase2_ports
    check_phase3_egress
    check_phase4_perms
    check_phase5_traces
    check_model_limits

    write_report
    maybe_send_telegram

    echo ""
    log "===== Zusammenfassung ====="
    echo "  Score: ${OVERALL_SCORE}/100"
    echo "  Counts: ${SEVERITY_COUNTS}"
    echo ""
    log "Fertig. Details: ${REPORT_LAST}"
    log "Bei P0: Basti fragen, NICHT automatisch fixen."
}

main "$@"