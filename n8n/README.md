\# ⚙️ n8n – IT Infrastructure Automation



Ten katalog zawiera workflow oraz dokumentację automatyzacji IT tworzonych w \*\*n8n\*\* w ramach mojego Home Lab.



Celem jest integracja monitoringu, systemów Windows/Linux, narzędzi bezpieczeństwa oraz lokalnych modeli LLM w celu automatyzacji diagnostyki i reakcji na zdarzenia infrastrukturalne.



\---



\## 🏗️ Architektura



Główny kierunek integracji:



```text

Monitoring

&#x20;   ↓

Zabbix / Wazuh

&#x20;   ↓

Webhook

&#x20;   ↓

n8n

&#x20;   ↓

Klasyfikacja zdarzenia

&#x20;   ↓

SSH / API / PowerShell

&#x20;   ↓

Diagnostyka

&#x20;   ↓

Auto-Remediation

&#x20;   ↓

Weryfikacja

&#x20;   ↓

Ollama / LLM

&#x20;   ↓

Powiadomienie / Eskalacja

```



\---



\## 🚀 Projekty



\### ✅ Zabbix Agent Auto-Remediation



\*\*Status:\*\* działa / przetestowane



Automatyczna reakcja na niedostępność usługi \*\*Zabbix Agent\*\* na systemie Windows.



Workflow odbiera zdarzenie z Zabbixa, podejmuje próbę automatycznej naprawy, weryfikuje rezultat, a w przypadku niepowodzenia uruchamia dodatkową diagnostykę i analizę przy użyciu lokalnego modelu LLM.



\### Workflow



```text

Zabbix

&#x20;   ↓

Webhook

&#x20;   ↓

n8n

&#x20;   ↓

SSH

&#x20;   ↓

PowerShell

&#x20;   ↓

Próba uruchomienia Zabbix Agent

&#x20;   ↓

Weryfikacja stanu usługi

&#x20;   ↓

&#x20;   ├── SUCCESS

&#x20;   │      ↓

&#x20;   │   E-mail: usługa została przywrócona

&#x20;   │

&#x20;   └── FAILED

&#x20;          ↓

&#x20;      Diagnostyka Windows

&#x20;          ↓

&#x20;      Pobranie informacji o usłudze

&#x20;          ↓

&#x20;      Analiza przez Ollama / LLM

&#x20;          ↓

&#x20;      Sugestie diagnostyczne

&#x20;          ↓

&#x20;      E-mail: wymagana interwencja administratora

```



\---



\## 🔧 Auto-Remediation



Po wykryciu przez Zabbix niedostępności agenta n8n wykonuje zdalną próbę uruchomienia usługi.



Przykładowa operacja PowerShell:



```powershell

Start-Service -Name "Zabbix Agent"

```



Po wykonaniu operacji następuje ponowne sprawdzenie stanu usługi.



```powershell

Get-Service -Name "Zabbix Agent"

```



Jeżeli usługa znajduje się w stanie:



```text

Running

```



workflow uznaje naprawę za zakończoną sukcesem.



\---



\## 🔍 Automatyczna diagnostyka



Jeżeli automatyczna próba naprawy zakończy się niepowodzeniem, n8n uruchamia dodatkowy etap diagnostyczny.



Zbierane są między innymi:



\- nazwa usługi,

\- aktualny stan usługi,

\- tryb uruchamiania,

\- kod wyjścia,

\- ścieżka do pliku wykonywalnego,

\- informacje pomocne w dalszej diagnostyce.



Przykład:



```powershell

$svc = Get-CimInstance Win32\_Service -Filter "Name='Zabbix Agent'"



\[PSCustomObject]@{

&#x20;   Name      = $svc.Name

&#x20;   State     = $svc.State

&#x20;   StartMode = $svc.StartMode

&#x20;   ExitCode  = $svc.ExitCode

&#x20;   Path      = $svc.PathName

} | ConvertTo-Json -Compress

```



Dane są zwracane do n8n w formacie JSON.



Przykład:



```json

{

&#x20; "Name": "Zabbix Agent",

&#x20; "State": "Stopped",

&#x20; "StartMode": "Disabled",

&#x20; "ExitCode": 0,

&#x20; "Path": "C:\\\\Program Files\\\\Zabbix Agent\\\\zabbix\_agentd.exe"

}

```



\---



\## 🤖 Analiza AI – Ollama



Jeżeli usługi nie uda się automatycznie przywrócić, dane diagnostyczne są przekazywane do lokalnego modelu LLM poprzez \*\*Ollama\*\*.



Aktualnie wykorzystywany model:



```text

gpt-oss:20b

```



