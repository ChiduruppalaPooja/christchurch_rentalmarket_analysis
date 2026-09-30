# Deliverable 7 settings. Change the end month here, not in each R script.
automation_settings <- list(
  start_month = "2025-10",
  end_month = "2026-08",
  sources_file = "config/airbnb_sources.csv",
  raw_dir = "data/raw",
  tenancy_raw = "data/raw/Detailed-Quarterly-Tenancy-Q1-2020-Q3-2026.csv",
  processed_dir = "data/processed/week11",
  output_dir = "output/week11",
  geography_cache = "data/processed/airbnb_sa2_2019_lookup_cache.csv"
)
