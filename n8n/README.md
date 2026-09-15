# ⚙️ n8n -- IT Infrastructure Automation

> Automatyzacje infrastruktury IT tworzone w **n8n** w ramach mojego
> Home IT Lab.

Repozytorium zawiera praktyczne projekty łączące monitoring,
administrację systemami Windows, PowerShell, webhooki, API oraz lokalne
modele LLM.

Głównym założeniem jest automatyzacja powtarzalnych zadań
administracyjnych oraz budowa mechanizmów:

**Detect → Analyze → Remediate → Verify → Escalate**

------------------------------------------------------------------------

## 🧰 Technologie

![n8n](https://img.shields.io/badge/n8n-Workflow_Automation-FF6D5A)
![PowerShell](https://img.shields.io/badge/PowerShell-Automation-5391FE)
![Windows](https://img.shields.io/badge/Windows-Administration-0078D4)
![Zabbix](https://img.shields.io/badge/Zabbix-Monitoring-D40000)
![Ollama](https://img.shields.io/badge/Ollama-Local_LLM-333333)
![JSON](https://img.shields.io/badge/Data-JSON-555555)

W projektach wykorzystywane są m.in.:

-   n8n,
-   PowerShell,
-   Windows,
-   Zabbix,
-   SSH,
-   REST API,
-   Webhooki,
-   JSON,
-   Ollama / lokalne modele LLM,
-   SMTP / powiadomienia e-mail.

------------------------------------------------------------------------

# 🚀 Projekty

## 1. Zabbix Agent Auto-Remediation

**Status:** ✅ działa / przetestowane

Automatyzacja reagująca na niedostępność usługi **Zabbix Agent** na
komputerze Windows.

Zabbix przekazuje zdarzenie do n8n przez webhook. Workflow wykonuje
zdalną diagnostykę przez SSH i PowerShell, podejmuje próbę
automatycznego uruchomienia usługi, a następnie weryfikuje rezultat.

Jeżeli naprawa się nie powiedzie, dane diagnostyczne mogą zostać
przekazane do lokalnego modelu LLM przez **Ollama**, który przygotowuje
rekomendacje dla administratora.

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
Próba naprawy
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
    E-mail
```

### Główne elementy

-   wykrycie problemu przez Zabbix,
-   przekazanie zdarzenia do n8n,
-   zdalne wykonanie PowerShell,
-   próba uruchomienia usługi,
-   weryfikacja stanu usługi,
-   diagnostyka po nieudanej naprawie,
-   analiza przez lokalny LLM,
-   powiadomienie administratora.

➡️ **[Dokumentacja projektu](zabbix-auto-remediation/README.md)**

------------------------------------------------------------------------

## 2. Windows Update Automation

**Status:** ✅ działa / przetestowane

Automatyzacja obsługi aktualizacji Windows wykorzystująca **PowerShell,
Windows Task Scheduler oraz n8n**.

Projekt zawiera dwa niezależne procesy:

-   **CHECK** --- monitoruje dostępność aktualizacji i wysyła raport,
-   **INSTALL** --- pobiera i instaluje aktualizacje, analizuje wynik,
    wykrywa wymagany restart i raportuje rezultat.

CHECK oraz INSTALL są niezależnymi zadaniami. Każdy proces posiada
własny skrypt PowerShell, własny webhook n8n i może być uruchamiany
osobno przez Windows Task Scheduler.

``` text
           Windows Update Automation
                    |
          +---------+---------+
          |                   |
          v                   v
        CHECK               INSTALL
          |                   |
          v                   v
     PowerShell          PowerShell
          |                   |
          v                   v
   Windows Update       Windows Update
          |                   |
          v                   v
     n8n Webhook          n8n Webhook
          |                   |
          v                   v
   Raport e-mail       SUCCESS / FAILED
                              |
                              v
                         Raport e-mail
```

### Główne elementy

-   Windows Update COM API,
-   PowerShell,
-   Windows Task Scheduler,
-   osobne workflow CHECK i INSTALL,
-   HTTPS POST / JSON,
-   webhooki n8n,
-   analiza `ResultCode` i `HRESULT`,
-   wykrywanie wymaganego restartu,
-   raportowanie e-mail.

➡️ **[Dokumentacja projektu](windows-update-automation/README.md)**

------------------------------------------------------------------------

# 🏗️ Architektura Home IT Lab

n8n pełni rolę warstwy automatyzacji łączącej różne elementy
laboratorium.

``` text
         Monitoring / Windows
                  |
          +-------+-------+
          |               |
          v               v
       Zabbix       Windows Scripts
          |               |
          +-------+-------+
                  |
                  v
             Webhook / API
                  |
                  v
                 n8n
                  |
        +---------+---------+
        |         |         |
        v         v         v
   PowerShell    SSH     Ollama / LLM
        |         |         |
        +---------+---------+
                  |
                  v
        Raport / Remediacja
                  |
                  v
            Administrator
```

n8n nie zastępuje systemów monitoringu ani narzędzi administracyjnych.
Pełni rolę warstwy integracyjnej i wykonawczej pomiędzy nimi.

------------------------------------------------------------------------

## 🤖 Lokalny LLM

W części automatyzacji wykorzystywany jest lokalny model LLM uruchamiany
przez **Ollama**.

Aktualnie używany model:

``` text
gpt-oss:20b
```

LLM pełni przede wszystkim rolę warstwy wspomagającej diagnostykę.

Może przygotowywać:

-   prawdopodobną przyczynę problemu,
-   sugerowaną kolejność diagnostyki,
-   przykładowe polecenia PowerShell,
-   rekomendacje dalszych działań,
-   ocenę konieczności ręcznej interwencji.

Model nie otrzymuje bezpośredniej możliwości wykonywania dowolnych
poleceń administracyjnych.

------------------------------------------------------------------------

## 🔐 Założenia bezpieczeństwa

Automatyzacje są projektowane z rozdzieleniem logiki wykonawczej od
warstwy analitycznej.

``` text
Monitoring / System
        |
        v
   Dane techniczne
        |
        v
       n8n
        |
        v
Kontrolowana logika
        |
        +-------> PowerShell / SSH
        |
        +-------> Ollama / LLM
                     |
                     v
                Rekomendacja
```

Najważniejsze założenia:

-   dane uwierzytelniające nie są przechowywane bezpośrednio w
    publicznych skryptach,
-   Credentials usług przechowywane są w n8n,
-   LLM służy przede wszystkim do analizy i rekomendacji,
-   działania administracyjne wykonywane są przez kontrolowaną logikę
    workflow,
-   projekty publikowane w repozytorium nie powinny zawierać haseł,
    tokenów ani innych sekretów.

------------------------------------------------------------------------

## 📁 Struktura katalogu

``` text
n8n/
├── README.md
├── zabbix-auto-remediation/
│   ├── README.md
│   ├── workflow.json
│   └── screenshots/
└── windows-update-automation/
    ├── README.md
    ├── scripts/
    ├── workflows/
    └── screenshots/
```

Każdy projekt posiada własny README zawierający szczegółowy opis
działania, architekturę oraz przykłady.

------------------------------------------------------------------------

## 🗺️ Plan rozwoju

Kolejne planowane kierunki rozwoju Home IT Lab:

-   dalsza automatyzacja diagnostyki Windows,
-   monitoring i automatyczna obsługa problemów z miejscem na dyskach,
-   diagnostyka wykorzystania CPU i RAM,
-   integracja alertów Wazuh z n8n,
-   klasyfikacja zdarzeń przez lokalny LLM,
-   automatyczne tworzenie raportów incydentów,
-   historia wykonanych działań Auto-Remediation,
-   centralne raportowanie stanu aktualizacji Windows,
-   rozwój mechanizmów eskalacji do administratora.

------------------------------------------------------------------------

## 🎯 Cel

Celem laboratorium jest praktyczna nauka i testowanie:

-   monitoringu infrastruktury,
-   automatyzacji IT,
-   PowerShell,
-   SSH,
-   REST API i webhooków,
-   Auto-Remediation,
-   diagnostyki systemów Windows,
-   integracji lokalnych modeli LLM,
-   automatyzacji reakcji na zdarzenia infrastrukturalne.

Docelowy kierunek rozwoju:

**Detect → Analyze → Remediate → Verify → Escalate**
