# 🏠 Home IT Lab

> Praktyczne laboratorium do nauki administracji systemami, sieci,
> cyberbezpieczeństwa, monitoringu oraz automatyzacji infrastruktury IT.

Repozytorium dokumentuje projekty, konfiguracje, skrypty, workflow oraz
runbooki tworzone i testowane w moim **Home IT Lab**.

Główny kierunek rozwoju środowiska to połączenie klasycznej
administracji IT z monitoringiem, automatyzacją oraz lokalnymi modelami
LLM.

------------------------------------------------------------------------

## 🧰 Technologie

![Windows
Server](https://img.shields.io/badge/Windows_Server-2025-0078D4)
![PowerShell](https://img.shields.io/badge/PowerShell-Automation-5391FE)
![n8n](https://img.shields.io/badge/n8n-Workflow_Automation-FF6D5A)
![Zabbix](https://img.shields.io/badge/Zabbix-Monitoring-D40000)
![Wazuh](https://img.shields.io/badge/Wazuh-SIEM-005571)
![FortiGate](https://img.shields.io/badge/FortiGate-Security-EE3124)
![Hyper-V](https://img.shields.io/badge/Hyper--V-Virtualization-0078D4)
![Ollama](https://img.shields.io/badge/Ollama-Local_LLM-333333)

Środowisko obejmuje m.in.:

-   **Windows Server 2025** --- Active Directory, DNS, GPO,
-   **Hyper-V** --- wirtualizacja środowiska laboratoryjnego,
-   **Windows 11** --- hosty klienckie i testy automatyzacji,
-   **FortiGate** --- firewall, routing i segmentacja sieci,
-   **VLAN** --- separacja i organizacja ruchu sieciowego,
-   **Zabbix** --- monitoring infrastruktury,
-   **Wazuh** --- monitoring bezpieczeństwa / SIEM,
-   **n8n** --- automatyzacja i integracja systemów,
-   **PowerShell** --- administracja i automatyzacja Windows,
-   **SSH / OpenSSH** --- zdalne wykonywanie operacji,
-   **Docker** --- konteneryzacja usług,
-   **Ollama / lokalne LLM** --- wspomaganie diagnostyki,
-   **Ubiquiti UniFi** --- infrastruktura sieciowa.

------------------------------------------------------------------------

# 🚀 Projekty

## 1. Zabbix Agent Auto-Remediation

**Status:** ✅ działa / przetestowane

Automatyczna reakcja na problemy z usługą **Zabbix Agent** na
komputerach Windows.

Zabbix wykrywa problem i przekazuje zdarzenie przez webhook do n8n.
Workflow wykonuje zdalną diagnostykę przez SSH i PowerShell, podejmuje
próbę automatycznej naprawy i weryfikuje rezultat.

``` text
Zabbix
   |
   v
Webhook
   |
   v
  n8n
   |
   v
SSH / PowerShell
   |
   v
Auto-Remediation
   |
   v
Weryfikacja
  / \
 /   \
OK   FAILED
 |      |
 |      v
 |   Diagnostyka
 |      |
 |      v
 |   Ollama / LLM
 |      |
 v      v
 Raport e-mail
```

**Zakres projektu:**

-   wykrywanie awarii przez Zabbix,
-   webhook Zabbix → n8n,
-   zdalne wykonywanie PowerShell przez SSH,
-   automatyczna próba uruchomienia usługi,
-   weryfikacja rezultatu,
-   diagnostyka Windows,
-   analiza problemu przez lokalny LLM,
-   raport e-mail dla administratora.

➡️ **[Dokumentacja Zabbix
Auto-Remediation](n8n/zabbix-auto-remediation/README.md)**

------------------------------------------------------------------------

## 2. Windows Update Automation

**Status:** ✅ działa / przetestowane

Automatyzacja sprawdzania oraz instalowania aktualizacji Windows z
wykorzystaniem **PowerShell, Windows Task Scheduler i n8n**.

Projekt zawiera dwa niezależne procesy:

-   **CHECK** --- sprawdza dostępność aktualizacji i wysyła raport,
-   **INSTALL** --- instaluje aktualizacje, analizuje rezultat oraz
    wykrywa wymagany restart.

CHECK i INSTALL posiadają osobne skrypty PowerShell, osobne webhooki n8n
i mogą być uruchamiane niezależnie.

``` text
       Windows Update Automation
                 |
        +--------+--------+
        |                 |
        v                 v
      CHECK             INSTALL
        |                 |
        v                 v
   PowerShell        PowerShell
        |                 |
        v                 v
 Windows Update      Windows Update
        |                 |
        v                 v
   n8n Webhook        n8n Webhook
        |                 |
        v                 v
 Raport e-mail      SUCCESS / FAILED
                          |
                          v
                    Raport e-mail
```

**Zakres projektu:**

-   Windows Update COM API,
-   PowerShell,
-   Windows Task Scheduler,
-   HTTP POST / JSON,
-   webhooki n8n,
-   analiza `ResultCode` i `HRESULT`,
-   wykrywanie wymaganego restartu,
-   raportowanie e-mail.

➡️ **[Dokumentacja Windows Update
Automation](n8n/windows-update-automation/README.md)**

------------------------------------------------------------------------

# 📚 Runbooki

Repozytorium zawiera również praktyczne procedury administracyjne
opisujące diagnostykę i rozwiązywanie problemów.

Aktualnie udokumentowane zostały m.in.:

-   konfiguracja **Apache HTTPS**,
-   instalacja i diagnostyka **Zabbix Agent**.

➡️ **[Przejdź do katalogu runbooks](runbooks/)**

------------------------------------------------------------------------

## 🏗️ Kierunek architektury

Home IT Lab rozwijany jest w kierunku środowiska, w którym monitoring
wykrywa zdarzenie, automatyzacja wykonuje kontrolowaną reakcję, a
administrator otrzymuje wynik oraz dane diagnostyczne.

``` text
Monitoring / System
        |
        v
   Zdarzenie / Alert
        |
        v
      Zabbix
        |
        v
   Webhook / API
        |
        v
       n8n
        |
   +----+----+
   |         |
   v         v
PowerShell  SSH
   |         |
   +----+----+
        |
        v
  Remediacja
        |
        v
  Weryfikacja
        |
   +----+----+
   |         |
   v         v
  OK      Diagnostyka
             |
             v
        Ollama / LLM
             |
             v
       Administrator
```

Docelowy model działania:

**Detect → Analyze → Remediate → Verify → Escalate**

------------------------------------------------------------------------

## 📁 Struktura repozytorium

``` text
home-it-lab/
├── n8n/
│   ├── README.md
│   ├── zabbix-auto-remediation/
│   └── windows-update-automation/
├── runbooks/
└── README.md
```

Repozytorium będzie rozwijane wraz z kolejnymi projektami
laboratoryjnymi. Każdy większy projekt posiada własny README z opisem
architektury, konfiguracji i działania.

------------------------------------------------------------------------

## 🗺️ Plan rozwoju

Kolejne kierunki rozwoju laboratorium:

-   dalsza automatyzacja administracji Windows,
-   integracja alertów **Wazuh → n8n**,
-   automatyczna analiza zdarzeń bezpieczeństwa,
-   monitoring i remediacja problemów z CPU, RAM oraz miejscem na
    dyskach,
-   centralne raportowanie stanu aktualizacji Windows,
-   rozwój automatyzacji opartych o PowerShell,
-   wykorzystanie lokalnego LLM do wspomagania diagnostyki,
-   rozwój dokumentacji i runbooków,
-   dalsza rozbudowa środowiska Active Directory, FortiGate i VLAN.

------------------------------------------------------------------------

## 🎯 Cel laboratorium

Celem Home IT Lab jest praktyczna nauka projektowania, wdrażania,
monitorowania i automatyzowania infrastruktury IT.

Środowisko służy do rozwijania praktycznych umiejętności w obszarach:

**Windows Server • Active Directory • Networking • Cybersecurity •
Monitoring • PowerShell • Automation • n8n • AI/LLM**

Laboratorium pozwala testować integrację klasycznych narzędzi
administracyjnych z automatyzacją oraz lokalnymi modelami AI przed
wykorzystaniem podobnych mechanizmów w większych środowiskach.

------------------------------------------------------------------------

## 🔐 Bezpieczeństwo

Repozytorium przedstawia **środowisko laboratoryjne**.

Przed publikacją konfiguracji, workflow i skryptów usuwane lub
zastępowane są informacje, które nie powinny znaleźć się w publicznym
repozytorium, m.in.:

-   hasła,
-   tokeny API,
-   klucze prywatne,
-   dane uwierzytelniające,
-   prywatne adresy IP,
-   inne sekrety i dane środowiskowe.

Dane dostępowe wykorzystywane przez automatyzacje przechowywane są poza
publicznym kodem, np. jako **Credentials w n8n**.