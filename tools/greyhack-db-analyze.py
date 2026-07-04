#!/usr/bin/env python3
# ==============================================================================
# greyhack-db-analyze.py — ClamAV-artige DB-Analyse (JSON-Output)
# ==============================================================================
# Extrahiert strukturierte Daten aus einem GreyHack-DB-Snapshot (Sandbox-Kopie):
#   - Player-State (Nickname, Missions, GameOver, LastConnection, Bank, Wallet)
#   - Mission-Status (Parse aus Missions-JSON-String)
#   - Account-Inventar (BankAccounts, MailAccounts, Passwords)
#   - Netzwerk-Topologie (Computer, Map)
#   - Wirtschaft (Coins, Stocks, Wallets)
#
# Usage:
#   greyhack-db-analyze.py sandbox-latest.db --json          # Vollständiges JSON
#   greyhack-db-analyze.py sandbox-latest.db --summary        # Menschliche Zusammenfassung
#   greyhack-db-analyze.py sandbox-latest.db --player-only    # Nur Player-State
#   greyhack-db-analyze.py sandbox-latest.db --json --pretty  # Formatiertes JSON
# ==============================================================================
import argparse
import json
import os
import sqlite3
import sys
from collections import defaultdict
from datetime import datetime


# ==============================================================================
# DB-Layer
# ==============================================================================

