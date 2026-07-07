# Block 8 — Server-Deployment (VPS + Docker)

## Ziel in einem Satz
MaxClaw sicher auf einem VPS in einem isolierten Docker-Container aufsetzen.

## Warum VPS + Docker?
Nach Block 7 ist klar: MaxClaw soll **nie direkt aufs Betriebssystem**. Ein VPS mit Docker gibt:
- **Isolation** — eigenes Dateisystem, eingeschränkter Netzwerkzugang, CPU/RAM-Limits.
  Worst Case bleibt der Schaden im Container.
- **24/7 online** — unabhängig davon, ob dein Rechner läuft.
- **Saubere Trennung** — Privatleben/Hauptrechner vs. Arbeitsbereich des Agenten.

## Das Port-Problem (unbedingt verstehen!)
Installierst du OpenClaw **manuell** auf einem Server, läuft das Gateway-Dashboard standardmäßig
auf Port **18789** — und der ist **von außen erreichbar** über die Server-IP. Damit hängt dein
Agent offen im Internet.

> ⚠️ Bots scannen rund um die Uhr das Internet nach offenen Ports. Es wurden bereits
> **>100.000 OpenClaw-Instanzen** so gefunden. Ein Angreifer braucht noch den Gateway-Token —
> könnte ihn aber brute-forcen.

## Zwei Deployment-Wege

### Weg A: Managed One-Click (z. B. Hostinger) — am einfachsten
Vorkonfigurierte Sicherheit:
- **Reverse Proxy (Traefik)** sitzt vor der Instanz → Gateway-Port **nicht** direkt erreichbar.
  Zugang nur über **Domain mit HTTPS**.
- **Gateway-Token** automatisch installiert.
- **Kein Root-Zugang nötig** — der Anbieter macht Sicherheitsupdates & Serverpflege.
- Setup-Schritte: AI-Provider wählen → Messenger-Channel (Telegram-Bot-Token) → fertig.

**Trade-off:** Weniger Kontrolle über die Infrastruktur, dafür sicher & wartungsarm.

### Weg B: Eigener VPS + Docker (volle Kontrolle) — unser Weg
Für Basti (Docker-Erfahrung, eigene GCP VM) der passendere Weg. Grundgerüst:

```bash
# --- Auf dem VPS (Ubuntu) ---

# 1. Docker installieren (falls nicht vorhanden)
curl -fsSL https://get.docker.com | sh

# 2. Isoliertes Netzwerk + Daten-Volume
docker network create maxclaw-net
docker volume create maxclaw-data

# 3. MaxClaw-Container starten — Gateway NUR an localhost binden (127.0.0.1)!
#    So ist Port 18789 NICHT von außen erreichbar.
docker run -d \
  --name maxclaw \
  --network maxclaw-net \
  --restart unless-stopped \
  --memory 2g --cpus 2 \
  -v maxclaw-data:/root/.openclaw \
  -p 127.0.0.1:18789:18789 \
  openclaw/openclaw:latest

# 4. Zugriff nur über verschlüsselten Tunnel (kein offener Port!)
#    Variante 1: SSH-Tunnel vom Laptop
#      ssh -L 18789:127.0.0.1:18789 user@dein-vps
#    Variante 2: Reverse Proxy (Caddy) mit HTTPS + Basic-Auth davorsetzen
```

### Minimaler Caddy-Reverse-Proxy (HTTPS automatisch)
```
# /etc/caddy/Caddyfile — Domain durch deine ersetzen
maxclaw.deine-domain.de {
    reverse_proxy 127.0.0.1:18789   # nur lokal erreichbarer Gateway-Port
    # optionale zusätzliche Schutzschicht:
    basicauth {
        admin <bcrypt-hash>
    }
}
```

## Sicherheits-Checkliste vor dem Go-Live
- [ ] Gateway-Port **nicht** auf `0.0.0.0`, sondern `127.0.0.1` gebunden.
- [ ] Zugang nur über SSH-Tunnel **oder** Reverse Proxy mit HTTPS.
- [ ] Gateway-Token gesetzt & sicher gespeichert (SecretRef, nicht im Klartext).
- [ ] CPU/RAM-Limits am Container gesetzt.
- [ ] Firewall (ufw): nur 22 (SSH) + 443 (HTTPS) offen, 18789 **zu**.
- [ ] `openclaw.json` + `exec-approvals.json` mit Default-Deny (siehe [07-security.md](07-security.md)).
- [ ] Wöchentlicher Security-Audit-Cron aktiv.

```bash
# Firewall-Beispiel (ufw)
sudo ufw default deny incoming
sudo ufw allow 22/tcp
sudo ufw allow 443/tcp
sudo ufw enable
sudo ufw status verbose   # 18789 darf NICHT auftauchen
```

## Häufige Fehler
- ❌ `-p 18789:18789` (bindet an alle Interfaces = offen im Netz). ✅ `-p 127.0.0.1:18789:18789`.
- ❌ Container ohne Memory-Limit → ein Runaway-Prozess frisst den ganzen VPS.
- ❌ Kein Reverse-Proxy/HTTPS → Token & Traffic im Klartext.

## Fertig
Damit läuft MaxClaw isoliert, 24/7, nur über verschlüsselten Zugang erreichbar. Jetzt Core-Dateien
konfigurieren ([Block 3](03-das-gehirn.md)) und Workflows registrieren ([`../workflows/`](../workflows/)).
