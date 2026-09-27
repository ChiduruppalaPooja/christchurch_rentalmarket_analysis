# ============================================================
# DATA422 - Airbnb Christchurch Rental Market Analysis
# Deliverable 3: Combine October 2025 - June 2026
# ============================================================

library(tidyverse)


# ============================================================
# 1. Load monthly Airbnb datasets
# ============================================================

# Define the monthly Airbnb files included in the project.
# These files cover October 2025 to June 2026.
input_files <- c(
  "data/raw/listings_2025_10.csv",
  "data/raw/listings_2025_11.csv",
  "data/raw/listings_2025_12.csv",
  "data/raw/listings_2026_01.csv",
  "data/raw/listings_2026_02.csv",
  "data/raw/listings_2026_03.csv",
  "data/raw/listings_2026_04.csv",
  "data/raw/listings_2026_05.csv",
  "data/raw/listings_2026_06.csv"
)

output_file <- "data/processed/airbnb_christchurch_oct2025_jun2026_clean.csv"


expected_months <- c(
  "2025_10",
  "2025_11",
  "2025_12",
  "2026_01",
  "2026_02",
  "2026_03",
  "2026_04",
  "2026_05",
  "2026_06"
)

actual_months <- str_extract(
  basename(input_files),
  "\\d{4}_\\d{2}"
)

if (!identical(actual_months, expected_months)) {
  stop(
    "Monthly Airbnb inputs do not match the expected October 2025 to June 2026 period."
  )
}



missing_inputs <- input_files[!file.exists(input_files)]

if (length(missing_inputs) > 0) {
  stop(
    "Missing monthly Airbnb input file(s): ",
    paste(missing_inputs, collapse = ", ")
  )
}


dir.create("data/processed", recursive = TRUE, showWarnings = FALSE)
dir.create("output/tables", recursive = TRUE, showWarnings = FALSE)

# Read all monthly datasets into a list so they can be
# inspected, filtered, and combined consistently.
listings <- map(
  input_files,
  ~ read_csv(.x, show_col_types = FALSE)
)


# ============================================================
# 2. Initial inspection of monthly datasets
# ============================================================

# Inspect the structure of every monthly dataset before
# combining them. This checks that the files have compatible
# columns and identifies differences in data types or missing
# values between months.
map(listings, glimpse)

reference_columns <- names(listings[[1]])

structure_check <- map_lgl(
  listings,
  ~ identical(names(.x), reference_columns)
)

if (!all(structure_check)) {
  stop("Monthly Airbnb datasets do not have consistent columns.")
}
# Observation:
# The monthly files contain the same variables and can be
# combined. Several variables contain missing values, including
# price, last_review, reviews_per_month, minimum_nights, and
# license. Price is completely missing in December 2025,
# January 2026, and February 2026.


# ============================================================
# 3. Filter to Christchurch City
# ============================================================

# Restrict every monthly dataset to Christchurch City before
# combining the files. This prevents records from other
# neighbourhood groups from entering the project dataset.
listings_chch <- map(
  listings,
  ~ filter(.x, neighbourhood_group == "Christchurch City")
)

for (i in seq_along(listings_chch)) {
  if (nrow(listings_chch[[i]]) == 0) {
    stop(
      "Christchurch filtering produced zero rows for: ",
      basename(input_files[i])
    )
  }
  
  if (any(listings_chch[[i]]$neighbourhood_group != "Christchurch City")) {
    stop(
      "Non-Christchurch records remain in: ",
      basename(input_files[i])
    )
  }
}



# Observation:
# The filtered datasets contain Christchurch City records only.
# The column structure remains consistent across the monthly
# files.


# ============================================================
# 4. Add monthly snapshot identifier
# ============================================================

# Extract the year and month from each source filename and add
# it as month_year. This variable identifies which monthly
# snapshot each listing record came from and is required for
# analysing changes over time.
listings_chch <- map2(
  listings_chch,
  input_files,
  ~ mutate(
    .x,
    month_year = str_extract(
      basename(.y),
      "\\d{4}_\\d{2}"
    )
  )
)

expected_months <- str_extract(
  basename(input_files),
  "\\d{4}_\\d{2}"
)

actual_months <- map_chr(
  listings_chch,
  ~ unique(.x$month_year)
)

if (!identical(actual_months, expected_months)) {
  stop("One or more monthly datasets has incorrect month_year metadata.")
}

# Inspect the resulting structure to confirm that month_year
# has been added correctly to each monthly dataset.
map(listings_chch, glimpse)

