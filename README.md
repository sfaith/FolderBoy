# FolderBoy — Media Library Manager

A PowerShell toolkit for managing [Sonarr](https://sonarr.tv), [Radarr](https://radarr.video), and [Lidarr](https://lidarr.audio) media libraries. FolderBoy helps you keep your library clean by finding orphaned media, tagging Sonarr series folders with IMDb IDs, and removing folders that contain no recognised media files.

---

## Tools

### 1. FolderBoy Cleaner
Scans your media root folders and identifies subfolders that contain no media files matching the configured extensions. Useful for removing leftover empty folders, failed partial downloads, and sample-only folders.

- No \*arr API calls required — purely filesystem-based
- Per-preset file extension lists for TV, Movies, and Music
- Reports non-media file types found in flagged folders
- Dry Run mode shows what would be deleted before committing

### 2. Sonarr Folder Tagger
Finds Sonarr series folders that are missing an `{imdb-ttXXXXXXX}` ID tag, renames them on disk to match the recommended naming format, and updates the series path in Sonarr via API so everything stays in sync.

This is the recommended first step before running the Orphan Scanner — ID-tagged folders are matched with very high confidence.

- Only renames folders that are missing the ID tag
- Detects and skips folders where the name doesn't match the Sonarr title (prevents accidental renames)
- Rolls back disk renames automatically if the Sonarr API update fails
- Dry Run mode previews all renames before applying

### 3. Orphan Scanner
Compares what is on disk against what each \*arr app manages. Produces a categorised report of unrecognised folders, then optionally lets you review and delete them item by item.

**Matching strategy:**

| App | Method |
|---|---|
| Radarr | Direct path comparison against Radarr's `path` field — no ID or name parsing needed |
| Sonarr | IMDb/TVDB ID tag matching for tagged folders; name-based fallback for untagged folders |
| Lidarr | Exact artist name match; fuzzy punctuation-stripped match for near-misses |

**Confidence categories:**

| Category | Meaning |
|---|---|
| NOT IN ARR | ID tag present but ID not found in \*arr library — high confidence orphan |
| NEEDS REVIEW | No ID tag and no name match — medium confidence, verify before deleting |
| NAME MATCHED | No ID tag but name matched — counted as matched, shown for awareness |

The interactive delete flow lets you review each item individually (`D` delete / `S` skip / `Q` quit), queue deletions, see a size summary, and type `YES` to confirm before anything is removed.

### 4. Full Run
Runs the Sonarr Folder Tagger first, then the Orphan Scanner. This is the recommended workflow — tagging first maximises ID coverage and gives the scanner its highest confidence results.

---

## Requirements

- **Windows** with PowerShell 5.1 or later (built into Windows 10, 11, and Server 2016+)
- Network access to each \*arr application's API
- All \*arr apps must be running and reachable at the configured URL

---

## Installation

1. Download `FolderBoy.ps1` and `FolderBoy.bat` to the same folder on your Windows machine (or media server).
2. Edit the `CONFIG` section at the top of `FolderBoy.ps1` — see [Configuration](#configuration) below.
3. Double-click `FolderBoy.bat` to launch, or run directly in PowerShell:

```powershell
.\FolderBoy.ps1
```

If you see an execution policy error, either use the `.bat` launcher (which bypasses it automatically) or run once as administrator:

```powershell
Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope LocalMachine
```

---

## Configuration

All settings are in the `CONFIG` section near the top of `FolderBoy.ps1`. Open the script in any text editor and edit the values described below.

### Enabling / Disabling Apps

Each \*arr app has an `Enabled` flag. Set it to `$false` if you don't use that app:

```powershell
$RadarrConfig = @{
    Enabled = $false   # Set to $true when you're ready to use Radarr features
    ...
}
```

### API Keys

Find your API key in each app under **Settings → General → Security → API Key**.

```powershell
$RadarrConfig = @{
    Enabled = $true
    BaseUrl = 'http://localhost:7878'         # URL you use to access Radarr
    ApiKey  = 'YOUR_RADARR_API_KEY'           # Paste your key here
    Paths   = @('\\SERVER\Movies')            # Your Radarr root folder(s)
}
```

### Paths

`Paths` is an array of root folder paths that each app manages. These must match exactly what is configured in the app under **Settings → Media Management → Root Folders**. You can have multiple paths per app:

```powershell
$RadarrConfig = @{
    ...
    Paths = @(
        '\\NAS\Movies',
        '\\NAS\Documentaries',
        '\\NAS\Comedy'
    )
}
```

Paths can be local (`C:\Media\Movies`) or UNC (`\\SERVER\Movies`).

### FolderBoy Cleaner Presets

Edit the presets to match your library layout. Each preset has a `Label`, a list of file `Exts`, and `Paths` to scan:

```powershell
$FolderBoyPresets = [ordered]@{
    '1' = @{
        Label = 'TV Shows'
        Exts  = @('.mkv', '.mp4', '.avi', '.m4v', '.ts')
        Paths = @('\\NAS\Episodes')
    }
    ...
}
```

---

## Recommended Naming Conventions

FolderBoy works best when your \*arr apps are configured with the naming schemes recommended by [TRaSH Guides](https://trash-guides.info). These formats embed metadata that FolderBoy uses for reliable matching and are considered best practice by the \*arr community.

### Sonarr

Go to **Settings → Media Management → Show Advanced → Series Folder Format**

**Recommended (Plex / IMDb):**
```
{Series TitleYear} {imdb-{ImdbId}}
```
Example: `The Wire (2002) {imdb-tt0306414}`

This is the format that the Sonarr Folder Tagger enforces. Without the `{imdb-{ImdbId}}` token, newly added series will not have ID tags and the Orphan Scanner will fall back to name-based matching for those folders.

> **Note from TRaSH Guides:** Folder names are written to the database when a series is first added. If the IMDb ID is missing in Sonarr at that time, the folder will have a blank ID. Run the Sonarr Folder Tagger after adding the ID to Sonarr to fix this.

**Full guide:** https://trash-guides.info/Sonarr/Sonarr-recommended-naming-scheme/

---

### Radarr

Go to **Settings → Media Management → Show Advanced → Movie Folder Format**

**Minimum recommended:**
```
{Movie CleanTitle} ({Release Year})
```
Example: `The Dark Knight (2008)`

**Optional (Plex with IMDb matching):**
```
{Movie CleanTitle} ({Release Year}) {imdb-{ImdbId}}
```
Example: `The Dark Knight (2008) {imdb-tt0468569}`

> **Note from TRaSH Guides:** Radarr sets the folder name when a movie is first added. If the IMDb ID was missing at that time, the folder will have a blank ID tag. Adding IDs to the *filename* format instead of the folder format avoids this, as filenames are generated fresh on each download.
>
> FolderBoy's Orphan Scanner uses **path-based matching** for Radarr and does not require ID tags in folder names.

**Full guide:** https://trash-guides.info/Radarr/Radarr-recommended-naming-scheme/

---

### Lidarr

Go to **Settings → Media Management → Show Advanced**

**Artist Folder Format (recommended):**
```
{Artist Name}
```
Example: `Pink Floyd`

**Album Folder Format (recommended):**
```
{Album Title} {(Album Disambiguation)}
```
Example: `The Wall` | `Weezer (Blue Album)`

> **Why album disambiguation matters:** Without it, two albums with the same title (e.g. self-titled albums) will write to the same folder and overwrite each other. When there is no disambiguation, Lidarr simply omits the `()` and uses the standard album title.

**Standard Track Format (recommended):**
```
{Album Title} {(Album Disambiguation)}/{Artist Name}_{Album Title}_{track:00}_{Track Title}
```

> **Important:** Enable **Rename Tracks** and **Replace Illegal Characters** in Settings → Media Management *before* you populate your library. Changing naming formats after the library is populated will trigger a full rename of every file the next time Lidarr refreshes each artist — plan accordingly and back up first.

**Full guide:** https://wiki.servarr.com/lidarr/naming-guide

---

## Workflow

The recommended workflow when running FolderBoy for the first time on an existing library:

1. **Run Sonarr Folder Tagger in Dry Run** — review which series folders would be renamed. Look for any title mismatches flagged in the output and rename those folders manually first.

2. **Run Sonarr Folder Tagger in Live Rename** — apply the renames. Sonarr paths are updated automatically via API.

3. **Run Orphan Scanner in Scan Only** — review the results. Investigate any `NEEDS REVIEW` items before deciding to delete.

4. **Run Orphan Scanner in Scan + Delete** — go through each flagged item, skip what you want to keep, queue what you want to delete, and confirm.

5. **Use option 4 (Full Run)** for ongoing maintenance — it runs the tagger and scanner back to back in a single session.

---

## Log Files

Every run saves a timestamped log file to the same folder as `FolderBoy.ps1`:

| Tool | Log filename |
|---|---|
| FolderBoy Cleaner | `FolderBoy_YYYYMMDD_HHMMSS.log` |
| Sonarr Folder Tagger | `FolderBoy_Tagger_YYYYMMDD_HHMMSS.log` |
| Orphan Scanner | `FolderBoy_Scanner_YYYYMMDD_HHMMSS.log` |

Logs contain the full console output including all renamed, deleted, skipped, and failed items.

---

## Troubleshooting

**"Could not reach API" errors**
- Confirm the `BaseUrl` in config matches the URL you use to access the app in a browser.
- Confirm the app is running and accessible from the machine running FolderBoy.
- Double-check the `ApiKey` — copy it fresh from Settings → General in the app.

**"Path not found" warnings**
- Confirm the path exists and is accessible. For UNC paths (`\\SERVER\Share`), make sure the machine running FolderBoy has network access.
- Check for trailing backslashes or typos in the config.

**Sonarr API returns 400 Bad Request**
- This can happen for series with non-ASCII characters in alternate titles. FolderBoy sends the request body as UTF-8 bytes to avoid this — if you see it, please open an issue.

**Title mismatch warnings in the Tagger**
- The folder name and Sonarr's title for that series differ enough that FolderBoy won't rename automatically. Rename the folder manually to match the Sonarr title, then re-run the tagger.

---

## Contributing

Pull requests welcome. If you encounter a matching failure, incorrect deletion candidate, or API error, please open an issue and include the relevant section of the log file.

---

## References

- [TRaSH Guides](https://trash-guides.info) — community best-practice guides for Sonarr and Radarr
- [Servarr Wiki — Lidarr Naming Guide](https://wiki.servarr.com/lidarr/naming-guide)
- [Sonarr](https://sonarr.tv) | [Radarr](https://radarr.video) | [Lidarr](https://lidarr.audio)
