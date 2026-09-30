# Deliverable 7: Run and Explain the Automated Pipeline

Prepared for Sahil, Pooja and Claudia. Verified on 1 October 2026.

## 1. What this week's work means

Previously, somebody had to open several R scripts and run them in the right order. This week, a single command manages that order. It downloads the two requested new files if they are missing, applies the team's existing cleaning, updates geography and comparisons, builds the database, makes plots and checks the results.

The main contribution is **automation of the existing work**, not a new set of cleaning decisions. The pipeline reuses Pooja's cleaning scripts and the team's integration, validation and documentation work.

The command is:

```sh
Rscript run_pipeline.R
```

The period is October 2025 to August 2026. The new downloads are the **New Zealand summary listings.csv** snapshots dated **12 July 2026** and **13 August 2026**. They are not the larger listings.csv.gz files.

## 2. What has been completed

| Requirement | What now fulfils it |
|---|---|
| Apply Week 10 automation ideas | A root orchestration script, configuration, ordered stages, failure checks and an automatically generated report |
| Obtain July and August | Verified official source links in config/airbnb_sources.csv; downloads saved locally in data/raw |
| Preprocess with one command | Rscript run_pipeline.R |
| Add months to previous work | Eleven monthly inputs are processed into a new period-specific dataset |
| Produce updated plots | Three monthly Airbnb plots plus the two existing comparison plots, all in PNG and PDF |
| Avoid manually repeating everything | Existing scripts are reused; unchanged stages and previously queried coordinates can be reused |
| Check the result | 23 automation tests, 22 integration tests, 4 database tests and 11 saved-result checks: 60 passes |

The full run and the repeat run both succeeded. A separate calculation directly from the two new raw CSVs agreed with the saved Christchurch row counts and price medians. All five PNG plots were visually inspected.

Earlier result files were preserved: 47 previous output/prepared-data files were compared with the pre-change backup and were unchanged. The shared SA2 lookup cache was deliberately extended. This week's results are in separate folders.

## 3. First open the correct project

1. Open Finder.
2. Open Documents, then DATA422, then christchurch_rentalmarket_analysis.
3. Double-click christchurch_rentalmarket_analysis.Rproj. RStudio should open the project.
4. In RStudio, choose Session, then Restart R. This clears the previous R session, not your saved files.
5. Click the Console tab, normally in the bottom-left panel. It has a `>` prompt.
6. Type this and press Return:

```r
getwd()
```

On Sahil's Mac, the answer should be:

```text
/Users/sahilmann/Documents/DATA422/christchurch_rentalmarket_analysis
```

Do not type the `>` prompt itself. Do not open a new empty RStudio project. Do not run the old Sahil_Lab_Run.R or R/10_run_week10.R for this new deliverable: those are earlier workflows.

## 4. Run it in RStudio first

In the **Console**, type each line and press Return:

```r
source("run_pipeline.R")
results <- run_pipeline()
```

The first line loads the function's instructions. The second line is the **one function call that performs the work** and stores a convenient set of results in an object named `results`.

Wait until the `>` prompt returns. A successful run ends with:

```text
SUCCESS: updated outputs are in output/week11/2025-10_to_2026-08
```

There can be a lot of printed inspection output on the first run because the existing team scripts still print their checks. A repeated unchanged run is shorter. You do not need to click Run on each individual script.

The warning about missing tenancy quarters is expected for the current source file. It is explained in section 9. An `Error:` is different: stop and investigate; do not present old files as the new run's successful results.

### The command-line version for the tutor

1. Click RStudio's **Terminal** tab, next to Console. If it is absent, choose Tools, Terminal, New Terminal.
2. On Sahil's Mac, type this first to select the project folder:

```sh
cd "/Users/sahilmann/Documents/DATA422/christchurch_rentalmarket_analysis"
```

3. Then run the entire update with this one command:

```sh
Rscript run_pipeline.R
```

`cd` only chooses a folder. `Rscript` starts R and executes the file. The terminal run is a separate R process, so it **does not populate RStudio's Global Environment**. Its tables and plots are still saved to disk. Use the Console version above when you want `results` in Global Environment.

## 5. Exactly which tables to open

After the Console version finishes, run these lines in the Console:

```r
monthly_results <- results$monthly_summary
coverage_check <- results$coverage
run_steps <- results$stage_log
sanity_checks <- results$sanity_checks
real_example <- results$sanity_example
```

These are now easy-to-find tables under **Environment / Global Environment**, normally top right. Click the table name, or use the commands below. `View` needs a capital V.

### Table 1: monthly_results

