# Deliverable 7 — Automated Monthly Data-Wrangling Pipeline

| Item | Details |
|---|---|
| Deliverable | 7 — Automation |
| Study period | October 2025–August 2026 |
| Main command | `Rscript run_pipeline.R` |
| Main controller | `run_pipeline.R` |
| Documentation | This file contains the project report, run instructions, validation evidence and troubleshooting notes. |

## 1. Objective

The objective of Deliverable 7 was to automate the existing data-wrangling workflow so that the July and August 2026 Inside Airbnb datasets could be downloaded, cleaned, integrated and analysed with one command. The task focused on orchestrating existing scripts rather than manually repeating the analysis or introducing new cleaning rules.

The pipeline was extended to process eleven monthly Christchurch Airbnb snapshots from October 2025 through August 2026. It also reuses the existing tenancy preparation, SA2 geographic matching, equal-listing aggregation, SQLite database, plotting and validation workflows.

## 2. One-command execution

Run the following from the repository root:

```sh
Rscript run_pipeline.R
```

Alternatively, in the RStudio Console:

```r
source("run_pipeline.R")
results <- run_pipeline()
```

The command-line version executes the complete workflow in a separate R process. The RStudio Console version also returns a `results` object for inspecting summary tables.

The controller reads configuration, checks inputs and required packages, downloads the requested new monthly files when they are absent, runs pipeline stages in dependency order, reuses eligible cached stages, runs tests, and writes a run summary. It reports success only after the required stages and checks complete.

## 3. Data sources and inputs

| Input | Role |
|---|---|
| Inside Airbnb, October 2025–June 2026 | Existing monthly CSV files stored locally in `data/raw/` |
| Inside Airbnb, July 2026 | New Zealand summary `listings.csv`, scraped 12 July 2026 |
| Inside Airbnb, August 2026 | New Zealand summary `listings.csv`, scraped 13 August 2026 |
| Tenancy Services | Existing quarterly rental bond and rent dataset |
| Stats NZ SA2 2019 | Geographic definitions used to match Airbnb coordinates to tenancy area codes |
| Koordinates layer `98970` | Spatial lookup layer for SA2 2019 |

The two new source URLs are recorded in `config/airbnb_sources.csv`:

- July 2026: `https://data.insideairbnb.com/new-zealand/2026-07-12/visualisations/listings.csv`
- August 2026: `https://data.insideairbnb.com/new-zealand/2026-08-13/visualisations/listings.csv`

The requested files are the summary `listings.csv` files, not the larger `listings.csv.gz` downloads. The controller downloads a missing file to a temporary location, checks that it is a valid CSV, and then saves it under the expected local filename. It records checksums so that downloaded inputs can be identified and verified. Existing files are not downloaded again automatically.

The October–June Airbnb files and tenancy source are prerequisites and must already be available locally. Large raw and processed datasets, credentials, caches and local logs are not intended to be committed to GitHub.

## 4. Pipeline design and orchestration

The controller reuses the existing project scripts in the following order.

| Stage | Script | Responsibility |
|---|---|---|
| Controller | `run_pipeline.R` | Coordinates configuration, downloads, stages, validation and reporting |
| Configuration | `config/automation.R` | Defines the automated study period and input/output locations |
| Source register | `config/airbnb_sources.csv` | Records month, source date and official download URL |
| 1 | `R/02_airbnb_combine.R` | Reads and cleans the eleven monthly Airbnb snapshots |
| 2 | `R/03_tenancy_prepare.R` | Cleans tenancy data and identifies the quarters available in the source |
| 3 | `R/04_airbnb_summary.R` | Writes descriptive summaries and missing-value summaries |
| 4 | `R/05_query_geography.R` | Assigns SA2 2019 codes and reuses the coordinate lookup cache |
| 5 | `R/06_integrate_rental_data.R` | Creates listing-quarter and area-quarter summaries and joins the sources |
| 6 | `R/07_build_database.R` | Builds and checks the seven-table SQLite database |
| 7 | `R/08_week9_plots.R` | Regenerates the existing price-gap and rental-count comparison charts |
| 7 | `R/11_monthly_update_plots.R` | Creates the new monthly price, listing-count and price-distribution charts |
| Validation | `tests/test_automation.R` and existing tests | Runs automated test cases |
| Validation | `R/09_validate_pipeline.R` | Independently recalculates important saved results |
| Report | `R/12_automation_report.R` | Produces `RUN_SUMMARY.md` from saved results |

