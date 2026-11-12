# 04 — Plan wdrożenia właściwego PKI (jeszcze nie wykonano)

1. Zdefiniować oddzielną, laboratoryjną hierarchię X.509; nie kopiować prywatnych kluczy produkcyjnych do labu.
2. Zweryfikować i utrwalić backupy/konfigurację serwerów, a następnie **fizycznie odłączyć kartę wirtualną Root CA od sieci w Hyper-V przed wygenerowaniem klucza Root CA**.
3. Przygotować osobne konfiguracje OpenSSL i bazy CA (indeksy, numery seryjne i CRL), zabezpieczyć katalog kluczy.
4. Wygenerować klucz Root CA offline i samopodpisany certyfikat z prawidłowymi rozszerzeniami CA.
5. Wygenerować klucz i CSR Issuing CA na maszynie online, przenieść CSR w kontrolowany sposób do Root CA.
6. Podpisać Issuing CA offline, zweryfikować pathLen, keyUsage, basicConstraints i łańcuch zaufania.
7. Opublikować certyfikaty CA i listy CRL pod stabilnym adresem HTTP; zaplanować ręczne odnawianie CRL Root CA offline.
8. Wystawić testowy certyfikat TLS z SAN, wdrożyć do usługi labowej i zweryfikować na Windows/Linux.
9. Wykonać zaszyfrowane kopie zapasowe i test odtworzenia, bez umieszczania prywatnych kluczy w repozytorium.

**Kolejne commity:** `feat(pki): configure offline root ca`, `feat(pki): configure issuing ca`, `docs(pki): verify certificate chain` — dopiero po wykonaniu odpowiednich czynności.