class GreyHackDBAnalyzer:
    """Analysiert eine GreyHack-DB-Kopie (READ-ONLY) und extrahiert strukturierte Daten."""

    def __init__(self, db_path: str, readonly: bool = True):
        if not os.path.isfile(db_path):
            raise FileNotFoundError(f"DB nicht gefunden: {db_path}")

        self.db_path = db_path
        # URI-Modus: immutable=1 verhindert jegliche Schreibversuche
        uri = f"file:{db_path}?mode=ro&immutable=1"
        self.conn = sqlite3.connect(uri, uri=True)
        self.conn.row_factory = sqlite3.Row
        self.cursor = self.conn.cursor()

    def close(self):
        self.conn.close()

    def __enter__(self):
        return self

    def __exit__(self, *args):
        self.close()

    # --- Hilfsfunktionen -----------------------------------------------------

    def _fetchone(self, sql: str, params: tuple = ()) -> dict | None:
        row = self.cursor.execute(sql, params).fetchone()
        return dict(row) if row else None

    def _fetchall(self, sql: str, params: tuple = ()) -> list[dict]:
        return [dict(row) for row in self.cursor.execute(sql, params).fetchall()]

    def _count(self, sql: str, params: tuple = ()) -> int:
        row = self.cursor.execute(sql, params).fetchone()
        return row[0] if row else 0

    # --- Analyse-Methoden ----------------------------------------------------

    def get_player_state(self) -> dict:
        """Extrahiert vollständigen Player-State (Spieler-Charakter)."""
        player = self._fetchone("SELECT * FROM Players LIMIT 1")
        if not player:
            return {"player_found": False}

        computer = self._fetchone(
            "SELECT * FROM Computer WHERE ID = ?", (player["ComputerID"],)
        )

        result = {
            "player_found": True,
            "player_id": player["PlayerID"],
            "computer_id": player["ComputerID"],
            "nickname": player["Nickname"] or "(none)",
            "game_over": bool(player["GameOver"]),
            "last_connection": player["LastConnection"],
            "info_map": {
                "x": player["infoMapX"],
                "y": player["infoMapY"],
                "ind": player["indMap"],
            },
            # Missionen als Rohstring (oft JSON-encoded)
            "missions_raw_length": len(player.get("Missions") or ""),
            "bank_user": player.get("BankUser") or "(none)",
            "wallet_id": player.get("WalletID") or "(none)",
            "shop_hardware_length": len(player.get("ShopHardware") or ""),
            "login_data": bool(player.get("LoginData")),
            "storage_length": len(player.get("Storage") or ""),
            "cooldowns": {
                "missions": player.get("MissionsCooldown"),
                "ctf": player.get("CTFCooldown"),
                "tl": player.get("TLCooldown"),
                "gui_launch": player.get("GuiLaunchCooldown"),
            },
            "computer": {
                "hardware": bool(computer.get("Hardware")) if computer else False,
                "file_system": bool(computer.get("FileSystem")) if computer else False,
                "config_os": bool(computer.get("ConfigOS")) if computer else False,
            } if computer else None,
        }

        # Missions als JSON parsen falls vorhanden
        missions_raw = player.get("Missions", "")
        if missions_raw and len(missions_raw) > 2:
            try:
                result["missions"] = json.loads(missions_raw)
            except (json.JSONDecodeError, TypeError):
                result["missions_raw"] = missions_raw

        # ZeroDay-Requests
        zdr = player.get("ZeroDayRequest", "")
        if zdr and len(zdr) > 2:
            try:
                result["zero_day_request"] = json.loads(zdr)
            except (json.JSONDecodeError, TypeError):
                result["zero_day_request_raw_length"] = len(zdr)

        # TokenTrace / PassiveTraces
        for trace_field in ["TokenTrace", "PassiveTraces", "BankTraces"]:
            val = player.get(trace_field, "")
            if val and len(val) > 2:
                try:
                    result[trace_field.lower()] = json.loads(val)
                except (json.JSONDecodeError, TypeError):
                    result[f"{trace_field.lower()}_length"] = len(val)

        return result

    def get_bank_accounts(self) -> list[dict]:
        """Extrahiert alle BankAccounts mit Transaktionsanzahl."""
        accounts = self._fetchall("SELECT User, Password, length(Transactions) as tx_count FROM BankAccounts")
        for acc in accounts:
            # Transaktionen parsen
            row = self._fetchone("SELECT Transactions FROM BankAccounts WHERE User = ?", (acc["User"],))
            if row and row["Transactions"]:
                try:
                    acc["transactions"] = json.loads(row["Transactions"])
                except (json.JSONDecodeError, TypeError):
                    acc["transactions_raw_length"] = len(row["Transactions"])
        return accounts

    def get_mail_accounts(self) -> list[dict]:
        """Extrahiert alle MailAccounts mit Mail-Anzahl."""
        accounts = self._fetchall("SELECT User, password, length(Mails) as mail_bytes FROM MailAccounts")
        for acc in accounts:
            row = self._fetchone("SELECT Mails FROM MailAccounts WHERE User = ?", (acc["User"],))
            if row and row["Mails"]:
                try:
                    mails = json.loads(row["Mails"])
                    acc["mail_count"] = len(mails) if isinstance(mails, list) else 1
                    acc["mails"] = mails
                except (json.JSONDecodeError, TypeError):
                    acc["mail_count"] = 0
        return accounts

    def get_passwords(self, limit: int = 50) -> list[dict]:
        """Extrahiert Passwort-Hashes/IDs (ohne Plaintext aus Sicherheit)."""
        total = self._count("SELECT COUNT(*) FROM Passwords")
        samples = self._fetchall(
            "SELECT ID, PlainPassword FROM Passwords LIMIT ?", (min(limit, total),)
        )
        return {
            "total": total,
            "samples_shown": len(samples),
            "samples": samples,
        }

    def get_computers(self) -> list[dict]:
        """Extrahiert alle Computer in der DB."""
        comps = self._fetchall("""
            SELECT ID, IsPlayer, IsRouter, IsCTF, IsRented,
                   length(FileSystem) as fs_length,
                   length(Hardware) as hw_length,
                   length(ConfigOS) as os_length,
                   length(Users) as users_length,
                   length(Procs) as procs_length
            FROM Computer ORDER BY IsPlayer DESC, IsCTF DESC
        """)
        return comps

    def get_network_map(self) -> dict:
        """Extrahiert die Netzwerk-Topologie aus der Map-Tabelle."""
        entries = self._fetchall("""
            SELECT IpAddress, Bssid, Essid, TipoRed, AccessType,
                   posX, posY, Mission, Length(LibVersions) as libs_length,
                   WebAddress, Date, GenerationProfile
            FROM Map ORDER BY AccessType
        """)
        # Statistik
        type_counts = defaultdict(int)
        access_counts = defaultdict(int)
        for e in entries:
            type_counts[f"tipo_{e['TipoRed']}"] += 1
            access_counts[f"access_{e['AccessType']}"] += 1

        return {
            "total_ips": len(entries),
            "entries": entries,
            "type_distribution": dict(type_counts),
            "access_distribution": dict(access_counts),
        }

    def get_web_pages(self) -> dict:
        """Extrahiert WebPage-Statistiken."""
        total = self._count("SELECT COUNT(*) FROM WebPages")
        pages = self._fetchall("""
            SELECT PublicIp, LocalIp, ExternalPort, TypeNet, NumVisits, DateCreation,
                   length(Web) as web_length
            FROM WebPages ORDER BY NumVisits DESC LIMIT 20
        """)
        return {
            "total": total,
            "sample": pages,
        }

    def get_files(self, limit: int = 20) -> dict:
        """Extrahiert Datei-Statistiken."""
        total = self._count("SELECT COUNT(*) FROM Files")
        files = self._fetchall(
            "SELECT ID, refCount, length(Content) as content_length FROM Files ORDER BY refCount DESC LIMIT ?",
            (limit,),
        )
        return {"total": total, "top_refcount": files}

    def get_logs(self, limit: int = 20) -> dict:
        """Extrahiert Log-Einträge."""
        total = self._count("SELECT COUNT(*) FROM Logs")
        logs = self._fetchall(
            "SELECT ID, length(Log) as log_length FROM Logs LIMIT ?",
            (limit,),
        )
        return {"total": total, "sample": logs}

    def get_economy(self) -> dict:
        """Extrahiert Wirtschaftsdaten (Coins, Stocks, Wallets)."""
        coins = self._fetchall("SELECT CoinName, OwnerPlayerID, length(CoinContent) as content_length FROM Coins")
        stocks = self._fetchall("SELECT IpAddress, length(StocksContent) as content_length, points FROM Stocks")
        wallets = self._fetchall("SELECT WalletID, length(WalletContent) as content_length FROM Wallets")
        return {
            "coins": {"count": len(coins), "entries": coins},
            "stocks": {"count": len(stocks), "entries": stocks},
            "wallets": {"count": len(wallets), "entries": wallets},
        }

    def get_ctfs(self) -> dict:
        """Extrahiert CTF-Daten."""
        ctfs = self._fetchall("SELECT EventName, OwnerPlayerID, length(EventContent) as content_length FROM CTFs")
        return {"count": len(ctfs), "entries": ctfs}

    def get_info_gen(self) -> dict:
        """Extrahiert globale Spiel-Info (InfoGen)."""
        info = self._fetchone("SELECT * FROM InfoGen")
        if not info:
            return {}
        result = {
            "seed": info["Seed"],
            "clock": info["Clock"],
            "global_money_length": len(info.get("GlobalMoney") or ""),
            "versions_control_length": len(info.get("VersionsControl") or ""),
            "all_libs_length": len(info.get("AllLibs") or ""),
            "exploits_length": len(info.get("Exploits") or ""),
            "guilds_length": len(info.get("Guilds") or ""),
            "invoices_length": len(info.get("Invoices") or ""),
            "delete_version": info.get("DeleteVersion"),
        }
        # ZeroDaySystem
        zds = info.get("ZeroDaySystem", "")
        if zds and len(zds) > 2:
            try:
                result["zero_day_system"] = json.loads(zds)
            except (json.JSONDecodeError, TypeError):
                result["zero_day_system_length"] = len(zds)
        return result

    def full_analysis(self) -> dict:
        """Führt eine vollständige Analyse durch (ClamAV-artig)."""
        return {
            "metadata": {
                "database": os.path.basename(self.db_path),
                "analysis_time": datetime.now().isoformat(),
                "db_size_bytes": os.path.getsize(self.db_path),
            },
            "player": self.get_player_state(),
            "computers": self.get_computers(),
            "bank_accounts": self.get_bank_accounts(),
            "mail_accounts": self.get_mail_accounts(),
            "passwords": self.get_passwords(),
            "network_map": self.get_network_map(),
            "web_pages": self.get_web_pages(),
            "files": self.get_files(),
            "logs": self.get_logs(),
            "economy": self.get_economy(),
            "ctfs": self.get_ctfs(),
            "info_gen": self.get_info_gen(),
        }

    def generate_summary(self) -> str:
        """Generiert eine menschenlesbare Zusammenfassung (Terminal)."""
        analysis = self.full_analysis()
        p = analysis["player"]
        lines = []
        lines.append("═" * 58)
        lines.append("  GREYHACK DB ANALYSE — Zusammenfassung")
        lines.append(f"  DB: {analysis['metadata']['database']}")
        lines.append(f"  Zeit: {analysis['metadata']['analysis_time']}")
        lines.append(f"  Grösse: {analysis['metadata']['db_size_bytes'] / 1048576:.2f} MB")
        lines.append("═" * 58)
        lines.append("")

        # Player
        if p.get("player_found"):
            lines.append(f"👤 Player:     {p['nickname']}")
            lines.append(f"   Player-ID:  {p['player_id'][:16]}...")
            lines.append(f"   Computer-ID:{p['computer_id']}")
            lines.append(f"   Game Over:  {'JA ⚠️' if p['game_over'] else 'Nein ✅'}")
            lines.append(f"   Zuletzt:    {p['last_connection']}")
            lines.append(f"   Missions:   {p['missions_raw_length']} Bytes")
            lines.append(f"   Bank-User:  {p['bank_user']}")
            lines.append(f"   Wallet:     {p['wallet_id'][:16]}...")
        else:
            lines.append("👤 Kein Player gefunden!")

        lines.append("")
        lines.append(f"🖥️  Computer:    {len(analysis['computers'])} total")
        for c in analysis['computers']:
            tags = []
            if c['IsPlayer']: tags.append("PLAYER")
            if c['IsRouter']: tags.append("ROUTER")
            if c['IsCTF']:    tags.append("CTF")
            if c['IsRented']: tags.append("RENTED")
            tag_str = f" [{','.join(tags)}]" if tags else ""
            lines.append(f"   - {c['ID'][:32]}{tag_str}")

        lines.append("")
        lines.append(f"🏦 Banken:      {len(analysis['bank_accounts'])} Accounts")
        for b in analysis['bank_accounts']:
            tx = b.get('tx_count', 0)
            lines.append(f"   - {b['User']} ({tx} Transaktionen)")

        lines.append("")
        lines.append(f"📧 Mails:       {len(analysis['mail_accounts'])} Accounts")
        for m in analysis['mail_accounts']:
            mc = m.get('mail_count', 0)
            lines.append(f"   - {m['User']} ({mc} Mails, {m['mail_bytes']} Bytes)")

        lines.append("")
        pwd = analysis['passwords']
        lines.append(f"🔑 Passwörter:  {pwd['total']} (zeige {pwd['samples_shown']})")

        lines.append("")
        nm = analysis['network_map']
        lines.append(f"🌐 Map:         {nm['total_ips']} IPs")
        for t, c in sorted(nm.get('type_distribution', {}).items()):
            lines.append(f"   - {t}: {c}")
        for a, c in sorted(nm.get('access_distribution', {}).items()):
            lines.append(f"   - {a}: {c}")

        lines.append("")
        econ = analysis['economy']
        lines.append(f"💰 Wirtschaft:")
        lines.append(f"   - Coins:   {econ['coins']['count']}")
        lines.append(f"   - Stocks:  {econ['stocks']['count']}")
        lines.append(f"   - Wallets: {econ['wallets']['count']}")

        lines.append("")
        ig = analysis['info_gen']
        if ig:
            lines.append(f"🌍 InfoGen:")
            lines.append(f"   - Seed:    {ig.get('seed')}")
            lines.append(f"   - Clock:   {ig.get('clock')}")
            lines.append(f"   - Exploits:{ig.get('exploits_length')} Bytes")
            lines.append(f"   - Guilds:  {ig.get('guilds_length')} Bytes")

        lines.append("")
        lines.append(f"📄 Files:       {analysis['files']['total']}")
        lines.append(f"📝 Logs:        {analysis['logs']['total']}")
        lines.append(f"🏴 CTFs:        {analysis['ctfs']['count']}")
        lines.append(f"🌐 Webseiten:   {analysis['web_pages']['total']}")
        lines.append("═" * 58)

        return "\n".join(lines)


