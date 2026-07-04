# MaxClaw Allround Skill-Set — Installation

Dieses Dokument beschreibt, wie die **9 Skills** (8 Allround + 1 Hermes-Quirks) in MaxClaws
Hermes-Workspace installiert und in `setup.sh` integriert werden.

## Übersicht

| # | Skill                | Kategorie             | Zweck                                       |
|---|----------------------|-----------------------|---------------------------------------------|
| A | sandbox-snapshot     | filesystem / ops      | Rotierende Verzeichnis-Snapshots            |
| B | sqlite-reader        | data / read-only      | Sichere SQLite-Analyse                      |
| C | greyscript-linter    | code / static-analysis| GreyScript-Validation vor greybel build    |
| D | github-ops           | collaboration         | gh-CLI-Patterns (PR, Issue, Triage)         |
| E | bash-script-builder  | code / template       | Robuste Bash-Boilerplate-Generierung        |
| F | telegram-notifier    | comms / watchdog      | Bot-API-Wrapper mit silent-on-success       |
| G | knowledge-distiller  | meta / reflection     | Wochenrückblick aus Logs/Docs               |
| H | maxclaw-session-manager | workflow / tracking | JSONL-Session-Log + Repeat-Detection        |
| **I** | **hermes-cli-quirks** | **ops / meta**     | **Hermes-CLI Pitfalls (#44585, model-pin, config-protected, gh-token)** |

## Voraussetzungen

- Linux oder macOS (Windows geht für die meisten Skripte, aber `rsync`/`fcntl`
  sind Linux/macOS-nativ).
- `bash ≥ 4`, `python3 ≥ 3.9`, `sqlite3` (CLI), `curl`, `rsync`, `gh` (für
  github-ops), `shellcheck` (optional für bash-builder-Lint).
- Hermes-Workspace: `~/.hermes/skills/` (oder `~/.openclaw/skills/`).

## Installations-Schritte

### 1. Repo klonen / aktualisieren

```bash
cd /tmp/maxclaw-clone   # oder dein lokaler Pfad
git pull                 # aktuelle Skills holen
```

### 2. Skills nach `~/.hermes/skills/` kopieren

```bash
# Symlinks (Empfehlung — Updates im Repo sofort verfügbar):
for s in sandbox-snapshot sqlite-reader greyscript-linter github-ops \
         bash-script-builder telegram-notifier knowledge-distiller \
         maxclaw-session-manager hermes-cli-quirks; do
  ln -sf "$(pwd)/skills/$s" "$HOME/.hermes/skills/$s"
done

# ODER harte Kopie (kein Live-Update):
for s in sandbox-snapshot sqlite-reader greyscript-linter github-ops \
         bash-script-builder telegram-notifier knowledge-distiller \
         maxclaw-session-manager hermes-cli-quirks; do
  cp -r "skills/$s" "$HOME/.hermes/skills/"
done
```

### 3. Skripte ausführbar machen

```bash
find ~/.hermes/skills/{sandbox-snapshot,sqlite-reader,greyscript-linter,github-ops,bash-script-builder,telegram-notifier,knowledge-distiller,maxclaw-session-manager,hermes-cli-quirks}/scripts \
     -type f \( -name '*.sh' -o -name '*.py' \) -exec chmod +x {} +
```

### 4. Telegram-Token setzen (für telegram-notifier)

```bash
# In ~/.bashrc oder ~/.config/hermes/env:
export TG_BOT_TOKEN="123456:ABC-DEF..."
export TG_CHAT_ID="7222661188"
```

### 5. Session-Verzeichnis vorbereiten

```bash
mkdir -p ~/.local/share/maxclaw/{snapshots,logs}
```

### 6. `setup.sh` ergänzen (optional, für Vollintegration)

Im Original-`setup.sh` nur `project-doc-sync` installiert. Damit **alle 8
neuen Skills** mitkommen, am Ende von `setup.sh` einfügen:

```bash
# --- Allround-Skills installieren --------------------------------------------
info "Installiere Allround-Skill-Set (9 Skills)..."
SKILL_SRC="$REPO_DIR/skills"
for s in sandbox-snapshot sqlite-reader greyscript-linter github-ops \
         bash-script-builder telegram-notifier knowledge-distiller \
         maxclaw-session-manager hermes-cli-quirks; do
    [[ -d "$SKILL_SRC/$s" ]] || { warn "  fehlt: $s"; continue; }
    cp -r "$SKILL_SRC/$s" "$SKILL_DST/"
    info "  + $s"
done
```

### 7. Cron-Jobs registrieren

`workflows/register-workflows.sh` ergänzen um die neuen Triggers:

```bash
declare -a JOBS=(
    "greyhack-ci-watch|0 * * * *|workflows/greyhack-ci-watch.md|greyhack,greyscript-linter,sandbox-snapshot"
    "github-pr-monitor|0 9,17 * * *|workflows/github-pr-monitor.md|github-ops,maxclaw-session-manager"
    "daily-briefing|0 7 * * *|workflows/daily-briefing.md|telegram-notifier,maxclaw-session-manager"
    "knowledge-distill|0 23 * * 0|workflows/knowledge-distill.md|knowledge-distiller,telegram-notifier"
    "sqlite-health|0 4 * * 0|workflows/sqlite-health.md|sqlite-reader,telegram-notifier"
)
./workflows/register-workflows.sh
```

## Verifikation

```bash
# 1) Alle Skills sichtbar?
ls ~/.hermes/skills/ | grep -E '(sandbox-snapshot|sqlite-reader|greyscript-linter|github-ops|bash-script-builder|telegram-notifier|knowledge-distiller|maxclaw-session-manager|hermes-cli-quirks)'

# 2) YAML-Frontmatter gültig?
for s in sandbox-snapshot sqlite-reader greyscript-linter github-ops \
         bash-script-builder telegram-notifier knowledge-distiller \
         maxclaw-session-manager hermes-cli-quirks; do
  head -1 "$HOME/.hermes/skills/$s/SKILL.md" | grep -q '^---$' && echo "OK $s"
done

# 3) Smoke-Tests der wichtigsten Skripte
~/.hermes/skills/maxclaw-session-manager/scripts/session.py start test
~/.hermes/skills/maxclaw-session-manager/scripts/session.py finish test 0
~/.hermes/skills/maxclaw-session-manager/scripts/session.py last test

# 4) Snapshot-Trockenlauf
~/.hermes/skills/sandbox-snapshot/scripts/snapshot.sh "$HOME" 3
```

## Deinstallation

```bash
for s in sandbox-snapshot sqlite-reader greyscript-linter github-ops \
         bash-script-builder telegram-notifier knowledge-distiller \
         maxclaw-session-manager hermes-cli-quirks; do
  rm -rf "$HOME/.hermes/skills/$s"
done
```

## Updates

Da das Skill-Set im MaxClaw-Repo versioniert ist (`version: x.y.z` im
Frontmatter), reicht ein `git pull` im Repo-Klon + ggf. neue Symlinks.
Hermes erkennt aktualisierte SKILL.md automatisch beim nächsten Start.