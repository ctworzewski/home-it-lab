\# ⚙️ n8n – IT Infrastructure Automation



Ten katalog zawiera workflow oraz dokumentację automatyzacji IT tworzonych w n8n w ramach mojego Home Lab.



Celem jest integracja monitoringu, systemów Windows/Linux, narzędzi bezpieczeństwa oraz lokalnych modeli LLM w celu automatyzacji diagnostyki i reakcji na zdarzenia infrastrukturalne.



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



\## 🚀 Projekty



\### ✅ Zabbix Agent Auto-Remediation



Status: \*\*działa / przetestowane\*\*



Automatyczna reakcja na niedostępność usługi Zabbix Agent na Windows.



Workflow:



```text

Zabbix

→ Webhook

→ n8n

→ SSH

→ PowerShell

→ Start-Service

→ Verification

```



Jeżeli naprawa się powiedzie:



```text

SUCCESS → Email

```



Jeżeli naprawa się nie powiedzie:



```text

FAILED

→ PowerShell Diagnostics

→ Ollama

→ AI-assisted troubleshooting

→ Email

```



Dokumentacja:



`zabbix-auto-remediation/`



\---



\## 🧪 Planowane automatyzacje



\### High CPU Diagnostics



```text

Zabbix High CPU

→ n8n

→ PowerShell

→ TOP Processes

→ Ollama

→ Email

```



\### High Memory Diagnostics



Analiza procesów odpowiedzialnych za wysokie wykorzystanie pamięci RAM.



\### Low Disk Space



Automatyczna diagnostyka wykorzystania przestrzeni dyskowej oraz identyfikacja największych katalogów i plików.



\### Host Unavailable



Diagnostyka:



\- ping,

\- DNS,

\- dostępność portów,

\- podstawowe testy sieciowe.



\### Backup Failure



Analiza błędów backupu oraz przygotowanie informacji dla administratora.



\### Certificate Expiration



Powiadomienia o certyfikatach zbliżających się do końca ważności.



\### Wazuh Integration



Docelowa obsługa wybranych alertów bezpieczeństwa z Wazuh przez n8n.



\---



\## 🤖 Local AI



Do analizy diagnostycznej wykorzystywana jest lokalna instancja:



\- Ollama

\- lokalne modele LLM



LLM służy do:



\- interpretacji danych diagnostycznych,

\- wskazywania prawdopodobnej przyczyny,

\- proponowania kolejnych kroków,

\- przygotowania czytelnego raportu dla administratora.



Model AI \*\*nie otrzymuje nieograniczonej możliwości wykonywania poleceń administracyjnych\*\*.



Akcje Auto-Remediation są wcześniej zdefiniowane i kontrolowane przez workflow.



\## 🔐 Security



Repozytorium nie powinno zawierać:



\- haseł,

\- API keys,

\- tokenów,

\- credentials n8n,

\- prywatnych kluczy SSH,

\- produkcyjnych adresów IP,

\- danych użytkowników.



Workflow przed publikacją powinien zostać zweryfikowany i zanonimizowany.

