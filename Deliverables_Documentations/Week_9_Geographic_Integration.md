# Deliverable 5 - Geographic Data and Dataset Integration

## 1. Purpose

Deliverable 5 connects the cleaned Christchurch Airbnb data to the cleaned Tenancy Services bond data. The two sources do not initially share a usable key:

- Airbnb identifies locations with latitude and longitude.
- Tenancy Services identifies locations with a six-digit `Location Id`.

The Week 9 workflow uses the Koordinates Query API to assign a Stats NZ Statistical Area 2 (SA2) code to each Airbnb coordinate. The two datasets can then be compared using the same geographic code and quarter.

## 2. Official requirements followed

The Week 9 LEARN instructions specify:

- a Koordinates account and API key;
- the Stats NZ Statistical Area 2 2026 layer;
- a test query before all coordinates are processed;
- a new area-code column in the Airbnb data;
- saving the enriched Airbnb data so the API does not need to be queried again;
- joining the Airbnb and tenancy data on area code and time;
- calculating Christchurch Central's median Airbnb price;
- investigating the largest short-term versus long-term rental price gap; and
- comparing Airbnb listing counts with tenancy bond counts.

SQLite is listed as an optional extension. This repository therefore creates database-ready CSV tables in the core workflow and provides a separate optional SQLite script.

## 3. Geographic data source and API

### Dataset

- Publisher: Stats NZ
- Dataset: Statistical Area 2 2026
- Koordinates layer ID: `123515`
- Primary code field: `SA22026_V1_00`
- Name field: `SA22026_V1_00_NAME`
- Layer page: <https://datafinder.stats.govt.nz/layer/123515-statistical-area-2-2026/>

Stats NZ describes SA2 as an output geography intended to represent communities that interact socially and economically. SA2 codes contain six digits. The 2026 layer is the layer explicitly specified on the Week 9 LEARN page.

### Query API

The code uses the Koordinates vector-query endpoint:

```text
https://datafinder.stats.govt.nz/services/query/v1/vector.json
```

For each unique Airbnb coordinate, the request supplies:

- the user's API key;
- layer `123515`;
- longitude as `x`;
- latitude as `y`;
- `max_results=1`;
- `radius=0`, so the result must contain the exact point;
- `geometry=false`, because only attributes are required; and
- `with_field_names=true`.

The API key is read from `KOORDINATES_API_KEY` in a local `.Renviron` file. `.Renviron` is excluded by `.gitignore`; the key must never be committed to GitHub.

## 4. API processing decisions

`R/05_query_geography.R` implements the API stage.

The script:

1. checks that the API key and cleaned Airbnb input exist;
2. extracts unique latitude/longitude pairs;
3. tests one query before starting the full run;
4. queries unique coordinates in batches of 100;
5. uses up to four workers on macOS/Linux;
6. retries a failed request up to three times;
7. writes a cache after every batch;
8. can resume from that cache after interruption;
9. joins SA2 codes and names back to all monthly Airbnb rows; and
10. saves match and unmatched-coordinate summaries.

Querying unique coordinates is important because the same Airbnb listing can appear in several monthly snapshots. Reusing a cached result avoids unnecessary requests and reduces running time.

## 5. Time alignment

Airbnb data are monthly while tenancy data are quarterly. Each Airbnb month is mapped to the first date of its calendar quarter:

| Airbnb months | Comparison quarter |
|---|---|
| October-December 2025 | `2025-10-01` |
| January-March 2026 | `2026-01-01` |
| April-June 2026 | `2026-04-01` |

The tenancy `TimeFrame` already uses these quarter-start dates.

## 6. Join grain and join choice

### Why the raw rows are not joined directly

An Airbnb file contains many listings per SA2 and month. The tenancy file contains many records per SA2 and quarter because it includes dwelling-type and bedroom categories. A direct join would pair many Airbnb rows with many tenancy rows and artificially duplicate both datasets.

### Grain used for comparison

The integration script first creates:

- one Airbnb summary row per `sa2_code + comparison_quarter`; and
- one tenancy summary row per `sa2_code + comparison_quarter` using the source's `Dwelling Type = ALL` and `Number Of Beds = ALL` record.

The two summary tables are joined with an `inner_join` on:

```text
sa2_code + comparison_quarter
```

An inner join is appropriate for the comparison table because price differences can only be calculated when both sources have a record for the same place and quarter. Separate anti-join outputs retain all Airbnb-only and tenancy-only keys for quality review.

## 7. Database-ready structure

The core workflow creates the following tables under `data/processed/database_ready/`:

| Table | Grain | Purpose |
|---|---|---|
| `dim_geography` | one row per SA2 | SA2 code and name lookup |
| `fact_airbnb_listing_month` | one listing snapshot per month | Enriched detailed Airbnb records |
| `fact_airbnb_sa2_quarter` | one row per SA2 and quarter | Airbnb price and listing summaries |
| `fact_tenancy_detail` | one source category per SA2 and quarter | Cleaned tenancy detail |
| `fact_tenancy_sa2_quarter` | one row per SA2 and quarter | Overall tenancy measures from `ALL/ALL` |
| `market_sa2_quarter` | one matched row per SA2 and quarter | Integrated comparison table |

