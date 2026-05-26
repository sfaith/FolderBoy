# ================================================================
#  FolderBoy.config.example.ps1  |  Configuration Template  |  v0.6.3
#
#  Copy this file to FolderBoy.config.ps1 and fill in your
#  own values before running FolderBoy for the first time.
#
#  FolderBoy.config.ps1 is excluded from source control via
#  .gitignore so your API keys and paths stay private.
#
#  See README.md for full configuration documentation.
# ================================================================

# ----------------------------------------------------------------
#  RADARR
#
#  Enabled  : $true to use Radarr features, $false to skip.
#  BaseUrl  : URL you use to access Radarr in a browser.
#             Use http://localhost:7878 if running on the same machine.
#             Use http://HOSTNAME:7878 or http://IP:7878 for remote.
#  ApiKey   : Settings > General > Security > API Key in Radarr.
#  Paths    : Optional. If omitted or empty, FolderBoy fetches root
#             folders from the Radarr API automatically. Define
#             manually only if you want to override or limit scope.
#
#  TRASH GUIDES -- Radarr Movie Folder Format:
#    Minimum:  {Movie CleanTitle} ({Release Year})
#    Plex:     {Movie CleanTitle} ({Release Year}) {imdb-{ImdbId}}
#    https://trash-guides.info/Radarr/Radarr-recommended-naming-scheme/
#
#  NOTE: FolderBoy's Orphan Scanner uses path-based matching for
#  Radarr and does not require ID tags in folder names.
# ----------------------------------------------------------------
$RadarrConfig = @{
    Enabled = $true
    BaseUrl = 'http://localhost:7878'    # CHANGE ME
    ApiKey  = 'YOUR_RADARR_API_KEY'     # CHANGE ME
    # Paths omitted -- FolderBoy will fetch from Radarr API automatically.
    # To override, uncomment and edit:
    # Paths = @(
    #     '\\YOUR-SERVER\Movies'
    #     '\\YOUR-SERVER\Documentaries'
    # )
}

# ----------------------------------------------------------------
#  SONARR
#
#  Enabled  : $true to use Sonarr features, $false to skip.
#  BaseUrl  : URL you use to access Sonarr in a browser.
#  ApiKey   : Settings > General > Security > API Key in Sonarr.
#  Paths    : Optional. If omitted or empty, FolderBoy fetches root
#             folders from the Sonarr API automatically.
#
#  TRASH GUIDES -- Sonarr Series Folder Format (REQUIRED for renamer):
#    {Series TitleYear} {imdb-{ImdbId}}
#    Example: The Wire (2002) {imdb-tt0306414}
#    Set in Sonarr: Settings > Media Management > (show advanced)
#                   > Series Folder Format
#    https://trash-guides.info/Sonarr/Sonarr-recommended-naming-scheme/
# ----------------------------------------------------------------
$SonarrConfig = @{
    Enabled = $true
    BaseUrl = 'http://localhost:8989'    # CHANGE ME
    ApiKey  = 'YOUR_SONARR_API_KEY'     # CHANGE ME
    # Paths omitted -- FolderBoy will fetch from Sonarr API automatically.
    # To override, uncomment and edit:
    # Paths = @(
    #     '\\YOUR-SERVER\Episodes'
    # )
}

# ----------------------------------------------------------------
#  LIDARR
#
#  Enabled  : $true to use Lidarr features, $false to skip.
#  BaseUrl  : URL you use to access Lidarr in a browser.
#  ApiKey   : Settings > General > Security > API Key in Lidarr.
#  Paths    : Optional. If omitted or empty, FolderBoy fetches root
#             folders from the Lidarr API automatically.
#
#  TRASH GUIDES -- Lidarr naming:
#    Artist Folder : {Artist Name}
#    Album Folder  : {Album Title} {(Album Disambiguation)}
#    Track Format  : {Album Title} {(Album Disambiguation)}/
#                    {Artist Name}_{Album Title}_{track:00}_{Track Title}
#    https://wiki.servarr.com/lidarr/naming-guide
# ----------------------------------------------------------------
$LidarrConfig = @{
    Enabled         = $true
    BaseUrl         = 'http://localhost:8686'    # CHANGE ME
    ApiKey          = 'YOUR_LIDARR_API_KEY'     # CHANGE ME
    SuppressMissing = $true   # Lidarr libraries often have many monitored-but-not-yet-
                              # downloaded artists. Set to $true to hide [MISSING] lines
                              # in the Lidarr Folder Renamer output. Count still shown
                              # in summary. Set to $false (or omit) to show all entries.
    # Paths omitted -- FolderBoy will fetch from Lidarr API automatically.
    # To override, uncomment and edit:
    # Paths = @(
    #     '\\YOUR-SERVER\Music'
    # )
}

# ----------------------------------------------------------------
#  FOLDERBOY CLEANER PRESETS
#
#  Each preset defines:
#    Label  -- display name shown in the menu
#    Exts   -- file extensions that count as media for this type
#    Paths  -- root folders to scan (array, one path per line)
#
#  The *arr configs above must be defined first so their Paths
#  can be referenced here. If you set explicit Paths in each
#  *arr config above, those are reused directly. If Paths is
#  omitted from a *arr config (API auto-fetch), the reference
#  will be null at config load time -- in that case, set Cleaner
#  paths explicitly below using the commented examples.
#
#  FolderBoy flags any subfolder that contains NO files matching
#  the Exts list. The Custom preset always appears and lets you
#  enter extensions interactively at runtime.
#
#  Add as many presets as you like by adding numbered entries.
# ----------------------------------------------------------------
$FolderBoyPresets = [ordered]@{
    '1' = @{
        Label = 'TV Shows'
        Exts  = @('.mkv','.mp4','.avi','.m4v','.mov','.wmv','.ts','.m2ts','.iso')
        Paths = $SonarrConfig.Paths      # Reuses Sonarr paths if defined above
        # If using API auto-fetch for Sonarr, set explicitly instead:
        # Paths = @('\\YOUR-SERVER\Episodes')
    }
    '2' = @{
        Label = 'Movies'
        Exts  = @('.mkv','.mp4','.avi','.m4v','.mov','.wmv','.ts','.m2ts','.iso',
                  '.mpg','.mpeg')        # .mpg and .mpeg for older content
        Paths = $RadarrConfig.Paths      # Reuses Radarr paths if defined above
        # If using API auto-fetch for Radarr, set explicitly instead:
        # Paths = @('\\YOUR-SERVER\Movies', '\\YOUR-SERVER\Documentaries')
    }
    '3' = @{
        Label = 'Music'
        Exts  = @('.mp3','.flac','.wav','.aac','.ogg','.wma',
                  '.m4a','.alac','.aiff','.ape','.opus','.dsf','.dff','.wv')
        Paths = $LidarrConfig.Paths      # Reuses Lidarr paths if defined above
        # If using API auto-fetch for Lidarr, set explicitly instead:
        # Paths = @('\\YOUR-SERVER\Music')
    }
    '4' = @{
        Label = 'Custom (enter extensions manually)'
        Exts  = @()
        Paths = @()
    }
}

# ----------------------------------------------------------------
#  DISPLAY
#  Path column width in scan output. Increase if paths are long.
# ----------------------------------------------------------------
$PathPad = 80