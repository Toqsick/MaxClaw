# 🦾 MaxClaw

> **MaxClaw** = die [OpenClaw](https://openclaw.ai)-Instanz von **minimax** (Nous Research), aufgesetzt für Bastis Projekte.
> Dieses Repo ist **Setup + Nutzung + automatische Workflows** — als lauffähige Vorlage, nicht als bloße Beschreibung.

MaxClaw ist ein **persönlicher KI-Agent**, der auf einem eigenen Rechner/Server läuft,
vollen Zugriff auf seine Arbeitsumgebung hat, sich mit deinen Tools verbindet und
**proaktiv** im Hintergrund arbeitet — während du etwas anderes machst.

Anders als ein Chatbot (ChatGPT, Claude, Gemini), der nur im Chatfenster antwortet und
auf dich wartet, ist MaxClaw ein **Mitarbeiter mit eigenem Schreibtisch**: er erstellt Dateien,
führt Programme aus, surft im Netz, ruft APIs auf, erweitert seine eigenen Fähigkeiten und
kommt von sich aus auf dich zu (z. B. per Telegram).

---

## 📚 Der Kurs — 8 Blöcke, die aufeinander aufbauen

Nachgebaut nach dem Video *„OpenClaw Kurs für Einsteiger: Alle Konzepte einfach erklärt"*,
aber konkret auf **MaxClaw** und **unsere Projekte** gemünzt.

| # | Block | Datei | Was du danach kannst |
|---|-------|-------|----------------------|
| 1 | Grundlagen & Installation | [docs/01-grundlagen.md](docs/01-grundlagen.md) | Was MaxClaw ist, wo man es installiert |
| 2 | Kosten & Modelle | [docs/02-kosten-und-modelle.md](docs/02-kosten-und-modelle.md) | API-Key vs. OAuth, Modell-Routing, Kosten begrenzen |
| 3 | Das Gehirn des Agenten | [docs/03-das-gehirn.md](docs/03-das-gehirn.md) | Soul/Identity/Agents/User/Tools/Memory verstehen |
| 4 | Kommunikation & Multi-Agent | [docs/04-kommunikation-multiagent.md](docs/04-kommunikation-multiagent.md) | Gateway, Channels, Sessions, Subagenten |
| 5 | Automatisierung | [docs/05-automatisierung.md](docs/05-automatisierung.md) | Heartbeat & Cron-Jobs |
| 6 | Erweiterungen | [docs/06-erweiterungen.md](docs/06-erweiterungen.md) | Skills, Plugins, MCP, CLI-Tools |
| 7 | Security & Risiken | [docs/07-security.md](docs/07-security.md) | Prompt Injection, Default-Deny, Secrets, Sandbox |
| 8 | Server-Deployment | [docs/08-server-deployment.md](docs/08-server-deployment.md) | VPS + Docker + Reverse Proxy sicher aufsetzen |

---

## 🗂️ Repo-Struktur

```
MaxClaw/
├── README.md               ← du bist hier
├── setup.sh                ← One-Command-Setup (kopiert Vorlagen in den Workspace)
├── docs/                   ← der 8-Block-Kurs
├── agent/                  ← Core-Dateien als Vorlage (Soul, Identity, Agents, …)
├── config/                 ← config.yaml mit Default-Deny + Modell-Routing
├── workflows/              ← automatische Workflows für UNSERE Projekte
│   ├── daily-briefing.md         (07:00 Briefing per Telegram)
│   ├── greyhack-ci-watch.md      (CI-Build-Check greyhack-tools)
│   ├── security-audit-weekly.md  (wöchentlicher Read-Only-Audit)
│   ├── github-pr-monitor.md      (offene PRs/Issues Toqsick-Repos)
│   └── register-workflows.sh     (registriert alle Cron-Jobs)
├── skills/                 ← Beispiel-Skill (project-doc-sync)
└── .gitignore
```

---

## ⚡ Quickstart

```bash
# 1. Repo holen
git clone https://github.com/Toqsick/MaxClaw.git
cd MaxClaw

# 2. Setup ausführen (legt Vorlagen im MaxClaw-Workspace an)
./setup.sh

# 3. Workflows als Cron-Jobs registrieren (optional)
./workflows/register-workflows.sh
```

> ⚠️ **Sicherheit zuerst:** Lies **[docs/07-security.md](docs/07-security.md)**, bevor du MaxClaw
> Zugriff auf sensible Tools gibst. MaxClaw ist ein *„Praktikant mit Superkräften"* —
> extrem nützlich, aber schau immer drüber, was er tut. Keine geschäftskritischen Prozesse.

---

## 🎯 Unsere konkreten Auto-Workflows

MaxClaw ist bei uns kein Spielzeug — er hält diese Projekte am Laufen:

- **GreyHack-Tools** — CI-Build-Wächter: prüft, ob `greybel`-Builds nach Commits grün bleiben.
- **hermes-v7** — beobachtet neue PRs/Issues und fasst sie zusammen.
- **System-Docs** (`~/docs/system/`) — synchronisiert Doku nach jedem relevanten Task.
- **Security-Audit** — wöchentlicher Read-Only-Check (Desktop + GCP VM), Report vor Fixes.
- **Daily-Briefing** — morgens um 07:00 kompakt per Telegram.

Details je Workflow im Ordner [`workflows/`](workflows/).

---

*Erstellt als lauffähige Vorlage. Kommentare & Config auf Deutsch. Stand: Juli 2026.*
