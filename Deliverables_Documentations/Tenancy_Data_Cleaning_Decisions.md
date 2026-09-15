# DATA422 — Data Sources and Cleaning Documentation

## 1. Project datasets

This project combines two datasets describing the Christchurch rental market:

1. **Airbnb listing data** — monthly Airbnb listing snapshots for Christchurch City.
2. **Tenancy Services rental bond data** — detailed quarterly rental bond data from Tenancy Services.

The datasets are being prepared so that they can be compared in the next stage of the project, particularly in relation to rental prices and the number of available properties.

---

# 2. Airbnb listing dataset

## Source

The Airbnb data consists of monthly listing snapshots. For Deliverable 3, the project combined the following Christchurch City snapshots:

- October 2025
- November 2025
- December 2025
- January 2026
- February 2026
- March 2026
- April 2026
- May 2026
- June 2026

The data was filtered to:

```text
neighbourhood_group = "Christchurch City"
```

A `snapshot_month` and `snapshot_year` variable were added to identify the month and year represented by each snapshot.

The combined dataset therefore covers **October 2025 to June 2026**.

## Airbnb cleaning decisions

The combined Christchurch dataset was inspected for:

- missing values
- missing prices
- missing minimum-night values
- missing review information
- invalid prices
- invalid minimum-night values
- duplicate listing IDs
- categorical values
- geographic coordinates
- invalid numerical values
- unusually high prices

### Columns removed

The following columns were removed:

| Column | Reason |
|---|---|
| `name` | Listing name is descriptive text and is not required for the planned quantitative comparison. |
| `host_name` | Host identity is not required for the rental-price/property-availability comparison. |
| `license` | The column contained no observed values in the Christchurch data and therefore provided no analytical value. |

Other potentially useful variables were retained because they may be useful when comparing Airbnb listings with rental bond information.

In particular, **latitude and longitude were retained**, as required by the deliverable.

### Missing values

Missing values were not automatically removed.

For example:

- missing `price` values were retained as `NA`
- missing `minimum_nights` values were retained as `NA`
- missing `last_review` and `reviews_per_month` values were retained because these were associated with listings having no reviews

Removing these observations would reduce the available listings without sufficient evidence that the missing values represented invalid records.

### Outliers

High Airbnb prices were inspected rather than automatically removed.

A high price is not necessarily an error because genuine high-priced accommodation can exist in the Christchurch market. Therefore, prices were not removed solely because they were statistical or unusually large values.

### Duplicate listings

Duplicate listing IDs were checked within each monthly snapshot. Listing IDs occurring across different snapshots were not treated as duplicates because the same listing can legitimately appear in multiple monthly snapshots.

### Output

The cleaned combined Airbnb dataset is saved as:

```text
data/processed/airbnb_christchurch_oct2025_jun2026_clean.csv
```

The processing code is contained in:

```text
02_airbnb_combine.R
```

---

# 3. Tenancy Services rental bond dataset

## Source

The rental bond dataset was downloaded from the New Zealand **Tenancy Services** rental bond data page.