```r
View(monthly_results)
```

It has 11 rows, one for each monthly snapshot. Show July and August near the bottom.

| Column | Meaning |
|---|---|
| snapshot_date | A first-of-month label used to group the month; not the exact scrape day |
| listings | Different listing IDs in that month's Christchurch data |
| priced_listings | Listings with an observed price |
| missing_prices | Listings with no price; they have not been filled with zero |
| median_nightly_price | The middle advertised nightly price among observed prices in that month |

Verified new results:

| Snapshot | Listings | With a price | Missing price | Median NZ$/night |
|---|---:|---:|---:|---:|
| July 2026 | 3,488 | 3,173 | 315 | 227 |
| August 2026 | 3,513 | 3,177 | 336 | 224 |

Say: "The pipeline incorporated two more snapshots automatically. The monthly median is $227 in July and $224 in August among listings with a recorded price. These are advertised prices, not realised revenue."

There are **35,796 listing-month rows** in the combined data, representing **4,264 distinct IDs** over the entire period. Do not call 35,796 different properties. July and August added 7,001 observations, not necessarily 7,001 newly appearing properties.

### Table 2: coverage_check

```r
View(coverage_check)
```

Look at `tenancy_quarter_available`. It is FALSE for July and August. This is a coverage limitation, not a failure to download the new Airbnb data. TRUE means that quarter exists in tenancy; it does not guarantee that every individual area matches.

Say: "We check dates before comparing rents. The new Airbnb months are available, but the tenancy file does not contain their quarter. We retain the Airbnb data and report the missing comparison."

### Table 3: run_steps

```r
View(run_steps)
```

`ran` means a stage executed. `reused` means its saved inputs, code, settings, package versions and outputs matched the previous stage checkpoint. A changed file causes the relevant stage to run again. Downstream stages rerun when their own inputs change.

The verified unchanged repeat run reused six of seven stages. The database is deliberately rebuilt and checked every run; all tests run every time as well. The CSV is replaced with the current run's record, so it describes the latest run.

### Table 4: sanity_checks

```r
View(sanity_checks)
```

This table contains 11 checks of the saved real outputs. All should say PASS. It checks unique keys, independent medians, the join, arithmetic and whether source fingerprints agree. It is one of four test reports, not the entire set of 60 tests.

### Table 5: real_example

```r
View(real_example)
```

The verified example is Christchurch Central, April-June 2026:

```text
Airbnb median nightly price = $253
Tenancy median weekly rent = $537
Equivalent nightly rent = 537 / 7 = $76.7142857
Gap = 253 - (537 / 7) = $176.2857143
```

The expected gap and saved gap agree. This is a descriptive comparison of two markets, not profit. It is an older matched quarter, not a July-August comparison.

## 6. Exactly where to open the charts

In RStudio's Files panel, normally bottom right, click:

```text
output > week11 > 2025-10_to_2026-08 > figures
```

Click a PNG filename to view it. PDF copies are available in the same folder. Cached runs do not recreate plot objects in Global Environment, which is why opening the saved image is the dependable approach.

| File | What to point out |
|---|---|
| week11_monthly_prices.png | Monthly Christchurch medians; July and August are highlighted. December-February gaps mean missing prices, not zero. |
| week11_monthly_listing_counts.png | Number of different IDs in each month. Do not add the bars to count unique properties across the whole period. |
| week11_new_month_price_distribution.png | Separate July and August histograms. Each bar counts listings in a NZ$25 price interval. |
| week9_price_gaps_top10.png | Updated execution of the existing area price-gap analysis. Only quarters with matching tenancy contribute. |
| week9_airbnb_vs_active_bonds_2026q2.png | Latest matched quarter is still April-June 2026. Active bonds are a rental indicator, not an exact count of distinct homes. |

The histogram is zoomed to the pooled 99th percentile, about $1,001. The 64 higher-priced observations remain in the dataset and summary statistics; the view has not deleted them. The existing extreme-price review, including $43,654, remains a team decision rather than a new automatic removal rule.

## 7. What each code file does

The names inside `stage()` are workflow labels. They do not renumber the existing R scripts.