LLM pełni rolę warstwy wspomagającej diagnostykę.



Na podstawie danych z systemu model przygotowuje:



\- prawdopodobną przyczynę problemu,

\- sugerowaną kolejność diagnostyki,

\- przykładowe polecenia PowerShell,

\- propozycję dalszych działań,

\- ocenę, czy wymagana jest ręczna interwencja administratora.



Model \*\*nie wykonuje samodzielnie zmian w systemie\*\* – jego zadaniem jest analiza danych i przygotowanie rekomendacji.



\---



\## 📧 Powiadomienia



Workflow obsługuje dwa podstawowe scenariusze.



\### ✅ Automatyczna naprawa zakończona sukcesem



Administrator otrzymuje wiadomość zawierającą m.in.:



```text

Zabbix Auto-Healing - SUCCESS



Host: TEST01

Problem: Zabbix Agent niedostępny



Akcja:

Start-Service "Zabbix Agent"



Wynik:

SUCCESS – usługa działa.

```



\### ⚠️ Automatyczna naprawa nie powiodła się



W przypadku niepowodzenia administrator otrzymuje rozszerzone powiadomienie:



```text

Automatyczna naprawa nie powiodła się



Host: TEST01

Problem: Zabbix Agent niedostępny

Wynik: FAILED



Analiza AI:

\- prawdopodobna przyczyna,

\- od czego rozpocząć diagnostykę,

\- sugerowane polecenia PowerShell,

\- ocena konieczności ręcznej interwencji.

```



\---



\## 🧪 Przetestowane scenariusze



\### Scenario 1 – zatrzymana usługa



```text

Zabbix Agent = Stopped

Startup Type = Automatic

```



Rezultat:



```text

Zabbix

→ Webhook

→ n8n

→ PowerShell

→ Start-Service

→ Verification

→ SUCCESS

→ Email

```



\### Scenario 2 – usługa wyłączona



```text

Zabbix Agent = Stopped

Startup Type = Disabled

```



Rezultat:



```text

Zabbix

→ Webhook

→ n8n

→ próba Start-Service

→ FAILED

→ diagnostyka

→ Ollama / LLM

→ rekomendacje

→ Email

→ ręczna interwencja administratora

```



\---



\## 🔐 Założenia bezpieczeństwa



Automatyzacja została zaprojektowana tak, aby oddzielić automatyczne działania od rekomendacji generowanych przez AI.



```text

Zabbix / Windows

&#x20;       ↓

&#x20;  dane techniczne

&#x20;       ↓

&#x20;     n8n

&#x20;       ↓

&#x20;  kontrolowana logika

&#x20;       ↓

PowerShell / SSH

```



LLM wykorzystywany jest przede wszystkim jako warstwa analityczna.



```text

Diagnostyka

&#x20;   ↓

Ollama / LLM

&#x20;   ↓

Rekomendacja

&#x20;   ↓

Administrator

```



Dzięki temu model AI nie otrzymuje bezpośredniej możliwości wykonywania dowolnych poleceń administracyjnych.



\---



\## 📁 Planowana struktura



```text

n8n/

│

├── README.md

│

├── zabbix-auto-remediation/

│   ├── README.md

│   ├── workflow.json

│   └── screenshots/

│

├── wazuh-automation/

│   └── README.md

│

└── windows-automation/

&#x20;   └── README.md

```



\---



\## 🗺️ Plan rozwoju



Planowane kolejne integracje:



\- Zabbix → n8n → automatyczna diagnostyka Windows,

\- Zabbix → n8n → analiza problemów usług Windows,

\- Zabbix → n8n → monitoring miejsca na dyskach,

\- Zabbix → n8n → diagnostyka wykorzystania CPU/RAM,

\- Wazuh → n8n → analiza alertów bezpieczeństwa,

\- n8n → Ollama → klasyfikacja zdarzeń,

\- automatyczne tworzenie raportów incydentów,

\- eskalacja zdarzeń wymagających interwencji administratora,

\- tworzenie historii wykonanych działań Auto-Remediation.



\---



\## 🎯 Cel projektu



Projekt służy do praktycznej nauki i testowania:



\- monitoringu infrastruktury,

\- automatyzacji IT,

\- PowerShell,

\- SSH,

\- API i Webhooków,

\- Auto-Remediation,

\- diagnostyki systemów Windows,

\- integracji lokalnych modeli LLM,

\- automatyzacji reakcji na incydenty.



Docelowo środowisko ma umożliwiać budowę coraz bardziej zaawansowanych mechanizmów:



\*\*Detect → Analyze → Remediate → Verify → Escalate\*\*

