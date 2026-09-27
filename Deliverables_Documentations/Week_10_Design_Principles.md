# Deliverable 6: Pipeline Design Principles

Christchurch Rental Market Analysis | DATA201/422 | Updated 27 September 2026 (based on Sahil's version of 23 September 2026, with Pooja's cleaning-script changes added)

## 1. Purpose and analytical intention

The pipeline prepares Christchurch Airbnb listing snapshots and Tenancy Services bond statistics for a descriptive comparison of short-term advertised accommodation prices and long-term rental prices. It does not estimate Airbnb profit, occupancy, housing displacement or causal effects.

Our price question is: **what is the median representative nightly price across eligible listings in an area and quarter?** Each listing receives equal weight within that comparison. A listing observed in three months must not receive three times the weight of a listing observed in one month simply because there are more snapshots.

Our cleaning intention is: **keep the source data as supplied, document every departure from it, and make the documented assumptions executable.** Raw files are never edited. Missing values are kept as missing rather than imputed, and a cleaning decision is applied only if the check that justifies it still passes.

This document describes the implemented code, not a proposed architecture. The team must still review the analytical choices before presenting them as an agreed group decision.

## 2. Inputs and their contracts

| Input | Required content | How it enters the pipeline |
|---|---|---|
| Inside Airbnb June 2026 snapshot | `listings.csv`; the same 18 summary columns as the monthly files | Stored unchanged under `data/raw/`. Used only by the exploratory file 01. |
| Nine Inside Airbnb monthly CSVs | `listings_2025_10.csv` through `listings_2026_06.csv`; listing IDs, coordinates, nightly prices and district fields | Stored unchanged under `data/raw/`. File 02 checks that all nine exist and share the same columns, filters Christchurch City, adds the snapshot month, then combines and cleans them. |
| MBIE tenancy CSV | `Detailed-Quarterly-Tenancy-Q1-2020-Q3-2026.csv`; area, quarter, dwelling/bed categories, bonds and weekly rent measures | Stored under `data/raw/`. File 03 checks that the file and required columns exist, cleans source-coded missing values, and selects the study quarters. |
| Stats NZ SA2 2019 geography | Layer `98970`; area code `SA22019_V1_00` and area name | File 05 queries the Koordinates endpoint and caches coordinate-to-area results locally. |
| Prepared Airbnb input | `data/processed/airbnb_christchurch_with_sa2.csv` | File 06 requires character listing/area IDs, snapshot month, numeric price, coordinates and area name. |
| Prepared tenancy input | `data/processed/tenancy_christchurch_oct2025_jun2026_clean.csv` | File 06 requires quarter dates, character location IDs, categories, bonds and numeric rent measures. |
| Environment | R, packages recorded in `renv.lock`; a local API key only for uncached requests | Open the `.Rproj` at the project root; restore packages separately from analysis. |

The cleaning scripts (01–03) now enforce their input contracts:

- files 02 and 03 stop with a clear error if an input file is missing;
- files 01 and 03 check that the required columns are present;
- file 02 checks that all nine monthly files share the same columns.

This gives a clear error at the start instead of a less informative failure later.

Despite its prepared filename, the tenancy input retains national area records for the selected quarters. Christchurch comparison coverage is determined by matching the Christchurch Airbnb areas, not by interpreting the filename as a city filter. The team reviewed this and chose to keep the existing filename for compatibility.

Detailed data, API caches, SQLite and credentials remain local. Code, documentation and selected small presentation/validation outputs are kept in Git. The course asks that the large Airbnb datasets not be uploaded to GitHub, so this is a documented exception to the lecture's generic data-and-code versioning example.

## 3. Outputs and table structure

### Cleaned intermediate files (files 01–04)