| Order | File | Job in ordinary language |
|---|---|---|
| Controller | run_pipeline.R | Reads settings, establishes paths, downloads, runs stages in order, runs checks and reports success/failure |
| Settings | config/automation.R | Selects October 2025-August 2026 and the source/output folders |
| Source list | config/airbnb_sources.csv | Records verified month, exact scrape day and official URL for each new download |
| Shared settings | R/pipeline_config.R | Lets existing scripts use the controller's paths while retaining their older defaults when run alone |
| Helper functions | R/helpers/automation_helpers.R | Validates months/downloads, records checksums and decides whether a stage is safe to reuse |
| 1 | R/02_airbnb_combine.R | Reads all 11 monthly files, filters Christchurch, labels months, combines rows, applies existing cleaning and checks keys |
| 2 | R/03_tenancy_prepare.R | Applies existing tenancy cleaning and selects available study quarters; reports missing quarters |
| 3 | R/04_airbnb_summary.R | Saves numeric/category summaries and missing-value counts |
| 4 | R/05_query_geography.R | Looks up or reuses SA2 2019 area codes for coordinates, using layer 98970 |
| 5 | R/06_integrate_rental_data.R | Builds listing/quarter and area/quarter tables, joins Airbnb and tenancy by area plus quarter, records unmatched keys |
| 6 | R/07_build_database.R | Writes seven SQLite tables safely and checks the SQL join against R |
| 7 | R/08_week9_plots.R | Produces the existing rental-comparison charts for genuinely matched data |
| 7 | R/11_monthly_update_plots.R | Produces the three new monthly Airbnb charts and their supporting summary |
| Validation | tests/test_automation.R and existing tests | Tests both ordinary and deliberately incorrect small examples |
| Validation | R/09_validate_pipeline.R | Independently recalculates important saved results using base R |
| Report | R/12_automation_report.R | Reads saved summaries and writes RUN_SUMMARY.md with results and coverage caveats |

File 01 is not an extra requirement before the controller: it was the earlier single-month exploration. File 02 is the reusable monthly preparation/cleaning stage. Do not clean July and August manually in file 01 first.

### Walk through the controller from top to bottom

1. `source("R/helpers/automation_helpers.R")` loads reusable helper functions.
2. `run_pipeline <- function(...)` defines the procedure. `end_month` is an optional parameter; the default comes from configuration. `force = FALSE` permits reuse.
3. `month_date()` checks that dates mean an actual month and use YYYY-MM. `monthly_input_paths()` creates the eleven expected filenames.
4. `requireNamespace()` checks that required packages exist. The runner does not silently install new package versions during an analysis.
5. `file.path()` builds platform-appropriate paths. `dir.create()` makes output folders when necessary.
6. `sink()` sends execution output to a log. `on.exit()` restores temporary settings even when a later step fails. A run-status file records RUNNING, FAILED or SUCCESS.
7. `download_new_months()` checks the two source-list rows. A missing file is downloaded to a temporary path, checked as CSV and only then moved into raw data. A present file is not downloaded again.
8. `tools::md5sum()` calculates a content fingerprint. Byte-identical files labelled as different months are rejected for review. The exact verified URL and checksum are saved as receipts.
9. `options(rental.pipeline.overrides = ...)` temporarily supplies the new date range and separate output paths to the existing scripts. The original options are restored when the function exits.
10. `new.env()` gives intermediate calculations a workspace. Most temporary objects stay there instead of filling Global Environment.
11. Each `stage()` specifies required inputs, expected outputs and the existing script to source. `run_cached_stage()` compares fingerprints and runs the script only when needed, unless forced.
12. The controller reads the joined table and chooses the latest quarter that actually matches, rather than assuming the new Airbnb months have tenancy data.
13. Tests and the results-only report run. The controller reports SUCCESS only after those steps complete and returns the selected tables in `results`.

### Common R expressions you will see

| Expression | Plain meaning |
|---|---|
| `<-` | Store the right-hand result under the name on the left |
| `function(...)` | Define reusable instructions, with optional inputs |
| `list(...)` | Keep several named values/tables together |
| `results$monthly_summary` | Get the item named monthly_summary from results |
| `source(...)` | Read and execute another R script |
| `if (...) stop(...)` | Stop with an explanation if an unsafe condition is found |
| `for (...)` | Repeat an operation for each item |
| `map(...)` | Apply the same operation to each monthly file |
| `filter(...)` | Keep matching rows |
| `mutate(...)` | Add or change a column |
| `bind_rows(...)` | Stack months underneath one another |
| `group_by(...)` and `summarise(...)` | Calculate an answer separately for each group |
| `n_distinct(id)` | Count different listing IDs rather than all repeated rows |
| `|>` or `%>%` | Pass the current result into the next operation |
| `NA` | Missing information, not zero |
| `read_csv()` / `write_csv()` | Read a table from a CSV / save it to a CSV |

## 8. How the repeated-listing problem remains addressed

