\# 🔄 Windows Update Automation with n8n



Automatyzacja procesu \*\*sprawdzania, instalowania i raportowania aktualizacji Windows\*\* z wykorzystaniem PowerShell, Windows Task Scheduler oraz n8n.



Projekt działa bezobsługowo — Harmonogram zadań uruchamia skrypt PowerShell, który komunikuje się z Windows Update, a wynik operacji przesyłany jest przez webhook do n8n.



n8n analizuje wynik i wysyła administratorowi odpowiednie powiadomienie e-mail.



\---



\## 🧰 Technologie



`PowerShell` • `Windows Update API` • `Task Scheduler` • `n8n` • `REST API` • `Webhook` • `JSON` • `SMTP`



\---



\## 🏗️ Architektura



```text

┌──────────────────────────┐

│  Windows Task Scheduler  │

└────────────┬─────────────┘

&#x20;            │

&#x20;            ▼

┌──────────────────────────┐

│        PowerShell        │

│                          │

│  CHECK / INSTALL         │

└────────────┬─────────────┘

&#x20;            │

&#x20;            ▼

┌──────────────────────────┐

│   Windows Update API     │

└────────────┬─────────────┘

&#x20;            │

&#x20;            │ HTTPS POST / JSON

&#x20;            ▼

┌──────────────────────────┐

│       n8n Webhook        │

└────────────┬─────────────┘

&#x20;            │

&#x20;            ▼

&#x20;       ┌─────────┐

&#x20;       │   IF    │

&#x20;       └────┬────┘

&#x20;         ┌──┴──┐

&#x20;         ▼     ▼

&#x20;     SUCCESS  FAILED

&#x20;         │     │

&#x20;         └──┬──┘

&#x20;            ▼

&#x20;     📧 Email Report

```



\---



\# 🔍 Windows Update - CHECK



Workflow odpowiada za sprawdzanie, czy na komputerze dostępne są nowe aktualizacje Windows.



PowerShell:



\- łączy się z Windows Update API,

\- wyszukuje dostępne aktualizacje,

\- tworzy raport JSON,

\- przesyła wynik do webhooka n8n,

\- n8n wysyła powiadomienie, jeżeli aktualizacje są dostępne.



\### Workflow n8n



!\[Windows Update CHECK](screenshots/WindowsUpdate-CHECK.png)



\---



\# ⚙️ Windows Update - INSTALL



Workflow odpowiada za automatyczną instalację aktualizacji.



Proces:



1\. PowerShell wyszukuje aktualizacje.

2\. Akceptuje wymagane EULA.

3\. Pobiera aktualizacje.

4\. Instaluje je przez Windows Update API.

5\. Analizuje `ResultCode` oraz `HRESULT`.

6\. Sprawdza, czy wymagany jest restart.

7\. Wysyła raport JSON do n8n.

8\. n8n rozdziela wynik na `SUCCESS` lub `FAILED`.

9\. Administrator otrzymuje raport e-mail.

10\. Jeżeli wymagany jest restart, system może zostać automatycznie uruchomiony ponownie.



\### Workflow n8n



!\[Windows Update INSTALL](screenshots/WindowsUpdate-INSTALL.png)



\---



\## 🔗 Komunikacja PowerShell → n8n



PowerShell przesyła wynik wykonania przez \*\*HTTP POST\*\* do webhooka n8n.



Przykładowy payload:



```json

{

&#x20; "host": "W11-TEST1",

&#x20; "date": "2026-09-15 09:35:08",

&#x20; "status": "SUCCESS",

&#x20; "found": 2,

&#x20; "installed": 2,

&#x20; "resultCode": 2,

&#x20; "rebootRequired": true

}

```



Dzięki temu PowerShell odpowiada za operacje systemowe, natomiast n8n pełni rolę warstwy automatyzacji i raportowania.



\---



\## ⏱️ Automatyczne uruchamianie



Skrypt uruchamiany jest przez \*\*Windows Task Scheduler\*\*.



Przykładowa akcja:



```powershell

powershell.exe -NoProfile -ExecutionPolicy Bypass -File "C:\\Scripts\\WindowsUpdate-Install.ps1"

```



Zadanie uruchamiane jest z opcją:



> \*\*Run with highest privileges\*\*



Jest to wymagane, ponieważ instalacja aktualizacji Windows wymaga podwyższonych uprawnień.



\---



\## 📂 Struktura projektu



```text

windows-update-automation/

│

├── scripts/

│   ├── WindowsUpdate-Check.ps1

│   └── WindowsUpdate-Install.ps1

│

├── workflows/

│   ├── windows-update-check.json

│   └── windows-update-install.json

│

├── screenshots/

│   ├── WindowsUpdate-CHECK.png

│   └── WindowsUpdate-INSTALL.png

│

└── README.md

```



\---



\## 🔐 Bezpieczeństwo



Publiczna wersja projektu nie zawiera:



\- danych uwierzytelniających,

\- haseł,

\- tokenów API,

\- prywatnych adresów webhooków,

\- danych SMTP.



Adres webhooka powinien zostać dostosowany do własnego środowiska:



```powershell

$WebhookUrl = "https://n8n.example.com/webhook/windows-update-install"

```



\---



\## 🚀 Dalszy rozwój



Projekt można rozbudować o:



\- obsługę wielu komputerów,

\- centralny dashboard aktualizacji,

\- historię instalacji,

\- maintenance windows,

\- integrację z Zabbix,

\- integrację z Wazuh,

\- automatyczną analizę błędów,

\- automatyczną remediację,

\- zbiorczy raport stanu aktualizacji infrastruktury.



\---



\## 🎯 Cel projektu



Projekt jest częścią mojego \*\*Home IT Lab\*\* i służy do praktycznej nauki automatyzacji administracji systemami Windows.



Głównym celem było połączenie klasycznej administracji Windows z nowoczesnym podejściem opartym o \*\*PowerShell, API, webhooki i n8n\*\*.

