# Deliverable 3 — Extended Airbnb Data Processing and Analysis

## Deliverable Information

| Item | Details |
|---|---|
| Deliverable | 3 |
| Study period | October 2025 – June 2026 |
| Geographic scope | Christchurch City, New Zealand |
| Programming language | R |
| Main processing script | `R/02_airbnb_combine.R` |
| Related preparation script | `R/01_airbnb_prepare.R` |
| Summary script | `R/04_airbnb_summary.R` |
| Main dataset | `data/processed/airbnb_christchurch_oct2025_jun2026_clean.csv` |
| Data source | [Inside Airbnb — Get the Data](https://insideairbnb.com/get-the-data/) |

## 1. Objective and Scope

The objective of Deliverable 3 was to extend the initial Airbnb data exploration from Deliverable 2 into a reproducible R workflow covering nine monthly datasets from October 2025 to June 2026.

The work involved downloading and loading the monthly Airbnb listing datasets, filtering the data to Christchurch City, adding a month-and-year identifier, preparing and combining the monthly datasets, examining missing values, producing summary statistics, and saving the resulting dataset for further analysis.

The deliverable also involved reproducing the previous week's no-code workflow and plots in R, presenting the updated Trello board, and reflecting on the team's project progress and management.

The main processing script, `R/02_airbnb_combine.R`, implements the multi-month Christchurch data pipeline. It also incorporates cleaning decisions associated with Deliverable 4. The separate `R/01_airbnb_prepare.R` script handles the June 2026 snapshot and its individual data-quality checks.

## 2. Dataset Source and Inputs

The data was obtained from Inside Airbnb, which publishes Airbnb listing datasets for research and analysis. The nine monthly New Zealand listing datasets covering October 2025 to June 2026 were downloaded and used in the project.

The files were stored locally in `data/raw/` and were not committed to GitHub because of their size.

| Snapshot | Input file |
|---|---|
| October 2025 | `listings_2025_10.csv` |
| November 2025 | `listings_2025_11.csv` |
| December 2025 | `listings_2025_12.csv` |
| January 2026 | `listings_2026_01.csv` |
| February 2026 | `listings_2026_02.csv` |
| March 2026 | `listings_2026_03.csv` |
| April 2026 | `listings_2026_04.csv` |
| May 2026 | `listings_2026_05.csv` |
| June 2026 | `listings_2026_06.csv` |

All filenames above are relative to `data/raw/`.

The combination script uses `R/pipeline_config.R` to obtain the configured study period and relevant file paths. It generates the expected monthly filenames and checks that the required files are available before processing.

The datasets contain listing and host identifiers, neighbourhoods, geographic coordinates, room types, prices, minimum-night requirements, review information, availability, and other listing attributes.

Each monthly file represents a snapshot of listings at a particular time. Consequently, the same property can appear in several monthly files. The combined dataset therefore represents **listing-month observations**, rather than unique properties across the entire study period.

## 3. R Data Processing Workflow

### 3.1 Loading and validating the monthly datasets

The main script, `R/02_airbnb_combine.R`, loads the `tidyverse` package and sources `R/pipeline_config.R`.

It constructs the expected monthly file list from the configured study period and checks that the filenames correspond to the required year-month sequence. The script also checks that the required input files exist.

The monthly CSV files are read into a list using `read_csv()`. Listing IDs and host IDs are imported as character values to preserve identifiers. The `last_review` field is handled as a date, while descriptive and categorical variables are retained in suitable data types.

The script checks for CSV parsing problems and verifies that the required columns are present. Column names and ordering are compared across the monthly files to maintain structural consistency before concatenation.

### 3.2 Filtering to Christchurch City

Each monthly dataset is filtered using the condition:

```r
filter(.x, neighbourhood_group == "Christchurch City")
```

Filtering is performed on every monthly dataset before the files are combined.

The script checks that each filtered dataset contains records and that no records from other geographic groups remain. This ensures that the subsequent analysis uses Christchurch City data only, as required by the assignment.

### 3.3 Adding the month-and-year column

A `month_year` column is added to each filtered dataset using the corresponding input filename.

Examples include:

- `2025_10` for October 2025.
- `2025_11` for November 2025.
- `2026_06` for June 2026.

This identifier records the snapshot from which each observation originated. It supports monthly comparisons and distinguishes repeated observations of the same listing across different snapshots.

The script validates the assigned labels against the expected monthly sequence. The identifier is based on the source filename rather than the `last_review` field.

### 3.4 Combining the monthly datasets

The nine filtered datasets are concatenated using `bind_rows()`:

```r
listings_chch_combined <- bind_rows(listings_chch)
```

The combined dataset is checked to ensure that it is not empty, that all expected snapshots are represented, and that all records remain within Christchurch City.

The script also compares the combined row count with the sum of the individual monthly row counts. This checks that concatenation preserves the monthly observations.

The recorded result was **28,795 listing-month rows across nine monthly snapshots**.

### 3.5 Inspecting the combined dataset

After concatenation, the dataset is inspected using `glimpse()`, `summary()`, and missing-value counts.

This stage provides an overview of the dataset structure, numerical distributions, categorical variables, and missing values. The findings inform the cleaning decisions applied in the pipeline.

The principal fields investigated include `price`, `minimum_nights`, `last_review`, `reviews_per_month`, `host_name`, and `license`.

## 4. Data Quality Findings and Cleaning Decisions

The multi-month pipeline incorporates cleaning decisions associated with Deliverable 4. The following sections document the decisions applied to the combined Christchurch dataset.

### 4.1 Missing-value findings

| Field | Missing values in the recorded run | Treatment |
|---|---:|---|
| `host_name` | 1 | Column removed because individual host names were not required for the planned analysis. |
| `price` | 10,667 | Column retained; missing values preserved as `NA`. |
| `minimum_nights` | 37 | Column retained; missing values preserved as `NA`. |
| `last_review` | 2,627 | Column retained; missing dates preserved as `NA`. |
| `reviews_per_month` | 2,627 | Column retained; missing values preserved as `NA`. |
| `license` | 28,795 | Column removed because every observation was missing for this field. |

### 4.2 Missing prices

The recorded inspection found that `price` was completely missing for December 2025, January 2026, and February 2026. The other months had approximately 5–8% missingness, according to the script's comments.

The consecutive months with completely missing prices indicate a systematic issue in the source data rather than ordinary missingness affecting individual listings.

The `price` column was retained, and missing values were preserved as `NA`. Prices were not imputed because the available data did not establish reliable replacement values.

Consequently, price analyses use observations with recorded prices. The absence of prices during these three months limits price comparisons across the full study period.

### 4.3 Missing review information

The review fields were examined to understand the relationship between missing values and listings with no recorded reviews.

The recorded findings were:

- All 2,627 missing `last_review` values were associated with `number_of_reviews == 0`.
- All 2,627 missing `reviews_per_month` values were associated with `number_of_reviews == 0`.

These values were retained as missing rather than automatically replaced with zero. A missing review date cannot be used as a valid elapsed-time measurement, and a missing monthly review rate should not automatically be treated as an observed rate of zero.

### 4.4 Column-retention decisions

The following fields were retained because they support listing identification, rental-market analysis, geographic analysis, or temporal comparisons:

- `id` and `host_id` for identifying listings and hosts.
- `neighbourhood` for local-area analysis.
- `latitude` and `longitude` for spatial analysis.
- `room_type` for accommodation-type comparisons.
- `price` and `minimum_nights` for rental-market analysis.
- `number_of_reviews`, `last_review`, `reviews_per_month`, and `number_of_reviews_ltm` for review-related analysis.
- `calculated_host_listings_count` for host listing counts.
- `availability_365` for availability analysis.
- `month_year` for identifying the monthly snapshot.

Four columns were removed:

| Column | Reason |
|---|---|
| `name` | Listing titles were not required for the planned rental-market analysis. |
| `host_name` | Host names were not required for the analysis, and one value was missing. |
| `neighbourhood_group` | All records had already been filtered to Christchurch City, making this field redundant. |
| `license` | All 28,795 observations were missing values for this field in the recorded run. |

These decisions removed columns rather than listing observations. The script checks that the row count remains unchanged after column removal.

### 4.5 Repeated listing IDs and duplicate records

Repeated listing IDs across different months are expected because the same property can appear in multiple snapshots. These records represent observations at different points in time and were retained.

The pipeline checks for duplicate listing IDs within each month and completely duplicated rows.

The recorded findings were:

- No duplicate listing IDs within the same month.
- No completely duplicated rows.
- 3,902 listing IDs appearing in more than one month.
- 2,338 listing IDs appearing in all nine months.

These results distinguish legitimate repeated observations across snapshots from duplicate records within an individual monthly dataset.

### 4.6 Single-snapshot quality checks

The related `R/01_airbnb_prepare.R` script investigates the June 2026 dataset separately. It examines missing review information, price quality, minimum nights, duplicate listing IDs, room-type categories, neighbourhood categories, geographic coordinates, and numerical values.

In this script, zero or negative prices and zero or negative minimum-night values trigger errors. High price values are inspected rather than automatically removed solely because they are unusually large.

The script also screens coordinates using broad thresholds to identify values requiring investigation. These checks belong to the June single-snapshot preparation workflow and are distinct from the nine-month combination process.

## 5. Results

The following results describe the recorded nine-month processing run.

### 5.1 Monthly listing counts

| Snapshot | Listing-month rows | Percentage of total |
|---|---:|---:|
| October 2025 | 2,991 | 10.39% |
| November 2025 | 3,047 | 10.58% |
| December 2025 | 3,180 | 11.04% |
| January 2026 | 3,057 | 10.62% |
| February 2026 | 3,190 | 11.08% |
| March 2026 | 3,227 | 11.21% |
| April 2026 | 3,273 | 11.37% |
| May 2026 | 3,361 | 11.67% |
| June 2026 | 3,469 | 12.05% |
| **Total** | **28,795** | **100%** |

June 2026 had the highest listing-month count among the nine snapshots. These counts describe observations per snapshot rather than unique properties across the entire study period.

### 5.2 Listing and host identifiers

| Measure | Result |
|---|---:|
| Listing-month rows | 28,795 |
| Distinct listing IDs | 4,117 |
| Distinct host IDs | 2,103 |
| Listing IDs appearing in more than one month | 3,902 |
| Listing IDs appearing in all nine months | 2,338 |
| Duplicate listing IDs within the same month | 0 |
| Completely duplicated rows | 0 |

The difference between 28,795 listing-month rows and 4,117 distinct listing IDs reflects the repeated observation of listings across monthly snapshots.

### 5.3 Missing-value summary

| Column | Missing values | Percentage |
|---|---:|---:|
| `price` | 10,667 | 37.04% |
| `last_review` | 2,627 | 9.12% |
| `reviews_per_month` | 2,627 | 9.12% |
| `minimum_nights` | 37 | 0.13% |

The original combined dataset also contained one missing `host_name` value and 28,795 missing `license` values. These columns were removed during cleaning and therefore do not appear in the final cleaned dataset's missing-value summary.

### 5.4 Numerical summary statistics

| Column | Non-missing count | Missing | Mean | Median | Minimum | Maximum | Standard deviation |
|---|---:|---:|---:|---:|---:|---:|---:|
| `price` | 18,128 | 10,667 | 260.20 | 205 | 27 | 43,654 | 943.72 |
| `minimum_nights` | 28,758 | 37 | 1.79 | 1 | 1 | 365 | 5.51 |
| `number_of_reviews` | 28,795 | 0 | 70.39 | 26 | 0 | 1,584 | 120.51 |
| `reviews_per_month` | 26,168 | 2,627 | 2.35 | 1.70 | 0.01 | 16.57 | 2.19 |
| `calculated_host_listings_count` | 28,795 | 0 | 58.30 | 3 | 1 | 1,586 | 188.53 |
| `availability_365` | 28,795 | 0 | 203.80 | 225 | 0 | 365 | 112.28 |
| `number_of_reviews_ltm` | 28,795 | 0 | 19.00 | 10 | 0 | 185 | 23.50 |
| `latitude` | 28,795 | 0 | -43.56 | -43.53 | -43.87 | -43.42 | 0.08 |
| `longitude` | 28,795 | 0 | 172.66 | 172.64 | 172.43 | 173.10 | 0.10 |

The recorded mean price is higher than the median, indicating a right-skewed distribution among observations with recorded prices. The large standard deviation also indicates substantial variability in listing prices. These results should be interpreted in the context of the missing-price issue.

### 5.5 Categorical summaries

| Column | Number of distinct values |
|---|---:|
| `neighbourhood` | 16 |
| `room_type` | 4 |
| `month_year` | 9 |

The recorded room-type distribution was:

| Room type | Listing-month rows | Percentage |
|---|---:|---:|
| Entire home/apt | 22,765 | 79.06% |
| Private room | 5,744 | 19.95% |
| Hotel room | 251 | 0.87% |
| Shared room | 35 | 0.12% |

The neighbourhood summary identified Central Ward as the neighbourhood with the most listing-month rows, at 10,554 (36.65%). The complete frequency table is available in `airbnb_neighbourhood_summary.csv`.

These frequencies describe combined monthly observations, not unique properties across the entire study period.

## 6. Summary Statistics and Output Generation

The `R/04_airbnb_summary.R` script generates summary tables from the saved dataset. The outputs document the structure, completeness, and distribution of the processed data.

The summary outputs include:

- Missing-value counts and percentages for each column.
- Numerical summaries containing non-missing counts, missing values, means, medians, minima, maxima, and standard deviations.
- Distinct-value counts for categorical columns.
- Room-type frequency counts.
- Neighbourhood frequency counts.
- Monthly snapshot summaries.
- Duplicate checks for listing IDs within a month, IDs repeated across months, and completely duplicated rows.

## 7. Reproduction of the Deliverable 2 Workflow and Plots

The Deliverable 2 workflow and its plots were reproduced in R as part of the extended analysis. The work connects the initial single-snapshot exploration to the wider multi-month Christchurch dataset.

### 7.1 Price distributions

The analysis compares listing-price distributions for New Zealand and Christchurch City, using clearly labelled geographic groups and consistent price units. Missing prices are treated as missing rather than assigned unsupported values.

The Christchurch component uses Christchurch-filtered data. The national comparison uses the relevant New Zealand dataset, since the Christchurch-only combined dataset cannot represent the national distribution.

### 7.2 Days since the last review

The analysis uses `last_review` to calculate the elapsed number of days since a listing's most recent review, relative to the applicable snapshot date.

Date fields are parsed consistently, and missing review dates remain missing rather than being assigned an artificial elapsed-time value. This treatment is important for listings with no recorded reviews.

### 7.3 Top 10% by review count

The analysis uses `number_of_reviews` to identify listings in the top 10% by review count and determine how many qualifying listings are located in Christchurch City.

The national comparison uses the national dataset to establish the top-decile threshold. This keeps the selection criterion consistent with the question of identifying highly reviewed listings across New Zealand, rather than only within Christchurch.

### 7.4 Plot reproduction and interpretation

Reproducing the earlier workflow in R maintains continuity between Deliverables 2 and 3 while allowing the analysis to be incorporated into the project’s code-based workflow. The plots support comparisons of listing prices, review recency, and review-count rankings.

## 8. Validation and Quality Assurance

The multi-month combination script incorporates checks to identify data-processing errors and maintain consistency across the nine monthly datasets.

| Check | Purpose |
|---|---|
| Expected input filenames | Ensures the inputs match the configured study period. |
| Missing input files | Stops execution if a required monthly dataset is unavailable. |
| CSV parsing | Identifies parsing problems in the source files. |
| Required columns | Verifies that expected variables are present. |
| Consistent column structure | Checks that monthly files have matching column names and ordering. |
| Christchurch filtering | Checks that filtered datasets contain Christchurch City records only. |
| Month-year labels | Validates labels against the corresponding filenames. |
| Snapshot count | Confirms that all expected months are represented. |
| Combined row count | Checks that concatenation preserves the sum of monthly row counts. |
| Cleaning validation | Confirms that selected columns are removed without changing the row count. |
| Duplicate checks | Checks for duplicate rows and listing IDs within each month. |
| Identifier validation | Checks that listing IDs are not missing or empty. |
| Price validation | Checks that observed prices are finite and nonnegative. |

The recorded run contained nine snapshots and 28,795 rows, with no duplicate listing IDs within a month and no completely duplicated rows.

## 9. Output Files and Repository Locations

### 9.1 Processed datasets

| File | Purpose |
|---|---|
| `data/processed/airbnb_christchurch_2026_06_clean.csv` | June 2026 Christchurch-only dataset produced by the single-snapshot preparation script. |
| `data/processed/airbnb_christchurch_oct2025_jun2026_clean.csv` | Combined and cleaned Christchurch dataset covering October 2025–June 2026. |

The processed datasets are stored locally rather than committed to GitHub because of their size.

### 9.2 Summary tables

The summary tables are stored under `output/tables/`.

| File | Purpose |
|---|---|
| `airbnb_missing_values.csv` | Missing-value counts and percentages by column. |
| `airbnb_numeric_summary.csv` | Numerical summary statistics. |
| `airbnb_categorical_summary.csv` | Distinct-value counts for categorical columns. |
| `airbnb_room_type_summary.csv` | Room-type frequency counts. |
| `airbnb_neighbourhood_summary.csv` | Neighbourhood frequency counts. |
| `airbnb_snapshot_summary.csv` | Listing counts by monthly snapshot. |

### 9.3 Raw datasets

The nine monthly source files are stored under `data/raw/`. They were downloaded for the project and remain local rather than being committed to GitHub. The source files are required to reproduce the monthly processing workflow.

## 10. Reproducibility

The workflow is organised into separate scripts for single-snapshot preparation, multi-month processing, and summary generation.

The following commands illustrate the documented execution sequence from the RStudio project root:

```r
source("R/01_airbnb_prepare.R")  # June 2026 single-snapshot preparation
source("R/02_airbnb_combine.R")  # Multi-month processing and cleaning
source("R/04_airbnb_summary.R")  # Summary-table generation
```

The multi-month processing script also depends on `R/pipeline_config.R`, which specifies the study period and relevant input and output paths. The required monthly files must be present in `data/raw/`, and the R project packages must be installed.

The June preparation script and the nine-month combination script serve different purposes: the former focuses on a single monthly snapshot, while the latter constructs the extended Christchurch dataset.

## 11. Team Progress and Project Management

The team used Trello to organise and communicate project tasks. The updated Trello board was presented, and the team reflected on project progress and management during the week.

The work included preparing the monthly datasets, developing and refining the R processing workflow, generating summary outputs, and extending the analysis beyond the initial Deliverable 2 exploration.

Pooja developed the initial preparation and combination scripts and the summary workflow. Sahil subsequently adjusted the combination script during later project work. These contributions formed part of the team's collaborative development of the data-processing pipeline.

The use of task tracking, shared code, and documented processing decisions supported coordination across the project and provided a record of the work completed.

## 12. Deliverable 3 Requirements

| Requirement | Implementation |
|---|---|
| Download the monthly datasets from October 2025 to June 2026 | Nine monthly New Zealand listing datasets were downloaded and used. |
| Load a dataset into R | The June 2026 snapshot is loaded in `R/01_airbnb_prepare.R`; the multi-month workflow loads the monthly datasets in `R/02_airbnb_combine.R`. |
| Filter to Christchurch and use the filtered data | Each monthly dataset is filtered to Christchurch City before concatenation. |
| Add a month-and-year column | The `month_year` field is extracted from the input filenames. |
| Prepare and concatenate all monthly datasets | The pipeline checks structural consistency and combines the nine filtered datasets using `bind_rows()`. |
| Produce summary statistics and missing-value counts | The summary workflow generates numerical, categorical, missing-value, room-type, neighbourhood, and monthly snapshot summaries. |
| Save the combined dataset to a new file | The processed dataset is saved as `data/processed/airbnb_christchurch_oct2025_jun2026_clean.csv`. |
| Reproduce the previous no-code workflow and plots | The Deliverable 2 analyses were reproduced in R for price distributions, review recency, and review-count rankings. |
| Present the updated Trello board and reflect on project management | The updated board was presented and the team reflected on its project progress and management. |

## 13. Limitations

The principal data limitation is the complete absence of prices in the December 2025, January 2026, and February 2026 snapshots. Price-related analysis across the nine-month period is therefore based on the available recorded prices and cannot provide complete monthly price coverage.

The combined dataset contains listing-month observations, so counts across the entire period must distinguish between repeated observations and unique listing IDs. Missing review dates and monthly review rates are retained as missing values rather than automatically replaced with zero.

The final combined dataset is a cleaned dataset rather than an untouched concatenation of the original monthly files, because four columns were removed during processing. These decisions are documented in Section 4.

## 14. Related Project Files

- `R/01_airbnb_prepare.R` — June 2026 single-snapshot preparation and quality checks.
- `R/02_airbnb_combine.R` — Multi-month Christchurch filtering, labelling, concatenation, cleaning, and output generation.
- `R/04_airbnb_summary.R` — Summary-table generation.
- `R/pipeline_config.R` — Study-period and pipeline configuration.
- [Deliverable2.md](Deliverable2.md) — Initial single-snapshot exploration and no-code workflow.
- [Deliverable4.md](Deliverable4.md) — Cleaning decisions associated with the combined Christchurch dataset.
- [coding_practices.md](../project/coding_practices.md) — Project coding practices.

## 15. Conclusion

Deliverable 3 extended the initial Airbnb exploration into a multi-month R-based data-processing workflow covering nine monthly snapshots from October 2025 to June 2026. The pipeline filters the data to Christchurch City, adds snapshot identifiers, combines the monthly datasets, checks data integrity, examines missingness, applies documented column-cleaning decisions, and saves a processed dataset for subsequent analysis.

The recorded results contain 28,795 listing-month observations, 4,117 distinct listing IDs, and 2,103 distinct host IDs. The summary analysis describes the numerical and categorical characteristics of the dataset, while the missing-value investigation identifies the complete absence of prices in three consecutive monthly snapshots as the main limitation for price comparisons.

The previous no-code workflow and plots were reproduced in R, and the team presented its updated Trello board and reflected on project progress and management. Together, the processing scripts, summary tables, cleaned dataset, and documentation establish the workflow and decisions used to complete Deliverable 3.
