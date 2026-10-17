# Deliverable 6: Change Log

Christchurch Rental Market Analysis | DATA201/422 | Updated 27 September 2026

A high-level record of what we changed in each file and why, after reviewing our code against the Week 9 coding-practices lectures. It combines Pooja's changes to the cleaning scripts (01–03) and Sahil's changes to 02 and 05–10. How the pipeline fits together is described in [Deliverable_6_Design_Principles.md](Deliverable_6_Design_Principles.md).

## Summary by file

| File | Changed by | Summary |
|---|---|---|
| `00_setup_packages.R` | — | No changes. |
| `01_airbnb_prepare.R` | Pooja | Paths defined once; printed inspections replaced by validation checks; output checks added. |
| `02_airbnb_combine.R` | Pooja | Input, filtering, snapshot, missing-value and duplicate checks made executable; global workspace clearing removed. |
| `03_tenancy_prepare.R` | Pooja | Renamed from `03_tenancy_inspect.R`. Structure, category, bond and rent checks made executable; type and structure checks after cleaning. |
| `04_airbnb_summary.R` | Pooja | Renamed from `04_summary_statistics_airbnb_clean.R`; no code changes. |
| `05_query_geography.R` | Sahil | Safer cached API use. |
| `06_integrate_rental_data.R` | Sahil | Equal-listing price weighting; ambiguous geography flagged and excluded; join assertions. |
| `07_build_database.R` | Sahil | Atomic SQLite rebuild with type and integrity checks. |
| `08_week9_plots.R` | Sahil | Charts regenerated with method and exclusion captions. |
| `09_validate_pipeline.R` | Sahil | independent validation of saved outputs. |
| `10_run_week10.R` | Sahil | one-command offline runner. |
| `pipeline_config.R`, `helpers/integration_helpers.R` | Sahil | shared configuration and testable helper functions. |

---

## 01_airbnb_prepare.R

| What we changed | Why |
|---|---|
| Input and output paths stored once in variables at the top | Keeps parameters visible and avoids repeating paths |
| Added a required-column check on the raw file | Fails early if the source structure changes |
| Added checks that the Christchurch filter worked and that the snapshot is June 2026 | Prevents empty or incorrect filtering and the wrong snapshot being used |
| Added validation of prices, minimum nights, other numeric fields, categorical fields and duplicate IDs | Stops invalid values entering the pipeline instead of only printing them |
| Confirmed `license` is removed, and made the final QA summary a pass/fail check | Verifies the cleaning decision actually happened |
| Reduced console output: only columns with missing values are shown, coordinate issues are shown as a count plus a sample, and a zero-review summary was added | Keeps the investigation readable and supports keeping missing review fields |
| Renamed `high_price_listings` to `top_price_listings`; removed a duplicate license check | The name shows the listings are inspected, not removed; avoids checking the same thing twice |
| Output folder created if missing; clear success/error message after saving | Prevents avoidable save failures and confirms the file was written |

## 02_airbnb_combine.R

| What we changed | Why |
|---|---|
| Input and output paths defined once; checks that all nine monthly files exist (Pooja, Sahil) | Stops the analysis silently using an incomplete study period |
| Checks that all monthly files share the same column structure | Ensures the files can be safely combined |
| Checks each month has Christchurch records and no other districts after filtering, and has the correct `month_year` | Only intended records and correct snapshot labels enter the combined data |
| Printed row-count comparisons replaced by assertions (after combining and after removing columns) | Combining and dropping columns must not lose or add observations |
| Missing-value patterns are now tested: prices 100% missing only in Dec 2025 – Feb 2026, and missing `last_review` / `reviews_per_month` only on zero-review listings | Makes the documented findings reproducible; the script stops if the data change |
| Checks `license` is fully missing before removing it, and that all intended columns were removed | The removal decision is only applied if its assumption still holds |
| Assertions for no duplicate rows and at most one record per listing per month; repeated IDs across months allowed | Separates legitimate monthly repetition from real duplication |
| Final check that all nine snapshots remain, and that the output file was written | Cleaning must not change the study-period coverage |
| Removed `rm(list = ls())` (Sahil) | It cleared unrelated objects from the user's R session |

## 03_tenancy_prepare.R

| What we changed | Why |
|---|---|
| Output paths stored in variables; checks that the input file and all required columns exist | Keeps paths in one place and gives a clear error before `read_csv()` fails |
| Checks that `TimeFrame` is a Date with no missing values, and that numeric `Location Id`s have six digits (`-99` and `NULL` codes left unchanged) | Protects the quarterly structure and documented ID format |
| Checks Dwelling Type categories, and that `Number Of Beds` stays as text with `ALL` and `5+` | Prevents meaningful categories being converted to numbers |
| Combined check for missing or negative bond values | Makes the bond-quality assumptions testable |
| Checks for unexpected text in rent columns before conversion, and for the shared `NULL` pattern across the four main rent measures | Prevents unexpected values being silently turned into NA |
| Check that Log Std Dev Weekly Rent has no negatives, while genuine zeros are kept | Protects the decision to keep valid zeros |
| Assertions that cleaning keeps the same rows, columns and unique reporting units, and that rent columns are numeric afterwards; `rent_cols` defined once | Cleaning should only convert values and types |
| Check that the study-period subset contains exactly Oct 2025, Jan 2026 and Apr 2026; output folder created if missing; both output files confirmed | Makes the period restriction testable and confirms the outputs were produced |

