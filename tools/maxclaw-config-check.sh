#!/usr/bin/env bash
# =============================================================================
# maxclaw-config-check.sh — MaxClaw OpenClaw-Config Validator
# -----------------------------------------------------------------------------
# Prüft die zentralen Sicherheits-Invarianten der OpenClaw-Config-Trias:
#   openclaw.json        (Runtime)         — browser deny, exec allowlist, gateway localhost
#   exec-approvals.json  (Command-Policy)  — Killer-Patterns in deny
#   greyhack.yaml        (Domänen-Daten)   — use_flag=false, network_isolation=true
#
# Wenn die OpenClaw-CLI vorhanden ist, wird zusätzlich `openclaw config validate`
# aufgerufen (Schema-Prüfung gegen die installierte Version).
#
# Usage:
#   maxclaw-config-check.sh                       # prüft config/openclaw.json (rel. zum Repo)
#   maxclaw-config-check.sh /pfad/openclaw.json   # benutzerdefinierte Datei
#
# Exit-Codes:  0 = alle Checks bestanden · 1 = kritischer Fehler · 2 = Warnung
# =============================================================================

set -uo pipefail

# --- Pfade auflösen -------------------------------------------------------
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
OPENCLAW_JSON="${1:-$REPO_DIR/config/openclaw.json}"
CFG_DIR="$(dirname "$OPENCLAW_JSON")"
EXEC_APPROVALS="$CFG_DIR/exec-approvals.json"
GREYHACK_YAML="$CFG_DIR/greyhack.yaml"

bold()   { printf '\033[1m%s\033[0m\n' "$*"; }
bold ""; bold "=== MaxClaw OpenClaw-Config Validator ==="
echo "  Runtime:  $OPENCLAW_JSON"
echo "  Exec:     $EXEC_APPROVALS"
echo "  GreyHack: $GREYHACK_YAML"

if [ ! -f "$OPENCLAW_JSON" ]; then
    printf '\033[31m  [FATAL] openclaw.json nicht gefunden: %s\033[0m\n' "$OPENCLAW_JSON"
    exit 1
fi

# --- Optional: native OpenClaw-Schema-Validierung -------------------------
if command -v openclaw >/dev/null 2>&1; then
    echo "  openclaw-CLI gefunden → openclaw config validate"
    openclaw config validate "$OPENCLAW_JSON" || \
        printf '\033[33m  [!] openclaw config validate meldete Probleme (siehe oben)\033[0m\n'
else
    echo "  openclaw-CLI nicht installiert → nur lokale Invarianten-Checks"
fi

# --- Invarianten in Python (JSON5-tolerant) -------------------------------
python3 - "$OPENCLAW_JSON" "$EXEC_APPROVALS" "$GREYHACK_YAML" <<'PYEOF'
import re, json, sys

oc_path, ex_path, gh_path = sys.argv[1], sys.argv[2], sys.argv[3]
ERRORS = 0; WARNINGS = 0
G="\033[32m"; R="\033[31m"; Y="\033[33m"; B="\033[1m"; N="\033[0m"
def ok(m):   print(f"  {G}[✓]{N} {m}")
def err(m):
    global ERRORS; ERRORS += 1; print(f"  {R}[✗]{N} {m}")
def warn(m):
    global WARNINGS; WARNINGS += 1; print(f"  {Y}[!]{N} {m}")
def head(m): print(f"\n{B}--- {m} ---{N}")

def strip_json5(t):
    out=[]; i=0; n=len(t); instr=False; q=''
    while i<n:
        c=t[i]
        if instr:
            out.append(c)
            if c=='\\' and i+1<n: out.append(t[i+1]); i+=2; continue
            if c==q: instr=False
            i+=1; continue
        if c in '"\'': instr=True; q=c; out.append(c); i+=1; continue
        if c=='/' and i+1<n and t[i+1]=='/':
            while i<n and t[i]!='\n': i+=1
            continue
        if c=='/' and i+1<n and t[i+1]=='*':
            i+=2
            while i+1<n and not(t[i]=='*' and t[i+1]=='/'): i+=1
            i+=2; continue
        out.append(c); i+=1
    s=''.join(out)
    s=re.sub(r',(\s*[}\]])', r'\1', s)
    s=re.sub(r'([{,]\s*)([A-Za-z_$][\w$]*)(\s*):', r'\1"\2"\3:', s)
    return s

def load_json5(path):
    with open(path) as f: return json.loads(strip_json5(f.read()))

def get(d, path, default=None):
    for p in path.split('.'):
        if isinstance(d, dict) and p in d: d = d[p]
        else: return default
    return d

