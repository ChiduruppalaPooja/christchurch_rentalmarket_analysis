# ============================================================
# Airbnb Data Preparation and Cleaning
# Snapshot: June 2026
# Location: Christchurch City
# ============================================================

library(tidyverse)

# ------------------------------------------------------------
# File paths
# ------------------------------------------------------------

input_file <- "data/raw/listings.csv"
output_file <- "data/processed/airbnb_christchurch_2026_06_clean.csv"

required_columns <- c(
  "id",
  "neighbourhood_group",
  "price",
  "minimum_nights",
  "last_review",
  "reviews_per_month",
  "license",
  "room_type",
  "neighbourhood",
  "latitude",
  "longitude"
)

missing_columns <- setdiff(required_columns, names(airbnb_raw))

if (length(missing_columns) > 0) {
  stop(
    "Required columns are missing: ",
    paste(missing_columns, collapse = ", ")
  )
}

# ------------------------------------------------------------
# 1. Load raw Airbnb data
# ------------------------------------------------------------

airbnb_raw <- read_csv(
  input_file,
  show_col_types = FALSE
)

# Basic information about the raw dataset
print(dim(airbnb_raw))
print(names(airbnb_raw))


# ------------------------------------------------------------
# 2. Filter to Christchurch City
# ------------------------------------------------------------

airbnb_chch <- airbnb_raw |>
  filter(
    neighbourhood_group == "Christchurch City"
  )

if (nrow(airbnb_chch) == 0) {
  stop("No Christchurch City listings were found.")
}

if (any(airbnb_chch$neighbourhood_group != "Christchurch City")) {
  stop("Filtering error: non-Christchurch records remain.")
}

# Confirm that only Christchurch City remains
print(table(airbnb_chch$neighbourhood_group))


# ------------------------------------------------------------
# 3. Add snapshot month and year
# ------------------------------------------------------------

# These identify the Airbnb data snapshot.
# They are NOT based on last_review.

airbnb_chch <- airbnb_chch |>
  mutate(
    snapshot_month = "June",
    snapshot_year = 2026
  )

if (
  any(airbnb_chch$snapshot_month != "June") ||
  any(airbnb_chch$snapshot_year != 2026)
) {
  stop("Snapshot metadata is incorrect for the June 2026 dataset.")
}

# ------------------------------------------------------------
# 4. Inspect missing values
# ------------------------------------------------------------

missing_values <- airbnb_chch |>
  summarise(
    across(
      everything(),
      ~ sum(is.na(.))
    )
  ) |>
  pivot_longer(
    cols = everything(),
    names_to = "column",
    values_to = "missing_count"
  )

print(
  missing_values |>
    filter(missing_count > 0),
  n = Inf
)

# ------------------------------------------------------------
# 5. Investigate missing review information
# ------------------------------------------------------------

# Check whether missing review information is associated
# with listings having no reviews.

missing_reviews <- airbnb_chch |>
  filter(
    is.na(last_review) |
      is.na(reviews_per_month)
  ) |>
  select(
    id,
    number_of_reviews,
    last_review,
    reviews_per_month
  )

print(missing_reviews, n = 40)

# Check the number of reviews for listings with missing
# last_review or reviews_per_month.

missing_reviews |>
  count(number_of_reviews) |>
  print(n = Inf)


review_missing_check <- missing_reviews |>
  summarise(
    listings_with_zero_reviews =
      sum(number_of_reviews == 0, na.rm = TRUE),
    listings_with_reviews =
      sum(number_of_reviews > 0, na.rm = TRUE)
  )

print(review_missing_check)

# ------------------------------------------------------------
# 6. Investigate missing price values
# ------------------------------------------------------------

# Inspect listings with missing prices.

missing_price_listings <- airbnb_chch |>
  filter(
    is.na(price)
  ) |>
  select(
    id,
    room_type,
    neighbourhood,
    minimum_nights,
    number_of_reviews,
    availability_365
  )

print(missing_price_listings, n = 30)


# Check for missing, zero, and negative prices.

price_quality <- airbnb_chch |>
  summarise(
    missing_price =
      sum(is.na(price)),
    
    zero_price =
      sum(price == 0, na.rm = TRUE),
    
    negative_price =
      sum(price < 0, na.rm = TRUE)
  )

print(price_quality)

if (price_quality$zero_price > 0 ||
    price_quality$negative_price > 0) {
  stop("Invalid price values detected: zero or negative prices.")
}


# Summary statistics for observed prices.

price_summary <- airbnb_chch |>
  summarise(
    min_price =
      min(price, na.rm = TRUE),
    
    mean_price =
      mean(price, na.rm = TRUE),
    
    median_price =
      median(price, na.rm = TRUE),
    
    max_price =
      max(price, na.rm = TRUE),
    
    sd_price =
      sd(price, na.rm = TRUE)
  )

