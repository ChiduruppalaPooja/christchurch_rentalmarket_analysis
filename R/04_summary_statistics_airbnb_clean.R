# ============================================================
# DATA422 - Airbnb Christchurch Rental Market Analysis
# Summary Statistics
# ============================================================

library(tidyverse)

# ============================================================
# Load cleaned dataset
# ============================================================

airbnb_christchurch_clean <- read_csv(
  "data/processed/airbnb_christchurch_oct2025_jun2026_clean.csv"
)

# ============================================================
# Missing-value summary
# ============================================================

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

# ============================================================
# Numeric summary statistics
# ============================================================

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

# ============================================================
# Categorical summary statistics
# ============================================================

categorical_summary <- airbnb_christchurch_clean |>
  select(
    neighbourhood,
    room_type,
    month_year
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

# ============================================================
# Frequency summaries
# ============================================================

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
  count(month_year) |>
  mutate(
    percent = round(n / sum(n) * 100, 2)
  )

print(room_type_summary)
print(neighbourhood_summary)
print(snapshot_summary)

# ============================================================
# Duplicate checks
# ============================================================

# Duplicate listing IDs within the same monthly snapshot

duplicate_ids_by_snapshot <- airbnb_christchurch_clean |>
  count(month_year, id) |>
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

#^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
#No duplicate listing IDs were found within individual monthly snapshots, and no completely duplicated rows were identified. Listings appearing across multiple snapshots were retained because each observation represents the listing at a different monthly point in time.
#^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^


# ============================================================
# Save summary tables
# ============================================================

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