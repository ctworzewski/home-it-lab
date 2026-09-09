\# Apache HTTPS z własnym Root CA



\## Cel



Konfiguracja HTTPS dla wewnętrznej aplikacji WWW działającej na Apache z wykorzystaniem własnego urzędu certyfikacji (Root CA).



Przykładowy scenariusz:



Client → HTTPS → Apache → aplikacja



Certyfikat serwera jest podpisany przez prywatne Root CA, które musi być zaufane na urządzeniach klienckich.



\---



\## 1. Wymagania



\- Apache2

\- OpenSSL

\- lokalny DNS

\- własny Root CA

\- dostęp administracyjny do serwera



Sprawdzenie Apache:



```bash

systemctl status apache2

```



Sprawdzenie OpenSSL:



```bash

openssl version

```



\---



\## 2. Lokalny rekord DNS



Przykład:



```text

zabbix.lab.local → 10.1.201.200

```



Sprawdzenie:



```bash

nslookup zabbix.lab.local

```



lub:



```bash

dig zabbix.lab.local

```



Klient powinien otrzymać adres IP właściwego serwera.



\---



\## 3. Utworzenie klucza prywatnego serwera



```bash

openssl genrsa -out zabbix.lab.local.key 2048

```



Klucz prywatny nie powinien opuszczać serwera.



Przykładowe uprawnienia:



```bash

chmod 600 zabbix.lab.local.key

```



\---



\## 4. Utworzenie CSR



```bash

openssl req -new \\

\-key zabbix.lab.local.key \\

\-out zabbix.lab.local.csr

```



CN powinien odpowiadać nazwie DNS używanej przez użytkowników.



\---



\## 5. Subject Alternative Name



Współczesne przeglądarki weryfikują przede wszystkim SAN.



Przykładowy plik:



```ini

subjectAltName=DNS:zabbix.lab.local

```



Jeżeli aplikacja posiada kilka nazw:



```ini

subjectAltName=DNS:zabbix.lab.local,DNS:www.zabbix.lab.local

```



\---



\## 6. Podpisanie certyfikatu przez Root CA



Przykład:



```bash

openssl x509 -req \\

\-in zabbix.lab.local.csr \\

\-CA rootCA.crt \\

\-CAkey rootCA.key \\

\-CAcreateserial \\

\-out zabbix.lab.local.crt \\

\-days 825 \\

\-sha256 \\

\-extfile san.ext

```



Sprawdzenie certyfikatu:



```bash

openssl x509 -in zabbix.lab.local.crt -text -noout

```



Zweryfikuj:



\- Subject

\- Issuer

\- okres ważności

\- Subject Alternative Name



\---



\## 7. Włączenie SSL w Apache



```bash

a2enmod ssl

```



Przykładowy VirtualHost:



```apache

<VirtualHost \*:443>



&#x20;   ServerName zabbix.lab.local



&#x20;   SSLEngine on



&#x20;   SSLCertificateFile /etc/ssl/certs/zabbix.lab.local.crt

&#x20;   SSLCertificateKeyFile /etc/ssl/private/zabbix.lab.local.key



&#x20;   DocumentRoot /var/www/html



</VirtualHost>

```



Aktywacja konfiguracji:



```bash

a2ensite zabbix-ssl.conf

```



Test:



```bash

apachectl configtest

```



Oczekiwany rezultat:



```text

Syntax OK

```



Restart:



```bash

systemctl restart apache2

```



\---



\## 8. Przekierowanie HTTP → HTTPS



Przykład VirtualHost dla portu 80:



```apache

<VirtualHost \*:80>



&#x20;   ServerName zabbix.lab.local



&#x20;   Redirect permanent / https://zabbix.lab.local/



</VirtualHost>

```



Sprawdź konfigurację:



```bash

apachectl configtest

```



Następnie:



```bash

systemctl reload apache2

```



\---



\## 9. Instalacja Root CA na Windows



Certyfikat Root CA należy zainstalować w:



```text

Trusted Root Certification Authorities

```



Dla środowiska domenowego można wdrożyć Root CA przez GPO:



```text

Computer Configuration

→ Policies

→ Windows Settings

→ Security Settings

→ Public Key Policies

→ Trusted Root Certification Authorities

```



\---



\## 10. Weryfikacja



W przeglądarce:



```text

https://zabbix.lab.local

```



Sprawdź:



\- HTTPS działa

\- brak ostrzeżenia o certyfikacie

\- nazwa DNS odpowiada SAN

\- certyfikat został wystawiony przez właściwe Root CA



Test z CLI:



```bash

curl -v https://zabbix.lab.local

```



\---



\## Troubleshooting



\### ERR\_CERT\_AUTHORITY\_INVALID



Najczęstsza przyczyna:



Root CA nie jest zainstalowane jako zaufane na urządzeniu klienckim.



Sprawdź magazyn:



```text

Trusted Root Certification Authorities

```



\### ERR\_CERT\_COMMON\_NAME\_INVALID



Sprawdź SAN certyfikatu:



```bash

openssl x509 -in zabbix.lab.local.crt -text -noout

```



Nazwa używana w przeglądarce musi znajdować się w SAN.



\### Apache nie uruchamia się po zmianie certyfikatu



```bash

apachectl configtest

journalctl -u apache2 -n 50

```



Sprawdź również ścieżki do certyfikatu i klucza.

