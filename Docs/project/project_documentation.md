# Project Documentation

This document covers how the project is set up, how to get it running on a new computer, how the pipeline fits together, and how the team manages branches. Results for each deliverable are in the [`Reports/`](../Reports) folder. Coding conventions are in [coding_practices.md](coding_practices.md), and the automated run is explained step by step in [automation_guide.md](automation_guide.md).

---

## 1. Project overview

The project compares the short-term (Airbnb) and long-term (bond) rental markets in Christchurch. It:

- prepares monthly Inside Airbnb listing snapshots for Christchurch City;
- prepares Tenancy Services quarterly rental bond statistics;
- assigns each Airbnb listing a Stats NZ SA2 2019 area code through the Koordinates API;
- joins the two sources by area and quarter; and
- produces tables, charts and a SQLite database.

The comparison is descriptive. It does not estimate Airbnb profit, occupancy, housing displacement or causal effects.

**Team:** Sahil, Pooja and Claudia.

---

## 2. Project setup

The project was set up at the start of the course (Deliverable 1):

1. A GitHub repository was created and cloned locally.
2. An RStudio project was created at the repository root: `christchurch_rentalmarket_analysis.Rproj`.
3. `renv` was initialised to give the project its own package library. The package versions are recorded in `renv.lock`.
4. A `.gitignore` was configured to keep local, large and private files out of Git.
5. The folder structure below was created.

### Environment

| Item | Value |
|---|---|
| Language | R 4.5.2 (recorded in `renv.lock`) |
| IDE | RStudio, using the `.Rproj` file |
| Package management | `renv`; `.Rprofile` runs `source("renv/activate.R")` whenever the project opens |
| RStudio project settings | 2-space indentation (spaces, not tabs), UTF-8 encoding |

### Folder structure

```text
christchurch_rentalmarket_analysis/
├── christchurch_rentalmarket_analysis.Rproj   open this first
├── run_pipeline.R            one-command automated run (D7)
├── config/
│   ├── automation.R          study period and folders for the automated run
│   └── airbnb_sources.csv    verified download links for new Airbnb months
├── R/
│   ├── 00_setup_packages.R … 12_automation_report.R   numbered pipeline scripts
│   ├── pipeline_config.R     shared settings used by the numbered scripts
│   ├── helpers/              reusable functions (integration and automation)
│   └── tests/                empty placeholder files (the real tests are in tests/)
├── tests/                    automated tests
├── data/
│   ├── raw/                  original downloads — never edited (local only)
│   └── processed/            files produced by the scripts (local only)
├── output/
│   ├── tables/               summary and validation tables (CSV)
│   ├── figures/              charts (PNG and PDF)
│   └── week11/               results of the automated D7 run
├── Docs/                     project documentation (this folder)
├── Reports/                  one report per deliverable (D3, D4, D5, D7)
├── renv/  and  renv.lock     package environment
├── .Renviron.example         template for the local API key file
└── README.md
```

### What is and is not in Git

| In Git | Local only (ignored by `.gitignore`) |
|---|---|
| R scripts, config, tests, documentation | `data/raw/` (raw Airbnb and tenancy downloads) |
| `renv.lock`, `.Rprofile`, `renv/activate.R`, `.Rproj` | `data/processed/` (cleaned data, API caches, SQLite) |
| Small output tables and figures in `output/` | `.Renviron` (API key) |
| | `renv/library/`, `.Rhistory`, `.RData`, `.Rproj.user/` |
| | `output/week11/**/logs/` and `run_status.rds` |

The course asked for the large Airbnb datasets to stay off GitHub, so each team member keeps their own copy of the raw data.

---

## 3. Getting started on a new computer

1. **Clone the repository** and switch to your own branch (see section 6).
2. **Open the project** by double-clicking `christchurch_rentalmarket_analysis.Rproj`. All paths in the code are relative to this folder. Check with `getwd()` in the Console; the result should end in `christchurch_rentalmarket_analysis`.
3. **Restore packages.** In the Console run:

   ```r
   renv::restore()
   ```

   This installs the exact package versions recorded in `renv.lock` into the project's own library.
