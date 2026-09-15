# DATA422 --- Airbnb Christchurch Rental Market

## Deliverable 3: Findings and Cleaning Decisions

### 1. Purpose

This document records the data-wrangling findings and cleaning decisions
for the Airbnb Christchurch rental-market dataset covering **October
2025 to June 2026**.

The workflow preserves the longitudinal structure of the data: each
monthly snapshot is retained as a separate observation period, so the
same listing can legitimately appear in multiple months.

------------------------------------------------------------------------

## 2. Source data and snapshot coverage

Nine Inside Airbnb `listings.csv` snapshots were used:

  Snapshot        Raw file
  --------------- ---------------------------------
  October 2025    `data/raw/listings_2025_10.csv`
  November 2025   `data/raw/listings_2025_11.csv`
  December 2025   `data/raw/listings_2025_12.csv`
  January 2026    `data/raw/listings_2026_01.csv`
  February 2026   `data/raw/listings_2026_02.csv`
  March 2026      `data/raw/listings_2026_03.csv`
  April 2026      `data/raw/listings_2026_04.csv`
  May 2026        `data/raw/listings_2026_05.csv`
  June 2026       `data/raw/listings_2026_06.csv`

The July and August 2026 files were not included because Deliverable 3
specifies the period **October 2025 through June 2026**.

Each source file was:

1.  Read into R.
2.  Filtered to `neighbourhood_group == "Christchurch City"`.
3.  Given `snapshot_month` and `snapshot_year`.
4.  Combined into one longitudinal Christchurch dataset.

------------------------------------------------------------------------

## 3. Christchurch filtering results

The number of Christchurch observations in each snapshot was:

  Snapshot          Christchurch listings
  --------------- -----------------------
  October 2025                      2,991
  November 2025                     3,047
  December 2025                     3,180
  January 2026                      3,057
  February 2026                     3,190
  March 2026                        3,227
  April 2026                        3,273
  May 2026                          3,361
  June 2026                         3,469
  **Total**                    **28,795**

The final combined dataset contains **28,795 observations**.

------------------------------------------------------------------------

## 4. Identifier handling

Airbnb `id` and `host_id` values were explicitly imported as **character
variables**:

``` r
col_types = cols(
  id = col_character(),
  host_id = col_character()
)
```

### Reason

Some Airbnb IDs are very large integers. Reading them as numeric values
can introduce precision loss or display them in scientific notation.
Treating them as character values preserves the original identifiers
exactly.

This is particularly important because listing IDs are used to track
listings across monthly snapshots.

------------------------------------------------------------------------

## 5. Longitudinal structure and duplicate findings

The combined dataset contains:

-   **4,117 unique listing IDs**
-   **2,103 unique host IDs**
-   **3,902 listing IDs that occur in more than one snapshot**

Repeated listing IDs across months are **expected** because the dataset
represents repeated monthly observations of the rental market.

### Duplicate checks

Three checks were performed:

#### Duplicate listing IDs within the same snapshot

No duplicate listing IDs were found within individual monthly snapshots.

**Decision:** no rows were removed for duplicate listing IDs.

#### Repeated listing IDs across snapshots

3,902 listing IDs occurred more than once across the nine-month dataset.

**Decision:** these observations were retained.

A listing appearing in all nine snapshots, for example, is not
considered a duplicate error; it represents the same listing being
observed at different points in time.

Therefore:

> `distinct(id)` must not be applied across the entire combined dataset.

#### Completely duplicated rows

The number of completely duplicated rows was:

**0**

------------------------------------------------------------------------

# 6. Missing-value investigation

Missingness was investigated before making cleaning decisions.

## Overall missingness after cleaning

  Variable                         Missing values   Percentage
  ------------------------------ ---------------- ------------
  `price`                                  10,667       37.00%
  `last_review`                             2,627        9.12%
  `reviews_per_month`                       2,627        9.12%
  `minimum_nights`                             37        0.13%
  All other retained variables                  0           0%

No observations were removed because of missing values.

------------------------------------------------------------------------

## 6.1 Price missingness

The price field was investigated at the raw-file level.

  Raw snapshot        Rows   Price missing   Price available
  --------------- -------- --------------- -----------------
  October 2025      47,752           2,493            45,259
  November 2025     48,624           3,055            45,569
  December 2025     49,899          49,899                 0
  January 2026      46,819          46,819                 0
  February 2026     48,692          48,692                 0
  March 2026        49,076           3,483            45,593
  April 2026        48,951           3,844            45,107
  May 2026          49,305           3,935            45,370
  June 2026         50,932           5,223            45,709

### Finding

`price` is completely missing in the **original source files** for:

-   December 2025
-   January 2026
-   February 2026

The Christchurch subset therefore contains:

