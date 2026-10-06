# 07 – AD Privilege Escalation Detection

## Cel projektu

Celem projektu jest wykrywanie zmian członkostwa w uprzywilejowanych grupach Active Directory oraz korelacja zdarzeń pozwalająca określić:

- kto wykonał zmianę,
- komu nadano uprawnienia,
- do jakiej grupy został dodany użytkownik,
- kiedy i na którym kontrolerze domeny wykonano operację,
- czy konto po otrzymaniu uprawnień wykonało kolejne działania administracyjne.

Projekt rozszerza wcześniejsze mechanizmy monitorowania kont uprzywilejowanych o scenariusz potencjalnej **eskalacji uprawnień w Active Directory**.

---

## Kontekst bezpieczeństwa

Dodanie użytkownika do uprzywilejowanej grupy Active Directory może być normalną operacją administracyjną, ale może również oznaczać:

- nieautoryzowaną zmianę,
- błąd konfiguracyjny,
- przejęcie konta administratora,
- próbę eskalacji uprawnień,
- działanie osoby wewnętrznej,
- przygotowanie persistence w domenie.

Szczególnie istotne są zmiany dotyczące grup takich jak:

- `Domain Admins`
- `Enterprise Admins`
- `Schema Admins`
- `Administrators`
- `Account Operators`
- `Server Operators`
- `Backup Operators`
- `Group Policy Creator Owners`

Sama informacja o zmianie członkostwa w grupie nie wystarcza.

W analizie bezpieczeństwa ważne jest również ustalenie:

```text
KTO
↓
KOGO
↓
DO JAKIEJ GRUPY
↓
KIEDY
↓
NA KTÓRYM DC
↓
CO STAŁO SIĘ PÓŹNIEJ
```

---

## Monitorowane zdarzenia Windows

Projekt wykorzystuje zdarzenia Windows Security związane ze zmianami członkostwa w grupach.

| Event ID | Znaczenie |
|---|---|
| `4728` | użytkownik został dodany do globalnej grupy zabezpieczeń |
| `4729` | użytkownik został usunięty z globalnej grupy zabezpieczeń |
| `4732` | użytkownik został dodany do lokalnej grupy zabezpieczeń |
| `4733` | użytkownik został usunięty z lokalnej grupy zabezpieczeń |
| `4756` | użytkownik został dodany do uniwersalnej grupy zabezpieczeń |
| `4757` | użytkownik został usunięty z uniwersalnej grupy zabezpieczeń |

Pierwszy etap projektu koncentruje się głównie na:

```text
4728
4732
4756
```

czyli zdarzeniach związanych z **nadaniem członkostwa w grupie**.

---

## Główna logika detekcji

Nie każde dodanie użytkownika do grupy powinno generować alert wysokiego poziomu.

Reguły Wazuh powinny filtrować zdarzenia i reagować przede wszystkim wtedy, gdy zmiana dotyczy grup uprzywilejowanych.

Przykładowa logika:

```text
4728 / 4732 / 4756
          |
          v
Czy zmiana dotyczy grupy uprzywilejowanej?
          |
        TAK
          |
          v
Alert HIGH / CRITICAL
```

---

## Kto wykonał zmianę

W zdarzeniu Windows istotna jest sekcja `Subject`.

Pozwala ona ustalić konto, które wykonało operację.

Przykład:

```text
SubjectUserName: admin.ctworzewski
SubjectDomainName: CYBER
SubjectLogonId: 0x123456
```

Informacja ta odpowiada na pytanie:

> Kto wykonał zmianę?

---

## Kto otrzymał uprawnienia

Drugim kluczowym elementem jest konto dodawane do grupy.

Przykład:

```text
MemberName:
CN=user.test,CN=Users,DC=cyber,DC=local
```

Informacja ta odpowiada na pytanie:

> Komu nadano uprawnienia?

---

## Do jakiej grupy dodano konto

Kolejną informacją jest nazwa grupy docelowej.

Przykład:

```text
TargetUserName: Domain Admins
TargetDomainName: CYBER
```

Dzięki temu możliwe jest rozróżnienie zwykłych zmian administracyjnych od zmian wysokiego ryzyka.

---

## Przykład alertu

