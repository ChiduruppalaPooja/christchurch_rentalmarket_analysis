# Coding Practices

This document describes the conventions the project follows: how files and objects are named, how the code and data are organised, how packages are managed, and the rules used when cleaning data. It also records the code review the team carried out against the Week 9 coding-practices lectures (Deliverable 6).

For project setup and branch management, see [project_documentation.md](project_documentation.md).

---

## 1. Naming conventions

### Files

| Type | Convention | Examples |
|---|---|---|
| Pipeline scripts | Two-digit run-order number, then a verb/noun description in `snake_case` | `02_airbnb_combine.R`, `05_query_geography.R` |
| Helper scripts | `<area>_helpers.R` in `R/helpers/` | `integration_helpers.R`, `automation_helpers.R` |
| Tests | `test_<what is tested>.R` in `tests/` | `test_integration.R`, `test_database_transaction.R` |
| Raw Airbnb files | `listings_YYYY_MM.csv` | `listings_2026_07.csv` |
| Processed data | `<source>_<place>_<period>_<state>.csv` | `airbnb_christchurch_oct2025_jun2026_clean.csv` |
| Output tables and figures | Prefixed with the deliverable week that introduced them | `week9_join_quality.csv`, `week11_monthly_prices.png` |
| Automated-run folders | `<start>_to_<end>` | `output/week11/2025-10_to_2026-08/` |

The `week9_` output names were kept after the Week 10 corrections so that existing links keep working, even though their contents now use the corrected method.

### Objects and columns

