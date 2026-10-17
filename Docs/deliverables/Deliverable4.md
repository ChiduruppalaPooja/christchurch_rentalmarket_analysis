# Deliverable 4 — Data Cleaning and Cleaning Decisions

| Project detail | Description |
|---|---|
| Deliverable | 4 — Data Cleaning and Cleaning Decisions |
| Study period | October 2025 – June 2026 |
| Airbnb processing | `R/02_airbnb_combine.R` |
| Tenancy processing | `R/03_tenancy_prepare.R` |
| Shared configuration | `R/pipeline_config.R` |

## 1. Objective

The objective of Deliverable 4 was to clean the Christchurch Airbnb dataset prepared in Deliverable 3 and the Tenancy Services detailed quarterly rental bond dataset. The cleaning process needed to preserve useful analytical variables, document decisions and their consequences, and produce reproducible outputs for the next stage of the project.

The main requirements were to:

- Clean the Airbnb dataset while retaining latitude and longitude.
- Document cleaning decisions, reasons and changes to the data.
- Preserve variables needed for rental-price and property-availability comparisons.
- Download and document the Tenancy Services detailed quarterly rental bond dataset.
- Restrict the Tenancy dataset to the quarters corresponding to the October 2025–June 2026 Airbnb study period.
- Clean the Tenancy dataset while retaining `Location Id` and `TimeFrame`.
- Save the processed datasets locally and make their generation reproducible through R scripts.
- Present the updated Trello board and reflect on project progress and management.

## 2. Final results

| Dataset | Final dimensions | Rows removed |
|---|---:|---:|
| Cleaned Christchurch Airbnb | 28,795 × 15 | 0 |
| Full cleaned Tenancy Services data | 226,080 × 12 | 0 |
| Tenancy data for the project period | 27,212 × 12 | 198,868 excluded by timeframe filtering |

The Airbnb workflow removed four columns but retained all rows. The Tenancy workflow converted source-coded missing rent values to `NA`, converted the five rent-related columns to numeric, and retained all 12 source columns.

The Tenancy project-period dataset contains three quarterly observations: October–December 2025, January–March 2026, and April–June 2026.

## 3. Input data and sources

### 3.1 Airbnb listing data

The Airbnb dataset was produced by combining the nine monthly Christchurch City listing snapshots from October 2025 through June 2026.

The monthly records were filtered to `neighbourhood_group == "Christchurch City"` before being combined. The `month_year` field identifies the monthly snapshot represented by each row.

The combined dataset contained 28,795 listing-month records before the Deliverable 4 column-removal step.

### 3.2 Tenancy Services rental bond data

