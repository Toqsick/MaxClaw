---
name: web-design-guidelines
description: UI-Code-Review gegen Vercels Web Interface Guidelines. Nutzen bei "review mein UI", "check accessibility", "audit
  design", "review UX" oder "check meine Seite gegen Best Practices".
metadata:
  author: vercel
  version: 1.0.0
lane: worker-flash
reasoning_effort: high
---
# Web Interface Guidelines

Review Dateien für Compliance mit Web Interface Guidelines.

## Wie es funktioniert

1. Die latest Guidelines von der Source-URL laden
2. Die angegebenen Dateien lesen (oder User nach Dateien/Patterns fragen)
3. Gegen alle Regeln prüfen
4. Findings im tersen `file:line` Format ausgeben

## Guidelines Source

Vor jedem Review fresh laden:
```
https://raw.githubusercontent.com/vercel-labs/web-interface-guidelines/main/command.md
```

Mit WebFetch/terminal die latest Regeln holen. Die geladene Datei enthält alle Rules und Output-Format-Anweisungen.

## Verwendung

Wenn der User ein Datei- oder Pattern-Argument gibt:
1. Guidelines von der Source-URL laden
2. Angegebene Dateien lesen
3. Alle Regeln anwenden
4. Findings im Guidelines-Format ausgeben

Wenn keine Dateien angegeben: User fragen welche Dateien reviewt werden sollen.

## Für Hermes

Nutze `terminal` + `curl` um die Guidelines zu laden:
```bash
curl -sL "https://raw.githubusercontent.com/vercel-labs/web-interface-guidelines/main/command.md"
```
