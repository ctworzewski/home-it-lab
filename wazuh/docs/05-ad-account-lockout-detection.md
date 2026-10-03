# 05 --- Wykrywanie blokady konta Active Directory

## Cel projektu

Celem projektu jest wykrywanie **blokady konta użytkownika Active
Directory** za pomocą Wazuh oraz automatyczne powiadomienie
administratora przez **n8n + SMTP**.

W tym etapie konto jest blokowane przez politykę domenową Active
Directory. Wazuh odpowiada za detekcję zdarzenia, a n8n za przetworzenie
alertu i wysłanie czytelnego powiadomienia.

### Aktualny przepływ

``` text
2 × błędne hasło
        ↓
Active Directory Account Lockout Policy
        ↓
Event ID 4740 na LAB-DC1
        ↓
Wazuh Rule ID 60115 / Level 9
        ↓
Integracja Wazuh
        ↓
Webhook n8n
        ↓
Normalize 4740
        ↓
IF 4740 + 60115
        ↓
Ollama
        ↓
SMTP
        ↓
E-mail administratora
```

------------------------------------------------------------------------

## Status projektu

### Zrealizowane

-   [x] Sprawdzić politykę blokady konta w Active Directory
-   [x] Skonfigurować testowy próg 2 błędnych logowań
-   [x] Zweryfikować konfigurację GPO za pomocą PowerShell
-   [x] Wygenerować testową blokadę konta użytkownika
-   [x] Potwierdzić Event ID 4740 na kontrolerze domeny
-   [x] Sprawdzić, czy Wazuh odbiera zdarzenie 4740
-   [x] Zidentyfikować wbudowaną regułę Wazuh 60115
-   [x] Potwierdzić nazwę zablokowanego użytkownika i komputer źródłowy
-   [x] Zweryfikować CIS/SCA --- `failed` oraz `passed`
-   [x] Wysłać alert z Wazuh do n8n
-   [x] Znormalizować i odfiltrować `4740 / 60115` w n8n
-   [x] Przygotować czytelny e-mail dla administratora
-   [x] Przetestować cały przepływ Wazuh → n8n → SMTP

### Kolejne etapy

-   [ ] Skorelować wcześniejsze zdarzenia `4625` z blokadą `4740`
-   [ ] Dodać adres IP źródła, jeżeli będzie dostępny w zdarzeniach
-   [ ] Wzbogacić alert o dane Active Directory
-   [ ] Rozbudować końcową wiadomość SMTP
-   [ ] Opcjonalnie dodać analizę lokalnym modelem Ollama
-   [ ] Wykonać finalny test korelacji i uzupełnić podsumowanie projektu

------------------------------------------------------------------------

## Środowisko LAB

  Element              Wartość
  -------------------- ---------------
  Domena               `cyber.local`
  Domena NetBIOS       `CYBER`
  Kontroler domeny     `LAB-DC1`
  Stacja robocza       `LAB-W11-1`
  Użytkownik testowy   `jkowalski`
  Windows Event ID     `4740`
  Wazuh Rule ID        `60115`
  Wazuh Rule Level     `9`

------------------------------------------------------------------------

# Etap 1 --- Detekcja i powiadomienie

## 1. Konfiguracja Account Lockout Policy

Na potrzeby kontrolowanego testu w LAB ustawiono:

``` text
Account lockout threshold: 2 błędne próby logowania
Account lockout duration: 10 minut
Reset account lockout counter after: 10 minut
```

Konfigurację zweryfikowano zarówno w Group Policy Management, jak i za
pomocą PowerShell.

![Konfiguracja Account Lockout
Policy](../screenshots/01-account-lockout-policy-gpo-powershell.png)

------------------------------------------------------------------------

## 2. Test blokady konta

Na stacji `LAB-W11-1` wykonano dwie błędne próby logowania na konto
domenowe `CYBER\jkowalski`.

Po osiągnięciu skonfigurowanego progu Active Directory zablokowało
konto.

![Zablokowane konto na
LAB-W11-1](../screenshots/09-account-lockout-lab-w11-1-final.png)

------------------------------------------------------------------------

## 3. Event ID 4740 na kontrolerze domeny

Na `LAB-DC1` pojawiło się zdarzenie **4740 --- A user account was locked
out**.

``` text
Account Name:         jkowalski
Caller Computer Name: LAB-W11-1
Computer:             LAB-DC1.cyber.local
Event ID:             4740
```

