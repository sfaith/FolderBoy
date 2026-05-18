# FolderBoy Test Checklist
Version: 0.4.6 | Updated: 2026-05-17

Check off each item as you test it. Note any unexpected output in the space provided.

**Legend:**
- `[x]` — Verified by automated logic tests (`FolderBoy_LogicTests.ps1`, 79/79 pass)
- `[c]` — Verified by code inspection (structure confirmed; needs live confirmation)
- `[ ]` — Needs live interactive testing

---

## 1. Startup & Config Validator

- [ ] **1.1** Normal startup — validator runs and shows all green for enabled apps
- [c] **1.2** Disable one app (`Enabled = $false`) — validator shows Disabled, tools skip it gracefully *(code: CF15 — "Disabled" label confirmed in dashboard and all tool guards)*
- [ ] **1.3** Introduce a typo in an API key — validator shows `[FAIL]` for that app's API check
- [ ] **1.4** Point a path to a nonexistent location — validator shows `[FAIL]` for that path
- [c] **1.5** Remove `Paths` from one app config block — validator fetches from API and shows resolved paths *(code: CF14 — `Resolve-ArrPaths` calls `rootfolder` endpoint confirmed)*
- [ ] **1.6** Restore config to normal — all checks pass, all green

Notes:
```

```

---

## 2. Library Health Dashboard

- [ ] **2.1** On startup, dashboard shows correct library counts for all three apps
- [c] **2.2** After running Orphan Scanner, dashboard updates with orphan counts *(code: CF7 — `DashboardCache[].Orphans` assignment after scan confirmed)*
- [ ] **2.3** Orphan counts show yellow when > 0, green when 0
- [ ] **2.4** API unreachable (stop an app temporarily) — dashboard shows red for that app
- [c] **2.5** Return to menu after each tool — session log and dashboard both update correctly *(code: CF16 — `Add-SessionEntry` function confirmed in all tool branches)*

Notes:
```

```

---

## 3. FolderBoy Cleaner

- [ ] **3.1** Dry Run — TV Shows — 0 folders flagged, correct path shown
- [ ] **3.2** Dry Run — Movies — 0 folders flagged, all 5 paths scanned
- [ ] **3.3** Dry Run — Music — 0 folders flagged, correct path shown
- [c] **3.4** Dry Run — All Libraries — runs all three presets in sequence, overall summary matches individual totals *(code: CF8, CF9 — All Libraries mode and `Invoke-CleanerScan` helper confirmed)*
- [ ] **3.5** Create a test folder with only `.nfo` and `.jpg` files in a library path — Dry Run shows `[WOULD DELETE]`
- [ ] **3.6** Live Delete — delete the test folder from 3.5 — shows `[DELETED]`, folder gone from disk
- [c] **3.7** Session log entry shows correct library label and path summary after each run *(code: CF16 — session log entry code confirmed in Cleaner branch)*
- [ ] **3.8** Custom preset — enter extensions manually, scan a custom path — works correctly

Notes:
```

```

---

## 4. Sonarr Folder Renamer

- [ ] **4.1** Dry Run — 0 renames, 564 already tagged, 3 no IMDb ID — matches baseline
- [c] **4.2** `SuppressMissing = $true` — MISSING entries disappear from output, count still shown in summary *(code: CF1 — `SonarrConfig.SuppressMissing` guard confirmed in renamer)*
- [c] **4.3** `SuppressMissing = $false` — MISSING entries appear normally *(code: CF1)*
- [ ] **4.4** Create a test series folder without an `{imdb-}` tag that matches a Sonarr title — Dry Run shows `[WOULD RENAME]`
- [ ] **4.5** `[MISMATCH]` case — rename a folder so it doesn't match Sonarr title, verify it's skipped with explanation

> **Note:** `Test-TitleMatch` was fixed in v0.4.6 — folders named with a year (e.g. `The Wire (2002)`) but no imdb tag now correctly match against the Sonarr title+year rather than producing a false `[MISMATCH]`. 4.5 should confirm a *genuinely* mismatched folder still gets skipped.

Notes:
```

```

---

## 5. Radarr Folder Renamer

- [ ] **5.1** Dry Run — Minimum format — 0 renames, 4193 already correct — matches baseline
- [ ] **5.2** Dry Run — Plex format — verify `{imdb-}` tags appear in WOULD RENAME output
- [c] **5.3** `SuppressMissing = $true` — 42 missing entries suppressed, count still in summary *(code: CF2 — `RadarrConfig.SuppressMissing` guard confirmed in renamer)*
- [c] **5.4** `SuppressMissing = $false` — 42 missing entries visible *(code: CF2)*
- [ ] **5.5** Verify `School of Rock` → `The School of Rock` no longer appears (already renamed in earlier session)