-   December 2025: 3,180 missing prices
-   January 2026: 3,057 missing prices
-   February 2026: 3,190 missing prices

These are source-level missing values, not values introduced by
filtering or combining.

### Decision

`price` is **retained**.

No price values were:

-   imputed,
-   replaced with zero,
-   inferred from other listings,
-   or used as a reason to delete observations.

The affected observations remain available for analyses involving other
variables.

For analyses specifically requiring price, December 2025--February 2026
should be treated as having unavailable price information.

------------------------------------------------------------------------

## 6.2 Minimum nights missingness

There are only **37 missing `minimum_nights` values**, representing
approximately **0.13%** of the combined dataset.

They occur across:

  Snapshot          Missing values
  --------------- ----------------
  January 2026                  12
  February 2026                 16
  March 2026                     1
  April 2026                     3
  May 2026                       3
  June 2026                      2

The affected records contain valid listing IDs, names, room types and
other listing information.

### Decision

`minimum_nights` is **retained**, with the 37 values left as `NA`.

No value was arbitrarily replaced with 1 or another assumed minimum
stay, and no rows were removed.

------------------------------------------------------------------------

## 6.3 Last review and reviews per month

There are **2,627 missing values** in both:

-   `last_review`
-   `reviews_per_month`

A check of all observations where either field is missing showed:

**all 2,627 observations have `number_of_reviews = 0`.**

### Interpretation

The missingness is structurally meaningful. A listing with no reviews
does not have a last-review date or a review rate to report.

### Decision

Both `last_review` and `reviews_per_month` are **retained as `NA`**.

They were not converted to zero, text such as `"No reviews"`, or an
artificial date.

------------------------------------------------------------------------

## 6.4 Host name missingness

There was **one missing `host_name` value** in the April 2026 snapshot.

### Decision

`host_name` was removed from the analytical dataset because it is
descriptive host information and is not required for the quantitative
rental-market analysis.

------------------------------------------------------------------------

## 6.5 License

`license` contains **100% missing values** across the 28,795 combined
Christchurch observations.

It therefore contributes no information to the analysis.

### Decision

`license` was removed.

------------------------------------------------------------------------

# 7. Column retention and removal decisions

The cleaned dataset contains **17 columns**.

## Retained variables

  Variable                           Reason for retention
  ---------------------------------- ---------------------------------------------------------
  `id`                               Listing identifier for longitudinal tracking
  `host_id`                          Host-level identifier
  `neighbourhood_group`              Documents the Christchurch geographic filter
  `neighbourhood`                    Useful geographic analysis variable
  `latitude`                         Geographic/spatial analysis
  `longitude`                        Geographic/spatial analysis
  `room_type`                        Important rental-market characteristic
  `price`                            Core rental-market measure; source missingness retained
  `minimum_nights`                   Rental-condition measure
  `number_of_reviews`                Listing activity measure
  `last_review`                      Review activity information
  `reviews_per_month`                Review activity measure
  `calculated_host_listings_count`   Host-level characteristic
  `availability_365`                 Listing availability measure
  `number_of_reviews_ltm`            Recent review activity
  `snapshot_month`                   Monthly longitudinal dimension
  `snapshot_year`                    Yearly longitudinal dimension

## Removed variables

  -----------------------------------------------------------------------
  Variable                            Reason
  ----------------------------------- -----------------------------------
  `name`                              Listing title; not required for
                                      quantitative rental-market analysis

  `host_name`                         Descriptive host information; not
                                      required for the analysis

  `license`                           100% missing and therefore
                                      non-informative
  -----------------------------------------------------------------------

### Important principle

Variables were not removed merely because they had few unique values.

For example, `room_type` has only four categories but is an important
analytical variable. Similarly, `neighbourhood` has 16 categories and is
retained for geographic analysis.

The retention criterion was **analytical usefulness and data quality**,
not uniqueness alone.

------------------------------------------------------------------------

# 8. Descriptive structure of the cleaned dataset

The cleaned dataset contains:

**28,795 rows × 17 columns**

Selected uniqueness results from the combined dataset were:

  Variable                             Unique values
  ---------------------------------- ---------------
  `name`                                       4,854
  `id`                                         4,117
  `longitude`                                  3,799
  `latitude`                                   3,752
  `host_id`                                    2,103
  `host_name`                                  1,423
  `reviews_per_month`                          1,129
  `price`                                        821
  `number_of_reviews`                            776
  `last_review`                                  746
  `availability_365`                             366
  `number_of_reviews_ltm`                        161
  `calculated_host_listings_count`               109
  `minimum_nights`                                29
  `neighbourhood`                                 16
  `snapshot_month`                                 9
  `room_type`                                      4
  `snapshot_year`                                  2
  `neighbourhood_group`                            1
  `license`                                        1

