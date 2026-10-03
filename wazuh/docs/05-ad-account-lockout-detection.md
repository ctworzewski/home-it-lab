# 05 --- Wykrywanie blokady konta Active Directory

## Cel projektu

Celem projektu jest wykrywanie **blokady konta użytkownika Active
Directory** za pomocą Wazuh oraz automatyczne powiadomienie
administratora przez **n8n + SMTP**.

Projekt rozpoczyna się od detekcji zdarzenia i wysłania powiadomienia, a
następnie będzie rozwijany o korelację zdarzeń oraz wzbogacanie alertu o
dodatkowe informacje.

> W tym projekcie Wazuh nie blokuje konta.\
> Konto jest blokowane przez politykę domenową Active Directory po
> przekroczeniu określonej liczby błędnych prób logowania.

------------------------------------------------------------------------

## Scenariusz

1.  Użytkownik domenowy kilkukrotnie podaje błędne hasło.
2.  Active Directory osiąga skonfigurowany próg blokady konta.
3.  Konto użytkownika zostaje zablokowane przez AD.
4.  Kontroler domeny generuje zdarzenie Windows Security **Event ID
    4740**.
5.  Agent Wazuh przekazuje zdarzenie z kontrolera domeny do Wazuh
    Managera.
6.  Wbudowana reguła Wazuh **60115** wykrywa blokadę konta.
7.  Wazuh przekazuje alert `60115` do webhooka n8n.
8.  n8n normalizuje dane i sprawdza `Event ID 4740 + Rule ID 60115`.
9.  Administrator otrzymuje wiadomość e-mail SMTP z najważniejszymi
    informacjami.

------------------------------------------------------------------------

## Środowisko LAB

``` text
Domena:                cyber.local
Domena NetBIOS:        CYBER
Kontroler domeny:      LAB-DC1
Stacja robocza:        LAB-W11-1
Użytkownik testowy:    jkowalski
Windows Event ID:      4740
Wazuh Rule ID:         60115
Wazuh Rule Level:      9
```

------------------------------------------------------------------------

## Konfiguracja Account Lockout Policy

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

## Test blokady konta

Na stacji `LAB-W11-1` wykonano dwie błędne próby logowania na konto
domenowe `CYBER\jkowalski`.

Po osiągnięciu skonfigurowanego progu Active Directory zablokowało
konto.

![Zablokowane konto na
LAB-W11-1](../screenshots/09-account-lockout-lab-w11-1-final.png)

Na kontrolerze domeny `LAB-DC1` pojawiło się zdarzenie:

``` text
Event ID:             4740
Account Name:         jkowalski
Caller Computer Name: LAB-W11-1
Computer:             LAB-DC1.cyber.local
```

![Event ID 4740 na kontrolerze
domeny](../screenshots/07-event-4740-domain-controller-final.png)

------------------------------------------------------------------------

## Detekcja w Wazuh

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

Szczegóły dokumentu w Wazuh potwierdzają m.in. Event ID `4740`, konto
`jkowalski` oraz `Caller Computer Name: LAB-W11-1`.

![Szczegóły Event ID 4740 w
Wazuh](../screenshots/11-wazuh-event-4740-details-final.png)

------------------------------------------------------------------------

## Weryfikacja zgodności z CIS Benchmark

Wazuh Security Configuration Assessment (SCA) wykorzystano również do
sprawdzenia ustawienia `Account lockout threshold`.

Przy wartości `0` kontrola została oznaczona jako **failed**. Po
ustawieniu niezerowego progu zgodnego z wymaganiem kontroli wynik
zmienił się na **passed**.

![CIS Account Lockout Threshold -
porównanie](../screenshots/06-cis-account-lockout-threshold-comparison.png)