Docelowy alert powinien zawierać najważniejsze informacje potrzebne administratorowi lub analitykowi SOC.

```text
PRIVILEGE ESCALATION DETECTED

Operator:
admin.ctworzewski

Account:
user.test

Group:
Domain Admins

Event ID:
4728

Domain Controller:
LAB-DC1

Domain:
CYBER.LOCAL

Severity:
HIGH
```

---

# Korelacja zdarzeń

Najważniejszym elementem projektu jest połączenie kilku niezależnych zdarzeń w jeden kontekst bezpieczeństwa.

Samo wykrycie `4728` informuje jedynie o zmianie grupy.

Znacznie większą wartość daje wykrycie sekwencji:

```text
4728
user.test został dodany do Domain Admins

        ↓

4624
user.test zalogował się

        ↓

4672
konto otrzymało specjalne uprawnienia

        ↓

PowerShell / Sysmon
konto rozpoczęło działania administracyjne
```

Takie zdarzenia mogą zostać potraktowane jako jeden potencjalny incydent:

```text
Possible AD Privilege Escalation
```

---

## Przykładowy timeline incydentu

```text
13:40
admin01 loguje się na LAB-DC1

13:41
admin01 dodaje user.test
do Domain Admins

13:43
user.test loguje się do domeny

13:43
konto otrzymuje specjalne uprawnienia

13:45
user.test uruchamia PowerShell

13:47
konto wykonuje operacje administracyjne
```

Dzięki temu administrator nie widzi już tylko pojedynczego alertu.

Widoczna jest pełna sekwencja działań.

---

# Scenariusz laboratoryjny

Planowany test będzie wykonywany w środowisku LAB.

## Środowisko

```text
LAB-DC1
LAB-W11-1
LAB-W11-2
Wazuh Manager
n8n
```

---

## Plan testu

1. Utworzenie zwykłego użytkownika domenowego.
2. Dodanie użytkownika do `Domain Admins`.
3. Wygenerowanie eventu `4728`.
4. Odebranie zdarzenia przez Wazuh.
5. Dopasowanie własnej reguły Wazuh.
6. Pobranie informacji:
   - operator,
   - użytkownik,
   - grupa,
   - domena,
   - SID,
   - DC,
   - czas zdarzenia.
7. Przekazanie danych do n8n.
8. Wygenerowanie alertu SOC.
9. Zalogowanie się na konto po otrzymaniu uprawnień.
10. Wykrycie `4624`.
11. Wykrycie `4672`.
12. Opcjonalne wykrycie aktywności PowerShell lub Sysmon.
13. Zbudowanie jednego timeline incydentu.

---

# Przykład testu PowerShell

Przykładowa operacja laboratoryjna:

```powershell
Add-ADGroupMember -Identity "Domain Admins" -Members "user.test"
```

Po wykonaniu operacji oczekiwanym rezultatem jest pojawienie się odpowiedniego zdarzenia Windows Security.

---

# Wartość dla administratora

Projekt pozwala szybko odpowiedzieć na pytanie:

> Czy ktoś właśnie nadał użytkownikowi wysokie uprawnienia w Active Directory?

Administrator otrzymuje informację:

```text
KTO
+
KOGO
+
DO JAKIEJ GRUPY
+
KIEDY
+
NA KTÓRYM DC
```

Pozwala to szybko zweryfikować, czy operacja:

- była planowana,
- była wykonana przez właściwego administratora,
- dotyczyła właściwego konta,
- była zgodna z procedurami.

---

# Wartość dla organizacji

Projekt może pomóc wykryć:

- nieautoryzowane nadanie uprawnień,
- przejęcie konta administratora,
- eskalację uprawnień,
- nieuprawnione zmiany w AD,
- tymczasowe dodanie konta do grupy administratorów,
- próby ukrycia działań po wykonaniu operacji.

Przykład:

```text
12:10
user.test → Domain Admins

12:12
logowanie uprzywilejowane

12:15
działania administracyjne

12:25
user.test ← Domain Admins
```

Po zakończeniu działań konto może nie być już członkiem `Domain Admins`.

Bez monitoringu historycznego administrator mógłby nie zauważyć incydentu.

Wazuh zachowuje jednak pełny kontekst zdarzeń.

---

# Wartość podczas analizy incydentu

