$ErrorActionPreference = "Stop"

$IsAdmin = ([Security.Principal.WindowsPrincipal] `
    [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole(
        [Security.Principal.WindowsBuiltInRole]::Administrator
    )

"$(Get-Date) | User: $env:USERNAME | Admin: $IsAdmin" |
    Out-File "C:\Scripts\scheduler-test.log" -Append

$LogFile = "C:\Scripts\WindowsUpdate-Scheduler.log"

"======================================" | Out-File $LogFile -Append
"START: $(Get-Date)" | Out-File $LogFile -Append
"USER: $([System.Security.Principal.WindowsIdentity]::GetCurrent().Name)" | Out-File $LogFile -Append
"ADMIN: $IsAdmin" | Out-File $LogFile -Append
"SESSION: $env:SESSIONNAME" | Out-File $LogFile -Append
"======================================" | Out-File $LogFile -Append




# ============================================================
# KONFIGURACJA
# ============================================================

$WebhookUrl = "https://n8n.tworzewski.pl/webhook/windows-update-install"

# Ile sekund do restartu
$RestartDelay = 60

# ============================================================
# ZMIENNE
# ============================================================

$Status = "FAILED"
$FoundCount = 0
$InstalledCount = 0

$WURebootRequired = $false
$PendingReboot = $false
$RebootReasons = @()

$ResultCode = $null
$DownloadResultCode = $null

$ErrorMessage = ""
$UpdateDetails = @()

$ReportSent = $false


Write-Host ""
Write-Host "============================================="
Write-Host "       WINDOWS UPDATE - INSTALL"
Write-Host "============================================="
Write-Host "Komputer: $env:COMPUTERNAME"
Write-Host "Data: $(Get-Date)"
Write-Host ""


# ============================================================
# SPRAWDZENIE UPRAWNIEN ADMINISTRATORA
# ============================================================

$IsAdmin = (
    New-Object Security.Principal.WindowsPrincipal(
        [Security.Principal.WindowsIdentity]::GetCurrent()
    )
).IsInRole(
    [Security.Principal.WindowsBuiltInRole]::Administrator
)

Write-Host "Uprawnienia administratora: $IsAdmin"
Write-Host ""

if (-not $IsAdmin) {

    Write-Host "BLAD: Skrypt musi byc uruchomiony jako Administrator."

    exit 1
}


try {

    # ========================================================
    # WINDOWS UPDATE SESSION
    # ========================================================

    $Session = New-Object -ComObject Microsoft.Update.Session

    $Searcher = $Session.CreateUpdateSearcher()


    # ========================================================
    # WYSZUKIWANIE AKTUALIZACJI
    # ========================================================

    Write-Host "Szukam aktualizacji..."

    $SearchResult = $Searcher.Search("IsInstalled=0")

    $FoundCount = $SearchResult.Updates.Count


    Write-Host "Znaleziono aktualizacji: $FoundCount"
    Write-Host ""


    # ========================================================
    # BRAK AKTUALIZACJI
    # ========================================================

    if ($FoundCount -eq 0) {

        $Status = "NO_UPDATES"

        $ResultCode = 2

        Write-Host "Brak aktualizacji do instalacji."
    }


    # ========================================================
    # SA AKTUALIZACJE
    # ========================================================

    else {

        $UpdatesToInstall = New-Object -ComObject Microsoft.Update.UpdateColl


        # ====================================================
        # PRZYGOTOWANIE AKTUALIZACJI
        # ====================================================

        foreach ($Update in $SearchResult.Updates) {

            Write-Host "Znaleziono: $($Update.Title)"


            if (-not $Update.EulaAccepted) {

                $Update.AcceptEula()
            }


            [void]$UpdatesToInstall.Add($Update)
        }


        Write-Host ""
        Write-Host "---------------------------------------------"
        Write-Host "POBIERANIE AKTUALIZACJI"
        Write-Host "---------------------------------------------"
        Write-Host ""


        # ====================================================
        # POBIERANIE
        # ====================================================

        $Downloader = $Session.CreateUpdateDownloader()

        $Downloader.Updates = $UpdatesToInstall


        $DownloadResult = $Downloader.Download()

        $DownloadResultCode = $DownloadResult.ResultCode


        Write-Host "Pobieranie zakonczone."
        Write-Host "Download ResultCode: $DownloadResultCode"
        Write-Host ""


        # ====================================================
        # SPRAWDZENIE POBIERANIA
        # ====================================================

        if (
            $DownloadResultCode -ne 2 -and
            $DownloadResultCode -ne 3
        ) {

            throw "Pobieranie aktualizacji nie powiodlo sie. ResultCode: $DownloadResultCode"
        }


        # ====================================================
        # INSTALACJA
        # ====================================================

        Write-Host "---------------------------------------------"
        Write-Host "INSTALACJA AKTUALIZACJI"
        Write-Host "---------------------------------------------"
        Write-Host ""

        Write-Host "Instaluje aktualizacje..."


        $Installer = $Session.CreateUpdateInstaller()

        $Installer.Updates = $UpdatesToInstall


        $InstallResult = $Installer.Install()


        $ResultCode = $InstallResult.ResultCode

        $WURebootRequired = $InstallResult.RebootRequired


        Write-Host ""
        Write-Host "=== WYNIK INSTALACJI ==="

        Write-Host "ResultCode: $ResultCode"

        Write-Host "Windows Update RebootRequired: $WURebootRequired"

        Write-Host ""


        # ====================================================
        # WYNIK KAZDEJ AKTUALIZACJI
        # ====================================================

        for (
            $i = 0;
            $i -lt $UpdatesToInstall.Count;
            $i++
        ) {

            $Update = $UpdatesToInstall.Item($i)

            $UpdateResult = $InstallResult.GetUpdateResult($i)


            $UpdateResultCode = $UpdateResult.ResultCode


            $HResultHex = "0x{0:X8}" -f (
                $UpdateResult.HResult -band 0xffffffff
            )


            # ================================================
            # STATUS AKTUALIZACJI
            # ================================================

            if ($UpdateResultCode -eq 2) {

                $InstalledCount++

                $UpdateStatus = "SUCCESS"
            }

            elseif ($UpdateResultCode -eq 3) {

                $InstalledCount++

                $UpdateStatus = "SUCCESS_WITH_ERRORS"
            }

            else {

                $UpdateStatus = "FAILED"
            }


            Write-Host "Aktualizacja: $($Update.Title)"

            Write-Host "Status: $UpdateStatus"

            Write-Host "ResultCode: $UpdateResultCode"

            Write-Host "HResult: $HResultHex"

            Write-Host ""


            # ================================================
            # DANE DLA N8N
            # ================================================

            $UpdateDetails += [PSCustomObject]@{

                title      = $Update.Title

                status     = $UpdateStatus

                resultCode = $UpdateResultCode

                hresult    = $HResultHex
            }
        }


        # ====================================================
        # STATUS CALEJ INSTALACJI
        # ====================================================

        if ($ResultCode -eq 2) {

            $Status = "SUCCESS"
        }

        elseif ($ResultCode -eq 3) {

            $Status = "SUCCESS_WITH_ERRORS"
        }

        else {

            $Status = "FAILED"
        }
    }
}

catch {

    $Status = "FAILED"

    $ErrorMessage = $_.Exception.Message


    Write-Host ""
    Write-Host "============================================="
    Write-Host "BLAD WINDOWS UPDATE"
    Write-Host "============================================="

    Write-Host $ErrorMessage
}


# ============================================================
# SPRAWDZENIE CZY WINDOWS WYMAGA RESTARTU
# ============================================================

Write-Host ""
Write-Host "---------------------------------------------"
Write-Host "SPRAWDZANIE RESTARTU"
Write-Host "---------------------------------------------"
Write-Host ""


# ============================================================
# 1. WINDOWS UPDATE API
# ============================================================

if ($WURebootRequired) {

    $PendingReboot = $true

    $RebootReasons += "Windows Update"
}


# ============================================================
# 2. COMPONENT BASED SERVICING
# ============================================================

if (
    Test-Path `
    "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Component Based Servicing\RebootPending"
) {

    $PendingReboot = $true

    $RebootReasons += "Component Based Servicing"
}