The controller uses stage checkpoints to determine whether outputs can safely be reused. A stage is reused only when its relevant inputs, code, settings, package versions and outputs match the saved checkpoint. Changed inputs cause the affected stage and downstream dependent stages to run again. The database is rebuilt and checked on each run, and tests are run each time.

## 5. Automation and coding practices

The implementation applies the following automation and software practices:

- **Configuration-driven execution:** the study period and output locations are defined in configuration rather than manually changed throughout multiple scripts.
- **Orchestration:** one root-level controller runs existing scripts in dependency order.
- **Reusable stages:** existing preparation, integration and validation code is reused instead of duplicating the same logic for July and August.
- **Input validation:** downloads are validated before being moved into the raw-data directory; required packages, dates and expected inputs are checked.
- **Failure handling:** the run records its status and log, and it should not report success if a required stage or check fails.
- **Caching:** unchanged stages and previously resolved geographic lookups can be reused, reducing unnecessary work.
- **Reproducibility:** source URLs, checksums, stage logs, test reports and a generated run summary provide evidence of what was processed.
- **Separation of concerns:** reporting reads saved results rather than repeating the cleaning and integration calculations.
- **Preservation of source data:** missing prices remain missing; extreme prices are not automatically removed; raw source files are not overwritten.
- **Independent validation:** the pipeline checks outputs with small test fixtures and separate calculations, rather than relying only on whether the scripts execute without errors.

## 6. Updated results

The verified run documented for this deliverable processed eleven monthly snapshots.

### 6.1 Monthly results for the new snapshots

| Snapshot | Christchurch listings | Listings with a price | Missing prices | Median advertised nightly price |
|---|---:|---:|---:|---:|
| July 2026 | 3,488 | 3,173 | 315 | NZ$227 |
| August 2026 | 3,513 | 3,177 | 336 | NZ$224 |

The two snapshots added 7,001 listing-month observations. They do not represent 7,001 necessarily distinct new properties, because a listing can appear in more than one month.

### 6.2 Study-period totals

| Measure | Recorded result |
|---|---:|
| Study period | October 2025–August 2026 |
| Monthly snapshots | 11 |
| Listing-month rows | 35,796 |
| Distinct listing IDs across the period | 4,264 |
| Airbnb rows assigned an SA2 code | 35,796 (100%) |
| Matched Airbnb/tenancy area-quarter rows | 408 |
| Unmatched Airbnb area-quarter keys | 270 |
| Christchurch Central whole-period median | NZ$237.75 per night |
| Eligible Christchurch Central listings with a price | 158 |

Listing-month rows are repeated observations across snapshots; they must not be described as a count of distinct properties across the whole period.

## 7. Updated plots

The run produces five PNG charts and corresponding PDF versions under:

`output/week11/2025-10_to_2026-08/figures/`

| Plot | Purpose |
|---|---|
| `week11_monthly_prices` | Monthly Christchurch median advertised nightly prices |
| `week11_monthly_listing_counts` | Distinct listing IDs observed in each monthly snapshot |
| `week11_new_month_price_distribution` | Separate price histograms for July and August |
| `week9_price_gaps_top10` | Updated existing comparison of median quarterly Airbnb/tenancy price gaps |
| `week9_airbnb_vs_active_bonds_2026q2` | Updated existing comparison of Airbnb listings and active tenancy bonds for the latest matched quarter |

The monthly price chart retains gaps for months with no observed Airbnb prices. The histogram is visually capped at the pooled 99th percentile (approximately NZ$1,001) to make the main distribution readable; the 64 higher-priced observations remain in the data. The view limit is not a cleaning rule.

## 8. Sanity checks and test evidence

The recorded successful run reported 60 passing checks:

| Test report | Number of checks |
|---|---:|
| Automation tests | 23 |
| Integration fixture tests | 22 |
| Database safety tests | 4 |
| Saved-output sanity checks | 11 |
| **Total** | **60** |

The checks cover automated download and stage behaviour, aggregation and weighting, keys and row counts, price-gap arithmetic, consistency between R and SQL joins, database integrity, and independent recalculation of saved outputs.

