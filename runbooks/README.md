# 📚 IT Administration Runbooks

> Zbiór praktycznych procedur administracyjnych, diagnostycznych i
> konfiguracyjnych tworzonych oraz testowanych w ramach mojego **Home IT
> Lab**.

Runbooki dokumentują konkretne zadania wykonywane podczas administracji
infrastrukturą IT. Ich celem jest stworzenie uporządkowanej bazy wiedzy
zawierającej sprawdzone procedury, polecenia, konfiguracje oraz kroki
diagnostyczne.

------------------------------------------------------------------------

## 🎯 Założenia

Każdy runbook powinien opisywać konkretny problem lub zadanie
administracyjne w sposób umożliwiający jego późniejsze odtworzenie.

Dokumentacja może zawierać m.in.:

-   cel procedury,
-   wymagania wstępne,
-   konfigurację krok po kroku,
-   polecenia PowerShell / Bash,
-   lokalizacje plików konfiguracyjnych,
-   sposób weryfikacji działania,
-   diagnostykę typowych problemów,
-   uwagi dotyczące bezpieczeństwa.

------------------------------------------------------------------------

## 📂 Kategorie

### 🔐 Certificates

Procedury związane z certyfikatami, HTTPS oraz własnym urzędem
certyfikacji.

  ---------------------------------------------------------------------------------
  Runbook                                       Opis
  --------------------------------------------- -----------------------------------
  [Apache HTTPS -- własne                       Konfiguracja HTTPS dla Apache z
  CA](certificates/apache-https-wlasne-ca.md)   wykorzystaniem własnego urzędu
                                                certyfikacji (CA).

  ---------------------------------------------------------------------------------

### 📊 Monitoring

Procedury związane z monitoringiem infrastruktury oraz agentami
monitorującymi.

  Runbook        Opis
  -------------- ------------------------------------------------------
  Zabbix Agent   Instalacja, konfiguracja i diagnostyka Zabbix Agent.

> Dokumentacja w tej kategorii będzie rozwijana wraz z kolejnymi testami
> w Home IT Lab.

### 🪟 Windows / Windows Server

Planowane procedury dotyczące m.in.:

-   Windows Server,
-   Active Directory,
-   DNS,
-   Group Policy,
-   Windows Update,
-   Remote Desktop Services,
-   PowerShell,
-   diagnostyki systemów Windows.

### 🌐 Network

Planowane procedury związane z:

-   VLAN,
-   routingiem,
-   firewallami,
-   FortiGate,
-   UniFi,
-   diagnostyką sieci,
-   segmentacją infrastruktury.

### 🛡️ Security

Planowane procedury dotyczące m.in.:

-   Wazuh,
-   analizy logów,
-   hardeningu systemów,
-   reagowania na zdarzenia,
-   podstawowych procedur bezpieczeństwa infrastruktury.

### ☁️ Microsoft 365

Planowane procedury administracyjne związane z:

-   Microsoft 365,
-   Exchange Online,
-   konfiguracją poczty,
-   regułami transportowymi,
-   diagnostyką problemów z pocztą,
-   zarządzaniem użytkownikami.

------------------------------------------------------------------------

## 🗂️ Docelowa struktura

``` text
runbooks/
├── README.md
│
├── certificates/
│   └── apache-https-wlasne-ca.md
│
├── monitoring/
│   └── zabbix-agent.md
│
├── windows/
│   └── ...
│
├── network/
│   └── ...
│
├── security/
│   └── ...
│
└── microsoft-365/
    └── ...
```

Struktura będzie rozwijana stopniowo wraz z dodawaniem kolejnych
procedur.

------------------------------------------------------------------------

## 📝 Schemat runbooka

Dla zachowania spójności kolejne dokumenty mogą wykorzystywać podobny
układ:

``` text
# Nazwa procedury

## Cel

## Środowisko / wymagania

## Konfiguracja

## Weryfikacja

## Diagnostyka

## Bezpieczeństwo

## Uwagi
```

Nie każdy runbook musi zawierać wszystkie sekcje --- układ powinien być
dopasowany do konkretnego zadania.

------------------------------------------------------------------------

## 🔗 Powiązanie z projektami

Runbooki są uzupełnieniem projektów znajdujących się w głównym
repozytorium **Home IT Lab**.

``` text
Home IT Lab
     |
     +---- Projekty / automatyzacje
     |          |
     |          +---- n8n
     |          +---- PowerShell
     |          +---- Monitoring
     |
     +---- Runbooki
                |
                +---- konfiguracja
                +---- administracja
                +---- diagnostyka
                +---- troubleshooting
```

Projekty pokazują kompletne rozwiązania i automatyzacje, natomiast
runbooki dokumentują konkretne procedury administracyjne, które można
wykorzystać ponownie.

------------------------------------------------------------------------

## 🚀 Plan rozwoju

Baza runbooków będzie rozszerzana wraz z rozwojem Home IT Lab.

Planowane są m.in. procedury dotyczące:

-   Active Directory i GPO,
-   Windows Server,
-   RDS,
-   Windows Update,
-   Zabbix,
-   Wazuh,
-   FortiGate i VLAN,
-   PowerShell,
-   Microsoft 365 / Exchange Online,
-   backupu i odtwarzania danych,
-   diagnostyki usług Windows.

------------------------------------------------------------------------

## 🔐 Bezpieczeństwo

Runbooki publikowane w repozytorium nie powinny zawierać informacji
umożliwiających dostęp do rzeczywistego środowiska.

Przed publikacją należy zweryfikować i w razie potrzeby usunąć lub
zastąpić:

-   hasła,
-   tokeny API,
-   klucze prywatne,
-   dane uwierzytelniające,
-   prywatne adresy IP,
-   poufne nazwy hostów i domen,
-   inne sekrety oraz dane środowiskowe.

Przykłady powinny wykorzystywać wartości testowe lub zanonimizowane.

------------------------------------------------------------------------

## 🏠 Home IT Lab

Runbooki powstają podczas praktycznej pracy w moim **Home IT Lab**.

Celem jest budowanie własnej, uporządkowanej bazy wiedzy administratora
IT oraz dokumentowanie rozwiązań, które zostały rzeczywiście
skonfigurowane, przetestowane lub wykorzystane podczas diagnostyki.
