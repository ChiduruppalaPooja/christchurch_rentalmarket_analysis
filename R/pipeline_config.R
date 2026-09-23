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
  database_file = "data/processed/christchurch_rental_market.sqlite",
  database_tables = c(
    "dim_geography", "fact_airbnb_listing_month", "fact_airbnb_listing_quarter",
    "fact_airbnb_sa2_quarter", "fact_tenancy_detail", "fact_tenancy_sa2_quarter",
    "market_sa2_quarter"
  )
)
