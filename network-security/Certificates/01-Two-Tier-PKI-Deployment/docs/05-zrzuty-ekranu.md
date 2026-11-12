# 05 — Galeria zrzutów z rzeczywistych prac

Poniższe obrazy pochodzą ze zrzutów udostępnionych podczas konfiguracji 10–12.11.2026. Każdy pokazuje konkretny, wykonany krok.

## 1. Dwie maszyny wirtualne podczas instalacji Debian 13

![Dwie maszyny wirtualne podczas instalacji Debian 13](../screenshots/01-instalacja-dwoch-vm.png)

## 2. Sprawdzenie adresacji i DNS na obu serwerach

![Sprawdzenie adresacji i DNS na obu serwerach](../screenshots/02-statyczne-ip-dns.png)

## 3. UFW aktywny i parametry SSH na obu maszynach

![UFW aktywny i parametry SSH na obu maszynach](../screenshots/03-ufw-ssh.png)

## 4. Efektywna konfiguracja SSH po wyłączeniu haseł

![Efektywna konfiguracja SSH po wyłączeniu haseł](../screenshots/04-ssh-klucze-konfiguracja.png)

## 5. Odmowa logowania bez klucza w PuTTY

![Odmowa logowania bez klucza w PuTTY](../screenshots/05-test-negatywny-ssh.png)

## 6. Umask 0077 na obu serwerach

![Umask 0077 na obu serwerach](../screenshots/06-umask.png)

## 7. Dwa serwery DNS i aktualizacja APT

![Dwa serwery DNS i aktualizacja APT](../screenshots/07-dns-aktualizacja.png)

## 8. Zmiana uprawnień katalogu sudoers.d

![Zmiana uprawnień katalogu sudoers.d](../screenshots/08-uprawnienia-sudoers.png)

## 9. Status ClamAV i aktualizacji sygnatur na Issuing CA

![Status ClamAV i aktualizacji sygnatur na Issuing CA](../screenshots/09-clamav-freshclam.png)

## 10. Synchronizacja NTP obu serwerów

![Synchronizacja NTP obu serwerów](../screenshots/10-synchronizacja-ntp.png)

## Etap 2 — przejście Root CA offline i przygotowanie OpenSSL

- **Hyper-V przed izolacją:** ![Przed odłączeniem](../screenshots/11-root-ca-offline-hyperv-przed.png)
- **Hyper-V po izolacji:** ![Po odłączeniu](../screenshots/12-root-ca-offline-hyperv-po.png)
- **Konsola i test offline:** ![Kontrola izolacji](../screenshots/13-root-ca-test-izolacji.png)
- **OpenSSL 3.5.7:** ![Wersja OpenSSL](../screenshots/14-root-ca-openssl-wersja.png)
- **Katalogi bazy Root CA:** ![Katalogi Root CA](../screenshots/15-root-ca-struktura-katalogow.png)
