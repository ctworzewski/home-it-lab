# 06 – Wykrywanie logowań na konta uprzywilejowane w Active Directory

## Cel projektu

Celem projektu jest zbudowanie wieloetapowej detekcji aktywności konta uprzywilejowanego w środowisku Active Directory.

Projekt ma docelowo odpowiedzieć na pytania:

1. **Czy konto uprzywilejowane zostało użyte do logowania?**
2. **Czy po logowaniu uruchomiono PowerShell?**
3. **Jakie polecenia lub skrypty zostały wykonane?**
4. **Czy kilka niezależnych zdarzeń można połączyć w jeden czytelny incydent?**

Docelowy przepływ:

```text
Privileged Account Logon
        ↓
Windows Security 4624 / 4672
        ↓
Wazuh
        ↓
Sysmon – Process Create
        ↓
PowerShell Script Block Logging – 4104
        ↓
własne reguły Wazuh
        ↓
n8n
        ↓
jeden skorelowany alert SMTP
```

Projekt jest wykonywany w środowisku LAB i służy do nauki analizy zdarzeń Windows, Sysmon, korelacji, Detection Engineering oraz automatyzacji obsługi alertów.

---

## Środowisko LAB

| Element | Rola |
|---|---|
| `LAB-DC1` | Active Directory / domena `cyber.local` |
| `LAB-W11-1` | stacja testowa Windows 11 |
| `CYBER\adm-ctworzewski` | testowe konto uprzywilejowane |
| Wazuh Agent | zbieranie logów ze stacji |
| Wazuh Manager | analiza zdarzeń i własne reguły |
| Sysmon | telemetria procesów |

---

# Etap 1 – logowanie konta uprzywilejowanego

Pierwszym etapem projektu jest sprawdzenie, jakie zdarzenia generuje Windows podczas użycia konta uprzywilejowanego oraz czy ten sam kontekst jest widoczny w Wazuh.

Analizowane zdarzenia:

- **4624** – udane logowanie,
- **4672** – przypisanie specjalnych uprawnień do nowej sesji.

## Event ID 4624 – udane logowanie

Po zalogowaniu konta:

```text
CYBER\adm-ctworzewski
```

Windows zarejestrował Event ID `4624`.

Na potrzeby korelacji interesujące są przede wszystkim:

- `Account Name`,
- `Account Domain`,
- `Logon Type`,
- `Logon ID`,
- `Linked Logon ID`.

W badanym zdarzeniu:

```text
Account Name: adm-ctworzewski
Domain: CYBER
Logon Type: 7
Logon ID: 0x38BF8E
Linked Logon ID: 0x38BD57
```

> `Logon Type 7` oznacza odblokowanie istniejącej sesji. W dalszej części projektu ten typ będzie celowo wyłączony z właściwej detekcji logowania uprzywilejowanego.

![Windows Event ID 4624](../screenshots/01-windows-4624-linked-logon-id.png)

## Event ID 4672 – specjalne uprawnienia

W tej samej sekwencji Windows wygenerował Event ID `4672`:

```text
Account Name: adm-ctworzewski
Domain: CYBER
Logon ID: 0x38BD57
```

Zdarzenie potwierdza przypisanie do sesji specjalnych uprawnień.

![Windows Event ID 4672](../screenshots/02-windows-4672-special-privileges.png)

## Korelacja 4624 → 4672 po Logon ID

Kluczową obserwacją jest możliwość powiązania obu zdarzeń.

W `4624`:

```text
Linked Logon ID: 0x38BD57
```

W `4672`:

```text
Logon ID: 0x38BD57
```

Daje to zależność:

```text
4624
Linked Logon ID: 0x38BD57
        ↓
4672
Logon ID: 0x38BD57
```

Dzięki temu można potwierdzić, że konkretna sesja logowania jest powiązana z sesją, której Windows przypisał specjalne uprawnienia.

---

# Windows → Wazuh

Kolejnym krokiem było sprawdzenie, czy Wazuh odbiera ten sam Event ID `4672` bez utraty najważniejszych informacji.

W Wazuh widoczne są:

```text
agent.name = LAB-W11-1
eventID = 4672
subjectDomainName = CYBER
subjectUserName = adm-ctworzewski
subjectLogonId = 0x38bd57
```

![Wazuh Event ID 4672](../screenshots/03-wazuh-4672-logon-id.png)

To ten sam identyfikator sesji, który był widoczny lokalnie w Event Viewer:

```text
Windows: 0x38BD57
Wazuh:   0x38bd57
```

Wazuh przypisał zdarzenie do domyślnej reguły:

```text
Rule ID: 67028
Level: 3
Description: Special privileges assigned to new logon.
```

![Wazuh Rule 67028](../screenshots/04-wazuh-4672-rule-details.png)

---

# Co potwierdzono w Etapie 1

- [x] konto testowe `adm-ctworzewski` istnieje,
- [x] Windows generuje `4624`,
- [x] Windows generuje `4672`,
- [x] możliwa jest korelacja po `Logon ID`,
- [x] Wazuh odbiera `4672`,
- [x] Wazuh zachowuje użytkownika, domenę i `Logon ID`,
- [x] domyślna reguła Wazuh `67028` poprawnie klasyfikuje `4672`.

---

# Etap 2 – Sysmon i uruchomienie PowerShell

