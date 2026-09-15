\# Windows Update Automation with n8n



Automatyzacja monitorowania i instalowania aktualizacji Windows wykorzystująca:



\- PowerShell

\- Windows Update Agent (COM API)

\- Windows Task Scheduler

\- n8n

\- Webhook REST API

\- SMTP / e-mail notifications



\## Architektura



Komputer Windows

&#x20;       |

&#x20;       | Task Scheduler

&#x20;       v

PowerShell

&#x20;       |

&#x20;       | Windows Update API

&#x20;       v

Sprawdzenie / instalacja aktualizacji

&#x20;       |

&#x20;       | HTTP POST / JSON

&#x20;       v

n8n Webhook

&#x20;       |

&#x20;       v

IF / analiza statusu

&#x20;       |

&#x20;       +---- SUCCESS ----> Email SUCCESS

&#x20;       |

&#x20;       +---- FAILED -----> Email FAILED



\## Workflow 1 - Windows Update CHECK



Skrypt PowerShell cyklicznie sprawdza dostępność aktualizacji Windows.



Jeżeli dostępne są aktualizacje, wysyła raport JSON do webhooka n8n.



n8n analizuje liczbę dostępnych aktualizacji i może wysłać administratorowi powiadomienie e-mail.



\## Workflow 2 - Windows Update INSTALL



Skrypt:



1\. wyszukuje dostępne aktualizacje,

2\. akceptuje wymagane EULA,

3\. pobiera aktualizacje,

4\. instaluje aktualizacje,

5\. analizuje ResultCode oraz HRESULT,

6\. sprawdza, czy wymagany jest restart,

7\. wysyła raport JSON do n8n,

8\. n8n wysyła administratorowi raport e-mail.



Jeżeli system wymaga restartu, skrypt może automatycznie wykonać ponowne uruchomienie komputera.



\## Raportowanie do n8n



PowerShell komunikuje się z n8n przez webhook HTTP POST.



Przykładowy payload:



```json

{

&#x20; "host": "W11-TEST1",

&#x20; "status": "SUCCESS",

&#x20; "found": 2,

&#x20; "installed": 2,

&#x20; "resultCode": 2,

&#x20; "rebootRequired": true

}



\## Screenshots



\### Windows Update - CHECK



Workflow odpowiedzialny za odbieranie informacji o dostępnych aktualizacjach i wysyłanie powiadomienia.



!\[Windows Update CHECK workflow](screenshots/WindowsUpdate-CHECK.png)



\### Windows Update - INSTALL



Workflow odbiera raport z PowerShell przez webhook, sprawdza wynik instalacji i wysyła odpowiedni raport e-mail.



!\[Windows Update INSTALL workflow](screenshots/WindowsUpdate-INSTALL.png)



\## Windows Task Scheduler



Skrypty mogą być uruchamiane automatycznie przez \*\*Windows Task Scheduler\*\*.



Zadanie powinno być skonfigurowane z opcją:



> \*\*Run with highest privileges\*\*



Przykładowa akcja:



```powershell

powershell.exe -NoProfile -ExecutionPolicy Bypass -File "C:\\Scripts\\WindowsUpdate-Check.ps1"

```



Dzięki temu skrypt posiada uprawnienia wymagane do instalowania aktualizacji Windows.



\---



\## Bezpieczeństwo



Przed publikacją repozytorium należy usunąć lub zastąpić wszystkie dane dotyczące rzeczywistego środowiska.



Nie należy publikować:



\- prywatnych adresów webhooków,

\- adresów e-mail,

\- danych uwierzytelniających,

\- tokenów API,

\- haseł,

\- innych sekretów.



Przykładowy adres webhooka w publicznej wersji skryptu:



```powershell

$WebhookUrl = "https://n8n.example.com/webhook/windows-update-install"

```



Dane uwierzytelniające SMTP wykorzystywane przez n8n nie powinny znajdować się w repozytorium.



\---



\## Struktura projektu



```text

windows-update-automation/

├── scripts/

│   ├── WindowsUpdate-Check.ps1

│   └── WindowsUpdate-Install.ps1

│

├── workflows/

│   ├── windows-update-check.json

│   └── windows-update-install.json

│

├── screenshots/

│

└── README.md

```



\### `scripts/`



Skrypty PowerShell odpowiedzialne za komunikację z Windows Update oraz przesyłanie wyników do n8n.



\### `workflows/`



Eksporty workflow n8n odpowiedzialnych za odbieranie danych przez webhook, analizę wyniku i wysyłanie powiadomień.



\### `screenshots/`



Zrzuty ekranu przedstawiające działanie automatyzacji.



\---



\## Cel projektu



Projekt powstał jako część domowego laboratorium IT do nauki:



\- automatyzacji administracji systemami Windows,

\- PowerShell,

\- Windows Update API,

\- REST API i webhooków,

\- n8n,

\- monitorowania infrastruktury,

\- automatycznej remediacji.



Projekt pokazuje praktyczne połączenie administracji systemami Windows z narzędziami automatyzacji.



\---



\## Możliwy dalszy rozwój



Projekt może zostać rozszerzony m.in. o:



\- centralne zarządzanie aktualizacjami wielu komputerów,

\- maintenance windows,

\- raportowanie historii aktualizacji,

\- integrację z \*\*Zabbix\*\*,

\- integrację z \*\*Wazuh\*\*,

\- automatyczną analizę błędów instalacji,

\- automatyczną remediację,

\- dashboard stanu aktualizacji,

\- przechowywanie historii instalacji,

\- raport zbiorczy dla administratora.

