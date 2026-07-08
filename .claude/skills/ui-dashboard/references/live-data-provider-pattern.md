# Live-Data-Provider Pattern for Dashboards

> Session-Reference from Yuno-Dashboard Live-Build (2026-07-01, updated v3)

## Problem

Dashboard-HTML läuft als static file, aber braucht **echte Live-Daten** von Hermes/System.
Direkter `/api/*`-Zugriff ist blockiert (HTTP 401 ohne Auth-Token).

## Lösung: Python Data-Provider + fetch-Polling

### Architektur

```
Browser (live.html)
  ├── fetch() alle 3s → localhost:8767/api/data
  │                          ↑
  │                    server.py (Python HTTPServer)
  │                     ├── urllib → /api/status (no-auth, einziger offener Endpoint)
  │                     ├── subprocess → hermes CLI (skills, profiles, cron)
  │                     ├── psutil → CPU/RAM/Disk/Temp
  │                     └── pathlib → Memory/Session/Cron File-Scans
```

### Hermes API-Surface (evaluiert 2026-07-01)

| Endpoint | Ohne Auth | Mit Bearer Token | Quelle |
|----------|-----------|-----------------|--------|
| `/api/status` | **200 ✓** | 200 | Version, Gateway, Platforms, Sessions |
| `/api/skills` | 401 | 401 (Token aus .env funktioniert nicht) | — |
| `/api/sessions` | 401 | 401 | — |
| `/api/crons` | 401 | 401 | — |
| `/api/profiles` | 401 | 401 | — |
| `/api/health` | 401 | 401 | — |

**Workaround:** `hermes` CLI via `subprocess` nutzen statt API:
```python
result = subprocess.run(
    [f"{HERMES_HOME}/hermes-agent/venv/bin/hermes", "skills", "list"],
    capture_output=True, text=True, timeout=10,
    env={**os.environ, "HERMES_HOME": str(HERMES_HOME)}
)
skill_count = result.stdout.count("enabled")
```

### Caching-Strategie

NICHT bei jedem HTTP-Request alle CLI-Befehle neu ausführen (das dauert 2-5s):

```python
_cache = {}
_cache_ts = {}
CACHE_TTL = 30  # Sekunden

def cached(key, fn, ttl=CACHE_TTL):
    now = time.time()
    if key in _cache and (now - _cache_ts.get(key, 0)) < ttl:
        return _cache[key]
    val = fn()
    _cache[key] = val
    _cache_ts[key] = now
    return val
```

**TTL-Empfehlungen:**
- Skills count: 60s (ändert sich selten)
- Profiles: 60s
- System-Stats (psutil): 0s (immer frisch)
- Hermes-API-Status: 0s (frisch für Gateway-State)
- Session/Cron count: 120s

### Client-Side Polling (3s Refresh — Basti's Präferenz)

```javascript
const DATA_URL = 'http://127.0.0.1:8767/api/data';
const REFRESH_MS = 3000; // 3 Sekunden!

async function fetchData() {
    try {
        const res = await fetch(DATA_URL, { cache: 'no-store' });
        if (!res.ok) throw new Error(`HTTP ${res.status}`);
        const data = await res.json();
        render(data);
        document.getElementById('error-banner').classList.remove('show');
    } catch (err) {
        document.getElementById('error-banner').classList.add('show');
    }
}

fetchData();
setInterval(fetchData, REFRESH_MS);
```

### Progress-Indicators

**Auto-Refresh Bar** (oben fixiert, füllt sich über ~3s):
```css
.refresh-bar { position: fixed; top: 0; left: 0; height: 2px; background: linear-gradient(90deg, var(--purple), var(--pink)); width: 0; z-index: 9999; transition: width 150ms ease; }
.refresh-bar.active { width: 100%; transition: width 2.8s linear; }
```

