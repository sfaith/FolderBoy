# ============================================================
#  PRESETS — edit these to match your library paths
# ============================================================
$Presets = [ordered]@{
    '1' = @{
        Label = 'Music'
        Exts  = @('.mp3','.flac','.wav','.aac','.ogg','.wma',
                  '.m4a','.alac','.aiff','.ape','.opus',
                  '.dsd','.dsf','.dff')
        Paths = @(
            'M:\',
            '\\DiskStation\music'
        )
    }
    '2' = @{
        Label = 'Movies'
        Exts  = @('.mkv','.mp4','.avi','.m4v','.mov','.wmv',
                  '.ts','.iso','.m2ts')
        Paths = @(
            '\\DiskStation\video\Movies'
        )
    }
    '3' = @{
        Label = 'TV'
        Exts  = @('.mkv','.mp4','.avi','.m4v','.mov','.wmv',
                  '.ts','.iso','.m2ts')
        Paths = @(
            '\\DiskStation\video\TV'
        )
    }
    '4' = @{
        Label = 'Custom'
        Exts  = @()
        Paths = @()
    }
}

$PathPad = 80

# ============================================================
#  FUNCTIONS
# ============================================================
function Select-Path ($MediaType) {
    $paths = $MediaType.Paths
    Write-Host ""
    Write-Host "  Select path to scan:" -ForegroundColor Cyan
    Write-Host ""

    $i = 1
    foreach ($p in $paths) {
        Write-Host ("    {0}) {1}" -f $i, $p)
        $i++
    }
    Write-Host ("    {0}) Enter a custom path" -f $i)
    Write-Host ""

    do {
        $choice = Read-Host "  Choice"
        $idx    = 0
        $valid  = [int]::TryParse($choice, [ref]$idx) -and $idx -ge 1 -and $idx -le $i
    } until ($valid)

    if ($idx -eq $i) {
        $custom = Read-Host "  Enter path"
        return $custom.Trim()
    } else {
        return $paths[$idx - 1]
    }
}

# ============================================================
#  PROMPTS
# ============================================================
Write-Host ""
Write-Host "  ============================================" -ForegroundColor Cyan
Write-Host "   FolderBoy - Media Folder Cleaner -- Live Delete" -ForegroundColor Cyan
Write-Host "  ============================================" -ForegroundColor Cyan
Write-Host ""

# Media type
Write-Host "  Select media type to scan for:" -ForegroundColor Cyan
Write-Host ""
foreach ($key in $Presets.Keys) {
    Write-Host ("    {0}) {1}" -f $key, $Presets[$key].Label)
}
Write-Host ""

do {
    $Choice = Read-Host "  Choice"
} until ($Presets.Contains($Choice))

$MediaType = $Presets[$Choice]

# Extensions
if ($Choice -eq '4') {
    $CustomInput = Read-Host "  Enter extensions comma-separated (e.g. mp3,flac,wav)"
    $MediaExts   = $CustomInput -split ',' | ForEach-Object {
        $e = $_.Trim().ToLower()
        if ($e -notmatch '^\.' ) { ".$e" } else { $e }
    }
    $Label = 'Custom'
} else {
    $MediaExts = $MediaType.Exts
    $Label     = $MediaType.Label
}

# Path
$Root = Select-Path $MediaType

if (-not (Test-Path -LiteralPath $Root)) {
    Write-Host "  Path not found: $Root" -ForegroundColor Red
    exit
}

Write-Host ""
Write-Host ("  Scanning    : {0}" -f $Root)                  -ForegroundColor Yellow
Write-Host ("  Media type  : {0}" -f $Label)                  -ForegroundColor Yellow
Write-Host ("  Looking for : {0}" -f ($MediaExts -join ', ')) -ForegroundColor Yellow
Write-Host ""

# Confirmation
Write-Host "  WARNING: This will permanently delete folders." -ForegroundColor Red
$Confirm = Read-Host "  Type YES to proceed"
if ($Confirm -ne 'YES') {
    Write-Host "  Aborted.`n" -ForegroundColor Yellow
    exit
}

$LogFile = Join-Path $PSScriptRoot "cleanup_log.txt"
"Cleanup run: $(Get-Date)"           | Out-File $LogFile -Encoding utf8
"Root: $Root  |  Media type: $Label" | Out-File $LogFile -Append -Encoding utf8

# ============================================================
#  MAIN
# ============================================================
Write-Host ""
Write-Host "Deleting folders with no $Label files..." -ForegroundColor Cyan
Write-Host ("=" * 60)

$deleted    = [System.Collections.Generic.List[string]]::new()
$failed     = [System.Collections.Generic.List[string]]::new()
$totalBytes = [long]0
$extTally   = @{}

$allFolders = Get-ChildItem -Path $Root -Recurse -ErrorAction SilentlyContinue |
              Where-Object { $_.PSIsContainer } |
              Sort-Object { $_.FullName.Length } -Descending

foreach ($folder in $allFolders) {
    if (-not (Test-Path -LiteralPath $folder.FullName)) { continue }

    $hasMedia = Get-ChildItem -LiteralPath $folder.FullName -Recurse -ErrorAction SilentlyContinue |
                Where-Object { -not $_.PSIsContainer -and $MediaExts -contains $_.Extension.ToLower() } |
                Select-Object -First 1

    if (-not $hasMedia) {
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
