#requires -Modules ActiveDirectory
[CmdletBinding(SupportsShouldProcess = $true)]
param(
    [string]$OldName = 'WAZUH-08-LAB',
    [string]$NewName = 'CYBERNET'
)
$ErrorActionPreference = 'Stop'
Import-Module ActiveDirectory
$domainDN = (Get-ADDomain).DistinguishedName
$oldDN = "OU=$OldName,$domainDN"
$oldOU = Get-ADOrganizationalUnit -Identity $oldDN -ErrorAction Stop
$newDN = "OU=$NewName,$domainDN"
if (Get-ADOrganizationalUnit -LDAPFilter "(ou=$NewName)" -SearchBase $domainDN -SearchScope OneLevel) {
    throw "OU '$NewName' juz istnieje w glownym poziomie domeny. Nie zmieniono nic."
}
if ($PSCmdlet.ShouldProcess($oldOU.DistinguishedName, "Zmien nazwe OU na '$NewName'")) {
    Rename-ADObject -Identity $oldOU.DistinguishedName -NewName $NewName -ErrorAction Stop
    Write-Host "Zmieniono nazwe OU: $oldDN -> $newDN" -ForegroundColor Green
    Write-Host 'Podrzedne OU, uzytkownicy i grupy pozostaly w nowym OU.' -ForegroundColor Cyan
}