Źródło: [CIS Password Policy
Guide](https://www.cisecurity.org/insights/white-papers/cis-password-policy-guide)

------------------------------------------------------------------------

## Integracja Wazuh → n8n

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

Istniejący skrypt integracyjny może zostać ponownie wykorzystany,
ponieważ adres webhooka pobiera z argumentu przekazanego przez
konfigurację Wazuh, zamiast posiadać adres wpisany na stałe.

------------------------------------------------------------------------

## Workflow n8n

Zaimplementowany przepływ:

``` text
Wazuh Webhook
      ↓
Normalize 4740
      ↓
IF 4740 + 60115
      ↓
SMTP - Account Lockout
```

Node `Normalize 4740` przygotowuje najważniejsze pola zdarzenia, a
`IF 4740 + 60115` przepuszcza tylko oczekiwany typ alertu.

Test produkcyjnego webhooka zakończył się sukcesem i cały workflow
został wykonany poprawnie.

![Workflow n8n dla blokady
konta](../screenshots/10-n8n-account-lockout-workflow.png)

------------------------------------------------------------------------

## Powiadomienie SMTP

Powiadomienie dla administratora zawiera:

``` text
Użytkownik:           jkowalski
Komputer źródłowy:    LAB-W11-1
Kontroler / agent:    LAB-DC1
Event ID:             4740
Rule ID:              60115
Level:                9
Czas:                 timestamp zdarzenia
```

Wiadomość informuje również, że sama blokada konta nie oznacza
automatycznie ataku i wymaga weryfikacji przez administratora.

> Finalny zrzut poprawionej wiadomości SMTP zostanie dodany jako:
> `12-final-smtp-account-lockout-alert.png`

------------------------------------------------------------------------

## Aktualny przepływ end-to-end

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
SMTP
        ↓
E-mail administratora
```

------------------------------------------------------------------------

# Dalsze etapy projektu

Podstawowa detekcja i automatyczne powiadomienie są już gotowe. Kolejne
etapy rozbudują **ten sam projekt** o korelację i wzbogacanie zdarzeń.

## Etap 2 --- Korelacja Event ID 4625 → 4740

Cel: odnaleźć nieudane logowania poprzedzające blokadę konta i powiązać
je ze zdarzeniem `4740`.

Do wykonania:

-   [ ] odnaleźć Event ID `4625` dotyczące zablokowanego użytkownika,
-   [ ] określić okno czasowe przed wystąpieniem `4740`,
-   [ ] powiązać zdarzenia po użytkowniku i komputerze źródłowym,
-   [ ] pobrać `IpAddress`, jeżeli występuje w zdarzeniu `4625`,
-   [ ] policzyć liczbę błędnych logowań poprzedzających blokadę,
-   [ ] przekazać wzbogacone dane do workflow n8n.

Docelowo alert może zawierać:

``` text
Użytkownik:                  jkowalski
Komputer źródłowy:           LAB-W11-1
Adres IP źródła:             10.1.201.x
Błędne logowania przed 4740: X
```

> Adres IP nie może być pobierany z nagłówków HTTP webhooka jako adres
> komputera źródłowego. Żądanie do n8n wysyła Wazuh Manager, dlatego
> `X-Real-IP` / `X-Forwarded-For` wskazuje nadawcę webhooka, a
> niekoniecznie urządzenie odpowiedzialne za błędne uwierzytelnienie.

------------------------------------------------------------------------

## Etap 3 --- Wzbogacenie alertu o dane Active Directory

Cel: automatycznie pobrać dodatkowy kontekst dotyczący zablokowanego
konta.

Planowane informacje:

-   [ ] stan `Enabled`,
-   [ ] stan `LockedOut`,
-   [ ] Display Name,
-   [ ] Password Last Set,
-   [ ] informacje o ostatnim logowaniu,
-   [ ] wybrane członkostwa w grupach.

Ten etap ma wzbogacać alert i pomagać administratorowi w analizie. Nie
będzie automatycznie odblokowywał ani modyfikował konta.

------------------------------------------------------------------------

## Etap 4 --- Rozbudowa wiadomości dla administratora

Po wykonaniu korelacji wiadomość SMTP zostanie rozszerzona o:

``` text
Użytkownik
Komputer źródłowy
Adres IP źródła (jeżeli dostępny)
Liczba błędnych logowań
Kontroler domeny
Event ID
Wazuh Rule ID
Rule Level
Czas zdarzenia
```

Powiadomienie powinno oddzielać dane wynikające bezpośrednio ze zdarzeń
od zaleceń dotyczących dalszej weryfikacji.

------------------------------------------------------------------------

## Etap 5 --- Opcjonalna analiza lokalnym AI / Ollama

Po poprawnym wdrożeniu deterministycznej korelacji zdarzeń n8n może
przekazać przygotowany kontekst do lokalnego modelu Ollama.

Model powinien przygotować maksymalnie kilka krótkich zdań:

1.  co się wydarzyło,
2.  dlaczego zdarzenie może być istotne,
3.  co administrator powinien sprawdzić.

AI nie powinno klasyfikować zdarzenia jako ataku bez wystarczających
dowodów.

------------------------------------------------------------------------

## Etap 6 --- Finalny test i dokumentacja

Na zakończenie zostanie wykonany pełny test:

``` text
Błędne uwierzytelnienia
        ↓
Blokada konta
        ↓
Event ID 4740
        ↓
Wazuh 60115
        ↓
Korelacja / wzbogacenie w n8n
        ↓
SMTP
        ↓
Powiadomienie administratora
```

Do repozytorium zostaną dodane finalne zrzuty ekranu oraz krótkie
podsumowanie problemów napotkanych podczas konfiguracji.

------------------------------------------------------------------------

## Możliwe przyczyny blokady konta

Blokada konta nie oznacza automatycznie ataku.

Możliwe przyczyny:

-   użytkownik kilkukrotnie podał błędne hasło,
-   stare hasło zapisane w Windows Credential Manager,
-   rozłączona sesja RDP,
-   mapowany dysk sieciowy,
-   zadanie harmonogramu korzystające ze starego hasła,
-   usługa Windows działająca na koncie domenowym,
-   urządzenie lub aplikacja korzystająca ze starego hasła,
-   powtarzające się próby uwierzytelnienia z innej stacji.

------------------------------------------------------------------------

## Status projektu

-   [x] Sprawdzić politykę blokady konta w Active Directory
-   [x] Skonfigurować testowy próg 2 błędnych logowań
-   [x] Zweryfikować konfigurację GPO za pomocą PowerShell
-   [x] Wygenerować testową blokadę konta użytkownika
-   [x] Potwierdzić Event ID 4740 na kontrolerze domeny
-   [x] Sprawdzić, czy Wazuh odbiera zdarzenie 4740
-   [x] Zidentyfikować domyślną regułę Wazuh 60115
-   [x] Potwierdzić nazwę zablokowanego użytkownika i komputer źródłowy
-   [x] Zweryfikować CIS/SCA --- `failed` oraz `passed`
-   [x] Wysłać alert z Wazuh do n8n
-   [x] Znormalizować i odfiltrować 4740 / 60115 w n8n
-   [x] Przygotować czytelny e-mail dla administratora
-   [x] Przetestować cały przepływ Wazuh → n8n → SMTP
-   [ ] Skorelować wcześniejsze zdarzenia 4625 z blokadą 4740
-   [ ] Dodać adres IP źródła, jeżeli będzie dostępny
-   [ ] Wzbogacić alert o dane Active Directory
-   [ ] Opcjonalnie dodać analizę Ollama
-   [ ] Dodać finalne zrzuty korelacji i wzbogacenia
-   [ ] Uzupełnić końcowe podsumowanie projektu

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
-   Active Directory,
-   Group Policy,
-   Wazuh,
-   analizą wbudowanych reguł SIEM,
-   Wazuh SCA / CIS Benchmark,
-   webhookami,
-   n8n,
-   normalizacją danych JSON,
-   filtrowaniem alertów,
-   SMTP,
-   podstawową analizą incydentu,
-   korelacją zdarzeń bezpieczeństwa rozwijaną w kolejnym etapie.

Projekt został wykonany jako praktyczne środowisko **Home IT Lab**, a
nie gotowe rozwiązanie produkcyjne.
