---
name: hermes-cli-quirks
description: "Hermes CLI Pitfalls + Workarounds für Agent-Writing (Cron create/mod, Provider-Drift #44585,
  cronjob action=update vs hermes cron edit, hermes-Live-config-protection, gh CLI Token-Scopes).
  Get hard-won Fixes statt Stolperfallen. v3.0."
version: 1.0.0
author: Yuno (MaxClaw-Betreiberin via Owl Alpha)
license: MIT
triggers:
  - "hermes cron"
  - "hermes cron create"
  - "hermes cron edit"
  - "cronjob action"
  - "provider drift"
  - "#44585"
  - "config.yaml protected"
  - "gh createPullRequest"
  - "Pitfall #10"
  - "Hermes-CLI"
---

# Hermes CLI — Quirks & Workarounds

Hard-won Erfahrungen aus dem MaxClaw v3.0 Upgrade (2026-07-04). Lade diesen Skill **bevor**
du Cron-Jobs anlegst oder Hermes-Config editierst — spart 5-10 Min Trial-Error.

## When to use

- Du willst Cron-Jobs anlegen, updaten oder löschen
- Du arbeitest mit `hermes config` und willst nicht versehentlich die Live-Config zerschießen
- Du bekommst Error `Skill "provider drift" or #44585`
- Du willst PRs via gh CLI anlegen und es schlägt fehl
- Du brauchst eine **Liste der bekannten Hermes-CLI-Edge-Cases**

## Pitfall-Tabelle (was geht NICHT wie erwartet)

### Pitfall #1: `hermes cron create --model` existiert NICHT

**Symptom:** `hermes cron create "0 */2 * * *" "prompt" --model heavy --name X ...`
→ `hermes: error: unrecognized arguments: --model heavy`

**Fix:**
1. Cron **ohne** `--model` anlegen (hermes wählt default)
2. **Danach** mit `cronjob action=update job_id=XXX provider=yyy model=zzz` pinnen

```bash
hermes cron create "0 */2 * * *" "mein prompt" \
    --name "my-job" --deliver "telegram:7222661188" \
    --workdir "/path/to/repo"

# Job-ID aus Output extrahieren (12-hex-digit), dann pin:
# cronjob action=update job_id=<hex> model="minimax-m3" provider="ollama-cloud"
```

### Pitfall #2: `hermes cron edit` hat auch kein `--model/--provider`

**Symptom:** `hermes cron edit <job-id> --model heavy ...` → unrecognized arguments

**Fix:** Genau wie #1 — `cronjob action=update` für Modell-Pin.

### Pitfall #3: Provider-Drift Error #44585

**Symptom:** Jeder Cron-Lauf gibt:
```
RuntimeError: Skipped to prevent unintended spend: global inference config drifted
since this job was created (provider 'X' -> 'Y'; model 'A' -> 'B'), and this job is unpinned.
```

**Ursache:** Globale Inference-Config wechselt (z.B. `provider: nous` → `minimax`), aber jeder
Cron hat seinen **alten** Provider-Pin. Cron weigert sich zu laufen, um ungewollte Spends zu
verhindern.

**Fix:** Pin alle Crons auf die **aktuelle** Default-Provider/Modell-Kombination:

```bash
# 1. Aktuellen Provider/Model aus hermes config.yaml holen
grep -E "model|provider" ~/.hermes/config.yaml | head

# 2. Für alle LLM-Crons:
for jid in $(hermes cron list 2>/dev/null | awk '/^  [a-f0-9]{12}/{job=$1} /Last run:/{for(i=1;i<=NF;i++) if($i=="error") print job}'); do
  echo "Pinning $jid..."
  # cronjob action=update job_id=$jid model="<model>" provider="<provider>"
done
```

**Prävention:** Nach jedem globalen Provider-Wechsel direkt alle Crons re-pinnen.

### Pitfall #4: `~/.hermes/config.yaml` ist Agent-write-protected

**Symptom:** Versuch `patch`-mode auf `~/.hermes/config.yaml` →
```
Refusing to write to Hermes config file: /home/bratan/.hermes/config.yaml
Agent cannot modify security-sensitive configuration. Edit ~/.hermes/config.yaml
directly or use 'hermes config' instead.
```

**Ursache:** Hermes built-in Schutz. Der Agent darf Live-Settings nicht versehentlich
zerschießen.

