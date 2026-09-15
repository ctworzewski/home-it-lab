# Windows Update Automation z PowerShell i n8n

> Automatyczne sprawdzanie, instalowanie i raportowanie aktualizacji
> Windows z wykorzystaniem PowerShell, Windows Task Scheduler oraz n8n.

![PowerShell](https://img.shields.io/badge/PowerShell-Automation-5391FE)
![Windows](https://img.shields.io/badge/Windows-11-0078D4)
![n8n](https://img.shields.io/badge/n8n-Workflow_Automation-FF6D5A)
![REST API](https://img.shields.io/badge/REST-API-009688)
![JSON](https://img.shields.io/badge/Data-JSON-555555)

## O projekcie

Projekt jest częścią mojego **Home IT Lab** i przedstawia kompletną
automatyzację procesu Windows Update.

Windows Task Scheduler uruchamia skrypty PowerShell z podwyższonymi
uprawnieniami. Skrypty komunikują się z Windows Update przez COM API, a
następnie przesyłają wynik wykonania w formacie JSON przez HTTPS do
mojej instancji n8n dostępnej pod adresem:

**https://n8n.tworzewski.pl**

n8n odbiera raport przez webhook, analizuje otrzymane dane i wysyła
administratorowi odpowiednie powiadomienie e-mail.

Projekt składa się z dwóch głównych procesów:

-   **CHECK** --- sprawdzanie dostępności aktualizacji Windows i
    raportowanie wyniku,
-   **INSTALL** --- pobieranie i instalowanie aktualizacji, analiza
    wyniku, wykrywanie wymaganego restartu i raportowanie rezultatu.

## Architektura

``` text
Windows Task Scheduler
          |
          v
      PowerShell
          |
          v
 Windows Update COM API
          |
          | HTTPS POST / JSON
          v
 n8n.tworzewski.pl
      Webhook
          |
          v
   Analiza statusu
       /     \
      /       \
 SUCCESS     FAILED
      \       /
       \     /
    Raport e-mail
```

## Jak to działa?

1.  **Windows Task Scheduler** automatycznie uruchamia skrypt PowerShell
    z podwyższonymi uprawnieniami.
2.  **PowerShell** komunikuje się z Windows Update COM API i wykonuje
    operację CHECK lub INSTALL.
3.  Wynik działania jest budowany w formacie JSON.
4.  Raport trafia przez HTTPS POST do webhooka na **n8n.tworzewski.pl**.
5.  **n8n** analizuje otrzymane dane i wysyła odpowiednie powiadomienie
    e-mail.
6.  Workflow INSTALL dodatkowo raportuje wynik instalacji oraz
    informację o wymaganym restarcie.

------------------------------------------------------------------------

## Windows Update - CHECK

Workflow **CHECK** odpowiada za automatyczne monitorowanie dostępności
aktualizacji Windows.

Skrypt PowerShell wyszukuje oczekujące aktualizacje i przygotowuje
raport zawierający m.in.:

-   nazwę hosta,
-   datę wykonania,
-   liczbę dostępnych aktualizacji,
-   listę znalezionych aktualizacji.

Raport jest następnie wysyłany do n8n przez webhook.

### Workflow n8n

![Windows Update CHECK workflow](screenshots/WindowsUpdate-CHECK.png)

### Powiadomienie e-mail

Po wykryciu dostępnych aktualizacji n8n wysyła administratorowi raport
zawierający informacje o komputerze oraz dostępnych aktualizacjach.

![Windows Update CHECK -
Email](screenshots/WindowsUpdate-CHECK-Email.png)

------------------------------------------------------------------------

## Windows Update - INSTALL

Workflow **INSTALL** odpowiada za pobieranie i instalowanie aktualizacji
oraz raportowanie wyniku operacji.

Skrypt PowerShell:

-   wyszukuje dostępne aktualizacje,
-   akceptuje wymagane EULA,
-   pobiera aktualizacje,
-   instaluje aktualizacje,
-   analizuje `ResultCode` oraz `HRESULT`,
-   sprawdza, czy wymagany jest restart,
-   przygotowuje raport JSON,
-   przesyła wynik do n8n.

Po odebraniu raportu n8n sprawdza status operacji i kieruje wykonanie do
odpowiedniej ścieżki:

``` text
                +--> SUCCESS --> Send Success Report
Webhook --> IF -|
                +--> FAILED  --> Send Failure Report
```

### Workflow n8n

![Windows Update INSTALL
workflow](screenshots/WindowsUpdate-INSTALL.png)

### Raport po instalacji

Po zakończeniu procesu administrator otrzymuje raport zawierający status
operacji, liczbę zainstalowanych aktualizacji oraz informację o
wymaganym restarcie.

![Windows Update INSTALL -
Email](screenshots/WindowsUpdate-INSTALL-Email.png)

------------------------------------------------------------------------

## Komunikacja PowerShell z n8n

PowerShell przesyła wynik wykonania metodą **HTTP POST** do webhooka
n8n.

``` text
PowerShell
    |
    | HTTPS POST
    | Content-Type: application/json
    v
n8n Webhook
```

Przykładowy raport:

``` json
{
  "host": "WINDOWS-CLIENT",
  "date": "2026-09-15 09:35:08",
  "status": "SUCCESS",
  "found": 2,
  "installed": 2,
  "resultCode": 2,
  "rebootRequired": true,
  "error": "",
  "updates": []
}
```

Dzięki takiemu podziałowi:

-   **PowerShell** odpowiada za operacje wykonywane w systemie Windows,
-   **Windows Update COM API** odpowiada za obsługę aktualizacji,
-   **n8n** odpowiada za logikę workflow i raportowanie,
-   **HTTPS Webhook** łączy obie części automatyzacji.

## Automatyczne uruchamianie

Skrypty działają bezobsługowo dzięki **Windows Task Scheduler**.

Przykładowa akcja:

``` powershell
powershell.exe -NoProfile -ExecutionPolicy Bypass -File "C:\Scripts\WindowsUpdate-Install.ps1"
```

Zadanie instalujące aktualizacje powinno działać z opcją:

> **Run with highest privileges**

Podwyższone uprawnienia są wymagane do wykonywania operacji związanych z
instalacją aktualizacji Windows.

## Struktura projektu

``` text
windows-update-automation/
├── scripts/
│   ├── WindowsUpdate-Check.ps1
│   └── WindowsUpdate-Install.ps1
├── workflows/
│   ├── windows-update-check.json
│   └── windows-update-install.json
├── screenshots/
│   ├── WindowsUpdate-CHECK.png
│   ├── WindowsUpdate-INSTALL.png
│   ├── WindowsUpdate-CHECK-Email.png
│   └── WindowsUpdate-INSTALL-Email.png
└── README.md
```

-   `scripts/` --- skrypty PowerShell odpowiedzialne za obsługę Windows
    Update i raportowanie do n8n,
-   `workflows/` --- eksporty workflow n8n dla procesów CHECK i INSTALL,
-   `screenshots/` --- zrzuty workflow oraz przykładowych powiadomień
    e-mail.

## Bezpieczeństwo

Repozytorium nie powinno zawierać danych uwierzytelniających ani
sekretów.

Przed publikacją należy zweryfikować i w razie potrzeby usunąć:

-   hasła,
-   tokeny API,
-   dane uwierzytelniające,
-   prywatne adresy IP,
-   pełne adresy webhooków zawierające niepubliczne identyfikatory,
-   inne dane, które nie powinny być publicznie dostępne.

Publiczny adres instancji n8n używanej w projekcie:

``` text
https://n8n.tworzewski.pl
```

Dane dostępowe do SMTP i innych usług powinny być przechowywane jako
**Credentials w n8n**, a nie bezpośrednio w skryptach lub definicjach
workflow.

## Dalszy rozwój

Projekt można rozbudować m.in. o:

-   obsługę wielu komputerów Windows,
-   maintenance windows,
-   historię wykonanych aktualizacji,
-   centralny dashboard stanu aktualizacji,
-   zbiorcze raportowanie,
-   obsługę restartu z uwzględnieniem aktywnych użytkowników,
-   integrację z Zabbix,
-   integrację z Wazuh,
-   automatyczną analizę błędów,
-   automatyczną remediację.

## Cel projektu

Projekt powstał w ramach mojego **Home IT Lab** jako praktyczne
ćwiczenie łączące administrację systemami Windows z automatyzacją.

Główne technologie i mechanizmy wykorzystane w projekcie:

**PowerShell + Windows Update + Task Scheduler + REST/Webhook + JSON +
n8n**

Projekt pozwala rozwijać praktyczne umiejętności związane z
administracją Windows, automatyzacją procesów, komunikacją pomiędzy
systemami, obsługą błędów oraz raportowaniem stanu infrastruktury.