# ================= openclaw.json =================
head("openclaw.json — Runtime-Invarianten")
try:
    oc = load_json5(oc_path)
except Exception as e:
    err(f"openclaw.json parst nicht: {e}"); print(); sys.exit(1)

deny = get(oc, "tools.deny", []) or []
ok("browser in tools.deny (Prompt-Injection-Schutz)") if "browser" in deny else \
    err("browser NICHT in tools.deny — Prompt-Injection-Risiko!")

mode = get(oc, "tools.exec.mode")
ok(f"tools.exec.mode = {mode}") if mode == "allowlist" else \
    err(f"tools.exec.mode = {mode!r} (ERWARTET: allowlist)")

af = get(oc, "tools.exec.askFallback")
ok(f"tools.exec.askFallback = {af}") if af == "deny" else \
    err(f"tools.exec.askFallback = {af!r} (ERWARTET: deny)")

bind = get(oc, "gateway.bind")
ok("gateway.bind = 127.0.0.1 (nur localhost)") if bind == "127.0.0.1" else \
    err(f"gateway.bind = {bind!r} (ERWARTET: 127.0.0.1 — nie 0.0.0.0!)")

hb = get(oc, "agents.defaults.heartbeat.every")
ok(f"heartbeat.every = {hb}") if hb else warn("agents.defaults.heartbeat.every nicht gesetzt")

# Keine Klartext-Secrets: env-Werte müssen ${...}-Refs sein
env = get(oc, "env", {}) or {}
leaks = [k for k, v in env.items() if isinstance(v, str) and not re.fullmatch(r"\$\{[^}]+\}", v.strip())]
ok("keine Klartext-Secrets im env-Block (nur ${..}-Refs)") if not leaks else \
    err(f"mögliche Klartext-Secrets in env: {leaks}")

# toolsBySender: Default-Deny für group:runtime
tbs_default = get(oc, "tools.toolsBySender.*", {})
dd = (tbs_default or {}).get("deny", [])
ok("toolsBySender['*'] verweigert group:runtime (Default-Deny)") if "group:runtime" in dd else \
    warn("toolsBySender['*'] verweigert group:runtime nicht — Injection-Fläche prüfen")

# ================= exec-approvals.json =================
head("exec-approvals.json — Command-Policy")
try:
    ex = load_json5(ex_path)
    exdeny = ex.get("deny", [])
    for pat in ["rm -rf*", "sudo*", "greybel build -u*"]:
        ok(f"deny enthält '{pat}'") if pat in exdeny else err(f"deny fehlt '{pat}'")
    ok("git-push-main in deny") if any("push" in p and "main" in p for p in exdeny) else \
        err("kein 'git push* main*' in deny — Bastis Regel verletzt!")
    ok("greybel build in allow") if any(p.startswith("greybel build") for p in ex.get("allow", [])) else \
        err("greybel build fehlt in allow")
except FileNotFoundError:
    err(f"exec-approvals.json fehlt: {ex_path}")
except Exception as e:
    err(f"exec-approvals.json parst nicht: {e}")

# ================= greyhack.yaml =================
head("greyhack.yaml — Domänen-Invarianten")
try:
    raw = open(gh_path).read()
    use_flag_false = re.search(r'use_flag:\s*false', raw)
    ok("greyhack.build.use_flag = false (kein -u)") if use_flag_false else \
        err("greyhack.build.use_flag != false — Inline-if-Bug-Risiko!")
    net_iso = re.search(r'network_isolation:\s*true', raw)
    ok("greyhack.sandbox.network_isolation = true") if net_iso else \
        err("network_isolation != true — Sandbox-Ausbruch-Risiko!")
    ok("forbidden_targets definiert") if 'forbidden_targets:' in raw else \
        warn("forbidden_targets nicht gesetzt")
except FileNotFoundError:
    warn(f"greyhack.yaml nicht gefunden ({gh_path}) — GreyHack-Track evtl. inaktiv")

# ================= Zusammenfassung =================
head("Zusammenfassung")
print(f"  Errors: {ERRORS}   Warnings: {WARNINGS}")
if ERRORS:
    print(f"\n{R}FAIL: {ERRORS} kritische Fehler — Config ist NICHT sicher!{N}")
    sys.exit(1)
if WARNINGS:
    print(f"\n{Y}PASS (mit Warnungen): {WARNINGS} Warnungen — bitte prüfen{N}")
    sys.exit(2)
print(f"\n{G}OK: Alle Checks bestanden.{N}")
sys.exit(0)
PYEOF
