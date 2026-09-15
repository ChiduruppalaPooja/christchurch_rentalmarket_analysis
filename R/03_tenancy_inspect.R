# ============================================================
# DATA422 - Tenancy Data Inspection
# Step 2: Load raw tenancy data
# ============================================================

library(tidyverse)

tenancy_file <- "data/raw/Detailed-Quarterly-Tenancy-Q1-2020-Q3-2026.csv"

tenancy <- read_csv(
  tenancy_file,
  show_col_types = FALSE
)

# Check dimensions
print(dim(tenancy))

# Check column names and data types
print(glimpse(tenancy))

# Display first few rows
print(head(tenancy))



# ============================================================
# Step 3: Inspect tenancy values
# ============================================================

# Check date range
print(range(tenancy$TimeFrame, na.rm = TRUE))

# Check unique dwelling types
print(unique(tenancy$`Dwelling Type`))

# Check unique number of beds
print(unique(tenancy$`Number Of Beds`))

# Check special values in Location Id
print(
  tenancy |>
    count(`Location Id`, sort = TRUE) |>
    head(20)
)

# Check special values in rent-related columns
print(
  tenancy |>
    summarise(
      median_rent_null = sum(`Median Rent` == "NULL", na.rm = TRUE),
      geometric_mean_rent_null = sum(`Geometric Mean Rent` == "NULL", na.rm = TRUE),
      upper_quartile_rent_null = sum(`Upper Quartile Rent` == "NULL", na.rm = TRUE),
      lower_quartile_rent_null = sum(`Lower Quartile Rent` == "NULL", na.rm = TRUE),
      log_std_dev_null = sum(`Log Std Dev Weekly Rent` == "NULL", na.rm = TRUE)
    )
)

# Check missing values as recorded by R
print(
  tenancy |>
    summarise(
      across(
        everything(),
        ~ sum(is.na(.))
      )
    )
)

# ============================================================
# Step 4: Inspect tenancy dimensions
# ============================================================

# Check all TimeFrame values
print(
  tenancy |>
    count(TimeFrame) |>
    arrange(TimeFrame)
)

# Check Location Id special values
print(
  tenancy |>
    filter(`Location Id` %in% c("NULL", "-99")) |>
    count(`Location Id`, TimeFrame) |>
    arrange(TimeFrame, `Location Id`)
)

# Check dwelling type frequencies
print(
  tenancy |>
    count(`Dwelling Type`, sort = TRUE)
)

# Check Number Of Beds frequencies
print(
  tenancy |>
    count(`Number Of Beds`, sort = TRUE)
)

# Check combinations of dwelling type and Number Of Beds
print(
  tenancy |>
    count(`Dwelling Type`, `Number Of Beds`, sort = TRUE)
)


# ============================================================
# Step 5: Inspect full quarterly coverage
# ============================================================

# Full list of reporting periods
print(
  tenancy |>
    count(TimeFrame) |>
    arrange(TimeFrame),
  n = Inf
)

# Full list of special Location Id values by quarter
print(
  tenancy |>
    filter(`Location Id` %in% c("NULL", "-99")) |>
    count(`Location Id`, TimeFrame) |>
    arrange(TimeFrame, `Location Id`),
  n = Inf
)

# Full dwelling type distribution
print(
  tenancy |>
    count(`Dwelling Type`, sort = TRUE),
  n = Inf
)

# Full Number Of Beds distribution
print(
  tenancy |>
    count(`Number Of Beds`, sort = TRUE),
  n = Inf
)



# ============================================================
# Step 6: Inspect Location Id structure
# ============================================================

# Number of unique Location Id values
print(
  tenancy |>
    summarise(
      unique_location_ids = n_distinct(`Location Id`)
    )
)



# Show Location Id values that are not numeric-looking
print(
  tenancy |>
    filter(
      !grepl("^[0-9]+$", `Location Id`)
    ) |>
    count(`Location Id`, sort = TRUE)
)

