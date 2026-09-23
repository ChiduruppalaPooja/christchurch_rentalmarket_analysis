# Deliverable 5 - Geographic Data and Dataset Integration

Updated 23 September 2026: the Week 10 correction changes price weighting and geographic eligibility. Output filenames retain their `week9_` prefix. The current method and high-level reasons are detailed in [Week 10 Design Principles](Week_10_Design_Principles.md) and [Week 10 Change Log](Week_10_Change_Log.md). The documentation-review notes in section 13 describe the earlier Week 9 run.

## 1. Purpose

Deliverable 5 connects the cleaned Christchurch Airbnb data to the cleaned Tenancy Services bond data. The two sources do not initially share a usable key:

- Airbnb identifies locations with latitude and longitude.
- Tenancy Services identifies locations with a six-digit `Location Id`.

The Week 9 workflow uses the Koordinates Query API to assign a Stats NZ Statistical Area 2 (SA2) code to each Airbnb coordinate. The two datasets can then be compared using the same geographic code and quarter.

## 2. Requirements and source constraints followed

The Week 9 implementation follows the LEARN requirements together with the geographic definition documented by Tenancy Services:

- a Koordinates account and API key;
- a Stats NZ SA2 layer compatible with the tenancy data's SA2-2019 definitions;
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
- Dataset: Statistical Area 2 2019 (generalised)
- Koordinates layer ID: `98970`
- Primary code field: `SA22019_V1_00`
- Name field: `SA22019_V1_00_NAME`
- Layer page: <https://datafinder.stats.govt.nz/layer/98970-statistical-area-2-2019-generalised/>
- Tenancy Services source: <https://www.tenancy.govt.nz/about-tenancy-services/data-and-statistics/rental-bond-data/>

Stats NZ describes SA2 as an output geography intended to represent communities that interact socially and economically. SA2 codes contain six digits. Tenancy Services states that its rental bond data use SA2-2019 area definitions, so the 2019 boundary layer is required for a compatible geographic join. Using the latest boundary release merely because it is newer could introduce changed codes or boundaries that do not correspond to the tenancy `Location Id` values.

### Query API

The code uses the Koordinates vector-query endpoint:

```text
https://datafinder.stats.govt.nz/services/query/v1/vector.json
```

For each unique Airbnb coordinate, the request supplies:

- the user's API key;
- layer `98970`;
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

1. checks the cleaned Airbnb input and requires an API key only for uncached requests;
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

- one intermediate row per listing and quarter, with that listing's median available monthly price;
- one Airbnb summary row per `sa2_code + comparison_quarter`; and
- one tenancy summary row per `sa2_code + comparison_quarter` using the source's `Dwelling Type = ALL` and `Number Of Beds = ALL` record.

The two summary tables are joined with an `inner_join` on:

```text
sa2_code + comparison_quarter
```

An inner join is appropriate for the comparison table because price differences can only be calculated when both sources have a record for the same place and quarter. Separate anti-join outputs retain all Airbnb-only and tenancy-only keys for quality review.

The area price is the median of the eligible listing-level medians, giving each listing one contribution. Listing-quarters with more than one observed SA2 are preserved and flagged, but excluded from spatial prices and counts until reviewed. Original monthly records are not deleted. This is separate from duplicate-ID/month validation.

## 7. Database-ready structure

The core workflow creates the following tables under `data/processed/database_ready/`:

| Table | Grain | Purpose |
|---|---|---|
| `dim_geography` | one row per SA2 | SA2 code and name lookup |
| `fact_airbnb_listing_month` | one listing snapshot per month | Enriched detailed Airbnb records |
| `fact_airbnb_listing_quarter` | one listing per quarter | Representative price and explicit geography eligibility |
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

- equal-listing median Airbnb nightly price;
- equivalent Airbnb weekly price (`nightly price * 7`);
- median tenancy weekly rent;
- equivalent tenancy nightly rent (`weekly rent / 7`);
- nightly and weekly short-term versus long-term price gaps;
- unique Airbnb listings per SA2 and quarter;
- total, active, and closed tenancy bond counts.

