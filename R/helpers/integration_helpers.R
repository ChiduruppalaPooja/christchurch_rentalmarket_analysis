# Pure transformations and assertions: no file writes or API calls.
assert_columns <- function(data, columns, label) {
  missing <- setdiff(columns, names(data))
  if (length(missing)) stop(label, " is missing: ", paste(missing, collapse = ", "))
  invisible(data)
}

assert_unique_keys <- function(data, keys, label, allow_missing = FALSE) {
  assert_columns(data, keys, label)
  key_data <- data[keys]
  if ((!allow_missing && anyNA(key_data)) || any(vapply(key_data, function(x) any(trimws(as.character(x)) == "", na.rm = TRUE), logical(1)))) {
    stop(label, " has missing or empty key values.")
  }
  if (anyDuplicated(key_data)) stop(label, " has duplicate keys: ", paste(keys, collapse = ", "))
  invisible(data)
}

assert_nonnegative <- function(values, label) {
  if (!is.numeric(values) || any(!is.na(values) & (!is.finite(values) | values < 0))) {
    stop(label, " must contain nonnegative finite numbers or NA.")
  }
  invisible(values)
}

median_or_na <- function(values) {
  observed <- values[!is.na(values)]
  if (!length(observed)) return(NA_real_)
  median(observed)
}

quarter_start <- function(dates) {
  if (!inherits(dates, "Date") || anyNA(dates)) stop("Quarter conversion requires nonmissing dates.")
  month <- as.integer(format(dates, "%m"))
  as.Date(sprintf("%s-%02d-01", format(dates, "%Y"), ((month - 1L) %/% 3L) * 3L + 1L))
}

build_listing_quarters <- function(monthly) {
  assert_columns(monthly, c("id", "snapshot_date", "comparison_quarter", "sa2_code", "sa2_name", "price"), "Airbnb monthly data")
  assert_unique_keys(monthly, c("id", "snapshot_date"), "Airbnb monthly data")
  assert_nonnegative(monthly$price, "Airbnb price")
  if (anyNA(monthly$comparison_quarter)) stop("Airbnb quarter must not be missing.")

  # Do not invent a location when coordinates cross SA2 boundaries.
  # Ambiguous listing-quarters stay in this table but are excluded from area summaries.
  monthly |>
    dplyr::group_by(id, comparison_quarter) |>
    dplyr::summarise(
      sa2_count = dplyr::n_distinct(sa2_code, na.rm = TRUE),
      sa2_code = if (sa2_count == 1L) dplyr::first(sa2_code[!is.na(sa2_code)]) else NA_character_,
      sa2_name = if (sa2_count == 1L) dplyr::first(sa2_name[!is.na(sa2_name)]) else NA_character_,
      monthly_snapshots = dplyr::n(),
      price_observations = sum(!is.na(price)),
      listing_median_nightly_price = median_or_na(price),
      .groups = "drop"
    ) |>
    dplyr::mutate(
      geography_status = dplyr::case_when(
        sa2_count == 1L ~ "single_sa2",
        sa2_count > 1L ~ "multiple_sa2",
        TRUE ~ "no_sa2"
      )
    ) |>
    dplyr::arrange(comparison_quarter, id)
}

summarise_listing_quarters <- function(listing_quarters) {
  assert_unique_keys(listing_quarters, c("id", "comparison_quarter"), "Listing-quarter table")
  listing_quarters |>
    dplyr::filter(geography_status == "single_sa2") |>
    dplyr::group_by(sa2_code, sa2_name, comparison_quarter) |>
    dplyr::summarise(
      airbnb_listing_snapshots = sum(monthly_snapshots),
      airbnb_unique_listings = dplyr::n(),
      airbnb_price_observations = sum(price_observations),
      airbnb_priced_listings = sum(!is.na(listing_median_nightly_price)),
      median_airbnb_nightly_price = median_or_na(listing_median_nightly_price),
      .groups = "drop"
    )
}

join_market_tables <- function(airbnb_quarters, tenancy_quarters) {
  keys <- c("sa2_code", "comparison_quarter")
  assert_unique_keys(airbnb_quarters, keys, "Airbnb area-quarter summary")
  assert_unique_keys(tenancy_quarters, keys, "Tenancy area-quarter summary")
  dplyr::inner_join(airbnb_quarters, tenancy_quarters, by = keys, relationship = "one-to-one") |>
    dplyr::mutate(
      equivalent_airbnb_weekly_price = median_airbnb_nightly_price * 7,
      equivalent_tenancy_nightly_price = median_weekly_rent / 7,
      nightly_price_gap = median_airbnb_nightly_price - equivalent_tenancy_nightly_price,
      weekly_price_gap = equivalent_airbnb_weekly_price - median_weekly_rent
    ) |>
    dplyr::arrange(comparison_quarter, sa2_code)
}
