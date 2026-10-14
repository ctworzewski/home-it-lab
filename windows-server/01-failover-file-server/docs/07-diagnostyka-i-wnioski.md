# 07 — Diagnostyka, ograniczenia i kolejne ćwiczenia

[← Poprzedni](06-testy-failover.md) | [README](../README.md)

## Problemy napotkane w trakcie

| Objaw | Przyczyna / rozpoznanie | Rozwiązanie |
|---|---|---|
| FS2 `TcpTestSucceeded False`, `DestinationHostUnreachable` | Problem komunikacji z TrueNAS, przed warstwą usługi iSCSI | Diagnostyka IP/VLAN/vSwitch i ponowny test portu; wynik True |
| Storage `Not Applicable` | `RAW disks cannot be clustered` w raporcie walidacji | GPT/NTFS na jednym węźle, potem pełna walidacja |
| `Get-ClusterAvailableDisk` error przed stworzeniem klastra | Brak działającego klastra | Nie uruchamiać cmdletu zarządzającego zasobami przed jego utworzeniem |
| Nie można otworzyć HTML `Invoke-Item .\raport.htm` | Raport zapisany gdzie indziej | `C:\Windows\Cluster\Reports` |
| Automatyczny Disk Witness na 30 GiB | Jedyny LUN w momencie tworzenia klastra | Osobny LUN 1 GiB i zmiana konfiguracji quorum |
| `At least one disk needs to have a drive letter` | Wolumin NTFS nie miał litery | Na właścicielu dysku przypisano `S:` |
| Network Validation Warning | Jedna ścieżka komunikacji FS1 ↔ FS2 | W labie akceptacja, w produkcji redundancja |

## Niezbędne polecenia diagnostyczne

```powershell
Test-NetConnection 10.1.201.230 -Port 3260
Get-IscsiSession
Get-Disk | Format-Table Number,FriendlyName,BusType,IsOffline,PartitionStyle,UniqueId,Size
Get-ClusterNode
Get-ClusterGroup
Get-ClusterResource
Get-ClusterQuorum
Get-ClusterGroup 'LAB-FILES' | Format-Table Name,OwnerNode,State
```

Najświeższy raport walidacji:

```powershell
Get-ChildItem 'C:\Windows\Cluster\Reports\*.htm' |
  Sort-Object LastWriteTime -Descending |
  Select-Object -First 1 |
  ForEach-Object { Invoke-Item $_.FullName }
```

## Produkcyjne ograniczenia

1. **TrueNAS** jako jedyny storage stanowi SPOF, podobnie jak jego zasilanie, system plików i sieć.
2. **Jeden host Hyper-V** — jeśli cały host ulegnie awarii, przestaną działać oba węzły, niezależnie od ich konfiguracji klastrowej.
3. **Jedna karta / jeden tor sieciowy** — walidator ostrzegał o braku niezależnej ścieżki komunikacji.
4. **Wspólny Target i dwa LUN-y** — rozdzielenie funkcji nie jest fizyczną redundancją storage ani witness.
5. **Backup** — snapshots TrueNAS i checkpointy pojedynczych VM nie zastępują spójnego, testowanego odtwarzania zasobów.
6. **ACL** — wymagają osobnej weryfikacji zarówno po stronie SMB, jak i NTFS.
7. **Monitoring** — bez pomiaru czasu i analizy event logów nie wyliczamy RTO/RPO na podstawie samych screenów.

## Dalsze eksperymenty

- Zabbix: stan `Get-ClusterNode`, `Get-ClusterGroup`, alarm „Failover”, czas niedostępności udziału.
- Wazuh: Microsoft-Windows-FailoverClustering/Operational, zmiany SMB/NTFS i kontrolowany audyt usuwania plików.
- Ciągły zapis z klienta i rejestr czasu błędów, zamknięte/otwarte uchwyty i SMB Continuous Availability.
- Test wyłączenia FS1 przy roli LAB-FILES na FS1.
- File Share Witness na oddzielnym systemie i porównanie quorum z Disk Witness.
- Projekt redundantnego storage/MPIO i dwóch niezależnych hostów Hyper-V.
- Dokumentacja zarządzania patchami i backupem oraz test restore.

## Notatka o publikacji screenów

Zrzuty zachowują rzeczywistą labową adresację, nazwy, daty i godziny. Jeden fragment screenów z notatkami VM zawierał jawną informację uwierzytelniającą i został zakryty przed przygotowaniem materiałów do publikacji. Jeżeli to hasło jest nadal gdzieś wykorzystywane, należy je zmienić niezależnie od redakcji obrazu.