Drugim etapem projektu jest rozszerzenie telemetrii o Sysmon i sprawdzenie, czy po użyciu konta uprzywilejowanego można wykryć uruchomienie PowerShell.

Interesuje nas przede wszystkim:

```text
Sysmon Event ID 1 – Process Create
```

Dzięki temu zdarzeniu można uzyskać m.in.:

- ścieżkę procesu,
- `CommandLine`,
- użytkownika,
- `ProcessId`,
- `ProcessGuid`,
- `LogonId`,
- `IntegrityLevel`,
- informacje o procesie nadrzędnym,
- hash procesu.

## Sysmon – lokalny Event ID 1

Po uruchomieniu PowerShell jako konto:

```text
CYBER\adm-ctworzewski
```

Sysmon zarejestrował:

```text
Event ID: 1
Image: C:\Windows\System32\WindowsPowerShell\v1.0\powershell.exe
User: CYBER\adm-ctworzewski
ProcessId: 9900
LogonId: 0x950c3
IntegrityLevel: High
```

`IntegrityLevel: High` potwierdza, że proces został uruchomiony w kontekście podwyższonych uprawnień.

![Windows Sysmon Event ID 1](../screenshots/05-windows-sysmon-event1-powershell.png)

---

## Sysmon → Wazuh

Do konfiguracji agenta Wazuh na `LAB-W11-1` dodano kanał Sysmon:

```xml
<localfile>
  <location>Microsoft-Windows-Sysmon/Operational</location>
  <log_format>eventchannel</log_format>
</localfile>
```

Po restarcie usługi agenta:

```powershell
Restart-Service WazuhSvc
```

Wazuh zaczął odbierać zdarzenia Sysmon.

Dla tego samego uruchomienia PowerShell widoczne są m.in.:

```text
agent.name = LAB-W11-1
image = C:\Windows\System32\WindowsPowerShell\v1.0\powershell.exe
processId = 9900
logonId = 0x950c3
integrityLevel = High
```

![Wazuh Sysmon Event ID 1 – details](../screenshots/06-wazuh-sysmon-event1-powershell-details.png)

Na poziomie reguły Wazuh zdarzenie zostało sklasyfikowane jako:

```text
Rule ID: 100100
Level: 3
Description: Sysmon - Event 1: Process creation Windows PowerShell
```

![Wazuh Sysmon rule details](../screenshots/07-wazuh-sysmon-event1-rule-details.png)

---

## Korelacja Windows Sysmon → Wazuh

Dla obu stron widoczny jest ten sam proces:

```text
PowerShell.exe
ProcessId: 9900
LogonId: 0x950c3
IntegrityLevel: High
```

Daje to czytelny przepływ:

```text
CYBER\adm-ctworzewski
        ↓
powershell.exe
        ↓
Sysmon Event ID 1
        ↓
ProcessId 9900 / LogonId 0x950c3
        ↓
Wazuh
        ↓
Rule 100100
```

To potwierdza, że Wazuh nie tylko odbiera Sysmon, ale zachowuje kontekst potrzebny do dalszej korelacji.

---

# Co potwierdzono w Etapie 2

- [x] Sysmon działa na `LAB-W11-1`,
- [x] Sysmon generuje Event ID `1`,
- [x] wykrywane jest uruchomienie `powershell.exe`,
- [x] widoczny jest użytkownik `CYBER\adm-ctworzewski`,
- [x] widoczny jest `ProcessId`,
- [x] widoczny jest `LogonId`,
- [x] widoczny jest `IntegrityLevel: High`,
- [x] Wazuh odbiera Sysmon Event ID `1`,
- [x] Wazuh klasyfikuje zdarzenie regułą `100100`.

---

# Dlaczego Sysmon jest ważny w tym projekcie

Windows Security Log pozwala odpowiedzieć na pytanie:

> **kto się zalogował?**

Sysmon rozszerza ten kontekst o:

> **co użytkownik uruchomił?**

Dzięki temu zamiast pojedynczego alertu o logowaniu możemy budować sekwencję:

```text
konto uprzywilejowane
        ↓
logowanie
        ↓
PowerShell
```

Samo uruchomienie PowerShell nie oznacza incydentu. Jest to jednak istotny element kontekstu, szczególnie gdy występuje bezpośrednio po logowaniu konta administracyjnego.

---

# Następny etap

## Etap 3 – PowerShell Script Block Logging

Sysmon pokazuje, że uruchomiono:

```text
powershell.exe
```

ale nie zawsze daje pełną odpowiedź na pytanie:

> **co dokładnie zostało wykonane wewnątrz PowerShell?**

Dlatego kolejnym etapem będzie włączenie:

```text
PowerShell Script Block Logging
```

i analiza:

```text
Event ID 4104
```

Docelowo chcemy uzyskać:

```text
Privileged Account Logon
        ↓
PowerShell Process
        ↓
ScriptBlockText
        ↓
konkretne wykonane polecenie
```

---

# Status projektu

✅ **Etap 1 – Windows Security / Wazuh zakończony**

```text
4624
↓
4672
↓
korelacja po Logon ID
↓
Wazuh Rule 67028
```

✅ **Etap 2 – Sysmon / PowerShell zakończony**

```text
PowerShell
↓
Sysmon Event ID 1
↓
ProcessId / LogonId / IntegrityLevel
↓
Wazuh Rule 100100
```

🚧 **Następny krok: PowerShell Script Block Logging / Event ID 4104**
