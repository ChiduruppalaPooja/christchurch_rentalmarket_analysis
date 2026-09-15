# ============================================================
# DATA422 - Airbnb Christchurch Rental Market Analysis
# Deliverable 3: Combine October 2025 - June 2026
# ============================================================


# ============================================================
# 1. Load packages
# ============================================================

library(tidyverse)


# ============================================================
# 2. Define raw files and snapshot dates
# ============================================================

airbnb_files <- tibble(
  file = c(
    "data/raw/listings_2025_10.csv",
    "data/raw/listings_2025_11.csv",
    "data/raw/listings_2025_12.csv",
    "data/raw/listings_2026_01.csv",
    "data/raw/listings_2026_02.csv",
    "data/raw/listings_2026_03.csv",
    "data/raw/listings_2026_04.csv",
    "data/raw/listings_2026_05.csv",
    "data/raw/listings_2026_06.csv"
  ),
  snapshot_month = c(
    "October",
    "November",
    "December",
    "January",
    "February",
    "March",
    "April",
    "May",
    "June"
  ),
  snapshot_year = c(
    2025,
    2025,
    2025,
    2026,
    2026,
    2026,
    2026,
    2026,
    2026
  )
)


# Check that all nine files exist
print(file.exists(airbnb_files$file))


# ============================================================
# 3. Read, filter Christchurch, and add snapshot information
# ============================================================

airbnb_christchurch_list <- map2(
  airbnb_files$file,
  seq_len(nrow(airbnb_files)),
  ~ read_csv(
    .x,
    col_types = cols(
      id = col_character(),
      host_id = col_character()
    )
  ) |>
    filter(neighbourhood_group == "Christchurch City") |>
    mutate(
      snapshot_month = airbnb_files$snapshot_month[.y],
      snapshot_year = airbnb_files$snapshot_year[.y]
    )
)

# ============================================================
# 4. Check Christchurch records for each snapshot
# ============================================================

snapshot_counts <- map2_dfr(
  airbnb_christchurch_list,
  airbnb_files$snapshot_month,
  ~ tibble(
    snapshot_month = .y,
    n_christchurch = nrow(.x)
  )
)

print(snapshot_counts)

# ============================================================
# 5. Combine all nine Christchurch datasets
# ============================================================

airbnb_christchurch_combined <- bind_rows(
  airbnb_christchurch_list
)

# ============================================================
# 6. Inspect the combined dataset
# ============================================================

print(dim(airbnb_christchurch_combined))

print(glimpse(airbnb_christchurch_combined))

print(names(airbnb_christchurch_combined))


# ============================================================
# 7. Check number of records by snapshot
# ============================================================

print(
  airbnb_christchurch_combined |>
    count(snapshot_year, snapshot_month)
)

# ============================================================
# 9. Check missing values
# ============================================================

missing_values <- airbnb_christchurch_combined |>
  summarise(
    across(
      everything(),
      ~ sum(is.na(.))
    )
  ) |>
  pivot_longer(
    cols = everything(),
    names_to = "variable",
    values_to = "missing_count"
  ) |>
  mutate(
    missing_percent =
      round(
        missing_count / nrow(airbnb_christchurch_combined) * 100,
        2
      )
  ) |>
  arrange(desc(missing_count))

print(missing_values)

print(airbnb_christchurch_combined |>
  group_by(snapshot_year, snapshot_month) |>
  summarise(
    total = n(),
    missing_price = sum(is.na(price)),
    missing_price_percent = round(
      mean(is.na(price)) * 100,
      2
    )
  ))

print(airbnb_christchurch_combined |>
  group_by(snapshot_year, snapshot_month) |>
  summarise(
    total = n(),
    missing_price = sum(is.na(price)),
    missing_minimum_nights = sum(is.na(minimum_nights)),
    missing_reviews = sum(is.na(number_of_reviews)),
    missing_last_review = sum(is.na(last_review)),
    missing_license = sum(is.na(license))
  ))



print(airbnb_christchurch_combined |>
        filter(
          snapshot_month %in% c("December", "January", "February")
        ) |>
        select(
          snapshot_year,
          snapshot_month,
          id,
          name,
          room_type,
          price,
          minimum_nights,
          availability_365
        ) |>
        head(20))
print(map_dfr(
  airbnb_files$file,
  ~ read_csv(.x, show_col_types = FALSE) |>
    summarise(
      file = .x,
      rows = n(),
      price_missing = sum(is.na(price)),
      price_available = sum(!is.na(price))
    )
))


print(airbnb_christchurch_combined |>
        group_by(snapshot_year, snapshot_month) |>
        summarise(
          across(
            everything(),
            ~ sum(is.na(.))
          ),
          .groups = "drop"
        ))


print(airbnb_christchurch_combined |>
        filter(is.na(minimum_nights)) |>
        select(
          snapshot_year,
          snapshot_month,
          id,
          name,
          room_type,
          price,
          number_of_reviews,
          availability_365
        ))


print(airbnb_christchurch_combined |>
        filter(is.na(minimum_nights)) |>
        count(snapshot_year, snapshot_month))