print(price_summary)


# ------------------------------------------------------------
# 7. Investigate high price values
# ------------------------------------------------------------

# Inspect the highest observed prices rather than removing
# values solely because they are statistical outliers.

top_price_listings <- airbnb_chch |>
  select(
    id,
    name,
    room_type,
    neighbourhood,
    price,
    minimum_nights
  ) |>
  filter(
    !is.na(price)
  ) |>
  arrange(
    desc(price)
  ) |>
  slice_head(
    n = 20
  )

print(top_price_listings, n = 20)


# ------------------------------------------------------------
# 8. Investigate minimum nights
# ------------------------------------------------------------

# Inspect listings where minimum_nights is missing.

missing_minimum_nights <- airbnb_chch |>
  filter(
    is.na(minimum_nights)
  ) |>
  select(
    id,
    name,
    room_type,
    neighbourhood,
    price,
    number_of_reviews,
    availability_365
  )

print(missing_minimum_nights, n = Inf)


# Check for missing, zero, and negative minimum-night values.

minimum_nights_quality <- airbnb_chch |>
  summarise(
    missing_minimum_nights =
      sum(is.na(minimum_nights)),
    
    zero_minimum_nights =
      sum(minimum_nights == 0, na.rm = TRUE),
    
    negative_minimum_nights =
      sum(minimum_nights < 0, na.rm = TRUE)
  )

print(minimum_nights_quality)

if (minimum_nights_quality$zero_minimum_nights > 0 ||
    minimum_nights_quality$negative_minimum_nights > 0) {
  stop("Invalid minimum_nights values detected: zero or negative values.")
}

# Summary statistics for minimum nights.

minimum_nights_summary <- airbnb_chch |>
  summarise(
    min_minimum_nights =
      min(minimum_nights, na.rm = TRUE),
    
    median_minimum_nights =
      median(minimum_nights, na.rm = TRUE),
    
    mean_minimum_nights =
      mean(minimum_nights, na.rm = TRUE),
    
    max_minimum_nights =
      max(minimum_nights, na.rm = TRUE)
  )

print(minimum_nights_summary)


# ------------------------------------------------------------
# 9. Check for duplicate listing IDs
# ------------------------------------------------------------

duplicate_ids <- airbnb_chch |>
  count(id) |>
  filter(
    n > 1
  )

print(duplicate_ids)

# Overall duplicate check

duplicate_summary <- airbnb_chch |>
  summarise(
    total_rows = n(),
    unique_ids = n_distinct(id),
    duplicate_rows = n() - n_distinct(id)
  )

print(duplicate_summary)
if (duplicate_summary$duplicate_rows > 0) {
  stop("Duplicate listing IDs detected in the June 2026 snapshot.")
}

# ------------------------------------------------------------
# 10. Inspect categorical variables
# ------------------------------------------------------------

# Room type categories

room_type_summary <- airbnb_chch |>
  count(
    room_type,
    sort = TRUE
  )

print(room_type_summary, n = Inf)


# Neighbourhood categories

neighbourhood_summary <- airbnb_chch |>
  count(
    neighbourhood,
    sort = TRUE
  )

print(neighbourhood_summary, n = Inf)


# Check missing and unique categorical values.

categorical_quality <- airbnb_chch |>
  summarise(
    room_type_missing =
      sum(is.na(room_type)),
    
    neighbourhood_missing =
      sum(is.na(neighbourhood)),
    
    room_type_unique =
      n_distinct(room_type),
    
    neighbourhood_unique =
      n_distinct(neighbourhood)
  )

print(categorical_quality)

if (categorical_quality$room_type_missing > 0) {
  stop("Missing room_type values detected.")
}

if (categorical_quality$neighbourhood_missing > 0) {
  stop("Missing neighbourhood values detected.")
}

# ------------------------------------------------------------
# 11. Check geographic coordinates
# ------------------------------------------------------------

coordinate_summary <- airbnb_chch |>
  summarise(
    missing_latitude =
      sum(is.na(latitude)),
    
    missing_longitude =
      sum(is.na(longitude)),
    
    min_latitude =
      min(latitude, na.rm = TRUE),
    
    max_latitude =
      max(latitude, na.rm = TRUE),
    
    min_longitude =
      min(longitude, na.rm = TRUE),
    
    max_longitude =
      max(longitude, na.rm = TRUE)
  )

print(coordinate_summary)


# Broad coordinate screening.
# These thresholds are used only to identify values that
# deserve investigation; they are NOT used to automatically
# remove listings.

