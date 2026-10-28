# Projekt 08 - struktura katalogow na dysku klastra LAB-FILES
# Uruchom jako Administrator na aktualnym wlascicielu dysku danych.
# Nie zmienia ACL ani konfiguracji SMB.
[CmdletBinding(SupportsShouldProcess=$true, ConfirmImpact='Medium')]
param(
    [string]$Drive = 'S:',
    [string]$ExpectedLabel = 'CLUSTER-DATA'
)

$ErrorActionPreference = 'Stop'
Import-Module FailoverClusters -ErrorAction Stop

$disk = Get-ClusterResource -Name 'Cluster Disk 1' -ErrorAction Stop
if ($disk.State -ne 'Online' -or $disk.OwnerNode.Name -ne $env:COMPUTERNAME -or $disk.OwnerGroup.Name -ne 'LAB-FILES') {
    throw "Cluster Disk 1 musi byc Online, przypisany do LAB-FILES i nalezec do lokalnego wezla. Stan: $($disk.State), wlasciciel: $($disk.OwnerNode.Name), grupa: $($disk.OwnerGroup.Name)."
}

$letter = $Drive.TrimEnd(':')
$volume = Get-Volume -DriveLetter $letter -ErrorAction Stop
if ($volume.FileSystemLabel -ne $ExpectedLabel -or $volume.FileSystem -ne 'NTFS') {
    throw "Niewlasciwy wolumin: $Drive (etykieta=$($volume.FileSystemLabel), system=$($volume.FileSystem))."
}

$root = Join-Path "$letter`:" 'CYFROWY POLSAT'
$directories = @('Ksiegowosc','Kadry','Produkcja','Zarzad','IT','Public','Testy_Wazuh')
$files = @{
    'Ksiegowosc' = @('Faktura_001.txt','Rozliczenie_Miesieczne.txt','Budzet_2026.txt')
    'Kadry' = @('Lista_Pracownikow.txt','Urlopy_2026.txt')
    'Produkcja' = @('Plan_Produkcji.txt','Raport_Zmiany.txt','Zlecenia.txt')
    'Zarzad' = @('Strategia_2026.txt','Protokol_Zarzadu.txt')
    'IT' = @('Inwentaryzacja.txt','Procedura_Backupu.txt','Rejestr_Incydentow.txt')
    'Public' = @('Komunikat_Firmowy.txt','Regulamin.txt')
    'Testy_Wazuh' = @('Test_Usuwania.txt','Test_Modyfikacji.txt')
}

if (-not (Test-Path -LiteralPath $root)) {
    if ($PSCmdlet.ShouldProcess($root, 'Utworz folder glowny')) {
        New-Item -ItemType Directory -Path $root -ErrorAction Stop | Out-Null
    }
}

foreach ($name in $directories) {
    $path = Join-Path $root $name
    if (-not (Test-Path -LiteralPath $path)) {
        if ($PSCmdlet.ShouldProcess($path, 'Utworz folder')) {
            New-Item -ItemType Directory -Path $path -ErrorAction Stop | Out-Null
        }
    }
    foreach ($file in $files[$name]) {
        $filePath = Join-Path $path $file
        if (-not (Test-Path -LiteralPath $filePath)) {
            if ($PSCmdlet.ShouldProcess($filePath, 'Utworz dokument testowy')) {
                "Projekt 08 - CYFROWY POLSAT`r`nDzial: $name`r`nPlik: $file`r`nDane fikcyjne do testow Wazuh." |
                    Set-Content -LiteralPath $filePath -Encoding UTF8 -ErrorAction Stop
            }
        }
    }
}

Write-Host "Gotowe (lub symulacja -WhatIf). Lokalizacja: $root" -ForegroundColor Green
Write-Host 'Skrypt nie zmienia uprawnien NTFS ani udzialow SMB.'
