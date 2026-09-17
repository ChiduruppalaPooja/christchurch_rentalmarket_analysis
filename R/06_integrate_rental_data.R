# ============================================================
# DATA422 - Deliverable 5
# Build database-ready Airbnb and tenancy tables and join them
# ============================================================

library(tidyverse)

airbnb_file <- "data/processed/airbnb_christchurch_with_sa2.csv"

tenancy_file <-
  "data/processed/tenancy_christchurch_oct2025_jun2026_clean.csv"

database_ready_dir <- "data/processed/database_ready"
summary_dir <- "output/tables"

required_files <- c(airbnb_file, tenancy_file)
missing_files <- required_files[!file.exists(required_files)]

if (length(missing_files) > 0) {
  stop(
    paste0(
      "Required processed file(s) not found:\n- ",
      paste(missing_files, collapse = "\n- "),
      "\nRun R/03_tenancy_inspect.R and R/05_query_geography.R first."
    )
  )
}

dir.create(database_ready_dir, recursive = TRUE, showWarnings = FALSE)
dir.create(summary_dir, recursive = TRUE, showWarnings = FALSE)

airbnb <- read_csv(
  airbnb_file,
  col_types = cols(
    id = col_character(),
    host_id = col_character(),
    sa2_code = col_character()
  ),
  show_col_types = FALSE
)

tenancy <- read_csv(
  tenancy_file,
  col_types = cols(
    `Location Id` = col_character()
  ),
  show_col_types = FALSE
)

required_airbnb_columns <- c(
  "id", "latitude", "longitude", "price", "sa2_code", "sa2_name"
)

required_tenancy_columns <- c(
  "TimeFrame", "Location Id", "Dwelling Type", "Number Of Beds",
  "Total Bonds", "Active Bonds", "Closed Bonds", "Median Rent",
  "Geometric Mean Rent", "Upper Quartile Rent", "Lower Quartile Rent",
  "Log Std Dev Weekly Rent"
)

missing_airbnb_columns <- setdiff(required_airbnb_columns, names(airbnb))
missing_tenancy_columns <- setdiff(required_tenancy_columns, names(tenancy))

if (length(missing_airbnb_columns) > 0) {
  stop(
    "Airbnb input is missing: ",
    paste(missing_airbnb_columns, collapse = ", ")
  )
}

if (length(missing_tenancy_columns) > 0) {
  stop(
    "Tenancy input is missing: ",
    paste(missing_tenancy_columns, collapse = ", ")
  )
}

month_lookup <- tibble(
  snapshot_month = month.name,
  snapshot_month_number = seq_along(month.name)
)

if ("month_year" %in% names(airbnb)) {
  airbnb <- airbnb |>
    mutate(
      snapshot_year = as.integer(stringr::str_sub(month_year, 1, 4)),
      snapshot_month_number =
        as.integer(stringr::str_sub(month_year, 6, 7)),
      snapshot_month = month.name[snapshot_month_number]
    )
} else if (all(c("data_month", "data_year") %in% names(airbnb))) {
  airbnb <- airbnb |>
    mutate(
      snapshot_month = stringr::str_to_title(data_month),
      snapshot_year = as.integer(data_year)
    ) |>
    left_join(month_lookup, by = "snapshot_month")
} else if (all(c("snapshot_month", "snapshot_year") %in% names(airbnb))) {
  airbnb <- airbnb |>
    mutate(
      snapshot_month = stringr::str_to_title(snapshot_month)
    ) |>
    left_join(month_lookup, by = "snapshot_month")
} else {
  stop(
    paste(
      "Airbnb input requires either month_year or both",
      "snapshot_month and snapshot_year (data_month/data_year are also supported)."
    )
  )
}

if (any(is.na(airbnb$snapshot_month_number))) {
  stop("Some Airbnb month values could not be converted to month numbers.")
}

fact_airbnb_listing_month <- airbnb |>
  mutate(
    snapshot_date = as.Date(
      sprintf(
        "%04d-%02d-01",
        as.integer(snapshot_year),
        snapshot_month_number
      )
    ),
    quarter_start_month =
      ((snapshot_month_number - 1L) %/% 3L) * 3L + 1L,
    comparison_quarter = as.Date(
      sprintf(
        "%04d-%02d-01",
        as.integer(snapshot_year),
        quarter_start_month
      )
    ),
    price = as.numeric(price),
    sa2_code = as.character(sa2_code)
  ) |>
  select(-snapshot_month_number, -quarter_start_month)