print(names(airbnb_christchurch_combined))

print(airbnb_christchurch_combined |>
        summarise(
          across(
            everything(),
            ~ n_distinct(.)
          )
        ) |>
        pivot_longer(
          cols = everything(),
          names_to = "variable",
          values_to = "unique_values"
        ) |>
        arrange(desc(unique_values)))


print(airbnb_christchurch_combined |>
        filter(
          is.na(last_review) | is.na(reviews_per_month)
        ) |>
        count(number_of_reviews, sort = TRUE))


# ------------------------------------------------------------
# Clean the combined Christchurch dataset
# ------------------------------------------------------------

airbnb_christchurch_clean <- airbnb_christchurch_combined |>
  select(
    -name,
    -host_name,
    -license
  )
print(dim(airbnb_christchurch_clean))
      
print(names(airbnb_christchurch_clean))


write_csv(
  airbnb_christchurch_clean,
  "data/processed/airbnb_christchurch_oct2025_jun2026_clean.csv"
)

# ------------------------------------------------------------
# Missing-value summary
# ------------------------------------------------------------

missing_values <- airbnb_christchurch_clean |>
  summarise(
    across(
      everything(),
      ~ sum(is.na(.))
    )
  ) |>
  pivot_longer(
    cols = everything(),
    names_to = "variable",
    values_to = "missing_count"
  ) |>
  mutate(
    missing_percent = round(
      missing_count / nrow(airbnb_christchurch_clean) * 100,
      2
    )
  ) |>
  arrange(desc(missing_count))

print(missing_values)


# ------------------------------------------------------------
# Numeric summary statistics
# ------------------------------------------------------------

numeric_summary <- airbnb_christchurch_clean |>
  summarise(
    across(
      where(is.numeric),
      list(
        count = ~ sum(!is.na(.)),
        missing = ~ sum(is.na(.)),
        mean = ~ mean(., na.rm = TRUE),
        median = ~ median(., na.rm = TRUE),
        min = ~ min(., na.rm = TRUE),
        max = ~ max(., na.rm = TRUE),
        sd = ~ sd(., na.rm = TRUE)
      )
    )
  ) |>
  pivot_longer(
    cols = everything(),
    names_to = c("variable", "statistic"),
    names_sep = "_(?=[^_]+$)",
    values_to = "value"
  ) |>
  pivot_wider(
    names_from = statistic,
    values_from = value
  )

print(numeric_summary)


# ------------------------------------------------------------
# Categorical summary statistics
# ------------------------------------------------------------

categorical_summary <- airbnb_christchurch_clean |>
  select(
    neighbourhood_group,
    neighbourhood,
    room_type,
    snapshot_month
  ) |>
  summarise(
    across(
      everything(),
      ~ n_distinct(.)
    )
  ) |>
  pivot_longer(
    cols = everything(),
    names_to = "variable",
    values_to = "unique_values"
  )

print(categorical_summary)


# ------------------------------------------------------------
# Frequency summaries for categorical variables
# ------------------------------------------------------------

room_type_summary <- airbnb_christchurch_clean |>
  count(room_type, sort = TRUE) |>
  mutate(
    percent = round(n / sum(n) * 100, 2)
  )

neighbourhood_summary <- airbnb_christchurch_clean |>
  count(neighbourhood, sort = TRUE) |>
  mutate(
    percent = round(n / sum(n) * 100, 2)
  )

snapshot_summary <- airbnb_christchurch_clean |>
  count(snapshot_year, snapshot_month) |>
  mutate(
    percent = round(n / sum(n) * 100, 2)
  )

print(room_type_summary)
print(neighbourhood_summary)
print(snapshot_summary)



# ------------------------------------------------------------
# Duplicate checks
# ------------------------------------------------------------

# Duplicate listing IDs within the same monthly snapshot
duplicate_ids_by_snapshot <- airbnb_christchurch_clean |>
  count(snapshot_year, snapshot_month, id) |>
  filter(n > 1)

print(duplicate_ids_by_snapshot)

# Listing IDs appearing across multiple snapshots
repeated_listings <- airbnb_christchurch_clean |>
  count(id) |>
  filter(n > 1) |>
  arrange(desc(n))

print(repeated_listings)

# Completely duplicated rows
duplicate_rows <- airbnb_christchurch_clean |>
  duplicated() |>
  sum()

print(duplicate_rows)



# ------------------------------------------------------------
# Save summary tables
# ------------------------------------------------------------

write_csv(
  missing_values,
  "output/tables/airbnb_missing_values.csv"
)

write_csv(
  numeric_summary,
  "output/tables/airbnb_numeric_summary.csv"
)

write_csv(
  categorical_summary,
  "output/tables/airbnb_categorical_summary.csv"
)

write_csv(
  room_type_summary,
  "output/tables/airbnb_room_type_summary.csv"
)

write_csv(
  neighbourhood_summary,
  "output/tables/airbnb_neighbourhood_summary.csv"
)

write_csv(
  snapshot_summary,
  "output/tables/airbnb_snapshot_summary.csv"
)