# 06 – Wykrywanie logowań na konta uprzywilejowane w Active Directory

## Cel projektu

Celem projektu jest wykrywanie i analiza logowań na konta uprzywilejowane w środowisku Active Directory oraz monitorowanie aktywności wykonywanej po zalogowaniu.

Projekt ma odpowiedzieć nie tylko na pytanie:

> **Kto i skąd zalogował się na konto uprzywilejowane?**

ale również:

> **Co użytkownik zrobił po zalogowaniu i czy jego aktywność wymaga dodatkowej weryfikacji?**

Projekt jest kolejnym krokiem po prostych detekcjach opartych o pojedyncze Event ID. Jego głównym celem jest nauka korelacji kilku źródeł logów, budowania własnych reguł detekcji oraz automatycznej reakcji na wybrane zdarzenia.

---

## Zakres projektu

Projekt obejmuje:

- wykrywanie logowań na konta uprzywilejowane,
- analizę zdarzeń Windows Security,
- monitoring procesów za pomocą Sysmon,
- monitoring wykonywanego kodu PowerShell,
- korelację zdarzeń w Wazuh,
- wzbogacanie alertów o dodatkowy kontekst,
- integrację z n8n,
- powiadomienia e-mail,
- test mechanizmu Wazuh Active Response.

---

## Etap 1 – Logowanie na konto uprzywilejowane

Podstawą projektu będzie analiza zdarzeń:

- Event ID `4624` – udane logowanie,
- Event ID `4672` – specjalne uprawnienia przypisane do nowej sesji,
- Event ID `4625` – nieudane logowanie.

Wazuh powinien zebrać i zaprezentować m.in.:

- użytkownika,
- domenę,
- host,
- źródłowy adres IP,
- nazwę stacji źródłowej,
- typ logowania,
- czas zdarzenia.

### Przykładowy scenariusz

```text
Użytkownik uprzywilejowany
        ↓
Udane logowanie
        ↓
Windows Event ID 4624
        ↓
Windows Event ID 4672
        ↓
Wazuh
        ↓
Alert bezpieczeństwa
```

---

## Etap 2 – Sysmon

Po wykryciu logowania na konto uprzywilejowane projekt zostanie rozszerzony o monitoring aktywności wykonywanej po zalogowaniu.

Do tego celu zostanie wykorzystany Sysmon.

Na początek monitorowane będą przede wszystkim:

- Event ID `1` – Process Create,
- Event ID `3` – Network Connection.

Najważniejszym elementem będzie wykrywanie uruchomienia procesów takich jak:

- `powershell.exe`,
- `pwsh.exe`,
- `cmd.exe`.

### Informacje analizowane z Sysmon

- użytkownik,
- nazwa procesu,
- ścieżka procesu,
- proces nadrzędny,
- CommandLine,
- Process ID,
- Parent Process ID,
- adres docelowy,
- port docelowy.

### Przykładowy scenariusz

```text
4624 / 4672
        ↓
Logowanie konta uprzywilejowanego
        ↓
Sysmon Event ID 1
        ↓
powershell.exe
        ↓
Analiza procesu i CommandLine
```

---

## Etap 3 – PowerShell Script Block Logging

Sam fakt uruchomienia `powershell.exe` nie musi oznaczać podejrzanej aktywności.

Dlatego projekt zostanie rozszerzony o PowerShell Script Block Logging.

Najważniejsze zdarzenie:

- Event ID `4104` – wykonany kod PowerShell.

Pozwoli to analizować nie tylko uruchomienie procesu PowerShell, ale również wykonywane polecenia i fragmenty skryptów.

### Planowany przepływ

```text
Logowanie konta uprzywilejowanego
        ↓
Sysmon Event ID 1
        ↓
powershell.exe
        ↓
PowerShell Event ID 4104
        ↓
Wazuh
        ↓
Korelacja zdarzeń
```

---

## Etap 4 – Korelacja w Wazuh

Docelowo alert nie powinien być generowany wyłącznie na podstawie pojedynczego zdarzenia.

Projekt ma umożliwić korelację kilku elementów, np.:

```text
Konto uprzywilejowane
        +
Udane logowanie
        +
Uruchomienie PowerShell
        +
Określone polecenie
        =
Alert o podwyższonym poziomie
```

Dodatkowo możliwa będzie analiza wcześniejszych zdarzeń `4625`, aby sprawdzić, czy przed poprawnym logowaniem występowały nieudane próby uwierzytelnienia.

---

## Etap 5 – Integracja z n8n

Po wykryciu zdarzenia Wazuh przekaże alert do n8n.

n8n będzie odpowiedzialny za przygotowanie czytelnego powiadomienia zawierającego najważniejsze informacje o zdarzeniu.

### Informacje w alercie

| Pole | Opis |
|---|---|
| Host | komputer, na którym wykryto aktywność |
| Użytkownik | konto uprzywilejowane |
| Domena | domena Active Directory |
| Event ID | zdarzenie Windows / Sysmon |
| Rule ID | reguła Wazuh |
| Logon Type | typ logowania |
| Source IP | źródłowy adres IP |
| Workstation | komputer źródłowy |
| Process | uruchomiony proces |
| Parent Process | proces nadrzędny |
| CommandLine | linia poleceń |
| Timestamp | czas zdarzenia |
| Previous Failed Logons | wcześniejsze nieudane próby logowania |