A snapshot is one observation of the market at a particular collection time. The same listing can appear in October, November and later months. Those are legitimate observations, so we preserve them rather than deleting every repeated ID.

For the monthly chart, the code requires one row per listing **within that month**. Therefore each listing gets one vote in that month's median.

For the quarterly area comparison, the code first calculates one representative median price for each listing within the quarter. It then takes the median of those listing-level prices for the area. A listing observed in three months does not get three votes while another gets one.

The small test remains: listing A costs $100 in three months, listing B costs $300 once. Pooling rows gives $100. Giving each listing one representative price gives median($100, $300) = $200.

The whole-period Christchurch Central answer similarly gives each eligible listing one median over its observed months. Its updated value is **$237.75** across 158 priced eligible listings. That is a different measure from the **$253 April-June** sanity-check example.

Locations can also change between snapshots. The current policy flags a listing-quarter assigned to multiple SA2 areas and excludes it from area comparisons instead of guessing. The monthly source observations are retained for inspection.

## 9. The important limitation to explain honestly

The tenancy filename ends in Q3-2026, but its actual latest TimeFrame is **2026-04-01**, the start label for **April-June 2026**. The script checks the contents, not merely the name.

Consequently:

- July and August Airbnb data are downloaded, cleaned, assigned SA2 codes, included in the database and shown in the monthly charts.
- They belong to Q3, but September is not included, so they represent two months of that quarter.
- No Q3 tenancy row exists to join with them. Older rent is not carried forward or renamed.
- There are 168 unmatched Airbnb area-quarter keys for Q3. This is not 168 failed API requests: all 35,796 monthly rows received an SA2 code in the verified run.
- The joined comparison table remains at 408 matched area-quarter rows; the latest count-comparison chart remains Q2.
- Across all study quarters, 270 Airbnb area-quarter keys are unmatched. The other 102 are older spatial/time coverage mismatches, retained in the unmatched-key report.

Say: "The automation updated everything supported by the available data. It also detected that the tenancy source does not yet cover the new quarter. We show the new Airbnb trends separately and do not invent a July-August long-term-rent comparison."

A future official tenancy file containing Q3 can be supplied through configuration and the same controller rerun. Review the source and any schema changes first. Neither the automation nor a passing test can create data that the source does not supply.

## 10. Files saved by this run

Within the project:

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
  stage_state/
output/week11/2025-10_to_2026-08/
  RUN_SUMMARY.md
  tables/
  figures/
  logs/
  run_status.rds
