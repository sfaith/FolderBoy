# FolderBoy Test Checklist
Version: 0.4.5 | Updated: 2026-05-17

Check off each item as you test it. Note any unexpected output in the space provided.

---

## 1. Startup & Config Validator

- [ ] **1.1** Normal startup — validator runs and shows all green for enabled apps
- [ ] **1.2** Disable one app (`Enabled = $false`) — validator shows Disabled, tools skip it gracefully
- [ ] **1.3** Introduce a typo in an API key — validator shows `[FAIL]` for that app's API check
- [ ] **1.4** Point a path to a nonexistent location — validator shows `[FAIL]` for that path
- [ ] **1.5** Remove `Paths` from one app config block — validator fetches from API and shows resolved paths
- [ ] **1.6** Restore config to normal — all checks pass, all green

Notes:
```

```

---

## 2. Library Health Dashboard

- [ ] **2.1** On startup, dashboard shows correct library counts for all three apps
- [ ] **2.2** After running Orphan Scanner, dashboard updates with orphan counts
- [ ] **2.3** Orphan counts show yellow when > 0, green when 0
- [ ] **2.4** API unreachable (stop an app temporarily) — dashboard shows red for that app
- [ ] **2.5** Return to menu after each tool — session log and dashboard both update correctly

Notes:
```

```

---

## 3. FolderBoy Cleaner

- [ ] **3.1** Dry Run — TV Shows — 0 folders flagged, correct path shown
- [ ] **3.2** Dry Run — Movies — 0 folders flagged, all 5 paths scanned
- [ ] **3.3** Dry Run — Music — 0 folders flagged, correct path shown
- [ ] **3.4** Dry Run — All Libraries — runs all three presets in sequence, overall summary matches individual totals
- [ ] **3.5** Create a test folder with only `.nfo` and `.jpg` files in a library path — Dry Run shows `[WOULD DELETE]`
- [ ] **3.6** Live Delete — delete the test folder from 3.5 — shows `[DELETED]`, folder gone from disk
- [ ] **3.7** Session log entry shows correct library label and path summary after each run
- [ ] **3.8** Custom preset — enter extensions manually, scan a custom path — works correctly

Notes:
```

```

---

## 4. Sonarr Folder Renamer

- [ ] **4.1** Dry Run — 0 renames, 564 already tagged, 3 no IMDb ID — matches baseline
- [ ] **4.2** `SuppressMissing = $true` — MISSING entries disappear from output, count still shown in summary
- [ ] **4.3** `SuppressMissing = $false` — MISSING entries appear normally
- [ ] **4.4** Create a test series folder without an `{imdb-}` tag that matches a Sonarr title — Dry Run shows `[WOULD RENAME]`
- [ ] **4.5** `[MISMATCH]` case — rename a folder so it doesn't match Sonarr title, verify it's skipped with explanation

Notes:
```

```

---

## 5. Radarr Folder Renamer

- [ ] **5.1** Dry Run — Minimum format — 0 renames, 4193 already correct — matches baseline
- [ ] **5.2** Dry Run — Plex format — verify `{imdb-}` tags appear in WOULD RENAME output
- [ ] **5.3** `SuppressMissing = $true` — 42 missing entries suppressed, count still in summary
- [ ] **5.4** `SuppressMissing = $false` — 42 missing entries visible
- [ ] **5.5** Verify `School of Rock` → `The School of Rock` no longer appears (already renamed in earlier session)

Notes:
```

```

---

## 6. Lidarr Folder Renamer

- [ ] **6.1** Dry Run — `SuppressMissing = $false` — 285 missing entries visible, 8 would rename (pre-T.I. fix) or 4 (post-fix)
- [ ] **6.2** Dry Run — `SuppressMissing = $true` — 285 missing entries suppressed, count still in summary
- [ ] **6.3** Verify T.I. folder no longer flagged for rename (trailing period fix)
- [ ] **6.4** Verify `Dinosaur Jr`, `Louis C.K`, `Run-D.M.C` also not flagged

Notes:
```

```

---

## 7. Orphan Scanner

- [ ] **7.1** Scan Only — All Libraries — matches baseline: 12 Radarr, 0 Sonarr, 0 Lidarr
- [ ] **7.2** Scan Only — Radarr only — 12 orphans, Sonarr/Lidarr show "Not scanned"
- [ ] **7.3** Scan Only — Sonarr only — 0 orphans
- [ ] **7.4** Scan Only — Lidarr only — 0 orphans
- [ ] **7.5** Create exactly ONE test orphan folder — run Scan + Delete — verify "REVIEWING 1 ITEMS" (not 4)
- [ ] **7.6** Create exactly TWO test orphan folders — run Scan + Delete — verify "REVIEWING 2 ITEMS"
- [ ] **7.7** Scan + Delete — choose category 1 (NOT IN ARR only) — verify correct items shown
- [ ] **7.8** Scan + Delete — choose category 3 (ALL) — verify NAME MATCHED items included
- [ ] **7.9** Scan + Delete — queue items then choose Q to quit review — verify nothing deleted
- [ ] **7.10** Scan + Delete — queue items, reach confirmation, type anything other than YES — verify aborted
- [ ] **7.11** Disabled app scoped scan — pick "Lidarr only" with Lidarr disabled — shows skipped message

Notes:
```

```

---

## 8. Full Run

- [ ] **8.1** Full Run — all tools Dry Run — runs Sonarr → Radarr → Lidarr renamers then Orphan Scanner without errors
- [ ] **8.2** Full Run — disabled app in config — skipped gracefully, other tools run normally
- [ ] **8.3** Session log after Full Run — shows entries for all tools that ran

Notes:
```

```

---

## 9. Log Files

- [ ] **9.1** All logs written to `Logs\` subdirectory, not script root
- [ ] **9.2** Log filenames use correct prefixes: `FolderBoy_`, `FolderBoy_SonarrRenamer_`, `FolderBoy_RadarrRenamer_`, `FolderBoy_LidarrRenamer_`, `FolderBoy_Scanner_`
- [ ] **9.3** Log content matches console output for a sample run

Notes:
```

```

---

## 10. Edge Cases

- [ ] **10.1** Run any tool immediately after startup without waiting — no errors
- [ ] **10.2** Press any key to return to menu repeatedly — no degradation or state issues
- [ ] **10.3** Run Cleaner Live Delete on a folder that was already deleted between scan and delete — handles gracefully
- [ ] **10.4** Network share unavailable during scan — `[WARN] Path not found` shown, other paths continue
- [ ] **10.5** Very long folder path (>80 chars) — output formatting stays readable, no truncation errors

Notes:
```

```

---

## Summary

| Section | Total | Passed | Failed | Skipped |
|---|---|---|---|---|
| 1. Startup & Config | 6 | | | |
| 2. Dashboard | 5 | | | |
| 3. Cleaner | 8 | | | |
| 4. Sonarr Renamer | 5 | | | |
| 5. Radarr Renamer | 5 | | | |
| 6. Lidarr Renamer | 4 | | | |
| 7. Orphan Scanner | 11 | | | |
| 8. Full Run | 3 | | | |
| 9. Log Files | 3 | | | |
| 10. Edge Cases | 5 | | | |
| **Total** | **55** | | | |