# Observation:
# Each Christchurch dataset now contains a month_year field
# identifying its monthly snapshot.


# ============================================================
# 5. Combine the monthly datasets
# ============================================================

# Combine the nine filtered monthly datasets into one dataset
# for the project analysis.
listings_chch_combined <- bind_rows(listings_chch)

if (nrow(listings_chch_combined) == 0) {
  stop("Combined Airbnb dataset contains zero rows.")
}
snapshot_count <- n_distinct(listings_chch_combined$month_year)

if (snapshot_count != length(expected_months)) {
  stop(
    "Expected ",
    length(expected_months),
    " monthly snapshots, but found ",
    snapshot_count,
    "."
  )
}
if (any(
  listings_chch_combined$neighbourhood_group != "Christchurch City"
)) {
  stop("Combined dataset contains non-Christchurch records.")
}
# Check the dimensions of the combined dataset to confirm
# the number of records and variables after binding the files.
print(dim(listings_chch_combined))

# Check the number of Christchurch records contributed by each
# monthly dataset. This provides a breakdown of the combined
# row count before validating the total.
print(
  map_int(listings_chch, nrow)
)

# Calculate the sum of rows across all monthly datasets so it
# can be compared with the number of rows in the combined data.
print(
  sum(map_int(listings_chch, nrow))
)

# Confirm that the combined row count equals the sum of the
# individual monthly row counts. This verifies that bind_rows()
# did not unexpectedly lose or add records.
expected_rows <- sum(map_int(listings_chch, nrow))
actual_rows <- nrow(listings_chch_combined)

if (expected_rows != actual_rows) {
  stop(
    "Row-count validation failed: combined rows do not match ",
    "the sum of the monthly rows."
  )
}

# Observation:
# The combined dataset contains 28,795 Christchurch listing
# records across nine monthly snapshots. The combined row count
# equals the sum of the individual monthly datasets, confirming
# that the merge was successful.


# ============================================================
# 6. Inspect combined dataset
# ============================================================

# Inspect the combined dataset structure after merging to
# confirm that all expected variables are present and to
# identify their data types.
glimpse(listings_chch_combined)

# Check summary statistics across the combined dataset to
# identify unusual values and variables requiring further
# investigation.
print(
  summary(listings_chch_combined)
)


# ============================================================
# 7. Inspect missing values
# ============================================================

# Count missing values in every column to identify which
# variables require detailed missingness investigation.
print(
  colSums(is.na(listings_chch_combined))
)

# Observation:
# Missing values are present in:
# host_name: 1
# price: 10,667
# minimum_nights: 37
# last_review: 2,627
# reviews_per_month: 2,627
# license: 28,795
#
# The remaining variables contain no missing values.


# ============================================================
# 8. Inspect host_name
# ============================================================

# Inspect the single record with a missing host name to
# determine whether the missing value affects other fields.
print(
  listings_chch_combined |>
    filter(is.na(host_name))
)

# Observation:
# Only one host_name value is missing. The remaining listing
# information is populated. Host names are not required for the
# rental-market comparison, so the host_name column will be
# removed rather than attempting to infer the missing value.

missing_host_names <- sum(is.na(listings_chch_combined$host_name))

if (missing_host_names != 1) {
  warning(
    "Expected 1 missing host_name value, found ",
    missing_host_names,
    "."
  )
}
# ============================================================
# 9. Inspect price missingness
# ============================================================

# Examine missing prices by month to distinguish ordinary
# listing-level missingness from systematic missingness in
# particular source files.
print(
  listings_chch_combined |>
    group_by(month_year) |>
    summarise(
      total_records = n(),
      missing_price = sum(is.na(price)),
      non_missing_price = sum(!is.na(price)),
      missing_percentage = mean(is.na(price)) * 100,
      .groups = "drop"
    )
)

# Observation:
# Price is completely missing for December 2025, January 2026,
# and February 2026. Other months have approximately 5–8%
# missingness.
#
# The three consecutive months with 100% missing prices indicate
# a systematic source/data-collection issue rather than ordinary
# listing-level missingness.
#
# Price values will not be imputed because there is insufficient
# information to determine the correct values. The column is
# retained and records with missing prices will remain NA.
price_by_month <- listings_chch_combined |>
  group_by(month_year) |>
  summarise(
    total_records = n(),
    missing_price = sum(is.na(price)),
    non_missing_price = sum(!is.na(price)),
    missing_percentage = mean(is.na(price)) * 100,
    .groups = "drop"
  )

expected_full_missing_price_months <- c(
  "2025_12",
  "2026_01",
  "2026_02"
)

