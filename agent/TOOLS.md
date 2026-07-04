# TOOLS.md — Notizbuch über die Tools im Setup (v3.0)

> Kein Doku-Ersatz, sondern praktische „Klebezettel am Monitor". Trag hier Workarounds ein,
> damit MaxClaw denselben Fehler nicht zweimal macht.

## Messaging

- **Telegram:** primärer Channel für Rückfragen. Chat-ID `7222661188` (Basti). Bot `@OlympAgentBot`.
  Ziel-String für send_message: `telegram:7222661188`.

## Git / GitHub

- **gh CLI** ist als `Toqsick` eingeloggt (Scopes: repo, workflow, read:org, gist).
- `main` niemals ohne Freigabe pushen — `develop`/`feature`-Branches ok.
- GreyHack-Tool-PRs immer auf `develop` oder Feature-Branch (`feature/greyhack-<tool>`).

## GreyHack-Build-Pipeline (dokumentiert aus 28 yuno-tools-Scripts)

### Architektur

```
~/greyhack-tools/
├── *.src                  → Lokale Quellen (GreyScript)
├── greyhack-sandbox/      → Test-Sandbox (sandbox_clone-Operation erlaubt)
├── build/                 → greybel build Output
└── mission-logs/          → Strike-Ergebnisse

/mnt/DATA/.../Grey Hack/yuno-tools/  → Im Spiel gemounteter Tool-Ordner
```

### Build-Aufruf

```bash
# RICHTIG: ohne -u, voller Pfad
greybel build ~/greyhack-tools/<tool>.src -o ~/greyhack-tools/build/<tool>.xml

# FALSCH: -u ist broken (Inline-if + Einzeiler-if Bug)
greybel build -u ~/greyhack-tools/<tool>.src   # ❌ NIEMALS
```

### Pflicht-Header (jedes `.src`)

```greybel
//command: <tool_name>          ← erste Zeile Pflicht, sonst kein Run
// === HEADER (Kommentar) ===
// Beschreibung, Nutzung, Parameter
```

### GreyScript-Syntax-Regeln (aus yuno-tools Pain-Points extrahiert)

| Pattern | Status | Hinweis |
|---------|--------|---------|
| `if bedingung then` … `end if` (mehrzeilig) | ✅ funktioniert | Standard-Pattern |
| Verschachteltes `if/end if` statt `else if` | ✅ funktioniert | greybel-Workaround |
| `if bedingung then BODY end if` (Einzeiler) | ❌ bricht ohne `-u` | IMMER ausschreiben |
| Inline-if `x = if cond then a else b` | ❌ bricht ohne `-u` | Mehrzeilig schreiben |
| `else if` | ⚠️ riskant | lieber verschachteln |
| `char(10)` für Newline | ✅ Pflicht | kein `\n` |
| `0` als truthy | ⚠️ Falle | explizit `== 0` testen |
| `str_repeat` | ❌ existiert nicht | `while`-Loop stattdessen |
| Negative Indizes | ❌ nicht unterstützt | `len-1`-Trick |
| `is_binary` (nicht `is_folder`) | ✅ merken | für Binary-Check |
| HTTP-Requests | ❌ GreyScript hat kein HTTP | nur via `lib/net.so` |
| `notify()` / `error()` Builtins | ❌ existieren nicht | nur `print()` |

### Wichtige Builtins (Häufigkeit aus 28 Scripts)

`host_computer` (222×) · `get_shell` (105×) · `ports` (86×) · `get_content` (79×) ·
`is_folder` (69×) · `metaxploit` (65×) · `include_lib` (64×) · `net` (62×) ·
`crypto` (61×) · `cat` (55×) · `bank` (54×) · `users` (46×) · `net_use` (46×) ·
`ssh` (43×) · `get_files` (42×)

### Wiederverwendbare Utilities (Funktionen die in mehreren Scripts vorkommen)

GreyScript hat **keine `function`-Definitionen** (Pattern: `grep "function\|sub" = 0`). Stattdessen
werden folgende Code-Idiome immer wieder kopiert — bei neuen Scripts übernehmen:

1. **Lib-Loader-Pattern** (dee_hack, mission_v3, multihop_strike):
   ```greybel
   metax = include_lib("/lib/metaxploit.so")
   if metax == null then
       print("[!] metaxploit.so fehlt!" + char(10))
       exit
   end if
   ```

2. **Null-Check mit `typeof()`** (dee_hack, deep_recon):
   ```greybel
   shell = get_shell.connect_service(ip, 22, "root", "pass")
   if typeof(shell) == "string" then
       print("[!] " + shell + char(10))
       exit
   end if
   ```

3. **Port-Scan-Loop** (multihop_strike, mission_final):
   ```greybel
   ports = [22, 80, 8080, 21, 443, 3306, 8443]
   while port_idx < ports.len
       test_session = metax.net_use(DEE_IP, ports[port_idx])
       if test_session != null then
           print("[+] Port offen!" + char(10))
       end if
       port_idx = port_idx + 1
   end while
   ```

4. **Home-Config-Looter** (strike1, multihop_strike, mission_v4):
   ```greybel
   home_list = shell.ls("/home")
   while user_count < home_list.len
       user = home_list[user_count]
       if user != "." and user != ".." then
           bank = shell.cat("/home/" + user + "/Config/Bank.txt")
           mail = shell.cat("/home/" + user + "/Config/Mail.txt")
       end if
       user_count = user_count + 1
   end while
   ```

5. **Param-Parser** (bruteforce, bank_grab):
   ```greybel
   if params.len > 0 then
       i = 0
       while i < params.len
           if params[i] == "--length" and i + 1 < params.len then
               length = val(params[i + 1])
               i = i + 1
           end if
           i = i + 1
       end while
   end if
   ```

## Modell-Routing (siehe config/config.yaml)

- Heartbeat/Routine → billiges Modell.
- Alltag → günstig-aber-gut.
- Coding/komplex → starkes Modell.
- Subagenten (Recherche) → billiges Modell.
- **NEU v3.0:** greybel build validation + neue GreyScript-Generierung → **heavy**.

## Sandbox-Tools (Python, ~/projects/greyhack-sandbox/)

- `greyhack-sandbox.py` — DB + greybel-Wrapper
- `npc_intel.py` — NPC-Schwachstellenscanner
- `auto_pwn.py` — Exploit-Generator
- Datei-Server (lokal) — `python3 -m http.server 8765` für `pc.wget` im Spiel

## Workarounds-Log

- (leer — hier neue Tool-Quirks eintragen, sobald sie auftauchen)
- **2026-07-04:** `greybel build -u` ist broken → immer ohne `-u`. Inline-if & Einzeiler-if
  durch mehrzeilige `if/else/end if`-Blöcke ersetzen.
- **2026-07-04:** `else if` durch verschachteltes `if/end if` ersetzen (greybel-Workaround).