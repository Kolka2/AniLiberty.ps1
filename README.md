# AniLiberty.ps1

PowerShell module that provides non-interactive functions to search anime titles by name on AniLiberty.top and retrieve torrents either with torrent file or magnet link.

## Requirements

- PowerShell 5.1+

## Install

Put `AniLiberty.psm1` and `AniLiberty.psd1` into one of the `$PSModulePath` directories.

For example:

```powershell
New-Item -Type Directory -Path "$HOME\Documents\WindowsPowerShell\Modules\AniLiberty" -Force
Copy-Item -Path 'AniLiberty.psm1', 'AniLiberty.psd1' -Destination "$HOME\Documents\WindowsPowerShell\Modules\AniLiberty" -Force
```

In this case it will work for Windows PowerShell and Powershell 7. Now simply reopen your PowerShell window and the module should be loaded automatically or you can execute `Import-Module AniLiberty` to load the module into current session.

## Functions

- **Search-AniLiberty**
  
  Searches AniLiberty for titles (exact or partial match). Returns objects containing at least `id`, `name.main`, `name.english`. Available alias: `sat`.
  
  ```powershell
  Search-AniLiberty [-Title] <string> [<CommonParameters>]
  ```

- **Get-AniLibertyTorrent**
  
  Retrieves torrent entries for the given release id. By default downloads the .torrent file; with `-OpenMagnetLink` opens the magnet URI. `-PreferHEVC` prefers HEVC codecs with AVC as fallback. Available alias: `gat`.
  
  ```powershell
  Get-AniLibertyTorrent [-ReleaseId] <string> [-PreferHEVC] [-OpenMagnetLink] [<CommonParameters>]
  ```

## Examples

**Example 1**

Let's search for "91 days" anime title. This will output all matching results.

```powershell
Search-AniLiberty -Title "91 days"

# ReleaseId Name (Rus) Name (Eng)
# --------- ---------- ----------
#      2621 91 День    91 Days
```

**Example 2**

Downloads torrent file for release `9122` to the current directory.

```powershell
Get-AniLibertyTorrent -ReleaseId "9122"
```

**Example 3**

Prefers HEVC torrents and opens the magnet link for the selected torrent.

```powershell
Get-AniLibertyTorrent -ReleaseId "9964" -PreferHEVC -OpenMagnetLink
```

**Example 4**

Searches AniLiberty for "Kyoushitsu", selects the 4th result (index 3), and requests the preferred HEVC torrent for that release. Downloads the torrent file unless -OpenMagnetLink is specified.

```powershell
Search-AniLiberty "Kyoushitsu" | Select-Object -Index 3 | Get-AniLibertyTorrent -PreferHEVC
```

## Notes

- If no matches are found, `Search-AniLiberty` returns `null`. `Get-AniLibertyTorrent` may throw if no torrent is selected.
- Use `-Verbose` to see request details and debug output (only for `Get-AniLibertyTorrent`).
