# MaxClaw Security Audit — 2026-07-04

> **Auditor:** MaxClaw Security-Auditor (read-only)
> **Repo:** `/tmp/maxclaw-clone/`
> **Inspiration:** `yuno-tools/hardening_audit.src` (GreyHack) → adaptiert auf Linux/MaxClaw
> **Status:** Vorschlag. P0-Findings erfordern Bastis Freigabe, bevor irgendeine Änderung
> an der Live-Config vorgenommen wird.

---

## 0. Executive Summary

| Metrik | Wert |
|--------|------|
| **Gesamt-Score** | **43 / 100** |
| **Findings total** | 20 |
| P0 (kritisch, sofort) | 2 |
| P1 (wichtig, diese Woche) | 5 |
| P2 (nice-to-have) | 3 |
| OK | 10 |
| **Verdict** | Grundphilosophie (Default-Deny, SecretRef, main-Tabu) ist **korrekt**, aber es fehlen operative Schichten (Egress-Isolation, Modell-Limits, automatischer Audit). Die Live-Config ist heute verletzbar in 2 P0-Punkten. |

**Top-3 Risiken heute:**
1. **`~/.hermes/.../.lock`-Dateien sind world-writable** — wenn auch harmlose Lockfiles, signalisiert es mangelnde Härtung und kann theoretisch missbraucht werden.
2. **Keine aktive Egress-Firewall** — bei kompromittiertem Agent beliebige Outbound-Verbindung möglich (Exfiltration).
3. **Heartbeat-Modell und `monthly_limit_eur` in der aktiven Hermes-Config nicht überprüfbar** — wir wissen nicht, ob Kostenlimits greifen.

---

## 1. Findings-Tabelle (komplett)

| ID | Phase | Severity | Was | Aufwand | Nutzen | Status |
|----|-------|----------|-----|---------|--------|--------|
| P0.backup.secretref_exists | 0 | **P0** | `~/.openclaw/out/` fehlt — Hermes/OpenClaw läuft ohne SecretRef-Backend | 15 min | hoch (Secrets aktuell unklar gespeichert) | offen |
| P0.backup.recent | 0 | OK | Letzte config.yaml-Sicherung 1 Tag alt | — | — | ok |
| P1.user.not_root | 1 | OK | Agent läuft als uid=1000 (bratan), nicht root | — | — | ok |
| P1.user.bin_owner | 1 | OK | `~/bin/` gehört bratan:bratan | — | — | ok |
| P2.port.gateway | 2 | OK | Port 18789 nicht aktiv (kein laufender Gateway) | — | — | ok |
| P2.port.world_listeners | 2 | P2 | 3 Listener auf 0.0.0.0 (Ports 27036, 8765, 8200) — sshd(22) fehlt sogar → möglicherweise Filter im Container | 5 min | mittel (Übersicht) | offen |
| P3.fw.ufw_active | 3 | P2 | ufw nicht installiert/aktiv — keine Egress-Isolation auf Host-Ebene | 30 min | hoch (Defense-in-Depth) | offen |
| P3.dns.resolution | 3 | OK | DNS funktioniert für Allowlist-Host | — | — | ok |
| P4.write_paths.declared | 4 | **P1** | In **aktuell aktiver** Hermes-Config fehlt `write_paths:`-Block — Default-Deny für Files ist **nicht durchgesetzt** | 10 min | hoch (Kernphilosophie!) | offen |
| P4.git.main_push_denied | 4 | **P1** | `git push* main*` ist in der Hermes-Config nicht in `deny:` — Risiko versehentlicher Push | 5 min | hoch | offen |
| P4.sudo.deny | 4 | **P1** | `sudo*` ist nicht in `deny:` — Rechte-Eskalation möglich | 5 min | hoch | offen |
| P4.config.perm | 4 | OK | `~/.hermes/config.yaml` ist 600 (korrekt) | — | — | ok |
| P4.fs.world_writable | 4 | **P0** | 3 `.lock`-Dateien in `~/.hermes/hermes-agent/.../venv*/` sind world-writable (`o+w`) | 5 min | mittel (Lockfiles, aber Hygiene) | offen |
| P4.ssh.dir_perm | 4 | OK | `~/.ssh` ist 700 | — | — | ok |
| P5.cron.root | 5 | P1 | `/etc/crontab` enthält `17 * * * * root run-parts --report /etc/cron.hourly` — System-Default; nicht vom Agent verursacht, aber dokumentationswürdig | 0 min (Info) | niedrig | info |
| P5.cron.user_jobs | 5 | OK | 3 User-Cron-Einträge, kein sudo | — | — | ok |
| P5.git.branch | 5 | OK | Repo-Branch: `main` (read-only Audit-Kontext) | — | — | ok |
| P5.git.uncommitted | 5 | P2 | 25 uncommitted Änderungen im Repo (Audit-Artefakte selbst) | 5 min | niedrig | offen |
| P5.proc.running | 5 | OK | Bekannte Hermes-Prozesse aktiv | — | — | ok |
| M.budget.declared | M | **P1** | `monthly_limit_eur` in der aktiven Hermes-Config nicht gefunden | 10 min | hoch (Kostenexplosions-Schutz) | offen |

