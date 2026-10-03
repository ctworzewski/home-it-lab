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
