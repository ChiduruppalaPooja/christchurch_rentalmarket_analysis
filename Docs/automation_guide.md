# Automation Guide

This guide walks through the automated pipeline: what it does, how to run it, how to check the results, and what each part of the code is responsible for. The results of the verified run are summarised in [D7](../Reports/D7.md).

---

## 1. What the automation does

Previously, someone had to open several R scripts and run them in the right order. Now **one command** does all of it:

```sh
Rscript run_pipeline.R
```

That command:

1. downloads any new Airbnb months listed in the config that are not already in `data/raw/`;
2. runs the team's existing cleaning, geography, integration, database and plotting scripts in the correct order;
3. skips stages whose inputs have not changed;
4. runs all the automated tests; and
5. writes a summary report.

The automation **reuses** the existing scripts. It does not introduce any new cleaning decisions.

The configured period is **October 2025 to August 2026**. The two newest files are the Inside Airbnb **New Zealand summary `listings.csv`** snapshots dated **12 July 2026** and **13 August 2026** (not the larger `listings.csv.gz` files).

---

## 2. Before you start

You need:

- the project open through `christchurch_rentalmarket_analysis.Rproj`;
- packages restored with `renv::restore()` (once, during setup; see [project_documentation.md](project_documentation.md#3-getting-started-on-a-new-computer));
- the October 2025 – June 2026 monthly files (`listings_YYYY_MM.csv`) and the raw tenancy file in `data/raw/`. These are not on GitHub. July and August download automatically if missing; and
- a Koordinates API key in `.Renviron`, but **only** if there are coordinates that are not already in the lookup cache.

---

## 3. Open the project correctly

1. In Finder, go to the project folder and double-click `christchurch_rentalmarket_analysis.Rproj`.
2. In RStudio choose **Session > Restart R**. This clears the R session, not your files.
3. In the **Console** (the `>` prompt), check the working directory:

   ```r
   getwd()
   ```

   The result should end in `christchurch_rentalmarket_analysis`.

Do not run `R/10_run_week10.R` for this; it is the earlier D6 runner. Do not prepare July and August by hand in `01_airbnb_prepare.R` either. That script is the earlier single-month exploration and is not part of the automated run.

---

## 4. Run the pipeline

### Option A: RStudio Console (results available in the Environment)

```r
source("run_pipeline.R")
results <- run_pipeline()
```

The first line loads the function. The second is the **single function call** that does all the work and stores the key tables in `results`.

### Option B: Terminal / command line

1. Open RStudio's **Terminal** tab, or **Tools > Terminal > New Terminal**.
2. Move to the project folder:

   ```sh
   cd "<path to>/christchurch_rentalmarket_analysis"
   ```

3. Run:

   ```sh
   Rscript run_pipeline.R
   ```

The Terminal version runs in a separate R process, so it **does not** create `results` in RStudio's Environment. The tables and plots are still saved to disk.

### What success looks like

When the `>` prompt returns, the last line should be:

```text
SUCCESS: updated outputs are in output/week11/2025-10_to_2026-08
```

- The first run prints a lot of inspection output because the existing scripts still print their checks. Later runs are shorter.
- A **warning** about missing tenancy quarters is expected (see section 9).
- An **`Error:`** is different. Stop and investigate. Do not present older files as the result of a new run.

### Options

| Want to… | Command |
|---|---|
| Rebuild every stage instead of reusing cached ones | `Rscript run_pipeline.R --force` or `run_pipeline(force = TRUE)` |
| Change the period | Edit `end_month` in `config/automation.R`, not the individual scripts |

Forcing a rebuild still keeps existing raw downloads and the geography lookup cache.

---

## 5. Check the results

After the Console version finishes, pull out the key tables:

```r
monthly_results <- results$monthly_summary
coverage_check  <- results$coverage
run_steps       <- results$stage_log
sanity_checks   <- results$sanity_checks
real_example    <- results$sanity_example
```

They appear under **Environment** (top right). Open each with `View()` (capital V).

### `monthly_results`: one row per monthly snapshot

| Column | Meaning |
|---|---|
| `snapshot_date` | First-of-month label for the snapshot (not the exact scrape day) |
| `listings` | Distinct listing IDs in that month's Christchurch data |
| `priced_listings` | Listings with an observed price |
| `missing_prices` | Listings with no price; these are **not** filled with zero |
| `median_nightly_price` | Median advertised nightly price among priced listings |

Results for the two new months:

| Snapshot | Listings | With a price | Missing price | Median $/night |
|---|---:|---:|---:|---:|
| July 2026 | 3,488 | 3,173 | 315 | 227 |
| August 2026 | 3,513 | 3,177 | 336 | 224 |

The combined data has **35,796 listing-month rows** covering **4,264 distinct listing IDs**. July and August added 7,001 observations, which are not necessarily 7,001 new properties. These are advertised prices, not realised revenue.

### `coverage_check`: is there tenancy data for each month?

Look at `tenancy_quarter_available`. It is `FALSE` for July and August, because the tenancy file has no July–September quarter. This is a gap in the tenancy data's coverage, not a failed download. `TRUE` means the quarter exists in the tenancy data; it does not guarantee that every area matches.

### `run_steps`: which stages ran

`ran` means the stage executed. `reused` means its inputs, code, settings, package versions and outputs all matched the previous checkpoint. On the verified repeat run, six of the seven stages were reused. The database stage is rebuilt and checked on every run, and all tests run every time.

### `sanity_checks`: checks of the saved real results

There are 11 checks, all of which should say `PASS`. They cover unique keys, independent median recalculation, the join, arithmetic and source-file fingerprints. This is one of four test reports; together they make **60 checks**:

| Report | Checks |
|---|---:|
| `week11_automation_tests.csv` | 23 |
| `week10_fixture_tests.csv` | 22 |
| `week10_database_tests.csv` | 4 |
| `week10_sanity_checks.csv` | 11 |

### `real_example`: a worked calculation

Christchurch Central, April–June 2026:

```text
Airbnb median nightly price = $253
Tenancy median weekly rent  = $537
Equivalent nightly rent     = 537 / 7 = $76.71
Gap                         = 253 − 76.71 = $176.29
```

The expected and saved gaps agree. This describes two different markets; it is not profit.

---

## 6. View the charts

In RStudio's **Files** panel, open:

```text
output > week11 > 2025-10_to_2026-08 > figures
```

Click a PNG to view it; PDF copies are alongside. (Cached runs do not recreate plot objects in the Environment, so opening the saved file is the reliable way to view them.)

| File | What to point out |
|---|---|
| `week11_monthly_prices.png` | Monthly Christchurch medians with July and August highlighted. The December–February gap means missing prices, not zero. |
| `week11_monthly_listing_counts.png` | Distinct IDs per month. Do not add the bars together to count unique properties. |
| `week11_new_month_price_distribution.png` | July and August histograms in $25 bins. The view is capped at the pooled 99th percentile (about $1,001); the 64 higher prices stay in the data. |
| `week9_price_gaps_top10.png` | The existing area price-gap analysis, re-run. Only quarters with tenancy data contribute. |
| `week9_airbnb_vs_active_bonds_2026q2.png` | The latest matched quarter is still April–June 2026. Active bonds are a rental indicator, not an exact count of homes. |

---

## 7. How the code fits together

### Files

| Role | File | Job |
|---|---|---|
| Controller | `run_pipeline.R` | Reads settings, sets paths, downloads, runs stages in order, runs checks, reports success or failure |
| Settings | `config/automation.R` | Study period and source/output folders |
| Source list | `config/airbnb_sources.csv` | Month, exact scrape date and official URL for each new download |
| Shared settings | `R/pipeline_config.R` | Lets the existing scripts use the controller's paths while keeping their own defaults when run alone |
| Helpers | `R/helpers/automation_helpers.R` | Validates months and downloads, records checksums, decides whether a stage can be reused |
| Stage 1 | `R/02_airbnb_combine.R` | Reads all monthly files, filters to Christchurch, labels months, combines and cleans |
| Stage 2 | `R/03_tenancy_prepare.R` | Cleans tenancy data, selects available study quarters, reports missing ones |
| Stage 3 | `R/04_airbnb_summary.R` | Numeric and categorical summaries, missing-value counts |
| Stage 4 | `R/05_query_geography.R` | Looks up or reuses SA2 2019 codes (layer `98970`) |
| Stage 5 | `R/06_integrate_rental_data.R` | Listing-quarter and area-quarter tables; joins Airbnb and tenancy on area + quarter; records unmatched keys |
| Stage 6 | `R/07_build_database.R` | Writes seven SQLite tables safely and checks the SQL join against R |
| Stage 7 | `R/08_week9_plots.R`, `R/11_monthly_update_plots.R` | Comparison charts and the new monthly charts |
| Validation | `tests/test_automation.R`, other tests, `R/09_validate_pipeline.R` | Small examples plus independent recalculation of saved results |
| Report | `R/12_automation_report.R` | Writes `RUN_SUMMARY.md` from the saved results |

The stage names in `stage()` are workflow labels; they do not renumber the R scripts.

### Walking through `run_pipeline.R`

You do not need to run these steps yourself. They explain what the controller does in order.

1. `source("R/helpers/automation_helpers.R")` loads the helper functions.
2. `run_pipeline <- function(end_month = NULL, force = FALSE)` defines the procedure. `end_month` defaults to the config value; `force = FALSE` allows cached stages to be reused.
3. `month_date()` checks that each month is a real YYYY-MM month, and `monthly_input_paths()` builds the expected filenames.
4. `requireNamespace()` checks the required packages are installed. The runner never installs packages itself.
5. `file.path()` builds paths and `dir.create()` makes the output folders.
6. `sink()` copies output to a log file. `on.exit()` restores settings even if a later step fails. A status file records `RUNNING`, `FAILED` or `SUCCESS`.
7. `download_new_months()` checks the source list. A missing file is downloaded to a temporary path, checked as a CSV, then moved into `data/raw/`. A file already present is not downloaded again.
8. `tools::md5sum()` fingerprints each file. Identical files labelled as different months are rejected. The URL and checksum are saved as download receipts.
9. `options(rental.pipeline.overrides = …)` temporarily gives the existing scripts the new date range and output paths. The original options are restored afterwards.
10. `new.env()` gives each stage its own workspace, so temporary objects do not fill the Global Environment.
11. Each `stage()` lists its inputs, outputs and script. `run_cached_stage()` compares fingerprints and runs the script only if something changed, or if forced.
12. The controller picks the latest quarter that **actually** has matched tenancy data, rather than assuming the new months do.
13. The tests and report run, and SUCCESS is reported only once they have finished. The selected tables are returned in `results`.

### Common R expressions

| Expression | Meaning |
|---|---|
| `<-` | Store the result on the right under the name on the left |
| `function(...)` | Define reusable instructions |
| `list(...)` | Keep several named items together |
| `results$monthly_summary` | Get the item called `monthly_summary` from `results` |
| `source(...)` | Run another R script |
| `if (...) stop(...)` | Stop with a message if something unsafe is found |
| `map(...)` | Apply the same operation to each monthly file |
| `filter()` / `mutate()` | Keep matching rows / add or change a column |
| `bind_rows()` | Stack months on top of each other |
| `group_by()` + `summarise()` | Calculate a result for each group |
| `n_distinct(id)` | Count different listing IDs, not repeated rows |
| `\|>` or `%>%` | Pass the result into the next step |
| `NA` | Missing information, not zero |

---

## 8. How repeated listings are handled

The same listing appears in many monthly snapshots. These are legitimate observations, so they are kept, but each listing must count once:

- **Monthly chart:** one row per listing **within each month**, so each listing gets one vote in that month's median.
- **Quarterly area comparison:** one median price per listing per quarter, then the median across listings in the area.

Example: listing A is $100 in three months and listing B is $300 once. Pooling rows gives $100; one price per listing gives median($100, $300) = **$200**.

The whole-period Christchurch Central median, calculated the same way, is **$237.75** across 158 priced listings. This is a different measure from the $253 April–June value in the worked example.

A listing that falls in more than one SA2 within a quarter is flagged and left out of area comparisons rather than guessed. Its monthly rows are kept.

---

## 9. Main limitation: tenancy coverage

The tenancy filename ends in `Q3-2026`, but its latest `TimeFrame` is **2026-04-01** (April–June 2026). The pipeline checks the contents, not the filename. As a result:

- July and August Airbnb data is downloaded, cleaned, given SA2 codes, stored in the database and shown in the monthly charts;
- it covers only two months of Q3, since September is not included;
- there is no Q3 tenancy data to join with, and older rents are **not** carried forward;
- there are **168** unmatched Airbnb area-quarter keys for Q3. These are not failed API requests: all 35,796 rows received an SA2 code;
- the matched comparison table stays at **408** area-quarter rows, and the latest count chart is still April–June; and
- across all quarters there are **270** unmatched Airbnb keys: 168 from Q3 and 102 earlier spatial/time mismatches.

When a tenancy file covering Q3 is available, set its path in `config/automation.R` and run the same command again, after checking the file for format changes.

---

## 10. Files produced

```text
config/
  automation.R
  airbnb_sources.csv
data/raw/
  listings_2026_07.csv
  listings_2026_08.csv
data/processed/week11/2025-10_to_2026-08/
  airbnb_clean.csv
  airbnb_with_sa2.csv
  tenancy_full.csv
  tenancy_study.csv
  christchurch_rental_market.sqlite
  database_ready/
  quality/
  stage_state/          checkpoints used to recognise unchanged stages
output/week11/2025-10_to_2026-08/
  RUN_SUMMARY.md
  tables/
  figures/
  logs/                 local only
  run_status.rds        local only
```

`raw` is original input, `processed` is derived data, `tables` holds compact results and checks, and `figures` holds the charts. The `.sqlite` file is a self-contained database; no database server is needed.

### Optional: look inside the database

```r
con <- DBI::dbConnect(
  RSQLite::SQLite(),
  dbname = file.path(results$processed_dir, "christchurch_rental_market.sqlite"),
  flags = RSQLite::SQLITE_RO
)
DBI::dbListTables(con)
database_preview <- DBI::dbGetQuery(con, "SELECT * FROM market_sa2_quarter LIMIT 10")
DBI::dbDisconnect(con)
View(database_preview)
```

This opens the database read-only, lists the tables, reads ten rows and closes the connection.

---

## 11. Troubleshooting

| What you see | What to do |
|---|---|
| Cannot open `run_pipeline.R` or `R/helpers/…` | Open the `.Rproj` and check `getwd()`; you are probably in the wrong folder. |
| Missing monthly input | Put the correctly named `listings_YYYY_MM.csv` in `data/raw/`. Do not rename one month's file as another. |
| Missing package | Run `renv::restore()`, then try again. |
| `KOORDINATES_API_KEY` missing | Add the key to `.Renviron` and restart R. Never paste the key into code. |
| API requests failed after retries | Check internet, key and service access, then re-run. Successful lookups are kept. |
| Duplicate listing-month or invalid price | Investigate the source record. Do not remove the check to get a pass. |
| Tenancy does not cover every study quarter | Expected with the current file; see section 9. |
| `results` not found after a Terminal run | The Terminal is a separate process. Use the Console version to get `results`. |
| Many stages say `reused` | Normal if nothing changed. Tests still run. |
| Old plots exist after an error | Check `run_status.rds` and the log. Do not treat old or partial files as a successful run. |

---

## 12. Scope

- This is **on-demand** automation run locally. It is not scheduled, and no GitHub Actions CI is configured.
- The source list covers the July and August downloads. Future months must be added to `config/airbnb_sources.csv`; they are not discovered automatically.
- **Do not commit** `.Renviron`, `renv/library/`, raw or processed data, caches or local logs.

### Earlier runner (D6)

`source("R/10_run_week10.R")` rebuilds the October 2025 – June 2026 results from the already prepared files without downloading anything or calling the API. It runs the fixture tests, stages `06`–`09` and the database tests, and writes to `output/tables/` and `output/figures/`. Use `run_pipeline.R` for the automated monthly update.

### Sources

- Week 10 automation lectures: `10-monday-automation.pdf` (orchestration from the project root, ordered `source()` calls, reporting from saved results) and `10-tuesday-automation.pdf` (configuration, failure handling, automated checks).
- [Inside Airbnb data page](https://insideairbnb.com/get-the-data/); [July 2026 file](https://data.insideairbnb.com/new-zealand/2026-07-12/visualisations/listings.csv); [August 2026 file](https://data.insideairbnb.com/new-zealand/2026-08-13/visualisations/listings.csv).

The automation code and the original guide were prepared with OpenAI Codex assistance. Claudia updated the guide after a test run.
