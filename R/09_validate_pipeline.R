# Inputs: saved source and result CSVs. Output: a tutor-readable sanity-check table.
# Recompute listing and area medians with base R, independently of the pipeline helpers.
library(tidyverse)
source("R/pipeline_config.R", local = TRUE)

validate_saved_pipeline <- function(config) {
  pipeline_config <- config
  read_saved <- function(name) {
    read.csv(file.path(pipeline_config$table_dir, paste0(name, ".csv")),
             colClasses = "character", check.names = FALSE)
  }
  monthly_check <- read_saved("fact_airbnb_listing_month")
  monthly_check$price <- as.numeric(monthly_check$price)
  quarter_check <- read_saved("fact_airbnb_listing_quarter")
  area_check <- read_saved("fact_airbnb_sa2_quarter")
  market_check <- read_saved("market_sa2_quarter")
  tenancy_check <- read_saved("fact_tenancy_sa2_quarter")
  metadata_check <- read.csv(file.path(pipeline_config$summary_dir, "week10_method_metadata.csv"))

  listing_groups <- split(monthly_check, paste(monthly_check$id, monthly_check$comparison_quarter, sep = "|"))
  independent_quarters <- do.call(rbind, lapply(listing_groups, function(rows) {
    codes <- unique(rows$sa2_code[!is.na(rows$sa2_code)])
    values <- rows$price[!is.na(rows$price)]
    data.frame(id = rows$id[1], comparison_quarter = rows$comparison_quarter[1],
               sa2_code = if (length(codes) == 1L) codes[1] else NA_character_,
               monthly_snapshots = nrow(rows), price_observations = length(values),
               listing_median_nightly_price = if (length(values)) median(values) else NA_real_)
  }))
  independent_quarters <- independent_quarters[order(independent_quarters$id, independent_quarters$comparison_quarter), ]
  quarter_check <- quarter_check[order(quarter_check$id, quarter_check$comparison_quarter), ]
  numbers_equal <- function(a, b) isTRUE(all.equal(as.numeric(a), as.numeric(b), check.attributes = FALSE, tolerance = 1e-8))
  eligible_check <- independent_quarters[!is.na(independent_quarters$sa2_code), ]
  area_groups <- split(eligible_check, paste(eligible_check$sa2_code, eligible_check$comparison_quarter, sep = "|"))
  independent_areas <- do.call(rbind, lapply(area_groups, function(rows) {
    values <- rows$listing_median_nightly_price[!is.na(rows$listing_median_nightly_price)]
    data.frame(sa2_code = rows$sa2_code[1], comparison_quarter = rows$comparison_quarter[1],
               listing_count = nrow(rows), priced_listings = length(values),
               median_price = if (length(values)) median(values) else NA_real_)
  }))
  independent_areas <- independent_areas[order(independent_areas$sa2_code, independent_areas$comparison_quarter), ]
  area_check <- area_check[order(area_check$sa2_code, area_check$comparison_quarter), ]

  checks <- list()
  record_check <- function(label, condition, detail) {
    tibble(check = label, status = if (isTRUE(condition)) "PASS" else "FAIL", detail = detail)
  }
  checks[[1]] <- record_check("Unique listing-month keys", !anyDuplicated(monthly_check[c("id", "snapshot_date")]), "Each listing appears at most once in each monthly snapshot.")
  checks[[2]] <- record_check("Unique listing-quarter keys", !anyDuplicated(quarter_check[c("id", "comparison_quarter")]), "One row per listing and quarter, including flagged records.")
  checks[[3]] <- record_check("All monthly rows accounted for", sum(as.numeric(quarter_check$monthly_snapshots)) == nrow(monthly_check), "Quarterly snapshot counts sum to the preserved monthly row count.")
  checks[[4]] <- record_check("Independent listing medians", nrow(quarter_check) == nrow(independent_quarters) &&
                               identical(quarter_check$id, independent_quarters$id) &&
                               identical(quarter_check$comparison_quarter, independent_quarters$comparison_quarter) &&
                               numbers_equal(quarter_check$listing_median_nightly_price, independent_quarters$listing_median_nightly_price),
                             "Base R recomputation agrees for every listing-quarter.")
  checks[[5]] <- record_check("Ambiguous geography not assigned", identical(quarter_check$sa2_code, independent_quarters$sa2_code), "Only listing-quarters with exactly one observed area receive an area code.")
  checks[[6]] <- record_check("Independent area medians and counts", nrow(area_check) == nrow(independent_areas) &&
                               identical(area_check$sa2_code, independent_areas$sa2_code) &&
                               identical(area_check$comparison_quarter, independent_areas$comparison_quarter) &&
                               numbers_equal(area_check$median_airbnb_nightly_price, independent_areas$median_price) &&
                               numbers_equal(area_check$airbnb_unique_listings, independent_areas$listing_count) &&
                               numbers_equal(area_check$airbnb_priced_listings, independent_areas$priced_listings),
                             "One listing-level median per area-quarter agrees with an independent base R calculation.")
  expected_keys <- merge(area_check[c("sa2_code", "comparison_quarter")], tenancy_check[c("sa2_code", "comparison_quarter")])
  actual_keys <- market_check[c("sa2_code", "comparison_quarter")]
  sort_keys <- function(x) x[order(x$sa2_code, x$comparison_quarter), ]
  checks[[7]] <- record_check("Join keys exactly match intersection", isTRUE(all.equal(sort_keys(actual_keys), sort_keys(expected_keys), check.attributes = FALSE)) && !anyDuplicated(actual_keys), "No many-to-many expansion or missing matched key.")
  checks[[8]] <- record_check("Nightly price-gap arithmetic", numbers_equal(market_check$nightly_price_gap,
      as.numeric(market_check$median_airbnb_nightly_price) - as.numeric(market_check$median_weekly_rent) / 7), "Airbnb nightly median minus tenancy weekly median divided by seven.")
  checks[[9]] <- record_check("Input fingerprints unchanged", identical(as.character(metadata_check$airbnb_md5), unname(tools::md5sum(pipeline_config$airbnb_input))) &&
                               identical(as.character(metadata_check$tenancy_md5), unname(tools::md5sum(pipeline_config$tenancy_input))), "Saved results refer to the current prepared source files.")

  # A concrete real-data row for the tutor to recalculate with a calculator.
  sanity_example <- as_tibble(market_check) |>
    filter(sa2_code == pipeline_config$central_sa2,
           comparison_quarter == as.character(pipeline_config$chart_quarter)) |>
    transmute(sa2_code, comparison_quarter,
              airbnb_nightly = as.numeric(median_airbnb_nightly_price),
              tenancy_weekly = as.numeric(median_weekly_rent),
              tenancy_nightly = tenancy_weekly / 7,
              expected_gap = airbnb_nightly - tenancy_nightly,
              saved_gap = as.numeric(nightly_price_gap))
  checks[[10]] <- record_check("Central hand-check row available", nrow(sanity_example) == 1L &&
                                is.finite(sanity_example$expected_gap) && numbers_equal(sanity_example$expected_gap, sanity_example$saved_gap), "One real row can be demonstrated separately from the automated full-table check.")
  central_keys <- eligible_check[eligible_check$sa2_code == pipeline_config$central_sa2, c("id", "comparison_quarter")]
  central_months <- merge(monthly_check, central_keys, by = c("id", "comparison_quarter"))
  central_groups <- split(central_months$price, central_months$id)
  central_medians <- vapply(central_groups, function(x) {
    observed <- x[!is.na(x)]
    if (length(observed)) median(observed) else NA_real_
  }, numeric(1))
  central_saved <- read.csv(file.path(pipeline_config$summary_dir, "week9_christchurch_central_median.csv"))
  checks[[11]] <- record_check("Independent Central period median", nrow(central_saved) == 1L &&
                                numbers_equal(central_saved$median_airbnb_nightly_price, median(central_medians, na.rm = TRUE)) &&
                                central_saved$unique_listings == length(central_groups) &&
                                central_saved$priced_listings == sum(!is.na(central_medians)) &&
                                central_saved$price_observations == sum(!is.na(central_months$price)),
                              "Whole-period Central result uses one median per eligible listing, not a median of quarterly medians.")
  sanity_checks <- bind_rows(checks)
  write_csv(sanity_checks, file.path(pipeline_config$summary_dir, "week10_sanity_checks.csv"))
  write_csv(sanity_example, file.path(pipeline_config$summary_dir, "week10_sanity_example.csv"))
  print(sanity_checks, n = Inf)
  print(sanity_example)
  if (any(sanity_checks$status == "FAIL")) stop("A saved-output sanity check failed. Review week10_sanity_checks.csv.")
  message("All ", nrow(sanity_checks), " saved-output sanity checks passed.")
  list(checks = sanity_checks, example = sanity_example)
}

validation_result <- validate_saved_pipeline(pipeline_config)
sanity_checks <- validation_result$checks
sanity_example <- validation_result$example
