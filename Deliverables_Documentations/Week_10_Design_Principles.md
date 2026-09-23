# Deliverable 6: Pipeline Design Principles

Christchurch Rental Market Analysis | DATA422 | 23 September 2026

## 1. Purpose and analytical intention

The pipeline prepares Christchurch Airbnb listing snapshots and Tenancy Services bond statistics for a descriptive comparison of short-term advertised accommodation prices and long-term rental prices. It does not estimate Airbnb profit, occupancy, housing displacement or causal effects.

Our price question is: **what is the median representative nightly price across eligible listings in an area and quarter?** Each listing receives equal weight within that comparison. A listing observed in three months must not receive three times the weight of a listing observed in one month simply because there are more snapshots.

This document describes the implemented code, not a proposed architecture. The local implementation has been run and checked; the team must still review the analytical choices before presenting them as an agreed group decision.

## 2. Inputs and their contracts

| Input | Required content | How it enters the pipeline |
|---|---|---|
| Nine Inside Airbnb summary CSVs | `listings_2025_10.csv` through `listings_2026_06.csv`; listing IDs, geographic coordinates, advertised nightly prices and monthly snapshot identifiers | Stored unchanged under `data/raw/`; file 02 filters Christchurch City and combines/cleans them |
| MBIE tenancy CSV | `Detailed-Quarterly-Tenancy-Q1-2020-Q3-2026.csv`; area, quarter, dwelling/bed categories, bonds and weekly rent measures | Stored under `data/raw/`; file 03 cleans source-coded missing values and selects the study quarters |
| Stats NZ SA2 2019 geography | Layer `98970`; area code `SA22019_V1_00` and area name | File 05 queries the Koordinates endpoint and caches coordinate-to-area results locally |
| Prepared Airbnb input | `data/processed/airbnb_christchurch_with_sa2.csv` | File 06 requires character listing/area IDs, snapshot month, numeric price, coordinates and area name |
| Prepared tenancy input | `data/processed/tenancy_christchurch_oct2025_jun2026_clean.csv` | File 06 requires quarter dates, character location IDs, categories, bonds and numeric rent measures |
| Environment | R, packages recorded in `renv.lock`; a local API key only for uncached requests | Open the `.Rproj` at the project root; restore packages separately from analysis |

Despite its prepared filename, the tenancy input retains national area records for the selected quarters. Christchurch comparison coverage is determined by matching the Christchurch Airbnb areas, not by interpreting the filename as a city filter. Tenancy-only rows are therefore not all failed Christchurch matches.

Detailed data, API caches, SQLite and credentials remain local. Code, documentation and selected small presentation/validation outputs are kept in Git. The course explicitly asks that the large Airbnb datasets not be uploaded to GitHub; this is a documented exception to the lecture's generic data-and-code versioning example.

## 3. Outputs and table structure

File 06 writes the following CSVs under `data/processed/database_ready/`; file 07 stores the same seven tables in `data/processed/christchurch_rental_market.sqlite`.

| Table | Unit represented by one row | Current rows |
|---|---|---:|
| `dim_geography` | One SA2 code and name | 171 |
| `fact_airbnb_listing_month` | One listing in one monthly snapshot, preserved | 28,795 |
| `fact_airbnb_listing_quarter` | One listing in one quarter, including flagged geography | 10,355 |
| `fact_airbnb_sa2_quarter` | One eligible Airbnb area-quarter summary | 510 |
| `fact_tenancy_detail` | One area-quarter-dwelling-bedroom category record | 26,991 |
| `fact_tenancy_sa2_quarter` | One area-quarter `ALL/ALL` tenancy record | 4,865 |
| `market_sa2_quarter` | One matched area-quarter comparison | 408 |

`output/tables/` contains price/count summaries, missing-price coverage, unmatched keys, test results, sanity checks, a worked example, method metadata and a weighting-versus-geography comparison. Detailed listing-level exclusions and Central listing prices are saved under ignored `data/processed/quality/`.

`output/figures/` contains two PNG/PDF charts: the top ten median quarterly price gaps and April-June 2026 Airbnb listing counts versus active tenancy bonds. Existing `week9_` output filenames are retained so team links continue to work; their contents now use the corrected Week 10 method.

## 4. Main processing steps and interfaces

