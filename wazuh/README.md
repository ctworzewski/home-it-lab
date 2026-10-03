# \# 🛡️ Wazuh Security Monitoring Lab

# 

# Praktyczne laboratorium \*\*Windows Security / Active Directory / Wazuh\*\*,

# rozwijane jako część mojego \*\*Home IT Lab\*\*.

# 

# Celem projektu jest nie tylko wygenerowanie alertu w SIEM, ale

# prześledzenie całej ścieżki zdarzenia --- od Windows Event Log, przez

# detekcję w Wazuh, aż po automatyzację, powiadomienie i lokalną analizę

# AI.

# 

# \## 🔐 Aktualnie ukończony projekt

# 

# \### Active Directory Account Lockout Detection

# 

# ``` text

# Windows Security Log

# &#x20;       ↓

# Active Directory

# &#x20;       ↓

# Wazuh

# &#x20;       ↓

# n8n

# &#x20;       ↓

# Ollama

# &#x20;       ↓

# SMTP

# ```

# 

# W scenariuszu zostały wykorzystane m.in.:

# 

# \-   Windows Event ID `4625` --- nieudane logowanie,

# \-   Windows Event ID `4740` --- blokada konta,

# \-   Wazuh Rule ID `60115`,

# \-   Wazuh SCA / CIS,

# \-   webhook Wazuh → n8n,

# \-   normalizacja i filtrowanie danych w n8n,

# \-   lokalny model Ollama do pomocniczej analizy alertu,

# \-   SMTP do wysłania powiadomienia administratorowi.

# 

# Zależność `4625 → 4740` została potwierdzona na podstawie zdarzeń z

# `LAB-W11-1` oraz `LAB-DC1`. Automatyczne łączenie obu typów zdarzeń

# pozostaje możliwym dalszym rozszerzeniem projektu.

# 

# ➡️ \*\*\[Pełna dokumentacja

# projektu](docs/05-ad-account-lockout-detection.md)\*\*

# 

# \------------------------------------------------------------------------

# 

# \## 🖥️ Środowisko LAB

# 

# &#x20; -----------------------------------------------------------------------

# &#x20; Host                    System                  Rola

# &#x20; ----------------------- ----------------------- -----------------------

# &#x20; `WAZUH-SRV`             Ubuntu Server           Wazuh Manager

# 

# &#x20; `LAB-DC1`               Windows Server 2025     Active Directory /

# &#x20;                                                 Domain Controller

# 

# &#x20; `LAB-W11-1`             Windows 11              Stacja robocza w

# &#x20;                                                 domenie

# 

# &#x20; `LAB-W11-2`             Windows 11              Stacja robocza w

# &#x20;                                                 domenie

# 

# &#x20; `N8N-SRV`               Ubuntu Server / Docker  n8n / automatyzacje

# &#x20; -----------------------------------------------------------------------

# 

# Hosty Windows posiadają agentów Wazuh i przekazują zdarzenia do

# centralnego Wazuh Managera.

# 

# \------------------------------------------------------------------------

# 

# \## 🧰 Technologie

# 

# ``` text

# Windows Server 2025

# Active Directory

# Group Policy

# Windows 11

# Windows Security Event Log

# Wazuh

# Wazuh SCA

# n8n

# Ollama

# SMTP

# PowerShell

# Linux / Ubuntu

# Docker

# Git / GitHub

# ```

# 

# \------------------------------------------------------------------------

# 

# \## 📚 Dokumentacja

# 

# &#x20; -------------------------------------------------------------------------------------------------------------------------

# &#x20; Dokument                                                                              Zakres

# &#x20; ------------------------------------------------------------------------------------- -----------------------------------

# &#x20; \[`01-architecture.md`](docs/01-architecture.md)                                       Architektura środowiska

# 

# &#x20; \[`02-failed-logon-default-rule.md`](docs/02-failed-logon-default-rule.md)             Nieudane logowanie i domyślna

# &#x20;                                                                                       detekcja Wazuh

# 

# &#x20; \[`03-custom-rule-119100.md`](docs/03-custom-rule-119100.md)                           Własna reguła Wazuh

# 

# &#x20; \[`04-n8n-smtp-integration.md`](docs/04-n8n-smtp-integration.md)                       Integracja Wazuh → n8n → SMTP

# 

# &#x20; \*\*\[`05-ad-account-lockout-detection.md`](docs/05-ad-account-lockout-detection.md)\*\*   \*\*AD Account Lockout → Wazuh → n8n

# &#x20;                                                                                       → Ollama → SMTP\*\*

# &#x20; -------------------------------------------------------------------------------------------------------------------------

# 

# > Dokument `05` jest obecnie najbardziej rozbudowanym, kompletnym

# > scenariuszem w tym repozytorium.

# 

# \------------------------------------------------------------------------

# 

# \## 🔎 Jak analizuję zdarzenia

# 

# Każdy scenariusz staram się przeprowadzać według podobnego schematu:

# 

# ``` text

# Akcja testowa

# &#x20;     ↓

# Windows Event Log

# &#x20;     ↓

# Wazuh Agent

# &#x20;     ↓

# Wazuh Manager

# &#x20;     ↓

# Analiza Event ID / Rule ID

