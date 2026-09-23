# Deliverable 6: High-Level Change Log

Date: 23 September 2026. Prepared with OpenAI Codex for team review.

## What Changed and Why

| Change | Why it was needed | Implementation / evidence |
|---|---|---|
| Equal-listing price aggregation | Previously each monthly observation had a vote in the price median, even though the listing count used distinct IDs. This did not match the intended typical-listing comparison. | File 06 and `build_listing_quarters()` now take a within-listing quarterly median first, then a median across eligible listings. |
| Explicit geographic review policy | Some IDs have different SA2 codes within a quarter. Selecting one without evidence would conceal uncertainty. | Preserve all rows; flag and exclude 36 ambiguous listing-quarters from spatial comparisons. Detailed local review CSV and aggregate summary are saved. |
| Separate weighting and exclusion evidence | Both changes can move results, and attributing all movement to weighting would be misleading. | `week10_median_method_comparison.csv` contains old pooled, equal-listing-before-review and final medians. |
| Central headline corrected | A whole-period median of monthly rows also overweighted listings with more observations. | One period median per eligible Central listing, then an overall median; unpriced listings stay in counts, not price estimates. |
| Shared visible configuration | Paths, study dates, chosen area, chart settings and database table names were repeated. | `R/pipeline_config.R`; relative paths only. |
| Reusable pure helper functions | Key checks, missing-safe medians, quarter mapping and join rules should be independently testable. | `R/helpers/integration_helpers.R`, without file writes or network calls. |
| Executable input/join assertions | Printed observations and comments did not enforce the expected structure. | Reject duplicate listing-months, duplicate area-quarter keys, invalid prices/dates, parse errors and unsafe join expansion. Allow legitimate missing bedroom categories in detail. |
| Safer upstream script | `rm(list = ls())` cleared unrelated objects in the user's R session. Missing files failed later with less context. | Removed global clearing from file 02 and added required-file/output-directory checks without altering its cleaning decisions. |
| Safer cached API use | A key was required even when all coordinates were cached, and a global variable could appear during screen sharing. | File 05 only requires a key for uncached requests, reads it within the request function and suppresses token-bearing request warnings. Duplicate cache keys are rejected. |
| Atomic SQLite rebuild | Errors should not leave half-updated tables or an open connection. Identifier types must survive CSV import. | File 07 uses a transaction, explicit character IDs, unique indexes, `on.exit()` cleanup, SQL/R parity and database integrity checks. |
| Reproducible validation and execution | The tutor needs a demonstrable sanity check, and teammates need an unambiguous command. | 22 fixture tests, 4 database safety tests, 11 independent output checks in file 09, and offline runner `R/10_run_week10.R`. |
| Updated figures and documentation | Old descriptions could continue to imply snapshot weighting or outdated counts. | Regenerated PNG/PDF charts with method/exclusion captions; updated README, Week 9 notes and the nine-section design document. |

## Effect on the Results

| Measure | Before | Current |
|---|---:|---:|
| Monthly Airbnb rows retained | 28,795 | 28,795 |
| Explicit listing-quarter table | Not stored | 10,355 rows |
| Listing-quarters flagged with multiple SA2s | Not excluded | 36, representing 108 monthly rows |
| Airbnb area-quarter keys used in comparison | 511 | 510 |
| Matched area-quarter rows | 408 | 408 |
| Airbnb-only area-quarter keys | 103 | 102 |
| Central whole-period median nightly price | $240 (monthly observations) | $237 (equal eligible listings) |
| Central whole-period priced listings | Not explicitly reported | 151 |
| SQLite tables | 6 | 7 |

The weighting-only sensitivity changes 244 of 505 area-quarter medians that previously had a price. Geographic review changes a further 12 medians numerically relative to that intermediate method; a separate area-quarter disappears because no eligible listings remain. These counts describe different checks and must not be added as if they were distinct affected areas.

For Central in April-June 2026, the old pooled median is $253, the weighting-only median is $237, and the final median after excluding ambiguous listing-quarters is $253. Returning to the old numerical value does not mean the new method still pools repeated rows. The intermediate calculation is retained to make that distinction auditable.

## Sanity Check to Demonstrate

Toy example: A = $100 in three months; B = $300 in one month. The old pooled median is $100. One representative price per listing gives median($100, $300) = $200. This is tested automatically, including the case where repeated monthly prices are added.

Real example: Central, April-June 2026. Calculate `253 - 537 / 7 = 176.2857143`, then compare with `sanity_example$saved_gap`.

## What Was Retained

Pooja's raw-data cleaning decisions and the monthly observations are preserved. The SA2 2019 layer, source data, quarterly alignment, `ALL/ALL` tenancy selection, inner join and existing chart style remain. Missing prices have not been filled. Existing filenames are retained for compatibility. No new package or lockfile update was required.

## Verification Completed Locally

- All 22 aggregation/validation fixture tests passed.
- All 4 SQLite safety tests passed, including deliberate failure and rollback on temporary copies only.
- All 11 independent saved-output sanity checks passed.
- The SQL join agrees with the R join and SQLite reports an intact database.
- A cached geography rebuild succeeded with the API key removed from the test process; it made no new API requests and left no global `api_key` variable.
- Repeating the offline pipeline produced byte-identical CSV outputs. PDF creation metadata may change on export even when chart content is the same.
- Both regenerated PNG charts were visually checked for readable labels, units, exclusions and unclipped content.
- `git diff --check` passed. Production R code contains no personal absolute paths, `setwd()`, global workspace clearing or embedded package installation.

This verification does not constitute another team member's review, a live re-download of original sources or a successful package restore on a new computer.

## Lecture and Requirement Mapping

| Deliverable 6 requirement | Evidence to show |
|---|---|
| Review code against coding practices | This log, design principles section 6, configuration/helper files |
| Record high-level changes and reasons | The change table above |
| Give a sanity-check example | Fixture A/B example, `sanity_example`, `sanity_checks` |
| AI-created design document covering inputs, outputs, steps, strategies and AI name | `Week_10_Design_Principles.md`, sections 2, 3, 4, 6 and 9 |
| Ensure intentions, document and code agree | Equal-listing tests; independent recalculation; SQL/R agreement; updated captions and results |

The LEARN instructions list five substantive deliverable bullets, not nine separate assessed tasks. The design document is organised into nine sections for clarity. There is no claim that lab booking, attendance or team approval has already happened.