Przykładowa sytuacja:

> Na serwerze wykryto nieautoryzowaną zmianę i trzeba ustalić, kto ją wykonał.

Dzięki korelacji możliwe jest odtworzenie sekwencji:

```text
14:02
4728
jan.kowalski → Domain Admins

14:04
4624
jan.kowalski → SRV-FILE01

14:04
4672
Privileged Logon

14:07
PowerShell

14:13
4729
jan.kowalski ← Domain Admins
```

Pozwala to przejść od prostego zbierania logów do rzeczywistej analizy bezpieczeństwa.

---

# Architektura rozwiązania

```text
Active Directory
      |
      v
Windows Security Logs
      |
      v
Wazuh Agent
      |
      v
Wazuh Manager
      |
      v
Custom Rules
      |
      v
Correlation
      |
      v
n8n
      |
      v
SOC Alert
```

Opcjonalnie:

```text
Sysmon
  |
  v
Process Activity
  |
  v
Wazuh
```

---

# Technologie

Projekt wykorzystuje:

- Active Directory
- Windows Server 2025
- Windows Security Auditing
- Wazuh
- n8n
- PowerShell
- Sysmon
- Microsoft Event Viewer

---

# MITRE ATT&CK

Główne mapowanie projektu:

```text
T1098 – Account Manipulation
```

Projekt dotyczy przede wszystkim zmian kont i członkostwa w grupach uprzywilejowanych.

Możliwe dalsze rozszerzenia mogą dotyczyć:

- Privilege Escalation,
- Persistence,
- Valid Accounts,
- PowerShell,
- Account Manipulation.

---

# Planowane rozszerzenie – Active Response

Active Response nie będzie wykonywany automatycznie dla każdej zmiany.

Operacje dotyczące grup administracyjnych mogą być legalnym działaniem administratora.

Dlatego planowana logika wygląda następująco:

```text
AD Event
   |
   v
Wazuh
   |
   v
Correlation
   |
   v
Risk Evaluation
   |
   v
n8n
   |
   v
SOC Alert
   |
   v
Optional Active Response
```

Automatyczna reakcja może zostać wykorzystana dopiero po zebraniu odpowiedniego kontekstu.

---

# Status projektu

## Detekcja

- [ ] konfiguracja audytu zmian grup Active Directory
- [ ] test Event ID `4728`
- [ ] test Event ID `4732`
- [ ] test Event ID `4756`
- [ ] identyfikacja pól zdarzeń Windows
- [ ] custom rules Wazuh
- [ ] filtrowanie grup uprzywilejowanych

## Enrichment

- [ ] identyfikacja operatora
- [ ] identyfikacja użytkownika
- [ ] identyfikacja grupy
- [ ] identyfikacja SID
- [ ] identyfikacja DC
- [ ] identyfikacja domeny

## Automatyzacja

- [ ] workflow n8n
- [ ] alert HTML SOC
- [ ] mapowanie pól Wazuh → n8n

## Korelacja

- [ ] korelacja `4728 → 4624`
- [ ] korelacja `4624 → 4672`
- [ ] korelacja zdarzeń grup uprzywilejowanych
- [ ] timeline incydentu

## Rozszerzenia

- [ ] integracja Sysmon
- [ ] analiza aktywności PowerShell
- [ ] mapowanie MITRE ATT&CK
- [ ] dokumentacja testów
- [ ] screenshoty
- [ ] opcjonalny Active Response

---

# Oczekiwany efekt końcowy

Celem projektu jest przejście od prostego:

```text
Wazuh wykrył Event ID 4728
```

do:

```text
Wazuh wykrył potencjalną eskalację uprawnień.

Operator:
admin01

Account:
user.test

Group:
Domain Admins

Następnie:
user.test zalogował się i otrzymał specjalne uprawnienia.

Severity:
HIGH
```

Projekt ma pokazać praktyczne połączenie:

```text
Active Directory
+
Windows Security Logs
+
Wazuh
+
Custom Rules
+
Correlation
+
n8n
+
Sysmon
+
Incident Analysis
```

---

## Status

**Projekt w trakcie realizacji.**

Kolejne etapy będą uzupełniane wraz z konfiguracją środowiska, testami oraz budową korelacji zdarzeń.