Pole `Caller Computer Name` pozwala wskazać komputer, z którego
pochodziły próby uwierzytelnienia prowadzące do blokady.

![Event ID 4740 na kontrolerze
domeny](../screenshots/07-event-4740-domain-controller-final.png)

------------------------------------------------------------------------

## 4. Detekcja w Wazuh

Wazuh odebrał Event ID `4740` z agenta `LAB-DC1`.

Nie było potrzeby tworzenia własnej reguły detekcyjnej, ponieważ Wazuh
posiada wbudowaną regułę:

``` text
Rule ID:      60115
Rule Level:   9
Description:  User account locked out (multiple login errors)
```

![Detekcja Rule ID 60115 w
Wazuh](../screenshots/08-wazuh-rule-60115-detection.png)

Szczegóły dokumentu potwierdzają Event ID `4740`, konto `jkowalski` oraz
`Caller Computer Name: LAB-W11-1`.

![Szczegóły Event ID 4740 w
Wazuh](../screenshots/11-wazuh-event-4740-details-final.png)

------------------------------------------------------------------------

## 5. Weryfikacja CIS / SCA

Wazuh Security Configuration Assessment (SCA) wykorzystano do
sprawdzenia ustawienia `Account lockout threshold`.

Przy wartości `0` kontrola została oznaczona jako **failed**. Po
ustawieniu niezerowego progu zgodnego z wymaganiem kontroli wynik
zmienił się na **passed**.

![CIS Account Lockout Threshold -
porównanie](../screenshots/06-cis-account-lockout-threshold-comparison.png)