potential_coordinate_issues <- airbnb_chch |>
  filter(
    latitude < -44 |
      latitude > -43 |
      longitude < 171 |
      longitude > 173
  ) |>
  select(
    id,
    neighbourhood,
    latitude,
    longitude
  )

cat(
  "Potential coordinate issues:",
  nrow(potential_coordinate_issues),
  "\n"
)

print(potential_coordinate_issues, n = 20)

# ------------------------------------------------------------
# 12. Check numerical variables for invalid values
# ------------------------------------------------------------

numerical_quality <- airbnb_chch |>
  summarise(
    negative_number_of_reviews =
      sum(number_of_reviews < 0, na.rm = TRUE),
    
    negative_reviews_per_month =
      sum(reviews_per_month < 0, na.rm = TRUE),
    
    negative_calculated_host_listings =
      sum(
        calculated_host_listings_count < 0,
        na.rm = TRUE
      ),
    
    negative_availability =
      sum(availability_365 < 0, na.rm = TRUE),
    
    availability_over_365 =
      sum(availability_365 > 365, na.rm = TRUE),
    
    negative_reviews_ltm =
      sum(number_of_reviews_ltm < 0, na.rm = TRUE)
  )

print(numerical_quality, width = Inf)

if (any(numerical_quality < 0)) {
  stop("Invalid negative numerical values detected.")
}

if (numerical_quality$availability_over_365 > 0) {
  stop("Invalid availability_365 values above 365 detected.")
}

# ------------------------------------------------------------
# 13. Apply cleaning decisions
# ------------------------------------------------------------

# Cleaning decision:
# The license column contains no observed values in the
# Christchurch-filtered dataset (100% missing), so it is removed.
#
# Other missing values are retained:
# - Missing price values are preserved as NA.
# - Missing minimum_nights values are preserved as NA.
# - Missing last_review and reviews_per_month values correspond
#   to listings with zero reviews and are preserved as NA.
#
# No duplicate listing IDs were identified within this
# monthly snapshot.
#
# No invalid negative numerical values were identified.
#
# High price values were inspected and were not removed because
# they appear plausible and there was no evidence that they
# represent erroneous observations.

airbnb_chch_clean <- airbnb_chch |>
  select(
    -license
  )
if ("license" %in% names(airbnb_chch_clean)) {
  stop("Cleaning error: license column was not removed.")
}

# ------------------------------------------------------------
# 14. Final QA and cleaning consequences
# ------------------------------------------------------------

final_qa <- airbnb_chch_clean |>
  summarise(
    rows_after_cleaning = n(),
    columns_after_cleaning = ncol(airbnb_chch_clean),
    unique_ids = n_distinct(id),
    duplicate_rows = n() - n_distinct(id),
    christchurch_listings =
      sum(neighbourhood_group == "Christchurch City"),
    missing_price = sum(is.na(price)),
    missing_minimum_nights = sum(is.na(minimum_nights)),
    missing_last_review = sum(is.na(last_review)),
    missing_reviews_per_month = sum(is.na(reviews_per_month)),
    snapshot_months = n_distinct(snapshot_month),
    snapshot_years = n_distinct(snapshot_year)
  )

print(final_qa)

if (final_qa$duplicate_rows > 0) {
  stop("Final QA failed: duplicate listing IDs remain.")
}

if (final_qa$christchurch_listings != final_qa$rows_after_cleaning) {
  stop("Final QA failed: non-Christchurch records remain.")
}

if (final_qa$snapshot_months != 1 ||
    final_qa$snapshot_years != 1) {
  stop("Final QA failed: multiple snapshot periods remain.")
}
# ------------------------------------------------------------
# 16. Cleaning consequences
# ------------------------------------------------------------

rows_before <- nrow(airbnb_chch)
rows_after <- nrow(airbnb_chch_clean)

columns_before <- ncol(airbnb_chch)
columns_after <- ncol(airbnb_chch_clean)

cat(
  "Rows before cleaning:", rows_before, "\n",
  "Rows after cleaning:", rows_after, "\n",
  "Rows removed:", rows_before - rows_after, "\n",
  "Columns before cleaning:", columns_before, "\n",
  "Columns after cleaning:", columns_after, "\n",
  "Columns removed:", columns_before - columns_after, "\n"
)

# ------------------------------------------------------------
# 17. Save cleaned dataset
# ------------------------------------------------------------

if (!dir.exists(dirname(output_file))) {
  dir.create(
    dirname(output_file),
    recursive = TRUE
  )
}

write_csv(
  airbnb_chch_clean,
  output_file
)


# ------------------------------------------------------------
# 18. Confirm processed file was created
# ------------------------------------------------------------

if (!file.exists(output_file)) {
  stop("Output file was not created: ", output_file)
}

message("Cleaned dataset saved successfully: ", output_file)
