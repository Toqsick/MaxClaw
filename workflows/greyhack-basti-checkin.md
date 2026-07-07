# Workflow: GreyHack Basti-Check-in

**Typ:** Cron-Job (LLM, mittel) · **Zeitpunkt:** Mo + Mi + Fr, 20:00 · **Modell:** `main` (günstig, lockerer Ton) · **Deliver:** Telegram · **Skills:** `yuno-user-preferences`, `greyhack`

## Ziel
Dreimal pro Woche (Mo/Mi/Fr) schickt MaxClaw Basti einen **kurzen, warmen Check-in** — Wochenrückblick
+ neue Erkenntnisse aus den `yuno-tools`-Tests + Vorbereitung auf die nächste GreyHack-Session.
Damit Basti nicht jedes Mal bei Null anfängt, sondern kontinuierlich im Flow bleibt.

## Warum?
Basti spielt GreyHack in unregelmäßigen Sessions — mal 2 Tage am Stück, mal 2 Wochen Pause.
Ohne Check-in verliert er den Faden: welches Tool war nochmal halbfertig, welche Side-Quest
stand offen, welcher Bug nervt noch. Der Check-in ist **kein Report**, sondern ein **Kumpel-Anstoß**:
„Hey, letzte Woche hast du … — diese Woche wäre cool: …".

## Was passiert pro Lauf
1. **Letzte Session rekonstruieren:** letzte 1–3 GreyHack-bezogene Sessions aus `~/.local/share/openclaw/logs/`.
2. **yuno-tools-Tests scannen:** was hat sich seit letztem Check-in in `~/yuno-tools/` getan?
   (git log, neue Files, offene TODOs.)
3. **Offene GreyHack-Missionen** aus `~/docs/system/greyhack-missions.md` ziehen (nur Status, kein Volltext).
4. **Output:** Telegram-Nachricht mit festem 6-Zeilen-Schema:
   - 📅 Wann warst du zuletzt da? (kurz)
   - ✅ Was lief gut?
   - 🛠 Was hat sich in yuno-tools getan? (1 Zeile)
   - 🎮 Top-3 GreyHack-Highlights der letzten 7 Tage
   - ❗ Top-3 offene Punkte (sortiert nach „am nervigsten")
   - 💡 Ein konkreter Vorschlag für die nächste Session (1 Satz)
5. **Watchdog:** wenn weder GreyHack-Aktivität noch yuno-tools-Änderungen seit letztem Check-in:
   → **silent**. (Verhindert Spam in Urlaubswochen.)

## Prompt (self-contained)
```
Du bist Bastis GreyHack-Kumpel. Lese:
- Letzte 1–3 OpenClaw-Sessions aus ~/.local/share/openclaw/logs/ (GreyHack- oder yuno-tools-bezogen)
- ~/yuno-tools/ (git log --since="3 days ago", neue Files)
- ~/docs/system/greyhack-missions.md  (nur Status der Missionen)
- ~/docs/system/greyhack-weekly-insights-*.md (die letzten 2 Wochen, falls vorhanden)

Aufgaben:
1. WENN keine GreyHack-Aktivität UND keine yuno-tools-Änderungen seit dem letzten Check-in
   (vor 2 Tagen): antworte nur "all quiet, skipping" und schicke NICHTS an Telegram.
2. Sonst baue eine 6-zeilige Telegram-Nachricht exakt nach diesem Schema:

   📅 Letzte GreyHack-Session: <relative Zeit, 1 Zeile>
   ✅ Was lief: <max. 2 Bullet-Points>
   🛠 yuno-tools: <1 Bullet, was sich getan hat>
   🎮 Highlights (7 d): <max. 3 Bullets>
   ❗ Offen: <max. 3 Bullets, sortiert nach "am nervigsten">
   💡 Nächste Session: <1 konkreter Satz-Vorschlag>

3. Ton: locker, „Kumpel", keine Floskeln, kein „Hier ist dein Bericht". Basti will einen Anstoß,
   keinen Roman. Maximal 12 Zeilen Telegram.

Nutze die Skills `yuno-user-preferences` (Bastis Schreibstil: kurz, ehrlich, kein Bullshit-Bingo)
und `greyhack` (Domänen-Vokabular). Deutsch.
```

## Einrichten
```bash
#   Schedule: "0 20 * * 1,3,5"   (Mo + Mi + Fr um 20:00)
#   Deliver:  telegram:7222661188
#   Skills:   yuno-user-preferences, greyhack
#   (registriert via ./workflows/register-workflows.sh)
```

## Pitfalls
- ❌ **Jeden Lauf eine Nachricht, auch wenn nichts los war** → Watchdog-Pattern verletzt; in
  Urlaubswochen führt das zu Reiz-Abschaltung.
- ❌ **Zu lang werden** → 12 Zeilen Telegram ist das harte Limit. Lieber eine Sache weglassen
  als das Limit zu sprengen.
- ❌ **Generische Vorschläge** („Weiter so!", „Viel Erfolg!") → verboten; der Skill
  `yuno-user-preferences` ist genau dafür da, Bastis No-BS-Ton zu treffen.
- ✅ **Modell `main`** — lockerer Ton + moderate Synthese; Opus wäre overkill, Heartbeat zu dünn.
- ✅ **Mo/Mi/Fr statt täglich** — gibt Basti 2 Tage Ruhe zwischen Check-ins, ohne den Faden zu
  verlieren.
- ✅ **Konsistenz mit Knowledge-Distiller** — der Sonntags-Distiller füttert die Insights-Files,
  aus denen dieser Check-in seine Highlights zieht. So entsteht ein Wochen-Rhythmus.