## 04_airbnb_summary.R

Renamed from `04_summary_statistics_airbnb_clean.R`; no code changes. It remains an exploratory summary of the monthly observations.

## 05_query_geography.R

| What we changed | Why |
|---|---|
| API key required only for uncached requests, read inside the request function; token-bearing request warnings suppressed; duplicate cache keys rejected | A key was needed even when everything was cached, and a global key variable could appear while screen sharing |

## 06_integrate_rental_data.R (with `helpers/integration_helpers.R`)

| What we changed | Why |
|---|---|
| Equal-listing price aggregation: a within-listing quarterly median first, then a median across eligible listings (`build_listing_quarters()`) | Monthly observations were each getting a vote, which did not match our intended typical-listing comparison |
| Listings in more than one SA2 within a quarter are flagged and excluded from spatial comparisons (36 listing-quarters); all rows preserved; review CSV and summary saved | Picking one area without evidence would hide uncertainty |
| Central whole-period headline recalculated as one median per listing, then an overall median | A median of monthly rows overweighted listings with more observations |
| Saved `week10_median_method_comparison.csv` with old, weighting-only and final medians | Separates the effect of weighting from the effect of geographic exclusions |
| Assertions rejecting duplicate listing-months, duplicate area-quarter keys, invalid prices/dates, parse errors and unsafe join expansion | Printed observations and comments did not enforce the expected structure |

## 07_build_database.R

| What we changed | Why |
|---|---|
| Rebuild in a transaction with `on.exit()` cleanup; explicit character IDs; unique indexes; SQL-vs-R join comparison and integrity check | Errors should not leave half-updated tables or an open connection, and IDs must keep their type through CSV import |

## 08_week9_plots.R

| What we changed | Why |
|---|---|
| Charts regenerated from saved summaries with captions stating the equal-listing method and exclusions | Old charts implied snapshot weighting and outdated counts |

## 09_validate_pipeline.R

| What we changed | Why |
|---|---|
| Independently recomputes every listing-quarter and area-quarter median in base R, and checks counts, keys, arithmetic and source fingerprints (11 checks) | Stronger evidence than "the script ran without an error" |

## 10_run_week10.R

| What we changed | Why |
|---|---|
| Runs the 22 fixture tests, 4 database safety tests, and stages 06–09 offline with one command | Teammates and the tutor need one clear, repeatable command |

## pipeline_config.R

| What we changed | Why |
|---|---|
| Study dates, SA2 layer, chosen area, chart settings, paths and table names defined in one shared file | These were repeated across scripts; follows the lecture's visible-parameters rule |

---

## Effect on the results

| Measure | Before | Current |
|---|---:|---:|
| Monthly Airbnb rows retained | 28,795 | 28,795 |
| Listing-quarter table | Not stored | 10,355 rows |
| Listing-quarters flagged with multiple SA2s | Not excluded | 36 (108 monthly rows) |
| Airbnb area-quarter keys used in comparison | 511 | 510 |
| Matched area-quarter rows | 408 | 408 |
| Airbnb-only area-quarter keys | 103 | 102 |
| Central whole-period median nightly price | $240 (monthly observations) | $237 (equal eligible listings) |
| SQLite tables | 6 | 7 |

These figures were confirmed by a full re-run on 28 September 2026 after merging, with all 22 fixture tests, 4 database tests and 11 saved-output checks passing. The tenancy detail table now has 27,212 rows and the tenancy area-quarter table 4,871 (Sahil's earlier run recorded 26,991 and 4,865). The matched comparison (408 rows) and all price results are unchanged. [Sahil to confirm why his tenancy counts were slightly lower: 27,212 is also what file 03 produced in Claudia's run on 25 September.]

## Decisions from the team review of files 01–04

| Finding | Decision |
|---|---|
| File 01 repeats June 2026, which file 02 already covers | Keep 01 as an exploratory script; it is not required before 02 |
| The tenancy output is named `tenancy_christchurch_…` but keeps national records | Keep the filename for compatibility; Christchurch coverage comes from the join in file 06 |
| Possible price outlier ($43,654/night) in the combined Airbnb data | **Open:** to be discussed in person |

## Sanity check example

**Toy example:** listing A = $100 in three months; listing B = $300 in one month. The old pooled median is $100. One representative price per listing gives median($100, $300) = $200, which is tested automatically.

**Real example:** Central, April–June 2026: $253 − $537 / 7 = $176.29 per night. Compare with `sanity_example$saved_gap`.

**AI use:** Sahil's changes were made with OpenAI Codex; Claudia used Claude to combine the documentation.
