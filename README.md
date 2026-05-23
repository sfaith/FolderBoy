# FolderBoy — Media Library Manager

![Version](https://img.shields.io/badge/version-0.6.3-blue) ![Platform](https://img.shields.io/badge/platform-Windows-lightgrey) ![PowerShell](https://img.shields.io/badge/powershell-5.1%2B-blue) ![License](https://img.shields.io/badge/license-GPL--3.0-green)

A PowerShell toolkit for managing [Sonarr](https://sonarr.tv), [Radarr](https://radarr.video), and [Lidarr](https://lidarr.audio) media libraries. FolderBoy helps you keep your library clean by renaming series, movie, and artist folders to standard formats, finding orphaned media, removing folders that contain no recognized media files, and generating detailed library statistics.

---

## Prerequisites

### Required software

| Component | Requirement |
|---|---|
| **Operating system** | Windows 10, Windows 11, or Windows Server 2016 or later |
| **PowerShell** | 5.1 or later — built into all supported Windows versions |
| **Sonarr** | v3 or later, running and reachable over the network |
| **Radarr** | v3 or later, running and reachable over the network |
| **Lidarr** | v1 or later, running and reachable over the network |

All three \*arr apps are optional — set `Enabled = $false` for any app you don't use.

### Network access

FolderBoy communicates with each \*arr app over HTTP using its REST API. The machine running FolderBoy must be able to reach each app's URL (local, LAN, or UNC path). API traffic is JSON over HTTP — no special ports or credentials beyond the API key.

### File system access

FolderBoy reads your media root folders directly from disk for the Cleaner, Orphan Scanner, and Dashboard Full mode. UNC paths (`\\SERVER\Share`) and local paths (`C:\Media`) are both supported. The user running FolderBoy needs read access to all configured paths, plus write access if you intend to use Live Rename or Live Delete.

### Naming conventions (strongly recommended)

FolderBoy is designed around the naming schemes recommended by [TRaSH Guides](https://trash-guides.info). Using the recommended formats gives the Orphan Scanner its highest confidence matching and the Folder Renamers the cleanest results. See [Recommended Naming Conventions](#recommended-naming-conventions) for the exact strings to use in each app.

---

## Tools

### 1. FolderBoy Cleaner
Scans your media root folders and identifies subfolders that contain no media files matching your configured extensions. Useful for removing leftover empty folders, failed partial downloads, and sample-only folders.

- No \*arr API calls required — purely filesystem-based
- Configurable per-preset file extension lists for TV, Movies, Music, or Custom
- All Libraries mode runs all presets in sequence with a combined summary
- Reports non-media file types found in flagged folders so you know what you're deleting
- Dry Run mode shows exactly what would be deleted before you commit

### 2. Sonarr Folder Renamer
Finds Sonarr series folders missing an `{imdb-ttXXXXXXX}` ID tag, renames them on disk to match Sonarr's configured Series Folder Format, and updates the series path in Sonarr via API so everything stays in sync.

- Only renames folders missing an ID tag — already-tagged folders are skipped
- Detects folders where the name doesn't match Sonarr's title and skips them rather than renaming incorrectly
- Automatically rolls back disk renames if the Sonarr API update fails
- Dry Run mode previews all renames before applying

### 3. Radarr Folder Renamer
Finds Radarr movie folders that don't match the recommended naming format and renames them on disk, then updates the movie path in Radarr via API so everything stays in sync.

- Supports two target formats: Minimum (`{Movie CleanTitle} ({Release Year})`) and Plex (`{Movie CleanTitle} ({Release Year}) {imdb-{ImdbId}}`)
- Only renames folders that don't already match the target format
- Automatically rolls back disk renames if the Radarr API update fails
- Dry Run mode previews all renames before applying

### 4. Lidarr Folder Renamer
Finds Lidarr artist folders that don't match the recommended `{Artist Name}` format and renames them on disk, then updates the artist path in Lidarr via API so everything stays in sync.

- Handles colon and illegal character sanitization consistently with Sonarr and Radarr
- Automatically rolls back disk renames if the Lidarr API update fails
- Dry Run mode previews all renames before applying

### 5. Orphan Scanner
Compares what is on disk against what each \*arr app manages. Produces a categorized report of unrecognized folders, then optionally lets you review and delete them one at a time.

**Matching strategy:**

| App | Method |
|---|---|
| Radarr | Direct path comparison against Radarr's `path` field — no ID or name parsing needed |
| Sonarr | IMDb/TVDB ID tag matching for tagged folders; name-based fallback for untagged folders |
| Lidarr | Exact artist name match; fuzzy punctuation-stripped match for near-misses |

**Confidence categories:**

| Category | Meaning |
|---|---|
| NOT IN ARR | ID tag present but not found in \*arr library — high confidence orphan |
| NEEDS REVIEW | No ID tag and no name match — medium confidence, verify before deleting |
| NAME MATCHED | No ID tag but name matched — counted as matched, shown for awareness |

### 6. Full Run
Runs all 8 tools in sequence: Sonarr Folder Renamer → Radarr Folder Renamer → Lidarr Folder Renamer → Orphan Scanner → Sonarr File Renamer → Radarr File Renamer → Lidarr File Renamer → Media Dashboard.

Three run modes:
- **Attended** — prompts for Dry Run or Live for each tool individually (safest)
- **Dry Run All** — runs every tool in Dry Run mode without further prompts
- **Live All** — runs every tool in Live mode; requires typing `CONFIRM`; clearly explains what will and won't change (Orphan Scanner always Scan Only; Dashboard always Quick)

Disabled apps are skipped automatically.

### 7. Media Dashboard
Generates a detailed statistics report for your media libraries. Select an app (Sonarr, Radarr, Lidarr, or all) and a mode:

- **Quick mode** (API only, fast) — total counts, monitored vs unmonitored, on disk vs missing, size on disk, quality profile breakdown, and actual file quality breakdown
- **Full mode** (API + filesystem scan) — everything in Quick plus actual disk usage, file format breakdown with percentages, and top 10 largest items

Report is automatically saved to `Logs\FolderBoy_Dashboard_*.log`.

### 8. Media File Renamer
Renames individual media files inside your libraries to match each app's configured naming scheme (TRaSH Guides standard). FolderBoy uses each app's own `/rename` preview API to show you exactly what will change before anything happens, then sends a rename command — the \*arr app performs all the actual file moves.

- **Dry Run mode** calls `GET /rename` and displays the full before/after list — zero changes made
- **Live Rename mode** sends `POST /command` (RenameFiles / RenameArtist) and the app renames its own files in the background
- Scope selection per app: rename all at once, or pick a specific series / movie / artist
- No direct filesystem manipulation by FolderBoy — rename logic and error handling stays inside each \*arr app
- File naming format is controlled by each app's Media Management settings; configure those to TRaSH standards first

> **Note on Lidarr speed:** Lidarr's `/rename` API returns track-level data and must be queried once per artist. On a large music library (700+ artists) this is inherently slower than Sonarr or Radarr — expect 5–10 minutes for a full check. This is normal.

---

## Requirements

- **Windows** with PowerShell 5.1 or later (built into Windows 10, 11, and Server 2016+)
- `FolderBoy.config.ps1` configured with your settings (see [Setup](#setup) below)
- Network access to each \*arr application's API
- All \*arr apps must be running and reachable at the configured URL

---

## Setup

### 1. Download the files

Download the following files and place them in the same folder:

| File | Purpose |
|---|---|
| `FolderBoy.ps1` | Main script — do not edit this file |
| `FolderBoy.config.example.ps1` | Configuration template |
| `FolderBoy.bat` | Optional one-click launcher |

### 2. Create your config file

Copy `FolderBoy.config.example.ps1` and rename the copy to `FolderBoy.config.ps1`:

```
FolderBoy.config.example.ps1  →  FolderBoy.config.ps1  (your copy, fill this in)
```

Open `FolderBoy.config.ps1` in any text editor and fill in your settings. See [Configuration](#configuration) below for a full explanation of every setting.

### 3. Configure naming schemes in your \*arr apps

Before running FolderBoy, set each app's naming format to the TRaSH-recommended scheme. This is what FolderBoy expects and what gives you the best results. See [Recommended Naming Conventions](#recommended-naming-conventions) for the exact strings.

### 4. Run FolderBoy

Double-click `FolderBoy.bat`, or run in PowerShell:

```powershell
.\FolderBoy.ps1
```

If you see an execution policy error when running the `.ps1` directly, either use the `.bat` launcher (which bypasses the policy automatically) or run the following once as administrator:

```powershell
Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope LocalMachine
```

---

## Configuration

All settings live in `FolderBoy.config.ps1`. The main script (`FolderBoy.ps1`) loads this file automatically at startup. If the config file is missing or has errors, FolderBoy will explain what to fix before exiting.

### Enabling and disabling apps

Each \*arr app has an `Enabled` flag. Set it to `$false` if you don't use that app and FolderBoy will skip it entirely:

```powershell
$LidarrConfig = @{
    Enabled = $false    # Lidarr not in use -- skip all Lidarr features
    ...
}
```

### Suppressing missing path entries

If an app has many monitored items that haven't been downloaded yet, the Folder Renamer output can be noisy with `[MISSING]` entries. Set `SuppressMissing = $true` to hide them — the count still appears in the summary:

```powershell
$LidarrConfig = @{
    Enabled         = $true
    SuppressMissing = $true   # Hide [MISSING] lines in Lidarr Folder Renamer output
    ...
}
```

### API Keys

Find your API key in each app under **Settings → General → Security → API Key**.

### Paths

The `Paths` array is **optional**. If omitted or left empty, FolderBoy automatically fetches root folders from each app's API at startup. This means paths are always in sync with what the app has configured — no manual maintenance needed.

If you want to override or limit scope (for example, scanning only a subset of your root folders), define `Paths` explicitly:

```powershell
$RadarrConfig = @{
    Enabled = $true
    BaseUrl = 'http://localhost:7878'
    ApiKey  = 'YOUR_RADARR_API_KEY'
    Paths   = @(
        '\\NAS\Movies'
        '\\NAS\Documentaries'
    )
}
```

Paths can be local (`C:\Media\Movies`) or UNC (`\\SERVER\Movies`).

### FolderBoy Cleaner presets

Edit the presets to match your library layout. Each preset has a `Label`, a list of file `Exts` that count as media, and `Paths` to scan:

```powershell
$FolderBoyPresets = [ordered]@{
    '1' = @{
        Label = 'TV Shows'
        Exts  = @('.mkv', '.mp4', '.avi', '.ts')
        Paths = @('\\NAS\Episodes')
    }
    '2' = @{
        Label = 'Movies'
        Exts  = @('.mkv', '.mp4', '.avi', '.ts')
        Paths = @('\\NAS\Movies', '\\NAS\Documentaries')
    }
    ...
}
```

The last preset is always a **Custom** option that lets you enter extensions interactively at runtime.

---

## Recommended Naming Conventions

FolderBoy works best when your \*arr apps use the naming schemes recommended by [TRaSH Guides](https://trash-guides.info). These formats embed metadata (IMDb/TVDB IDs) that FolderBoy uses for reliable matching and are the community best-practice standard.

Configure naming schemes **before** running any of the Folder Renamers or File Renamers. The Folder Renamers will bring your existing folders into line with whatever format you set, and the File Renamer will apply each app's configured naming scheme to individual files.

---

### Sonarr

**Series Folder Format**
Go to **Settings → Media Management → Show Advanced → Series Folder Format**

```
{Series TitleYear} {imdb-{ImdbId}}
```
Example: `The Wire (2002) {imdb-tt0306414}`

The `{imdb-{ImdbId}}` tag is what the Sonarr Folder Renamer adds and the Orphan Scanner uses for high-confidence matching. Without it, FolderBoy falls back to name-only matching.

**Episode Naming Format**
Go to **Settings → Media Management → Episode Naming**

TRaSH recommends a format that includes the series title, season/episode numbers, episode title, quality, and release group. The exact string is long — use the TRaSH guide to copy it directly:

📖 **Full Sonarr naming guide:** https://trash-guides.info/Sonarr/Sonarr-recommended-naming-scheme/

---

### Radarr

**Movie Folder Format**
Go to **Settings → Media Management → Show Advanced → Movie Folder Format**

Minimum (compatible with most setups):
```
{Movie CleanTitle} ({Release Year})
```

Plex (includes IMDb ID for direct matching):
```
{Movie CleanTitle} ({Release Year}) {imdb-{ImdbId}}
```
Example: `The Dark Knight (2008) {imdb-tt0468569}`

FolderBoy's Radarr Folder Renamer supports both formats — choose at runtime.

**Movie File Naming Format**
Go to **Settings → Media Management → Movie Naming**

TRaSH recommends a format that includes the movie title, year, edition, quality, and release group. Use the TRaSH guide to copy the recommended string directly:

📖 **Full Radarr naming guide:** https://trash-guides.info/Radarr/Radarr-recommended-naming-scheme/

---

### Lidarr

Go to **Settings → Media Management → Show Advanced**

**Artist Folder Format:**
```
{Artist Name}
```

**Album Folder Format:**
```
{Album Title} {(Album Disambiguation)}
```
The disambiguation suffix (e.g. `(Deluxe Edition)`, `(2023 Remaster)`) prevents collisions between multiple releases with the same title.

**Track Naming Format:**
TRaSH recommends including track number, title, and quality. Use the Servarr Wiki for the recommended string:

📖 **Full Lidarr naming guide:** https://wiki.servarr.com/lidarr/naming-guide

---

## Recommended Workflow

### First-time setup on an existing library

1. Configure naming schemes in Sonarr, Radarr, and Lidarr (see above)
2. **Sonarr Folder Renamer → Dry Run** — review which series folders would be renamed and tagged
3. **Sonarr Folder Renamer → Live Rename** — apply
4. **Radarr Folder Renamer → Dry Run** — review movie folder renames
5. **Radarr Folder Renamer → Live Rename** — apply
6. **Lidarr Folder Renamer → Dry Run** — review artist folder renames
7. **Lidarr Folder Renamer → Live Rename** — apply
8. **Orphan Scanner → Scan Only** — review the full orphan report
9. **Orphan Scanner → Scan + Delete** — delete confirmed orphans
10. **Media File Renamer → Dry Run (All apps)** — review which individual files would be renamed
11. **Media File Renamer → Live Rename** — apply
12. **Media Dashboard** — run after cleanup for a full baseline report

### Ongoing maintenance

Use **option 6 (Full Run)** for regular maintenance. Select **Dry Run All** for a fast, safe check of what has drifted across all 8 tools. Select **Attended** to choose Dry Run or Live for each tool individually as it runs. Use **Live All** only when you're ready to apply everything in one pass.

---

## File Reference

| File | Committed to repo | Description |
|---|---|---|
| `FolderBoy.ps1` | ✅ Yes | Main script |
| `FolderBoy.config.example.ps1` | ✅ Yes | Config template with placeholders |
| `FolderBoy.bat` | ✅ Yes | One-click launcher |
| `README.md` | ✅ Yes | This file |
| `.gitignore` | ✅ Yes | Excludes config and log files |
| `FolderBoy_LogicTests.ps1` | ✅ Yes | Standalone logic test suite |
| `FolderBoy_Test_Checklist.md` | ✅ Yes | Interactive test checklist |
| `FolderBoy.config.ps1` | ❌ No (gitignored) | Your config with real API keys and paths |
| `Logs\` | ❌ No (gitignored) | Runtime logs generated by FolderBoy |

---

## Log Files

Every run saves a timestamped log file to the `Logs\` subfolder next to `FolderBoy.ps1`.

| Tool | Log filename |
|---|---|
| FolderBoy Cleaner | `FolderBoy_YYYYMMDD_HHMMSS.log` |
| Sonarr Folder Renamer | `FolderBoy_SonarrRenamer_YYYYMMDD_HHMMSS.log` |
| Radarr Folder Renamer | `FolderBoy_RadarrRenamer_YYYYMMDD_HHMMSS.log` |
| Lidarr Folder Renamer | `FolderBoy_LidarrRenamer_YYYYMMDD_HHMMSS.log` |
| Orphan Scanner | `FolderBoy_Scanner_YYYYMMDD_HHMMSS.log` |
| Media Dashboard | `FolderBoy_Dashboard_YYYYMMDD_HHMMSS.log` |
| Media File Renamer | `FolderBoy_FileRenamer_YYYYMMDD_HHMMSS.log` |

When using Full Run, each tool writes its own log file independently.

---

## Troubleshooting

**Config file not found**

FolderBoy will print clear setup instructions. Copy `FolderBoy.config.example.ps1` to `FolderBoy.config.ps1` and fill in your values.

**"Could not reach API" errors**

- Confirm the `BaseUrl` matches the URL you use to access the app in a browser
- Confirm the app is running and reachable from the machine running FolderBoy
- Double-check the `ApiKey` — copy it fresh from Settings → General in the app

**"Path not found" warnings**

- Confirm the path exists and is accessible from the machine running FolderBoy
- For UNC paths (`\\SERVER\Share`), verify network access is available
- Check for typos or missing leading backslashes in the config

**Sonarr API returns 400 Bad Request**

FolderBoy sends the request body as UTF-8 bytes to handle series with non-ASCII characters. If you still see this error, open an issue and include the relevant section of the log file.

**Title mismatch warnings in the Sonarr Folder Renamer**

The folder name and Sonarr's stored title differ enough that FolderBoy won't rename automatically. Rename the folder manually to match the Sonarr title, then re-run the Sonarr Folder Renamer.

**Lidarr File Renamer is slow**

This is normal. Lidarr's `/rename` API must be queried once per artist and returns track-level data — 700+ artists takes 5–10 minutes. No fix needed.

**Execution policy error**

Use the `.bat` launcher instead, or run once as administrator:
```powershell
Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope LocalMachine
```

---

## Contributing

Pull requests welcome. If you encounter a matching failure, incorrect deletion candidate, or API error, please open an issue and include the relevant section of the log file.

---

## References

- [TRaSH Guides](https://trash-guides.info) — community best-practice guides for Sonarr and Radarr naming, quality profiles, and custom formats
- [TRaSH — Sonarr Naming](https://trash-guides.info/Sonarr/Sonarr-recommended-naming-scheme/)
- [TRaSH — Radarr Naming](https://trash-guides.info/Radarr/Radarr-recommended-naming-scheme/)
- [Servarr Wiki — Lidarr Naming Guide](https://wiki.servarr.com/lidarr/naming-guide)
- [Sonarr](https://sonarr.tv) | [Radarr](https://radarr.video) | [Lidarr](https://lidarr.audio)