A hand-checkable example from Christchurch Central for April–June 2026 is:

\[
\text{Nightly gap} = 253 - \frac{537}{7}
= 176.2857 \approx \text{NZ\$176.29}
\]

Here, NZ$253 is the median Airbnb nightly price and NZ$537 is the median weekly tenancy rent. The expected and saved gap agreed in the documented run. This is a descriptive comparison, not an estimate of profit.

## 9. Important coverage limitation

The tenancy source filename refers to Q3 2026, but the latest actual `TimeFrame` in the supplied data is `2026-04-01`, representing April–June 2026. Therefore, the source does not yet provide July–September 2026 tenancy records.

The pipeline still processes and charts July and August Airbnb observations, but it does not carry older rents forward or create a tenancy comparison for the missing quarter. July and August are only two months of Q3; September is not included. The comparison table remains at 408 matched area-quarter rows, and the 168 new Q3 Airbnb-only keys are recorded as unmatched rather than treated as failed API lookups.

This is an important example of automation checking data coverage instead of assuming that a filename accurately describes the data inside it.

Other limitations remain:

- December 2025, January 2026 and February 2026 Airbnb prices are missing in the source and are not imputed.
- The extreme Airbnb price of NZ$43,654 remains pending the team's existing review.
- The pipeline runs on demand; it is not a scheduled background service and no GitHub Actions workflow is configured.
- Future months must be added to the source register and configuration before they can be included automatically.

## 10. Reproducibility

Run the command from the repository root after opening `christchurch_rentalmarket_analysis.Rproj`:

```sh
Rscript run_pipeline.R
```

To force stages to rebuild rather than reuse cached outputs:

```sh
Rscript run_pipeline.R --force
```

In RStudio, the equivalent is:

```r
source("run_pipeline.R")
results <- run_pipeline(force = TRUE)
```

If packages are missing, restore the project environment before running the pipeline. New geographic coordinates may require a valid local `KOORDINATES_API_KEY` in `.Renviron`; do not commit or display the key.

The run writes outputs to `data/processed/week11/2025-10_to_2026-08/` and `output/week11/2025-10_to_2026-08/`. The generated `RUN_SUMMARY.md`, monthly summary, coverage tables, download receipts, stage log, test reports, SQLite database and charts document the run. The exact output folders are controlled by the automation configuration.

## 11. Team contributions and reflection

The project documentation records the following contributions:

- **Sahil:** implemented the automation controller and related workflow changes.
- **Pooja:** developed the cleaning scripts reused by the automated workflow.
- **Claudia:** updated the automation guide after a test run.

The main improvement was turning a sequence of manually ordered scripts into one repeatable command. Central configuration, explicit stage dependencies, cached execution and validation reduce repeated manual work and make it easier to determine what was processed.

The automation also surfaced a data limitation: the tenancy file did not yet contain Q3 2026. Detecting and reporting this limitation is preferable to silently comparing July–August Airbnb data with an older rent quarter. The team should present its updated Trello board and reflect on progress, coordination and remaining review tasks during the required session.

## 12. Requirement checklist

| Requirement | Evidence |
|---|---|
| Apply Week 10 automation concepts | Root controller, configuration, ordered stages, caching, failure checks and generated report |
| Download July and August 2026 New Zealand `listings.csv` files | Official source URLs and checksums recorded in `config/airbnb_sources.csv` |
| Preprocess with one command | `Rscript run_pipeline.R` |
| Add the new months to prior analysis | Eleven monthly snapshots processed through cleaning and geographic enrichment |
| Generate updated plots | Three monthly plots and two regenerated comparison plots |
| Automate instead of manually repeating every stage | Existing scripts reused and unchanged stages eligible for cache reuse |
| Sanity-check outputs | 60 checks reported passing in the documented run |
| Present updated Trello board and reflect on management | To be presented and discussed by the team |

## 13. References and AI disclosure