4. **Load packages** by running `source("R/00_setup_packages.R")` (see section 4).
5. **Add the raw data** to `data/raw/`:
   - `listings_2025_10.csv` … `listings_2026_06.csv`: Inside Airbnb New Zealand `listings.csv`, one per month (the July and August 2026 files are downloaded automatically by `run_pipeline.R`);
   - `listings.csv`: the June 2026 snapshot, used only by the exploratory script `01`;
   - `Detailed-Quarterly-Tenancy-Q1-2020-Q3-2026.csv`: the Tenancy Services detailed quarterly report.
6. **Set up the API key** (only needed when there are coordinates that have not been looked up before):
   - copy `.Renviron.example` to a new file named `.Renviron` in the project root;
   - replace the placeholder with the Koordinates API key (the team shares one key);
   - restart R (**Session > Restart R**).
7. **Run the pipeline:** `Rscript run_pipeline.R`. See [automation_guide.md](automation_guide.md).

### Known setup issues

| Problem | Cause and fix |
|---|---|
| `renv::restore()` fails to build `data.table` on macOS with `'libintl.h' file not found` | A missing header when compiling the locked version from source on current macOS/Xcode toolchains. Accepting renv's offer to install the latest pre-built binary works. A team run with the newer version reproduced the same results. |
| `Invalid or closed connection` when building the SQLite database | Previously caused by a `dbDisconnect()` call placed too early in `07_build_database.R`. This has been fixed; the connection is now closed with `on.exit()`. |
| `KOORDINATES_API_KEY missing` | `.Renviron` is missing or R was not restarted after creating it. |
| A script cannot find a file | The project was not opened through the `.Rproj`, so the working directory is wrong. |

---

## 4. `R/00_setup_packages.R`

This script loads the four packages the pipeline uses:

| Package | Used for |
|---|---|
| `tidyverse` | Reading/writing CSVs, data manipulation and plotting (`readr`, `dplyr`, `tidyr`, `purrr`, `stringr`, `ggplot2`) |
| `jsonlite` | Reading the JSON responses from the Koordinates API |
| `DBI` | The general database interface |
| `RSQLite` | Writing and reading the SQLite database |

It only **loads** packages with `library()`. It does not install or update anything. Package versions come from `renv.lock` via `renv::restore()`, which is run once during setup rather than inside the analysis. The automated runner (`run_pipeline.R`) checks that the same four packages are available and stops with "Run renv::restore() before the pipeline" if any are missing.

---

## 5. Pipeline design

### Inputs

| Input | Location | Used by |
|---|---|---|
| Inside Airbnb monthly `listings.csv` snapshots | `data/raw/listings_YYYY_MM.csv` | `02` (and `01` for the June file) |
| Tenancy Services detailed quarterly report | `data/raw/Detailed-Quarterly-Tenancy-Q1-2020-Q3-2026.csv` | `03` |
| Stats NZ SA2 2019 boundaries | Koordinates layer `98970`, queried through the API | `05` |
| Local API key | `.Renviron` (only for uncached coordinates) | `05` |
| Shared settings | `R/pipeline_config.R`, `config/automation.R`, `config/airbnb_sources.csv` | all stages |

### Scripts and what each produces

