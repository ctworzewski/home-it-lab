$ErrorActionPreference = "Stop"

# TU WKLEISZ ADRES WEBHOOKA Z n8n
$WebhookUrl = "https://n8n.tworzewski.pl/webhook/windows-update"

Write-Host "=== WINDOWS UPDATE CHECK ==="
Write-Host "Komputer: $env:COMPUTERNAME"
Write-Host "Data: $(Get-Date)"
Write-Host ""

try {

    $UpdateSession = New-Object -ComObject Microsoft.Update.Session
    $UpdateSearcher = $UpdateSession.CreateUpdateSearcher()

    Write-Host "Sprawdzam dostepne aktualizacje..."

    $SearchResult = $UpdateSearcher.Search("IsInstalled=0")

    $Count = $SearchResult.Updates.Count

    Write-Host ""
    Write-Host "Liczba dostepnych aktualizacji: $Count"

    if ($Count -gt 0) {

        $UpdateList = @()

        foreach ($Update in $SearchResult.Updates) {

            Write-Host "- $($Update.Title)"

            $UpdateList += $Update.Title
        }

        $Body = @{
            host = $env:COMPUTERNAME
            date = (Get-Date -Format "yyyy-MM-dd HH:mm:ss")
            updatesCount = $Count
            updates = $UpdateList
        }

        $JsonBody = $Body | ConvertTo-Json -Depth 5

        Write-Host ""
        Write-Host "Wysylam dane do n8n..."

        Invoke-RestMethod `
            -Uri $WebhookUrl `
            -Method POST `
            -ContentType "application/json" `
            -Body $JsonBody

        Write-Host "Dane wyslane do n8n."

    }
    else {

        Write-Host ""
        Write-Host "Brak aktualizacji - nic nie wysylam do n8n."

    }

}
catch {

    Write-Host ""
    Write-Host "BLAD:"
    Write-Host $_.Exception.Message

    exit 1
}

Write-Host ""
Write-Host "=== KONIEC ==="