Bond counts are administrative counts and should be described as a proxy rather than a perfect count of all rental properties.

## 9. Validation completed

The locally available Week 8 files were checked before the geographic API stage:

- Airbnb combined rows: `28,795`
- Monthly snapshots: `9` (October 2025 to June 2026)
- Unique exact latitude/longitude pairs: `3,957`
- Unique API query keys after rounding coordinates to six decimal places: `3,952`
- Missing Airbnb prices: `10,667`
- Cleaned tenancy rows: `26,991`
- Unique tenancy `SA2 + quarter` keys in the `ALL/ALL` category: `4,865`
- Christchurch Central (`326600`) overall tenancy rows: `3`, one for each comparison quarter

The Airbnb price missingness is systematic. December 2025, January 2026, and February 2026 have no observed prices. Quarter-level Airbnb medians therefore use only the observed prices available in each quarter. The output includes explicit monthly and quarterly price-coverage tables so this limitation can be presented honestly.

The completed SA2-2019 API and integration run produced:

| Validation measure | Result |
|---|---:|
| Airbnb rows with coordinates | `28,795` |
| Airbnb rows matched to SA2 2019 | `28,795` (`100%`) |
| Unique matched SA2 areas | `171` |
| Eligible Airbnb SA2-quarter keys | `510` |
| Matched Airbnb/tenancy SA2-quarter keys | `408` (`80%`) |
| Unmatched Airbnb SA2-quarter keys | `102` |
| Tenancy-only SA2-quarter keys | `4,457` |
| Christchurch Central eligible monthly price observations | `695` |
| Christchurch Central unique eligible Airbnb listings | `152` |
| Christchurch Central eligible listings with a price | `151` |
| Christchurch Central equal-listing median nightly Airbnb price | `$237` |

The `4,457` tenancy-only keys largely reflect a difference in scope: the source bond file contains SA2 records from throughout New Zealand, while the Airbnb input is restricted to Christchurch. They should not be interpreted as 4,457 failed Christchurch joins. The `102` Airbnb-only keys remain in a separate review table and may reflect absent or suppressed `ALL/ALL` tenancy values for particular place-quarter combinations.

An earlier exploratory run used an SA2 2026 layer and produced only `344` matched Airbnb SA2-quarter keys, with `188` Airbnb keys unmatched. The initial SA2 2019 correction increased the matched count to `408` and reduced unmatched Airbnb keys to `103`. Week 10's separate eligibility correction reduced eligible Airbnb-only keys to `102`; this was not another boundary-vintage change. The governing reason for using 2019 remains the Tenancy Services metadata.

The optional SQLite build also completed successfully:

| Database table | Rows |
|---|---:|
| `dim_geography` | `171` |
| `fact_airbnb_listing_month` | `28,795` |
| `fact_airbnb_listing_quarter` | `10,355` |
| `fact_airbnb_sa2_quarter` | `510` |
| `fact_tenancy_detail` | `26,991` |
| `fact_tenancy_sa2_quarter` | `4,865` |
| `market_sa2_quarter` | `408` |

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

### Presentation charts

Run `source("R/08_week9_plots.R")` after file 06. It reads the saved summary tables without querying the API or requiring a key. Two named plot objects remain available in RStudio:

- `print(price_gap_plot)`: the ten largest median quarterly nightly price gaps, using equal-listing area medians. Wigram South leads at approximately NZ$288.29 per night. Labels show the number of quarters with a usable gap; this chart does not show the distribution of individual listing gaps.
- `print(rental_count_plot)`: unique Airbnb listings and active tenancy bonds for April-June 2026, restricted to the ten matched SA2 areas with the most Airbnb listings. Counts are not summed across quarters. Bonds are an administrative rental indicator, not a verified distinct-property count.