| Script | Job | Main outputs |
|---|---|---|
| `00_setup_packages.R` | Loads packages | – |
| `01_airbnb_prepare.R` | Exploratory single-month (June 2026) preparation. Not needed before `02`. | `airbnb_christchurch_2026_06_clean.csv` |
| `02_airbnb_combine.R` | Reads each month, filters to Christchurch City, adds `month_year`, combines and cleans | `airbnb_christchurch_oct2025_jun2026_clean.csv` |
| `03_tenancy_prepare.R` | Cleans the bond data and selects the study quarters | `tenancy_clean.csv`, `tenancy_christchurch_oct2025_jun2026_clean.csv` |
| `04_airbnb_summary.R` | Summary statistics of the cleaned Airbnb data | `output/tables/airbnb_*.csv` |
| `05_query_geography.R` | Looks up the SA2 2019 code for each coordinate (cached) | `airbnb_christchurch_with_sa2.csv`, `airbnb_sa2_2019_lookup_cache.csv` |
| `06_integrate_rental_data.R` | Builds listing-quarter and area-quarter tables and joins Airbnb and tenancy | `data/processed/database_ready/*.csv`, `output/tables/week9_*`, `week10_*` |
| `07_build_database.R` | Writes the seven tables to SQLite inside a transaction | `christchurch_rental_market.sqlite` |
| `08_week9_plots.R` | Price-gap and listing-vs-bond charts | `output/figures/week9_*` |
| `09_validate_pipeline.R` | Independently recalculates key results in base R | `week10_sanity_checks.csv`, `week10_sanity_example.csv` |
| `10_run_week10.R` | Offline runner for D6: tests plus stages `06`–`09` | – |
| `11_monthly_update_plots.R` | Monthly charts for the automated run | `week11_*` figures |
| `12_automation_report.R` | Writes `RUN_SUMMARY.md` for the automated run | `RUN_SUMMARY.md` |
| `run_pipeline.R` | Runs everything above in order with one command | `output/week11/<period>/`, `data/processed/week11/<period>/` |

### Database tables

| Table | One row represents | Rows (Oct 2025 – Jun 2026 run) |
|---|---|---:|
| `dim_geography` | one SA2 code and name | 171 |
| `fact_airbnb_listing_month` | one listing in one monthly snapshot | 28,795 |
| `fact_airbnb_listing_quarter` | one listing in one quarter | 10,355 |
| `fact_airbnb_sa2_quarter` | one eligible Airbnb area-quarter | 510 |
| `fact_tenancy_detail` | one area-quarter-dwelling-bedroom category | 27,212 |
| `fact_tenancy_sa2_quarter` | one area-quarter `ALL/ALL` tenancy record | 4,871 |
| `market_sa2_quarter` | one matched area-quarter comparison | 408 |

### Key design decisions

- **Equal listing weighting.** A listing seen in three months must not count three times. For each listing and quarter the pipeline takes the median of its monthly prices, then the median across listings in the area. Toy check: listing A at $100 in three months and listing B at $300 once gives a pooled median of $100, but the intended answer is median($100, $300) = $200. A test enforces this.
- **Time alignment.** Airbnb months map to the first day of their calendar quarter (Oct–Dec → `2025-10-01`, and so on), matching the tenancy `TimeFrame`.
- **Geography.** SA2 2019 is used because Tenancy Services states its bond data uses SA2-2019 definitions. A listing assigned to more than one SA2 within a quarter is flagged `multiple_sa2` and left out of area comparisons (36 listing-quarters, 108 monthly rows). Its rows are kept.
- **Join.** Tenancy uses the `Dwelling Type = ALL`, `Number Of Beds = ALL` row so overlapping categories are not double-counted. Both sides are checked to have unique keys, then joined with an `inner_join` on `sa2_code + comparison_quarter`. Unmatched keys are saved, not dropped silently.
- **Price gap.** Airbnb nightly median minus tenancy weekly median ÷ 7. This is a descriptive comparison of two different markets, not profit.

### Known limitations

- Airbnb prices are missing in the source files for December 2025 – February 2026.
- The highest Airbnb price ($43,654/night) is kept; whether it is genuine is still an open team decision.
- Bond counts are an administrative indicator, not an exact count of rental properties.
- The tenancy file's latest quarter is April–June 2026, so July and August 2026 Airbnb data has no tenancy match.

---

## 6. Branch management

| Branch | Purpose | Who pushes |
|---|---|---|
| `claudia`, `pooja`, `sahil` | Each team member's own working branch | That team member |
| `staging` | Shared integration branch where everyone's work is combined and checked | Everyone (from their own branch) |
| `main` | The reviewed, final version of the project | **Pooja only** |

### Workflow

1. Work and commit on **your own branch**.
2. Push your work to **`staging`**.
3. **Pooja** pushes `staging` to **`main`**. She is the only team member who can push to `main`.

### Rules