airbnb_price_coverage_by_month <- fact_airbnb_listing_month |>
  group_by(snapshot_date, snapshot_year, snapshot_month) |>
  summarise(
    total_rows = n(),
    observed_prices = sum(!is.na(price)),
    missing_prices = sum(is.na(price)),
    observed_price_percent = round(mean(!is.na(price)) * 100, 2),
    .groups = "drop"
  ) |>
  arrange(snapshot_date)

airbnb_price_coverage_by_quarter <- fact_airbnb_listing_month |>
  group_by(comparison_quarter) |>
  summarise(
    total_rows = n(),
    observed_prices = sum(!is.na(price)),
    missing_prices = sum(is.na(price)),
    observed_price_percent = round(mean(!is.na(price)) * 100, 2),
    months_with_any_observed_price = n_distinct(
      snapshot_date[!is.na(price)]
    ),
    .groups = "drop"
  ) |>
  arrange(comparison_quarter)

if (any(is.na(fact_airbnb_listing_month$snapshot_date))) {
  stop("Some Airbnb snapshot months could not be converted to dates.")
}

if (any(is.na(fact_airbnb_listing_month$sa2_code))) {
  warning(
    "Some Airbnb rows have no SA2 match. See ",
    "output/tables/week9_unmatched_coordinates.csv."
  )
}

dim_geography <- fact_airbnb_listing_month |>
  filter(!is.na(sa2_code)) |>
  distinct(sa2_code, sa2_name) |>
  arrange(sa2_code)

fact_airbnb_sa2_quarter <- fact_airbnb_listing_month |>
  filter(!is.na(sa2_code)) |>
  group_by(sa2_code, sa2_name, comparison_quarter) |>
  summarise(
    airbnb_listing_snapshots = n(),
    airbnb_unique_listings = n_distinct(id),
    airbnb_price_observations = sum(!is.na(price)),
    median_airbnb_nightly_price = if_else(
      airbnb_price_observations > 0,
      median(price, na.rm = TRUE),
      NA_real_
    ),
    .groups = "drop"
  )

fact_tenancy_detail <- tenancy |>
  transmute(
    comparison_quarter = as.Date(TimeFrame),
    sa2_code = as.character(`Location Id`),
    dwelling_type = as.character(`Dwelling Type`),
    number_of_beds = as.character(`Number Of Beds`),
    total_bonds = as.numeric(`Total Bonds`),
    active_bonds = as.numeric(`Active Bonds`),
    closed_bonds = as.numeric(`Closed Bonds`),
    median_weekly_rent = as.numeric(`Median Rent`),
    geometric_mean_weekly_rent = as.numeric(`Geometric Mean Rent`),
    upper_quartile_weekly_rent = as.numeric(`Upper Quartile Rent`),
    lower_quartile_weekly_rent = as.numeric(`Lower Quartile Rent`),
    log_sd_weekly_rent = as.numeric(`Log Std Dev Weekly Rent`)
  )

# Use the source's ALL/ALL category for one tenancy row per SA2 and quarter.
# Joining every dwelling/bed category to every Airbnb would duplicate data.
fact_tenancy_sa2_quarter <- fact_tenancy_detail |>
  filter(
    stringr::str_to_upper(stringr::str_trim(dwelling_type)) == "ALL",
    stringr::str_to_upper(stringr::str_trim(number_of_beds)) == "ALL"
  ) |>
  select(
    sa2_code,
    comparison_quarter,
    total_bonds,
    active_bonds,
    closed_bonds,
    median_weekly_rent,
    geometric_mean_weekly_rent,
    upper_quartile_weekly_rent,
    lower_quartile_weekly_rent,
    log_sd_weekly_rent
  )

if (nrow(fact_tenancy_sa2_quarter) == 0) {
  stop("No ALL/ALL aggregate tenancy records were found.")
}

duplicate_tenancy_keys <- fact_tenancy_sa2_quarter |>
  count(sa2_code, comparison_quarter) |>
  filter(n > 1)

if (nrow(duplicate_tenancy_keys) > 0) {
  stop(
    "Tenancy ALL/ALL data are not unique by SA2 and quarter. ",
    "Inspect the source before joining."
  )
}

join_keys <- c("sa2_code", "comparison_quarter")