- **`snake_case`** for objects, functions and created columns: `listings_chch`, `build_listing_quarters()`, `month_year`.
- **Functions are verbs**: `assert_unique_keys()`, `validate_download()`, `summarise_listing_quarters()`, `join_market_tables()`.
- **Names state the grain of a table**, i.e. what one row represents: `fact_airbnb_listing_month`, `fact_airbnb_listing_quarter`, `fact_airbnb_sa2_quarter`.
- **Database tables** use `dim_` for lookup tables and `fact_` for measurement tables.
- **Names describe what happens to the data.** For example, `high_price_listings` was renamed `top_price_listings` because those listings are inspected, not removed.
- **Source column names are kept as supplied** in the raw-data stages (for example tenancy's `` `Location Id` ``) and renamed to `snake_case` only when building the integration tables (`sa2_code`, `number_of_beds`).

### Data types

- Listing and host IDs are read as **character**. Very large IDs lose precision or turn into scientific notation if read as numbers.
- SA2 codes and `Location Id` are character so leading digits and special codes are preserved.
- Dates and prices are given explicit parsers (`col_date()`, `col_double()`) rather than relying on guessing.

---

## 2. Organisation

- **Raw, processed and output data are kept separate.** `data/raw/` is never edited; every change is made by a script and written to `data/processed/` or `output/`.
- **One job per script**, numbered in the order they run. Each script reads its inputs from files rather than relying on objects left over in the R session.
- **Reusable logic lives in `R/helpers/`.** The helpers are small, testable functions.
- **Settings are defined once.**
  - `R/pipeline_config.R` holds the study dates, SA2 layer, Christchurch Central code, chart settings, file paths and database table names.
  - `config/automation.R` holds the period and folders for the automated run; change the end month here, not in each script.
  - `config/airbnb_sources.csv` holds the verified download links.
  - Each cleaning script defines its input and output paths once, at the top.
- **Relative paths only.** Paths are relative to the project root. No `setwd()` and no personal computer paths. The runners check that the `.Rproj` file is present before starting.
- **No workspace clearing.** `rm(list = ls())` was removed because it deleted unrelated objects from the user's R session.
- **Credentials never appear in code.** The API key is read from `.Renviron` with `Sys.getenv()`, and only when an uncached request is needed.

---

## 3. Checks and validation

Findings that used to be printed or written in comments are now checks that stop the script when they fail. This means the documented assumptions are re-tested every time the code runs.

| Check style | Use |
|---|---|
| `stop("…")` | Something is wrong and continuing would give an incorrect result (missing file, missing columns, duplicate keys, invalid prices, a join that would multiply rows) |
| `warning("…")` | A documented finding has changed and should be reviewed (for example, the months with fully missing prices are no longer December–February) |

Examples:

- the input files and required columns exist;
- all monthly Airbnb files share the same columns;
- the combined row count equals the sum of the monthly row counts, and removing columns does not change it;
- no listing appears twice in the same month and no rows are completely duplicated;
- prices are non-negative and finite, or `NA`;
- join keys are unique on both sides before joining, and each output file was actually written.

### Tests

| Test file / script | What it covers |
|---|---|
| `tests/test_integration.R` | 22 small hand-checkable examples, such as the equal-listing weighting example |
| `tests/test_database_transaction.R` | 4 database safety tests, including that a failed rebuild rolls back |
| `tests/test_automation.R` | 23 tests of the automated runner (month validation, downloads, caching, failure recovery) |
| `R/09_validate_pipeline.R` | 11 checks that recalculate the saved results independently in base R |

A passing test shows the code follows the stated rules. It does not show that the source data are complete.

### Sanity-check examples

- **Toy example.** Listing A costs $100 in three months and listing B costs $300 in one month. Pooling the monthly rows gives a median of $100. The intended answer is median($100, $300) = $200, and this is tested automatically.
- **Real data.** Christchurch Central, April–June 2026: $253 per night (Airbnb) − $537 per week ÷ 7 (tenancy) = $176.29 per night. The expected and saved values are stored side by side in `week10_sanity_example.csv`.

---

## 4. Cleaning practices

### General principles

1. **Never edit raw data.** All cleaning is done in R so that it can be re-run.
2. **Investigate before deciding.** Each issue (missing values, duplicates, odd codes, outliers) is inspected before any action is taken.
3. **Do not invent values.** Missing values stay as `NA`; nothing is imputed or replaced with zero.
4. **Do not delete rows just because some fields are missing.**
5. **Tell source-level problems apart from errors we introduced**, for example prices missing in the original files rather than lost during filtering.
6. **Treat structural missingness as meaningful.** A listing with no reviews has no last-review date.
7. **Do not impose relationships the source does not support**, for example `Total Bonds = Active + Closed`.
8. **Remove columns for a reason** (no information, redundant, or not needed for the analysis), never just because they have few distinct values.
9. **Repeated observations over time are not duplicates.** A listing that appears in every monthly snapshot is legitimate; only a repeat *within* the same month is an error.
10. **Make each decision a check.** A cleaning step is only applied if the check that justifies it still passes.

### Airbnb decisions (`02_airbnb_combine.R`)

| Issue | Decision |
|---|---|
| `price` entirely missing in the Dec 2025, Jan 2026 and Feb 2026 source files; a few percent missing in other months | Kept as `NA`. Not imputed. |
| `minimum_nights` missing on a few records | Kept as `NA`. Not imputed. |
| `last_review` and `reviews_per_month` missing only where `number_of_reviews = 0` | Kept as `NA`. Not converted to zero. The relationship is tested. |
| `license` 100% missing | Column removed (checked to be fully missing first) |
| `host_name`, `name` | Removed. Not needed for the quantitative comparison. |
| `neighbourhood_group` | Removed. Redundant after filtering to Christchurch City. |
| Very high prices | Inspected, not removed automatically |
| Same listing ID in several months | Kept |

### Tenancy decisions (`03_tenancy_prepare.R`)

| Issue | Decision |
|---|---|
| Rent columns contain the text `"NULL"` | Converted to `NA`, then to numeric. Checked first that no other unexpected text exists. |
| The four main rent measures are `NULL` on the same records | The shared pattern is checked, not assumed |
| `Location Id` codes `-99` and `NULL` | Kept unchanged, since their meaning cannot be established from the data. They do not match any SA2 code, so they drop out at the join. |
| Numeric `Location Id` values | Checked to be six digits |
| `Number Of Beds` contains `ALL` and `5+` | Kept as text so these categories keep their meaning. Missing values kept. |
| Zeros in `Log Std Dev Weekly Rent` | Kept as genuine values. Negatives rejected. |
| `Total ≠ Active + Closed` bonds for most rows | Source values kept as supplied |
| Row count, column count and reporting-unit uniqueness | Asserted to be unchanged by cleaning |

Results of applying these rules are in [D4](../Reports/D4.md).

---

## 5. Integration practices

- **Summarise to the same grain before joining.** A direct join of listing rows to tenancy category rows would be many-to-many and duplicate data. Both sides are summarised to one row per `sa2_code + comparison_quarter` first.
- **One listing, one vote.** Price is calculated per listing per quarter, then across listings.
- **Flag uncertainty instead of guessing.** Listings in more than one SA2 within a quarter are flagged and excluded from area comparisons; no majority vote is used.
- **Keep what does not match.** Unmatched keys from both sides are saved to review tables.
- **Rebuild the database safely.** SQLite is rebuilt inside a transaction, the connection is always closed with `on.exit()`, and the SQL join is compared with the R join.

---

## 6. Automation practices

- **Orchestrate existing scripts rather than rewriting them.** `run_pipeline.R` sources the numbered scripts in order and passes run-specific settings through `options(rental.pipeline.overrides = …)`.
- **Skip work that has not changed.** A stage is reused only when its inputs, code, settings, package versions and outputs all match the last run.
- **Check before trusting a download.** New files are checked as CSVs and checksummed before they are moved into `data/raw/`.
- **Separate outputs per run** so that earlier deliverable results are not overwritten.
- **Report from saved results**, and only report success after all tests have passed.

See [automation_guide.md](automation_guide.md) for the full walkthrough.

---

## 7. Package versions (`renv.lock`)

The project uses `renv` so that everyone runs the same package versions.

- **`renv.lock`** records every package and its exact version, plus the R version (4.5.2). It is committed to Git.
- **`renv/library/`** is the project's local package library. It is not committed (`.gitignore`).
- **`.Rprofile`** activates `renv` automatically whenever the project opens.

| When | Command |
|---|---|
| Setting up the project, or after someone else changes `renv.lock` | `renv::restore()` |
| After adding or updating a package that the code now needs | `renv::snapshot()`, then commit the updated `renv.lock` |
| Checking whether the library and lockfile agree | `renv::status()` |

Practices:

- Restoring packages is a **setup step**, not part of the analysis. `00_setup_packages.R` only loads packages, and `run_pipeline.R` stops with a message to run `renv::restore()` if a package is missing. Neither installs anything.
- Do not update `renv.lock` silently. The D6 and D7 code changes did not modify the lockfile, and the automated runner never changes it.
- If a locked version will not install on your computer (for example the `data.table` compile issue on macOS), say so to the team before committing a changed lockfile.

---

## 8. Deliverable 6 code review

In Deliverable 6 the team reviewed the code against the Week 9 coding-practices lectures. These are the main changes and why they were made.

| File | What changed | Why |
|---|---|---|
| `01_airbnb_prepare.R` | Paths defined once; printed inspections turned into checks (required columns, Christchurch filter, June snapshot, prices, minimum nights, IDs); `high_price_listings` renamed `top_price_listings`; duplicate license check removed; output folder created and file confirmed | Fail early and visibly; names that match what the code does |
| `02_airbnb_combine.R` | Checks that all monthly files exist and match; row-count assertions; missing-value patterns tested; license checked before removal; duplicate checks; final snapshot check; `rm(list = ls())` removed | Make the documented findings executable; stop clearing the user's session |
| `03_tenancy_prepare.R` | Renamed from `03_tenancy_inspect.R`; input and column checks; `TimeFrame`, `Location Id`, category, bond and rent checks; asserts cleaning keeps rows, columns and keys; study-period check | Make the tenancy assumptions testable |
| `04_airbnb_summary.R` | Renamed from `04_summary_statistics_airbnb_clean.R`; no code changes | Consistent naming |
| `05_query_geography.R` | API key needed only for uncached requests; key read inside the request function; duplicate cache keys rejected | Avoid needing (and exposing) the key when everything is cached |
| `06_integrate_rental_data.R` + `helpers/integration_helpers.R` | Equal-listing price weighting; ambiguous geography flagged and excluded; Central headline recalculated per listing; method-comparison table; key and join assertions | The code previously gave each monthly row a vote, which did not match the team's intention |
| `07_build_database.R` | Transaction-based rebuild with `on.exit()` cleanup, explicit ID types, unique indexes, SQL-vs-R comparison | No half-built tables or open connections after an error |
| `08_week9_plots.R` | Captions state the method and exclusions | Charts should match the corrected method |
| `09_validate_pipeline.R` | New: independent base-R recalculation of saved results | Stronger evidence than "the script ran" |
| `10_run_week10.R` | New: one-command offline runner for D6 | One repeatable command for the team and tutor |
| `pipeline_config.R` | New: shared settings in one file | Parameters were repeated across scripts |

### Effect on the results

After the D6 corrections, the integration outputs are:

- 36 listing-quarters flagged with more than one SA2 (108 monthly rows);
- 510 Airbnb area-quarter keys used in the comparison;
- 408 matched area-quarters and 102 Airbnb-only keys;
- a Christchurch Central median of $237 per night (151 priced listings);
- 7 SQLite tables.

The before-and-after medians for every area are in `output/tables/week10_median_method_comparison.csv`.

### Decisions still open

- Whether the $43,654/night Airbnb price is genuine. It is currently kept.
- Review of the 36 geographically ambiguous listing-quarters.
