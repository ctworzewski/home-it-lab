# 06 – Wykrywanie logowań na konta uprzywilejowane w Active Directory

## Cel projektu

Celem projektu jest wykrywanie i analiza logowań na konta uprzywilejowane w środowisku Active Directory.

Projekt ma pozwolić na szybką identyfikację sytuacji, w której konto posiadające podwyższone uprawnienia zostaje użyte do logowania, a następnie wzbogacić alert o najważniejsze informacje potrzebne administratorowi do weryfikacji zdarzenia.

Projekt jest kolejnym krokiem po prostych detekcjach opartych o pojedyncze Event ID i ma wprowadzić korelację kilku zdarzeń oraz analizę kontekstu logowania.

---

## Przykładowy scenariusz

Administrator loguje się na konto uprzywilejowane.

Windows zapisuje m.in.:

- Event ID `4624` – udane logowanie,
- Event ID `4672` – specjalne uprawnienia przypisane do nowej sesji.

Wazuh wykrywa zdarzenie i analizuje dodatkowe informacje:

- użytkownika,
- host,
- źródłowy adres IP,
- typ logowania,
- domenę,
- wcześniejsze nieudane próby logowania.

Na tej podstawie generowany jest alert przekazywany dalej do n8n.

---

## Planowany przepływ

```text
Windows / Active Directory
        ↓
      Wazuh
        ↓
Detekcja 4624 / 4672
        ↓
Korelacja i wzbogacenie alertu
        ↓
       n8n
        ↓
Analiza zdarzenia
        ↓
      E-mail
```

---

## Założenia projektu

- [ ] Monitorowanie Event ID `4624`
- [ ] Monitorowanie Event ID `4672`
- [ ] Identyfikacja kont uprzywilejowanych
- [ ] Korelacja logowania z przyznaniem specjalnych uprawnień
- [ ] Pobranie nazwy użytkownika
- [ ] Pobranie domeny
- [ ] Pobranie nazwy hosta
- [ ] Pobranie źródłowego adresu IP
- [ ] Pobranie typu logowania
- [ ] Weryfikacja wcześniejszych zdarzeń `4625`
- [ ] Utworzenie własnej reguły Wazuh
- [ ] Test logowania kontem administracyjnym
- [ ] Przekazanie alertu do n8n
- [ ] Przygotowanie czytelnego powiadomienia e-mail
- [ ] Dokumentacja wyników i screenshoty
- [ ] Instalacja i konfiguracja Sysmon
- [ ] Monitoring Sysmon Event ID `1`
- [ ] Monitoring Sysmon Event ID `3`
- [ ] Włączenie PowerShell Script Block Logging
- [ ] Monitoring Event ID `4104`
- [ ] Korelacja logowania konta uprzywilejowanego z uruchomieniem PowerShell
- [ ] Przygotowanie własnej reguły dla podejrzanego zachowania
- [ ] Active Response – zakończenie procesu PowerShell
- [ ] Active Response – test czasowej izolacji hosta w LAB

---

## Informacje, które powinien zawierać alert

Docelowy alert powinien zawierać co najmniej:

| Pole | Opis |
|---|---|
| Host | komputer, na którym wykryto logowanie |
| Użytkownik | konto uprzywilejowane |
| Domena | domena Active Directory |
| Event ID | zdarzenie Windows |
| Rule ID | reguła Wazuh |
| Logon Type | typ logowania |
| Source IP | adres źródłowy |
| Workstation | komputer źródłowy |
| Timestamp | czas zdarzenia |
| Previous Failed Logons | wcześniejsze nieudane próby logowania |

---

## Co chcę osiągnąć

Projekt ma pozwolić mi przejść od prostego wykrywania pojedynczych zdarzeń do bardziej świadomej analizy aktywności kont uprzywilejowanych.

Główne cele edukacyjne:

- lepsze zrozumienie logów bezpieczeństwa Windows,
- analiza Event ID `4624` i `4672`,
- korelacja zdarzeń w Wazuh,
- budowanie własnych reguł detekcji,
- wzbogacanie alertów o dodatkowy kontekst,
- integracja Wazuh z n8n,
- tworzenie alertów przydatnych z punktu widzenia administratora i SOC.

---

## Kryterium zakończenia projektu

Projekt zostanie uznany za zakończony, gdy:

