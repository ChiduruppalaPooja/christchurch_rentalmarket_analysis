# ============================================================
# Airbnb Data Preparation and Cleaning
# Snapshot: June 2026
# Location: Christchurch City
# ============================================================

library(tidyverse)


# ------------------------------------------------------------
# 1. Load raw Airbnb data
# ------------------------------------------------------------

airbnb_raw <- read_csv(
  "data/raw/listings.csv",
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

# Check filtered dataset
print(dim(airbnb_chch))

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

# Check snapshot information
print(unique(airbnb_chch$snapshot_month))
print(unique(airbnb_chch$snapshot_year))

# Check dimensions after adding the two columns
print(dim(airbnb_chch))


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

print(missing_values, n = Inf)


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

high_price_listings <- airbnb_chch |>
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

print(high_price_listings, n = 20)


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

print(potential_coordinate_issues, n = Inf)


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

# Check that the license column has been removed
print(
  "license" %in% names(airbnb_chch_clean)
)



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

write_csv(
  airbnb_chch_clean,
  "data/processed/airbnb_christchurch_2026_06_clean.csv"
)


# ------------------------------------------------------------
# 18. Confirm processed file was created
# ------------------------------------------------------------

print(
  file.exists(
    "data/processed/airbnb_christchurch_2026_06_clean.csv"
  )
)
