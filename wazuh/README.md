# 🛡️ Wazuh Security Monitoring Lab

Praktyczne laboratorium do nauki monitoringu bezpieczeństwa, analizy zdarzeń Windows oraz tworzenia detekcji w systemie Wazuh.

Projekt jest częścią mojego środowiska **Home IT Lab** i służy do praktycznego poznawania monitoringu infrastruktury Windows, Active Directory oraz podstaw pracy z systemem SIEM.

---

## 🖥️ Środowisko

| Host | System | Rola |
|---|---|---|
| WAZUH-SRV | Ubuntu Server | Wazuh Manager |
| LAB-DC1 | Windows Server 2025 | Kontroler domeny Active Directory |
| LAB-W11-1 | Windows 11 | Stacja robocza w domenie |
| LAB-W11-2 | Windows 11 | Stacja robocza w domenie |

Wszystkie hosty Windows posiadają zainstalowane agenty Wazuh i przesyłają zdarzenia do centralnego serwera Wazuh.

---

## 🎯 Cele projektu

Celem projektu jest praktyczna nauka:

- monitorowania zdarzeń systemu Windows,
- analizy logów bezpieczeństwa,
- monitorowania Active Directory,
- wykrywania nieudanych prób logowania,
- monitorowania tworzenia i usuwania kont użytkowników,
- monitorowania zmian członkostwa w grupach,
- wykrywania zmian w grupach uprzywilejowanych,
- monitorowania aktywności PowerShell,
- File Integrity Monitoring,
- monitorowania zdarzeń Microsoft Defender,
- tworzenia własnych reguł Wazuh,
- analizy alertów,
- konfiguracji powiadomień,
- dokumentowania scenariuszy bezpieczeństwa.

---

## 🧪 Planowane scenariusze

### 1. Nieudane logowanie do domeny

Wygenerowanie nieudanych prób logowania do konta domenowego oraz analiza powstałych zdarzeń.

Zakres testu:

- Windows Security Event Log,
- Event ID związany z nieudanym logowaniem,
- analiza alertu w Wazuh,
- identyfikacja użytkownika oraz źródła logowania,
- utworzenie własnej reguły detekcyjnej.

---

### 2. Utworzenie użytkownika Active Directory

Utworzenie testowego konta domenowego i analiza zdarzenia w Wazuh.

Zakres testu:

- utworzenie konta użytkownika,
- Event Viewer,
- analiza Event ID,
- analiza Rule ID w Wazuh.

---

### 3. Usunięcie użytkownika Active Directory

Monitorowanie usunięcia konta użytkownika z Active Directory.

---

### 4. Zmiana członkostwa w grupach

Dodanie oraz usunięcie użytkownika z grupy Active Directory.

---

### 5. Dodanie użytkownika do grupy uprzywilejowanej

Monitorowanie zmian w grupach o podwyższonych uprawnieniach, między innymi:

- Domain Admins,
- Administrators,
- Enterprise Admins.

---

### 6. Monitoring PowerShell

Rejestrowanie oraz analiza aktywności PowerShell.

Planowane elementy:

- PowerShell Operational Log,
- Script Block Logging,
- analiza wykonywanych poleceń,
- wykrywanie nietypowej aktywności.

---

### 7. File Integrity Monitoring

Monitoring zmian w wybranym katalogu testowym.

Testowane operacje:

- utworzenie pliku,
- modyfikacja pliku,
- zmiana nazwy,
- usunięcie pliku.

Przykładowy katalog:

```text
C:\Wazuh-Test
```

---

### 8. Zatrzymanie agenta Wazuh

Test wykrywania sytuacji, w której agent Wazuh przestaje komunikować się z serwerem.

---

### 9. Microsoft Defender

Analiza zdarzeń generowanych przez Microsoft Defender.

Planowane testy:

- wykrycie testowego zagrożenia,
- analiza zdarzenia,
- korelacja z alertem Wazuh.

---

### 10. Własne reguły Wazuh

Tworzenie reguł dopasowanych do wybranych zdarzeń Windows i Active Directory.

Zakres:

- `rule.id`,
- `rule.level`,
- `rule.description`,
- `eventID`,
- filtrowanie alertów,
- ograniczanie niepotrzebnego szumu.

---