# ==============================================================================
# CLI
# ==============================================================================

def main():
    parser = argparse.ArgumentParser(
        description="GreyHack DB Analyzer — ClamAV-artige Analyse eines DB-Snapshots",
        formatter_class=argparse.RawDescriptionHelpFormatter,
        epilog="""
Beispiele:
  %(prog)s ~/backups/greyhack/sandbox-latest.db --summary
  %(prog)s ~/backups/greyhack/sandbox-latest.db --json --pretty
  %(prog)s ~/backups/greyhack/sandbox-latest.db --player-only
        """,
    )
    parser.add_argument("database", help="Pfad zum DB-Snapshot (Sandbox-Kopie)")
    parser.add_argument("--json", action="store_true", help="Ausgabe als JSON")
    parser.add_argument("--pretty", action="store_true", help="JSON hübsch formatieren")
    parser.add_argument("--summary", action="store_true", help="Menschliche Zusammenfassung")
    parser.add_argument("--player-only", action="store_true", help="Nur Player-State extrahieren")
    parser.add_argument("--output", "-o", help="Ausgabedatei (statt stdout)")

    args = parser.parse_args()

    if not args.json and not args.summary and not args.player_only:
        args.summary = True  # Default: Zusammenfassung

    try:
        analyzer = GreyHackDBAnalyzer(args.database)
    except FileNotFoundError as e:
        print(f"❌ {e}", file=sys.stderr)
        sys.exit(1)
    except sqlite3.DatabaseError as e:
        print(f"❌ Datenbank-Fehler: {e}", file=sys.stderr)
        sys.exit(2)

    result = None

    if args.player_only:
        result = analyzer.get_player_state()
        result["_metadata"] = {
            "database": os.path.basename(args.database),
            "analysis_time": datetime.now().isoformat(),
        }
    elif args.json:
        result = analyzer.full_analysis()
    else:
        result = analyzer.generate_summary()

    analyzer.close()

    # Ausgabe
    output = ""
    if isinstance(result, str):
        output = result
    elif args.json or args.player_only:
        indent = 2 if args.pretty else None
        output = json.dumps(result, indent=indent, default=str, ensure_ascii=False)
    else:
        output = str(result)

    if args.output:
        with open(args.output, "w", encoding="utf-8") as f:
            f.write(output)
            if not output.endswith("\n"):
                f.write("\n")
        print(f"✅ Geschrieben: {args.output} ({len(output)} Bytes)")
    else:
        print(output)


if __name__ == "__main__":
    main()