---

## 2. Was ist OK (was funktioniert bereits)

- ✅ **Default-Deny-Philosophie in Repo-Config** (`config/config.yaml`): `permissions.default: deny` ist gesetzt. Die Vorlage ist solide.
- ✅ **`write_paths`-Block in der Repo-Vorlage** (Zeile 59–62): nur 3 enge Pfade, korrekt.
- ✅ **`greybel build` ohne `-u`**: in `permissions.terminal.allow` und in AGENTS.md dokumentiert.
- ✅ **`git push* main*` in Repo-Vorlage** in `deny` — GreyHack-Prinzip „main ist tabu" erfüllt.
- ✅ **`sudo*` in Repo-Vorlage** in `deny`.
- ✅ **Confirmations / Bestätigungspflicht** in Repo-Vorlage für `send_message`, `publish`, `delete_outside_workspace`, `git_push_main`.
- ✅ **Browser-Tool** in Repo-Vorlage explizit aus (`enabled: false`) — Prompt-Injection-Schutz.
- ✅ **Gateway bindet auf `127.0.0.1`** in Repo-Vorlage, mit `require_token: true`.
- ✅ **Telegram `home_chat_id`** in Repo-Vorlage fest auf Bastis Chat-ID.
- ✅ **`config.yaml` selbst ist 600** auf der Live-Instanz.
- ✅ **`~/.ssh` ist 700** auf der Live-Instanz.

---

## 3. Was ist schwach (P1, diese Woche)

| ID | Problem | Empfehlung | Aufwand |
|----|---------|------------|---------|
| P4.write_paths.declared | In der **aktiv laufenden** `~/.hermes/config.yaml` fehlt `write_paths:`. Damit ist Default-Deny für Files **theoretisch** gesetzt, praktisch aber undefiniert. | `permissions.file.write_paths` mit den drei Repo-Pfaden + `~/logs/` ergänzen. | 10 min |
| P4.git.main_push_denied | In der Live-Config fehlt `git push* main*` in `deny`. | Eintrag in `permissions.terminal.deny` ergänzen. | 5 min |
| P4.sudo.deny | `sudo*` ist nicht in `deny:`. | Eintrag ergänzen. | 5 min |
| M.budget.declared | `monthly_limit_eur` fehlt in Live-Config. | Pro Modell ergänzen (Heartbeat 1 €, main 20 €, heavy 50 €). | 10 min |
| P5.cron.root | System-Crontab existiert (`/etc/crontab`). **Nicht** vom Agent verursacht, aber MaxClaw sollte das in seinem Inventar kennen. | Dokumentation in `agent/MEMORY.md`: „System-Cron houry auf root — unverändert lassen." | 5 min |

---

## 4. Was fehlt (P2, nice-to-have)

