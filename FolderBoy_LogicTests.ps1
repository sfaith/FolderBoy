# FolderBoy logic unit tests -- run standalone, no config required
# Tests all pure functions extracted from FolderBoy.ps1

# ── Pure logic copied from FolderBoy.ps1 ─────────────────────────────────────

function Get-CleanTitle ([string]$Title) {
    $clean = $Title -replace ':', ' -'
    $clean = $clean -replace '[\\/<>"\|\?\*]', ''
    $clean = $clean -replace '\s+', ' '
    return $clean.Trim()
}

function Get-RadarrCleanTitle ([string]$Title) {
    $clean = $Title -replace '[:\/<>"\|\?\*]', ''
    $clean = $clean -replace '\s+', ' '
    return $clean.Trim()
}

function Get-LidarrCleanArtistName ([string]$Name) {
    $clean = $Name -replace ':', ' -'
    $clean = $clean -replace '[\\/<>"\|\?\*]', ''
    $clean = $clean -replace '\s+', ' '
    $clean = $clean.Trim()
    $clean = $clean.TrimEnd('.')
    return $clean
}

function Normalize ([string]$s) {
    return ($s.ToLower() -replace '[^a-z0-9]', '')
}

function Normalize-Path ([string]$p) {
    return $p.ToLower().TrimEnd('\','/') -replace '/', '\'
}

function Get-TargetFolderName ([string]$Title, [int]$Year, [string]$ImdbId) {
    $clean = Get-CleanTitle $Title
    if ($Year -gt 0 -and $clean -notmatch '\(\d{4}\)\s*$') {
        return '{0} ({1}) {{imdb-{2}}}' -f $clean, $Year, $ImdbId
    } else {
        return '{0} {{imdb-{1}}}' -f $clean, $ImdbId
    }
}

function Get-RadarrTargetFolderName ([string]$Title, [int]$Year, [string]$ImdbId, [bool]$UsePlex) {
    $clean = Get-RadarrCleanTitle $Title
    if ($UsePlex -and $ImdbId) {
        return '{0} ({1}) {{imdb-{2}}}' -f $clean, $Year, $ImdbId
    } else {
        return '{0} ({1})' -f $clean, $Year
    }
}

function Test-TitleMatch ([string]$FolderName, [string]$SonarrTitle, [int]$Year = 0) {
    $folderBase         = ($FolderName -replace '\{[^}]+\}', '' -replace '\s+', ' ').Trim()
    $normFolder         = Normalize $folderBase
    $clean              = Get-CleanTitle $SonarrTitle
    $normSonarr         = Normalize $clean
    $cleanNoYear        = $clean -replace '\s*\(\d{4}\)\s*$', ''
    $normSonarrNoYear   = Normalize $cleanNoYear
    $normSonarrWithYear = if ($Year -gt 0) { Normalize "$cleanNoYear ($Year)" } else { '' }
    return ($normFolder -eq $normSonarr) -or
           ($normFolder -eq $normSonarrNoYear) -or
           ($normSonarrWithYear -and $normFolder -eq $normSonarrWithYear)
}

function Format-Bytes ([long]$Bytes) {
    if ($Bytes -ge 1GB) { return ('{0:N2} GB' -f ($Bytes / 1GB)) }
    if ($Bytes -ge 1MB) { return ('{0:N1} MB' -f ($Bytes / 1MB)) }
    return ('{0} B' -f $Bytes)
}

function Test-LidarrAlreadyCorrect ([string]$FolderName, [string]$ArtistName) {
    $newFolderName = Get-LidarrCleanArtistName $ArtistName
    if ($FolderName -eq $newFolderName)             { return $true }
    if ($FolderName.TrimEnd('.') -eq $newFolderName) { return $true }
    return $false
}

# ── Test harness ──────────────────────────────────────────────────────────────
$pass = 0; $fail = 0
$results = [System.Collections.Generic.List[psobject]]::new()

function T ([string]$ID, [string]$Desc, $Got, $Expected) {
    if ($Got -eq $Expected) {
        $script:pass++
        $script:results.Add([pscustomobject]@{ Result='PASS'; ID=$ID; Desc=$Desc })
    } else {
        $script:fail++
        $script:results.Add([pscustomobject]@{ Result='FAIL'; ID=$ID; Desc=$Desc; Got="$Got"; Expected="$Expected" })
    }
}

# ── Normalize ─────────────────────────────────────────────────────────────────
T 'N1'  'Normalize strips non-alphanumeric' (Normalize 'The Wire (2002)') 'thewire2002'
T 'N2'  'Normalize is lowercase'            (Normalize 'BREAKING BAD')    'breakingbad'
T 'N3'  'Normalize empty string'            (Normalize '')                ''

# ── Normalize-Path ────────────────────────────────────────────────────────────
T 'NP1' 'Normalize-Path trims trailing backslash' (Normalize-Path 'C:\Media\TV\')  'c:\media\tv'
T 'NP2' 'Normalize-Path trims trailing slash'     (Normalize-Path 'C:\Media\TV/')  'c:\media\tv'
T 'NP3' 'Normalize-Path converts forward slash'   (Normalize-Path 'C:/Media/TV')   'c:\media\tv'

# ── Get-CleanTitle (Sonarr) ───────────────────────────────────────────────────
T 'CT1' 'Sonarr colon becomes space-dash'   (Get-CleanTitle 'House: M.D.')  'House - M.D.'
T 'CT2' 'Sonarr forward slash removed'      (Get-CleanTitle 'A/B')          'AB'
T 'CT3' 'Sonarr question mark removed'      (Get-CleanTitle 'What?')        'What'
T 'CT4' 'Sonarr multiple spaces collapsed'  (Get-CleanTitle 'The  Wire')    'The Wire'
T 'CT5' 'Sonarr normal title unchanged'     (Get-CleanTitle 'The Wire')     'The Wire'
T 'CT6' 'Sonarr asterisk removed'           (Get-CleanTitle 'Mr. *')        'Mr.'

# ── Get-RadarrCleanTitle ──────────────────────────────────────────────────────
T 'RC1' 'Radarr colon removed entirely'     (Get-RadarrCleanTitle '3:10 to Yuma')    '310 to Yuma'
T 'RC2' 'Radarr slash removed'              (Get-RadarrCleanTitle 'A/B')             'AB'
T 'RC3' 'Radarr question mark removed'      (Get-RadarrCleanTitle 'What?')           'What'
T 'RC4' 'Radarr normal title unchanged'     (Get-RadarrCleanTitle 'The Dark Knight') 'The Dark Knight'
T 'RC5' 'Radarr multiple spaces collapsed'  (Get-RadarrCleanTitle 'A  B')            'A B'

# ── Get-LidarrCleanArtistName ─────────────────────────────────────────────────
T 'LA1' 'Lidarr T.I. trailing period stripped'      (Get-LidarrCleanArtistName 'T.I.')         'T.I'
T 'LA2' 'Lidarr Dinosaur Jr. trailing period'        (Get-LidarrCleanArtistName 'Dinosaur Jr.') 'Dinosaur Jr'
T 'LA3' 'Lidarr Louis C.K. trailing period'          (Get-LidarrCleanArtistName 'Louis C.K.')   'Louis C.K'
T 'LA4' 'Lidarr Run-D.M.C no trailing period'        (Get-LidarrCleanArtistName 'Run-D.M.C')    'Run-D.M.C'
T 'LA5' 'Lidarr colon becomes space-dash'            (Get-LidarrCleanArtistName 'A: B')          'A - B'
T 'LA6' 'Lidarr normal name unchanged'               (Get-LidarrCleanArtistName 'The Beatles')   'The Beatles'

# ── Get-TargetFolderName (Sonarr) ─────────────────────────────────────────────
T 'TF1' 'Sonarr standard title+year'               (Get-TargetFolderName 'The Wire' 2002 'tt0306414')                  'The Wire (2002) {imdb-tt0306414}'
T 'TF2' 'Sonarr year 0 -> no year appended'        (Get-TargetFolderName 'Some Show' 0 'tt1234567')                    'Some Show {imdb-tt1234567}'
T 'TF3' 'Sonarr title already has year, no double' (Get-TargetFolderName 'The Twilight Zone (1985)' 1985 'tt0088634')  'The Twilight Zone (1985) {imdb-tt0088634}'
T 'TF4' 'Sonarr Battlestar no double-year'         (Get-TargetFolderName 'Battlestar Galactica (2003)' 2003 'tt0340987') 'Battlestar Galactica (2003) {imdb-tt0340987}'
T 'TF5' 'Sonarr colon sanitized in target'         (Get-TargetFolderName 'House: M.D.' 2004 'tt0412142')               'House - M.D. (2004) {imdb-tt0412142}'

# ── Get-RadarrTargetFolderName ────────────────────────────────────────────────
T 'RT1' 'Radarr minimum format'           (Get-RadarrTargetFolderName 'The Dark Knight' 2008 'tt0468569' $false) 'The Dark Knight (2008)'
T 'RT2' 'Radarr Plex format with ImdbId'  (Get-RadarrTargetFolderName 'The Dark Knight' 2008 'tt0468569' $true)  'The Dark Knight (2008) {imdb-tt0468569}'
T 'RT3' 'Radarr Plex no ImdbId -> min'   (Get-RadarrTargetFolderName 'Some Movie' 2020 '' $true)                'Some Movie (2020)'
T 'RT4' 'Radarr colon stripped in title' (Get-RadarrTargetFolderName '3:10 to Yuma' 2007 'tt0381849' $false)    '310 to Yuma (2007)'

# ── Test-TitleMatch ───────────────────────────────────────────────────────────
# Without $Year: folder with year vs Sonarr title without year does NOT match
T 'TM1' 'TitleMatch: no Year param, year-in-folder -> no match'  (Test-TitleMatch 'The Wire (2002)' 'The Wire')           $false
# With $Year: Sonarr title + year reconstructed for comparison
T 'TM2' 'TitleMatch: Year param, folder year matches'            (Test-TitleMatch 'The Wire (2002)' 'The Wire' 2002)      $true
T 'TM3' 'TitleMatch: Year param, ID tag stripped then matches'   (Test-TitleMatch 'The Wire (2002) {imdb-tt0306414}' 'The Wire' 2002) $true
T 'TM4' 'TitleMatch: disambiguation year in both -> direct match' (Test-TitleMatch 'Battlestar Galactica (2003)' 'Battlestar Galactica (2003)') $true
T 'TM5' 'TitleMatch: different title does not match'             (Test-TitleMatch 'Breaking Bad' 'The Wire')              $false
T 'TM6' 'TitleMatch: colon in Sonarr, dash+year with Year param' (Test-TitleMatch 'House - M.D. (2004)' 'House: M.D.' 2004) $true
T 'TM7' 'TitleMatch: plain folder, Sonarr has disambig year'    (Test-TitleMatch 'The Twilight Zone' 'The Twilight Zone (1985)') $true
T 'TM8' 'TitleMatch: wrong year does not match'                  (Test-TitleMatch 'The Wire (2003)' 'The Wire' 2002)      $false

# ── Format-Bytes ──────────────────────────────────────────────────────────────
T 'FB1' 'Format-Bytes: raw bytes'  (Format-Bytes 500)  '500 B'
T 'FB2' 'Format-Bytes: megabytes'  (Format-Bytes 15MB) '15.0 MB'
T 'FB3' 'Format-Bytes: gigabytes'  (Format-Bytes 2GB)  '2.00 GB'
T 'FB4' 'Format-Bytes: zero'       (Format-Bytes 0)    '0 B'

# ── Lidarr already-correct logic (checklist 6.3/6.4) ─────────────────────────
T 'LC1' 'T.I. on disk (trailing period) -> already correct'    (Test-LidarrAlreadyCorrect 'T.I.'        'T.I.')         $true
T 'LC2' 'T.I on disk (no trailing period) -> already correct'  (Test-LidarrAlreadyCorrect 'T.I'         'T.I.')         $true
T 'LC3' 'Dinosaur Jr. on disk -> already correct'              (Test-LidarrAlreadyCorrect 'Dinosaur Jr.' 'Dinosaur Jr.') $true
T 'LC4' 'Dinosaur Jr on disk -> already correct'               (Test-LidarrAlreadyCorrect 'Dinosaur Jr'  'Dinosaur Jr.') $true
T 'LC5' 'Completely different name -> not correct'             (Test-LidarrAlreadyCorrect 'TI'           'T.I.')         $false
T 'LC6' 'Louis C.K. on disk -> already correct'               (Test-LidarrAlreadyCorrect 'Louis C.K.'   'Louis C.K.')   $true
T 'LC7' 'Run-D.M.C on disk -> already correct'                (Test-LidarrAlreadyCorrect 'Run-D.M.C'    'Run-D.M.C')    $true

# ── Orphan Scanner single-item @() fix (checklist 7.5) ───────────────────────
$oneItem = [System.Collections.Generic.List[hashtable]]::new()
$oneItem.Add(@{ Path = 'C:\Test\Orphan'; App = 'Radarr'; Size = '1.0 GB'; Bytes = [long]1073741824 })
$sorted1 = @($oneItem | Sort-Object { $_.Path })
T 'OS1' 'Single-item sort in @() -> Count=1' $sorted1.Count 1

$twoItems = [System.Collections.Generic.List[hashtable]]::new()
$twoItems.Add(@{ Path = 'C:\Test\A'; App = 'Radarr'; Size = '1 GB'; Bytes = [long]1GB })
$twoItems.Add(@{ Path = 'C:\Test\B'; App = 'Sonarr'; Size = '2 GB'; Bytes = [long]2GB })
$sorted2 = @($twoItems | Sort-Object { $_.Path })
T 'OS2' 'Two-item sort in @() -> Count=2' $sorted2.Count 2

# ── Log file prefixes (checklist 9.2) ─────────────────────────────────────────
$src = Get-Content 'D:\GitHub\FolderBoy\FolderBoy.ps1' -Raw
T 'LF1' "Cleaner uses Start-Log 'FolderBoy'"              ($src -match "Start-Log 'FolderBoy'")              $true
T 'LF2' "Sonarr renamer uses Start-Log 'FolderBoy_SonarrRenamer'" ($src -match "Start-Log 'FolderBoy_SonarrRenamer'") $true
T 'LF3' "Radarr renamer uses Start-Log 'FolderBoy_RadarrRenamer'" ($src -match "Start-Log 'FolderBoy_RadarrRenamer'") $true
T 'LF4' "Lidarr renamer uses Start-Log 'FolderBoy_LidarrRenamer'" ($src -match "Start-Log 'FolderBoy_LidarrRenamer'") $true
T 'LF5' "Scanner uses Start-Log 'FolderBoy_Scanner'"     ($src -match "Start-Log 'FolderBoy_Scanner'")      $true
T 'LF6' 'Logs\ subdir used in Start-Log'                 ($src -match [regex]::Escape("Join-Path `$PSScriptRoot 'Logs'")) $true

# ── Code-level feature presence checks ───────────────────────────────────────
T 'CF1'  'SuppressMissing defaulted in Sonarr block'     ($src -match 'SonarrConfig\.SuppressMissing')      $true
T 'CF2'  'SuppressMissing defaulted in Radarr block'     ($src -match 'RadarrConfig\.SuppressMissing')      $true
T 'CF3'  'SuppressMissing defaulted in Lidarr block'     ($src -match 'LidarrConfig\.SuppressMissing')      $true
T 'CF4'  'Confirm-LiveAction defined'                    ($src -match 'function Confirm-LiveAction')         $true
T 'CF5'  'Rollback logic present in Sonarr renamer'      ($src -match 'Rollback successful')                 $true
T 'CF6'  'Orphan Scanner Scope param present'            ($src -match '\[string\]\$Scope')                   $true
T 'CF7'  'Dashboard orphan count updated after scan'     ($src -match 'DashboardCache\[')                    $true
T 'CF8'  'All Libraries Cleaner mode present'            ($src -match 'All libraries')                       $true
T 'CF9'  'Invoke-CleanerScan helper defined'             ($src -match 'function Invoke-CleanerScan')         $true
T 'CF10' 'Scope label shown in scanner header'           ($src -match 'scopeLabel')                          $true
T 'CF11' 'Scan+Delete banner present'                    ($src -match 'SCAN \+ DELETE MODE')                 $true
T 'CF12' '@() wrapping on candidates Sort-Object'        ($src -match '@\(\$candidates \| Sort-Object')      $true
T 'CF13' 'Full Run Lidarr renamer included'              ($src -match 'Invoke-LidarrFolderRenamer')          $true
T 'CF14' 'Resolve-ArrPaths fetches from rootfolder API' ($src -match "Invoke-ArrGet .+ 'rootfolder'")        $true
T 'CF15' 'Disabled app shown in dashboard as Disabled'   ($src -match '"    {0,-8}  Disabled"')              $true
T 'CF16' 'Session log Add-SessionEntry defined'          ($src -match 'function Add-SessionEntry')           $true
T 'CF17' 'No stray SonarrTagger references'              ($src -notmatch 'SonarrTagger')                     $true
T 'CF18' 'No stray Invoke-SonarrGet references'         ($src -notmatch 'Invoke-SonarrGet')                  $true
T 'CF19' 'No stray FolderBoy_Tagger log prefix'         ($src -notmatch "Start-Log 'FolderBoy_Tagger'")     $true
T 'CF20' 'No stray Sonarr Folder Tagger menu text'      ($src -notmatch 'Sonarr Folder Tagger')              $true

# ── Print results ─────────────────────────────────────────────────────────────
Write-Host ''
Write-Host '  ─────────────────────────────────────────────────────────────────' -ForegroundColor Cyan
$results | ForEach-Object {
    if ($_.Result -eq 'PASS') {
        Write-Host ("  PASS  {0,-5}  {1}" -f $_.ID, $_.Desc) -ForegroundColor Green
    } else {
        Write-Host ("  FAIL  {0,-5}  {1}" -f $_.ID, $_.Desc) -ForegroundColor Red
        Write-Host ("         got:      [{0}]"  -f $_.Got)     -ForegroundColor Yellow
        Write-Host ("         expected: [{0}]"  -f $_.Expected) -ForegroundColor Yellow
    }
}
Write-Host '  ─────────────────────────────────────────────────────────────────' -ForegroundColor Cyan
$color = if ($fail -gt 0) { 'Red' } else { 'Green' }
Write-Host ("  {0} passed   {1} failed" -f $pass, $fail) -ForegroundColor $color
Write-Host ''