actual_full_missing_price_months <- price_by_month |>
  filter(missing_percentage == 100) |>
  pull(month_year)

if (!setequal(
  actual_full_missing_price_months,
  expected_full_missing_price_months
)) {
  warning(
    "The months with 100% missing prices differ from the documented expectation."
  )
}

# ============================================================
# 10. Inspect minimum_nights
# ============================================================

# Inspect the records with missing minimum_nights to determine
# whether the missingness is associated with the systematic
# missing-price period or occurs independently.
minimum_nights_missing <- listings_chch_combined |>
  filter(is.na(minimum_nights)) |>
  summarise(
    missing_count = n(),
    with_price = sum(!is.na(price)),
    without_price = sum(is.na(price))
  )

print(minimum_nights_missing)

# Observation:
# There are 37 missing minimum_nights values. Some occur during
# the period with systematic missing prices, while others occur
# when other listing information, including price, is available.
#
# The missing values will be retained as NA and will not be
# imputed.


# ============================================================
# 11. Inspect last_review
# ============================================================

# Examine missing last_review values by month to understand
# their temporal distribution.
print(
  listings_chch_combined |>
    group_by(month_year) |>
    summarise(
      total_records = n(),
      missing_last_review = sum(is.na(last_review)),
      non_missing_last_review = sum(!is.na(last_review)),
      missing_percentage = mean(is.na(last_review)) * 100,
      .groups = "drop"
    )
)

# Check whether missing last_review values are associated with
# listings that have no reviews.
last_review_missing_check <- listings_chch_combined |>
  filter(is.na(last_review)) |>
  count(number_of_reviews, sort = TRUE)

print(last_review_missing_check)
if (any(last_review_missing_check$number_of_reviews != 0)) {
  warning(
    "Some missing last_review values occur for listings with reviews."
  )
}

# Observation:
# All 2,627 missing last_review values occur where
# number_of_reviews is zero. This indicates that the missingness
# is structurally related to listings having no reviews rather
# than being unexplained missing data.
#
# The missing values are therefore retained as NA.


# ============================================================
# 12. Inspect reviews_per_month
# ============================================================

# Check whether missing reviews_per_month values are also
# associated with listings having no reviews.
reviews_per_month_missing_check <- listings_chch_combined |>
  filter(is.na(reviews_per_month)) |>
  count(number_of_reviews, sort = TRUE)

print(reviews_per_month_missing_check)

if (any(reviews_per_month_missing_check$number_of_reviews != 0)) {
  warning(
    "Some missing reviews_per_month values occur for listings with reviews."
  )
}

# Observation:
# All 2,627 missing reviews_per_month values occur where
# number_of_reviews is zero. These values represent listings
# without review activity rather than an unknown positive
# review rate.
#
# The missing values are retained as NA rather than being
# automatically replaced with zero.


# ============================================================
# 13. Inspect license
# ============================================================

# Count license values to confirm whether the field contains
# any usable information in the combined Christchurch dataset.
license_missing_count <- sum(is.na(listings_chch_combined$license))

if (license_missing_count != nrow(listings_chch_combined)) {
  warning(
    "The license column is not completely missing. Review before removing it."
  )
}

# Observation:
# License is missing for all 28,795 Christchurch records.
# Because the field contains no usable information in this
# dataset, it will be removed during cleaning.


# ============================================================
# 14. Cleaning decisions
# ============================================================

# Based on the inspection above:
#
# - price:
#   Retain the column and preserve missing values as NA.
#   Do not impute missing prices. Analyses requiring price
#   should exclude records where price is unavailable.
#
# - minimum_nights:
#   Retain the column and preserve its 37 missing values as NA.
#   Do not impute.
#
# - last_review:
#   Retain the column and preserve its 2,627 missing values as
#   NA. The missingness is associated with listings having no
#   reviews.
#
# - reviews_per_month:
#   Retain the column and preserve its 2,627 missing values as
#   NA. Do not automatically replace them with zero.
#
# - id:
#   Retain as the listing identifier. It is useful for identifying
#   listings and checking repeated observations across monthly
#   snapshots.
#
# - host_id:
#   Retain because it identifies hosts and can support analysis
#   of repeated listings or host activity.
#
# - neighbourhood:
#   Retain because it is relevant to geographic and
#   rental-market analysis.
#
# - latitude / longitude:
#   Retain because they support spatial analysis and mapping.
#
# - room_type:
#   Retain because accommodation type is relevant to rental
#   market analysis.
#
# - number_of_reviews:
#   Retain because it provides information about listing activity.
#
# - calculated_host_listings_count:
#   Retain because it describes the number of listings associated
#   with a host.
#
# - availability_365:
#   Retain because it provides information about listing supply
#   and availability.
#
# - number_of_reviews_ltm:
#   Retain because it provides a measure of recent listing
#   activity.
#
# - month_year:
#   Retain because it identifies the monthly snapshot and is
#   required for temporal analysis.
#
# - host_name:
#   Remove because individual host names are not required for
#   the rental-market comparison.
#
# - name:
#   Remove because the listing title is descriptive text and is
#   not required for the planned rental-market analysis.
#
# - neighbourhood_group:
#   Remove because all records have already been filtered to
#   Christchurch City, making the field redundant.
#
# - license:
#   Remove because all 28,795 observations are missing.


