# Wazuh – Home IT Lab

Repozytorium zawiera moje projekty związane z monitoringiem bezpieczeństwa, analizą zdarzeń Windows, Active Directory, automatyzacją alertów oraz reakcją na incydenty z wykorzystaniem Wazuh.

Głównym celem jest praktyczna nauka:

- Windows Security Logs,
- Active Directory,
- własnych reguł Wazuh,
- korelacji zdarzeń,
- integracji z n8n,
- powiadomień SMTP,
- Sysmon,
- PowerShell Script Block Logging,
- Active Response,
- podstaw Detection Engineering / SOC.

---

## Roadmapa projektów

### ✅ Zakończone

- ✅ [01 – Wykrywanie nieudanych logowań Windows](docs/01-failed-logon-eventviewer.md)
- ✅ [02 – Analiza domyślnej reguły Wazuh dla Event ID 4625](docs/02-failed-logon-default-rule.md)
- ✅ [03 – Własna reguła Wazuh 119100](docs/03-custom-rule-119100.md)
- ✅ [04 – Integracja Wazuh + n8n + SMTP](docs/04-n8n-smtp-integration.md)
- ✅ [05 – Wykrywanie blokady konta Active Directory](docs/05-ad-account-lockout-detection.md)
- ✅ [06 – Privileged Account Logon Detection + PowerShell Correlation](docs/06-privileged-account-logon-detection.md)
- ⬜ 07 – AD Privilege Escalation Detection

### 🚧 W trakcie

- 🚧 [06 – Wykrywanie logowań na konta uprzywilejowane](docs/06-privileged-account-logon-detection.md)

Projekt `06` będzie rozwijany etapami o:

- Sysmon Event ID `1` – Process Create,
- Sysmon Event ID `3` – Network Connection,
- PowerShell Script Block Logging – Event ID `4104`,
- korelację logowania konta uprzywilejowanego z uruchamianymi procesami,
- własne reguły Wazuh,
- integrację z n8n,
- Wazuh Active Response,
- test automatycznego zakończenia procesu,
- test czasowej izolacji hosta w środowisku LAB.

---

## Środowisko LAB

Przykładowe elementy środowiska:

- Windows Server 2025 / Active Directory,
- Windows 11,
- Ubuntu,
- Wazuh Manager,
- Wazuh Agent,
- n8n,
- SMTP,
- Sysmon,
- PowerShell,
- Hyper-V.

---

## Przykładowy przepływ zdarzeń

```text
Windows / Active Directory
        ↓
Security Logs / Sysmon / PowerShell Logs
        ↓
Wazuh
        ↓
Custom Rules / Correlation
        ↓
n8n
        ↓
E-mail / Automatyzacja
        ↓
Active Response
```

---

## Cel repozytorium

Repozytorium ma dokumentować kolejne etapy rozwoju mojego Home IT Lab i pokazywać praktyczne scenariusze związane z bezpieczeństwem środowiska Windows.

Każdy projekt zawiera:

- opis celu,
- konfigurację,
- używane Event ID,
- reguły Wazuh,
- testy,
- screenshoty,
- wnioski,
- możliwe rozszerzenia.

---

## Status

🚧 Repozytorium jest aktywnie rozwijane.

Kolejne projekty i rozszerzenia będą dodawane wraz z rozwojem środowiska LAB.