Źródło: [CIS Password Policy
Guide](https://www.cisecurity.org/insights/white-papers/cis-password-policy-guide)

------------------------------------------------------------------------

## 6. Integracja Wazuh → n8n

Wazuh Manager przekazuje do dedykowanego webhooka n8n alerty dla Rule ID
`60115`.

``` xml
<integration>
  <name>custom-n8n-failed-logon</name>
  <hook_url>https://n8n.tworzewski.pl/webhook/wazuh-ad-account-lockout</hook_url>
  <rule_id>60115</rule_id>
  <alert_format>json</alert_format>
</integration>
```

Istniejący skrypt integracyjny został ponownie wykorzystany, ponieważ
adres webhooka pobiera z argumentu przekazanego przez konfigurację Wazuh
zamiast posiadać adres wpisany na stałe.

------------------------------------------------------------------------

## 7. Workflow n8n

``` text
Wazuh Webhook
      ↓
Normalize 4740
      ↓
IF 4740 + 60115
      ↓
SMTP - Account Lockout
```

`Normalize 4740` przygotowuje najważniejsze pola zdarzenia, a
`IF 4740 + 60115` przepuszcza tylko oczekiwany typ alertu.

Test produkcyjnego webhooka zakończył się sukcesem.

![Workflow n8n dla blokady
konta](../screenshots/10-n8n-account-lockout-workflow.png)

------------------------------------------------------------------------

## 8. Powiadomienie SMTP

Finalne powiadomienie zawiera:

``` text
Użytkownik:           jkowalski
Komputer źródłowy:    LAB-W11-1
Kontroler / agent:    LAB-DC1
Event ID:             4740
Rule ID:              60115
Level:                9
Czas:                 timestamp zdarzenia
```

Wiadomość przypomina również administratorowi, że sama blokada konta nie
oznacza automatycznie ataku i wymaga weryfikacji.

![Finalne powiadomienie SMTP o blokadzie
konta](../screenshots/12-final-smtp-account-lockout-alert.png)

------------------------------------------------------------------------

## Wynik Etapu 1

Pełny przepływ został potwierdzony:

``` text
LAB-W11-1
   ↓  błędne logowania
Active Directory
   ↓  blokada konta
LAB-DC1 / Event 4740
   ↓
Wazuh / Rule 60115
   ↓
n8n
   ↓
SMTP
   ↓
Administrator
```

Detekcja i automatyczne powiadomienie są gotowe. Projekt może zostać
rozszerzony o korelację zdarzeń poprzedzających blokadę.

------------------------------------------------------------------------

# Etap 2 --- Korelacja Event ID 4625 → 4740

## Cel

Odnaleźć nieudane logowania poprzedzające blokadę konta i powiązać je ze
zdarzeniem `4740`.

### Do wykonania

-   [ ] odnaleźć Event ID `4625` dotyczące zablokowanego użytkownika,
-   [ ] określić okno czasowe przed `4740`,
-   [ ] powiązać zdarzenia po użytkowniku i komputerze źródłowym,
-   [ ] pobrać `IpAddress`, jeżeli występuje w zdarzeniu `4625`,
-   [ ] policzyć liczbę błędnych logowań poprzedzających blokadę,
-   [ ] przekazać wzbogacone dane do n8n.

Docelowo:

``` text
Użytkownik:                   jkowalski
Komputer źródłowy:            LAB-W11-1
Adres IP źródła:              10.1.201.x
Błędne logowania przed 4740:  X
```

> Adres IP nie może być pobierany z nagłówków HTTP webhooka jako adres
> komputera źródłowego. Żądanie do n8n wysyła Wazuh Manager, dlatego
> `X-Real-IP` / `X-Forwarded-For` wskazuje nadawcę webhooka.

------------------------------------------------------------------------

# Etap 3 --- Wzbogacenie alertu o dane Active Directory

Planowane informacje:

-   stan `Enabled`,
-   stan `LockedOut`,
-   Display Name,
-   Password Last Set,
-   informacje o ostatnim logowaniu,
-   wybrane członkostwa w grupach.

Ten etap ma dostarczyć administratorowi dodatkowy kontekst. Nie będzie
automatycznie modyfikował ani odblokowywał konta.

------------------------------------------------------------------------

# Etap 4 --- Rozbudowa powiadomienia

Po wykonaniu korelacji finalny alert może zawierać:

``` text
Użytkownik
Komputer źródłowy
Adres IP źródła
Liczba błędnych logowań
Stan konta AD
Kontroler domeny
Event ID
Wazuh Rule ID
Rule Level
Czas zdarzenia
```

------------------------------------------------------------------------

# Etap 5 --- Opcjonalna analiza Ollama

Po wdrożeniu korelacji n8n może przekazać przygotowany kontekst do
lokalnego modelu Ollama.

Model powinien przygotować krótką analizę:

1.  co się wydarzyło,
2.  dlaczego zdarzenie może być istotne,
3.  co administrator powinien sprawdzić.

AI nie powinno klasyfikować zdarzenia jako ataku bez wystarczających
dowodów.

------------------------------------------------------------------------

# Etap 6 --- Finalny test projektu

Docelowy przepływ:

``` text
Błędne uwierzytelnienia
        ↓
Event ID 4625
        ↓
Blokada konta
        ↓
Event ID 4740
        ↓
Wazuh
        ↓
Korelacja / wzbogacenie w n8n
        ↓
SMTP
        ↓
Powiadomienie administratora
```

Po zakończeniu zostaną dodane finalne zrzuty ekranu oraz krótkie
podsumowanie problemów i wniosków z konfiguracji.

------------------------------------------------------------------------

## Możliwe przyczyny blokady konta

Blokada konta nie oznacza automatycznie ataku. Możliwe przyczyny to
m.in.:

-   użytkownik kilkukrotnie podał błędne hasło,
-   stare hasło zapisane w Windows Credential Manager,
-   rozłączona sesja RDP,
-   mapowany dysk sieciowy,
-   zadanie harmonogramu korzystające ze starego hasła,
-   usługa Windows działająca na koncie domenowym,
-   urządzenie lub aplikacja korzystająca ze starego hasła,
-   powtarzające się próby uwierzytelnienia z innej stacji.

------------------------------------------------------------------------

## Struktura repozytorium

``` text
home-it-lab/
└── wazuh/
    ├── configs/
    ├── docs/
    │   ├── 01-architecture.md
    │   ├── 02-failed-logon-default-rule.md
    │   ├── 03-custom-rule-n8n-integration.md
    │   ├── 04-n8n-smtp-integration.md
    │   └── 05-ad-account-lockout-detection.md
    ├── screenshots/
    └── scripts/
```

------------------------------------------------------------------------

## Co projekt pokazuje w portfolio

Projekt pokazuje praktyczną pracę z:

-   Windows Security Events,
-   Active Directory i Group Policy,
-   Wazuh i analizą reguł SIEM,
-   Wazuh SCA / CIS Benchmark,
-   integracją webhook,
-   n8n i normalizacją JSON,
-   filtrowaniem zdarzeń,
-   SMTP,
-   podstawową analizą incydentu,
-   rozwijaną korelacją zdarzeń `4625 → 4740`.

Projekt został wykonany jako praktyczne środowisko **Home IT Lab**, a
nie gotowe rozwiązanie produkcyjne.