# Show the range of numeric Location Id values
print(
  tenancy |>
    filter(grepl("^[0-9]+$", `Location Id`)) |>
    summarise(
      minimum_location_id = min(as.numeric(`Location Id`)),
      maximum_location_id = max(as.numeric(`Location Id`)),
      unique_numeric_ids = n_distinct(`Location Id`)
    )
)

# Inspect a sample of Location Ids
print(
  tenancy |>
    distinct(`Location Id`) |>
    arrange(`Location Id`) |>
    head(50),
  n = 50
)


# ============================================================
# Step 7: Check for geographic name information
# ============================================================

# Print all column names
print(names(tenancy))

# Print rows for a few selected Location Id values
print(
  tenancy |>
    filter(`Location Id` %in% c("100100", "179900", "251600", "327000")) |>
    select(
      TimeFrame,
      `Location Id`,
      `Dwelling Type`,
      `Number Of Beds`,
      `Total Bonds`,
      `Median Rent`
    ) |>
    head(20)
)

# Print rows where Location Id is -99 or NULL
print(
  tenancy |>
    filter(`Location Id` %in% c("-99", "NULL")) |>
    select(
      TimeFrame,
      `Location Id`,
      `Dwelling Type`,
      `Number Of Beds`,
      `Total Bonds`,
      `Median Rent`
    ) |>
    head(20)
)



# ============================================================
# Step 8: Check project for geographic lookup files
# ============================================================

print(
  list.files(
    "data",
    recursive = TRUE,
    full.names = TRUE
  )
)


# ============================================================
# Step 9: Inspect tenancy dataset metadata
# ============================================================

# Check the first few raw records
print(
  tenancy |>
    slice_head(n = 20)
)

# Check the last few raw records
print(
  tenancy |>
    slice_tail(n = 20)
)

# Check whether Location Id has a consistent number of digits
print(
  tenancy |>
    filter(grepl("^[0-9]+$", `Location Id`)) |>
    mutate(
      location_id_digits = nchar(`Location Id`)
    ) |>
    count(location_id_digits, sort = TRUE)
)

print(
  list.files(
    "data/raw",
    pattern = "SA2|sa2|2019",
    full.names = TRUE
  )
)

# ============================================================
# Step 10: Inspect TimeFrame values
# ============================================================

print(
  tenancy |>
    distinct(TimeFrame) |>
    arrange(TimeFrame),
  n = Inf
)


# ============================================================
# Step 10: Filter bond dataset to Airbnb comparison timeframe
# ============================================================

tenancy_period <- tenancy |>
  filter(
    TimeFrame >= as.Date("2025-10-01"),
    TimeFrame <= as.Date("2026-04-01")
  )

# Check the filtered timeframe
print(
  tenancy_period |>
    count(TimeFrame) |>
    arrange(TimeFrame)
)

# Check dimensions after timeframe filtering
print(dim(tenancy_period))


# ============================================================
# Step 11: Inspect bond dataset columns and data types
# ============================================================

print(
  tibble(
    column = names(tenancy_period),
    data_type = sapply(tenancy_period, class)
  )
)

# Check the first few rows of the filtered dataset
print(
  tenancy_period |>
    slice_head(n = 10)
)


# ============================================================
# Step 12: Inspect special values in the filtered bond dataset
# ============================================================

# Location Id special values
print(
  tenancy_period |>
    count(`Location Id`, sort = TRUE) |>
    filter(
      `Location Id` %in% c("NULL", "-99")
    )
)

# Rent columns: count special values
print(
  tenancy_period |>
    summarise(
      median_rent_NULL =
        sum(`Median Rent` == "NULL", na.rm = TRUE),
      
      geometric_mean_rent_NULL =
        sum(`Geometric Mean Rent` == "NULL", na.rm = TRUE),
      
      upper_quartile_rent_NULL =
        sum(`Upper Quartile Rent` == "NULL", na.rm = TRUE),
      
      lower_quartile_rent_NULL =
        sum(`Lower Quartile Rent` == "NULL", na.rm = TRUE),
      
      log_std_dev_NULL =
        sum(`Log Std Dev Weekly Rent` == "NULL", na.rm = TRUE)
    )
)