- Only Pooja pushes to `main`.
- Never commit `.Renviron`, raw or processed data, the SQLite database or `renv/library/`. `.gitignore` already excludes these.
- Commit `renv.lock` changes only when packages change (see [coding_practices.md](coding_practices.md#7-package-versions-renvlock)).

### Security note

An API key previously appeared in the Git history. Removing a file from tracking does not revoke a key that was already committed, so the key owner must rotate it, and any history clean-up must be coordinated with the whole team. Never show a key while screen sharing.

---

## 7. Data sources

### Inside Airbnb

Monthly New Zealand summary `listings.csv` files (not `listings.csv.gz`) from [insideairbnb.com/get-the-data](https://insideairbnb.com/get-the-data/), filtered to `neighbourhood_group == "Christchurch City"`. Columns kept after cleaning:

| Column | Meaning / why kept |
|---|---|
| `id` | Listing identifier (stored as text to avoid precision loss); tracks a listing across months |
| `host_id` | Host identifier (stored as text) |
| `neighbourhood` | Christchurch ward; geographic analysis |
| `latitude`, `longitude` | Location; used for the SA2 lookup |
| `room_type` | Entire home/apt, private room, hotel room or shared room |
| `price` | Advertised nightly price (NZ$) |
| `minimum_nights` | Minimum stay |
| `number_of_reviews` | Total reviews |
| `last_review` | Date of the most recent review |
| `reviews_per_month` | Average review rate |
| `calculated_host_listings_count` | Number of listings the host has |
| `availability_365` | Days available in the next year |
| `number_of_reviews_ltm` | Reviews in the last 12 months |
| `month_year` | Snapshot month (added by the pipeline), e.g. `2025_10` |

### Tenancy Services rental bond data

The *Detailed quarterly report* from the [Tenancy Services rental bond data page](https://www.tenancy.govt.nz/about-tenancy-services/data-and-statistics/rental-bond-data/). Tenancy Services states that the data comes from its bond database and is based on tenancy start date. It uses Stats NZ SA2-2019 area definitions and applies privacy protection: fixed random rounding, and suppression where fewer than five bonds are present. The figures are provisional because of a migration between bond management systems.

| Column | Meaning |
|---|---|
| `TimeFrame` | First day of the reporting quarter |
| `Location Id` | SA2-2019 area code (six digits); the source also contains the codes `-99` and `NULL` |
| `Dwelling Type` | House, Apartment, Flat, Room, Boarding House, or `ALL` |
| `Number Of Beds` | Bedroom category (e.g. `1`, `2`, `5+`) or `ALL` |
| `Total Bonds` | Number of bonds recorded for the selection |
| `Active Bonds` | Number of active bonds |
| `Closed Bonds` | Number of closed bonds |
| `Median Rent` | Median weekly rent |
| `Geometric Mean Rent` | Geometric mean of weekly rent, an alternative measure because rents cluster at round values |
| `Upper Quartile Rent` | Estimated 75th percentile of weekly rent (log-normal assumption) |
| `Lower Quartile Rent` | Estimated 25th percentile of weekly rent (log-normal assumption) |
| `Log Std Dev Weekly Rent` | Standard deviation of weekly rent on the log scale |

### Stats NZ geography

*Statistical Area 2 2019 (generalised)*, Koordinates layer `98970` ([layer page](https://datafinder.stats.govt.nz/layer/98970-statistical-area-2-2019-generalised/)). Code field `SA22019_V1_00`, name field `SA22019_V1_00_NAME`. Queried at `https://datafinder.stats.govt.nz/services/query/v1/vector.json`.

---

## 8. AI use and references

**AI tools used:**

- **OpenAI Codex**, used by Sahil to implement and test the D6 weighting correction and refactoring, the D7 automation, and early versions of the D6 and D7 documentation.
- **Claude (Anthropic)**, used by Claudia to review scripts `01`–`04` against the coding-practices lectures, to merge documentation, and to compile this documentation.

The team set the analytical objectives and is responsible for reviewing the definitions, exclusions and conclusions.

**Course references:**

- John Bryant, *Best Coding Practices (Revisited)*, DATA201/422, Week 9 (`09-monday-coding.pdf`, `09-tuesday-coding.pdf`).
- DATA201/422 Week 10 automation lectures (`10-monday-automation.pdf`, `10-tuesday-automation.pdf`).
