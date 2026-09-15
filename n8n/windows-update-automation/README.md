# Windows Update Automation z PowerShell i n8n

> Automatyczne sprawdzanie, instalowanie i raportowanie aktualizacji
> Windows z wykorzystaniem PowerShell, Windows Task Scheduler oraz n8n.

![PowerShell](https://img.shields.io/badge/PowerShell-Automation-5391FE)
![Windows](https://img.shields.io/badge/Windows-11-0078D4)
![n8n](https://img.shields.io/badge/n8n-Workflow_Automation-FF6D5A)
![REST API](https://img.shields.io/badge/REST-API-009688)
![JSON](https://img.shields.io/badge/Data-JSON-555555)

## O projekcie

Projekt jest częścią mojego **Home IT Lab** i przedstawia automatyzację
obsługi Windows Update z wykorzystaniem PowerShell oraz n8n.

Windows Task Scheduler uruchamia skrypty PowerShell z podwyższonymi
uprawnieniami. Skrypty komunikują się z Windows Update przez COM API, a
następnie przesyłają wyniki w formacie JSON przez HTTPS do lokalnej
instancji n8n.

n8n odbiera raporty przez webhooki, analizuje otrzymane dane i wysyła
administratorowi odpowiednie powiadomienia e-mail.

Projekt składa się z dwóch głównych, **niezależnych od siebie
procesów**:

-   **CHECK** --- sprawdza dostępność aktualizacji Windows i raportuje
    wynik,
-   **INSTALL** --- pobiera i instaluje aktualizacje, analizuje wynik
    instalacji, wykrywa wymagany restart i raportuje rezultat.

> **CHECK i INSTALL są dwoma niezależnymi zadaniami.**
>
> Workflow **CHECK nie uruchamia INSTALL** i nie jest wymagany do jego
> działania. Każdy proces posiada własny skrypt PowerShell, własny
> webhook n8n oraz może być uruchamiany niezależnie przez osobne zadanie
> w Windows Task Scheduler.

## Architektura

``` text
                WINDOWS UPDATE AUTOMATION
                          |
              +-----------+-----------+
              |                       |
              v                       v
            CHECK                   INSTALL
              |                       |
              v                       v
      PowerShell CHECK       PowerShell INSTALL
              |                       |
              v                       v
       Windows Update          Windows Update
          COM API                 COM API
              |                       |
              | HTTPS / JSON          | HTTPS / JSON
              v                       v
        n8n Webhook              n8n Webhook
              |                       |
              v                       v
     Dostępne aktualizacje      Analiza statusu
              |                   /       \
              v              SUCCESS     FAILED
       Raport e-mail               \       /
                                    \     /
                                     v   v
                                Raport e-mail
```

Oba procesy korzystają z Windows Update oraz n8n, ale działają
niezależnie i realizują inne zadania.

## Jak to działa?

### CHECK

1.  Windows Task Scheduler uruchamia skrypt **WindowsUpdate-Check.ps1**.
2.  PowerShell sprawdza dostępność aktualizacji przez Windows Update COM
    API.
3.  Skrypt przygotowuje raport JSON.
4.  Raport trafia przez HTTPS POST do webhooka CHECK w n8n.
5.  n8n analizuje liczbę dostępnych aktualizacji.
6.  Administrator otrzymuje powiadomienie e-mail o dostępnych
    aktualizacjach.

### INSTALL

1.  Windows Task Scheduler niezależnie uruchamia skrypt
    **WindowsUpdate-Install.ps1**.
2.  PowerShell wyszukuje, pobiera i instaluje aktualizacje.
3.  Skrypt analizuje wynik instalacji oraz wymaganie restartu.
4.  Powstaje raport JSON z wynikiem operacji.
5.  Raport trafia przez HTTPS POST do osobnego webhooka INSTALL w n8n.
6.  n8n rozpoznaje status `SUCCESS` lub `FAILED`.
7.  Administrator otrzymuje raport e-mail z wynikiem instalacji.

------------------------------------------------------------------------

## Windows Update - CHECK

Workflow **CHECK** odpowiada wyłącznie za monitorowanie dostępności
aktualizacji Windows.

Nie instaluje aktualizacji i nie uruchamia procesu INSTALL.

Skrypt PowerShell wyszukuje oczekujące aktualizacje i przygotowuje
raport zawierający m.in.:

-   nazwę hosta,
-   datę wykonania,
-   liczbę dostępnych aktualizacji,
-   listę znalezionych aktualizacji.

Raport jest następnie wysyłany do dedykowanego webhooka CHECK w n8n.

### Workflow n8n

![Windows Update CHECK workflow](screenshots/WindowsUpdate-CHECK.png)

### Powiadomienie e-mail

Po wykryciu dostępnych aktualizacji n8n wysyła administratorowi raport
zawierający informacje o komputerze oraz dostępnych aktualizacjach.

![Windows Update CHECK -
Email](screenshots/WindowsUpdate-CHECK-Email.png)

------------------------------------------------------------------------

## Windows Update - INSTALL

Workflow **INSTALL** jest osobnym procesem odpowiedzialnym za
instalowanie aktualizacji i raportowanie wyniku operacji.

Nie wymaga wcześniejszego uruchomienia workflow CHECK.

Skrypt PowerShell:

-   wyszukuje dostępne aktualizacje,
-   akceptuje wymagane EULA,
-   pobiera aktualizacje,
-   instaluje aktualizacje,
-   analizuje `ResultCode` oraz `HRESULT`,
-   sprawdza, czy wymagany jest restart,
-   przygotowuje raport JSON,
-   przesyła wynik do dedykowanego webhooka INSTALL w n8n.

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

Każdy proces posiada własny endpoint webhooka w n8n.

``` text
WindowsUpdate-Check.ps1
        |
        | HTTPS POST / JSON
        v
   Webhook CHECK


WindowsUpdate-Install.ps1
        |
        | HTTPS POST / JSON
        v
  Webhook INSTALL
```

Przykładowy raport z procesu INSTALL:

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
-   **HTTPS Webhook** zapewnia komunikację pomiędzy PowerShell i n8n,
-   **CHECK i INSTALL pozostają od siebie niezależne**.

## Automatyczne uruchamianie

Oba procesy mogą być uruchamiane niezależnie przez osobne zadania w
**Windows Task Scheduler**.

Przykładowa akcja dla CHECK:

``` powershell
powershell.exe -NoProfile -ExecutionPolicy Bypass -File "C:\Scripts\WindowsUpdate-Check.ps1"
```

Przykładowa akcja dla INSTALL:

``` powershell
powershell.exe -NoProfile -ExecutionPolicy Bypass -File "C:\Scripts\WindowsUpdate-Install.ps1"
```

Zadanie odpowiedzialne za instalowanie aktualizacji powinno działać z
opcją:

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

-   `scripts/` --- skrypty PowerShell odpowiedzialne za CHECK i INSTALL,
-   `workflows/` --- dwa niezależne eksporty workflow n8n,
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

### Lokalna instancja n8n

W projekcie wykorzystywana jest instancja n8n dostępna pod adresem:

``` text
https://n8n.tworzewski.pl
```

Adres `n8n.tworzewski.pl` jest wykorzystywany wyłącznie w środowisku
lokalnym **Home IT Lab** i nie jest publicznie dostępny z Internetu.

Dostęp do instancji oraz webhooków możliwy jest jedynie z odpowiednio
skonfigurowanej sieci lokalnej.

Dane dostępowe do SMTP i innych usług przechowywane są jako
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