# Check whether any other special text values occur
# in the rent columns
print(
  tenancy_period |>
    summarise(
      median_rent_values =
        paste(sort(unique(`Median Rent`)), collapse = ", "),
      
      geometric_mean_values =
        paste(sort(unique(`Geometric Mean Rent`)), collapse = ", ")
    )
)

# ============================================================
# Step 13: Investigate Location Id special values
# ============================================================

print(
  tenancy_period |>
    filter(`Location Id` %in% c("NULL", "-99")) |>
    count(
      `Location Id`,
      `Dwelling Type`,
      `Number Of Beds`,
      sort = TRUE
    )
)

# Check whether the 94 NULL rent rows are exactly
# the rows with Location Id = NULL

print(
  tenancy_period |>
    summarise(
      location_id_NULL =
        sum(`Location Id` == "NULL"),
      
      location_id_minus99 =
        sum(`Location Id` == "-99"),
      
      median_rent_NULL =
        sum(`Median Rent` == "NULL"),
      
      median_rent_NULL_and_location_NULL =
        sum(
          `Median Rent` == "NULL" &
            `Location Id` == "NULL"
        )
    )
)

# ============================================================
# Step 14: Inspect -99 Location Id records
# ============================================================

print(
  tenancy_period |>
    filter(`Location Id` == "-99") |>
    select(
      TimeFrame,
      `Location Id`,
      `Dwelling Type`,
      `Number Of Beds`,
      `Total Bonds`,
      `Active Bonds`,
      `Closed Bonds`,
      `Median Rent`,
      `Geometric Mean Rent`,
      `Upper Quartile Rent`,
      `Lower Quartile Rent`,
      `Log Std Dev Weekly Rent`
    ) |>
    print(n = 30)
)

# ============================================================
# Step 15: Measure consequences of removing non-location rows
# ============================================================

print(
  tenancy_period |>
    group_by(
      `Location Id`
    ) |>
    summarise(
      rows = n(),
      .groups = "drop"
    ) |>
    filter(
      `Location Id` %in% c("NULL", "-99")
    )
)

# Count rows remaining if we keep only valid numeric Location Ids

print(
  tenancy_period |>
    filter(
      grepl("^[0-9]+$", `Location Id`)
    ) |>
    summarise(
      rows_remaining = n(),
      rows_removed = nrow(tenancy_period) - n()
    )
)


# ============================================================
# Step 16: Remove non-geographic Location Id records
# ============================================================

tenancy_location <- tenancy_period |>
  filter(
    grepl("^[0-9]+$", `Location Id`)
  )

# Check dimensions
print(dim(tenancy_location))

# Confirm all remaining Location Id values are numeric-looking
print(
  tenancy_location |>
    filter(!grepl("^[0-9]+$", `Location Id`)) |>
    count()
)

# ============================================================
# Step 17: Convert rent columns to numeric
# ============================================================

tenancy_location <- tenancy_location |>
  mutate(
    `Median Rent` =
      na_if(`Median Rent`, "NULL"),
    
    `Geometric Mean Rent` =
      na_if(`Geometric Mean Rent`, "NULL"),
    
    `Upper Quartile Rent` =
      na_if(`Upper Quartile Rent`, "NULL"),
    
    `Lower Quartile Rent` =
      na_if(`Lower Quartile Rent`, "NULL"),
    
    `Log Std Dev Weekly Rent` =
      na_if(`Log Std Dev Weekly Rent`, "NULL")
  ) |>
  mutate(
    `Median Rent` =
      as.numeric(`Median Rent`),
    
    `Geometric Mean Rent` =
      as.numeric(`Geometric Mean Rent`),
    
    `Upper Quartile Rent` =
      as.numeric(`Upper Quartile Rent`),
    
    `Lower Quartile Rent` =
      as.numeric(`Lower Quartile Rent`),
    
    `Log Std Dev Weekly Rent` =
      as.numeric(`Log Std Dev Weekly Rent`)
  )

