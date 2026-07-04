# Workflow: GreyHack DB Snapshot (Sandbox-Clone)

**Typ:** Cron-Job · **Zeitpunkt:** alle 6 Stunden (0 */6 * * *) · **Modell:** `heartbeat` (billig) · **Deliver:** Telegram (nur bei Anomalie) · **Skills:** `greyhack`

## Ziel
Regelmäßige **Sandbox-Snapshots** der GreyHack-Datenbank anlegen, ohne das Original zu berühren.
MaxClaw arbeitet nur auf Kopien → null Risiko für den laufenden Spielstand.

## Was passiert pro Lauf
1. **Snapshot erstellen:** `sqlite3 .backup` → `~/backups/greyhack/GreyHackDB_YYYYMMDD_HHMMSS.db`
2. **Sandbox-Clone:** Symlink `~/backups/greyhack/sandbox-latest.db` → aktuellster Snapshot
3. **Rotation:** Alte Snapshots → nur die letzten 7 behalten
4. **Diff:** Vergleich mit Vorgänger-Snapshot — neue Computer? Neue Mails? Neue Passwörter?
5. **Größen-Tracking:** `greyhack-db-snapshot.sh --dry-run` → Größenentwicklung loggen
6. **Analyse:** Optional `greyhack-db-analyze.py ~/backups/greyhack/sandbox-latest.db --json`
7. **Stille:** Nur bei **Anomalie** (Größensprung >20%, neue Computer, neue Player, neue BankAccounts) → Telegram-Alarm

## Warum "Sandbox"?
Die GreyHack-DB darf NIE direkt beschrieben werden. `sqlite3 .backup` erzeugt eine atomare,
konsistente Kopie — READ-ONLY auf dem Original. Die Analysen greifen nur auf die Kopie zu.
So arbeiten MaxClaws Werkzeuge in einer eigenen Sandbox.

## Prompt (self-contained)
```
Führe ~/bin/greyhack-db-snapshot.sh --dry-run aus.
Wenn der Dry-Run grün ist (keine Anomalie), führe ohne --dry-run aus.
- Silently on success: Keine Nachricht bei Erfolg.
- Alert on anomaly: Nur bei echtem Alarm (Größensprung >20%, neue Computer, neuer Player)
  → Telegram an mich mit Diff-Report.
Dann führe optional ~/bin/greyhack-db-analyze.py ~/backups/greyhack/sandbox-latest.db --json --summary
aus. Wenn die Analyse neue Erkenntnisse bringt (z. B. neuer Coins-Wallet, neuer Bank-Account):
Kurze Zusammenfassung an Basti.
Wenn nichts los: absolut still.
Deutsch.
```

## Einrichten
```bash
# Schedule: "0 */6 * * *"   (alle 6 Stunden)
# Deliver:  telegram:7222661188
# Skills:   greyhack
# (registriert via ./workflows/register-workflows.sh)
```

## Pitfalls
- ❌ Direkt auf die Original-DB schreiben → Spiel kann Corrupt produzieren.
- ✅ `sqlite3 .backup` (oder `.clone`) ist READ-ONLY auf Source — immer sicher.
- ❌ Täglich zu snapshotten bei 6.9 MB → unnötig; 6h reicht völlig.
- ✅ Rotation auf 7 Snapshots = ~48 MB max auf Disk.
- ✅ Watchdog-Pattern: Stille ist gut — Alarm nur bei echten Changes.
