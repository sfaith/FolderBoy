# ============================================================
#  CONFIG
# ============================================================
$Root      = "M:\"
$MusicExts = @('.mp3','.flac','.wav','.aac','.ogg','.wma',
               '.m4a','.alac','.aiff','.ape','.opus',
               '.dsd','.dsf','.dff')
$LogFile   = Join-Path $PSScriptRoot "cleanup_log.txt"
$PathPad   = 80   # adjust to suit your typical path length

# ============================================================
#  MAIN
# ============================================================
"Cleanup run: $(Get-Date)" | Out-File $LogFile -Encoding utf8

Write-Host "`nDeleting folders with no music files..." -ForegroundColor Cyan
Write-Host ("=" * 60)

$deleted    = [System.Collections.Generic.List[string]]::new()
$failed     = [System.Collections.Generic.List[string]]::new()
$totalBytes = [long]0
$extTally   = @{}

# Get all folders, deepest first
$allFolders = Get-ChildItem -Path $Root -Recurse -ErrorAction SilentlyContinue |
              Where-Object { $_.PSIsContainer } |
              Sort-Object { $_.FullName.Length } -Descending

foreach ($folder in $allFolders) {
    if (-not (Test-Path -LiteralPath $folder.FullName)) { continue }

    $hasMusic = Get-ChildItem -LiteralPath $folder.FullName -Recurse -ErrorAction SilentlyContinue |
                Where-Object { -not $_.PSIsContainer -and $MusicExts -contains $_.Extension.ToLower() } |
                Select-Object -First 1

    if (-not $hasMusic) {
        $files = Get-ChildItem -LiteralPath $folder.FullName -Recurse -ErrorAction SilentlyContinue |
                 Where-Object { -not $_.PSIsContainer }

        $sizeBytes = ($files | Measure-Object -Property Length -Sum).Sum
        $sizeBytes = if ($sizeBytes) { [long]$sizeBytes } else { [long]0 }
        $sizeMB    = [math]::Round($sizeBytes / 1MB, 1)

        foreach ($file in $files) {
            $ext = if ($file.Extension) { $file.Extension.ToLower() } else { '(no extension)' }
            if (-not $extTally[$ext]) { $extTally[$ext] = @{ Count = 0; Bytes = [long]0 } }
            $extTally[$ext].Count++
            $extTally[$ext].Bytes += $file.Length
        }

        try {
            Remove-Item -LiteralPath $folder.FullName -Recurse -Force -ErrorAction Stop
            Write-Host ("[DELETED] {0}  ({1} MB)" -f $folder.FullName.PadRight($PathPad), $sizeMB) -ForegroundColor Green
            "[DELETED] $($folder.FullName)  ($sizeMB MB)" | Out-File $LogFile -Append -Encoding utf8
            $deleted.Add($folder.FullName)
            $totalBytes += $sizeBytes
        }
        catch {
            Write-Host ("[FAILED]  {0}  -- $_" -f $folder.FullName.PadRight($PathPad)) -ForegroundColor Red
            "[FAILED]  $($folder.FullName)  -- $_" | Out-File $LogFile -Append -Encoding utf8
            $failed.Add($folder.FullName)
        }
    }
}

$totalMB = [math]::Round($totalBytes / 1MB, 1)
$totalGB = [math]::Round($totalBytes / 1GB, 2)

Write-Host ("=" * 60)
Write-Host ("  Folders deleted               : {0}" -f $deleted.Count) -ForegroundColor Green
Write-Host ("  Folders failed                : {0}" -f $failed.Count)  -ForegroundColor $(if ($failed.Count) { 'Red' } else { 'Green' })
Write-Host ("  Total space reclaimed         : {0} GB  ({1} MB)" -f $totalGB, $totalMB) -ForegroundColor Yellow

Write-Host ""
Write-Host "  File type breakdown:" -ForegroundColor Cyan
Write-Host ("  {0,-20} {1,8}   {2,10}" -f "Extension", "Files", "Size")
Write-Host ("  " + ("-" * 44))

$extTally.GetEnumerator() |
    Sort-Object { $_.Value.Bytes } -Descending |
    ForEach-Object {
        $extMB = [math]::Round($_.Value.Bytes / 1MB, 1)
        Write-Host ("  {0,-20} {1,8}   {2,8} MB" -f $_.Key, $_.Value.Count, $extMB)
    }

Write-Host ("=" * 60)
Write-Host "Done. Log saved to: $LogFile`n" -ForegroundColor Green
