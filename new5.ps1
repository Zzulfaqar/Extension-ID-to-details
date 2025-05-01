<#  Extension ID --> Details by https://github.com/Zzulfaqar #> 

# ── Edge’s JSON endpoint requires TLS 1.2 (force it once, at start) ──────────
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

function Show-Menu {
    Write-Host ""
    Write-Host "==== Extension Info Menu ===="
    Write-Host "1) Lookup one extension ID"
    Write-Host "2) Lookup multiple IDs (save to TSV)"
    Write-Host "3) Exit"
    Write-Host "4) Help/About"
}

function Show-Help {
    Write-Host ""
    Write-Host "Extension ID detail scraping"
    Write-Host "https://github.com/Zzulfaqar"
    Write-Host "Enter a Chrome or Edge extension ID to retrieve its Details."
    Write-Host "To Exit press 3 and enter or just ctrl+C"
    Write-Host "Press button:"
    Write-Host " 1 : Extract one ID at One Time"
    Write-Host " 2 : Enter IDs one by one, then save all results to a TSV file"
    Write-Host " 3 : Exit the script"
    Write-Host " 4 : Show this help message"
    Write-Host ""
}

# ────────────────────────────────────────────────────────────────────────────
#  Get-ExtensionMeta
#  • Tries Chrome Web Store first (HTML scrape)
#  • Falls back to Edge Add-ons JSON endpoint (fast + clean)
#    and then Edge HTML page as a final fallback
# ────────────────────────────────────────────────────────────────────────────
function Get-ExtensionMeta {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][string]$ID
    )

    $headers = @{ 'User-Agent' = 'Mozilla/5.0' }

    # skeleton object (default “No data”)
    $obj = [PSCustomObject]@{
        ID          = $ID
        Name        = ''
        Description = ''
        Version     = ''
        Source      = 'No data'
    }

    # ── 1) Chrome Web Store ────────────────────────────────────────────────
    try {
        $cUrl  = "https://chrome.google.com/webstore/detail/$ID"
        $cResp = Invoke-WebRequest -Uri $cUrl -Headers $headers -UseBasicParsing -ErrorAction Stop

        if ($cResp.StatusCode -eq 200) {
            $html = $cResp.Content

            if ($html -match '<title>(.*?) - Chrome Web Store</title>') {
                $obj.Name = $matches[1]
            }
            if ($html -match '<meta[^>]*name="description"[^>]*content="([^"]+)"') {
                $obj.Description = $matches[1]
            }
            if ($html -match '<meta[^>]*itemprop="version"[^>]*content="([^"]+)"') {
                $obj.Version = $matches[1]
            }

            if ($obj.Name) {
                $obj.Source = 'Chrome'
                return $obj
            }
        }
    } catch {}

    # ── 2) Edge Add-ons JSON endpoint (quick + reliable) ──────────────────
    try {
        $eUrl  = "https://microsoftedge.microsoft.com/addons/getproductdetailsbycrxid/$ID"
        $eResp = Invoke-WebRequest -Uri $eUrl -Headers $headers -UseBasicParsing -ErrorAction Stop

        if ($eResp.StatusCode -eq 200 -and $eResp.Content.Trim().StartsWith('{')) {
            $j = $eResp.Content | ConvertFrom-Json

            $obj.Name        = $j.name
            $obj.Description = $j.shortDescription
            $obj.Version     = $j.version
            $obj.Source      = 'Edge'
            return $obj
        }
    } catch {}

    # ── 3) Edge Add-ons HTML page (fallback) ───────────────────────────────
    try {
        $eHtmlUrl  = "https://microsoftedge.microsoft.com/addons/detail/$ID"
        $eHtmlResp = Invoke-WebRequest -Uri $eHtmlUrl -Headers $headers -UseBasicParsing -ErrorAction Stop

        if ($eHtmlResp.StatusCode -eq 200) {
            $html = $eHtmlResp.Content
            if ($html -match '<h1[^>]*>(.*?)</h1>') {
                $obj.Name = $matches[1].Trim()
            }
            if ($html -match '"description":"([^"]+)"') {
                $obj.Description = $matches[1]
            }
            if ($html -match '"version":"([^"]+)"') {
                $obj.Version = $matches[1]
            }
            if ($obj.Name) {
                $obj.Source = 'Edge'
                return $obj
            }
        }
    } catch {}

    return $obj   # “No data”
}

# ────────────────────────────────────────────────────────────────────────────
#  Add-ReferenceLink
#  • Appends a “Link” property based on the detected source
#  • Designed to work in the pipeline
# ────────────────────────────────────────────────────────────────────────────
function Add-ReferenceLink {
    [CmdletBinding()]
    param(
        [Parameter(ValueFromPipeline)][psobject]$InputObject
    )
    process {
        $link = switch ($InputObject.Source) {
            'Chrome' { "https://chrome.google.com/webstore/detail/$($InputObject.ID)" }
            'Edge'   { "https://microsoftedge.microsoft.com/addons/detail/$($InputObject.ID)" }
            default  { "N/A" }
        }
        Add-Member -InputObject $InputObject -NotePropertyName Link -NotePropertyValue $link -Force
        $InputObject
    }
}

# ──────────────────────────  Main Menu Loop  ───────────────────────────────
$continue = $true
while ($continue) {
    Show-Menu
    $choice = Read-Host "Enter your choice (1-4)"
    switch ($choice) {
        '1' {
            # ── Single ID lookup ──
            do {
                $extID = Read-Host "Enter extension ID"
            } until ($extID -match '^[a-z0-9]{16,32}$' -or [string]::IsNullOrWhiteSpace($extID))

            if ([string]::IsNullOrWhiteSpace($extID)) {
                Write-Warning "No ID entered."
                break
            }

            $meta = Get-ExtensionMeta -ID $extID | Add-ReferenceLink
            $meta | Format-Table ID,Name,Version,Description,Source,Link -AutoSize
        }
        '2' {
            # ── Batch mode ──
            $ids = @()
            Write-Host "Enter extension IDs one per line (type 'done' when finished):"
            while ($true) {
                $in = Read-Host "ID"
                if ($in -eq 'done') { break }
                if ($in -match '^[a-z0-9]{16,32}$') {
                    $ids += $in
                } else {
                    Write-Warning "Invalid ID format. Use 16-32 lowercase letters/digits."
                }
            }

            if ($ids.Count -eq 0) {
                Write-Warning "No IDs entered."
                break
            }

            $fname = Read-Host "Output file name (default: compile1.tsv)"
            if ([string]::IsNullOrWhiteSpace($fname)) { $fname = "compile1.tsv" }
            if ($fname -notmatch '\.tsv$') { $fname += ".tsv" }

            $results = $ids |
                        ForEach-Object { Get-ExtensionMeta -ID $_ } |
                        Add-ReferenceLink

            $results | Format-Table ID,Name,Version,Description,Source,Link -AutoSize

            $results |
              Select-Object ID,Name,Version,Description,Source,Link |
              Export-Csv -Delimiter "`t" -Path $fname -NoTypeInformation

            Write-Host "Saved metadata for $($results.Count) extensions to '$fname'."
        }
        '3' {
            Write-Host "Exiting."
            $continue = $false
        }
        '4' {
            Show-Help
        }
        default {
            Write-Warning "Invalid selection. Please choose 1-4."
        }
    }
}
