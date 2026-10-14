# 04 — Tworzenie klastra i osobnego Disk Witness

[← Poprzedni](03-windows-walidacja.md) | [README](../README.md) | [Następny →](05-file-server-smb.md)

## 1. Create Cluster Wizard

Po pełnej walidacji w **Failover Cluster Manager → Create Cluster** wybrano:

- `FS1.cyber.local`, `FS2.cyber.local`
- Cluster Name: `LAB-CLUSTER`
- Static IPv4: `10.1.201.223` (sprawdzony wolny adres)

Wynik: **Create Cluster Wizard successfully completed**. Oba węzły `Up`.

![Utworzenie klastra](../screenshots/28-cluster-creation-summary.png)

## 2. Automatyczny wybór nieoptymalnego świadka

Kreator wybrał `Node and Disk Majority (Cluster Disk 1)` i użył jedynego dostępnego wówczas LUN 30 GiB jako Disk Witness. To nie odpowiadało docelowemu podziałowi, bo 30 GiB miało służyć do przechowywania plików SMB.

```powershell
Get-ClusterQuorum
Get-ClusterResource | Format-Table Name,ResourceType,State,OwnerGroup -AutoSize
```

![Początkowy witness](../screenshots/30-initial-quorum-resource.png)

## 3. Osobny LUN 1 GiB

Na TrueNAS: utworzono `ZVOL-QUORUM` (1 GiB), `extent-quorum` i podłączono do Targetu jako LUN 1. Po `Update-HostStorageCache` obydwa węzły widziały nowy dysk iSCSI (w przykładzie `Disk 2`).

### Przygotowanie nowego, pustego LUN

Na FS1, po identyfikacji unikatowego ID i rozmiaru:

```powershell
Get-Disk -Number 2 | Format-List Number,FriendlyName,UniqueId,Size,IsOffline,PartitionStyle
Set-Disk -Number 2 -IsOffline $false
Initialize-Disk -Number 2 -PartitionStyle GPT
New-Partition -DiskNumber 2 -UseMaximumSize |
    Format-Volume -FileSystem NTFS -NewFileSystemLabel 'CLUSTER-QUORUM' -Confirm:$false
```

Na FS2 odświeżono storage i zostawiono dysk Offline do momentu przejęcia nad nim kontroli przez klaster; nie przeprowadzano kolejnej inicjalizacji:

```powershell
Update-HostStorageCache
Get-Disk -Number 2 | Format-List UniqueId,IsOffline,PartitionStyle,Size
```

![Przygotowany witness](../screenshots/39-quorum-disk-gpt-ntfs.png)

## 4. Walidacja i zmiana quorum

```powershell
Test-Cluster -Node FS1,FS2 -Include Storage
```

Po sprawdzeniu, czy test rzeczywiście obejmuje nowy LUN i kończy się sukcesem:

1. **Failover Cluster Manager → Storage → Disks → Add Disk**.
2. Dodano **tylko LUN 1 GiB** jako `Cluster Disk 2`.
3. Węzeł główny → **More Actions → Configure Cluster Quorum Settings**.
4. **Select the quorum witness → Configure a disk witness → Cluster Disk 2 (1 GiB)**.
5. Potwierdzono `Get-ClusterQuorum`.

```powershell
Get-ClusterQuorum
# QuorumResource = Cluster Disk 2
```

Rezultat: `Cluster Disk 1` (30 GiB) przeszedł do `Available Storage`, `Cluster Disk 2` (1 GiB) został `Disk Witness in Quorum`.

![Docelowe dyski w klastrze](../screenshots/42-cluster-witness-switched.png)

## Dlaczego osobny świadek?

- Nie zużywamy na witness dysku przeznaczonego do roli danych.
- Węzły i witness uczestniczą w decyzjach quorum, ograniczając ryzyko split-brain.
- **Wada:** oba LUN-y leżą na tym samym TrueNAS. Awaria tego serwera usuwa zarówno storage danych, jak i witness. W produkcji rozważ niezależny File Share Witness lub Cloud Witness i redundantne storage.
