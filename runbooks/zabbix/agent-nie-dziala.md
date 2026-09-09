\# Zabbix Agent nie działa – diagnostyka i Auto-Remediation



\## Cel



Diagnostyka niedostępnego Zabbix Agent na hoście Windows oraz automatyczna próba przywrócenia usługi przez n8n.



Architektura:



```text

Zabbix

&#x20;  ↓

Webhook

&#x20;  ↓

n8n

&#x20;  ↓

SSH

&#x20;  ↓

PowerShell

&#x20;  ↓

Auto-Remediation

&#x20;  ↓

Verification

```



Jeżeli naprawa się nie powiedzie:



```text

FAILED

&#x20;  ↓

PowerShell Diagnostics

&#x20;  ↓

Ollama / LLM

&#x20;  ↓

AI-assisted troubleshooting

&#x20;  ↓

Email → Administrator

```



\---



\## 1. Objaw



Zabbix generuje problem:



```text

Zabbix agent is not available

```



Przed rozpoczęciem naprawy sprawdź:



\- host,

\- adres IP,

\- czas wystąpienia problemu,

\- severity,

\- Event ID.



\---



\## 2. Sprawdzenie usługi lokalnie



Na hoście Windows:



```powershell

Get-Service -Name "Zabbix Agent"

```



Możliwe stany:



```text

Running

Stopped

```



Dokładniejsza diagnostyka:



```powershell

Get-CimInstance Win32\_Service -Filter "Name='Zabbix Agent'" |

Select-Object Name,State,StartMode,ExitCode,PathName

```



\---



\## 3. Sprawdzenie portu agenta



Domyślny port Zabbix Agent:



```text

TCP 10050

```



Sprawdzenie:



```powershell

Get-NetTCPConnection -LocalPort 10050 -State Listen

```



Alternatywnie:



```powershell

netstat -ano | findstr 10050

```



\---



\## 4. Próba uruchomienia usługi



Jeżeli usługa jest zatrzymana:



```powershell

Start-Service -Name "Zabbix Agent"

```



Następnie:



```powershell

Get-Service -Name "Zabbix Agent"

```



Oczekiwany rezultat:



```text

Running

```



\---



\## 5. Usługa nie chce się uruchomić



Sprawdź konfigurację:



```powershell

Get-CimInstance Win32\_Service -Filter "Name='Zabbix Agent'" |

Select-Object Name,State,StartMode,ExitCode,PathName

```



Jeżeli:



```text

StartMode = Disabled

```



usługi nie można normalnie uruchomić.



Jeżeli wyłączenie nie było zamierzone:



```powershell

Set-Service -Name "Zabbix Agent" -StartupType Automatic

Start-Service -Name "Zabbix Agent"

```



Ponownie:



```powershell

Get-Service -Name "Zabbix Agent"

```



\---



\## 6. Event Viewer



Sprawdź zdarzenia Service Control Manager:



```powershell

Get-WinEvent -FilterHashtable @{

&#x20;   LogName='System'

&#x20;   StartTime=(Get-Date).AddMinutes(-10)

} -ErrorAction SilentlyContinue |

Where-Object {

&#x20;   $\_.ProviderName -eq 'Service Control Manager'

} |

Select-Object -First 10 TimeCreated,Id,LevelDisplayName,Message

```



Szukaj informacji o:



\- błędzie uruchomienia usługi,

\- nieprawidłowej konfiguracji,

\- problemach z kontem usługi,

\- timeout,

\- brakującym pliku wykonywalnym.



\---



\# Auto-Remediation przez n8n



\## 7. Zabbix → Webhook



Zabbix przekazuje do n8n dane zdarzenia w JSON.



Przykładowe informacje:



```json

{

&#x20; "host": "TEST01",

&#x20; "host\_ip": "10.x.x.x",

&#x20; "status": "PROBLEM",

&#x20; "event": "Zabbix agent is not available",

&#x20; "severity": "Average",

&#x20; "event\_id": "123"

}

```



Nie publikuj w repozytorium rzeczywistych danych środowiska produkcyjnego.



\---



\## 8. Logika n8n



Workflow:



```text

Webhook

&#x20;  ↓

IF status = PROBLEM

&#x20;  ↓

IF event = Zabbix agent unavailable

&#x20;  ↓

SSH → Get-Service

&#x20;  ↓

IF Stopped

&#x20;  ↓

SSH → Start-Service

&#x20;  ↓

SSH → Get-Service

&#x20;  ↓

IF Running

```



\### TRUE



```text

SUCCESS

↓

Email

```



Administrator otrzymuje informację, że usługa została automatycznie przywrócona.



\### FALSE



```text

FAILED

↓

PowerShell Diagnostics

↓

Ollama

↓

Email

```



\---



\## 9. Diagnostyka dla Ollama



n8n zbiera dane:



```powershell

$svc = Get-CimInstance Win32\_Service -Filter "Name='Zabbix Agent'";



\[PSCustomObject]@{

&#x20;   Name      = $svc.Name

&#x20;   State     = $svc.State

&#x20;   StartMode = $svc.StartMode

&#x20;   ExitCode  = $svc.ExitCode

&#x20;   Path      = $svc.PathName

} | ConvertTo-Json -Compress

```



Przykładowy rezultat:



```json

{

&#x20; "Name": "Zabbix Agent",

&#x20; "State": "Stopped",

&#x20; "StartMode": "Disabled",

&#x20; "ExitCode": 0

}

```



\---



\## 10. Analiza przez lokalny LLM



Dane diagnostyczne przekazywane są do lokalnego modelu Ollama.



LLM ma:



\- wskazać prawdopodobną przyczynę,

\- wskazać dowody w danych,

\- zaproponować pierwsze kroki diagnostyczne,

\- zaproponować przydatne polecenia PowerShell,

\- określić, czy potrzebna jest ręczna interwencja.



LLM nie wykonuje samodzielnie poleceń administracyjnych.



\---



\## 11. Eskalacja



Jeżeli usługa nadal nie działa, administrator otrzymuje e-mail:



```text

\[ZABBIX]\[WYMAGANA INTERWENCJA]

HOST - nie udało się uruchomić Zabbix Agent

```



Wiadomość zawiera:



\- host,

\- IP,

\- problem,

\- severity,

\- Event ID,

\- wykonaną akcję,

\- wynik,

\- analizę AI,

\- sugerowane dalsze działania.



\---



\## 12. Zasada bezpieczeństwa



Automatyczna naprawa powinna wykonywać wyłącznie wcześniej zdefiniowane i kontrolowane akcje.



Model LLM:



```text

analizuje → rekomenduje

```



ale nie powinien otrzymywać nieograniczonej możliwości:



```text

generowania → wykonywania dowolnego PowerShell

```



Akcje naprawcze powinny pozostać deterministyczne i kontrolowane przez workflow n8n.

