# Plan dalszego wdrożenia — stan na 16.11.2026

Root CA i Issuing CA zostały utworzone; Issuing CA podpisał offline Root CA. Łańcuch przeszedł lokalny test `openssl verify`.

## Następne działania

1. Przygotować kontrolowany transfer **wyłącznie publicznych** certyfikatów `root-ca.cert.pem` i `issuing-ca.cert.pem` na Issuing CA (VHDX lub inny nośnik offline).
2. Ustawić publikację plików na `http://pki.tworzewski.pl/ca/` oraz `/crl/`; sprawdzić DNS i serwer HTTP.
3. Wygenerować CRL Root CA na offline VM, przygotować CRL Issuing CA i publikować je w DER z datami obowiązywania.
4. Zweryfikować AIA/CRL z testowego klienta, w tym zachowanie po unieważnieniu certyfikatu.
5. Wystawić testowy certyfikat serwera z SAN, uruchomić HTTPS i przeprowadzić test zaufania klienta.
6. Uzupełnić dokumentację o wyniki i zrzuty oraz rozważyć dodatkowe zabezpieczenia/backup Root CA.

**Niewdrożone:** checkpoint policy, dodatkowe zabezpieczenia VHDX/hosta i zaszyfrowany backup Root CA (świadomie odłożone na później w tym labie).