[Tenancy Services — Rental bond data](https://www.tenancy.govt.nz/about-tenancy-services/data-and-statistics/rental-bond-data/?utm_source=chatgpt.com)

The dataset used for this project is the **Detailed quarterly report**.

Tenancy Services states that the data comes from its tenancy bond database and is based on tenancy start date. The detailed quarterly data uses the **SA2-2019 area definitions from Statistics New Zealand**. Privacy protection is applied, including fixed random rounding and suppression where fewer than five bonds are present for a selection.

Tenancy Services also notes that the rental bond data is currently provisional because of migration between legacy and new bond management systems. Recent figures may therefore be incomplete, revised, or affected by reclassification and methodology changes.

## Original file

```text
data/raw/Detailed-Quarterly-Tenancy-Q1-2020-Q3-2026.csv
```

The source data contains quarterly observations from 2020 onwards.

---

# 4. Tenancy Services columns

The detailed quarterly dataset contains 12 columns.

| Column | Meaning |
|---|---|
| `TimeFrame` | Quarterly reporting period represented by the observation. |
| `Location Id` | Geographic identifier for the SA2 area associated with the observation. |
| `Dwelling Type` | Type of dwelling represented by the observation, such as `House`, `Apartment`, `Flat`, `Room`, or `Boarding House`. `ALL` represents the aggregate dwelling category. |
| `Number Of Beds` | Number of bedrooms/beds represented by the observation. Values include individual categories such as `1`, `2`, `3`, `4`, `5`, `6`, `9`, as well as `5+` and `ALL`. |
| `Total Bonds` | Number of bonds recorded for the corresponding time, location, dwelling type and bed category. |
| `Active Bonds` | Number of active bonds represented by the corresponding selection. |
| `Closed Bonds` | Number of closed bonds represented by the corresponding selection. |
| `Median Rent` | Median weekly rent for the corresponding selection. |
| `Geometric Mean Rent` | Geometric mean of weekly rent. Tenancy Services provides this as an alternative rent measure because rent distributions can be skewed and clustered around round values. |
| `Upper Quartile Rent` | Upper quartile rent measure representing the upper part of the rent distribution. Tenancy Services describes its synthetic quartiles as estimates of the 75th percentile under a log-normal assumption. |
| `Lower Quartile Rent` | Lower quartile rent measure representing the lower part of the rent distribution. Tenancy Services describes its synthetic quartiles as estimates of the 25th percentile under a log-normal assumption. |
| `Log Std Dev Weekly Rent` | Log-scale standard deviation associated with the weekly rent distribution. |

Tenancy Services explains that geometric means and synthetic quartiles are provided as alternative measures because rents tend to cluster at round values, which can cause medians and quartiles to remain unchanged for periods of time.

---

# 5. Tenancy timeframe selection

The Airbnb dataset covers:

```text
October 2025 – June 2026
```

The Tenancy Services dataset is quarterly, so the closest matching quarterly reporting periods are:

| Tenancy `TimeFrame` | Period represented |
|---|---|
| `2025-10-01` | October–December 2025 |
| `2026-01-01` | January–March 2026 |
| `2026-04-01` | April–June 2026 |

The bond dataset was therefore filtered to these three quarterly observations.

Before filtering:

```text
26 quarterly periods
```

After filtering:

```text
3 quarterly periods
```

The resulting timeframe-filtered dataset contained:

```text
27,212 rows
12 columns
```

---

# 6. Tenancy Services cleaning decisions

## 6.1 Invalid/non-geographic Location IDs

The filtered dataset contained two special `Location Id` values:

```text
NULL    94 rows
-99    127 rows
```

These were not treated as valid geographic location identifiers.

The `NULL` records also corresponded exactly to the 94 observations where the rent measures were recorded as `"NULL"`.

The `-99` records represented non-geographic/aggregate records rather than specific location IDs.

Because the next stage of the project requires geographic comparison with the Airbnb Christchurch data, these records were removed.

### Consequence

```text
Rows before removal: 27,212
Rows removed:           221
Rows remaining:       26,991
```

Therefore:

```text
27,212 → 26,991 rows
```

No other rows were removed during this cleaning stage.

---

## 6.2 Rent values recorded as `"NULL"`

The five rent-related columns were initially stored as character values because the source contains the text value `"NULL"`.

The following columns were converted from character to numeric:

```text
Median Rent
Geometric Mean Rent
Upper Quartile Rent
Lower Quartile Rent
Log Std Dev Weekly Rent
```

The source value `"NULL"` was converted to `NA`.

The 94 records containing `"NULL"` rent values were the same records with `Location Id = "NULL"` and were therefore removed by the geographic filtering step.

No rent observations remained missing after the Location ID filtering.

---

## 6.3 Number of Beds

`Number Of Beds` was retained as a character variable.

The source contains meaningful categories including:

```text
ALL
1
2
3
4
5
5+
6
9
```

There were also 858 missing values.

The missing values were retained rather than removed or imputed because there was insufficient evidence to infer the number of beds from the other variables.

Similarly, `ALL` and `5+` were retained because they are source categories rather than errors.

### Consequence

```text
858 records have missing Number Of Beds
```

No rows were removed because of missing bed information.

---

## 6.4 Dwelling Type

The following dwelling categories were observed:

```text
ALL
House
Apartment
Flat
Room
Boarding House
```

These categories were retained because they provide useful information for future rental-market analysis.

No categories were removed or recoded.

---

## 6.5 Numeric quality checks

The following numeric variables were checked for negative values:

- `Total Bonds`
- `Active Bonds`
- `Closed Bonds`
- `Median Rent`
- `Geometric Mean Rent`
- `Upper Quartile Rent`
- `Lower Quartile Rent`
- `Log Std Dev Weekly Rent`

No negative values were found.

No numeric values were therefore removed or modified on the basis of these checks.

---

## 6.6 Bond-count consistency check

An additional check was performed to determine whether:

```text
Total Bonds = Active Bonds + Closed Bonds
```

This relationship did **not** hold for the majority of observations.

Only 351 of the 26,991 observations matched this equality, while 26,640 did not.

Therefore, no attempt was made to recalculate or alter `Total Bonds`, `Active Bonds`, or `Closed Bonds`.

The source values were retained unchanged because imposing an unsupported mathematical relationship could incorrectly alter the original data.

---

# 7. Current Tenancy dataset

After the cleaning described above, the dataset contains:

```text
Rows:    26,991
Columns: 12
```

The required fields:

```text
TimeFrame
Location Id
```

are both retained.

The final column structure is:

```text
TimeFrame
Location Id
Dwelling Type
Number Of Beds
Total Bonds
Active Bonds
Closed Bonds
Median Rent
Geometric Mean Rent
Upper Quartile Rent
Lower Quartile Rent
Log Std Dev Weekly Rent
```

The current processing code is:

```text
03_tenancy_inspect.R
```

and the processed dataset is intended to be saved under:

```text
data/processed/
```

---

# 8. Important geographic note

The detailed quarterly Tenancy Services dataset uses SA2-2019 geographic identifiers rather than Christchurch City names. Therefore, `Location Id` values must be mapped to the Christchurch geographic area before the dataset can be described as a Christchurch-only bond dataset.

The current cleaning stage has removed non-geographic `Location Id` values but has **not yet removed valid geographic IDs belonging to other parts of New Zealand**.

This geographic mapping will be completed before the two datasets are combined for the next stage of the project.

---

# 9. Reproducibility

All cleaning is performed programmatically in R using `tidyverse`.

The raw datasets are kept separate from processed datasets:

```text
data/
├── raw/
└── processed/
```

The processed datasets are generated from the R scripts rather than being manually edited.

This allows all team members to rerun the processing code and reproduce the same preprocessing steps.