**Fix:** Eine von drei Optionen:
1. **User-Action:** `hermes config set key value` oder direkter Edit durch Basti
2. **Workaround:** Settings in `config/config.yaml` dokumentieren + User-Aktion dokumentieren
   (z.B. siehe `security-remediation-2026-07-04.md`)
3. **In eigene Config:** MaxClaw hat eine eigene `config/config.yaml` (Vorlage unter `config.example`)
   — die darf der Agent editieren

### Pitfall #5: `hermes cron list` zeigt nach Pin oft noch alten Provider

**Symptom:** Du hast gerade `cronjob action=update job_id=XXX provider=ollama-cloud model=minimax-m3`
gemacht, `hermes cron list` zeigt aber **trotzdem** `provider: zai`.

**Fix:** Kein echtes Problem — der Provider wird visuell noch falsch dargestellt, aber die
**echte execution** läuft mit dem neuen Modell. Verifiziere via `cronjob action=run job_id=XXX`:

```bash
# Status sollte 'ok' sein mit dem neuen Provider/Model
hermes cron list 2>&1 | grep -A 8 "$job_id"
```

### Pitfall #6: gh CLI kann PRs nur mit speziellen Token-Scopes anlegen

**Symptom:**
- `gh pr create` → `GraphQL: Resource not accessible by personal access token (createPullRequest)`
- `gh api repos/X/Y/pulls` POST → `401 Bad credentials`

**Ursache:** gh CLI Keyring-Token (default) hat oft nur `gist, read:org, repo, workflow` Scopes,
aber PR-Erstellung braucht zusätzlich `write:packages` oder `admin:repo_hook`.

**Fix:** Push via `git push origin <branch>`, dann User-Action PR im Browser:
```
https://github.com/<owner>/<repo>/compare/main...<branch>
```

## Pattern (lauffähig)

### Komplett-Workflow "Cron sicher registrieren"

```bash
# 1. register-workflows.sh (kann mehrfach laufen, idempotent)
./workflows/register-workflows.sh --dry-run    # Vorschau
./workflows/register-workflows.sh              # alle
./workflows/register-workflows.sh --add <NAME> # nur einer
./workflows/register-workflows.sh --list       # 8 Workflows anzeigen

# 2. Provider-Drift erkennen + fixen (Script-Anti-Pattern)
JIDS=$(hermes cron list 2>/dev/null | awk '/^  [a-f0-9]{12}/{job=$1} /Last run:/{for(i=1;i<=NF;i++) if($i=="error") print job}')
echo "$JIDS" | while read jid; do
  echo "Pin $jid..."
  # manuell pro Cron: cronjob action=update job_id=$jid ...
done

# 3. Alle Crons smoke-test
ALL_JIDS=$(hermes cron list 2>/dev/null | awk '/^  [a-f0-9]{12}/{job=$1} END{print job}')
for jid in $ALL_JIDS; do
  # cronjob action=run job_id=$jid
  sleep 2  # nicht alle gleichzeitig (Rate-Limits)
done
```

### Provider-Drift-Detection (read-only)

```bash
hermes cron list 2>&1 | grep -B5 "Skipped to prevent" | grep -E "(provider.*->.*model|job_id)" \
  | head -20
# → Liste der Crons, die gepinnt werden müssen
```

## Pitfalls (was schiefgehen kann)

- ❌ Cron-Pin ohne `provider=` — Modell wird nicht gesetzt, Error #44585 bleibt
- ❌ Alle Crons gleichzeitig via `xargs` triggern → Rate-Limits von LLM-Provider
- ❌ `hermes cron edit --workdir /tmp/Pfad` der nicht existiert → scheitert silent
- ❌ `gh pr create` mit `main` als Quelle ohne Force → fataler Conflict
- ✅ **Immer zuerst** mit `cronjob action=run job_id=XXX` testen, ob Pin sitzt
- ✅ **register-workflows.sh --dry-run** vor jedem `register-workflows.sh` (Default-Deny-Mentalität)
- ✅ **Kompletter Push via `git push`** wenn PR-Erstellung via Tool blockiert → User öffnet Browser-PR

## Siehe auch

- Hermes-Agent Skill (Hauptreferenz): `hermes-agent`
- MaxClaw-Audit-Report mit allen P0/P1-Findings: `docs/reports/security-audit-2026-07-04.md`
- Multi-Agent-Pitfall-Checkliste (Pitfall #10 gleich wie oben): `~/.hermes/skills/orchestration/pitfalls/SKILL.md`
- Workflow-Templates: `workflows/greyhack-*.md`