Both charts are saved as PNG and PDF in `output/figures/`, with matching filenames beginning `week9_price_gaps_top10` and `week9_airbnb_vs_active_bonds_2026q2`. The exact selected rows are saved as `week9_plot_price_gaps_top10.csv` and `week9_plot_counts_top10_2026q2.csv` in `output/tables/`.

## 11. Important limitations

1. Both sides of the join must use the same geographic vintage. The workflow therefore uses SA2-2019 because that is the area definition documented for the Tenancy Services bond data. Unmatched-key tables are still reviewed because suppression or absent activity can leave valid SA2-quarter keys without a counterpart. Tenancy-only keys must also be interpreted in light of the source file's national scope.
2. Airbnb prices are advertised nightly prices, while tenancy prices are weekly bond-data measures. Dividing weekly rent by seven supports a simple comparison but does not make the markets identical.
3. Airbnb records are monthly snapshots. Both price aggregation and counts now use listing-quarter records: one median per listing, then a median across listings. The whole-period Central headline similarly uses one median per eligible listing. Ambiguous listing-quarters are excluded from spatial comparisons and audited; all monthly source records remain preserved.
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

# Presentation charts from the saved integration summaries
source("R/08_week9_plots.R")

# Optional SQLite extension
source("R/07_build_database.R")
```

`R/02_airbnb_combine.R` is only required when rebuilding the finalized combined Airbnb file from all nine local monthly source files. Those large raw files are intentionally not stored on GitHub.

Before running `R/05_query_geography.R`, copy `.Renviron.example` to `.Renviron`, insert the personal Koordinates API key, save the file, and restart RStudio.

## 13. Documentation Review
This section records observations from running the Week 9 workflow from a fresh setup, as part of the reproducibility review described in Section 14.

### API key changes
The original setup steps detailed on this document explained that each member should generate an individual API key in order to run the setup. Now one single API key has been generated for use across the whole team to ensure reproducibility is simple.

### SA2 2019 vs SA2 2026 correction
Originally, the SA2 2026 layer was chosen to ensure compatibility with up-to-date Airbnb records, and an exploratory run was conducted to observe the join-quality results. Of 532 Airbnb SA2-and-quarter keys, 188 did not match the tenancy record.
This review prompted another run using the SA2 2019 layer to observe if the output was more accurate. The results showed a decrease in mismatches from 188 to 103, solidifying our decision to switch to the SA2 2019 layer to match with the tenancy datasheet.

### RSQLite "Invalid or closed connection" error - resolved
When running R/07_build_database.R on a fresh R session, the above error occurred. This was due to an unexpected dbDisconnect(connection) statement in the code which closed the connection before the database could be created. This was moved which fixed this issue.

### Environment issue: "Data_table" install on MacOS 
Running R/00_setup_packages.R (renv::restore()) failed to install the exact locked version of data.table (1.18.2.1) from source, with a fatal compilation error: 'libintl.h' file not found. This is a missing-header build issue on current macOS/Xcode toolchains (Apple clang 17.0.0, macOS 15.5 SDK), unrelated to the OpenMP warnings that also appeared in the same log (those were explicitly non-fatal). When prompted, renv fell back to installing the latest available data.table (1.18.6.1), which installed cleanly from a pre-built binary with no compilation required. The final pipeline run using this newer version reproduced every one of Sahil's reported figures exactly, suggesting the version difference did not affect any results in this pipeline. This is likely to affect any other team member on a current Mac attempting to install the exact locked version.

## 14. Team responsibilities

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
- independently confirm the final row counts, match rate, and unmatched-key observations;
- run the scripts from a fresh R session to check reproducibility;
- record any correction needed in the join logic; and
- commit and push her reviewed documentation update to the agreed team branch.

This gives Claudia a small but substantive and assessable contribution. Pushing the whole team's work by itself is a mechanical action and should not be treated as her main task.