| File | Output | One row represents |
|---|---|---|
| 01 (exploratory) | `data/processed/airbnb_christchurch_2026_06_clean.csv` | One Christchurch listing in the June 2026 snapshot |
| 02 | `data/processed/airbnb_christchurch_oct2025_jun2026_clean.csv` | One listing in one monthly snapshot (28,795 rows, 15 columns) |
| 03 | `data/processed/tenancy_clean.csv` | One tenancy reporting unit, all periods |
| 03 | `data/processed/tenancy_christchurch_oct2025_jun2026_clean.csv` | One tenancy reporting unit in the Oct 2025, Jan 2026 or Apr 2026 quarter |
| 04 (exploratory) | Six summary tables in `output/tables/airbnb_*.csv` | Missing values, numeric, categorical, room type, neighbourhood and snapshot summaries |

Files 01–03 create their output folder if it is missing and confirm that each output file was written.

### Geography-enriched Airbnb file (file 05)

| Output | One row represents |
|---|---|
| `data/processed/airbnb_christchurch_with_sa2.csv` | One listing in one monthly snapshot, with its SA2 2019 code and name added (28,795 rows) |
| Local coordinate-to-SA2 cache (ignored by Git) | One unique coordinate pair and the area it falls in, so the API is not queried again for the same point |

### Integrated tables (files 06–07)

File 06 writes the following CSVs under `data/processed/database_ready/`; file 07 stores the same seven tables in `data/processed/christchurch_rental_market.sqlite`.

| Table | Unit represented by one row | Current rows |
|---|---|---:|
| `dim_geography` | One SA2 code and name | 171 |
| `fact_airbnb_listing_month` | One listing in one monthly snapshot, preserved | 28,795 |
| `fact_airbnb_listing_quarter` | One listing in one quarter, including flagged geography | 10,355 |
| `fact_airbnb_sa2_quarter` | One eligible Airbnb area-quarter summary | 510 |
| `fact_tenancy_detail` | One area-quarter-dwelling-bedroom category record | 27,212 |
| `fact_tenancy_sa2_quarter` | One area-quarter `ALL/ALL` tenancy record | 4,871 |
| `market_sa2_quarter` | One matched area-quarter comparison | 408 |

`output/tables/` contains price/count summaries, missing-price coverage, unmatched keys, test results, sanity checks, a worked example, method metadata and a weighting-versus-geography comparison. Detailed listing-level exclusions and Central listing prices are saved under the ignored folder `data/processed/quality/`.

`output/figures/` contains two PNG/PDF charts: the top ten median quarterly price gaps, and April–June 2026 Airbnb listing counts versus active tenancy bonds. Existing `week9_` output filenames are kept so team links continue to work, but their contents now use the corrected Week 10 method.

## 4. Main processing steps and interfaces

1. `R/00_setup_packages.R`: restore the project packages when setting up the project. It is not run automatically during analysis.
2. `R/01_airbnb_prepare.R`: the earlier single-month (June 2026) exploration. It validates the Christchurch filter, the snapshot label and the key fields, and saves a cleaned June file. It is **not** a prerequisite for file 02.
3. `R/02_airbnb_combine.R`: read the nine monthly files, check they share one structure, filter Christchurch City, add and validate `month_year`, combine them, assert the row counts, test the known missing-value patterns, remove the four documented columns, and save the cleaned combined input.
4. `R/03_tenancy_prepare.R`: inspect and validate the bond data, convert `NULL` rent values to NA and then to numeric, check that the table structure is unchanged, save the full cleaned file, then save the validated study-period subset.
5. `R/04_airbnb_summary.R`: an unchanged exploratory summary of monthly observations. It is not an equal-listing market price estimate.
6. `R/05_query_geography.R`: resolve unique coordinates against SA2 2019. It uses the saved cache, retries failed requests, and requires a key only if uncached coordinates remain. All monthly rows are kept in the enriched output.
7. `R/06_integrate_rental_data.R`: validate inputs, align months to quarters, create one price per listing-quarter, flag ambiguous locations, aggregate eligible listings, select tenancy `ALL/ALL`, and join on area and quarter. Quality evidence is saved alongside the results.
8. `R/07_build_database.R`: read the prepared tables with explicit identifier types, rebuild SQLite in a transaction, add unique indexes, compare an SQL join with the R result, and close the connection even on error.
9. `R/08_week9_plots.R`: read saved summaries and the method metadata, and produce the two labelled charts without an API request.
10. `R/09_validate_pipeline.R`: independently recompute listing and area medians with base R, validate counts/keys/arithmetic/source fingerprints, and write a check report.

