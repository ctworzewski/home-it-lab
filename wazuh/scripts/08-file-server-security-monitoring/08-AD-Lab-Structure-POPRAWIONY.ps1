#requires -Modules ActiveDirectory
<#
Projekt 08: Active Directory - testowe OU, grupy i uzytkownicy.
Uruchom jako PLIK .ps1 (nie wklejaj tresci linia po linii):
  .\08-AD-Lab-Structure-POPRAWIONY.ps1 -WhatIf
  .\08-AD-Lab-Structure-POPRAWIONY.ps1
Uwaga: nie tworzy folderow SMB, nie ustawia hasel, konta wylaczone.
#>
[CmdletBinding(SupportsShouldProcess = $true, ConfirmImpact = 'Medium')]
param()

$ErrorActionPreference = 'Stop'
Import-Module ActiveDirectory -ErrorAction Stop
$domain = Get-ADDomain
$rootDN = $domain.DistinguishedName
$labName = 'WAZUH-08-LAB'
$labDN = "OU=$labName,$rootDN"
$groupsDN = "OU=Grupy,$labDN"

$departments = @(
  @{ Name='Ksiegowosc'; Group='GG_W08_Ksiegowosc_RW'; People=@(@('Anna','Kowalska','akowalska'),@('Piotr','Malinowski','pmalinowski')) },
  @{ Name='Kadry'; Group='GG_W08_Kadry_RW'; People=@(@('Ewa','Nowicka','enowicka'),@('Marta','Lis','mlis')) },
  @{ Name='Produkcja'; Group='GG_W08_Produkcja_RW'; People=@(@('Tomasz','Zielinski','tzielinski'),@('Pawel','Krawczyk','pkrawczyk')) },
  @{ Name='Zarzad'; Group='GG_W08_Zarzad_RW'; People=@(@('Adam','Wisniewski','awisniewski')) },
  @{ Name='IT'; Group='GG_W08_IT_RW'; People=@(@('Karol','Mazur','kmazur')) },
  @{ Name='Public'; Group='GG_W08_Public_RW'; People=@() },
  @{ Name='Testy_Wazuh'; Group='GG_W08_Testy_Wazuh_RW'; People=@(@('Jan','Testowy','jtestowy')) }
)

Write-Host "Domena: $($domain.DNSRoot)" -ForegroundColor Cyan
Write-Host "Projekt: $labDN" -ForegroundColor Cyan

# Wykonywane w zakresie skryptu: $PSCmdlet istnieje dzieki CmdletBinding.
$ous = @(
  @{ Name=$labName; Parent=$rootDN }
  @{ Name='Grupy'; Parent=$labDN }
)
foreach ($dept in $departments) { $ous += @{ Name=$dept.Name; Parent=$labDN } }

foreach ($ou in $ous) {
  $dn = "OU=$($ou.Name),$($ou.Parent)"
  $existing = Get-ADOrganizationalUnit -LDAPFilter "(distinguishedName=$dn)" -ErrorAction Stop
  if ($existing) {
    Write-Host "[OK] OU: $dn"
  } elseif ($PSCmdlet.ShouldProcess($dn, 'Utworzenie OU')) {
    New-ADOrganizationalUnit -Name $ou.Name -Path $ou.Parent -ProtectedFromAccidentalDeletion $true -ErrorAction Stop
    Write-Host "[+] OU: $dn" -ForegroundColor Green
  }
}

foreach ($dept in $departments) {
  $name = $dept.Group
  $groupTargetDN = "CN=$name,$groupsDN"
  $g = Get-ADGroup -LDAPFilter "(sAMAccountName=$name)" -ErrorAction Stop
  if ($g) {
    if ($g.DistinguishedName -ne $groupTargetDN) { throw "Grupa $name istnieje POZA laboratorium: $($g.DistinguishedName)" }
    Write-Host "[OK] Grupa: $name"
  } elseif ($PSCmdlet.ShouldProcess($name, 'Utworzenie grupy')) {
    New-ADGroup -Name $name -SamAccountName $name -GroupScope Global -GroupCategory Security -Path $groupsDN -Description "WAZUH 08 - uprawnienia Modify: $($dept.Name)" -ErrorAction Stop
    Write-Host "[+] Grupa: $name" -ForegroundColor Green
  }

  foreach ($p in $dept.People) {
    $first = $p[0]; $last = $p[1]; $login = $p[2]
    $full = "$first $last"
    $userDN = "CN=$full,OU=$($dept.Name),$labDN"
    $u = Get-ADUser -LDAPFilter "(sAMAccountName=$login)" -ErrorAction Stop
    if ($u) {
      if ($u.DistinguishedName -ne $userDN) { throw "Login $login istnieje POZA docelowym OU: $($u.DistinguishedName)" }
      Write-Host "[OK] Uzytkownik: $login"
    } elseif ($PSCmdlet.ShouldProcess($login, 'Utworzenie wylaczonego uzytkownika')) {
      New-ADUser -Name $full -GivenName $first -Surname $last -DisplayName $full -SamAccountName $login -UserPrincipalName "$login@$($domain.DNSRoot)" -Path "OU=$($dept.Name),$labDN" -Enabled $false -Description 'Konto fikcyjne - WAZUH 08' -ErrorAction Stop
      Write-Host "[+] Uzytkownik: $login (wylaczony)" -ForegroundColor Green
    }

    # Czlonkostwo tylko dla uzytkownikow i grup nalezacych do projektu.
    $u = Get-ADUser -LDAPFilter "(sAMAccountName=$login)" -ErrorAction Stop
    $g = Get-ADGroup -LDAPFilter "(sAMAccountName=$name)" -ErrorAction Stop
    if ($u -and $g -and $u.DistinguishedName -eq $userDN -and $g.DistinguishedName -eq $groupTargetDN) {
      $isMember = Get-ADGroupMember -Identity $g -ErrorAction Stop | Where-Object { $_.DistinguishedName -eq $u.DistinguishedName }
      if (-not $isMember -and $PSCmdlet.ShouldProcess("$login -> $name", 'Dodanie do grupy')) {
        Add-ADGroupMember -Identity $g -Members $u -ErrorAction Stop
        Write-Host "[+] Czlonkostwo: $login -> $name" -ForegroundColor Green
      }
    }
  }
}
Write-Host 'Gotowe: konta wylaczone; brak zmian w SMB i ACL.' -ForegroundColor Cyan