## 🔍 Schemat analizy zdarzenia

Każdy scenariusz będzie analizowany według podobnego schematu:

```text
Akcja testowa
     ↓
Windows Event Log
     ↓
Wazuh Agent
     ↓
Wazuh Manager
     ↓
Alert
     ↓
Analiza Event ID
     ↓
Analiza Rule ID
     ↓
Własna reguła lub konfiguracja
     ↓
Ponowny test
     ↓
Dokumentacja wyniku
```

Celem jest zrozumienie całej ścieżki zdarzenia, a nie tylko uzyskanie gotowego alertu.

---

## 🔎 Analizowane pola

Podczas pracy z alertami szczególna uwaga będzie zwracana na pola:

```text
rule.id
rule.level
rule.description
agent.name
data.win.system.eventID
data.win.eventdata.targetUserName
data.win.eventdata.subjectUserName
```

W zależności od typu zdarzenia analizowane będą również inne pola dostępne w logach Windows.

---

## 📁 Struktura projektu

```text
wazuh/
├── README.md
├── docs/
├── configs/
├── scripts/
└── screenshots/
    ├── agents/
    ├── architecture/
    └── detections/
```

### `docs`

Dokumentacja poszczególnych scenariuszy oraz konfiguracji.

Planowana struktura:

```text
docs/
├── 01-architecture.md
├── 02-agent-deployment.md
├── 03-windows-auditing.md
├── 04-failed-domain-logon.md
├── 05-ad-user-monitoring.md
├── 06-privileged-groups.md
├── 07-powershell-monitoring.md
└── 08-file-integrity-monitoring.md
```

### `configs`

Przykładowe konfiguracje używane w środowisku.

Planowane pliki:

```text
configs/
├── local_rules.xml
└── ossec.conf.example
```

Wrażliwe dane, hasła, klucze oraz dane produkcyjne nie będą umieszczane w repozytorium.

### `scripts`

Skrypty PowerShell wykorzystywane do generowania kontrolowanych zdarzeń testowych.

Przykładowo:

```text
scripts/
├── failed-logon-test.ps1
├── create-test-user.ps1
└── fim-test.ps1
```

### `screenshots`

Zrzuty ekranu dokumentujące konfigurację oraz wyniki testów.

---

## ✅ Aktualny stan projektu

- [x] Wazuh Manager zainstalowany
- [x] LAB-DC1 podłączony do Wazuh
- [x] LAB-W11-1 podłączony do Wazuh
- [x] LAB-W11-2 podłączony do Wazuh
- [ ] Dokumentacja architektury
- [ ] Konfiguracja Windows Audit Policy
- [ ] Test nieudanych logowań
- [ ] Monitoring tworzenia użytkowników Active Directory
- [ ] Monitoring usuwania użytkowników Active Directory
- [ ] Monitoring zmian członkostwa w grupach
- [ ] Monitoring grup uprzywilejowanych
- [ ] Monitoring PowerShell
- [ ] File Integrity Monitoring
- [ ] Monitoring Microsoft Defender
- [ ] Własne reguły Wazuh
- [ ] Powiadomienia o wybranych zdarzeniach
- [ ] Dokumentacja wyników testów

---

## 🚧 Aktualny etap

Pierwszym pełnym scenariuszem projektu będzie:

**Wykrywanie nieudanych prób logowania do domeny Active Directory.**

Test obejmie:

1. konfigurację audytu Windows,
2. wygenerowanie zdarzenia,
3. sprawdzenie zdarzenia w Event Viewer,
4. odnalezienie zdarzenia w Wazuh,
5. analizę Event ID,
6. analizę Rule ID,
7. przygotowanie własnej reguły,
8. ponowne wykonanie testu,
9. wykonanie zrzutów ekranu,
10. opisanie wyniku w dokumentacji.

---

## 📌 Założenia

Projekt wykonywany jest wyłącznie w izolowanym środowisku laboratoryjnym.

W repozytorium nie są publikowane:

- hasła,
- klucze agentów,
- tokeny API,
- dane produkcyjne,
- dane użytkowników,
- konfiguracje zawierające dane dostępowe.

Celem projektu jest praktyczna nauka administracji, monitoringu bezpieczeństwa i analizy zdarzeń w kontrolowanym środowisku testowym.