---

## Etap 6 – Wazuh Active Response

Końcowym etapem projektu będzie wykorzystanie mechanizmu Wazuh Active Response.

Active Response **nie będzie uruchamiany po samym wykryciu PowerShella**.

Reakcja zostanie wykonana dopiero po spełnieniu określonych warunków, np.:

- logowanie na konto uprzywilejowane,
- uruchomienie PowerShell,
- wykrycie określonego polecenia lub wzorca,
- wygenerowanie przez Wazuh alertu o odpowiednio wysokim poziomie.

### Active Response – etap 1

Pierwszym testowanym scenariuszem będzie automatyczne zakończenie procesu PowerShell.

Planowana reakcja:

- identyfikacja procesu,
- zapisanie PID,
- zapisanie użytkownika,
- zapisanie hosta,
- zakończenie procesu `powershell.exe`,
- zapisanie informacji o wykonanej reakcji,
- przekazanie informacji do n8n,
- wysłanie powiadomienia e-mail.

### Active Response – etap 2

Po poprawnym przetestowaniu pierwszej wersji projekt może zostać rozszerzony o czasową izolację hosta.

Przykładowy scenariusz:

- Wazuh wykrywa określone zachowanie,
- Active Response uruchamia skrypt,
- Windows Firewall ogranicza ruch sieciowy hosta,
- pozostawiony zostaje dostęp wymagany do obsługi incydentu,
- po określonym czasie host zostaje przywrócony do normalnego stanu.

Ta część będzie wykonywana wyłącznie w środowisku LAB.

---

## Docelowy przepływ projektu

```text
Active Directory
        ↓
4624 / 4672
        ↓
Logowanie konta uprzywilejowanego
        ↓
Sysmon Event ID 1
        ↓
PowerShell / CMD
        ↓
PowerShell Event ID 4104
        ↓
Wazuh
        ↓
Korelacja zdarzeń
        ↓
Własna reguła detekcji
        ↓
Active Response
        ↓
Zakończenie procesu / izolacja hosta
        ↓
n8n
        ↓
Powiadomienie e-mail
```

---

## Checklista

- [ ] Monitorowanie Event ID `4624`
- [ ] Monitorowanie Event ID `4672`
- [ ] Monitorowanie Event ID `4625`
- [ ] Identyfikacja kont uprzywilejowanych
- [ ] Pobranie użytkownika, domeny, hosta i Source IP
- [ ] Analiza Logon Type
- [ ] Instalacja i konfiguracja Sysmon
- [ ] Monitoring Sysmon Event ID `1`
- [ ] Monitoring Sysmon Event ID `3`
- [ ] Monitoring `powershell.exe`, `pwsh.exe` i `cmd.exe`
- [ ] Włączenie PowerShell Script Block Logging
- [ ] Monitoring Event ID `4104`
- [ ] Korelacja logowania z aktywnością procesu
- [ ] Korelacja z wcześniejszymi zdarzeniami `4625`
- [ ] Utworzenie własnej reguły Wazuh
- [ ] Test scenariusza w środowisku LAB
- [ ] Przekazanie alertu do n8n
- [ ] Przygotowanie powiadomienia e-mail
- [ ] Active Response – zakończenie procesu PowerShell
- [ ] Active Response – test czasowej izolacji hosta
- [ ] Dokumentacja wyników
- [ ] Dodanie screenshotów z testów

---

## Czego chcę się nauczyć

Projekt ma pozwolić mi rozwinąć umiejętności w zakresie:

- analizy Windows Security Logs,
- konfiguracji i analizy Sysmon,
- analizy relacji Parent / Child Process,
- analizy CommandLine,
- PowerShell Script Block Logging,
- korelacji kilku źródeł logów,
- tworzenia własnych reguł Wazuh,
- integracji Wazuh z n8n,
- automatyzacji reakcji na incydenty,
- wykorzystania Wazuh Active Response,
- budowania praktycznych scenariuszy Detection Engineering / SOC.

---

## Kryterium zakończenia projektu

Projekt zostanie uznany za zakończony, gdy:

- Wazuh poprawnie wykryje logowanie na konto uprzywilejowane,
- zostanie wykryte uruchomienie PowerShell lub CMD po zalogowaniu,
- Sysmon poprawnie przekaże informacje o procesie,
- PowerShell Script Block Logging dostarczy zdarzenia `4104`,
- Wazuh skoreluje wybrane zdarzenia,
- alert będzie zawierał najważniejszy kontekst dotyczący aktywności,
- zdarzenie zostanie przekazane do n8n,
- n8n wygeneruje czytelne powiadomienie e-mail,
- Active Response zostanie poprawnie przetestowany w środowisku LAB,
- cały scenariusz zostanie udokumentowany na GitHub.

---

## Status

🚧 **Projekt w trakcie realizacji**

Kolejne etapy będą dodawane wraz z rozwojem projektu.
