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

Projekt jest wykonywany w środowisku LAB i służy do nauki analizy zdarzeń Windows, korelacji, Detection Engineering oraz automatyzacji obsługi alertów.

---

## Środowisko LAB

| Element | Rola |
|---|---|
| `LAB-DC1` | Active Directory / domena `cyber.local` |
| `LAB-W11-1` | stacja testowa Windows 11 |
| `CYBER\adm-ctworzewski` | testowe konto uprzywilejowane |
| Wazuh Agent | zbieranie logów ze stacji |
| Wazuh Manager | analiza zdarzeń i własne reguły |

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

![Windows Event ID 4624](screenshots/01-windows-4624-linked-logon-id.png)

## Event ID 4672 – specjalne uprawnienia

W tej samej sekwencji Windows wygenerował Event ID `4672`:

```text
Account Name: adm-ctworzewski
Domain: CYBER
Logon ID: 0x38BD57
```

Zdarzenie potwierdza przypisanie do sesji specjalnych uprawnień, m.in.:

```text
SeSecurityPrivilege
SeTakeOwnershipPrivilege
SeLoadDriverPrivilege
SeBackupPrivilege
SeRestorePrivilege
SeDebugPrivilege
SeSystemEnvironmentPrivilege
SeImpersonatePrivilege
```

![Windows Event ID 4672](screenshots/02-windows-4672-special-privileges.png)

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

![Wazuh Event ID 4672](screenshots/03-wazuh-4672-logon-id.png)

To dokładnie ten sam identyfikator sesji, który był widoczny lokalnie w Event Viewer:

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

![Wazuh Rule 67028](screenshots/04-wazuh-4672-rule-details.png)

---

# Co potwierdzono w Etapie 1

- [x] konto testowe `adm-ctworzewski` istnieje,
- [x] Windows generuje `4624`,
- [x] Windows generuje `4672`,
- [x] możliwa jest korelacja po `Logon ID`,
- [x] Wazuh odbiera `4672`,
- [x] Wazuh zachowuje użytkownika, domenę i `Logon ID`,
- [x] domyślna reguła Wazuh `67028` poprawnie klasyfikuje `4672`.

# Dlaczego ten etap jest ważny

Samo wykrycie `4672` nie oznacza jeszcze incydentu bezpieczeństwa. Windows może generować wiele zdarzeń związanych z tokenami, sesjami i działaniem systemu.

Dlatego projekt nie będzie opierał się wyłącznie na:

```text
4672 = ALERT
```

Docelowo detekcja ma uwzględniać również:

- właściwe konto uprzywilejowane,
- typ logowania,
- uruchomienie PowerShell,
- proces nadrzędny,
- wykonane polecenia,
- sekwencję zdarzeń w określonym czasie.

# Następny etap

## Etap 2 – Sysmon

Kolejny krok:

```text
instalacja Sysmon
        ↓
Event ID 1 – Process Create
        ↓
powershell.exe
        ↓
CommandLine
        ↓
User
        ↓
ParentImage
        ↓
Wazuh
```

Celem będzie sprawdzenie, czy po logowaniu konta uprzywilejowanego uruchomiono PowerShell oraz z jakim kontekstem procesowym.

# Status

✅ **Etap 1 zakończony**

```text
Windows 4624
        ↓
Windows 4672
        ↓
korelacja po Logon ID
        ↓
Wazuh 4672 / Rule 67028
```

🚧 **Następny krok: Sysmon / Process Create**