1. `R/00_setup_packages.R`: restore the project packages when setting up the project. This is not run automatically during analysis.
2. `R/02_airbnb_combine.R`: read the nine local monthly files, filter Christchurch City, retain the month identifier and save the cleaned combined input. `R/01_airbnb_prepare.R` is the earlier single-month exploration, not a prerequisite for file 02.
3. `R/03_tenancy_inspect.R`: inspect and clean bond data, then save the study-period input. `R/04_summary_statistics_airbnb_clean.R` remains an exploratory summary of monthly observations, not an equal-listing market price estimate.
4. `R/05_query_geography.R`: resolve unique coordinates against SA2 2019. Use the saved cache, retry failed requests, and require a key only if uncached coordinates remain. Keep all monthly rows in the enriched output.
5. `R/06_integrate_rental_data.R`: validate inputs, align months to quarters, create one price per listing-quarter, flag ambiguous locations, aggregate eligible listings, select tenancy `ALL/ALL`, and join on area and quarter. Save quality evidence alongside results.
6. `R/07_build_database.R`: read the prepared tables with explicit identifier types, rebuild SQLite in a transaction, add unique indexes, compare an SQL join with the R result, and close the connection even on error.
7. `R/08_week9_plots.R`: read saved summaries and the method metadata; produce the two labelled charts without an API request.
8. `R/09_validate_pipeline.R`: independently recompute listing and area medians with base R, validate counts/keys/arithmetic/source fingerprints and write a check report.

For the current prepared data, `source("R/10_run_week10.R")` runs fixture tests and stages 06-09 in order. It does not download source data or repeat live geographic requests. Each stage reads its own files instead of relying on objects left from a previous R session.

## 5. Price weighting, geography and joining rules

### Price weighting

Monthly records are kept as longitudinal observations. We reject duplicate `id + snapshot_date` keys, but do not delete legitimate observations of the same listing in different months.

For each listing and calendar quarter, the first median summarises that listing's available monthly prices. The second median is calculated across these listing-level values within each eligible SA2-quarter. Listings with no price remain in listing counts but do not contribute a zero or an invented price to the median.

Christchurch Central's whole-period headline is calculated separately: one median per listing from its eligible Central monthly observations over October 2025-June 2026, followed by the median across those listing medians. It is not the median of the three quarterly medians. The current result is NZ$237 from 151 priced listings; 152 eligible listings are counted in total, using 695 observed monthly prices.

### Geographic ambiguity

An ID appearing in more than one SA2 within a quarter is flagged `multiple_sa2`. Its monthly history and listing-quarter row are preserved, but that quarter receives no chosen SA2 and is excluded from both geographic price and count comparisons. No majority vote or latest-coordinate rule is used to pretend that a true location is known.

There are currently 36 flagged listing-quarters covering 108 monthly rows. There are 37 IDs with different SA2 codes somewhere across the full study period; this is a different measure. A listing with a single known area within a particular quarter remains eligible in that quarter, even if a different quarter has a different area. A quarter with no known area is flagged `no_sa2` and is also excluded.

This is a conservative, explicit exclusion policy, not a completed investigation of the underlying location changes. The team should review the local audit before deciding whether an authoritative correction is possible. The sensitivity table records the effect of weighting separately from the effect of exclusions.

### Join and units

Tenancy uses the existing `Dwelling Type = ALL` and `Number Of Beds = ALL` rows. Adding the detailed categories would count overlapping groups repeatedly. Both summary keys are asserted unique before a one-to-one inner join on `sa2_code + comparison_quarter`.

Nightly gap = equal-listing Airbnb nightly median minus tenancy weekly median / 7. These are different markets and pricing bases, so the gap is descriptive, not a measure of realised profit. The area ranking takes the median of its available quarterly gaps; the number of usable quarters is displayed.

## 6. Coding strategies linked to the lectures

| Lecture principle | Implementation and reason |
|---|---|
| Separate data, code and output; preserve originals (Monday PDF p. 5) | Existing directories retained. Raw files are never overwritten. Local detailed outputs can be regenerated; small published chart/check outputs are explicit Git exceptions for tutor/team inspection. |
| Keep the project root and use relative paths (Monday pp. 8-9) | All production paths are project-relative. No `setwd()` or personal Mac paths are added. The runner checks that the `.Rproj` is present. |
| Clearly scoped stages (Monday p. 10) | Numbered scripts retain separate responsibilities. Pure aggregation/validation helpers are extracted instead of rewriting Pooja's upstream cleaning policy. Some stages intentionally emit a related bundle of tables rather than one file per output. |
| Visible parameters and clear interfaces (Monday pp. 13-14) | `R/pipeline_config.R` holds the study window, layer, area, chart choices, paths and table list. Script headers identify inputs and outputs. |
| Self-documenting names and expected data types (Monday pp. 15-19) | Names distinguish listing-month, listing-quarter and area-quarter tables. Character IDs prevent precision loss. Critical price/date columns have explicit parsers. Comments explain non-obvious policy decisions. |
| Assertions as documentation (Monday p. 20) | Required columns, valid prices/dates, unique keys and one-to-one joins are executable checks rather than promises in comments. Expected missing bedroom categories are retained in tenancy detail. |
| Hand calculation and graphical checks (Monday pp. 22-23) | Toy fixtures, independent saved-data recalculation, a real Central arithmetic example and regenerated charts check intermediate and final results. |
| Human-in-the-loop AI work (Tuesday p. 6) | The coordinator's feedback sets the analytical objective. AI implements and tests; the team reviews definitions, exclusions and conclusions and remains accountable. |

