# Changelog

All notable changes to FolderBoy are documented here.

Format follows [Keep a Changelog](https://keepachangelog.com/en/1.0.0/).

---

## [Unreleased]

### Planned
- Scheduled / unattended execution support (Windows Task Scheduler)
- Radarr orphan scanner improvements for libraries with parenthetical folder suffixes
- Media file renaming (FLAC/MP3 cleanup within album folders)

---

## [0.4.3] - 2026-05-17

### Added
- **Automatic path resolution from \*arr APIs** — the `Paths` array in each \*arr
  config block is now optional. If omitted or empty, FolderBoy queries the app's
  `rootfolder` API endpoint at startup and uses those paths automatically. This
  keeps paths in sync with what each app has configured without any manual
  maintenance. Explicit `Paths` in config always takes precedence if defined.
- **Startup path resolution output** — a brief summary is printed at startup
  showing whether each app's paths came from config or were fetched from the API.

### Changed
- **`FolderBoy.config.example.ps1`** — `*arr` config blocks now appear before
  `$FolderBoyPresets` so the presets can reference `$SonarrConfig.Paths` etc.
  directly. `Paths` is now commented out by default in all three `*arr` blocks,
  with instructions to uncomment and edit if an override is needed.
- **README** — Paths section updated to reflect that `Paths` is now optional,
  with guidance on when to define it explicitly.

---

## [0.4.2] - 2026-05-17

### Added
- **Orphan Scanner Scan + Delete mode banner** — Scan + Delete mode now displays
  a yellow banner at startup confirming the mode and reminding the user that
  nothing is deleted until the final confirmation. Mirrors the existing Scan Only
  mode banner for consistency.

### Fixed
- **Orphan Scanner interactive delete** — "REVIEWING N ITEMS" header showed
  incorrect count when exactly one item was queued for review. `Sort-Object` on
  a single-item collection returns the item itself rather than a collection, so
  `.Count` was returning the number of hashtable keys (4) instead of 1. Fixed by
  wrapping the sort result in `@()` to force an array.

---

## [0.4.1] - 2026-05-17

### Added
- **Orphan Scanner scope selection** — before choosing Scan Only or Scan + Delete,
  the user now selects which libraries to scan: All libraries, Radarr only, Sonarr
  only, or Lidarr only. Disabled apps are skipped with a message when selected
  individually. Full Run always scans all libraries. Scope is shown in the scanner
  header and session log.

### Fixed
- **Lidarr Folder Renamer** — trailing periods are now stripped from generated
  artist folder names. Windows allows trailing periods in folder names but
  Explorer and many tools silently remove them, causing path resolution issues.
  Artists like `T.I.`, `Dinosaur Jr.`, and `Run‐D.M.C.` whose folders lack the
  trailing period are now correctly treated as already correct rather than flagged
  for rename.
- **Lidarr Folder Renamer** — folders with a trailing period in their existing name
  (e.g. `T.I.` on disk) are now also treated as already correct when the generated
  target name matches after stripping the period. Previously this caused a spurious
  WOULD RENAME from `T.I.` to `T.I`.

### Changed
- **Log file location** — logs are now written to a `Logs\` subdirectory next to
  `FolderBoy.ps1` rather than the script directory root. The folder is created
  automatically on first run. `.gitignore` updated accordingly.
- **Code optimization** — six app-specific API helper functions (`Invoke-SonarrGet`,
  `Invoke-SonarrPut`, `Invoke-RadarrGet`, `Invoke-RadarrPut`, `Invoke-LidarrGet`,
  `Invoke-LidarrPut`) consolidated into two generic helpers (`Invoke-ArrGet`,
  `Invoke-ArrPut`). API version stamped onto each app config at startup.
- **Orphan Scanner performance** — folder size calculation deferred to display time
  in all three scanners. Size is now only calculated for folders that actually appear
  in the report, not for every unmatched folder during the scan loop.
- **Lidarr Scanner performance** — fuzzy artist name lookup pre-computed as a
  hashtable at library load time rather than iterating all keys per unmatched folder.
- **`Test-TitleMatch`** — replaced inline normalize scriptblock with the existing
  global `Normalize` function.
- **`Normalize-Path`** — double `.TrimEnd()` calls collapsed into a single call.

---

## [0.4.0] - 2026-05-17

### Added
- **Lidarr Folder Renamer** (menu option 4) — renames artist folders to the
  `{Artist Name}` format recommended by Lidarr and updates artist paths via API.
  - Uses Lidarr API v1
  - Same colon and illegal character sanitization as Sonarr Folder Renamer
  - Automatic rollback if Lidarr API update fails after disk rename
  - Dry Run and Live Rename modes
  - Timestamped log: `FolderBoy_LidarrRenamer_YYYYMMDD_HHMMSS.log`
- **Lidarr Folder Renamer** added to Full Run sequence (runs after Radarr, before Orphan Scanner)
- **Lidarr Folder Renamer** added to README tools section, recommended workflow, and log file table

### Changed
- **Sonarr Folder Tagger renamed to Sonarr Folder Renamer** throughout — script,
  README, CHANGELOG, log prefix (`FolderBoy_SonarrRenamer_*`), and all menu text.
  The tool is functionally identical; the name better reflects what it does and
  matches the naming convention of Radarr Folder Renamer and Lidarr Folder Renamer.
- **Main menu renumbered** to accommodate new tool:
  - (1) FolderBoy Cleaner
  - (2) Sonarr Folder Renamer *(renamed from Sonarr Folder Tagger)*
  - (3) Radarr Folder Renamer
  - (4) Lidarr Folder Renamer *(new)*
  - (5) Orphan Scanner
  - (6) Full Run
  - (7) Exit
- **Full Run** (option 6) now runs all three Folder Renamers before Orphan Scanner;
  each renamer prompts for its own Dry Run / Live Rename mode independently
- **Script header comment** updated: tool count corrected to six, all six tools listed
- **README intro** updated to reflect all three Folder Renamers
- **README recommended workflow** updated with Lidarr steps and corrected option numbers
- **Orphan Scanner tip** updated to reference Sonarr Folder Renamer by new name

---

## [0.3.0] - 2026-05-16

### Added
- **Radarr Folder Renamer** (menu option 3) — renames movie folders to match the
  TRaSH Guides recommended naming format and updates Radarr paths via API.
  - User selects target format at runtime:
    - Minimum: `{Movie CleanTitle} ({Release Year})`
    - Plex: `{Movie CleanTitle} ({Release Year}) {imdb-{ImdbId}}`
  - Movies with no release year in Radarr are skipped and listed in output
  - Automatic rollback if Radarr API update fails after disk rename
  - Dry Run and Live Rename modes
  - Timestamped log: `FolderBoy_RadarrRenamer_YYYYMMDD_HHMMSS.log`
- **Session activity tracker** — main menu now displays a `This session:` section
  showing each tool that has been run, its mode, and the time it completed.
  Example: `[18:45] Sonarr Folder Tagger [Dry Run] -- complete`
- **Radarr Folder Renamer** added to README tools section with full description
- **Radarr Folder Renamer** added to recommended workflow in README

### Changed
- Main menu renumbered to accommodate new tool:
  - (1) FolderBoy Cleaner
  - (2) Sonarr Folder Tagger
  - (3) Radarr Folder Renamer *(new)*
  - (4) Orphan Scanner
  - (5) Full Run
  - (6) Exit
- README recommended workflow updated to include Radarr Folder Renamer steps
- README log file table updated with Radarr Folder Renamer entry

### Fixed
- **`Get-FolderSizeBytes`** — `return if (...)` is invalid PowerShell 5.1 syntax;
  replaced with `if (...) { return ... } else { return ... }`. This caused all
  folder sizes to display as `0 B` in the Orphan Scanner output.
- **Orphan Scanner header** — inline `if` expression inside a `-f` format string
  caused `'if' is not recognized` errors on every scanner invocation. Fixed by
  assigning to a temp variable before formatting.

---

## [0.2.0] - 2026-05-16

### Added
- **External config file** (`FolderBoy.config.ps1`) — all user settings (API keys,
  paths, presets) moved out of the main script into a separate file that is loaded
  at startup via dot-sourcing.
  - `FolderBoy.config.example.ps1` — sanitized template with placeholder values,
    committed to source control.
  - `FolderBoy.config.ps1` — user's actual config, excluded from source control
    via `.gitignore`.
- **Config validation on startup** — if the config file is missing, has syntax
  errors, or is missing required variables, FolderBoy prints a clear setup guide
  and exits gracefully rather than crashing.
- **`.gitignore`** — excludes `FolderBoy.config.ps1` and all `*.log` files.
- **`FolderBoy.bat`** — one-click launcher that bypasses PowerShell execution
  policy restrictions. Drop alongside `FolderBoy.ps1` and double-click to run.
- **`README.md`** — full GitHub-ready documentation covering:
  - Tool descriptions and matching strategy
  - Requirements and setup instructions
  - Configuration reference for all settings
  - TRaSH Guides naming convention recommendations for Sonarr, Radarr, and Lidarr
  - Recommended first-run workflow
  - File reference table (what gets committed vs. what stays local)
  - Log file reference
  - Troubleshooting guide
- **In-script TRaSH Guides tips** (`[TIP]` lines in DarkCyan) — displayed at
  relevant moments during each tool run:
  - Sonarr tagger shows recommended Series Folder Format and guide link
  - Radarr scanner shows recommended Movie Folder Format and guide link
  - Lidarr scanner shows recommended Artist and Album Folder formats and guide link
- **`Enabled` flag** on each `*arr` config block — set to `$false` to skip an app
  entirely. Disabled apps are skipped in all tools and labeled `Disabled` in
  the Orphan Scanner overall summary.
- **`Confirm-LiveAction` helper** — shared function used by all tools before any
  destructive action; prints a standard warning and requires `YES` confirmation.
- **Dry Run explanation banners** — each tool prints a clear explanation of what
  Dry Run mode does (and does not do) before processing begins.

### Changed
- **Merged all scripts into single `FolderBoy.ps1`** — FolderBoy Cleaner,
  Sonarr Folder Tagger, and Orphan Scanner combined into one file with a
  persistent main menu.
- **Main menu** — interactive, returns to menu after each tool completes.
  Sub-menus prompt for mode (Dry Run vs. Live) before each tool runs.
- **`Paths` config** — each app config now accepts an array of root paths,
  supporting libraries spread across multiple root folders.
- **Orphan Scanner overall summary** — correctly shows `Disabled` for apps
  that are turned off in config, rather than `SKIPPED (API unreachable)`.
- Script header updated to reflect merged structure and config file requirement.

---

## [0.1.0] - 2026-05-16

### Added

#### FolderBoy Cleaner
- Scans media root folders recursively for subfolders containing no recognized
  media files matching configured extensions.
- Pre-configured presets for TV Shows, Movies, and Music with appropriate
  default extension lists.
- Custom preset — user enters extensions interactively at runtime.
- Multi-path support — if a preset has multiple paths, user can choose one or
  scan all.
- Non-media file type breakdown in output — shows what file types were found
  in flagged folders (e.g. `.nfo`, `.jpg`, `.srt`).
- Dry Run mode — shows folders that would be deleted with size estimates.
- Live Delete mode — deletes folders with no media files after `YES` confirmation.
- Timestamped log: `FolderBoy_YYYYMMDD_HHMMSS.log`

#### Sonarr Folder Tagger
- Queries Sonarr API for all series in the library.
- Identifies series folders missing an `{imdb-ttXXXXXXX}` ID tag.
- Renames folders on disk to match the TRaSH Guides recommended Series Folder
  Format: `{Series TitleYear} {imdb-{ImdbId}}`
- Updates the series path in Sonarr via API after each rename so Sonarr stays
  in sync with the new folder name.
- Handles disambiguation titles correctly — does not append year a second time
  to titles that already end with `(YYYY)` (e.g. `The Twilight Zone (1985)`).
- Skips series where the folder name does not normalize to match the Sonarr title,
  logging a `[MISMATCH]` entry rather than renaming incorrectly.
- Skips series with no IMDb ID in Sonarr; lists them in the summary with a tip
  on how to add one.
- Sends Sonarr PUT requests as UTF-8 byte arrays to handle series with non-ASCII
  characters in alternate titles (e.g. accented letters) that caused `400 Bad
  Request` errors when sent as plain strings.
- Automatic rollback — if the disk rename succeeds but the Sonarr API update
  fails, the folder rename is reversed and the failure is logged.
- Dry Run and Live Rename modes.
- Timestamped log: `FolderBoy_Tagger_YYYYMMDD_HHMMSS.log`

#### Orphan Scanner
- Scans configured root paths for each app and cross-references against the
  app's library via API.
- **Radarr matching** — direct path comparison against Radarr's `path` field
  for each movie. No ID or name parsing required. Most reliable matching method.
- **Sonarr matching** — three-tier approach:
  - IMDb ID tag match (high confidence) for folders tagged by the Sonarr Folder Tagger
  - TVDB ID tag match fallback
  - Normalized name match fallback for untagged folders
- **Lidarr matching** — exact normalized artist name match with a secondary
  punctuation-stripped fuzzy match for near-misses (e.g. `AC-DC` vs `ACDC`).
- Three output categories with explanations:
  - `NOT IN ARR` — high confidence; ID tag present but not found in library
  - `NEEDS REVIEW` — medium confidence; no ID tag, no name match
  - `NAME MATCHED` — low confidence; name matched but no ID tag to confirm
- Interactive delete flow (Scan + Delete mode):
  - Category selection — choose which confidence levels to review
  - Per-item review with `(D)elete / (S)kip / (Q)uit`
  - Deletion queue summary showing total size before committing
  - Final `YES` confirmation before any files are deleted
  - Deletions executed in a single pass after confirmation
- Scan Only mode — reports orphans without any delete prompts.
- Timestamped log: `FolderBoy_Scanner_YYYYMMDD_HHMMSS.log`

### Fixed (during initial development and testing)
- **Double-year bug** — `Get-TargetFolderName` now checks if the clean title
  already ends with any `(\d{4})` before appending the year, preventing
  `Battlestar Galactica (2003) (2005) {imdb-...}` style duplication.
- **Trailing backslash** — Sonarr paths with a trailing `\` are trimmed before
  `Split-Path` runs to prevent incorrect folder name parsing.
- **Title mismatch safety** — `Test-TitleMatch` compares the folder base name
  against both the full Sonarr title and the title without its disambiguation
  year, preventing false mismatch flags for folders like `Battlestar Galactica
  (2003)` which legitimately differ from Sonarr's broadcast year.
- **Sonarr API 400 errors** — all Sonarr PUT requests now send the body as
  UTF-8 encoded bytes with `Content-Type: application/json; charset=utf-8`,
  resolving failures for series with non-ASCII alternate title entries
  (e.g. `Rick es Morty`).
- **Radarr path matching** — replaced name-based Radarr matching (which produced
  thousands of false `NEEDS REVIEW` results) with direct path comparison against
  Radarr's `path` field. Eliminated all false positives for Radarr.
- **`Test-TitleMatch` over-aggressiveness** — early version stripped trailing
  years from folder names before comparing, causing legitimate disambiguation
  folders (`Battlestar Galactica (2003)`, `The Twilight Zone (1985)`) to flag
  as mismatches. Fixed to compare full folder base name without stripping.
- **Sonarr `alternateTitles` null investigation** — ruled out as root cause
  of 400 errors (titles appeared non-null); root cause was string encoding.

---

## Notes

Version numbers reflect development milestones rather than formal releases.
All versions were developed and tested against:
- Sonarr v4 (API v3) at `http://localhost:8989`
- Radarr v5 (API v3) at `http://localhost:7878`
- Lidarr v2 (API v1) at `http://localhost:8686`
- Windows 10 / PowerShell 5.1
- NAS accessed via UNC paths (`\\YOUR-SERVER\...`)