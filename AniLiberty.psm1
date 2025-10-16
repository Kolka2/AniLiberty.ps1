function Search-AniLiberty {

<#
.SYNOPSIS
    Searches for a specified title on AniLiberty.top

.DESCRIPTION
    Queries the AniLiberty API for the specified title.
    The request includes only the following fields: id,
    name.main and name.english.

.PARAMETER Title
    The title to search for.
    Notes: Exact or partial matches are accepted.

.EXAMPLE

    ```powershell
    Search-AniLiberty -Title "91 days"
    ```

.INPUTS
    System.String

.OUTPUTS
    PSCustomObject
    Each object contains at least the following properties:
      - ReleaseId   : System.String
      - Name (Rus)  : System.String
      - Name (Eng)  : System.String

.NOTES
    Author: qfian
    Version: 0.1
    LastModified: 2025-10-16
#>

    [Alias('sat')]
    param (
        [Parameter(Mandatory)]
        [string]$Title
    )

    $IncludeFields = @('id', 'name.main', 'name.english') -Join ','

    $params = @{
        Uri  = 'https://anilibria.top/api/v1/app/search/releases'
        Body = @{
            query   = $Title
            include = $IncludeFields
        }
        TimeOutSec  = 10
    }
    if ($PSVersionTable.PSVersion.Major -ge 6) {
        $params['MaximumRetryCount'] = 3
    }

    $response = Invoke-RestMethod @params

    $response | 
        ForEach-Object {
            [PSCustomObject]@{
              [String]'ReleaseId'  = $_.id
              [String]'Name (Rus)' = $_.name.main
              [String]'Name (Eng)' = $_.name.english
            }
        } 
}

function Get-AniLibertyTorrent {

<#
.SYNOPSIS
    Retrieves a torrent (or opens its magnet link) for a specified AniLiberty release.

.DESCRIPTION
    Calls the AniLiberty API to get torrent entries for a given release ID and
    selects a single torrent according to codec preference. By default the function
    attempts to download the torrent file; with -OpenMagnetLink it opens the magnet
    link instead. The API request asks for the following fields:
    id, codec.label, release.name.main, filename, magnet.

.PARAMETER ReleaseId
    The AniLiberty release identifier to query.
    ValueFromPipelineByPropertyName: True

.PARAMETER PreferHEVC
    If specified, prefer torrents with HEVC codec. If no HEVC torrent is found,
    an x264 torrent will be used as a fallback.
    Type: SwitchParameter
    Default: $false

.PARAMETER OpenMagnetLink
    If specified, opens the selected torrent's magnet link using Start-Process. 
    Otherwise the function downloads the .torrent file to the current directory
    Type: SwitchParameter
    Default: $false

.EXAMPLE

    Downloads torrent file for release 9122 to the current directory.

    ```powershell
    Get-AniLibertyTorrent -ReleaseId "9122"
    ```

.EXAMPLE

    Prefers HEVC torrents and opens the magnet link for the selected torrent.

    ```powershell
    Get-AniLibertyTorrent -ReleaseId "9964" -PreferHEVC -OpenMagnetLink
    ```powershell

.EXAMPLE

    Searches AniLiberty for "Kyoushitsu", selects the 4th result (index 3),
    and requests the preferred HEVC torrent for that release. Downloads the
    torrent file unless -OpenMagnetLink is specified.

    ```powershell
    Search-AniLiberty "Kyoushitsu" | Select-Object -Index 3 | Get-AniLibertyTorrent -PreferHEVC
    ```

.INPUTS
    System.String (ReleaseId via pipeline by property name)

.OUTPUTS
    None

.NOTES
    Author: qfian
    Version: 0.1
    LastModified: 2025-10-16
#>

    [Alias('gat')]
    [CmdletBinding()]
    param (
        [Parameter(Mandatory,
                   ValueFromPipelineByPropertyName)]
        [string]$ReleaseId,
        [switch]$PreferHEVC,
        [switch]$OpenMagnetLink
    )

    begin {
        $baseUri = "https://anilibria.top/api/v1/anime/torrents"
    }

    process {
        $params = @{
            Uri  = "$baseUri/release/$ReleaseId"
            Body = @{
                include   = 'id,codec.label,release.name.main,filename,magnet'
            }
            TimeOutSec  = 10
        }
        if ($PSVersionTable.PSVersion.Major -ge 6) {
            $params['MaximumRetryCount'] = 3
        }

        Write-Verbose "
            Variables
            ---------
            PSVersion:         $($PSVersionTable.PSVersion.ToString())
            ReleaseId:         $ReleaseId
            PreferHEVC:        $PreferHEVC
            OpenMagnetLink:    $OpenMagnetLink
            Uri:               $($params.Uri)
            Body:              $($params.Body | ConvertTo-Json -Compress)
            TimeOutSec:        $($params.TimeOutSec)
            MaximumRetryCount: $(if ($params.MaximumRetryCount) { $params.MaximumRetryCount} else { 'N/A' })
        "

        Write-Verbose "Invoking RestMethod..."
        try {
            $response = Invoke-RestMethod @params
        } catch {
            Write-Verbose "Error. Exception occured during the Invoke-RestMethod."
        }

        Write-Verbose ($response | Out-String)
        $torrent = if ($PreferHEVC) {
            $response | Where-Object { $_.codec.label -eq 'HEVC' }
        } else {
            $response | Where-Object { $_.codec.label -eq 'AVC' }
        }

        if ($PreferHEVC -and -not $torrent) {
            $torrent = $response | Where-Object { $_.codec.label -eq 'AVC' }
        }

        Write-Verbose "
        Filtered torrent Ids
        --------------------
        $($torrent | Out-String)
        "

        # TODO: Add validation
        if ($OpenMagnetLink) {
            Write-Host "Opening Magnet Link for $($torrent.release.name.main)..."
            Start-Process $torrent.magnet
        } else {
            Write-Host "Downloading torrent file for $($torrent.release.name.main)..."

            if ($PSVersionTable.PSVersion.Major -lt 6) {
                $filePath = $torrent.filename -replace '[\[\]]', ''
            } else {
                $filePath = $torrent.filename
            }

            Invoke-WebRequest -Uri "$baseUri/$($torrent.id)/file" -OutFile $filePath
        }
    }
}