- Wazuh poprawnie wykryje logowanie na konto uprzywilejowane,
- alert będzie zawierał najważniejsze informacje o logowaniu,
- zdarzenie zostanie przekazane do n8n,
- n8n wygeneruje czytelne powiadomienie e-mail,
- scenariusz zostanie przetestowany w środowisku LAB,
- całość zostanie udokumentowana na GitHub.

---

## Status

🚧 **Projekt w trakcie realizacji**

Kolejne etapy będą dodawane wraz z rozwojem projektu.


---

## Rozszerzenie projektu – Sysmon i PowerShell

Po wykryciu logowania na konto uprzywilejowane projekt zostanie rozszerzony o monitoring aktywności wykonywanej po zalogowaniu.

Celem będzie sprawdzenie nie tylko **kto się zalogował**, ale również **co zrobił po zalogowaniu**.

### Sysmon

Planowane jest wdrożenie Sysmon i monitorowanie wybranych zdarzeń, przede wszystkim:

- Event ID `1` – Process Create,
- Event ID `3` – Network Connection.

Najważniejszym elementem będzie wykrywanie uruchomienia:

- `powershell.exe`,
- `pwsh.exe`,
- `cmd.exe`.

Przykładowe informacje zbierane z Sysmon:

- użytkownik,
- uruchomiony proces,
- proces nadrzędny,
- CommandLine,
- Process ID,
- Parent Process ID,
- adres docelowy,
- port docelowy.

Przykładowy scenariusz:

```text
4624 / 4672
        ↓
Logowanie konta uprzywilejowanego
        ↓
Sysmon Event ID 1
        ↓
Uruchomienie powershell.exe
        ↓
Analiza CommandLine
```

---

## PowerShell Script Block Logging

Projekt zostanie rozszerzony również o PowerShell Script Block Logging.

Najważniejsze zdarzenie:

- Event ID `4104` – wykonany kod PowerShell.

Pozwoli to analizować nie tylko samo uruchomienie `powershell.exe`, ale również polecenia i fragmenty kodu wykonywane w PowerShell.

Planowany przepływ:

```text
Privileged Account Login
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

## Active Response

Końcowym etapem projektu będzie wykorzystanie mechanizmu Wazuh Active Response.

Reakcja nie będzie uruchamiana po samym wykryciu PowerShella.

Active Response zostanie wywołany dopiero po spełnieniu określonych warunków, np.:

- logowanie na konto uprzywilejowane,
- uruchomienie PowerShell,
- wykrycie określonego polecenia lub wzorca,
- podniesiony poziom alertu Wazuh.

### Active Response – etap 1

Pierwszym scenariuszem będzie automatyczne zakończenie procesu PowerShell.

Planowana reakcja:

- identyfikacja procesu,
- zapisanie PID,
- zapisanie użytkownika,
- zapisanie hosta,
- zakończenie procesu `powershell.exe`,
- zapisanie informacji o wykonanej reakcji,
- wysłanie alertu przez n8n.

Przepływ:

```text
Privileged Account Login
        ↓
PowerShell uruchomiony
        ↓
Podejrzane polecenie
        ↓
Wazuh Rule
        ↓
Active Response
        ↓
Zakończenie procesu
        ↓
n8n
        ↓
E-mail
```

### Active Response – etap 2

Po poprawnym przetestowaniu pierwszej wersji projekt może zostać rozszerzony o czasową izolację hosta.

Przykładowy scenariusz:

- Wazuh wykrywa określone zachowanie,
- Active Response uruchamia skrypt,
- Windows Firewall ogranicza ruch sieciowy hosta,
- pozostawiony zostaje dostęp wymagany do obsługi incydentu,
- po określonym czasie host może zostać automatycznie przywrócony do normalnego stanu.

Ta część będzie wykonywana wyłącznie w środowisku LAB.

---

## Docelowy scenariusz projektu

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
Ocena reguły
        ↓
Active Response
        ↓
Zakończenie procesu / izolacja hosta
        ↓
n8n
        ↓
E-mail z informacją o incydencie
```

---

## Dodatkowe cele edukacyjne

Rozszerzenie projektu ma pozwolić nauczyć się:

- wdrażania i konfiguracji Sysmon,
- analizy Process Create,
- analizy relacji Parent / Child Process,
- analizy CommandLine,
- PowerShell Script Block Logging,
- korelacji kilku źródeł logów,
- budowania własnych reguł Wazuh,
- reagowania na incydenty przy użyciu Active Response,
- automatyzacji reakcji,
- wzbogacania alertów w n8n,
- budowania prostego scenariusza SOC / Detection Engineering.
