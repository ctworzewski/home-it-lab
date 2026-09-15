\# 🔄 Windows Update Automation with PowerShell \& n8n



Automatyzacja procesu \*\*sprawdzania, instalowania i raportowania aktualizacji Windows\*\* z wykorzystaniem PowerShell, Windows Task Scheduler oraz n8n.



Projekt działa automatycznie — \*\*Windows Task Scheduler\*\* uruchamia skrypt PowerShell, który komunikuje się z Windows Update, a wynik operacji przesyłany jest przez \*\*HTTPS Webhook\*\* do n8n.



n8n analizuje otrzymany raport i wysyła administratorowi odpowiednie powiadomienie e-mail.



\---



\## 🧰 Technologie



!\[PowerShell](https://img.shields.io/badge/PowerShell-Automation-blue)

!\[Windows](https://img.shields.io/badge/Windows-11-blue)

!\[n8n](https://img.shields.io/badge/n8n-Workflow\_Automation-orange)

!\[REST API](https://img.shields.io/badge/REST-API-green)

!\[JSON](https://img.shields.io/badge/Data-JSON-yellow)



\*\*Wykorzystane technologie:\*\*



\- PowerShell

\- Windows Update Agent COM API

\- Windows Task Scheduler

\- n8n

\- REST API

\- HTTPS Webhook

\- JSON

\- SMTP / Email



\---



\## 🏗️ Architektura



```text

┌───────────────────────────┐

│  Windows Task Scheduler   │

└─────────────┬─────────────┘

&#x20;             │

&#x20;             ▼

┌───────────────────────────┐

│        PowerShell         │

│                           │

│      CHECK / INSTALL      │

└─────────────┬─────────────┘

&#x20;             │

&#x20;             ▼

┌───────────────────────────┐

│  Windows Update COM API   │

└─────────────┬─────────────┘

&#x20;             │

&#x20;             │ HTTPS POST / JSON

&#x20;             ▼

┌───────────────────────────┐

│        n8n Webhook        │

└─────────────┬─────────────┘

&#x20;             │

&#x20;             ▼

&#x20;      ┌─────────────┐

&#x20;      │     IF      │

&#x20;      └──────┬──────┘

&#x20;         ┌───┴───┐

&#x20;         │       │

&#x20;         ▼       ▼

&#x20;     SUCCESS   FAILED

&#x20;         │       │

&#x20;         └───┬───┘

&#x20;             │

&#x20;             ▼

&#x20;    Email notification

```



\---



\## 🔍 Windows Update - CHECK



Workflow \*\*CHECK\*\* odpowiada za automatyczne sprawdzanie dostępności nowych aktualizacji Windows.



Skrypt PowerShell:



1\. łączy się z Windows Update,

2\. wyszukuje dostępne aktualizacje,

3\. pobiera informacje o znalezionych aktualizacjach,

4\. tworzy raport w formacie JSON,

5\. przesyła raport przez HTTP POST do webhooka n8n,

6\. n8n analizuje liczbę dostępnych aktualizacji,

7\. w razie potrzeby wysyła administratorowi powiadomienie.



\### Workflow n8n - CHECK



!\[Windows Update CHECK](screenshots/WindowsUpdate-CHECK.png)



\---



\## ⚙️ Windows Update - INSTALL



Workflow \*\*INSTALL\*\* odpowiada za automatyczne pobieranie i instalowanie aktualizacji Windows.



Skrypt PowerShell:



1\. wyszukuje dostępne aktualizacje,

2\. akceptuje wymagane EULA,

3\. tworzy kolekcję aktualizacji do instalacji,

4\. pobiera aktualizacje,

5\. rozpoczyna instalację,

6\. analizuje wynik instalacji,

7\. zapisuje `ResultCode` oraz `HRESULT`,

8\. sprawdza, czy wymagany jest restart,

9\. tworzy raport JSON,

10\. wysyła wynik do n8n przez webhook.



n8n analizuje status otrzymany ze skryptu i kieruje wykonanie do odpowiedniej gałęzi:



```text

&#x20;                 ┌── SUCCESS ──► Success Email

Webhook ──► IF ───┤

&#x20;                 └── FAILED ───► Failure Email

```



\### Workflow n8n - INSTALL



!\[Windows Update INSTALL](screenshots/WindowsUpdate-INSTALL.png)



\---



\## 🔗 PowerShell → n8n



Komunikacja pomiędzy PowerShell a n8n realizowana jest za pomocą \*\*HTTPS Webhook\*\*.



Po wykonaniu operacji skrypt PowerShell wysyła metodą:



```text

HTTP POST

```



raport w formacie:



```text

Content-Type: application/json

```



Przykładowy payload:



```json

{

&#x20; "host": "WINDOWS-CLIENT",

&#x20; "date": "2026-09-15 09:35:08",

&#x20; "status": "SUCCESS",

&#x20; "found": 2,

&#x20; "installed": 2,

&#x20; "resultCode": 2,

&#x20; "rebootRequired": true,

&#x20; "error": "",

&#x20; "updates": \[]

}

```



Dzięki takiemu podziałowi:



\- \*\*PowerShell\*\* odpowiada za operacje wykonywane bezpośrednio w systemie Windows,

\- \*\*Windows Update API\*\* odpowiada za wyszukiwanie, pobieranie i instalowanie aktualizacji,

\- \*\*n8n\*\* odpowiada za logikę workflow oraz raportowanie,

\- \*\*Webhook\*\* zapewnia komunikację pomiędzy hostem Windows a n8n.



\---



\## 🔁 Obsługa restartu



Po zakończeniu instalacji skrypt sprawdza, czy Windows wymaga ponownego uruchomienia.



Sprawdzany jest m.in. wynik zwracany przez Windows Update:



```powershell

$InstallResult.RebootRequired

```



Skrypt może również wykrywać dodatkowe oznaki oczekującego restartu systemu.



Jeżeli restart jest wymagany, informacja:



```json

"rebootRequired": true

```



zostaje przekazana do n8n w raporcie.



W zależności od konfiguracji skrypt może następnie wykonać automatyczny restart systemu.



\---



\## ⏱️ Windows Task Scheduler



Skrypty są uruchamiane automatycznie przez \*\*Windows Task Scheduler\*\*, dzięki czemu proces nie wymaga ręcznego uruchamiania PowerShell.



Przykładowa akcja zadania:



```powershell

powershell.exe -NoProfile -ExecutionPolicy Bypass -File "C:\\Scripts\\WindowsUpdate-Install.ps1"

```



Zadanie instalujące aktualizacje powinno być uruchamiane z opcją:



> \*\*Run with highest privileges\*\*



Podwyższone uprawnienia są wymagane do wykonywania operacji związanych z instalacją aktualizacji Windows.



\---



\## 📧 Raportowanie



Po zakończeniu procesu n8n otrzymuje raport przesłany przez PowerShell.



Workflow rozpoznaje wynik wykonania i może wysłać administratorowi:



\*\*SUCCESS\*\*



```text

Windows Update installation completed successfully.

Installed updates: 2

Reboot required: True

```



lub:



\*\*FAILED\*\*



```text

Windows Update installation failed.

ResultCode: 4

HRESULT: 0xXXXXXXXX

```



Pozwala to monitorować wynik aktualizacji bez konieczności logowania się bezpośrednio do komputera.



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



\### `scripts/`



Skrypty PowerShell odpowiedzialne za obsługę Windows Update i komunikację z n8n.



\### `workflows/`



Eksporty workflow n8n umożliwiające odtworzenie automatyzacji na innej instancji n8n.



\### `screenshots/`



Zrzuty ekranu przedstawiające przygotowane workflow.



\---



\## 🔐 Bezpieczeństwo



Publiczna wersja projektu nie powinna zawierać informacji związanych z rzeczywistym środowiskiem produkcyjnym lub laboratoryjnym.



Przed publikacją należy usunąć lub zastąpić:



\- rzeczywiste adresy webhooków,

\- dane uwierzytelniające,

\- hasła,

\- tokeny API,

\- adresy e-mail,

\- prywatne adresy IP,

\- inne sekrety.



Przykładowy adres webhooka:



```powershell

$WebhookUrl = "https://n8n.example.com/webhook/windows-update-install"

```



Dane dostępowe do SMTP oraz innych usług powinny być przechowywane jako \*\*Credentials w n8n\*\*, a nie bezpośrednio w workflow lub skryptach.



\---



\## 🚀 Możliwy dalszy rozwój



Projekt można rozszerzyć o:



\- obsługę wielu komputerów Windows,

\- centralny dashboard stanu aktualizacji,

\- historię wykonanych instalacji,

\- maintenance windows,

\- opóźnianie restartu dla aktywnych użytkowników,

\- raport zbiorczy dla administratora,

\- integrację z Zabbix,

\- integrację z Wazuh,

\- automatyczną analizę błędów Windows Update,

\- automatyczną remediację,

\- przechowywanie wyników w bazie danych,

\- monitoring komputerów wymagających restartu.



\---



\## 🎯 Cel projektu



Projekt jest częścią mojego \*\*Home IT Lab\*\* i został przygotowany w celu praktycznej nauki automatyzacji administracji systemami Windows.



Głównym założeniem było połączenie klasycznej administracji Windows z narzędziami automatyzacji:



\*\*PowerShell + Windows Update + Task Scheduler + REST/Webhook + n8n\*\*



Projekt pozwala przećwiczyć nie tylko administrację Windows, ale również komunikację pomiędzy systemami, automatyzację procesów oraz monitoring wyniku wykonywanych operacji.

