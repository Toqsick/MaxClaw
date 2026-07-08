---
name: vanilla-js-tdz-helper-first
title: Vanilla JS — Helper-First Pattern (TDZ vermeiden)
description: Definiere $() / setText() / escapeHtml() immer als ALLERERSTES im script-Tag, vor state, vor funktionen die sie
  nutzen. Sonst crashed die Init wegen Temporal Dead Zone und connect()/connectBtn-Click laufen nie.
triggers:
- Working with vanilla HTML/JS dashboards (no bundler, no module system)
- SSE/WebSocket Frontend mit EventSource
- Dashboard reload crasht mit "Cannot access X before initialization"
- SetActiveTab / init function crashed silently
- Debugging 0 Verbundene or Verbindung fehlgeschlagen in a real-time dashboard
version: 1.0.0
author: Hermes Agent
lane: worker-heavy
reasoning_effort: xhigh
---
# Vanilla JS — Helper-First Pattern

## Warum

In Vanilla JS (ohne Bundler, ohne ESM) sind `const`/`let` **nicht** gehoisted wie `var`. Sie leben in der **Temporal Dead Zone (TDZ)** bis zu ihrer Definition. Wenn eine Funktion während der Page-Init eine `const` benutzt, die später im Script definiert wird → `ReferenceError`, Script bricht ab, Event-Handler werden nie gebunden.

**Realer Vorfall 2026-06-30:** Hermes SSE Dashboard — `setActiveTab()` rief `$()` auf, bevor `const $ = ...` definiert war. `connect()` lief nie, Dashboard zeigte permanent roten Dot, obwohl Server grün war.

## Pattern

```html
<script>
// 1. HILFSFUNKTIONEN ZUERST (vor state, vor allem anderen)
const $ = (id) => document.getElementById(id);
const setText = (id, text) => { $(id).textContent = text; };
const escapeHtml = (s) => String(s).replace(/[&<>"']/g, c => ({'&':'&amp;','<':'&lt;','>':'&gt;','"':'&quot;',"'":'&#39;'}[c]));

// 2. State (nutzt die Helper nicht direkt, ist safe)
const state = { events: [], conn: null };

// 3. Funktionen die Helper nutzen
function setActiveTab(name) {
  const filterLabel = $('activeFilterLabel');  // ← safe, $ ist definiert
  // ...
}

// 4. Init-Code
setActiveTab('live');  // ← safe
</script>
```

## Anti-Pattern (was crashed)

```html
<script>
const state = { activeTab: 'live' };

function setActiveTab(name) {
  const el = $('filterLabel');  // ← TDZ-ReferenceError wenn vor $ definiert
}

setActiveTab(state.activeTab);  // ← CRASH: Cannot access '$' before initialization

const $ = (id) => document.getElementById(id);  // ← zu spät
</script>
```

## Diagnose

Console-Error:
```
Uncaught ReferenceError: Cannot access '$' before initialization
    at setActiveTab (file.html:1205:27)
    at file.html:1228:5
```

→ Helper ans Script-Anfang verschieben.

## Erweitertes Pattern: API-Wrapper + Token-Helper

Wenn dein Dashboard gegen ein auth-required Backend spricht, definiere **zusätzlich** einen zentralen `apiFetch()`-Wrapper ganz oben. Sonst passiert Bug 9 (siehe dev-tools): SSE connected (query-token fallback), aber `fetch('/api/status')` ohne Header → 401 → KPIs leer.

```html
<script>
// 1. HILFSFUNKTIONEN + AUTH-HELPER ZUERST
const $ = (id) => document.getElementById(id);
const setText = (id, text) => { $(id).textContent = text; };

const DEFAULT_AUTH_TOKEN = 'super-secret';
let currentAuthToken = DEFAULT_AUTH_TOKEN;
function apiFetch(path, opts = {}) {
  const userHeaders = opts.headers || {};
  const headers = {
    ...userHeaders,
    'X-Hermes-Token': userHeaders['X-Hermes-Token'] || currentAuthToken,
  };
  return fetch(path, { ...opts, headers });
}

// 2. State
const state = { events: [], conn: null };

// 3. Funktionen die Helper nutzen — IMMER apiFetch() statt fetch('/api/')
async function fetchStatus() {
  const r = await apiFetch('/api/status');  // ← nicht fetch('/api/status')!
  // ...
}
</script>
```

**Rule:** wenn du im Code `fetch('/api/')` siehst, ersetze es durch `apiFetch('/api/')`. Für 14+ Call-Sites geht das in einem `sed -i`/`patch replace_all`-Sweep.

**Detection nach Multi-Section-Patches:** nach jeder Serie von `patch`-Calls, die den `<script>`-Block berührt, Sanity-Check:
- `grep -n "^\s*const \$" dashboard.html` → genau 1 Match ganz oben, nicht 2 (verwaister alter + neuer).
- `grep -c "fetch('/api" dashboard.html` → 0, alles durch `apiFetch` ersetzt.
- Im Browser: `console.log` direkt nach `const $ = ...` ausführen, um TDZ auszuschließen.

## Wann triggern

- Vanilla-JS-Frontends ohne Bundler (single HTML files mit inline `<script>`)
- Multi-File-Setups ohne ESM-Modules
- Quick-Mockups / DevTools-Snippets
- Legacy-Code-Refactorings

## Alternative (wenn Helper-First zu invasiv)

IIFE-Wrapper mit Funktions-Scope:
```javascript
(() => {
  const $ = (id) => document.getElementById(id);
  // ... alles andere
})();
```
Pro: saubererer Scope. Contra: schwerer zu debuggen, kein globaler Zugriff.

## Verwandte Docs

- `~/docs/system/hermes-sse-5-layer-debug-2026-06-30.md` — Layer 5
- Skill: `sse-frontend-patterns` — umfassender Pattern-Set für SSE-Dashboards (EventSource, apiFetch, Exponential-Backoff, 429-Cooldown, Audit-UI)

## Diagnose-Hierarchie für "Dashboard connected nicht"

Wenn du in einem Vanilla-JS+SSE-Dashboard Probleme debugst, prüfe in dieser Reihenfolge (jeder Layer schließt die meisten einfachen Fälle aus):

1. **Server-Health** (`curl /health`) — läuft der Server überhaupt?
2. **CORS** — antwortet der Server mit `Access-Control-Allow-Origin` für deinen Origin?
3. **Auth-Gate** — blockt die Middleware statische HTML-Files? Sollte bypass-Pfade haben für `/dashboard/`.
4. **EventSource-Header** — Browser kann keine custom Header. Token MUSS in URL.
5. **TDZ (dieser Skill)** — `console.log` direkt nach `const $ = ...`. ReferenceError beim Init?
6. **apiFetch-Wrapper** — alle `/api/`-Calls müssen durch den Token-Wrapper, sonst 401.
7. **429-Spirale** — flacher SSE-Reconnect + Rate-Limit = Endlos-Loop. Exponential-Backoff.

Die ersten 4 sind Server-Side-Issues, 5–6 sind typische Vanilla-JS-Front-End-Bugs, 7 ist die häufigste Edge-Case im Betrieb.