```javascript
// Bei jedem fetch: Bar resetten und neu starten
const bar = document.getElementById('refresh-bar');
bar.classList.remove('active');
void bar.offsetWidth; // Reflow-Reset (CRITICAL — ohne das läuft die CSS-Animation nicht neu)
bar.classList.add('active');
```

### Color-Coded Dynamic Bars

```javascript
function colorBar(barId, pct, warn=70, crit=90) {
    const bar = document.getElementById(barId);
    bar.className = 'progress-fill ' + (pct >= crit ? 'error' : pct >= warn ? 'warning' : '');
}
// Grün = ok, Gelb = >70%, Rot = >90%
```

### Start-Skript Pattern

```bash
#!/usr/bin/env bash
# start.sh — startet Data-Provider + HTML-Server + öffnet Browser
python3 server.py > .server-data.log 2>&1 &
python3 -m http.server 8768 --bind 127.0.0.1 > .server-html.log 2>&1 &
xdg-open "http://127.0.0.1:8768/live.html"
```

## Validation

Smoke-Test für Data-Provider:
```bash
# 1. Server erreichbar?
curl -s http://127.0.0.1:8767/health  # → "ok"

# 2. JSON valid?
curl -s http://127.0.0.1:8767/api/data | python3 -c "import sys,json; d=json.load(sys.stdin); print(list(d.keys()))"

# 3. Key fields prüfen
curl -s http://127.0.0.1:8767/api/data | python3 -c "
import sys, json
d = json.load(sys.stdin)
assert d['hermes']['version'], 'version missing'
assert d['system']['memory']['percent'] > 0, 'RAM missing'
assert d['skills']['enabled'] > 0, 'skills missing'
print('✓ All fields present')
"
```

## Dependencies

- `psutil` — `pip install psutil` (System-Stats: CPU, RAM, Disk, Temperaturen)
- Python 3.11+ (stdlib `http.server`, `json`, `subprocess`, `pathlib`)
- Hermes CLI erreichbar unter `~/.hermes/hermes-agent/venv/bin/hermes`
- Hermes Dashboard läuft auf Port 9119 (für `/api/status`)

## Common Issues

| Issue | Fix |
|-------|-----|
| `psutil not found` | `pip install psutil --user` |
| CORS-Error im Browser | `Access-Control-Allow-Origin: *` im Response-Header setzen |
| Server startet nicht (Port belegt) | Alte PID-File löschen, `kill` alte Prozesse |
| `/api/status` nicht erreichbar | Hermes Dashboard läuft nicht: `hermes dashboard --port 9119` |
| CLI-Aufrufe zu langsam | TTL-Hochsetzen (60s statt 30s), caching verbessern |
| `pkill -f "server.py"` signal -15 | Normales SIGTERM, Python HTTPServer fängt das sauber auf. Wenn nicht: `process(action='kill', session_id=...)` nutzen |
| Refresh-Bar läuft nicht neu | `void bar.offsetWidth;` Reflow-Reset zwischen remove+add class ist CRITICAL |

## v3 Lessons (2026-07-01)

1. **3s-Refresh** ist Basti's Präferenz für System-Monitoring — nicht 10s. Die Progress-Bar zeigt dem User "es lebt" ohne zu flackern.
2. **Accordion-Cards** (klickbar, aufklappbar) sind der beste Kompromiss zwischen Übersicht und Detailtiefe — nicht alles auf einmal zeigen.
3. **KPI-as-Buttons** (kleine Cards oben klickbar → öffnen Detail-Card unten mit smooth scroll) ist intuitiver als verschachtelte Menüs.
4. **Mini-Tiles** in aufgeklappten Cards (große Zahlen als Zusammenfassung) geben schnellen Überblick ohne Tabelle lesen zu müssen.
5. **psutil** ist die zuverlässigste Quelle für System-Stats (CPU%, RAM%, Disk%, CPU-Temp, Load-Average) — kein Shell-Parsing nötig.
