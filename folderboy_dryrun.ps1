# ============================================================
#  CONFIG
# ============================================================
$Root      = "M:\"
$MusicExts = @('.mp3','.flac','.wav','.aac','.ogg','.wma',
               '.m4a','.alac','.aiff','.ape','.opus',
               '.dsd','.dsf','.dff')
$PathPad   = 80   # adjust to suit your typical path length

# ============================================================
#  MAIN
# ============================================================
Write-Host "`nDry run -- folders that WOULD be deleted:" -ForegroundColor Cyan
Write-Host ("=" * 60)

$toDelete   = [System.Collections.Generic.List[string]]::new()
$totalBytes = [long]0
$extTally   = @{}

# Get all folders, deepest first
$allFolders = Get-ChildItem -Path $Root -Recurse -ErrorAction SilentlyContinue |
              Where-Object { $_.PSIsContainer } |
              Sort-Object { $_.FullName.Length } -Descending

foreach ($folder in $allFolders) {
    $hasMusic = Get-ChildItem -LiteralPath $folder.FullName -Recurse -ErrorAction SilentlyContinue |
                Where-Object { -not $_.PSIsContainer -and $MusicExts -contains $_.Extension.ToLower() } |
                Select-Object -First 1

    if (-not $hasMusic) {
        $files = Get-ChildItem -LiteralPath $folder.FullName -Recurse -ErrorAction SilentlyContinue |
                 Where-Object { -not $_.PSIsContainer }

        $sizeBytes = ($files | Measure-Object -Property Length -Sum).Sum
        $sizeBytes = if ($sizeBytes) { [long]$sizeBytes } else { [long]0 }
        $sizeMB    = [math]::Round($sizeBytes / 1MB, 1)

        Write-Host ("[WOULD DELETE] {0}  ({1} MB)" -f $folder.FullName.PadRight($PathPad), $sizeMB)

        foreach ($file in $files) {
            $ext = if ($file.Extension) { $file.Extension.ToLower() } else { '(no extension)' }
            if (-not $extTally[$ext]) { $extTally[$ext] = @{ Count = 0; Bytes = [long]0 } }
            $extTally[$ext].Count++
            $extTally[$ext].Bytes += $file.Length
        }

        $toDelete.Add($folder.FullName)
        $totalBytes += $sizeBytes
    }
}

$totalMB = [math]::Round($totalBytes / 1MB, 1)
$totalGB = [math]::Round($totalBytes / 1GB, 2)

Write-Host ("=" * 60)
Write-Host ("  Folders that would be deleted : {0}"              -f $toDelete.Count)    -ForegroundColor Yellow
Write-Host ("  Total reclaimable space       : {0} GB  ({1} MB)" -f $totalGB, $totalMB) -ForegroundColor Yellow

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
Write-Host "Done. No changes were made.`n" -ForegroundColor Green
