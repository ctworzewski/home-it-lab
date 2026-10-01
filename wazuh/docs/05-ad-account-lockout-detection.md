# 05 — Wykrywanie blokady konta Active Directory

## O projekcie

Projekt będzie pokazywał wykrywanie blokady konta użytkownika w Active Directory przy użyciu Wazuh.

Założenie jest proste:

1. Active Directory samo blokuje konto po kilku błędnych próbach logowania.
2. Wazuh wykrywa Event ID 4740.
3. n8n wysyła czytelne powiadomienie e-mail do administratora.

Na tym etapie nie używamy jeszcze Active Response.

---

## Plan projektu

- [ ] Sprawdzić politykę blokady konta w Active Directory
- [ ] Wygenerować testową blokadę konta użytkownika
- [ ] Potwierdzić Event ID 4740 na kontrolerze domeny
- [ ] Sprawdzić, czy Wazuh odbiera zdarzenie 4740
- [ ] Utworzyć własną regułę Wazuh dla blokady konta
- [ ] Wyciągnąć z alertu nazwę użytkownika
- [ ] Wyciągnąć nazwę komputera źródłowego
- [ ] Wysłać alert z Wazuh do n8n
- [ ] Przygotować czytelny e-mail dla administratora
- [ ] Przetestować cały przepływ
- [ ] Dodać screenshoty do GitHub
- [ ] Uzupełnić dokumentację projektu

---

## Docelowy przepływ

```text
Błędne logowania
      ↓
Active Directory
      ↓
Event ID 4740
      ↓
Wazuh
      ↓
n8n
      ↓
E-mail do administratora
```
