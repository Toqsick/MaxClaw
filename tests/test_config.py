"""
Config-Validierungs-Tests fuer die OpenClaw-Config-Trias.

Prueft, dass die kanonische Runtime-Config (openclaw.json), die Command-Policy
(exec-approvals.json) und die GreyHack-Domaenendaten (greyhack.yaml) parsen und
die zentralen Sicherheits-Invarianten einhalten. Bewusst ohne externe
Abhaengigkeiten (nur stdlib json/re) — passend zum minimalen CI-Setup.
"""

import json
import re
from pathlib import Path

CONFIG_DIR = Path(__file__).resolve().parent.parent / "config"


def _strip_json5(text):
    """Entfernt // + /* */ Kommentare, Trailing-Commas und quotet unquoted Keys."""
    out = []
    i = 0
    n = len(text)
    in_str = False
    quote = ""
    while i < n:
        c = text[i]
        if in_str:
            out.append(c)
            if c == "\\" and i + 1 < n:
                out.append(text[i + 1])
                i += 2
                continue
            if c == quote:
                in_str = False
            i += 1
            continue
        if c in "\"'":
            in_str = True
            quote = c
            out.append(c)
            i += 1
            continue
        if c == "/" and i + 1 < n and text[i + 1] == "/":
            while i < n and text[i] != "\n":
                i += 1
            continue
        if c == "/" and i + 1 < n and text[i + 1] == "*":
            i += 2
            while i + 1 < n and not (text[i] == "*" and text[i + 1] == "/"):
                i += 1
            i += 2
            continue
        out.append(c)
        i += 1
    s = "".join(out)
    s = re.sub(r",(\s*[}\]])", r"\1", s)
    s = re.sub(r"([{,]\s*)([A-Za-z_$][\w$]*)(\s*):", r'\1"\2"\3:', s)
    return s


def _load_json5(name):
    return json.loads(_strip_json5((CONFIG_DIR / name).read_text(encoding="utf-8")))


def _get(d, dotted, default=None):
    for part in dotted.split("."):
        if isinstance(d, dict) and part in d:
            d = d[part]
        else:
            return default
    return d


# --- openclaw.json -----------------------------------------------------------

def test_openclaw_json_parses():
    cfg = _load_json5("openclaw.json")
    assert isinstance(cfg, dict)
    assert "agents" in cfg and "tools" in cfg and "gateway" in cfg


def test_exec_mode_is_allowlist_with_deny_fallback():
    cfg = _load_json5("openclaw.json")
    assert _get(cfg, "tools.exec.mode") == "allowlist"
    assert _get(cfg, "tools.exec.askFallback") == "deny"


def test_browser_is_denied():
    cfg = _load_json5("openclaw.json")
    assert "browser" in (_get(cfg, "tools.deny", []) or [])


def test_gateway_binds_loopback_only():
    cfg = _load_json5("openclaw.json")
    assert _get(cfg, "gateway.bind") == "127.0.0.1"


def test_env_has_no_plaintext_secrets():
    cfg = _load_json5("openclaw.json")
    env = _get(cfg, "env", {}) or {}
    for key, val in env.items():
        assert re.fullmatch(r"\$\{[^}]+\}", str(val).strip()), \
            "env['%s'] darf nur ${..}-Referenz sein, kein Klartext" % key


def test_default_sender_denies_runtime_tools():
    cfg = _load_json5("openclaw.json")
    star = _get(cfg, "tools.toolsBySender.*", {}) or {}
    assert "group:runtime" in star.get("deny", [])


# --- exec-approvals.json -----------------------------------------------------

def test_exec_approvals_parses():
    ex = _load_json5("exec-approvals.json")
    assert "allow" in ex and "deny" in ex


def test_exec_approvals_denies_killer_patterns():
    ex = _load_json5("exec-approvals.json")
    deny = ex["deny"]
    for pattern in ("rm -rf*", "sudo*", "greybel build -u*"):
        assert pattern in deny, "deny fehlt: %s" % pattern
    assert any("push" in p and "main" in p for p in deny), "git-push-main fehlt in deny"


def test_exec_approvals_allows_greybel_build():
    ex = _load_json5("exec-approvals.json")
    assert any(p.startswith("greybel build") for p in ex["allow"])


# --- greyhack.yaml (regex-basiert, kein pyyaml noetig) -----------------------

def test_greyhack_domain_invariants():
    raw = (CONFIG_DIR / "greyhack.yaml").read_text(encoding="utf-8")
    assert re.search(r"use_flag:\s*false", raw), "greyhack.build.use_flag muss false sein"
    assert re.search(r"network_isolation:\s*true", raw), "sandbox.network_isolation muss true sein"
    assert "forbidden_targets:" in raw
