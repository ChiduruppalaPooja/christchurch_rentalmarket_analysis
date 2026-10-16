# Deliverable 5 — Geographic Matching and Rental Market Integration

|                           |                                                                                                                                     |
| ------------------------- | ----------------------------------------------------------------------------------------------------------------------------------- |
| **Deliverable**           | 5                                                                                                                                   |
| **Course week**           | Week 9, with methodology refinements in Week 10                                                                                     |
| **Study period**          | October 2025 – June 2026                                                                                                            |
| **Main scripts**          | `R/05_query_geography.R`, `R/06_integrate_rental_data.R`, `R/07_build_database.R`, `R/08_week9_plots.R`, `R/09_validate_pipeline.R` |
| **Related documentation** | `Docs/project_documentation.md`, `Docs/coding_practices.md`                                                                         |

## 1. Objective

Deliverable 5 integrates the cleaned Airbnb listing data with Tenancy Services rental bond data to compare short-term and long-term rental markets by geographic area and time.

The Airbnb dataset identifies locations using latitude and longitude, whereas the Tenancy Services dataset uses a geographic `Location Id`. The project therefore used the Koordinates Query API and a compatible Stats NZ geographic layer to assign SA2 codes to Airbnb coordinates.

The completed workflow included:

- identifying the appropriate Stats NZ geographic layer;
- querying the Koordinates API and saving geographic matches;
- enriching the Airbnb dataset with SA2 codes and names;
- aligning monthly Airbnb observations with quarterly tenancy reporting periods;
- preparing both datasets at compatible geographic and temporal levels;
- joining the datasets to compare prices and rental activity;
- calculating the median Airbnb nightly price in Christchurch Central;
- identifying areas with the largest observed short-term versus long-term rental price gaps;
- comparing Airbnb listings with active tenancy bonds;
- creating presentation charts; and
- implementing an optional SQLite database and an independent validation script.

## 2. Data sources and geographic layer

### 2.1 Data sources

| Source                | Purpose                                                                                                 |
| --------------------- | ------------------------------------------------------------------------------------------------------- |
| Inside Airbnb         | Monthly Airbnb listing snapshots, including coordinates, advertised prices, room types and availability |
| MBIE Tenancy Services | Quarterly rental bond data, including geographic identifiers, bond counts and rent statistics           |
| Stats NZ              | SA2 geographic definitions, codes and names                                                             |
| Koordinates Query API | Spatial lookup of the SA2 area associated with each Airbnb coordinate                                   |

The Tenancy Services rental bond data uses **Statistical Area 2 (SA2) 2019** geographic definitions. The project therefore selected the Stats NZ *Statistical Area 2 2019 (generalised)* layer.