No new package was required. The existing `renv.lock` was not silently updated. Broad formatting changes and unrelated upstream refactoring were avoided.

## 7. Sanity checks and evidence

The simple weighting fixture has listing A at $100 in three months and listing B at $300 in one month. A pooled median is $100. The intended calculation is median($100, $300) = $200. The automated test requires $200 and verifies that adding repeated equal-price monthly observations does not increase a listing's weight.

The real-data worked example is Christchurch Central in April-June 2026: Airbnb $253/night, tenancy $537/week, equivalent tenancy $76.7142857/night, and gap $176.2857143/night. The CSV `week10_sanity_example.csv` stores both the expected and saved gap for comparison.

Validation includes 22 fixture tests, 4 database safety tests on temporary copies, and 11 saved-output sanity checks. The latter independently recompute every listing-quarter and area-quarter median and the Central whole-period result, check matched-key intersection, source-file fingerprints and price-gap arithmetic. The build also checks SQL-versus-R join agreement and SQLite integrity. The saved reports are `week10_fixture_tests.csv`, `week10_database_tests.csv` and `week10_sanity_checks.csv`. Passing means the implementation follows the stated policy, not that the source data are complete or free from all uncertainty.

## 8. Limitations, reproducibility and review boundaries

- December 2025, January 2026 and February 2026 have no observed prices in the prepared Airbnb input. Changing weights does not fill those gaps. No imputation was introduced.
- Listings contribute equally within an area-quarter; monthly price changes are summarised, not modelled. This estimates a typical listing's representative price, not a price weighted by available nights, occupancy or bookings.
- Ambiguous geography exclusions can change both the price distribution and counts. They are reported explicitly and require human review rather than being hidden as routine deduplication.
- Active bonds are an administrative indicator, not a verified count of distinct long-term properties. Room type, bedrooms, fees and availability are not fully standardised between markets.
- The current core join has 408 matched and 102 Airbnb-only area-quarter keys; 4,457 tenancy-only keys remain because the tenancy source has wider geographic coverage. Unmatched does not automatically mean an API error.
- Verification used the currently prepared local inputs and a cached geography rebuild. The original internet downloads and a new live API request were not repeated; no fresh package installation on another teammate's Mac was tested.
- `.Renviron` is ignored and not required for the offline runner. A key previously appeared in Git history; removing the current file from tracking does not revoke that key. Its owner must rotate it and coordinate any necessary history cleanup. Never show a key while screen sharing.
- Booking the tutor slot, confirming attendance, choosing the presentation lead and getting the team's final sign-off are human tasks and are not marked complete by a successful script run.

## 9. AI disclosure, references and acceptance

**AI used: OpenAI Codex, an AI coding agent.** Codex inspected the local R project and the two lecture PDFs, implemented the weighting correction and focused refactoring, wrote this design document and change log, and ran tests. The AI-generated implementation and wording should be reviewed by Sahil, Pooja and Claudia before being presented as the group's accepted design. No human approval is implied by the automated test results.

References reviewed:

- John Bryant, *Best Coding Practices (Revisited)*, DATA201/422, 21 September 2026, `09-monday-coding.pdf`. [LEARN resource](https://learn.canterbury.ac.nz/mod/resource/view.php?id=4865993).
- John Bryant, *Best Coding Practices (Revisited)*, DATA201/422, 22 September 2026, `09-tuesday-coding.pdf`. [LEARN resource](https://learn.canterbury.ac.nz/mod/resource/view.php?id=4867439).
- [Week 10 Deliverable 6 instructions](https://learn.canterbury.ac.nz/course/section.php?id=448322), checked on LEARN on 23 September 2026.
- Existing source and preparation decisions in `Week_9_Geographic_Integration.md`, `README_Airbnb_Cleaning_Decisions.md` and `Tenancy_Data_Cleaning_Decisions.md`.

Acceptance checklist: code review and rationale recorded; repeated-listing weighting corrected; tests and a hand-checkable example supplied; inputs/outputs/steps/strategies documented; AI named; code and document cross-checked. Team review and lab logistics remain outstanding.