For the current prepared data, `source("R/10_run_week10.R")` runs the fixture tests and stages 06–09 in order. It does not download source data or repeat live geographic requests. Each stage reads its own files instead of relying on objects left from a previous R session.

## 5. Cleaning, price weighting, geography and joining rules

### Airbnb cleaning (files 01–02)

- **Scope:** only `neighbourhood_group == "Christchurch City"` is kept. The script checks that each month still has Christchurch records and no other districts after filtering.
- **Missing values are kept, not imputed.**
  - Price is entirely missing in the December 2025, January 2026 and February 2026 source files, and about 5–8% missing in the other months.
  - `minimum_nights` is missing on 37 records.
  - `last_review` and `reviews_per_month` are missing only where `number_of_reviews` is zero, and the script tests this relationship.
- **Columns removed:** `license` (checked to be 100% missing before removal), plus `name`, `host_name` and `neighbourhood_group`, which are not needed after filtering. The script confirms that exactly these columns were removed and that no rows were lost.
- **Duplicates:** a listing may appear once per monthly snapshot. Repeated IDs across months are legitimate observations. Duplicates within a month, or completely duplicated rows, stop the script.
- **High prices** are inspected but not removed automatically. Whether the highest value in the combined data ($43,654/night) is a genuine price is an open team decision (see section 8).

### Tenancy cleaning (file 03)

- `NULL` in the five rent measures is converted to NA, then the columns are converted to numeric. The script first checks that no other unexpected text is present.
- The four main rent measures are missing on the same 803 records. This shared pattern is checked rather than assumed.
- The `-99` and `NULL` Location Id codes contain real records, so they are kept rather than removed or recoded. Numeric Location Ids are checked to be six digits.
- `Number Of Beds` stays as text so that `ALL` and `5+` keep their meaning. Genuine zeros in Log Std Dev Weekly Rent are kept, and negative values are rejected.
- The relationship Total = Active + Closed bonds does not hold in the source data, so it is not imposed.
- Cleaning must not change the row count, column count or the uniqueness of each reporting unit (quarter, location, dwelling type, beds). All three are asserted.

### Price weighting

Monthly records are kept as longitudinal observations. We reject duplicate `id + snapshot_date` keys, but do not delete legitimate observations of the same listing in different months.

For each listing and calendar quarter, the first median summarises that listing's available monthly prices. The second median is calculated across these listing-level values within each eligible SA2-quarter. Listings with no price remain in listing counts but do not contribute a zero or an invented price to the median.

Christchurch Central's whole-period headline is calculated separately. We take one median per listing from its eligible Central monthly observations over October 2025–June 2026, then the median across those listing medians. It is not the median of the three quarterly medians. The current result is NZ$237 from 151 priced listings; 152 eligible listings are counted in total, using 695 observed monthly prices.

### Geographic ambiguity

An ID appearing in more than one SA2 within a quarter is flagged `multiple_sa2`. Its monthly history and listing-quarter row are preserved, but that quarter receives no chosen SA2 and is excluded from both geographic price and count comparisons. No majority vote or latest-coordinate rule is used to pretend that a true location is known.

There are currently 36 flagged listing-quarters covering 108 monthly rows. Separately, 37 IDs have different SA2 codes somewhere across the full study period; this is a different measure. A listing with a single known area within a particular quarter remains eligible in that quarter, even if a different quarter has a different area. A quarter with no known area is flagged `no_sa2` and is also excluded.

This is a conservative, explicit exclusion policy, not a completed investigation of the underlying location changes. The sensitivity table records the effect of weighting separately from the effect of exclusions.

### Join and units