# ============================================================
# 15. Apply cleaning decisions
# ============================================================

# Remove fields that are either irrelevant to the analysis,
# redundant after Christchurch filtering, or entirely missing.
airbnb_christchurch_clean <- listings_chch_combined |>
  select(
    -name,
    -host_name,
    -neighbourhood_group,
    -license
  )

removed_columns <- c(
  "name",
  "host_name",
  "neighbourhood_group",
  "license"
)

if (any(removed_columns %in% names(airbnb_christchurch_clean))) {
  stop("One or more columns marked for removal are still present.")
}
# ============================================================
# 16. Validate cleaned dataset
# ============================================================

# Confirm the number of rows and columns after removing the
# four unnecessary variables.
print(
  dim(airbnb_christchurch_clean)
)

if (nrow(listings_chch_combined) != nrow(airbnb_christchurch_clean)) {
  stop(
    "Row count changed during column cleaning: ",
    nrow(listings_chch_combined),
    " before vs ",
    nrow(airbnb_christchurch_clean),
    " after."
  )
}
# Confirm the final set of variables retained for analysis.
print(
  names(airbnb_christchurch_clean)
)

# Check missing values after cleaning to confirm that no
# unexpected missing values were introduced or removed.
missing_summary <- airbnb_christchurch_clean |>
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
  ) |>
  filter(missing_count > 0)

print(missing_summary)

# Check completely duplicated rows to ensure that the cleaning
# process did not introduce duplicate records.
duplicate_rows <- sum(duplicated(airbnb_christchurch_clean))

if (duplicate_rows > 0) {
  stop(
    "Found ", duplicate_rows,
    " completely duplicated rows in the cleaned Airbnb dataset."
  )
}
# Check duplicate listing IDs within each monthly snapshot.
# The same listing ID is expected to appear across different
# months, but should not occur more than once within the same
# monthly snapshot.
duplicate_listing_months <- airbnb_christchurch_clean |>
  count(id, month_year) |>
  filter(n > 1)

if (nrow(duplicate_listing_months) > 0) {
  stop(
    "Found duplicate listing IDs within the same month."
  )
}
# Check how many listing IDs appear in more than one monthly
# snapshot. Repeated IDs across months are expected because
# the dataset contains monthly snapshots of the same listings.
print(
  airbnb_christchurch_clean |>
    count(id) |>
    summarise(
      listing_ids_repeated_across_months =
        sum(n > 1)
    )
)

# Observation:
# The cleaned dataset contains 28,795 records and 15 variables.
# The removed fields are no longer present.
#
# Missing values remain only in the variables where missingness
# was identified during inspection, and no completely duplicated
# rows are present.
#
# Listing IDs are unique within each monthly snapshot.
# Repeated listing IDs across different months are expected and
# represent the same listing being observed in multiple monthly
# snapshots.

repeated_listing_ids <- airbnb_christchurch_clean |>
  count(id) |>
  filter(n > 1)

if (nrow(repeated_listing_ids) == 0) {
  warning("No listing IDs repeat across monthly snapshots.")
}


snapshot_months <- sort(unique(airbnb_christchurch_clean$month_year))

if (!identical(snapshot_months, sort(expected_months))) {
  stop(
    "Final cleaned dataset does not contain exactly the expected monthly snapshots."
  )
}
# ============================================================
# 17. Save cleaned Airbnb dataset
# ============================================================

# Save the cleaned Christchurch Airbnb dataset for use in
# subsequent analysis and reproducible project workflows.
write_csv(airbnb_christchurch_clean, output_file)

if (!file.exists(output_file)) {
  stop("Cleaned Airbnb output file was not created.")
}

message("Cleaned Airbnb dataset saved successfully: ", output_file)