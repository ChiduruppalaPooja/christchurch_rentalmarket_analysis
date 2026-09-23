# Small, hand-checkable fixtures. No source data, database or API is needed.
library(dplyr)
library(tibble)
source("R/helpers/integration_helpers.R")

run_integration_tests <- function() {
  results <- list()
  check <- function(condition, label) {
    if (!isTRUE(condition)) stop("FAILED: ", label)
    results[[length(results) + 1L]] <<- tibble(check = label, status = "PASS")
  }
  errors_with <- function(expression, pattern) {
    result <- tryCatch({ force(expression); "NO_ERROR" }, error = function(e) conditionMessage(e))
    grepl(pattern, result, fixed = TRUE)
  }
  toy <- tibble(
    id = c("A", "A", "A", "B"),
    snapshot_date = as.Date(c("2026-04-01", "2026-05-01", "2026-06-01", "2026-04-01")),
    comparison_quarter = as.Date("2026-04-01"),
    sa2_code = "326600", sa2_name = "Christchurch Central",
    price = c(100, 100, 100, 300)
  )
  quarters <- build_listing_quarters(toy)
  area <- summarise_listing_quarters(quarters)
  check(median(toy$price) == 100, "Hand example: old pooled median is 100")
  check(area$median_airbnb_nightly_price == 200, "Hand example: equal-listing median is 200")
  check(nrow(quarters) == 2L && area$airbnb_unique_listings == 2L, "One row and one count per listing-quarter")
  shorter <- toy[c(1, 4), ]
  check(summarise_listing_quarters(build_listing_quarters(shorter))$median_airbnb_nightly_price == 200,
        "Repeating the same monthly price does not overweight a listing")
  changed <- toy
  changed$price <- c(100, 150, 200, 300)
  check(summarise_listing_quarters(build_listing_quarters(changed))$median_airbnb_nightly_price == 225,
        "Changing monthly prices uses the within-listing median first")
  missing_price <- bind_rows(toy, mutate(toy[4, ], id = "C", price = NA_real_))
  missing_area <- summarise_listing_quarters(build_listing_quarters(missing_price))
  check(missing_area$airbnb_unique_listings == 3L && missing_area$airbnb_priced_listings == 2L &&
          missing_area$median_airbnb_nightly_price == 200, "Unpriced listing counts but does not become a zero price")
  check(is.na(summarise_listing_quarters(build_listing_quarters(mutate(toy, price = NA_real_)))$median_airbnb_nightly_price),
        "All-missing prices return NA")
  ambiguous <- toy
  ambiguous$sa2_code[2] <- "999999"
  ambiguous$sa2_name[2] <- "Different area"
  ambiguous_quarters <- build_listing_quarters(ambiguous)
  check(ambiguous_quarters$geography_status[ambiguous_quarters$id == "A"] == "multiple_sa2" &&
          is.na(ambiguous_quarters$sa2_code[ambiguous_quarters$id == "A"]), "Conflicting locations are flagged, not guessed")
  check(summarise_listing_quarters(ambiguous_quarters)$median_airbnb_nightly_price == 300,
        "Ambiguous listing-quarter is excluded from spatial comparison")
  unlocated <- mutate(toy, sa2_code = NA_character_, sa2_name = NA_character_)
  check(all(build_listing_quarters(unlocated)$geography_status == "no_sa2"), "Missing geography stays explicitly unlocated")
  check(errors_with(build_listing_quarters(bind_rows(toy, toy[1, ])), "duplicate keys"), "Duplicate listing-months stop the pipeline")
  check(errors_with(build_listing_quarters(mutate(toy, id = "")), "missing or empty"), "Empty identifiers are rejected")
  check(errors_with(build_listing_quarters(mutate(toy, price = -1)), "nonnegative"), "Negative prices are rejected")
  check(errors_with(build_listing_quarters(mutate(toy, price = Inf)), "finite"), "Infinite prices are rejected")
  check(errors_with(build_listing_quarters(select(toy, -price)), "missing: price"), "Missing required column gives a clear error")
  check(identical(quarter_start(as.Date(c("2025-12-31", "2026-01-01", "2026-06-30"))),
                  as.Date(c("2025-10-01", "2026-01-01", "2026-04-01"))), "Quarter conversion handles year and quarter boundaries")
  check(errors_with(quarter_start(as.Date(NA_character_)), "nonmissing"), "Missing dates are rejected")
  tenancy <- tibble(sa2_code = "326600", comparison_quarter = as.Date("2026-04-01"), median_weekly_rent = 700)
  joined <- join_market_tables(area, tenancy)
  check(joined$nightly_price_gap == 100 && joined$weekly_price_gap == 700, "Hand example: 200 minus 700/7 gives 100 per night")
  check(errors_with(join_market_tables(area, bind_rows(tenancy, tenancy)), "duplicate keys"), "Duplicate tenancy join keys are rejected")
  check(errors_with(join_market_tables(bind_rows(area, area), tenancy), "duplicate keys"), "Duplicate Airbnb join keys are rejected")
  check(nrow(join_market_tables(area, mutate(tenancy, sa2_code = "999999"))) == 0L, "Different areas never match")
  check(nrow(join_market_tables(area, mutate(tenancy, comparison_quarter = as.Date("2026-01-01")))) == 0L, "Different quarters never match")
  bind_rows(results)
}

test_results <- run_integration_tests()
print(test_results, n = Inf)
message(nrow(test_results), " fixture tests passed.")