Tenancy uses the existing `Dwelling Type = ALL` and `Number Of Beds = ALL` rows. Adding the detailed categories would count overlapping groups repeatedly. Both summary keys are asserted unique before a one-to-one inner join on `sa2_code + comparison_quarter`.

Nightly gap = equal-listing Airbnb nightly median minus tenancy weekly median / 7. These are different markets and pricing bases, so the gap is descriptive, not a measure of realised profit. The area ranking takes the median of its available quarterly gaps, and the number of usable quarters is displayed.

## 6. Coding strategies linked to the lectures

| Lecture principle | Implementation and reason |
|---|---|
| Separate data, code and output; preserve originals (Monday PDF p. 5) | Existing directories retained. Raw files are never overwritten; every change is made by a script. Local detailed outputs can be regenerated; small published chart/check outputs are explicit Git exceptions for tutor/team inspection. |
| Keep the project root and use relative paths (Monday pp. 8–9) | All production paths are project-relative. No `setwd()` or personal Mac paths. The runner checks that the `.Rproj` is present. |
| Clearly scoped stages (Monday p. 10) | Numbered scripts keep separate responsibilities. Pure aggregation/validation helpers are extracted into `R/helpers/`. Some stages intentionally write a related bundle of outputs (e.g. file 03's full and study-period tenancy files) rather than one file per output. |
| Visible parameters and clear interfaces (Monday pp. 12–13) | `R/pipeline_config.R` holds the study window, layer, area, chart choices, paths and table list. The cleaning scripts define their input and output paths once, at the top, instead of repeating them. The cleaning scripts check their inputs before starting and confirm their outputs were written. |
| Self-documenting names and expected data types (Monday pp. 16–18) | Names distinguish listing-month, listing-quarter and area-quarter tables. `high_price_listings` was renamed `top_price_listings` because the listings are inspected, not removed. Character IDs prevent precision loss. Critical price/date columns have explicit parsers, and file 03 checks that rent columns are numeric after conversion. |
| Assertions as documentation (Monday p. 19) | Findings that used to be printed or written in comments are now checks that stop the script if they fail. Examples: required columns, nine monthly files with matching structure, row counts preserved through combining and column removal, Dec–Feb prices fully missing, missing review fields only on zero-review listings, unique keys, valid prices/dates and one-to-one joins. |
| Hand calculation and graphical checks (Monday pp. 21–22) | Toy fixtures, independent saved-data recalculation, a real Central arithmetic example and regenerated charts check intermediate and final results. |
| Human-in-the-loop AI work (Tuesday p. 6) | The team sets the analytical objective and reviews definitions, exclusions and conclusions. AI tools help implement, test and document, and the team remains accountable. |

No new package was required. The existing `renv.lock` was not silently updated. Broad formatting changes and unrelated refactoring were avoided.

## 7. Sanity checks and evidence

**Cleaning stage.** Files 01–03 assert their documented assumptions each time they run:

- the combined Airbnb row count equals the sum of the monthly row counts, and removing columns does not change it;
- all nine snapshots remain after cleaning;
- only the three expected months have fully missing prices;
- the tenancy table keeps the same rows, columns and unique reporting units after `NULL` conversion;
- the study-period subset contains exactly the October 2025, January 2026 and April 2026 quarters.

**Geography stage.** File 05 prints a join-quality summary after each run. In the 28 September re-run, all 28,795 Airbnb rows had coordinates and all 28,795 matched an SA2 2019 area (100%, 0 unmatched), covering 171 unique areas. That equals the 171 rows in `dim_geography`.

**Weighting.** The simple weighting fixture has listing A at $100 in three months and listing B at $300 in one month. A pooled median is $100. The intended calculation is median($100, $300) = $200. The automated test requires $200 and verifies that adding repeated equal-price monthly observations does not increase a listing's weight.

**Real-data worked example.** Christchurch Central in April–June 2026: Airbnb $253/night, tenancy $537/week, equivalent tenancy $76.7142857/night, and gap $176.2857143/night. The CSV `week10_sanity_example.csv` stores both the expected and saved gap for comparison.

**Integration stage.** Validation includes 22 fixture tests, 4 database safety tests on temporary copies, and 11 saved-output sanity checks. The saved-output checks independently recompute every listing-quarter and area-quarter median and the Central whole-period result, and check matched-key intersection, source-file fingerprints and price-gap arithmetic. The build also checks SQL-versus-R join agreement and SQLite integrity. The saved reports are `week10_fixture_tests.csv`, `week10_database_tests.csv` and `week10_sanity_checks.csv`. Passing means the implementation follows the stated policy, not that the source data are complete or free from all uncertainty.

## 8. Limitations, reproducibility and review boundaries

- December 2025, January 2026 and February 2026 have no observed prices in the source Airbnb files. Changing weights does not fill those gaps, and no imputation was introduced.
- The highest combined Airbnb price ($43,654/night) has not yet been confirmed as genuine or erroneous. **The team will decide how to handle it; record the decision here.**
- Listings contribute equally within an area-quarter; monthly price changes are summarised, not modelled. This estimates a typical listing's representative price, not a price weighted by available nights, occupancy or bookings.
- Ambiguous geography exclusions can change both the price distribution and counts. They are reported explicitly and require human review rather than being hidden as routine deduplication.
- Active bonds are an administrative indicator, not a verified count of distinct long-term properties. Room type, bedrooms, fees and availability are not fully standardised between markets.
- The current core join has 408 matched and 102 Airbnb-only area-quarter keys; 4,463 tenancy-only keys remain because the tenancy source has wider geographic coverage. Unmatched does not automatically mean an API error.
- All counts in this document were confirmed by a full re-run on 28 September 2026, after merging Pooja's and Sahil's changes. All 22 fixture tests, 4 database tests and 11 saved-output checks passed.
- Verification used the local prepared inputs and a cached geography rebuild. The original internet downloads and a new live API request were not repeated, and a fresh package installation on another teammate's Mac was not tested.
- `.Renviron` is ignored and not required for the offline runner. A key previously appeared in Git history, and removing the file from tracking does not revoke it. Its owner must rotate it and coordinate any history cleanup. Never show a key while screen sharing.

## 9. AI disclosure, references and acceptance

**AI used:**

- **OpenAI Codex** (an AI coding agent): used by Sahil to inspect the project and the lecture PDFs, implement the weighting correction and refactoring of files 02 and 05–10, write the original version of this document and the change log, and run tests.
- **Claude (Anthropic)**: used by Claudia to review files 01–04 against the lecture principles, and to merge Pooja's cleaning changes into this updated document and the change log.

The AI-generated implementation and wording should be reviewed by Sahil, Pooja and Claudia before being presented as the group's accepted design. Automated test results do not imply human approval.

References reviewed:

- John Bryant, *Best Coding Practices (Revisited)*, DATA201/422, 21 September 2026, `09-monday-coding.pdf`. [LEARN resource](https://learn.canterbury.ac.nz/mod/resource/view.php?id=4865993).
- John Bryant, *Best Coding Practices (Revisited)*, DATA201/422, 22 September 2026, `09-tuesday-coding.pdf`. [LEARN resource](https://learn.canterbury.ac.nz/mod/resource/view.php?id=4867439).
- [Week 10 Deliverable 6 instructions](https://learn.canterbury.ac.nz/course/section.php?id=448322), checked on LEARN on 23 September 2026.
- Existing source and preparation decisions in `Week_9_Geographic_Integration.md`, `README_Airbnb_Cleaning_Decisions.md`, `Tenancy_Data_Cleaning_Decisions.md` and `cleaning decisions.Rmd`.

Acceptance checklist: code review and rationale recorded; cleaning assumptions made executable; repeated-listing weighting corrected; tests and a hand-checkable example supplied; inputs/outputs/steps/strategies documented; AI named; code and document cross-checked. Still outstanding: team review, the price-outlier decision, and lab logistics.