| ID | Problem | Empfehlung | Aufwand |
|----|---------|------------|---------|
| P2.port.world_listeners | 3 world-listening Ports unerklärt (27036, 8765, 8200) | `ss -ltnp` mit `-p` (root) → welche Prozesse; in `hardening_audit_maxclaw.yaml` als `known_safe` eintragen, wenn harmlos. | 15 min |
| P3.fw.ufw_active | Keine Host-Firewall → keine Egress-Isolation. | `ufw installieren`, `default deny outgoing`, Allowlist für OpenRouter, Telegram, GitHub aufnehmen. | 30 min |
| P5.git.uncommitted | 25 uncommitted Dateien → Audit-Artefakte selbst + andere Änderungen. | Nach Audit-Commit: `git add security/ security-audit-2026-07-04.md && git commit -m "audit(report)"` (auf feature-Branch!). | 5 min |

---

## 5. Was ist P0 (sofort klären)

### P0.backup.secretref_exists — `~/.openclaw/out/` fehlt

**Befund:** Der Pfad, in dem SecretRef laut Repo-Config (`secrets.path: "~/.openclaw/out/"`) verschlüsselte Credentials ablegen sollte, existiert nicht auf Bastis Host. Auf seiner Instanz läuft Hermes statt OpenClaw (`~/.hermes/` ist da, `~/.openclaw/` nicht). Das ist erstmal konsistent — Hermes speichert in `auth.json` (0600) statt in SecretRef.

**Frage an Basti:**
1. Bleiben wir bei Hermes-nativer Secret-Persistenz (`auth.json`, 0600) und lassen den OpenClaw-SecretRef-Pfad leer?
2. Oder migrieren wir zu SecretRef (externes Tool, z. B. `pass`/GPG), um die Repo-Philosophie zu spiegeln?

**Empfehlung (zur Auswahl):**
- **Variante A:** Repo-Config anpassen → `secrets.backend: hermes-native`, Pfad `~/.hermes/`. Aufwand 5 min.
- **Variante B:** SecretRef mit `pass` einrichten → kompatibel zur Repo-Philosophie, aber Migration aller Tokens. Aufwand ~1 Stunde.

### P0.fs.world_writable — `~/.hermes/.../venv*/.lock`-Dateien sind world-writable

**Befund:** Drei Lock-Dateien in Python-venv-Pfaden (`hermes-agent/venv/lib/python3.11/site-packages/.lock`, `hermes-agent/venv/.lock`, `hermes-agent/.venv/.lock`) haben Modus `o+w`. Sie sind technisch Lockfiles (also nicht direkt ausführbar), aber:

- **Hygiene-Indikator:** Wenn das Setupscript `o+w` setzt, macht es das möglicherweise auch woanders.
- **Theoretisches Risiko:** Andere User auf dem Host könnten Lockfiles durch Race-Condition-Manipulation beeinflussen → Pip-Pakete zur Installationszeit austauschen (Supply-Chain-Risiko, low-probability).

**Frage an Basti:**
1. Sind die Lockfiles vom pip-Installations-Bug oder bewusst?
2. Soll der Audit sie per `chmod o-w` härten?

**Empfehlung:** `chmod o-w ~/.hermes/hermes-agent/venv/.lock ~/.hermes/hermes-agent/.venv/.lock ~/.hermes/hermes-agent/venv/lib/python3.11/site-packages/.lock` — Aufwand 2 min.

---

## 6. Adaptierte GreyHack-Phasen (Mapping)

| GreyHack-Phase | GreyHack-Check | MaxClaw-Adaptierung | Wo dokumentiert |
|---|---|---|---|
| PHASE 0 BACKUP-ADMIN | Backup-User anlegen | SecretRef-Backup + Hermes-config-Snapshot-Alter | `phase_0_backup_admin` in `hardening_audit_maxclaw.yaml` |
| PHASE 1 USER-AUDIT | Gast-Account listen | uid != 0 + ~/bin-Ownership | `phase_1_user_audit` |
| PHASE 2 PORT-AUDIT | offene Ports listen | Gateway-Bind + 0.0.0.0-Listener | `phase_2_port_audit` |
| PHASE 3 FIREWALL | Router-Regeln empfehlen | Egress-UFW + DNS-Test | `phase_3_firewall` |
| PHASE 4 PERMISSION-CHECK | `/etc/passwd`-Modus | write_paths + world-writable + SecretRef-Modus | `phase_4_permission_check` |
| PHASE 5 TRACE-MONITORING | Active Trace = disconnect | Cron-Diff + Git-Branch + laufende Prozesse | `phase_5_trace_monitoring` |

