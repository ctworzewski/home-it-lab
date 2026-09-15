# 🔐 Apache HTTPS z własnym Root CA

> Runbook konfiguracji HTTPS dla wewnętrznej aplikacji WWW działającej
> na Apache z wykorzystaniem własnego urzędu certyfikacji (Root CA).

## 📋 Informacje

  Element            Wartość
  ------------------ --------------------
  Serwer WWW         Apache2
  Certyfikaty        OpenSSL
  DNS                lokalny DNS
  CA                 własny Root CA
  Protokół           HTTPS / TLS
  Przykładowy host   `zabbix.lab.local`

## 🏗️ Schemat

``` text
Klient
  |
  | HTTPS
  v
Apache
  |
  v
Aplikacja WWW

Certyfikat serwera
        |
        v
 podpisany przez
        |
        v
     Root CA
        |
        v
zaufany na urządzeniu klienta
```

Certyfikat serwera jest podpisany przez prywatne Root CA, które musi
zostać dodane do zaufanych urzędów certyfikacji na urządzeniach
klienckich.

------------------------------------------------------------------------

## 1. Wymagania

Przed rozpoczęciem konfiguracji wymagane są:

-   Apache2,
-   OpenSSL,
-   lokalny DNS,
-   własny Root CA,
-   dostęp administracyjny do serwera.

### Sprawdzenie Apache

``` bash
systemctl status apache2
```

### Sprawdzenie OpenSSL

``` bash
openssl version
```

------------------------------------------------------------------------

## 2. Lokalny rekord DNS

Przykładowy rekord:

``` text
zabbix.lab.local → 10.1.201.200
```

### Weryfikacja

``` bash
nslookup zabbix.lab.local
```

lub:

``` bash
dig zabbix.lab.local
```

Klient powinien otrzymać adres IP właściwego serwera.

------------------------------------------------------------------------

## 3. Utworzenie klucza prywatnego serwera

Wygeneruj klucz prywatny:

``` bash
openssl genrsa -out zabbix.lab.local.key 2048
```

> Klucz prywatny nie powinien opuszczać serwera.

Ustaw ograniczone uprawnienia:

``` bash
chmod 600 zabbix.lab.local.key
```

------------------------------------------------------------------------

## 4. Utworzenie CSR

Utwórz żądanie podpisania certyfikatu:

``` bash
openssl req -new \
  -key zabbix.lab.local.key \
  -out zabbix.lab.local.csr
```

CN powinien odpowiadać nazwie DNS używanej przez użytkowników.

------------------------------------------------------------------------

## 5. Subject Alternative Name

Współczesne przeglądarki weryfikują przede wszystkim **Subject
Alternative Name (SAN)**.

Przykładowy plik `san.ext`:

``` ini
subjectAltName=DNS:zabbix.lab.local
```

Jeżeli aplikacja posiada kilka nazw:

``` ini
subjectAltName=DNS:zabbix.lab.local,DNS:www.zabbix.lab.local
```

------------------------------------------------------------------------

## 6. Podpisanie certyfikatu przez Root CA

Podpisz CSR własnym Root CA:

``` bash
openssl x509 -req \
  -in zabbix.lab.local.csr \
  -CA rootCA.crt \
  -CAkey rootCA.key \
  -CAcreateserial \
  -out zabbix.lab.local.crt \
  -days 825 \
  -sha256 \
  -extfile san.ext
```

### Sprawdzenie certyfikatu

``` bash
openssl x509 -in zabbix.lab.local.crt -text -noout
```

Zweryfikuj:

-   `Subject`,
-   `Issuer`,
-   okres ważności,
-   `Subject Alternative Name`.

------------------------------------------------------------------------

## 7. Włączenie SSL w Apache

Włącz moduł SSL:

``` bash
a2enmod ssl
```

### VirtualHost HTTPS

Przykładowa konfiguracja:

``` apache
<VirtualHost *:443>
    ServerName zabbix.lab.local

    SSLEngine on

    SSLCertificateFile /etc/ssl/certs/zabbix.lab.local.crt
    SSLCertificateKeyFile /etc/ssl/private/zabbix.lab.local.key

    DocumentRoot /var/www/html
</VirtualHost>
```

Aktywuj konfigurację:

``` bash
a2ensite zabbix-ssl.conf
```

### Test konfiguracji

``` bash
apachectl configtest
```

Oczekiwany rezultat:

``` text
Syntax OK
```

Uruchom ponownie Apache:

``` bash
systemctl restart apache2
```

------------------------------------------------------------------------

## 8. Przekierowanie HTTP → HTTPS

Przykładowy VirtualHost dla portu 80:

``` apache
<VirtualHost *:80>
    ServerName zabbix.lab.local

    Redirect permanent / https://zabbix.lab.local/
</VirtualHost>
```

Sprawdź konfigurację:

``` bash
apachectl configtest
```

Następnie przeładuj Apache:

``` bash
systemctl reload apache2
```

------------------------------------------------------------------------

## 9. Instalacja Root CA na Windows

Certyfikat Root CA należy zainstalować w magazynie:

``` text
Trusted Root Certification Authorities
```

### Wdrożenie przez GPO

W środowisku domenowym Root CA można wdrożyć centralnie:

``` text
Computer Configuration
└── Policies
    └── Windows Settings
        └── Security Settings
            └── Public Key Policies
                └── Trusted Root Certification Authorities
```

------------------------------------------------------------------------

## 10. Weryfikacja

Otwórz w przeglądarce:

``` text
https://zabbix.lab.local
```

Sprawdź, czy:

-   HTTPS działa,
-   przeglądarka nie wyświetla ostrzeżenia o certyfikacie,
-   nazwa DNS odpowiada wartości SAN,
-   certyfikat został wystawiony przez właściwe Root CA.

### Test z CLI

``` bash
curl -v https://zabbix.lab.local
```

------------------------------------------------------------------------

# 🛠️ Troubleshooting

## `ERR_CERT_AUTHORITY_INVALID`

**Najczęstsza przyczyna:** Root CA nie jest zainstalowane jako zaufane
na urządzeniu klienckim.

Sprawdź magazyn:

``` text
Trusted Root Certification Authorities
```

## `ERR_CERT_COMMON_NAME_INVALID`

Sprawdź SAN certyfikatu:

``` bash
openssl x509 -in zabbix.lab.local.crt -text -noout
```

Nazwa używana w przeglądarce musi znajdować się w SAN.

## Apache nie uruchamia się po zmianie certyfikatu

Sprawdź konfigurację:

``` bash
apachectl configtest
```

Sprawdź logi usługi:

``` bash
journalctl -u apache2 -n 50
```

Zweryfikuj również ścieżki do certyfikatu i klucza.

------------------------------------------------------------------------

## ✅ Rezultat

Po wykonaniu runbooka:

``` text
https://zabbix.lab.local
```

powinien być dostępny przez HTTPS, a urządzenia posiadające zaufany Root
CA nie powinny wyświetlać ostrzeżenia dotyczącego certyfikatu.