# ============================================================
# 3. WINDOWS UPDATE REBOOT REQUIRED
# ============================================================

if (
    Test-Path `
    "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\WindowsUpdate\Auto Update\RebootRequired"
) {

    $PendingReboot = $true

    $RebootReasons += "Windows Update RebootRequired"
}


# ============================================================
# 4. PENDING FILE RENAME OPERATIONS
# ============================================================

$SessionManager = Get-ItemProperty `
    "HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager" `
    -Name PendingFileRenameOperations `
    -ErrorAction SilentlyContinue


if ($SessionManager.PendingFileRenameOperations) {

    $PendingReboot = $true

    $RebootReasons += "PendingFileRenameOperations"
}


# ============================================================
# INFORMACJA O RESTART
# ============================================================

if ($PendingReboot) {

    Write-Host "Restart komputera jest WYMAGANY."

    Write-Host ""

    Write-Host "Powody restartu:"


    foreach ($Reason in $RebootReasons) {

        Write-Host " - $Reason"
    }
}

else {

    Write-Host "Restart komputera NIE jest wymagany."
}


# ============================================================
# PODSUMOWANIE
# ============================================================

Write-Host ""
Write-Host "============================================="
Write-Host "PODSUMOWANIE"
Write-Host "============================================="

Write-Host "Komputer: $env:COMPUTERNAME"

Write-Host "Status: $Status"

Write-Host "Znaleziono: $FoundCount"

Write-Host "Zainstalowano poprawnie: $InstalledCount"

Write-Host "Download ResultCode: $DownloadResultCode"

Write-Host "Install ResultCode: $ResultCode"

Write-Host "Restart wymagany: $PendingReboot"


if ($ErrorMessage) {

    Write-Host "Blad: $ErrorMessage"
}


# ============================================================
# PRZYGOTOWANIE RAPORTU DLA N8N
# ============================================================

$Body = @{

    host = $env:COMPUTERNAME

    date = (
        Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    )

    status = $Status

    found = $FoundCount

    installed = $InstalledCount

    downloadResultCode = $DownloadResultCode

    resultCode = $ResultCode

    rebootRequired = $PendingReboot

    rebootReasons = $RebootReasons

    error = $ErrorMessage

    updates = $UpdateDetails
}


$JsonBody = $Body | ConvertTo-Json -Depth 5


# ============================================================
# WYSYLANIE RAPORTU DO N8N
# ============================================================

Write-Host ""
Write-Host "---------------------------------------------"
Write-Host "N8N"
Write-Host "---------------------------------------------"

Write-Host ""

Write-Host "Wysylam raport do n8n..."


try {

    $Response = Invoke-RestMethod `
        -Uri $WebhookUrl `
        -Method POST `
        -ContentType "application/json" `
        -Body $JsonBody


    $ReportSent = $true


    Write-Host "Raport wyslany do n8n."
}

catch {

    $ReportSent = $false


    Write-Host ""

    Write-Host "BLAD WYSYLANIA DO N8N:"

    Write-Host $_.Exception.Message
}


# ============================================================
# AUTOMATYCZNY RESTART
# ============================================================

Write-Host ""
Write-Host "---------------------------------------------"
Write-Host "DECYZJA O RESTART"
Write-Host "---------------------------------------------"
Write-Host ""


# Restart wykonujemy tylko gdy:
#
# 1. Windows wymaga restartu
# 2. Instalacja zakonczyla sie sukcesem
#    lub sukcesem z bledami
# 3. Raport zostal wyslany do n8n

if (
    $PendingReboot -and
    (
        $Status -eq "SUCCESS" -or
        $Status -eq "SUCCESS_WITH_ERRORS"
    ) -and
    $ReportSent
) {

    Write-Host "Aktualizacje zostaly zainstalowane."

    Write-Host "Windows wymaga restartu."

    Write-Host "Raport zostal wyslany do n8n."

    Write-Host ""

    Write-Host "UWAGA!"

    Write-Host "Komputer zostanie uruchomiony ponownie za $RestartDelay sekund."


    shutdown.exe `
        /r `
        /t $RestartDelay `
        /c "Windows Update - automatyczny restart po instalacji aktualizacji"
}

elseif (
    $PendingReboot -and
    -not $ReportSent
) {

    Write-Host "Restart jest wymagany, ale raport NIE zostal wyslany do n8n."

    Write-Host "Ze wzgledow bezpieczenstwa automatyczny restart NIE zostanie wykonany."
}

elseif (
    $PendingReboot -and
    $Status -eq "FAILED"
) {

    Write-Host "Restart jest oznaczony jako wymagany, ale instalacja zakonczyla sie bledem."

    Write-Host "Automatyczny restart NIE zostanie wykonany."
}

else {

    Write-Host "Automatyczny restart nie jest wymagany."
}


Write-Host ""
Write-Host "============================================="
Write-Host "KONIEC"
Write-Host "============================================="