market_sa2_quarter <- fact_airbnb_sa2_quarter |>
  inner_join(fact_tenancy_sa2_quarter, by = join_keys) |>
  mutate(
    equivalent_airbnb_weekly_price = median_airbnb_nightly_price * 7,
    equivalent_tenancy_nightly_price = median_weekly_rent / 7,
    nightly_price_gap =
      median_airbnb_nightly_price - equivalent_tenancy_nightly_price,
    weekly_price_gap =
      equivalent_airbnb_weekly_price - median_weekly_rent
  ) |>
  arrange(comparison_quarter, sa2_code)

unmatched_airbnb_keys <- fact_airbnb_sa2_quarter |>
  anti_join(fact_tenancy_sa2_quarter, by = join_keys) |>
  arrange(comparison_quarter, sa2_code)

unmatched_tenancy_keys <- fact_tenancy_sa2_quarter |>
  anti_join(fact_airbnb_sa2_quarter, by = join_keys) |>
  arrange(comparison_quarter, sa2_code)

join_quality <- tibble(
  measure = c(
    "airbnb_sa2_quarter_keys",
    "tenancy_sa2_quarter_keys",
    "matched_sa2_quarter_keys",
    "unmatched_airbnb_keys",
    "unmatched_tenancy_keys"
  ),
  value = c(
    nrow(fact_airbnb_sa2_quarter),
    nrow(fact_tenancy_sa2_quarter),
    nrow(market_sa2_quarter),
    nrow(unmatched_airbnb_keys),
    nrow(unmatched_tenancy_keys)
  )
)

christchurch_central <- fact_airbnb_listing_month |>
  filter(sa2_code == "326600") |>
  summarise(
    sa2_code = "326600",
    sa2_name = dplyr::first(
      sa2_name[!is.na(sa2_name)],
      default = NA_character_
    ),
    price_observations = sum(!is.na(price)),
    unique_listings = n_distinct(id),
    median_airbnb_nightly_price = median(price, na.rm = TRUE)
  )

largest_price_gaps <- market_sa2_quarter |>
  group_by(sa2_code, sa2_name) |>
  summarise(
    quarters_compared = n(),
    median_airbnb_nightly_price =
      median(median_airbnb_nightly_price, na.rm = TRUE),
    median_tenancy_nightly_price =
      median(equivalent_tenancy_nightly_price, na.rm = TRUE),
    median_nightly_price_gap = median(nightly_price_gap, na.rm = TRUE),
    .groups = "drop"
  ) |>
  arrange(desc(median_nightly_price_gap))

property_count_comparison <- market_sa2_quarter |>
  select(
    sa2_code,
    sa2_name,
    comparison_quarter,
    airbnb_unique_listings,
    total_bonds,
    active_bonds
  ) |>
  arrange(comparison_quarter, sa2_code)

database_tables <- list(
  dim_geography = dim_geography,
  fact_airbnb_listing_month = fact_airbnb_listing_month,
  fact_airbnb_sa2_quarter = fact_airbnb_sa2_quarter,
  fact_tenancy_detail = fact_tenancy_detail,
  fact_tenancy_sa2_quarter = fact_tenancy_sa2_quarter,
  market_sa2_quarter = market_sa2_quarter
)

purrr::iwalk(
  database_tables,
  ~ write_csv(
    .x,
    file.path(database_ready_dir, paste0(.y, ".csv"))
  )
)

write_csv(join_quality, file.path(summary_dir, "week9_join_quality.csv"))
write_csv(
  airbnb_price_coverage_by_month,
  file.path(summary_dir, "week9_airbnb_price_coverage_by_month.csv")
)
write_csv(
  airbnb_price_coverage_by_quarter,
  file.path(summary_dir, "week9_airbnb_price_coverage_by_quarter.csv")
)
write_csv(
  unmatched_airbnb_keys,
  file.path(summary_dir, "week9_unmatched_airbnb_keys.csv")
)
write_csv(
  unmatched_tenancy_keys,
  file.path(summary_dir, "week9_unmatched_tenancy_keys.csv")
)
write_csv(
  christchurch_central,
  file.path(summary_dir, "week9_christchurch_central_median.csv")
)
write_csv(
  largest_price_gaps,
  file.path(summary_dir, "week9_largest_price_gaps.csv")
)
write_csv(
  property_count_comparison,
  file.path(summary_dir, "week9_property_count_comparison.csv")
)

print(join_quality)
print(airbnb_price_coverage_by_month)
print(christchurch_central)
print(slice_head(largest_price_gaps, n = 10))
message("Saved database-ready tables to: ", database_ready_dir)