The single value in `neighbourhood_group` is expected because the
dataset has already been filtered to Christchurch City. The single value
in `license` represents its complete missingness and was the basis for
removing that column.

------------------------------------------------------------------------

# 9. Numeric summary statistics

The retained numeric variables were summarised using count, missing
count, mean, median, minimum, maximum and standard deviation.

  --------------------------------------------------------------------------------------------------------
  Variable                               Count   Missing      Mean    Median       Min       Max        SD
  ---------------------------------- --------- --------- --------- --------- --------- --------- ---------
  `latitude`                            28,795         0     -43.6     -43.5     -43.9     -43.4    0.0763

  `longitude`                           28,795         0     173.0     173.0     172.0     173.0    0.0967

  `price`                               18,128    10,667       260       205        27    43,654       944

  `minimum_nights`                      28,758        37      1.79         1         1       365      5.51

  `number_of_reviews`                   28,795         0      70.4        26         0     1,584       121

  `reviews_per_month`                   26,168     2,627      2.35       1.7      0.01      16.6      2.19

  `calculated_host_listings_count`      28,795         0      58.3         3         1     1,586       189

  `availability_365`                    28,795         0       204       225         0       365       112

  `number_of_reviews_ltm`               28,795         0      19.0        10         0       185      23.5
  --------------------------------------------------------------------------------------------------------

`snapshot_year` is retained as a time variable but is not treated as an
analytical continuous measure.

------------------------------------------------------------------------

# 10. Categorical structure

The main categorical variables have:

-   `neighbourhood_group`: 1 category
-   `neighbourhood`: 16 categories
-   `room_type`: 4 categories
-   `snapshot_month`: 9 categories

The frequency tables are generated programmatically in the R workflow
for:

-   `room_type`
-   `neighbourhood`
-   monthly snapshot counts

------------------------------------------------------------------------

# 11. Data-cleaning principles applied

The cleaning workflow follows these principles:

1.  **Preserve source information where possible.**
2.  **Do not fabricate missing values.**
3.  **Do not delete observations solely because some fields are
    missing.**
4.  **Distinguish source-level missingness from cleaning errors.**
5.  **Treat structurally meaningful missingness appropriately.**
6.  **Preserve listing IDs exactly as character values.**
7.  **Preserve repeated listings across monthly snapshots.**
8.  **Check duplicates within snapshots rather than deduplicating the
    longitudinal dataset.**
9.  **Document every column-removal decision.**
10. **Keep the cleaning process reproducible through R scripts and saved
    outputs.**

------------------------------------------------------------------------

# 12. Final cleaned dataset

The final analytical dataset is:

``` text
data/processed/airbnb_christchurch_oct2025_jun2026_clean.csv
```

It contains:

-   **28,795 observations**
-   **17 variables**
-   nine monthly Christchurch snapshots
-   no observations removed for missingness
-   no exact duplicate rows
-   no duplicate listing IDs within a monthly snapshot
-   repeated listing IDs retained across months

------------------------------------------------------------------------

# 13. Reproducible outputs

The workflow also produces summary tables in:

``` text
output/tables/airbnb_missing_values.csv
output/tables/airbnb_numeric_summary.csv
output/tables/airbnb_categorical_summary.csv
output/tables/airbnb_room_type_summary.csv
output/tables/airbnb_neighbourhood_summary.csv
output/tables/airbnb_snapshot_summary.csv
```

These outputs provide reproducible evidence for the missing-value
analysis and descriptive summaries required for Deliverable 3.

------------------------------------------------------------------------

# 14. Final cleaning decision summary

### Removed

``` text
name
host_name
license
```

### Retained with missing values where appropriate

``` text
price
minimum_nights
last_review
reviews_per_month
```

### No row deletion

All **28,795 Christchurch observations** were retained.

### No imputation

No missing prices, minimum-night values, review dates, or review rates
were artificially filled.

### No longitudinal deduplication

Repeated listing IDs across monthly snapshots were intentionally
retained.

### Identifier protection

`id` and `host_id` were imported as character values to prevent
precision loss.

------------------------------------------------------------------------

## 15. Overall conclusion

The final dataset is a longitudinal Christchurch Airbnb dataset covering
October 2025 to June 2026. The main data-quality issue is the complete
absence of `price` in the original December 2025, January 2026 and
February 2026 source files. This missingness is preserved rather than
artificially corrected.

Review-related missingness is structurally associated with listings
having zero reviews, while the 37 missing `minimum_nights` values are
retained because there is insufficient evidence to determine replacement
values.

The cleaning process therefore prioritises **data fidelity,
transparency, and reproducibility** over aggressive standardisation or
deletion.
