# Changelog

All notable changes to FolderBoy are documented here.

Format follows [Keep a Changelog](https://keepachangelog.com/en/1.0.0/).

---

## [Unreleased]

### Planned
- Scheduled / unattended execution support (Windows Task Scheduler)
- Radarr orphan scanner improvements for libraries with parenthetical folder suffixes
- Naming Config Manager -- view and apply TRaSH-recommended naming schemes via API
- Quality Upgrade Scanner -- surface items below quality profile cutoff across all apps
- Duplicate Detector
- Menu consistency: "All apps" / "All libraries" option to appear after Sonarr, Radarr,
  Lidarr in all menus (currently last in most, pending test confirmation)

---

## [0.6.3] - 2026-05-23

### Fixed
- **`Confirm-LiveAction` case sensitivity** -- confirmation prompt now accepts
  `yes`, `Yes`, or `YES` consistently. Previously required exact case match `YES`,
  rejecting lowercase variants. Matches TrashBoy behavior.
- **Exit message** -- "Goodbye." replaced with a warm, personal thank-you message.
- **Orphan Scanner path header collision** -- `Clear-Progress` was missing before
  the `Scanning \\path (N folders)` line in `Invoke-RadarrScan`, `Invoke-SonarrScan`,
  and `Invoke-LidarrScan`. On multi-path libraries the previous path's progress line
  was still visible on the right side of the terminal when the next path announced
  itself. Fixed in all three scanners.
- **Media File Renamer -- Summary Only mode** -- after selecting app scope, a new
  detail-level prompt lets the user choose between Full listing (all From/To paths,
  original behavior) and Summary only (per-app table only, no per-file lines). Dry
  run only; Live Rename always shows the summary table. Keeps large-library logs
  (4,000+ movies) from becoming unwieldy.
- **FolderBoy Cleaner -- separator visual** -- the closing `------` divider line in
  `Invoke-CleanerScan` is now only printed when at least one folder was flagged.
  Previously it appeared even on clean runs, producing an orphaned dashes line with
  nothing between it and the summary counts.
- **File Renamer summary tables -- Group-Object scriptblock** -- `Group-Object PropertyName`
  on `List[hashtable]` groups everything into one bucket (key access fails silently); all
  six `Group-Object` calls changed to `Group-Object { $_.PropertyName }` scriptblock form.
  Summary tables now correctly show one row per series/movie/artist.
- **Full Run session log -- one entry per tool** -- previously joined all 8 tool results
  into a single session log line. Now each tool adds its own entry with individual
  timestamp and elapsed time.
- **Full Run file renamer log contamination** -- when called from Full Run, Sonarr/Radarr/
  Lidarr File Renamer sub-functions inherited the Orphan Scanner's `$Script:LogFile`.
  Fixed with a `-SharedLog` parameter.
- **Media File Renamer session log missing app name** -- `Add-SessionEntry` for Tool 8
  now records which app was selected alongside mode. Entry suppressed on M/Q abort.
- **README** -- added Prerequisites, expanded Recommended Naming Conventions, updated
  Recommended Workflow, added Lidarr slowness to Troubleshooting, added References.

---

## [0.6.2] - 2026-05-21

### Fixed
- **Media File Renamer: "Across : 0 series/artists"** -- `Select-Object -ExpandProperty`
  on a `List[hashtable]` does not expand hashtable values; replaced with
  `ForEach-Object { $_.PropertyName } | Select-Object -Unique` in both the
  Sonarr series count and Lidarr artist count summary lines.
- **Media File Renamer: live-rename group title lookup** -- the `Where-Object`
  re-scan of `$allRenames` to find a display name for each group was O(n²) and
  could silently return empty if the type comparison failed. Replaced with direct
  access `$group.Group[0].PropertyName` in all three sub-renamers (Sonarr, Radarr,
  Lidarr). Simpler, faster, and type-safe.

---

## [0.6.1] - 2026-05-21

### Added
- **Per-item summary tables in Media File Renamer dry run output** -- after the
  full file-by-file listing, each sub-renamer now prints a compact summary table
  showing every series / movie / artist with a file count. Makes it easy to scan
  a large library's rename scope at a glance without reading thousands of lines.
  Columns: name (55 chars) and file count. Sorted alphabetically.

---

## [0.6.0] - 2026-05-21

### Added
- **Media File Renamer (Tool 8)** -- renames individual media files inside Sonarr,
  Radarr, and Lidarr libraries to match each app's configured naming scheme.
  - **Dry Run mode**: calls `GET /api/vX/rename` per app to preview every
    `existingPath → newPath` change before anything happens. Zero changes made.
  - **Live Rename mode**: sends `POST /api/vX/command` (Sonarr/Radarr: `RenameFiles`;
    Lidarr: `RenameArtist`) and the *arr app performs all file renaming in the
    background. FolderBoy does no direct filesystem manipulation.
  - Scope selection per app: rename all items at once, or pick a single
    series (Sonarr), movie (Radarr), or artist (Lidarr) from a numbered list.
  - File naming format is controlled by each app's own Media Management settings;
    the tip at the start of each sub-renamer points to the relevant guide.
  - Output grouped by series/movie/artist with clear From/To display.
  - Confirmation prompt with file count before any live rename is sent.
  - Background-processing note and tip to check Activity > Queue in each app.
- **`Invoke-ArrPost` helper** -- new generic POST function (parallel to the existing
  `Invoke-ArrGet` / `Invoke-ArrPut`) used by all three file renamer sub-functions
  to send commands to the *arr APIs.
- **Progress indicator** -- `Write-Progress2` and `Clear-Progress` helpers added.
  All long-running loops now show a live `\r`-overwrite console status line in the
  format `  Label N / Total  (Item Name)` with a 90-char pad to prevent leftovers.
  Loops instrumented: Cleaner folder scan, Sonarr/Radarr/Lidarr Folder Renamer,
  Orphan Scanner (all three apps), Dashboard Full mode filesystem scans (all three
  apps), Sonarr/Radarr/Lidarr File Renamer API check loops. Console only -- log
  file is never affected.
- **Full Run redesign (Tool 6)** -- now runs all 8 tools in sequence: Sonarr Folder
  Renamer → Radarr Folder Renamer → Lidarr Folder Renamer → Orphan Scanner → Sonarr
  File Renamer → Radarr File Renamer → Lidarr File Renamer → Media Dashboard.
  Three run modes: (1) Attended -- prompts per tool; (2) Dry Run All -- no prompts,
  all dry runs; (3) Live All -- requires typing `CONFIRM`, clearly explains what will
  and won't be changed (Orphan Scanner stays Scan Only; Dashboard runs Quick).
- **`Invoke-MediaDashboardDirect`** -- unattended entry point for the Dashboard used
  by Full Run; accepts `-FullScan` parameter, bypasses interactive menus.
- **`Get-FullRunMode` helper** -- inner function used by Full Run to select tool mode
  based on attended vs unattended setting.
- **Exit moved to option 9** -- menu renumbered to accommodate Media File Renamer at 8.

### Changed
- **Tool ordering** -- Sonarr → Radarr → Lidarr → All apps enforced consistently
  throughout: main menu health widget, Orphan Scanner scope menu, Dashboard app menu
  and All apps dispatch order, `Invoke-MediaDashboardDirect` dispatch order.
- **Main menu** -- Full Run description updated to reflect all 8 tools.
- **Orphan Scanner scope menu** -- reordered: All → Sonarr → Radarr → Lidarr.

### Fixed
- **Progress indicator `\r` collision** -- `Clear-Progress` is now called immediately
  before every mid-loop `Write-Log` that produces visible output (`[WOULD RENAME]`,
  `[MISSING]`, `[NO YEAR]`, `[NO IMDB ID]`, `[MISMATCH]`, `[CONFLICT]`, `[RENAMED]`,
  `[API FAIL]`, `[DELETED]`, `[FAILED]`, `[WOULD DELETE]`) across all three Folder
  Renamers and the Cleaner. Fixes garbled output on multi-root libraries.
- **Cleaner multi-root progress collision** -- `Clear-Progress` added before each
  "Scanning \\\path (N subfolders)" header line in the outer root loop, so the
  previous root's progress line is always cleared before the next root announces.
- **File Renamer summary tables -- blank name column** -- `Group-Object` on
  `List[hashtable]` cannot access hashtable keys as property names, so `$_.Name`
  was blank. All three summary tables now use `Group-Object {ID field}` +
  `$_.Group[0].{NameField}` for display, matching the fix applied to Folder Renamer
  count lines in earlier patches.
- **Lidarr Folder Renamer live rename output** -- `Clear-Progress` added before
  `[RENAMED]` and `[API FAIL]` lines, consistent with Sonarr and Radarr.

---

## [0.5.2] - 2026-05-19

### Changed
- **Lidarr Dashboard album display** -- the album line now shows monitored count,
  on-disk count, and not-downloaded count separately, making the gap between
  Lidarr's full catalogue and what is actually on disk immediately clear.
  e.g. `8,840 monitored  |  4,397 on disk  (4,443 not downloaded)`. Yellow
  when there are undownloaded albums, white when all monitored albums are on disk.
- **Lidarr Dashboard track count** -- added `Tracks on disk` line showing the
  total track file count summed from album statistics, enabling direct comparison
  against Plex/Tautulli track counts.

---

## [0.5.1] - 2026-05-18

### Fixed
- **Sonarr Dashboard size reporting** -- the bulk `/episodefile` endpoint returns
  400 Bad Request in Sonarr v3. Size is now read from `series.statistics.sizeOnDisk`
  which is returned inline with the `/series` call at no extra cost, giving accurate
  total size with zero additional API calls.
- **Sonarr Dashboard quality breakdown** -- quality data now fetched per-series
  using `episodefile?seriesId=X` (the correct v3 endpoint). Sampled from the top
  20 series by episode count to keep Quick mode fast. Label updated to reflect
  the sampling so users understand the scope.

---

## [0.5.0] - 2026-05-18

### Added
- **Media Dashboard (Tool 7)** -- new dedicated menu option for library statistics.
  - Select app (Radarr / Sonarr / Lidarr / All) and optionally a specific path.
  - **Quick mode** (API only, fast): total counts, monitored vs unmonitored, on disk
    vs missing, size on disk, quality profile breakdown, and actual file quality
    breakdown. Sonarr size is fetched via `/episodefile` endpoint. Lidarr shows
    album counts; size requires Full mode.
  - **Full mode** (API + filesystem scan): everything in Quick plus actual disk
    usage per path, file format breakdown with percentages, and top 10 largest
    items per library.
  - Report automatically saved to `Logs\FolderBoy_Dashboard_*.log`.
- **Exit moved to option 8** -- menu renumbered to accommodate Dashboard at 7.

### Fixed
- **`Format-Bytes`** now handles TB-scale values correctly (previously displayed
  large libraries as thousands of GB).

---

## [0.4.6] - 2026-05-17

### Fixed
- **`Test-TitleMatch`** -- added optional `$Year` parameter (default 0). Previously,
  a folder named `The Wire (2002)` against a Sonarr title `The Wire` (year stored
  separately) would produce a false `[MISMATCH]` and be skipped. The function now
  also compares the folder name against the clean Sonarr title reconstructed with
  the series year (e.g. `The Wire (2002)`), correctly identifying these as matches.
  Existing behavior for disambiguation-year titles (`The Twilight Zone (1985)`) and
  for direct-match titles is unchanged.
- **`Invoke-SonarrRenamer`** -- updated `Test-TitleMatch` call to pass `$year` so
  the new comparison is active during live renames.

### Added
- **`FolderBoy_LogicTests.ps1`** -- standalone logic test suite (79 tests) covering
  all pure functions: `Normalize`, `Normalize-Path`, `Get-CleanTitle`,
  `Get-RadarrCleanTitle`, `Get-LidarrCleanArtistName`, `Get-TargetFolderName`,
  `Get-RadarrTargetFolderName`, `Test-TitleMatch` (including new `$Year` cases),
  `Format-Bytes`, Lidarr already-correct logic, Orphan Scanner `@()` fix, log
  file prefix checks, and 20 code-level feature presence checks.

---

## [0.4.5] - 2026-05-17

### Added
- **Config validator** -- runs automatically at startup after path resolution.
  Tests API connectivity (via `/system/status`) and path accessibility for every
  enabled app. Prints pass/fail for each check. All results are always shown,
  including passes, so users can confirm their setup is fully operational.
- **Library health dashboard** -- the main menu now displays a color-coded summary
  below the tool list showing API status and library counts for each enabled app.
  Green = healthy, Yellow = orphans present (after an Orphan Scanner run),
  Red = API unreachable or path inaccessible. Counts are fetched at startup and
  cached; orphan counts are updated after each Orphan Scanner run.
- **SuppressMissing config flag** -- add `SuppressMissing = $true` to any `*arr`
  config block to hide `[MISSING]` path entries in that app's Folder Renamer
  output. The count is still shown in the summary. Useful for Lidarr libraries
  with many monitored-but-not-yet-downloaded artists. Applies to Sonarr, Radarr,
  and Lidarr renamers. Defaults to `$false` if not set.

---

## [0.4.4] - 2026-05-17

### Added
- **FolderBoy Cleaner All Libraries mode** -- a new `(A) All libraries` option in
  the Cleaner media type menu runs every non-custom preset in sequence using all
  configured paths. Mode (Dry Run or Live Delete) is selected once upfront and
  applied to all presets. Each preset produces its own per-library summary, followed
  by a combined OVERALL SUMMARY showing total folders and reclaimable space across
  all libraries. The Custom preset is excluded from All Libraries runs.
- **`Invoke-CleanerScan` helper** -- core scan logic extracted into a reusable
  function, making the Cleaner code cleaner and enabling the All Libraries mode
  without duplicating logic.

---

## [0.4.3] - 2026-05-17

### Added
- **Auto path resolution** -- `Paths` is now optional in each `*arr` config block.
  If omitted or empty, FolderBoy fetches root folders from the app's API at startup
  via `GET /api/vX/rootfolder`. Paths defined in config always take precedence.
  Resolved paths are shown at startup for verification.

### Changed
- Config example reordered: `*arr` config blocks now appear before `$FolderBoyPresets`
  so presets can reference `$SonarrConfig.Paths`, `$RadarrConfig.Paths`, and
  `$LidarrConfig.Paths` directly.
- Cleaner presets updated to reference `*arr` config paths directly (single source
  of truth).

---

## [0.4.2] - 2026-05-17

### Added
- **Orphan Scanner Scan+Delete banner** -- Live Delete mode now shows a clear
  `SCAN + DELETE MODE` banner at the start of the run.

### Fixed
- **REVIEWING N ITEMS count** -- `Sort-Object` on a single-item list returns the
  item itself rather than a collection; wrapping with `@()` ensures `.Count` always
  returns the number of items rather than the number of hashtable keys.

---

## [0.4.1] - 2026-05-17

### Added
- **Orphan Scanner scope selection** -- choose All Libraries, Radarr only, Sonarr
  only, or Lidarr only before each scan.
- **Lidarr trailing-period fix** -- artist names ending in a period (e.g. `T.I.`,
  `Dinosaur Jr.`) generate folder names with a trailing period that Windows handles
  inconsistently. FolderBoy now strips trailing periods from generated names and
  treats existing folders whose name differs only by a trailing period as already
  correct (no rename needed).

### Changed
- Six app-specific API helpers (`Invoke-SonarrGet`, `Invoke-RadarrGet`, etc.)
  consolidated into two generic helpers: `Invoke-ArrGet` and `Invoke-ArrPut`.
  API version is stamped onto each config hashtable at startup.
- Folder size calculation deferred to display time in all three scanners.
- Lidarr fuzzy-match lookup pre-computed as a hashtable at library load time.
- `Test-TitleMatch` inline scriptblock promoted to a named global function.
- `Normalize-Path` double `TrimEnd` consolidated to a single call.

---

## [0.4.0] - 2026-05-17

### Added
- **Lidarr Folder Renamer (Tool 4)** -- renames artist folders to `{Artist Name}`
  format and updates Lidarr paths via API. Includes Dry Run and Live Rename modes,
  conflict detection, and API rollback on failure.

### Changed
- Sonarr Tagger renamed to **Sonarr Folder Renamer** throughout (tool name, log
  prefix, menu label, code).
- Menu renumbered: Sonarr Renamer=2, Radarr Renamer=3, Lidarr Renamer=4,
  Orphan Scanner=5, Full Run=6, Exit=7.
- Full Run updated to include Lidarr Folder Renamer.

---

## [0.3.0] - 2026-05-16

### Added
- **Radarr Folder Renamer (Tool 3)** -- renames movie folders to TRaSH Guides
  format. Supports Minimum (`{Movie CleanTitle} ({Release Year})`) and Plex
  (`... {imdb-{ImdbId}}`) formats. Includes soft-match logic to skip folders
  that differ only in separator style.
- Conflict detection and API rollback for both Sonarr and Radarr renamers.

---

## [0.2.0] - 2026-05-15

### Added
- **Orphan Scanner (Tool 2)** -- scans library paths and cross-references against
  each `*arr` app. Categorises folders as NOT IN ARR (high confidence), NEEDS REVIEW
  (medium), or NAME MATCHED (low). Optional interactive delete with queue-and-confirm
  flow.
- **Full Run (Tool 3 at the time)** -- runs Sonarr Renamer then Orphan Scanner.

---

## [0.1.0] - 2026-05-14

### Added
- Initial release.
- **FolderBoy Cleaner (Tool 1)** -- scans library paths for folders containing no
  recognized media files. Dry Run and Live Delete modes. Configurable presets and
  Custom mode. Extension tally for non-media files found in flagged folders.
- **Sonarr Folder Tagger (Tool 2)** -- renames series folders to
  `{Series TitleYear} {imdb-{ImdbId}}` format and updates Sonarr paths via API.
- Config file system with example template and gitignore.
- Log files written to `Logs\` subfolder with timestamps.
