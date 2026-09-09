\# 🏠 Home IT Lab



Moje środowisko laboratoryjne do nauki i testowania administracji systemami, sieci, cyberbezpieczeństwa, monitoringu oraz automatyzacji IT.



Repozytorium zawiera konfiguracje, workflow, skrypty, runbooki oraz dokumentację rozwiązań testowanych w środowisku Home Lab.



\## 🧰 Technologie



\- Windows Server 2025

\- Active Directory / DNS / GPO

\- Hyper-V

\- Windows 11

\- FortiGate

\- VLAN / routing / firewall

\- Zabbix

\- Wazuh

\- n8n

\- PowerShell

\- SSH / OpenSSH

\- Docker

\- Ollama / lokalne LLM

\- Ubiquiti UniFi



\## 🔬 Projekty



\### Zabbix Auto-Remediation



Automatyczna reakcja na awarie usług Windows wykrywane przez Zabbix.



Przykładowy przepływ:



Zabbix → Webhook → n8n → SSH → PowerShell → weryfikacja → Auto-Healing



Jeżeli automatyczna naprawa się nie powiedzie:



Zabbix → n8n → diagnostyka Windows → Ollama / LLM → analiza problemu → e-mail do administratora



Funkcje:

\- wykrywanie awarii przez Zabbix,

\- przekazywanie zdarzeń przez webhook,

\- zdalne wykonywanie poleceń PowerShell przez SSH,

\- automatyczna próba uruchomienia usługi,

\- weryfikacja rezultatu,

\- diagnostyka usługi Windows,

\- analiza diagnostyki przez lokalny model AI,

\- powiadomienie e-mail o wyniku.



Dokumentacja:

`n8n/zabbix-auto-remediation/`



\## 📁 Struktura repozytorium



&#x20;   home-it-lab/

&#x20;   ├── active-directory/

&#x20;   ├── fortigate/

&#x20;   ├── n8n/

&#x20;   │   └── zabbix-auto-remediation/

&#x20;   ├── runbooks/

&#x20;   ├── wazuh/

&#x20;   └── zabbix/



\## 🎯 Cel



Celem laboratorium jest praktyczna nauka projektowania, wdrażania, monitorowania i automatyzowania infrastruktury IT.



Środowisko służy również do testowania integracji klasycznych narzędzi administracyjnych z lokalnymi modelami AI.



\## ⚠️ Informacja



Repozytorium przedstawia środowisko laboratoryjne.



Przed publikacją konfiguracji usuwane są dane wrażliwe, takie jak:

\- hasła,

\- tokeny API,

\- klucze prywatne,

\- dane uwierzytelniające,

\- dane produkcyjne.

