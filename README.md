# Christchurch Rental Market Analysis

## Overview

This project analyses Christchurch's rental market using Airbnb listing snapshots, Tenancy Services rental-bond data, and geographic information. It develops a reproducible R workflow for data acquisition, cleaning, geographic integration, validation, analysis, and visualisation.

The repository README provides the project overview and essential run instructions. Detailed implementation decisions, validation evidence, and deliverable-specific instructions are maintained in [`Deliverables_Documentations/`](Deliverables_Documentations/).

## Quick start

The project uses **R 4.5.2**, RStudio, and [`renv`](https://rstudio.github.io/renv/).

1. Clone the repository and open the `.Rproj` file in RStudio.
2. Restore the R package environment:

   ```r
   renv::restore()
   ```

3. Ensure the required local input files are available in `data/raw/` (see [Data requirements](#data-requirements)).
4. Run the Deliverable 7 pipeline from the repository root:

   ```sh
   Rscript run_pipeline.R
   ```

   Or run it from the RStudio Console:

   ```r
   source("run_pipeline.R")
   results <- run_pipeline()
   View(results$monthly_summary)
   ```

For exact setup, run steps, expected outputs, validation details, and troubleshooting, see the [Week 11 Automation Guide](Deliverables_Documentations/Week11_Automation_Guide.md).

## Data sources

- **Airbnb:** [Inside Airbnb](https://insideairbnb.com/) listing snapshots for October 2025–August 2026.
- **Tenancy data:** [Tenancy Services](https://www.tenancy.govt.nz/) / MBIE rental-bond data.
- **Geographic data:** Stats NZ SA2 2019 geography, with coordinate enrichment through the [Koordinates](https://koordinates.com/) Query API.

Airbnb snapshots and tenancy data are used at different time resolutions. The project documents the aggregation and join rules in its deliverable documentation. The configured tenancy source currently covers April–June 2026; the pipeline does not invent a later-quarter tenancy comparison.

## Data requirements and credentials

Raw datasets are not distributed through Git. Before running the pipeline, place the required October 2025–June 2026 Airbnb files (`listings_YYYY_MM.csv`) and the configured tenancy source file in `data/raw/`.

The pipeline downloads the configured July and August 2026 Airbnb summary listings when they are missing. The source URLs are recorded in `config/airbnb_sources.csv`, and pipeline settings are in `config/automation.R`.

If the pipeline needs to query uncached coordinates, a Koordinates API key may be required in your local `.Renviron` file. Restart R after configuring it. **Never commit `.Renviron`, API keys, or other credentials.**

## Repository structure

```text
christchurch_rentalmarket_analysis/
├── config/                         # Automation settings and source URL register
├── data/
│   ├── raw/                        # Local source datasets; not committed
│   └── processed/                  # Generated analytical datasets
├── Docs/ 
│   ├── deliverables/               # Detailed deliverable documentation
│   └── project/                  # Detailed project level documentation
├── output/                         # Figures, summaries, and run outputs
├── R/                              # R pipeline stages and reusable 
│   ├── helpers/               
│   └── test/  
├── renv/
├── tests/                 
├── run_pipeline.R                  # Deliverable 7 entry point
├── renv.lock                       # Recorded R package versions
├── .Rprofile                       # renv project activation
├── .gitignore
├── christchurch_rentalmarket_analysis.Rproj
└── README.md
```

Generated files and exact subdirectories depend on which stages have been run. Local raw data, credentials, and large generated datasets may be excluded from version control. The `renv/` infrastructure may also be present in the repository.

## Workflow and outputs

The project follows this general sequence:

**Source data → inspection and cleaning → transformation → geographic enrichment → integration → validation → analysis and visualisation.**

The Deliverable 7 controller runs the existing R stages in dependency order, refreshes the relevant integrated datasets and SQLite tables, regenerates plots, and writes validation/run-summary outputs. Results from that pipeline are isolated under:

- `data/processed/week11/2025-10_to_2026-08/`
- `output/week11/2025-10_to_2026-08/`

Review the generated `RUN_SUMMARY.md` and coverage table before presenting results. Results can change when the inputs or pipeline are updated.

### Latest documented pipeline run

The documented run processed 11 monthly snapshots from October 2025 through August 2026, comprising 35,796 listing-month observations and 4,264 distinct listings. It generated five updated plots and passed 60 validation checks. The median nightly prices reported for July and August 2026 were NZ$227 and NZ$224, respectively.

These figures describe that run and should be refreshed from the generated run summary after a subsequent run. The pipeline is run **on demand**; scheduled execution and GitHub Actions are not currently configured.

## Git and branch protection

The team uses Git and GitHub for version control. The repository has an **Active** ruleset named `Pushes to the main branch`, targeting `main`. As currently configured, it restricts updates and deletions for actors who are not on the bypass list. The displayed bypass list includes the Repository admin role and the `ChiduruppalaPooja` user.


## Deliverable documentation

Use the relevant document for implementation details rather than duplicating them in this README.

- [Week 9 Geographic Integration](Deliverables_Documentations/Week_9_Geographic_Integration.md) — geographic enrichment, schemas, joins, and validation.
- [Week 10 Design Principles](Deliverables_Documentations/Week_10_Design_Principles.md) — design principles, pipeline structure, and limitations.
- [Week 10 Change Log](Deliverables_Documentations/Week_10_Change_Log.md) — code changes, rationale, and before/after results.
- [Week 10 Run and Presentation Guide](Deliverables_Documentations/Week_10_Run_And_Present.md) — execution and presentation guidance.
- [Week 11 Automation Guide](Deliverables_Documentations/Week11_Automation_Guide.md) — pipeline execution, output locations, validation evidence, and troubleshooting.

## Reproducibility

- Keep raw source data unchanged.
- Implement cleaning and transformation in code rather than manually editing source files.
- Record package dependencies in `renv.lock`; use `renv::snapshot()` after intentional package changes.
- Validate generated outputs and review Git changes before committing.
- Keep credentials and local-only data out of version control.

## Current status

- **Deliverable 1:** R project and package environment established.
- **Deliverables 2–4:** Refer to their current implementation and documentation status; do not infer completion from this summary.
- **Deliverable 5:** SA2 2019 geographic integration and comparison tables implemented and validated locally.
- **Deliverable 6:** Coding-practice changes, design documentation, and 22 hand-checkable sanity tests implemented; team review/presentation was still pending in the last documented status.
- **Deliverable 7:** On-demand automated pipeline implemented and validated locally, with 60 passing validation checks in the documented run.
- **Deliverable 8:** Final project consolidation and submission.

## Contributors

Project contributors and responsibilities are maintained through the team's repository and deliverable records. Main contributors:
1. Pooja Chiduruppala - ChiduruppalaPooja
2. Sahil Mann - sahil-mann
3. Claudia Thompson - claudia-thompson-101

## References

- [Inside Airbnb](https://insideairbnb.com/)
- [Tenancy Services](https://www.tenancy.govt.nz/) / Ministry of Business, Innovation and Employment (MBIE)
- [Koordinates](https://koordinates.com/)
- Stats NZ — Statistical Area 2 2019 geographic definitions

The configured Airbnb source URLs are recorded in `config/airbnb_sources.csv`; consult the deliverable documentation for dataset-specific sources and processing decisions.
