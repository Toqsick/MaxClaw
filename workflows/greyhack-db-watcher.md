# Workflow: GreyHack Datenbank-Wächter

**Typ:** Cron-Job (Watchdog) · **Zeitpunkt:** alle 30 Minuten · **Modell:** `heartbeat` (billig, deterministisch) · **Deliver:** Telegram (nur bei Änderung)

## Ziel
MaxClaw überwacht die **GreyHack-Spielwelt** autonom: er erkennt, wann ein neuer Computer, eine neue Mail
oder eine neue Bank-Transaktion im Savegame auftaucht — und meldet es Basti sofort per Telegram.
Wenn nichts passiert ist: **still bleiben** (Watchdog-Pattern).

## Warum?
Im GreyHack-Savegame (`GreyHackDB.db`) liegt die gesamte persistente Spielwelt: gehackte Computer,
Mails, Bank-Transaktionen, Missionen. Basti kann nicht alle paar Minuten ins Savegame schauen — der
Agent schon. Bei einer frischen Mail über einen heißen Lead oder einer unerwarteten Bank-Bewegung
will Basti sofort Bescheid wissen, ohne dass er danach fragen muss.

## Was passiert pro Lauf
1. **Snapshot ziehen:** `cp /mnt/DATA/Programme/Steam/steamapps/common/Grey Hack/Grey Hack_Data/GreyHackDB.db`
   nach `~/.local/share/maxclaw/snapshots/GreyHackDB-$(date +%Y%m%d-%H%M).db`.
2. **Hash vergleichen:** wenn identisch zum letzten Snapshot → **silent exit** (kein Telegram).
3. **Bei Änderung:** Schema-Dump + Diff der relevanten Tabellen (`computers`, `mails`, `bank_transactions`)
   via `sqlite3 .dump` extrahieren, zeilenweise vergleichen.
4. **Alarme rastern:** pro Tabelle die hinzugekommenen Zeilen als Kurzbullet zusammenstellen.
5. **Telegram:** nur die Alarm-Bulletlist schicken — kein Volltext, max. 8 Zeilen.

## Snapshot-Strategie (Platten-Hygiene)
```bash
SNAPDIR=~/.local/share/maxclaw/snapshots
mkdir -p "$SNAPDIR"
# Maximal 96 Snapshots behalten (= 48 h bei 30-min-Takt); ältere löschen
ls -1t "$SNAPDIR"/GreyHackDB-*.db | tail -n +97 | xargs -r rm -f
```

## Prompt (self-contained)
```
Du bist der GreyHack-Spielwelt-Wächter. Prüfe die Savegame-DB:
/mnt/DATA/Programme/Steam/steamapps/common/Grey Hack/Grey Hack_Data/GreyHackDB.db

Schritte:
1. sqlite3 <db> "SELECT md5sum FROM pragma_check;" für die drei Tabellen:
   computers, mails, bank_transactions (oder vergleichbare, falls Schema abweicht — prüfe via
   .tables). Wenn sich die Hash-Summe(n) seit dem letzten Snapshot NICHT geändert haben:
   antworte NUR "DB unchanged" und schicke NICHTS an Telegram.
2. Wenn anders: extrahiere die NEUEN Zeilen mit `sqlite3 <db> "SELECT * FROM <tab> WHERE rowid > X"`
   (X = letzte bekannte rowid aus ~/.local/share/maxclaw/db-state.json). Formatiere kompakt:
   max. 3 Zeilen pro Tabelle, ID + 1-2 Schlüsselfelder.
3. Schreibe die neuen rowid-Cursor nach db-state.json zurück (damit der nächste Lauf weiß, wo er
   aufhört).
4. Schicke Basti per Telegram: "🎮 GreyHack-DB-Änderung: <Tabelle(n)> <Anzahl neuer Zeilen>"
   plus die Bulletlist. Wenn keine Alerts: still bleiben.
Deutsch. Keine Floskeln, keine Erklärungen — nur die Tatsachen.
```

## Einrichten
```bash
#   Schedule: "*/30 * * * *"    (jede 30 min)
#   Deliver:  telegram:7222661188 (nur bei Änderung — Watchdog)
#   Skills:   greyhack, greyhack-sandbox
#   (registriert via ./workflows/register-workflows.sh)
```

## Pitfalls
- ❌ **Bei jedem Lauf ein Telegram** → führt zu Reiz-Überflutung; Watchdog-Pattern verbietet das.
- ❌ **Komplettes DB-File kopieren ohne Rotation** → nach einer Woche sind das >2 GB Müll.
- ❌ **Bei laufendem GreyHack lesen** → die DB ist während des Spiels gesperrt (SQLITE_BUSY). Lösung:
  erst auf Existenz von `/tmp/greyhack-save-running.flag` prüfen; falls vorhanden → still überspringen.
- ❌ **Schema-Hardcoding** → wenn GreyHack neue Tabellen einführt, schlägt das Script fehl. Im Prompt
  ist `pragma_check`/`tables`-Liste explizit erwähnt, damit das Schema erst erkundet wird.
- ✅ **Heartbeat-Modell** — der Job ist deterministisch (Hash + sqlite3), keine LLM-Magie nötig.
- ✅ **state-file mit Cursor** — `db-state.json` persistiert die letzte gesehene `rowid` pro Tabelle,
  damit beim nächsten Lauf klar ist, was „neu" ist.