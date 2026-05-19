# Changelog

All notable changes to FolderBoy are documented here.

Format follows [Keep a Changelog](https://keepachangelog.com/en/1.0.0/).

---

## [Unreleased]

### Planned
- Scheduled / unattended execution support (Windows Task Scheduler)
- Radarr orphan scanner improvements for libraries with parenthetical folder suffixes
- Media file renaming (FLAC/MP3 cleanup within album folders)
- Duplicate media detector (Tool 2)

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
