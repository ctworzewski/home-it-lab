# 04 — Następne etapy PKI

## Stan na 12 listopada 2026

**Wykonano:** odłączenie LAB-ROOT-CA od przełącznika wirtualnego Hyper-V, wyłączenie SSH, potwierdzenie braku łączności, instalację/zweryfikowanie OpenSSL 3.5.7 i przygotowanie katalogów oraz pustej bazy Root CA.

**Nie wykonano:** konfiguracji `openssl.cnf`, generowania klucza Root CA, certyfikatu Root CA, budowy Issuing CA, CSR, CRL/AIA i certyfikatów TLS.

## Plan

1. Opracować konfigurację `openssl.cnf` dla Root CA i ustalić parametry hierarchii.
2. Na izolowanej maszynie wygenerować szyfrowany klucz prywatny i certyfikat Root CA.
3. Przygotować Issuing CA online, CSR i politykę wystawiania certyfikatów.
4. Przenieść CSR przez kontrolowany nośnik do offline Root CA, podpisać i bezpiecznie oddać certyfikat.
5. Opublikować certyfikaty CA i listy CRL, uwzględniając odnawianie offline Root CRL.
6. Wystawić testowy certyfikat serwera i potwierdzić zaufanie na Windows i Linux.

## Zalecenia niewdrożone

Nie wyłączono checkpointów Hyper-V, nie przeprowadzono dodatkowego ograniczenia uprawnień VHDX/hosta ani nie przygotowano niezależnego zaszyfrowanego backupu Root CA. Powody i ryzyka opisano w głównym [README](../README.md#dodatkowe-zabezpieczenia-root-ca--zalecane-ale-niewdrożone-w-tym-labie).
