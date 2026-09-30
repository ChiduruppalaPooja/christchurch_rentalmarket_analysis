# Shared parameters. Open the .Rproj file; all paths are relative to its root.
pipeline_config <- list(
  study_start = as.Date("2025-10-01"),
  study_end = as.Date("2026-06-01"),
  central_sa2 = "326600",
  sa2_layer = "98970",
  chart_quarter = as.Date("2026-04-01"),
  chart_top_n = 10L,
  airbnb_input = "data/processed/airbnb_christchurch_with_sa2.csv",
  tenancy_input = "data/processed/tenancy_christchurch_oct2025_jun2026_clean.csv",
  table_dir = "data/processed/database_ready",
  quality_dir = "data/processed/quality",
  summary_dir = "output/tables",
  figure_dir = "output/figures",
  raw_dir = "data/raw",
  cleaned_airbnb = "data/processed/airbnb_christchurch_oct2025_jun2026_clean.csv",
  tenancy_raw = "data/raw/Detailed-Quarterly-Tenancy-Q1-2020-Q3-2026.csv",
  tenancy_full = "data/processed/tenancy_clean.csv",
  geography_cache = "data/processed/airbnb_sa2_2019_lookup_cache.csv",
  database_file = "data/processed/christchurch_rental_market.sqlite",
  database_tables = c(
    "dim_geography", "fact_airbnb_listing_month", "fact_airbnb_listing_quarter",
    "fact_airbnb_sa2_quarter", "fact_tenancy_detail", "fact_tenancy_sa2_quarter",
    "market_sa2_quarter"
  )
)

# The root orchestrator supplies a run-specific configuration without rewriting
# the older scripts' defaults or overwriting earlier deliverable outputs.
overrides <- getOption("rental.pipeline.overrides", list())
if (length(setdiff(names(overrides), names(pipeline_config)))) {
  stop("Unknown pipeline configuration setting.")
}
pipeline_config <- utils::modifyList(pipeline_config, overrides)
if (anyNA(c(pipeline_config$study_start, pipeline_config$study_end)) ||
    pipeline_config$study_end < pipeline_config$study_start) {
  stop("Invalid configured study dates.")
}
