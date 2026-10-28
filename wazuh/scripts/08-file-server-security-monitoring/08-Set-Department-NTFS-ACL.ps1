#requires -Version 5.1
#requires -RunAsAdministrator
[CmdletBinding(SupportsShouldProcess=$true, ConfirmImpact='High')]
param(
    [string]$Root = 'S:\CYFROWY POLSAT',
    [string]$Domain = 'CYBER',
    [switch]$Apply
)
Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

# Only modify dedicated test department directories. No broad recursive changes.
$departments = [ordered]@{
    'Ksiegowosc' = 'GG_W08_Ksiegowosc_RW'
    'Kadry' = 'GG_W08_Kadry_RW'
    'Produkcja' = 'GG_W08_Produkcja_RW'
    'Zarzad' = 'GG_W08_Zarzad_RW'
    'IT' = 'GG_W08_IT_RW'
    'Testy_Wazuh' = 'GG_W08_Testy_Wazuh_RW'
    'Public' = 'Domain Users'
}

if (-not (Test-Path -LiteralPath $Root -PathType Container)) { throw "Nie istnieje folder: $Root" }
$drive = (Split-Path -Path $Root -Qualifier).TrimEnd(':')
$volume = Get-Volume -DriveLetter $drive -ErrorAction Stop
if ($volume.FileSystemLabel -ne 'CLUSTER-DATA') { throw "Dysk $drive`: ma etykiete '$($volume.FileSystemLabel)', oczekiwano CLUSTER-DATA." }

# Resolve SIDs up front, preventing partial modifications due to missing principals.
$administratorsSid = New-Object System.Security.Principal.SecurityIdentifier 'S-1-5-32-544'
$systemSid = New-Object System.Security.Principal.SecurityIdentifier 'S-1-5-18'
$adminName = $administratorsSid.Translate([System.Security.Principal.NTAccount]).Value
$systemName = $systemSid.Translate([System.Security.Principal.NTAccount]).Value
$targets = @()
foreach ($department in $departments.Keys) {
    $path = Join-Path $Root $department
    if (-not (Test-Path -LiteralPath $path -PathType Container)) { throw "Brak folderu: $path" }
    $account = "$Domain\$($departments[$department])"
    try { $null = (New-Object System.Security.Principal.NTAccount($account)).Translate([System.Security.Principal.SecurityIdentifier]) }
    catch { throw "Nie mozna odnalezc grupy $account. Sprawdz NetBIOS domeny (parametr -Domain)." }
    $targets += [pscustomobject]@{Path=$path; Account=$account}
}

$backupDir = Join-Path $env:ProgramData ('Wazuh08-AclBackup-' + (Get-Date -Format 'yyyyMMdd-HHmmss'))
if ($Apply) {
    New-Item -Path $backupDir -ItemType Directory -Force | Out-Null
    & icacls.exe $Root /save (Join-Path $backupDir 'acl-before.txt') /T /C | Out-Null
    if ($LASTEXITCODE -ne 0) { throw 'Backup ACL przez icacls zwrocil blad. Niczego nie zmieniono.' }
    Write-Host "Backup ACL: $backupDir" -ForegroundColor Cyan
} else {
    Write-Host 'TRYB PODGLADU - brak modyfikacji. Aby zapisac ACL, uruchom z -Apply -Confirm:$false' -ForegroundColor Yellow
}

$inheritFlags = [System.Security.AccessControl.InheritanceFlags]'ContainerInherit, ObjectInherit'
$propFlags = [System.Security.AccessControl.PropagationFlags]::None
$allow = [System.Security.AccessControl.AccessControlType]::Allow

foreach ($target in $targets) {
    Write-Host "Folder: $($target.Path)  =>  $($target.Account) (Modify)"
    if (-not $Apply) { continue }
    if (-not $PSCmdlet.ShouldProcess($target.Path, "Zastap ACL folderu i dziedziczonych obiektow uprawnieniami dzialowymi")) { continue }

    # Protect the folder; explicitly define SYSTEM, Administrators and department group.
    $acl = Get-Acl -LiteralPath $target.Path
    $acl.SetAccessRuleProtection($true, $false)
    foreach ($rule in @($acl.Access)) { $acl.RemoveAccessRuleSpecific($rule) }
    foreach ($spec in @(
        @{Id=$adminName; Rights=[System.Security.AccessControl.FileSystemRights]::FullControl},
        @{Id=$systemName; Rights=[System.Security.AccessControl.FileSystemRights]::FullControl},
        @{Id=$target.Account; Rights=[System.Security.AccessControl.FileSystemRights]::Modify}
    )) {
        $rule = New-Object System.Security.AccessControl.FileSystemAccessRule($spec.Id, $spec.Rights, $inheritFlags, $propFlags, $allow)
        $acl.AddAccessRule($rule)
    }
    Set-Acl -LiteralPath $target.Path -AclObject $acl
    Write-Host "[OK] $($target.Path)" -ForegroundColor Green
}

Write-Host 'Uwaga: skrypt ustawia ACL na folderach dzialowych i reguly dziedziczenia na przyszlosc. Nie przebudowuje automatycznie ACL istniejacych plikow, ktore moga miec uprawnienia jawne lub wylaczone dziedziczenie. Zweryfikuj ACL konkretnych plikow przed testami.' -ForegroundColor Yellow