Notes:
```

```

---

## 6. Lidarr Folder Renamer

- [c] **6.1** Dry Run — `SuppressMissing = $false` — 285 missing entries visible, 4 would rename *(code: CF3 — `LidarrConfig.SuppressMissing` guard confirmed; trailing-period count reduction confirmed by logic tests)*
- [c] **6.2** Dry Run — `SuppressMissing = $true` — 285 missing entries suppressed, count still in summary *(code: CF3)*
- [x] **6.3** Verify T.I. folder no longer flagged for rename (trailing period fix) *(auto: LC1 — `T.I.` on disk and `T.I` on disk both treated as already-correct against artist name `T.I.`)*
- [x] **6.4** Verify `Dinosaur Jr`, `Louis C.K`, `Run-D.M.C` also not flagged *(auto: LC3, LC4, LC6, LC7 — all four already-correct cases pass; LA2, LA3, LA4 confirm clean name generation)*

Notes:
```

```

---

## 7. Orphan Scanner

- [ ] **7.1** Scan Only — All Libraries — matches baseline: 12 Radarr, 0 Sonarr, 0 Lidarr
- [c] **7.2** Scan Only — Radarr only — 12 orphans, Sonarr/Lidarr show "Not scanned" *(code: CF6 — `$Scope` parameter and "Not scanned" label confirmed)*
- [ ] **7.3** Scan Only — Sonarr only — 0 orphans
- [ ] **7.4** Scan Only — Lidarr only — 0 orphans
- [x] **7.5** Create exactly ONE test orphan folder — run Scan + Delete — verify "REVIEWING 1 ITEMS" (not 4) *(auto: OS1 — `@()` wrapping on `Sort-Object` result confirmed; single-item `.Count` returns 1)*
- [x] **7.6** Create exactly TWO test orphan folders — run Scan + Delete — verify "REVIEWING 2 ITEMS" *(auto: OS2)*
- [ ] **7.7** Scan + Delete — choose category 1 (NOT IN ARR only) — verify correct items shown
- [ ] **7.8** Scan + Delete — choose category 3 (ALL) — verify NAME MATCHED items included
- [ ] **7.9** Scan + Delete — queue items then choose Q to quit review — verify nothing deleted
- [ ] **7.10** Scan + Delete — queue items, reach confirmation, type anything other than YES — verify aborted
- [c] **7.11** Disabled app scoped scan — pick "Lidarr only" with Lidarr disabled — shows skipped message *(code: CF6 — scope guard and disabled-skip path confirmed)*

Notes:
```

```

---

## 8. Full Run

- [c] **8.1** Full Run — all tools Dry Run — runs Sonarr → Radarr → Lidarr renamers then Orphan Scanner without errors *(code: CF13 — `Invoke-LidarrFolderRenamer` call in Full Run branch confirmed)*
- [c] **8.2** Full Run — disabled app in config — skipped gracefully, other tools run normally *(code: CF15 — disabled-skip guards confirmed in all Full Run branches)*
- [ ] **8.3** Session log after Full Run — shows entries for all tools that ran

Notes:
```

```

---

## 9. Log Files

- [ ] **9.1** All logs written to `Logs\` subdirectory, not script root
- [x] **9.2** Log filenames use correct prefixes: `FolderBoy_`, `FolderBoy_SonarrRenamer_`, `FolderBoy_RadarrRenamer_`, `FolderBoy_LidarrRenamer_`, `FolderBoy_Scanner_` *(auto: LF1–LF5 — all five `Start-Log` calls confirmed with correct prefixes; LF6 — `Logs\` subdir path confirmed)*
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

| Section | Total | Auto `[x]` | Code `[c]` | Live `[ ]` |
|---|---|---|---|---|
| 1. Startup & Config | 6 | 0 | 2 | 4 |
| 2. Dashboard | 5 | 0 | 2 | 3 |
| 3. Cleaner | 8 | 0 | 2 | 6 |
| 4. Sonarr Renamer | 5 | 0 | 2 | 3 |
| 5. Radarr Renamer | 5 | 0 | 2 | 3 |
| 6. Lidarr Renamer | 4 | 2 | 2 | 0 |
| 7. Orphan Scanner | 11 | 2 | 2 | 7 |
| 8. Full Run | 3 | 0 | 2 | 1 |
| 9. Log Files | 3 | 1 | 0 | 2 |
| 10. Edge Cases | 5 | 0 | 0 | 5 |
| **Total** | **55** | **5** | **16** | **34** |

`[x]` = logic test verified · `[c]` = code inspection confirmed · `[ ]` = needs live testing