**Source:** [Tenancy Services — Rental bond data](https://www.tenancy.govt.nz/about-tenancy-services/data-and-statistics/rental-bond-data/)

The project uses the *Detailed quarterly report, 2020–2026*, downloaded and stored locally as:

`data/raw/Detailed-Quarterly-Tenancy-Q1-2020-Q3-2026.csv`

The source data comes from the Tenancy Services bond database and is based on tenancy start date. Its geographic identifiers use Statistics New Zealand's SA2-2019 area definitions. The published data applies privacy protections, including fixed random rounding and suppression for selections with fewer than five bonds. Recent figures may be provisional and subject to revision.

The dataset covers New Zealand, not Christchurch alone. Geographic matching to Christchurch areas is performed in the later integration workflow.

## 4. Airbnb cleaning

**Script:** `R/02_airbnb_combine.R`

The script loads the nine monthly CSV files, validates their structure, filters each snapshot to Christchurch City, adds `month_year`, combines the records, investigates missingness, removes unnecessary columns and validates the final dataset.

### 4.1 Column-removal decisions

| Column removed | Reason | Consequence |
|---|---|---|
| `name` | Listing title is descriptive text and is not required for the planned quantitative comparison. | Removes unnecessary text data. |
| `host_name` | Host names are not required for the rental-price and property-availability comparison. | Removes unnecessary text data, including one missing host name. |
| `neighbourhood_group` | All records have already been filtered to Christchurch City. | Removes a redundant column without changing the geographic scope. |
| `license` | All 28,795 values are missing. | Removes a column with no observed analytical information. |

The final dataset retains 15 columns. No rows were removed during this cleaning stage, and no values were imputed.

### 4.2 Missing values

| Variable | Missing values | Decision and reason |
|---|---:|---|
| `price` | 10,667 | Retained as `NA`. Missing prices cannot be recovered reliably from the available data. |
| `minimum_nights` | 37 | Retained as `NA`; no unsupported values were inferred. |
| `last_review` | 2,627 | Retained as `NA`. All affected listings have zero reviews. |
| `reviews_per_month` | 2,627 | Retained as `NA`, rather than automatically replacing missing values with zero. |
| `host_name` | 1 | The entire column was removed because host names are not required. |
| `license` | 28,795 | The entire column was removed because it is completely missing. |

The most important issue is the systematic absence of prices in December 2025, January 2026 and February 2026.

| Snapshot | Listings with a price | Listings with missing price |
|---|---:|---:|
| October 2025 | 2,821 | 170 |
| November 2025 | 2,835 | 212 |
| December 2025 | 0 | 3,180 |
| January 2026 | 0 | 3,057 |
| February 2026 | 0 | 3,190 |
| March 2026 | 3,059 | 168 |
| April 2026 | 3,069 | 204 |
| May 2026 | 3,149 | 212 |
| June 2026 | 3,195 | 274 |

The missing prices are retained as missing data, not converted to zero. Price-based analysis cannot be performed for the three fully missing snapshots without another suitable data source.

### 4.3 Review information

All 2,627 missing `last_review` values occur for listings with `number_of_reviews = 0`. The same pattern holds for `reviews_per_month`.

These values are retained because the absence of review information is consistent with listings that have no recorded reviews. Replacing them automatically with zero or removing the affected rows would impose an unsupported interpretation or unnecessarily reduce the dataset.

### 4.4 Prices, duplicates and geographic information

High prices were inspected but not automatically removed. The observed maximum of NZ$43,654 is retained because a high value alone does not establish that an observation is erroneous.

Listing IDs can legitimately recur across different monthly snapshots. The script checks that listing IDs are unique within each snapshot and that no fully duplicated rows exist. The same listing appearing in multiple months is not treated as an error.

Latitude and longitude are retained for geographic analysis and later mapping. Other useful variables—including `id`, `host_id`, `neighbourhood`, `room_type`, `price`, `availability_365` and `month_year`—are also retained.

### 4.5 Final Airbnb columns

The cleaned Airbnb dataset contains these 15 columns:

`id`, `host_id`, `neighbourhood`, `latitude`, `longitude`, `room_type`, `price`, `minimum_nights`, `number_of_reviews`, `last_review`, `reviews_per_month`, `calculated_host_listings_count`, `availability_365`, `number_of_reviews_ltm`, `month_year`.

### 4.6 Airbnb validation results

The script checks that:

- all expected monthly files exist and have compatible structures;
- all nine snapshots are represented;
- only Christchurch City records are included;
- the combined row count equals the sum of the monthly row counts;
- column removal does not change the number of rows;
- listing IDs are present and unique within each month;
- no fully duplicated rows exist; and
- prices are either missing or finite, non-negative numeric values.

The resulting dataset has **28,795 rows and 15 columns**, with latitude and longitude preserved.

## 5. Tenancy Services cleaning

**Script:** `R/03_tenancy_prepare.R`

The script reads the source CSV, checks the required columns, inspects data types and values, converts the rent-related fields, validates the cleaned data, saves the full cleaned dataset and creates the project-period subset.

### 5.1 Column-level decisions

| Column | Cleaning decision | Reason |
|---|---|---|
| `TimeFrame` | Retained as a date. | Identifies the quarterly reporting period and is required for time alignment. |
| `Location Id` | Retained unchanged. | Preserves the geographic identifier needed for spatial matching. |
| `Dwelling Type` | Retained unchanged. | Preserves distinctions between dwelling categories. |
| `Number Of Beds` | Retained as character. | Preserves meaningful categories such as `ALL` and `5+`, as well as missing values. |
| `Total Bonds` | Retained as supplied. | Required for analysing bond counts; no missing or negative values were found. |
| `Active Bonds` | Retained as supplied. | Provides an indicator of active rental bonds. |
| `Closed Bonds` | Retained as supplied. | Provides an indicator of closed rental bonds. |
| `Median Rent` | Converted to numeric; `"NULL"` becomes `NA`. | Enables numerical rent analysis without treating missing values as zero. |
| `Geometric Mean Rent` | Converted to numeric; `"NULL"` becomes `NA`. | Retains an alternative rent measure for comparison. |
| `Upper Quartile Rent` | Converted to numeric; `"NULL"` becomes `NA`. | Preserves an upper-end rent measure. |
| `Lower Quartile Rent` | Converted to numeric; `"NULL"` becomes `NA`. | Preserves a lower-end rent measure. |
| `Log Std Dev Weekly Rent` | Converted to numeric; `"NULL"` becomes `NA`. | Preserves information about rent dispersion. Genuine zero values are retained. |

All 12 columns are kept. No rows are removed during cleaning, and missing values are not imputed.

### 5.2 Handling `"NULL"` in rent columns

The five rent-related columns initially contain the text value `"NULL"`. The script replaces that source-coded value with a true missing value (`NA`) and converts the columns to numeric.

In the full dataset:

- `Median Rent`: 803 `"NULL"` values.
- `Geometric Mean Rent`: 803 `"NULL"` values.
- `Upper Quartile Rent`: 803 `"NULL"` values.
- `Lower Quartile Rent`: 803 `"NULL"` values.
- `Log Std Dev Weekly Rent`: 859 `"NULL"` values.

No unexpected non-numeric strings or negative rent values were found in the inspected source columns. Genuine zero values in `Log Std Dev Weekly Rent` are retained. The conversion changes data representation, not the number of observations.

### 5.3 Missing and special values

`Number Of Beds` is kept as a character field because `ALL` and `5+` are meaningful categories, not ordinary numeric values. Missing bed information is retained rather than inferred.

The `Location Id` values `-99` and `NULL` are also retained. Their precise meaning cannot be established from the dataset alone, and the current cleaning script does not remove or recode them. These identifiers do not represent ordinary six-digit numeric SA2 codes and must not be interpreted as valid geographic areas without further verification.

The script also checks the reporting key consisting of `TimeFrame`, `Location Id`, `Dwelling Type` and `Number Of Beds`. No duplicate combinations were identified.

### 5.4 Bond-count consistency

The script checks whether:

`Total Bonds = Active Bonds + Closed Bonds`

This equality does not hold for most observations. In the project-period subset, only 351 of 27,212 rows satisfy the equality.

The three count variables are retained as supplied. The cleaning process does not force the equality or recalculate the source values because the available evidence does not justify doing so.

## 6. Timeframe filtering

The Airbnb dataset covers October 2025 through June 2026. Because Tenancy Services reports quarterly observations, the corresponding reporting periods are:

| `TimeFrame` | Quarter represented | Rows retained |
|---|---|---:|
| `2025-10-01` | October–December 2025 | 9,459 |
| `2026-01-01` | January–March 2026 | 9,255 |
| `2026-04-01` | April–June 2026 | 8,498 |
| **Total** | **Three quarters** | **27,212** |

The full cleaned Tenancy dataset contains 226,080 rows across 26 quarters. Filtering to the project period retains 27,212 rows and excludes 198,868 rows from other reporting periods.

This exclusion is a deliberate timeframe restriction, not row deletion due to poor data quality. The script checks that the resulting dataset contains the expected reporting periods, stays within the configured date range, retains the same columns and preserves the project-period set of `Location Id` values.

The resulting Tenancy dataset is **not restricted to Christchurch alone**. Geographic matching is handled in the subsequent integration workflow.

## 7. Tenancy Services source and column definitions

The following section should also be added to the repository's root `README.md` to meet the requirement that the dataset's source and column meanings be documented there.

**Dataset:** *Detailed quarterly report, 2020–2026*  
**Source:** [Tenancy Services — Rental bond data](https://www.tenancy.govt.nz/about-tenancy-services/data-and-statistics/rental-bond-data/)

| Column | Meaning |
|---|---|
| `TimeFrame` | Quarterly reporting period represented by the observation. |
| `Location Id` | Geographic identifier for the SA2 area associated with the observation. |
| `Dwelling Type` | Dwelling category, such as House, Apartment, Flat, Room or Boarding House. `ALL` represents an aggregate category. |
| `Number Of Beds` | Bedroom/bed category, including values such as `1`, `2`, `3`, `4`, `5`, `6`, `9`, `5+` and `ALL`. |
| `Total Bonds` | Number of bonds recorded for the corresponding reporting selection. |
| `Active Bonds` | Number of active bonds represented by the selection. |
| `Closed Bonds` | Number of closed bonds represented by the selection. |
| `Median Rent` | Median weekly rent for the selection. |
| `Geometric Mean Rent` | Geometric mean of weekly rent, provided as an alternative measure for a skewed rent distribution. |
| `Upper Quartile Rent` | Upper-quartile rent measure. Tenancy Services describes its synthetic quartiles as estimates of the 75th percentile under a log-normal assumption. |
| `Lower Quartile Rent` | Lower-quartile rent measure. Tenancy Services describes its synthetic quartiles as estimates of the 25th percentile under a log-normal assumption. |
| `Log Std Dev Weekly Rent` | Log-scale standard deviation associated with the weekly rent distribution. |

Tenancy Services provides geometric means and synthetic quartiles as alternative measures because rents can cluster around round values, causing medians and quartiles to remain unchanged across reporting periods.

The published dataset uses SA2-2019 geographic definitions and applies privacy protections, including fixed random rounding and suppression for selections with fewer than five bonds. Recent figures may be provisional and can be revised.

## 8. Output files

The scripts generate the following processed files locally under `data/processed/`:

| Output file | Contents |
|---|---|
| `airbnb_christchurch_oct2025_jun2026_clean.csv` | Cleaned Christchurch Airbnb data for the nine monthly snapshots; 28,795 rows × 15 columns. |
| `tenancy_clean.csv` | Full cleaned Tenancy Services dataset across all available quarters; 226,080 rows × 12 columns. |
| `tenancy_christchurch_oct2025_jun2026_clean.csv` | Cleaned Tenancy data restricted to the three project quarters; 27,212 rows × 12 columns. |

The Airbnb output is produced by `R/02_airbnb_combine.R`. The two Tenancy outputs are produced by `R/03_tenancy_prepare.R`, using paths and dates from `R/pipeline_config.R`.

The processed CSV files are generated by code and are not intended to be manually edited.

## 9. Reproducibility

From the RStudio project root, with the required raw files present in `data/raw/` and the project's R packages installed, run:

```r
source("R/02_airbnb_combine.R")
source("R/03_tenancy_prepare.R")
```

The scripts use shared configuration for the project dates and output locations. They check required inputs, expected columns, data types, row counts, missingness patterns, duplicate keys and output creation.

The raw files remain separate from processed outputs. This allows team members to rerun the cleaning workflows without modifying the source data.

## 10. Trello presentation and project reflection

The team presented the updated Trello board and reflected on project progress and management during the week, as required by the deliverable.

The board provides a shared view of the cleaning tasks, their progress and the work required to complete the deliverable. The project uses documented R scripts and explicit cleaning decisions to make the processing steps traceable and reproducible.


## 11. Conclusion

Deliverable 4 produced a cleaned Airbnb dataset containing 28,795 rows and 15 columns, and a cleaned Tenancy Services dataset containing 27,212 rows for the three project quarters. The full cleaned Tenancy dataset is also retained separately.

The cleaning process preserves missing values where the correct values cannot be inferred, keeps the geographic and time identifiers needed for integration, and retains the rent and bond-count variables needed for subsequent analysis. The R scripts provide a reproducible way to regenerate the processed datasets for Deliverable 5.