# &#x20;     ↓

# Reguła lub filtr

# &#x20;     ↓

# Automatyzacja

# &#x20;     ↓

# Powiadomienie

# &#x20;     ↓

# Dokumentacja i ponowny test

# ```

# 

# Celem jest zrozumienie \*\*dlaczego alert powstał, z jakiego zdarzenia

# pochodzi i jakie dane są rzeczywiście przydatne administratorowi\*\*, a

# nie samo uzyskanie alertu w dashboardzie.

# 

# \------------------------------------------------------------------------

# 

# \## 🔍 Analizowane dane

# 

# W zależności od scenariusza analizuję m.in.:

# 

# ``` text

# rule.id

# rule.level

# rule.description

# agent.name

# agent.ip

# data.win.system.eventID

# data.win.eventdata.targetUserName

# data.win.eventdata.subjectUserName

# data.win.eventdata.workstationName

# data.win.eventdata.logonType

# ```

# 

# Zakres pól zależy od konkretnego Windows Event ID.

# 

# \------------------------------------------------------------------------

# 

# \## ✅ Zrealizowane elementy

# 

# \-   \[x] Wazuh Manager

# \-   \[x] Agenty Windows i Linux

# \-   \[x] Monitoring kontrolera domeny

# \-   \[x] Monitoring stacji Windows 11

# \-   \[x] Windows Audit Policy dla testowanych zdarzeń

# \-   \[x] Detekcja nieudanych logowań --- Event ID `4625`

# \-   \[x] Własna reguła Wazuh dla wybranego scenariusza

# \-   \[x] Integracja Wazuh → n8n

# \-   \[x] Powiadomienia SMTP

# \-   \[x] Monitoring utworzenia i usunięcia użytkownika AD

# \-   \[x] Detekcja blokady konta --- Event ID `4740`

# \-   \[x] Wazuh Rule ID `60115`

# \-   \[x] Test Account Lockout Policy

# \-   \[x] Wazuh SCA / CIS dla Account Lockout Threshold

# \-   \[x] Potwierdzenie zależności `4625 → 4740`

# \-   \[x] Lokalna analiza alertu przez Ollama

# \-   \[x] Finalny workflow `Wazuh → n8n → Ollama → SMTP`

# 

# \------------------------------------------------------------------------

# 

# \## 🧪 Kolejne scenariusze

# 

# Repozytorium będzie rozwijane o kolejne kontrolowane testy

# bezpieczeństwa, m.in.:

# 

# \-   zmiany członkostwa w grupach Active Directory,

# \-   zmiany w grupach uprzywilejowanych,

# \-   monitoring PowerShell,

# \-   File Integrity Monitoring,

# \-   zdarzenia Microsoft Defender,

# \-   wybrane scenariusze Active Response,

# \-   dalszą korelację zdarzeń Windows i Active Directory.

# 

# Jednym z możliwych rozszerzeń obecnego projektu jest automatyczna

# korelacja wcześniejszych zdarzeń `4625` z późniejszym `4740` i

# przekazanie pełnego kontekstu incydentu do n8n/Ollama.

# 

# \------------------------------------------------------------------------

# 

# \## 📁 Struktura repozytorium

# 

# ``` text

# wazuh/

# ├── README.md

# ├── docs/

# │   ├── 01-architecture.md

# │   ├── 02-failed-logon-default-rule.md

# │   ├── 03-custom-rule-119100.md

# │   ├── 04-n8n-smtp-integration.md

# │   └── 05-ad-account-lockout-detection.md

# ├── configs/

# ├── scripts/

# └── screenshots/

# ```

# 

# \### `docs/`

# 

# Dokumentacja konfiguracji, testów i wyników poszczególnych scenariuszy.

# 

# \### `configs/`

# 

# Przykładowe konfiguracje Wazuh wykorzystywane w LAB.

# 

# \### `scripts/`

# 

# Skrypty i narzędzia używane do generowania kontrolowanych zdarzeń oraz

# testów.

# 

# \### `screenshots/`

# 

# Zrzuty z Windows Event Viewer, Wazuh, n8n oraz finalnych powiadomień

# dokumentujące przebieg testów.

# 

# \------------------------------------------------------------------------

# 

# \## 🔒 Bezpieczeństwo repozytorium

# 

# Projekt wykonywany jest wyłącznie w kontrolowanym środowisku

# laboratoryjnym.

# 

# W repozytorium nie publikuję:

# 

# \-   haseł,

# \-   kluczy agentów,

# \-   tokenów API,

# \-   danych dostępowych,

# \-   danych produkcyjnych,

# \-   konfiguracji zawierających sekrety.

# 

# Dane użytkowników, hostów i domen wykorzystywane w scenariuszach są

# elementami środowiska LAB.

# 

# \------------------------------------------------------------------------

# 

# \## 🎯 Cel repozytorium

# 

# Repozytorium dokumentuje mój praktyczny rozwój w obszarze:

# 

# \*\*Windows Administration → Active Directory → Security Monitoring → SIEM

# → Automation\*\*

# 

# Każdy scenariusz ma być możliwie praktyczny, powtarzalny i

# udokumentowany tak, aby pokazywał zarówno konfigurację, jak i sposób

# analizy zdarzenia.