---

## 7. Empfehlungen mit Aufwand/Nutzen

### 7.1 Sofort (P0 — diese Sitzung, nach Bastis OK)

| Maßnahme | Aufwand | Nutzen | Risiko ohne |
|---|---|---|---|
| `chmod o-w` auf 3 venv-Lockfiles | 2 min | Hygiene, mögl. Supply-Chain-Mitigation | gering (Lockfiles) → mittel (Habit) |
| Entscheidung Secret-Backend | 5 min | Klare Persistenz-Strategie | hoch (unklar wo Keys liegen) |

### 7.2 Diese Woche (P1)

| Maßnahme | Aufwand | Nutzen |
|---|---|---|
| `write_paths:` in Hermes-Config ergänzen | 10 min | Default-Deny wird durchsetzbar |
| `git push* main*` + `sudo*` in `deny:` | 5 min | Rechte-Disziplin |
| `monthly_limit_eur` pro Modell | 10 min | Kostenexplosions-Schutz |
| Dokumentation System-Cron in MEMORY | 5 min | Audit-Trail |

### 7.3 Nächste 2 Wochen (P2)

| Maßnahme | Aufwand | Nutzen |
|---|---|---|
| ufw + Egress-Allowlist | 30 min | Defense-in-Depth gegen Exfiltration |
| World-Listener-Inventar | 15 min | Klare Sicherheitslage |
| `~/bin/maxclaw-security-audit.sh` als Cron-Job | 5 min | Tägliche Selbst-Prüfung |
| Audit-Commit auf feature-Branch | 5 min | Sauberes Repo |

### 7.4 Nice-to-have (laufend)

| Maßnahme | Aufwand | Nutzen |
|---|---|---|
| Skill-Whitelist-Policy durchsetzen | 1 h | ClawHavoc-Resilienz |
| Gehärtete v3.1-Config aktivieren (siehe `config/config.yaml` v3.1-Vorschlag) | 20 min | Integrierte Defense |
| Network-Isolation auf Docker-Bridge (Block 8) | 4 h | Stärkste Stufe |

---

## 8. Was MaxClaw NICHT tun wird (automatisch)

Defensive by design — Basti hat ein lokales System. Deshalb:

- ❌ Keine Auto-Fixes bei P0 — Audit fragt erst.
- ❌ Keine `sudo`-Aufrufe — alles im User-Kontext.
- ❌ Kein Schreiben außerhalb `~/docs/` für Audit-Reports — alles read-only.
- ❌ Kein Senden an Telegram bei P0 ohne Hook — Hook muss von Basti genehmigt werden.
- ❌ Kein Push auf `main` — alle Audit-Änderungen gehen auf feature-Branch.

---

## 9. Gehärtete config.yaml v3.1 (Vorschlag, nicht aktiv)

Siehe [`config/config.yaml v3.1`](#) (separater Vorschlag im Repo). Integriert:

- Verschärfte `write_paths` (4 statt 3, plus `~/logs/`)
- Skill-Limit-Tabelle (welcher Skill darf welche Tools)
- Cron-Approval-Mode (`safe` default, `smart` opt-in)
- Network-Isolation-Block mit Allowlist
- Rate-Limits (Heartbeat 1 €/Monat, main 20 €, heavy 50 €)

**Status:** Bereit zur Übernahme — wartet auf Bastis Review.

---

## 10. Anhänge

- A. `security/policies.md` — verbindliche Aktions-Policy
- B. `security/hardening_audit_maxclaw.yaml` — Self-Hardening-Config (GreyHack-Pattern)
- C. `security/key_rotation.md` — Secret-Rotations-Wissen
- D. `~/bin/maxclaw-security-audit.sh` — operatives Audit-Skript (read-only)
- E. `~/logs/maxclaw-security-audit-FIRST.json` — erster Test-Lauf (Score 0)
- F. `config/config.yaml v3.1` — gehärtete Config-Vorlage