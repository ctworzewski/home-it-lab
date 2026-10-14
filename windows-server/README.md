# Windows Server — Home IT Lab

> Praktyczne projekty z administracji środowiskami Microsoft: od konfiguracji usług, przez diagnostykę, po testy awarii i dokumentowanie wyników.

Ten katalog jest częścią repozytorium [home-it-lab](../README.md). Zbieram tutaj scenariusze realizowane w prywatnym laboratorium — **Windows Server, Active Directory, Hyper-V, usługi plikowe, storage i wysoka dostępność (HA)**. Każdy ukończony projekt ma własny README, instrukcje, komendy PowerShell, zrzuty ekranu i weryfikację działania.

## Projekty i postęp

| Status | Projekt | Zakres |
| :---: | --- | --- |
| ✅ | **[01 — Failover File Server + TrueNAS iSCSI](./01-failover-file-server/README.md)** | Dwuwęzłowy klaster Windows Server 2025, wspólny storage iSCSI, quorum, udział SMB, kontrolowany i awaryjny failover |
| ⬜ | **02 — Active Directory: administracja i odporność** *(planowany)* | AD DS, DNS, replikacja, GPO, diagnostyka kontrolerów domeny |
| ⬜ | **03 — Hyper-V: wirtualizacja i odzyskiwanie** *(planowany)* | Maszyny wirtualne, sieci wirtualne, backup i scenariusze odtworzenia |
| ⬜ | **04 — File Server: audyt dostępu do plików** *(planowany)* | Uprawnienia SMB/NTFS, zdarzenia dostępu i usuwania plików, integracja z monitoringiem |

**Legenda:** ✅ opisany i ukończony w labie · ⬜ planowany (jeszcze bez opublikowanego projektu).

## Zrealizowany projekt: Failover File Server

Pierwszy projekt prezentuje kompletną budowę klastra serwera plików, w tym diagnozowanie problemów napotkanych podczas konfiguracji.

**Środowisko testowe**

| Komponent | Konfiguracja |
| --- | --- |
| Domena | `cyber.local` |
| Kontroler domeny | `LAB-DC1` — `10.1.201.200` |
| Węzły | `FS1` — `10.1.201.221`, `FS2` — `10.1.201.222` |
| Klaster | `LAB-CLUSTER` — `10.1.201.223` |
| Rola File Server | `LAB-FILES` — `10.1.201.224` |
| Storage | TrueNAS SCALE — `10.1.201.230` |
| Dane | LUN 0 — 30 GiB, NTFS |
| Disk Witness | LUN 1 — 1 GiB |
| Udział | `\\LAB-FILES\DANE` |

**Sprawdzone w praktyce:** walidacja klastra i storage, przełączenie roli FS1 → FS2, nagłe wyłączenie FS2, automatyczne przejęcie usługi przez FS1, dostęp do plików po awarii oraz ponowne dołączenie FS2.

➡️ **[Przejdź do projektu, dokumentacji i screenów](./01-failover-file-server/README.md)**

## Jak czytać to repozytorium?

1. Wejdź do wybranego projektu i zacznij od jego `README.md`.
2. W katalogu `docs/` znajdziesz bardziej szczegółowe instrukcje i wyjaśnienia.
3. W `screenshots/` są zrzuty z faktycznej konfiguracji oraz testów.
4. W `scripts/` znajdują się polecenia i skrypty pomocnicze, jeśli występują w danym projekcie.

## Podejście do nauki

**Zbuduj → zrozum → zepsuj w kontrolowanych warunkach → zdiagnozuj → napraw → udokumentuj.**

Projekty są realizowane w prywatnym środowisku laboratoryjnym. Przed wykorzystaniem rozwiązań produkcyjnie należy uwzględnić m.in. redundancję hostów i storage, bezpieczeństwo dostępu, kopie zapasowe oraz testy odtworzeniowe.

---

[← Powrót do głównego repozytorium](../README.md)