- **Koordinates layer ID:** `98970`
- **SA2 code field:** `SA22019_V1_00`
- **SA2 name field:** `SA22019_V1_00_NAME`
- **Layer page:** [https://datafinder.stats.govt.nz/layer/98970-statistical-area-2-2019-generalised/](https://datafinder.stats.govt.nz/layer/98970-statistical-area-2-2019-generalised/)
- **Tenancy Services source:** [https://www.tenancy.govt.nz/about-tenancy-services/data-and-statistics/rental-bond-data/](https://www.tenancy.govt.nz/about-tenancy-services/data-and-statistics/rental-bond-data/)

The 2019 geographic layer was selected because its area definitions correspond to those used by Tenancy Services. Using a newer geographic release could introduce changed codes or boundaries that would not align with the tenancy `Location Id` values.

### 2.2 Koordinates API

The geographic lookup uses the Koordinates vector-query endpoint:

`https://datafinder.stats.govt.nz/services/query/v1/vector.json`

The API request supplies the API key, layer ID, longitude as `x`, and latitude as `y`. It also uses the following parameters:

| Parameter               | Purpose                                                           |
| ----------------------- | ----------------------------------------------------------------- |
| `max_results=1`         | Requests at most one matching feature                             |
| `radius=0`              | Requires the point to be matched without a non-zero search radius |
| `geometry=false`        | Avoids returning geometry when only attributes are needed         |
| `with_field_names=true` | Requests named fields in the response                             |

The API key is read from the `KOORDINATES_API_KEY` environment variable, configured in a local `.Renviron` file. The key is not embedded in the R script or committed to GitHub.

## 3. Geographic matching workflow

The script `R/05_query_geography.R` assigns SA2 codes and names to the Airbnb records.

### 3.1 Coordinate preparation and API queries

The script:

1. Reads the prepared Airbnb dataset and checks that latitude and longitude are present and valid.
2. Extracts unique coordinate pairs, using six decimal places to construct a coordinate lookup key.
3. Tests a single API query before processing the remaining coordinates.
4. Processes uncached coordinates in batches of 100.
5. Uses up to four parallel workers on supported non-Windows systems.
6. Retries failed requests up to three times, with increasing delays between attempts.
7. Saves the lookup cache after each batch so completed work can be reused if processing is interrupted.
8. Joins the resulting SA2 codes and names back to the monthly Airbnb records.
9. Saves a match summary and a list of unmatched coordinates.

Querying unique coordinates avoids repeating API requests when listings recur across monthly snapshots. The cache also allows subsequent runs to query only coordinates that do not already have a successful or valid no-polygon result.

API failures and genuine no-polygon matches are recorded separately. Failed requests are retried on a subsequent run rather than being treated as confirmed geographic non-matches.

### 3.2 Geographic matching results

The recorded integration results show:

| Measure                                 | Result |
| --------------------------------------- | -----: |
| Airbnb rows processed                   | 28,795 |
| Airbnb rows matched to an SA2 2019 code | 28,795 |
| Geographic match rate                   |   100% |
| Unique matched SA2 areas                |    171 |

The enriched Airbnb dataset and coordinate cache were saved locally, allowing the integration to reuse the geographic results without querying every coordinate again.

## 4. Aligning the datasets by time

Airbnb data are collected monthly, whereas Tenancy Services reports quarterly. The project aligned both sources using the start date of each calendar quarter.

| Airbnb months         | `comparison_quarter` |
| --------------------- | -------------------- |
| October–December 2025 | `2025-10-01`         |
| January–March 2026    | `2026-01-01`         |
| April–June 2026       | `2026-04-01`         |

The tenancy `TimeFrame` values already use quarterly start dates. The `comparison_quarter` field therefore provides a common temporal key for the integration.

## 5. Integration method

### 5.1 Why the raw datasets were not joined directly

The Airbnb data contain multiple listing records per area and month. The tenancy dataset contains multiple records per area and quarter because it distinguishes dwelling types and bedroom categories.

Joining the raw datasets directly would create a many-to-many relationship, duplicating observations and potentially distorting prices and counts.

The integration script, `R/06_integrate_rental_data.R`, first aggregates each dataset to a compatible level.

### 5.2 Airbnb aggregation

The Airbnb workflow creates three levels of data:

1. **Listing-month:** one record for each listing in each monthly snapshot.
2. **Listing-quarter:** one record for each listing and quarter, with the listing's median observed monthly price.
3. **SA2-quarter:** one summary record per geographic area and quarter, including the median of eligible listing-level prices and unique listing counts.

Each listing contributes at most one price to an area-quarter median, regardless of how many monthly snapshots contain that listing. This equal-listing weighting prevents frequently observed listings from receiving additional weight merely because they occur in more monthly snapshots.

A listing-quarter with more than one observed SA2 is flagged as geographically ambiguous. It is excluded from area-level price and count comparisons, while the underlying monthly records are preserved for review.

### 5.3 Tenancy aggregation

The tenancy source contains several records for each SA2 and quarter, differentiated by dwelling type and bedroom category.

For the main market comparison, the script selects the aggregate record where:

- `Dwelling Type = ALL`
- `Number Of Beds = ALL`

This produces one tenancy summary per SA2 and quarter without duplicating the Airbnb summaries across dwelling and bedroom categories.

The selected record provides total, active and closed bond counts, together with the available rent statistics.

### 5.4 Join choice and keys

The Airbnb and tenancy summary tables are joined using an **inner join** on:

- `sa2_code`
- `comparison_quarter`

The inner join retains area-quarter combinations represented in both sources, allowing their prices and counts to be compared on the same geographic and temporal basis.

Unmatched Airbnb and tenancy keys are saved separately. This makes it possible to identify area-quarter combinations that could not be included in the comparison rather than silently discarding them.

The recorded results contain **408 matched SA2-quarter rows**.

### 5.5 Calculating the nightly price gap

Airbnb prices are advertised per night, while tenancy rents are reported per week. To compare them in a common unit, the median weekly tenancy rent is divided by seven.

The calculation for each matched area-quarter is:

`Nightly price gap = Median Airbnb nightly price − (Median tenancy weekly rent ÷ 7)`

The final area ranking uses the median of the available quarterly price gaps for each SA2.

A positive gap indicates that the median Airbnb nightly price exceeds the nightly equivalent of the median tenancy rent. This is a descriptive comparison between two different rental markets, not a calculation of profit or a causal estimate.

## 6. Key analytical results

The results in this section are drawn from the project's recorded integration outputs.

### 6.1 Geographic matching and join quality

| Measure                                                        |                 Result |
| -------------------------------------------------------------- | ---------------------: |
| Airbnb rows matched to an SA2 2019 code                        | 28,795 / 28,795 (100%) |
| Unique SA2 areas matched                                       |                    171 |
| Eligible Airbnb SA2-quarter keys                               |                    510 |
| Matched Airbnb/tenancy SA2-quarter keys                        |                    408 |
| Unmatched Airbnb SA2-quarter keys                              |                    102 |
| Tenancy SA2-quarter keys using the `ALL/ALL` aggregate         |                  4,871 |
| Tenancy-only SA2-quarter keys                                  |                  4,463 |
| Listing-quarters excluded because they had more than one SA2   |                     36 |
| Monthly Airbnb rows associated with ambiguous listing-quarters |                    108 |

The tenancy dataset covers New Zealand, while the Airbnb dataset is restricted to Christchurch. Tenancy-only keys are therefore expected because the two sources have different geographic coverage. Unmatched Airbnb keys may also arise when the corresponding aggregate tenancy record is unavailable or suppressed.

### 6.2 Christchurch Central — SA2 code `326600`

The Christchurch Central result uses one median observed price per eligible listing across the study period, followed by the median across eligible listings.

| Measure                             |     Result |
| ----------------------------------- | ---------: |
| Eligible monthly price observations |        695 |
| Unique eligible Airbnb listings     |        152 |
| Eligible listings with a price      |        151 |
| **Median Airbnb nightly price**     | **NZ$237** |

The reported median is a whole-period, equal-listing summary. It is not calculated by taking the median of the quarterly area medians.

### 6.3 Largest short-term versus long-term rental price gaps

The following table shows the areas with the largest recorded median quarterly nightly price gaps.

| SA2 area       | Quarters compared | Median Airbnb price per night | Median tenancy rent per night | Median gap per night |
| -------------- | ----------------: | ----------------------------: | ----------------------------: | -------------------: |
| Wigram South   |                 3 |                     NZ$389.00 |                      NZ$97.14 |        **NZ$288.29** |
| Wigram West    |                 3 |                     NZ$350.00 |                     NZ$100.00 |            NZ$247.14 |
| Lancaster Park |                 2 |                     NZ$287.00 |                      NZ$44.86 |            NZ$242.14 |
| Malvern        |                 3 |                     NZ$323.00 |                      NZ$85.71 |            NZ$231.57 |
| Holmwood       |                 3 |                     NZ$331.50 |                     NZ$114.29 |            NZ$222.07 |

**Wigram South** had the largest recorded median nightly price gap, at approximately **NZ$288.29 per night**.

The number of quarters compared is important when interpreting the ranking. The study period contains three quarters, but Airbnb prices are entirely missing in December 2025, January 2026 and February 2026. As a result, some areas have fewer usable quarterly price gaps than others.

The full top-ten ranking is saved in `output/tables/week9_plot_price_gaps_top10.csv`.

### 6.4 Airbnb listings versus active tenancy bonds

The project compared eligible unique Airbnb listings with active tenancy bonds by SA2. The following results show the five areas with the most eligible Airbnb listings in April–June 2026.

| SA2 area                   | Unique Airbnb listings | Active tenancy bonds |
| -------------------------- | ---------------------: | -------------------: |
| Christchurch Central-East  |                    352 |                  987 |
| Christchurch Central-South |                    290 |                  276 |
| Christchurch Central-North |                    199 |                1,131 |
| Christchurch Central-West  |                    131 |                  441 |
| Christchurch Central       |                    123 |                   42 |

The Airbnb counts represent distinct listing IDs with an unambiguous area assignment in the quarter. Active tenancy bonds are an administrative measure of rental activity and are not an exact count of distinct rental properties.

The optional comparison of Airbnb beds with long-term rental beds was not completed.

## 7. SQLite database

The optional SQLite extension was implemented in `R/07_build_database.R`.

The script imports the saved database-ready CSV files, writes them into SQLite, creates uniqueness indexes for the relevant keys and executes a SQL inner join between the Airbnb and tenancy area-quarter tables.

It then checks that the SQL price-gap results agree with the saved R integration results and runs SQLite's integrity check. The table row counts are saved to a summary CSV.

The database contains seven tables:

| Table                         | Grain                                       |   Rows |
| ----------------------------- | ------------------------------------------- | -----: |
| `dim_geography`               | One row per SA2                             |    171 |
| `fact_airbnb_listing_month`   | One listing per month                       | 28,795 |
| `fact_airbnb_listing_quarter` | One listing per quarter                     | 10,355 |
| `fact_airbnb_sa2_quarter`     | One row per SA2 and quarter                 |    510 |
| `fact_tenancy_detail`         | One tenancy category per SA2 and quarter    | 27,212 |
| `fact_tenancy_sa2_quarter`    | One row per SA2 and quarter using `ALL/ALL` |  4,871 |
| `market_sa2_quarter`          | One matched row per SA2 and quarter         |    408 |

The recorded database location is:

`data/processed/christchurch_rental_market.sqlite`

The database and database-ready files are generated locally and are excluded from GitHub through the processed-data configuration.

## 8. Charts and validation

### 8.1 Presentation charts

The script `R/08_week9_plots.R` generates two presentation charts from saved summary tables.

**Chart 1: Largest short-term versus long-term rental price gaps**

- Ranks SA2 areas by their median quarterly nightly price gap.
- Uses the equal-listing Airbnb price aggregation.
- Labels the number of quarters with a usable price gap.
- Does not represent the distribution of individual Airbnb listing-level gaps.

**Chart 2: Airbnb listings versus active tenancy bonds**

- Compares unique Airbnb listings with active tenancy bonds.
- Uses April–June 2026.
- Shows the ten matched SA2 areas with the most eligible Airbnb listings.
- Does not add counts across quarters.

Both charts are saved as PNG and PDF files in `output/figures/`. The selected chart data are also saved in `output/tables/`. The chart script reads prepared outputs, so it does not require another API query.

### 8.2 Independent validation

The script `R/09_validate_pipeline.R` independently recalculates important results using base R and compares them with the saved pipeline tables.

The validation covers:

- uniqueness of listing-month and listing-quarter keys;
- preservation of monthly rows when aggregating listings to quarters;
- agreement between independently calculated listing and area medians;
- exclusion of ambiguous geographic assignments from area summaries;
- agreement between the matched area-quarter keys and the intersection of the source summaries;
- correctness of the nightly price-gap arithmetic;
- consistency between the saved input files and their recorded file fingerprints;
- independent recalculation of the Christchurch Central whole-period median; and
- a hand-checkable example of a real area-quarter price-gap calculation.

The script writes `week10_sanity_checks.csv` and `week10_sanity_example.csv` to the configured summary directory. These outputs provide a record of the checks and a numerical example that can be inspected independently of the integration helpers.

## 9. Limitations and interpretation

1. **Different price units and markets:** Airbnb prices are advertised nightly prices, while tenancy figures are weekly bond-based rent measures. Dividing weekly rent by seven creates a common unit but does not make the two markets equivalent.
2. **Missing Airbnb prices:** December 2025, January 2026 and February 2026 have no observed Airbnb prices. Price summaries therefore use the available observations and do not represent complete price coverage across every month.
3. **Tenancy data suppression and rounding:** Tenancy Services applies privacy-related rounding and suppression, and recent figures may be revised. Some area-quarter aggregate records may consequently be unavailable.
4. **Ambiguous geography:** Listing-quarters assigned to more than one SA2 are excluded from area-level price and count comparisons. Their monthly source records remain preserved.
5. **Different geographic coverage:** The tenancy source covers New Zealand, while the Airbnb dataset covers Christchurch. Tenancy-only area-quarter keys are therefore not all failed Christchurch matches.
6. **Counts are not equivalent:** Airbnb listing counts and tenancy bond counts measure different aspects of rental activity. Active bonds should not be treated as a verified count of distinct rental properties.
7. **Limited time coverage:** The analysis covers three quarters, and missing Airbnb prices reduce the number of usable quarterly comparisons for some areas. The largest observed price gap should be interpreted alongside the number of quarters contributing to it.

## 10. Reproducibility and generated outputs

The workflow is run from the RStudio project root. The local `.Renviron` file must contain `KOORDINATES_API_KEY` before uncached geographic queries are run, and RStudio must be restarted after the environment variable is configured.

### 10.1 Run order

```r
# Package setup
source("R/00_setup_packages.R")

# Prepare the input datasets when required
source("R/02_airbnb_combine.R")
source("R/03_tenancy_prepare.R")

# Geographic matching and integration
source("R/05_query_geography.R")
source("R/06_integrate_rental_data.R")

# Optional database
source("R/07_build_database.R")

# Presentation charts
source("R/08_week9_plots.R")

# Independent validation
source("R/09_validate_pipeline.R")
```

`R/02_airbnb_combine.R` is needed when rebuilding the combined Airbnb dataset from the nine monthly source files, which are stored locally rather than on GitHub. Successful geographic lookups can be reused from the cache on later runs.

### 10.2 Generated outputs

| Location                           | Contents                                                                                                                                                                                                   |
| ---------------------------------- | ---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| `data/processed/`                  | Enriched Airbnb data, cleaned tenancy data and the SQLite database                                                                                                                                         |
| `data/processed/` coordinate cache | Reusable latitude/longitude-to-SA2 lookup results                                                                                                                                                          |
| `data/processed/database_ready/`   | Seven CSV tables used to build the SQLite database                                                                                                                                                         |
| `output/tables/`                   | API match summary, unmatched coordinates, join quality, monthly and quarterly price coverage, Christchurch Central median, price-gap ranking, count comparison, database row counts and validation outputs |
| `output/figures/`                  | Price-gap and Airbnb-versus-active-bonds charts in PNG and PDF formats                                                                                                                                     |

The exact output paths and filenames are controlled by `R/pipeline_config.R`.


## 11. Conclusion

Deliverable 5 integrated the monthly Christchurch Airbnb data with quarterly Tenancy Services rental bond statistics using compatible SA2 2019 geographic identifiers and a common quarterly time key.

The recorded analysis found a whole-period median Airbnb nightly price of **NZ$237 in Christchurch Central** and the largest observed median quarterly nightly price gap in **Wigram South, at approximately NZ$288.29**. The project also compared Airbnb listing counts with active tenancy bonds, generated presentation charts, saved reusable geographic lookups and implemented a SQLite database with a SQL join.

The resulting workflow provides a reproducible basis for comparing short-term and long-term rental indicators across Christchurch. Its results remain descriptive and must be interpreted in light of missing Airbnb prices, tenancy data suppression, geographic ambiguity and the differences between advertised nightly prices and weekly bond rents.
