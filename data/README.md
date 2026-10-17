# Local data inputs and generated datasets

The R pipeline's CSV datasets and SQLite database stay on each team member's computer. Git tracks this guide, the source code and selected aggregate outputs. The `.gitignore` rules cover `data/raw/` and `data/processed/`.

Create `data/raw/` locally and place the original monthly Inside Airbnb New Zealand **summary** CSVs there, named `listings_YYYY_MM.csv`. The existing October 2025 through June 2026 files and the team's raw tenancy file are required before starting the automated pipeline.

The configured tenancy filename is `Detailed-Quarterly-Tenancy-Q1-2020-Q3-2026.csv`. Its actual coverage is checked from the records; the filename alone does not establish Q3 coverage.

The pipeline downloads the July and August 2026 Airbnb summary files when absent. Exact source URLs are recorded in [the source register](../config/airbnb_sources.csv), and dates and paths are selected in [the automation configuration](../config/automation.R).

The optional June-only exploratory script `R/01_airbnb_prepare.R` reads `data/raw/listings.csv`. To use the existing June input for that script, run from the project root:

```r
file.copy("data/raw/listings_2026_06.csv", "data/raw/listings.csv")
```

This keeps the monthly input and does not overwrite an existing `listings.csv`. The June-only script is not a prerequisite for the automated pipeline.

The pipeline creates cleaned datasets, geographic lookup data and SQLite under `data/processed/`. A local Koordinates key is needed only for geographic coordinates not already covered by the lookup cache. Keep credentials in the ignored `.Renviron` file.

Follow [the automation guide](../Docs/project/automation_guide.md) for package setup, execution and output interpretation. Keep source files unchanged; regenerate processed files through the R scripts.

## Historical KNIME workflow

The KNIME archive under `Docs/project/` is a separate historical deliverable and contains saved node tables. It is not an R pipeline input. The team should review whether it needs a data-free re-export under the course's data-publication rules.
