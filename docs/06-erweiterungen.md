# Block 6 — Erweiterungen

## Ziel in einem Satz
MaxClaw vom Generalisten zum Spezialisten machen — mit Skills, Plugins, MCP-Servern, CLI-Tools und Nodes.

## Skills — die wichtigste Erweiterung
Standardmäßig ist MaxClaw ein **Generalist**: kann von allem etwas, nichts wirklich spezialisiert.
Ein **Skill** ändert das. Ein Skill ist im Grunde eine **Markdown-Textdatei mit konkreten
Anweisungen**, die MaxClaw ausliest, wenn sie in einer Situation nützlich ist. Ein Skill kann
zusätzlich Ressourcen enthalten (PDFs, Python-Skripte).

**Wann nutzen?** Für Aufgaben, die **regelmäßig** anfallen und die du nicht jedes Mal neu
erklären willst. Beispiel Blogartikel: Ohne Skill rät MaxClaw. Mit Skill weiß er Tonalität,
Länge, Struktur, Quellen → deutlich besseres Ergebnis.

> Skills sind portabel — dieselben Skills funktionieren bei Claude Code, OpenClaw und anderen
> agentischen Systemen, weil es am Ende nur Textdateien sind.

### Built-in Skills & Community-Hub
- **Built-in Skills** sind vorinstalliert (Apple Notes, Google Workspace, Nano-Banana-Bilder …),
  einfach aktivieren.
- **ClawHub** = Community-Hub, wo Leute Skills teilen (auch von Peter Steinberger).
- ⚠️ **Vorsicht:** Auf ClawHub gibt es auch **gefährliche Skills**. Immer die enthaltenen
  Dateien prüfen. ClawHub hat einen Security-Scan, aber trotzdem selbst kontrollieren.
  → Details in [07-security.md](07-security.md).
- Installieren? Einfach MaxClaw den Link/Namen schicken — er durchsucht ClawHub selbst.

## MCP-Server
Ein **MCP-Server** (Model Context Protocol) erklärt MaxClaw einheitlich, wie er mit einem
externen Tool kommuniziert und dessen Funktionen ausführt — ohne komplizierte Einzel-Konfig.
Standard für die Anbindung agentischer Systeme an externe Tools.

## CLI-Tools (der wachsende Trend)
Tools, die direkt im Terminal laufen und vom Agenten ausgeführt werden. **Deutlich
tokeneffizienter** als MCP-Server. Oft werden Skills + CLI-Tools zusammen genutzt.

## Plugins
Ein **Plugin** = Skill mit zusätzlichen Ressourcen (PDFs, MCP-Server, CLI-Tools, Python-Skripte)
— ein **komplettes Paket** für neue Funktionalität. Beispiel: *Lossless Claw* (tauscht die
Context Engine). Sogar Channels (Telegram, WhatsApp, Discord) sind unter der Haube **Plugins**.

## Nodes
Ein **Node** ist ein Gerät, das du mit MaxClaw verbindest (Smart Glasses → *Vision Claw*, iPad
für Benachrichtigungen, Home Assistant für Licht). Idee: der Agent lebt nicht nur auf einem
Bildschirm, sondern ist in deiner ganzen Umgebung präsent. (Noch experimentell.)

## Unsere Erweiterungen (Basti)
- **System-Documentation-Skill** — pflegt `~/docs/system/` als Markdown-Baum.
- **GreyHack-Skills** — Build-Pipeline, GreyScript-Referenz, GTFOBins-DB.
- **daily-briefing / session-handoff / telegram-clarification-prompt** — Betriebs-Skills.
- Beispiel-Skill in diesem Repo: [`../skills/project-doc-sync/`](../skills/project-doc-sync/).

> 💡 Eigenen Skill erstellen? Einfach sagen: „Erstelle einen Skill, der X macht."

## Häufige Fehler
- ❌ Blind Skills von ClawHub installieren, ohne reinzuschauen → Malware/Prompt Injection.
- ✅ Eigene Skills bevorzugen, nur vertraute Quellen, immer Inhalt prüfen.

## Nächste Ausbaustufe
→ [Block 7 — Security & Risiken](07-security.md)
