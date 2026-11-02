#!/usr/bin/env python3
"""Home IT Lab: raporty OpenCanary Gmail (szablon, bez sekretow)."""
import json
import logging
import os
import smtplib
import ssl
import time
from collections import defaultdict
from email.message import EmailMessage
from pathlib import Path

LOG = Path(os.getenv("OPENCANARY_LOG", "/var/tmp/opencanary.log"))
SENDER = os.environ["SMTP_SENDER"]
RECIPIENT = os.environ["SMTP_RECIPIENT"]
SMTP_HOST = os.getenv("SMTP_HOST", "smtp.gmail.com")
SMTP_PORT = int(os.getenv("SMTP_PORT", "587"))
PASSWORD_FILE = Path(os.getenv("SMTP_PASSWORD_FILE", "/etc/opencanaryd/secrets/gmail-password"))
SCAN_WINDOW, SCAN_IDLE, MIN_PORTS, SCAN_COOLDOWN = 60, 12, 5, 60
EVENT_COOLDOWN = 60
EVENTS = {2000: "Proba logowania FTP", 3001: "Proba logowania HTTP", 4002: "Proba logowania SSH", 14001: "Interakcja RDP"}
scans = defaultdict(list)
last_scan_alert = {}
last_event_alert = {}
logging.basicConfig(level=logging.INFO, format="%(asctime)s %(levelname)s %(message)s")


def clean(value):
    return "".join(c if c.isprintable() else " " for c in str(value))[:160]


def send_email(subject, body):
    mail = EmailMessage()
    mail["From"] = SENDER
    mail["To"] = RECIPIENT
    mail["Subject"] = subject
    mail.set_content(body)
    password = PASSWORD_FILE.read_text(encoding="utf-8").strip()
    with smtplib.SMTP(SMTP_HOST, SMTP_PORT, timeout=15) as smtp:
        smtp.ehlo()
        smtp.starttls(context=ssl.create_default_context())
        smtp.ehlo()
        smtp.login(SENDER, password)
        smtp.send_message(mail)


def process(event):
    try:
        code = int(event.get("logtype", 0))
    except (TypeError, ValueError):
        return
    source = str(event.get("src_host") or "")
    if not source:
        return
    now = time.monotonic()
    if code == 5001:
        try:
            port = int(event.get("dst_port", -1))
        except (TypeError, ValueError):
            return
        if 1 <= port <= 65535:
            scans[(source, str(event.get("dst_host") or ""))].append((now, port))
        return
    if code not in EVENTS:
        return
    key = (source, code)
    if now - last_event_alert.get(key, -1e9) < EVENT_COOLDOWN:
        return
    data = event.get("logdata") or {}
    if not isinstance(data, dict):
        data = {}
    body = (f"ALERT OPENCANARY\n\nZdarzenie: {EVENTS[code]}\n"
            f"Czas: {clean(event.get('local_time_adjusted', '-'))}\n"
            f"Zrodlo: {clean(source)}\nCel: {clean(event.get('dst_host', '-'))}\n"
            f"Port docelowy: {clean(event.get('dst_port', '-'))}\n"
            f"Login: {clean(data.get('USERNAME', '-'))}\n"
            "Hasla celowo pominieto.\n")
    send_email(f"[HONEYPOT] {EVENTS[code]}", body)
    last_event_alert[key] = now
    logging.info("Wyslano alert typ=%s z IP=%s", code, clean(source))


def flush_scans():
    now = time.monotonic()
    for key, entries in list(scans.items()):
        entries = [(t, p) for t, p in entries if now - t <= SCAN_WINDOW]
        if not entries:
            scans.pop(key, None)
            continue
        scans[key] = entries
        if now - entries[-1][0] < SCAN_IDLE:
            continue
        ports = sorted({p for _, p in entries})
        if len(ports) < MIN_PORTS or now - last_scan_alert.get(key, -1e9) < SCAN_COOLDOWN:
            scans.pop(key, None)
            continue
        source, destination = key
        body = ("HONEYPOT - RAPORT SKANOWANIA\n\n"
                f"Zrodlo: {clean(source)}\nCel: {clean(destination)}\n"
                f"Zaobserwowane porty: {len(ports)}\nPakiety: {len(entries)}\n"
                f"Porty TCP: {', '.join(map(str, ports))}\n\n"
                "Lista obejmuje wyłącznie zaobserwowane porty, nie caly zakres Nmap.\n")
        send_email("[HONEYPOT] Wykryto skanowanie portow", body)
        last_scan_alert[key] = now
        scans.pop(key, None)
        logging.info("Raport skanowania: IP=%s porty=%s", clean(source), len(ports))


def watch():
    logging.info("Uruchomiono OpenCanary Mail Alerts")
    stream, inode = None, None
    while True:
        try:
            stat = LOG.stat()
            if stream is None or stat.st_ino != inode:
                if stream:
                    stream.close()
                stream = LOG.open("r", encoding="utf-8")
                inode = stat.st_ino
                stream.seek(0, 2)  # tylko zdarzenia od momentu uruchomienia
            line = stream.readline()
            if line:
                try:
                    process(json.loads(line))
                except (ValueError, TypeError):
                    logging.warning("Pominieto niepoprawny wpis JSON")
                except (OSError, smtplib.SMTPException) as exc:
                    logging.error("Blad wysylki: %s", type(exc).__name__)
            else:
                if LOG.stat().st_size < stream.tell():
                    stream.seek(0)
                try:
                    flush_scans()
                except (OSError, smtplib.SMTPException) as exc:
                    logging.error("Blad raportu: %s", type(exc).__name__)
                time.sleep(1)
        except OSError as exc:
            logging.error("Blad odczytu logu: %s", type(exc).__name__)
            if stream:
                stream.close()
                stream = None
            time.sleep(5)


if __name__ == "__main__":
    watch()