- Inside Airbnb, [Get the Data](https://insideairbnb.com/get-the-data/).
- Inside Airbnb, [New Zealand July 2026 summary listings](https://data.insideairbnb.com/new-zealand/2026-07-12/visualisations/listings.csv).
- Inside Airbnb, [New Zealand August 2026 summary listings](https://data.insideairbnb.com/new-zealand/2026-08-13/visualisations/listings.csv).
- DATA422 Week 10 lecture materials on automation and orchestration.
- Project source code, configuration, test reports and generated run summary.


## 14. Running and inspecting the pipeline

### 14.1 Before running

Run the pipeline from the repository root after opening `christchurch_rentalmarket_analysis.Rproj` in RStudio. Confirm that the October 2025–June 2026 Airbnb CSV files and the Tenancy Services CSV are present in `data/raw/`. Restore the project package environment if required. If geographic lookups are not already cached, configure `KOORDINATES_API_KEY` in a local `.Renviron` file and restart RStudio. Leave `AIRBNB_INPUT` unset: use `Sys.unsetenv("AIRBNB_INPUT")` in R or `unset AIRBNB_INPUT` in the terminal; the automated runner rejects this override.

Do not commit `.Renviron`, API keys, raw or processed datasets, caches, or local logs.

### 14.2 Execute the pipeline

Run the complete workflow from a terminal at the repository root:

```sh
Rscript run_pipeline.R
```

Alternatively, run it from the RStudio Console:

```r
source("run_pipeline.R")
results <- run_pipeline()
```

To force eligible stages to rebuild rather than reuse cached outputs:

```sh
Rscript run_pipeline.R --force
```

or:

```r
results <- run_pipeline(force = TRUE)
```

The command-line invocation saves results to disk but does not populate the RStudio Global Environment. The RStudio invocation returns the `results` object for inspection.

### 14.3 Inspect generated summaries

After running through RStudio, use:

```r
View(results$monthly_summary)
View(results$coverage)
View(results$stage_log)
View(results$sanity_checks)
View(results$sanity_example)
```

The objects provide the monthly listing and price summaries, source-coverage information, stage execution/reuse status, independent saved-output checks, and a worked price-gap calculation. The generated `RUN_SUMMARY.md` and accompanying tables, logs, test reports, database and charts are saved under the configured Week 11 output directories.

### 14.4 Troubleshooting

| Symptom | Action |
|---|---|
| `run_pipeline.R` not found | Open the correct `.Rproj` and confirm that the working directory is the repository root. |
| An older monthly file is missing | Restore the correct original month file to `data/raw/`; do not relabel another month's data. |
| A required R package is missing | Restore the project environment with `renv::restore()`. |
| The Koordinates API key is missing | Configure `KOORDINATES_API_KEY` locally in `.Renviron`, then restart R. |
| The tenancy quarter is unavailable | Inspect the coverage table and report the source limitation; do not carry an older rent value forward. |
| A run fails but old figures remain | Inspect the current run status and logs. Do not treat figures from a previous successful run as evidence that the latest run succeeded. |
| Many stages are marked as reused | This is expected when their inputs, code, settings, package versions and outputs are unchanged. Validation and tests still run. |

## 15. Team reflection



A concise explanation of the result is:

 One command now downloads the July and August Airbnb snapshots when needed, reuses the existing cleaning and integration scripts, rebuilds the database, updates the monthly and comparison plots, and runs validation. The pipeline also checks the actual time coverage of the tenancy source. Because the source does not yet contain Q3 2026 tenancy records, July and August Airbnb trends are reported without inventing a new-quarter rent comparison.

## 16. Run-summary snapshot

The following values are a documentation snapshot of the recorded run. The pipeline-generated `RUN_SUMMARY.md` should be refreshed after each subsequent run.

- Study period: October 2025–August 2026, covering 11 monthly snapshots.
- Listing-month rows: 35,796.
- Distinct listing IDs across the period: 4,264.
- July 2026: 3,488 listings; 3,173 with prices; median observed nightly price NZ$227.
- August 2026: 3,513 listings; 3,177 with prices; median observed nightly price NZ$224.
- SA2 assignment: 35,796 of 35,796 rows (100%).
- Matched Airbnb/tenancy area-quarter rows: 408.
- Unmatched Airbnb area-quarter keys: 270.
- Christchurch Central whole-period median: NZ$237.75 per night across 158 eligible priced listings.
- Recorded validation: 23 automation checks, 22 integration fixture checks, 4 database checks and 11 saved-output checks, 60 in total.
- Tenancy coverage: the latest actual `TimeFrame` is `2026-04-01`, representing April–June 2026; Q3 2026 tenancy records are not present in the supplied source.
