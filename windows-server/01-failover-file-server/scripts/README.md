# Skrócona ściąga PowerShell

> Polecenia destrukcyjne zawarte w dokumentacji wykonuj wyłącznie po sprawdzeniu `UniqueId` i rozmiaru dysku. To laboratorium, nie skrypt do bezrefleksyjnego uruchomienia w produkcji.

## Weryfikacja Windows i klastra

```powershell
Get-WindowsFeature FS-FileServer,Failover-Clustering
Test-NetConnection 10.1.201.230 -Port 3260
Get-IscsiSession
Get-Disk | Format-Table Number,FriendlyName,UniqueId,Size,IsOffline,PartitionStyle
Get-ClusterNode | Format-Table Name,State
Get-ClusterGroup 'LAB-FILES' | Format-Table Name,OwnerNode,State
Get-ClusterQuorum
Get-ClusterResource | Format-Table Name,ResourceType,State,OwnerGroup
```

## Raporty

```powershell
Test-Cluster -Node FS1,FS2
# Lub test diagnostyczny storage (z potencjalnym wpływem na dyski!)
Test-Cluster -Node FS1,FS2 -Include Storage
Get-ChildItem 'C:\Windows\Cluster\Reports\*.htm' | Sort-Object LastWriteTime -Descending | Select-Object -First 1 | ForEach-Object { Invoke-Item $_.FullName }
```

## Prosty polling SMB na kliencie

```powershell
while ($true) {
    '{0} | SMB: {1}' -f (Get-Date -Format 'HH:mm:ss'), (Test-Path '\\LAB-FILES\DANE')
    Start-Sleep -Seconds 1
}
```

Przerwanie: `Ctrl+C`. To prosty test dostępności, nie benchmark RTO.