# Check the resulting data types
print(
  tibble(
    column = names(tenancy_location),
    data_type = sapply(tenancy_location, class)
  )
)


# ============================================================
# Step 18: Check numeric variables for invalid values
# ============================================================

print(
  tenancy_location |>
    summarise(
      negative_total_bonds =
        sum(`Total Bonds` < 0, na.rm = TRUE),
      
      negative_active_bonds =
        sum(`Active Bonds` < 0, na.rm = TRUE),
      
      negative_closed_bonds =
        sum(`Closed Bonds` < 0, na.rm = TRUE),
      
      negative_median_rent =
        sum(`Median Rent` < 0, na.rm = TRUE),
      
      negative_geometric_mean_rent =
        sum(`Geometric Mean Rent` < 0, na.rm = TRUE),
      
      negative_upper_quartile_rent =
        sum(`Upper Quartile Rent` < 0, na.rm = TRUE),
      
      negative_lower_quartile_rent =
        sum(`Lower Quartile Rent` < 0, na.rm = TRUE),
      
      negative_log_std_dev =
        sum(`Log Std Dev Weekly Rent` < 0, na.rm = TRUE)
    )
)
# ============================================================
# Step 19: Check missing values after cleaning
# ============================================================

print(
  tenancy_location |>
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
    arrange(desc(missing_count))
)


# ============================================================
# Step 20: Investigate missing Number Of Beds
# ============================================================

print(
  tenancy_location |>
    filter(is.na(`Number Of Beds`)) |>
    count(
      TimeFrame,
      `Dwelling Type`,
      sort = TRUE
    )
)

# Inspect some of the affected records
print(
  tenancy_location |>
    filter(is.na(`Number Of Beds`)) |>
    select(
      TimeFrame,
      `Location Id`,
      `Dwelling Type`,
      `Number Of Beds`,
      `Total Bonds`,
      `Median Rent`
    ) |>
    slice_head(n = 30)
)

# ============================================================
# Step 21: Inspect categorical values
# ============================================================

print(
  tenancy_location |>
    count(`Dwelling Type`, sort = TRUE)
)

print(
  tenancy_location |>
    count(`Number Of Beds`, sort = TRUE)
)


# ============================================================
# Step 22: Check bond count consistency
# ============================================================

bond_count_check <- tenancy_location |>
  mutate(
    calculated_total =
      `Active Bonds` + `Closed Bonds`,
    
    difference =
      `Total Bonds` - calculated_total
  )

# Check whether Total Bonds equals Active + Closed Bonds
print(
  bond_count_check |>
    summarise(
      rows_checked = n(),
      matching_rows = sum(difference == 0, na.rm = TRUE),
      non_matching_rows = sum(difference != 0, na.rm = TRUE),
      missing_difference = sum(is.na(difference))
    )
)

# Inspect any non-matching records
print(
  bond_count_check |>
    filter(
      difference != 0
    ) |>
    select(
      TimeFrame,
      `Location Id`,
      `Dwelling Type`,
      `Number Of Beds`,
      `Total Bonds`,
      `Active Bonds`,
      `Closed Bonds`,
      difference
    ) |>
    slice_head(n = 20)
)


# ============================================================
# Step 23: Create final cleaned bond dataset
# ============================================================

tenancy_clean <- tenancy_location

# Check final dimensions
print(dim(tenancy_clean))

# Check final columns
print(names(tenancy_clean))

# Final check that required fields are present
print(
  all(
    c("TimeFrame", "Location Id") %in%
      names(tenancy_clean)
  )
)

# ============================================================
# Step 24: Save cleaned bond dataset
# ============================================================

write_csv(
  tenancy_clean,
  "data/processed/tenancy_christchurch_oct2025_jun2026_clean.csv"
)

# Confirm the processed file was created
print(
  file.exists(
    "data/processed/tenancy_christchurch_oct2025_jun2026_clean.csv"
  )
)