```

`raw` means original local input. `processed` means derived data. `tables` contains compact results and checks. `figures` contains charts. `stage_state` contains local checkpoints used to recognise unchanged stages.

The .sqlite file is a database stored in one file. The workflow has already built it; no separate database server is needed. The seven prepared tables preserve monthly observations, listing-quarter summaries, area-quarter summaries, tenancy detail, geography and the matched comparison.

### Optional: inspect the database in RStudio

After running the Console version:

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

This opens the database read-only, lists its tables, reads ten comparison rows and closes the connection. It does not rerun the API or modify the database.

## 11. What to demonstrate to the tutor, in order

1. Open run_pipeline.R and config/automation.R. Explain that the date range is a parameter, not eleven hand-written runs.
2. Open config/airbnb_sources.csv. Point out summary listings.csv, New Zealand, and the two exact scrape dates.
3. Run `Rscript run_pipeline.R` in Terminal. Wait for SUCCESS. Explain any REUSE records rather than claiming every stage was recomputed.
4. In Console, use the source-and-function version if you need fresh Global Environment tables. Open monthly_results and point out July and August.
5. Open the monthly price, count and distribution PNGs. Explain what the axes and missing-price gap mean.
6. Open coverage_check and explain the absent Q3 tenancy data.
7. Show run_steps, sanity_checks and the real_example calculation. Explain that the total 60 checks include small synthetic tests and independent checks of real saved data.
8. Show the team's Trello update and the automation commit on the GitHub sahil branch. Publishing a personal branch is separate from merging it into staging: ask the team to review the changes before that merge.

### A short explanation to practise

"For this deliverable, we automated our existing R pipeline. Instead of running each script manually, one command reads the configuration and runs the stages in dependency order. It downloads the July and August New Zealand summary listings when needed, filters Christchurch, applies our existing cleaning, adds SA2 2019 geography and updates the database and plots.

We preserve one row per listing per month, but give each listing one representative price in the quarterly comparisons. We check whether inputs or code changed before reusing saved work, and run all validation checks each time.

The updated dataset contains 35,796 listing-month records across eleven months. July's observed median is $227 and August's is $224. The current tenancy source only covers through June, so the pipeline identifies that limitation and does not fabricate a Q3 rent comparison. All 60 checks passed."

## 12. What teammates need, and what belongs on GitHub

Each teammate needs the updated code, the existing October-June monthly raw files, the raw tenancy file and the project package environment. The two new months download automatically if absent. Earlier raw files are prerequisites, not magically obtained from GitHub: raw data are deliberately ignored.

If packages are missing, open the project and run `renv::restore()` in Console, then follow the package manager's prompt. Do this as setup before the demonstration, not inside each stage. The controller itself does not change renv.lock.

New geographic coordinates need a working Koordinates API key in that person's local .Renviron, followed by an R session restart. Do not put a real key in an R script, Git commit, screenshot or group message. A complete existing cache can avoid new API requests.

Share the controller, config, helper changes, tests, this guide, summary CSVs, report and selected PNG/PDF figures. Do not commit .Renviron, renv/library, raw data, processed data, caches or local logs. .gitignore excludes these local files; previously tracked files must still be reviewed separately.

A suggested group message:

"I have completed and tested the automation for Deliverable 7 locally. One command now reuses our existing scripts to download/process July and August, update the SA2 integration and database, regenerate plots and run 60 checks. I have kept the previous outputs separate and written a run guide. One important finding: the tenancy file actually stops at April-June, so the new Airbnb months are shown but we cannot claim Q3 rent comparisons yet. The changes are ready for team review before merging."

Suggested Trello completion notes:

- Implemented root one-command orchestration using the existing team scripts.
- Downloaded and verified July/August New Zealand summary listings; recorded source dates and checksums.
- Extended local preparation and database tables to October 2025-August 2026.
- Added monthly median-price, listing-count and new-month histogram charts.
- Verified full run, unchanged repeat run, failure/recovery examples and 60 automated checks.
- Documented missing Q3 tenancy and retained the existing equal-listing weighting policy.
- Remaining team actions: review the changes, commit/push through the agreed branch workflow, rehearse, and record the presentation booking.

## 13. Troubleshooting and boundaries

| What you see | What to do |
|---|---|
| Cannot open run_pipeline.R or R/helpers/... | Open the correct .Rproj and check getwd(); you are probably in the wrong folder. |
| Missing monthly input | Put the named older CSV in data/raw with the expected listings_YYYY_MM.csv name. Do not rename one month's data as another. |
| Missing package | Restore the project environment with renv::restore(), then retry. |
| KOORDINATES_API_KEY missing | Configure a local key and restart R. Do not paste the key into the code. |
| API requests failed after retries | Check internet/key/service access and rerun. Successful lookups are retained; failures are retried. |
| Duplicate listing-month or invalid price | Investigate the source record. Do not remove the check merely to get a green result. |
| Tenancy does not cover every study quarter | Expected with the current file; open coverage_check and explain it. |
| results not found after a Terminal run | Terminal uses a separate process. Run the Console source-and-function commands to create results there. |
| Many stages say reused | Normal if their inputs, code, settings and outputs are unchanged. Tests still run. |
| Need to deliberately rebuild stage outputs | Use Rscript run_pipeline.R --force, or run_pipeline(force = TRUE). This still keeps existing raw downloads and the geography lookup cache. |
| Previous plots exist after an error | Check run_status.rds and the log. Do not interpret old or partly updated files as a successful new run. |

This is local on-demand automation, not a scheduled background service. A GitHub Actions CI workflow has not been added. The lecture discusses CI, but the supplied deliverable specifically requires the single-command update. The source list currently covers the requested July/August downloads; it does not automatically discover arbitrary future months.

## 14. Lecture and source basis

- Week 10 Monday, 10-monday-automation.pdf: automation, orchestration from the project root, ordered source() calls and reporting from saved results.
- Week 10 Tuesday, 10-tuesday-automation.pdf: configuration, clear failure handling and automated checks; CI is a related concept rather than a configured service here.
- [Inside Airbnb official data page](https://insideairbnb.com/get-the-data/).
- [New Zealand summary listings, 12 July 2026](https://data.insideairbnb.com/new-zealand/2026-07-12/visualisations/listings.csv).
- [New Zealand summary listings, 13 August 2026](https://data.insideairbnb.com/new-zealand/2026-08-13/visualisations/listings.csv).
- Team's existing local tenancy source and SA2 2019 API/cache workflow, layer 98970.

Implementation and this guide were prepared with OpenAI Codex assistance. The explanation follows the implemented and tested code; the team should review it and practise explaining the choices in its own words.