`R/07_build_database.R` optionally writes these tables to:

```text
data/processed/christchurch_rental_market.sqlite
```

The database and detailed processed CSV files are local outputs and are excluded from GitHub through `data/processed/`.

## 8. Measures produced

The integrated comparison includes:

- median Airbnb nightly price;
- equivalent Airbnb weekly price (`nightly price * 7`);
- median tenancy weekly rent;
- equivalent tenancy nightly rent (`weekly rent / 7`);
- nightly and weekly short-term versus long-term price gaps;
- unique Airbnb listings per SA2 and quarter;
- total, active, and closed tenancy bond counts.

Bond counts are administrative counts and should be described as a proxy rather than a perfect count of all rental properties.

## 9. Pre-API validation completed

The locally available Week 8 files were checked before the geographic API stage:

- Airbnb combined rows: `28,795`
- Monthly snapshots: `9` (October 2025 to June 2026)
- Unique latitude/longitude pairs: `3,957`
- Missing Airbnb prices: `10,667`
- Cleaned tenancy rows: `26,991`
- Unique tenancy `SA2 + quarter` keys in the `ALL/ALL` category: `4,865`
- Christchurch Central (`326600`) overall tenancy rows: `3`, one for each comparison quarter

The Airbnb price missingness is systematic. December 2025, January 2026, and February 2026 have no observed prices. Quarter-level Airbnb medians therefore use only the observed prices available in each quarter. The output includes explicit monthly and quarterly price-coverage tables so this limitation can be presented honestly.

## 10. Validation outputs

Small review tables are written to `output/tables/`:

- `week9_api_match_summary.csv`
- `week9_unmatched_coordinates.csv`
- `week9_join_quality.csv`
- `week9_airbnb_price_coverage_by_month.csv`
- `week9_airbnb_price_coverage_by_quarter.csv`
- `week9_unmatched_airbnb_keys.csv`
- `week9_unmatched_tenancy_keys.csv`
- `week9_christchurch_central_median.csv`
- `week9_largest_price_gaps.csv`
- `week9_property_count_comparison.csv`
- `week9_database_row_counts.csv` when SQLite is built

These files provide evidence for the presentation and stop unmatched data from disappearing silently.

## 11. Important limitations

1. The Tenancy Services documentation supplied in Deliverable 4 refers to SA2-2019 definitions, while the Week 9 instructions explicitly specify the SA2 2026 layer. Codes that changed between versions may not match. The unmatched-key tables must be reviewed and reported.
2. Airbnb prices are advertised nightly prices, while tenancy prices are weekly bond-data measures. Dividing weekly rent by seven supports a simple comparison but does not make the markets identical.
3. Airbnb records are monthly snapshots and can contain the same listing in several months. Counts are therefore calculated as distinct listing IDs within each quarter.
4. Bond statistics are subject to Tenancy Services privacy protection, provisional revisions, and source methodology.
5. An API failure and a true no-polygon result are recorded separately in the lookup cache.
6. December 2025 to February 2026 have systematic Airbnb price missingness. Quarterly medians do not represent three complete months in those quarters.

## 12. Reproducible run order

From the RStudio project root:

```r
# First-time package setup
source("R/00_setup_packages.R")

# Week 8 tenancy preparation, if its processed file is not already present
source("R/03_tenancy_inspect.R")

# The finalized combined Airbnb file is used directly:
# data/processed/airbnb_christchurch_combined.csv

# Week 9 core workflow
source("R/05_query_geography.R")
source("R/06_integrate_rental_data.R")

# Optional SQLite extension
source("R/07_build_database.R")
```

`R/02_airbnb_combine.R` is only required when rebuilding the finalized combined Airbnb file from all nine local monthly source files. Those large raw files are intentionally not stored on GitHub.

Before running `R/05_query_geography.R`, copy `.Renviron.example` to `.Renviron`, insert the personal Koordinates API key, save the file, and restart RStudio.

## 13. Team responsibilities

### Sahil

- verify the official Week 9 requirements;
- select and document the Stats NZ layer and Koordinates API;
- implement and test the API-query workflow;
- implement the time alignment and data integration;
- create the database-ready tables and optional SQLite database;
- interpret the Week 9 analytical outputs; and
- lead the Deliverable 5 presentation.

### Claudia

- review this document against the actual script outputs;
- complete the final row counts, match rate, and unmatched-key observations after the full run;
- run the scripts from a fresh R session to check reproducibility;
- record any correction needed in the join logic; and
- commit and push her reviewed documentation update to the agreed team branch.

This gives Claudia a small but substantive and assessable contribution. Pushing the whole team's work by itself is a mechanical action and should not be treated as her main task.
