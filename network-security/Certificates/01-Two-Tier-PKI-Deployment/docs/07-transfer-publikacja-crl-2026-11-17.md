# Etap 3 — transfer certyfikatów, AIA i CRL (16–17.11.2026)

## Potwierdzone wyniki

1. **Transfer**: publiczne `root-ca.cert.pem` i `issuing-ca.cert.pem` z offline Root CA przez odłączany VHDX ext4 na online Issuing CA. Z FAT32 występował problem utraty widoczności plików po przełączeniu; dokładnej przyczyny nie ustalono.
2. **Walidacja** na Issuing CA: `sudo openssl verify -CAfile /opt/pki/intermediate/certs/root-ca.cert.pem /opt/pki/intermediate/certs/issuing-ca.cert.pem` → `OK`.
3. **Nginx**: instalacja, `nginx -t` OK, usługa aktywna, katalogi `/var/www/pki/{ca,crl}`, lokalny rekord DNS `10.1.201.231`, UFW HTTP 80 z `10.1.201.0/24`.
4. **AIA**: certyfikaty Root oraz Issuing dostępne pod `/ca/` (HTTP 200); `curl | openssl x509 -noout -subject -issuer` wskazał właściwe tożsamości.
5. **Issuing CRL**: wygenerowana kluczem CA (ręczne wpisanie hasła), podpis `verify OK`, konwersja do DER, opublikowana jako `/crl/issuing-ca.crl`; ostatni `nextUpdate=Nov 23 23:34:58 2026 GMT`.
6. **Root CRL**: wygenerowana i zweryfikowana na offline Root CA, przekazana przez VHDX, opublikowana jako `/crl/root-ca.crl`; `nextUpdate=May 15 23:20:11 2027 GMT`.

## URL publikacji

| Typ | URL |
|---|---|
| Root CA (PEM) | `http://pki.tworzewski.pl/ca/root-ca.cert.pem` |
| Issuing CA (PEM) | `http://pki.tworzewski.pl/ca/issuing-ca.cert.pem` |
| Root CRL (DER) | `http://pki.tworzewski.pl/crl/root-ca.crl` |
| Issuing CRL (DER) | `http://pki.tworzewski.pl/crl/issuing-ca.crl` |

## Przykładowe polecenia weryfikacyjne

```bash
curl -fsS http://pki.tworzewski.pl/ca/issuing-ca.cert.pem | openssl x509 -noout -subject -issuer
curl -fsS http://pki.tworzewski.pl/crl/root-ca.crl | openssl crl -inform DER -noout -issuer -nextupdate
curl -fsS http://pki.tworzewski.pl/crl/issuing-ca.crl | openssl crl -inform DER -noout -issuer -nextupdate
sudo openssl crl -in /opt/pki/intermediate/crl/issuing-ca.crl.pem -verify -CAfile /opt/pki/intermediate/certs/issuing-ca.cert.pem -noout
```

## Ręczna procedura odnawiania Issuing CRL

```bash
sudo openssl ca -config /opt/pki/intermediate/openssl.cnf -gencrl -out /opt/pki/intermediate/crl/issuing-ca.crl.pem
sudo openssl crl -in /opt/pki/intermediate/crl/issuing-ca.crl.pem -verify -CAfile /opt/pki/intermediate/certs/issuing-ca.cert.pem -noout
sudo openssl crl -in /opt/pki/intermediate/crl/issuing-ca.crl.pem -outform DER -out /var/www/pki/crl/issuing-ca.crl.tmp
sudo chmod 644 /var/www/pki/crl/issuing-ca.crl.tmp
sudo mv /var/www/pki/crl/issuing-ca.crl.tmp /var/www/pki/crl/issuing-ca.crl
curl -fsS http://pki.tworzewski.pl/crl/issuing-ca.crl | openssl crl -inform DER -noout -issuer -lastupdate -nextupdate
```

Wymagane jest hasło klucza Issuing CA; procedura nie jest bezobsługowa. Nie wdrożono `systemd timer`. Przed podmianą opublikowanej CRL należy sprawdzić podpis i daty. Klucz prywatny **nie** jest publikowany.

## Ograniczenia i bezpieczeństwo

- Root CA offline; wymiana danych przez odłączane nośniki, bez transferu prywatnego klucza.
- Należy zaplanować czas odnowienia obu CRL; ważność Issuing CRL: 7 dni, Root CRL: 180 dni według konfiguracji.
- Testy na serwerze publikacji nie potwierdzają dostępności z każdej sieci użytkowników.
- Do ukończenia: SAN/TLS dla usługi, sprawdzenie łańcucha i unieważnienia na kliencie.
