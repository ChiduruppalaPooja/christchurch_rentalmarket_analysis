# ============================================================
# DATA422 - Tenancy Services Rental Data
# Cleaning and Inspection
# ============================================================

library(tidyverse)


# ============================================================
# 1. Load raw tenancy data
# ============================================================

tenancy_file <- "data/raw/Detailed-Quarterly-Tenancy-Q1-2020-Q3-2026.csv"

tenancy <- read_csv(
  tenancy_file,
  show_col_types = FALSE
)


# ============================================================
# 2. Initial data inspection
# ============================================================

# Check the number of observations and variables in the raw
# dataset before beginning any cleaning.
print(dim(tenancy))

# Check the column names to confirm the variables supplied
# by the source dataset.
print(names(tenancy))

# Inspect column data types and example values to identify
# variables that may require conversion or further inspection.
glimpse(tenancy)

# Inspect the first few records to understand the structure
# and representation of values in the raw dataset.
print(head(tenancy))


# ============================================================
# 3. Inspect TimeFrame
# ============================================================

# Check the first reporting period, last reporting period,
# and number of unique reporting periods to understand the
# temporal coverage of the dataset.
print(
  tenancy |>
    summarise(
      first_period = min(TimeFrame, na.rm = TRUE),
      last_period = max(TimeFrame, na.rm = TRUE),
      number_of_periods = n_distinct(TimeFrame)
    )
)

# Check the spacing between consecutive reporting periods
# to determine whether the quarterly reporting sequence is
# structurally consistent.
print(
  tenancy |>
    distinct(TimeFrame) |>
    arrange(TimeFrame) |>
    mutate(
      previous_period = lag(TimeFrame),
      gap_days = as.numeric(TimeFrame - previous_period)
    )
)

# Check for missing TimeFrame values because the reporting
# period is required to identify each observation temporally.
print(
  tenancy |>
    summarise(
      missing_TimeFrame = sum(is.na(TimeFrame))
    )
)

# Observation:
# TimeFrame is structurally complete. There are no missing
# dates and the reporting periods form a continuous quarterly
# sequence. No cleaning is required for TimeFrame.


# ============================================================
# 4. Inspect Location Id
# ============================================================

# Inspect the most frequent Location Id values to identify
# special source-coded values such as "-99" and "NULL".
print(
  tenancy |>
    count(`Location Id`, sort = TRUE) |>
    slice_head(n = 20)
)

# Check the number of unique Location Id values and whether
# any values are stored as actual NA.
print(
  tenancy |>
    summarise(
      unique_location_ids = n_distinct(`Location Id`),
      missing_location_id = sum(is.na(`Location Id`))
    )
)

# Check whether the "-99" and "NULL" Location Id records
# contain substantive bond data rather than empty records.
print(
  tenancy |>
    filter(`Location Id` %in% c("-99", "NULL")) |>
    summarise(
      records = n(),
      total_bonds = sum(`Total Bonds`, na.rm = TRUE),
      active_bonds = sum(`Active Bonds`, na.rm = TRUE),
      closed_bonds = sum(`Closed Bonds`, na.rm = TRUE)
    )
)

# Count the two special Location Id codes separately to
# understand how frequently each occurs.
print(
  tenancy |>
    filter(`Location Id` %in% c("-99", "NULL")) |>
    count(`Location Id`)
)

# Check missing values within the special-code records to
# determine whether these rows are otherwise empty or contain
# meaningful information.
print(
  tenancy |>
    filter(`Location Id` %in% c("-99", "NULL")) |>
    summarise(
      across(
        everything(),
        ~ sum(is.na(.))
      )
    )
)

# Examine the relationship between the special Location Id
# codes and Dwelling Type to determine whether the codes occur
# across different categories.
print(
  tenancy |>
    filter(`Location Id` %in% c("-99", "NULL")) |>
    count(`Location Id`, `Dwelling Type`, sort = TRUE)
)

# Check whether "-99" and "NULL" occur across the entire
# reporting period or only in isolated periods.
print(
  tenancy |>
    filter(`Location Id` %in% c("-99", "NULL")) |>
    count(TimeFrame, `Location Id`) |>
    arrange(TimeFrame, `Location Id`)
)

# Compare bond totals and rent availability between "-99"
# and "NULL" to determine whether the two codes have different
# characteristics.
print(
  tenancy |>
    filter(`Location Id` %in% c("-99", "NULL")) |>
    group_by(`Location Id`) |>
    summarise(
      records = n(),
      total_bonds = sum(`Total Bonds`, na.rm = TRUE),
      active_bonds = sum(`Active Bonds`, na.rm = TRUE),
      closed_bonds = sum(`Closed Bonds`, na.rm = TRUE),
      median_rent_null = sum(`Median Rent` == "NULL", na.rm = TRUE),
      .groups = "drop"
    )
)

# Check the relationship between the special Location Id
# codes and Median Rent availability.
print(
  tenancy |>
    filter(`Location Id` %in% c("-99", "NULL")) |>
    summarise(
      location_null = sum(`Location Id` == "NULL"),
      
      null_location_and_null_median =
        sum(
          `Location Id` == "NULL" &
            `Median Rent` == "NULL"
        ),
      
      null_location_and_valid_median =
        sum(
          `Location Id` == "NULL" &
            `Median Rent` != "NULL"
        ),
      
      minus99_and_null_median =
        sum(
          `Location Id` == "-99" &
            `Median Rent` == "NULL"
        ),
      
      minus99_and_valid_median =
        sum(
          `Location Id` == "-99" &
            `Median Rent` != "NULL"
        )
    )
)

# Inspect representative special-code records to confirm that
# they contain substantive observations and are not empty rows.
tenancy |>
  filter(`Location Id` %in% c("-99", "NULL")) |>
  select(
    TimeFrame,
    `Location Id`,
    `Dwelling Type`,
    `Number Of Beds`,
    `Total Bonds`,
    `Median Rent`,
    `Geometric Mean Rent`,
    `Upper Quartile Rent`,
    `Lower Quartile Rent`
  ) |>
  arrange(
    `Location Id`,
    TimeFrame,
    `Dwelling Type`,
    `Number Of Beds`
  ) |>
  print(n = 40)

# Check the number of digits in numeric-looking Location Ids
# to determine whether geographic IDs follow a consistent
# structural format.
print(
  tenancy |>
    filter(grepl("^[0-9]+$", `Location Id`)) |>
    mutate(
      location_id_digits = nchar(`Location Id`)
    ) |>
    count(location_id_digits, sort = TRUE)
)

# Observation:
# Numeric Location Ids consistently contain six digits.
# The source-coded values "-99" and "NULL" occur across
# periods and dwelling types and contain substantive records.
# Their precise semantic meaning cannot be established from
# this dataset alone, so they are preserved rather than
# removed or recoded. Numeric Location Ids require no
# reformatting.


# ============================================================
# 5. Inspect Dwelling Type
# ============================================================

# Count each Dwelling Type category to identify the values
# represented in the dataset.
print(
  tenancy |>
    count(`Dwelling Type`, sort = TRUE)
)

# Check the number of categories and whether any Dwelling Type
# values are actually missing.
print(
  tenancy |>
    summarise(
      unique_dwelling_types = n_distinct(`Dwelling Type`),
      missing_dwelling_type = sum(is.na(`Dwelling Type`))
    )
)

# Observation:
# Dwelling Type contains six categories:
# ALL, House, Flat, Apartment, Room, and Boarding House.
# There are no missing values. No cleaning is required.


# ============================================================
# 6. Inspect Number Of Beds
# ============================================================

# Inspect the frequency of Number Of Beds values to identify
# numeric-style values and explicit categories such as "ALL"
# and "5+".
print(
  tenancy |>
    count(`Number Of Beds`, sort = TRUE)
)

# Check which dwelling types contain missing Number Of Beds
# values to understand whether missingness is concentrated
# in particular categories.
print(
  tenancy |>
    filter(is.na(`Number Of Beds`)) |>
    count(`Dwelling Type`, sort = TRUE)
)

# Check missing Number Of Beds by reporting period to identify
# whether missingness is stable or changes over time.
tenancy |>
  filter(is.na(`Number Of Beds`)) |>
  count(TimeFrame) |>
  arrange(TimeFrame) |>
  print(n = Inf)

# Examine the periods with higher missingness in 2025 and
# identify which dwelling types contribute to it.
tenancy |>
  filter(
    is.na(`Number Of Beds`),
    TimeFrame >= as.Date("2025-01-01"),
    TimeFrame <= as.Date("2025-10-01")
  ) |>
  count(TimeFrame, `Dwelling Type`) |>
  arrange(TimeFrame, desc(n)) |>
  print(n = Inf)

# Check where the explicit "ALL" category is used across
# dwelling types to determine whether it is a deliberate
# aggregate category rather than a missing-value code.
tenancy |>
  count(`Number Of Beds`, `Dwelling Type`, sort = TRUE) |>
  filter(`Number Of Beds` == "ALL") |>
  print(n = Inf)

# Observation:
# Number Of Beds contains numeric-style values as well as
# meaningful categorical values such as "ALL" and "5+".
# There are 12,009 actual missing values. "ALL" is used
# systematically and is therefore retained as an explicit
# category. Missing values are retained and not imputed.


# ============================================================
# 7. Inspect Total Bonds
# ============================================================

# Check missingness, range, and number of unique values to
# assess the basic structure of Total Bonds.
print(
  tenancy |>
    summarise(
      missing_total_bonds = sum(is.na(`Total Bonds`)),
      min_total_bonds = min(`Total Bonds`, na.rm = TRUE),
      max_total_bonds = max(`Total Bonds`, na.rm = TRUE),
      unique_total_bonds = n_distinct(`Total Bonds`)
    )
)

# Inspect the most frequent Total Bonds values to understand
# the distribution and identify unusual coding patterns.
print(
  tenancy |>
    count(`Total Bonds`, sort = TRUE) |>
    slice_head(n = 20)
)

# Observation:
# Total Bonds contains no missing values and no negative values.
# Values range from 6 to 49,875. No cleaning is required.


# ============================================================
# 8. Inspect Active Bonds
# ============================================================

# Check missingness, range, and number of unique values to
# assess the basic structure of Active Bonds.
print(
  tenancy |>
    summarise(
      missing_active_bonds = sum(is.na(`Active Bonds`)),
      min_active_bonds = min(`Active Bonds`, na.rm = TRUE),
      max_active_bonds = max(`Active Bonds`, na.rm = TRUE),
      unique_active_bonds = n_distinct(`Active Bonds`)
    )
)

# Inspect the most frequent Active Bonds values to understand
# their distribution and confirm that zero occurs as a value.
print(
  tenancy |>
    count(`Active Bonds`, sort = TRUE) |>
    slice_head(n = 20)
)

# Observation:
# Active Bonds contains no missing or negative values.
# Zero is retained as a valid recorded value. No cleaning
# is required.


# ============================================================
# 9. Inspect Closed Bonds
# ============================================================

# Check missingness, range, and number of unique values to
# assess the basic structure of Closed Bonds.
print(
  tenancy |>
    summarise(
      missing_closed_bonds = sum(is.na(`Closed Bonds`)),
      min_closed_bonds = min(`Closed Bonds`, na.rm = TRUE),
      max_closed_bonds = max(`Closed Bonds`, na.rm = TRUE),
      unique_closed_bonds = n_distinct(`Closed Bonds`)
    )
)

# Inspect the most frequent Closed Bonds values to understand
# their distribution and confirm that zero is a valid value.
print(
  tenancy |>
    count(`Closed Bonds`, sort = TRUE) |>
    slice_head(n = 20)
)

# Observation:
# Closed Bonds contains no missing or negative values.
# Zero is a valid recorded value. No cleaning is required.


# ============================================================
# 10. Validate bond values
# ============================================================

# Check for negative bond counts because bond counts cannot
# logically be negative.
print(
  tenancy |>
    summarise(
      negative_total_bonds =
        sum(`Total Bonds` < 0, na.rm = TRUE),
      
      negative_active_bonds =
        sum(`Active Bonds` < 0, na.rm = TRUE),
      
      negative_closed_bonds =
        sum(`Closed Bonds` < 0, na.rm = TRUE)
    )
)

# Check whether Total Bonds equals Active Bonds plus Closed
# Bonds. This tests whether the three variables form an
# additive relationship in this dataset.
print(
  tenancy |>
    mutate(
      calculated_total = `Active Bonds` + `Closed Bonds`
    ) |>
    summarise(
      total_records = n(),
      matching =
        sum(`Total Bonds` == calculated_total),
      not_matching =
        sum(`Total Bonds` != calculated_total)
    )
)

# Observation:
# No negative bond values were found.
# Total Bonds does not generally equal Active Bonds plus
# Closed Bonds. Therefore, this additive relationship is not
# imposed during cleaning and all three variables are retained
# as supplied.


# ============================================================
# 11. Inspect Median Rent
# ============================================================

# Inspect the most frequent values to identify the "NULL"
# source code and the numeric-looking rent values.
print(
  tenancy |>
    count(`Median Rent`, sort = TRUE) |>
    slice_head(n = 20)
)

# Count actual NA values and source-coded "NULL" values
# separately because "NULL" is currently stored as text.
print(
  tenancy |>
    summarise(
      missing_median_rent =
        sum(is.na(`Median Rent`)),
      
      null_median_rent =
        sum(`Median Rent` == "NULL", na.rm = TRUE)
    )
)

# Check when and where Median Rent is coded as "NULL" to
# determine whether missingness is isolated or systematic.
tenancy |>
  filter(`Median Rent` == "NULL") |>
  count(TimeFrame, `Dwelling Type`, sort = TRUE) |>
  print(n = Inf)

# Observation:
# Median Rent contains 803 source-coded "NULL" values and
# no actual NA values. "NULL" represents unavailable rent
# information rather than zero. It will be converted to NA
# and the column will then be converted to numeric.


# ============================================================
# 12. Inspect Geometric Mean Rent
# ============================================================

# Inspect the most frequent values to confirm the structure
# and identify source-coded "NULL" values.
print(
  tenancy |>
    count(`Geometric Mean Rent`, sort = TRUE) |>
    slice_head(n = 20)
)

# Observation:
# Geometric Mean Rent contains 803 "NULL" values, matching
# the number found for Median Rent. These values represent
# unavailable observations. The column will be converted from
# character to numeric after replacing "NULL" with NA.


# ============================================================
# 13. Inspect Upper Quartile Rent
# ============================================================

# Inspect the most frequent values to identify "NULL" and
# numeric-looking rent values.
print(
  tenancy |>
    count(`Upper Quartile Rent`, sort = TRUE) |>
    slice_head(n = 20)
)

# Check actual NA and source-coded "NULL" values separately.
print(
  tenancy |>
    summarise(
      missing_upper_quartile =
        sum(is.na(`Upper Quartile Rent`)),
      
      null_upper_quartile =
        sum(`Upper Quartile Rent` == "NULL", na.rm = TRUE)
    )
)

# Observation:
# Upper Quartile Rent contains 803 "NULL" values and no
# actual NA values. "NULL" will be converted to NA and the
# column will then be converted to numeric.


# ============================================================
# 14. Inspect Lower Quartile Rent
# ============================================================

# Inspect the most frequent values to identify "NULL" and
# numeric-looking rent values.
print(
  tenancy |>
    count(`Lower Quartile Rent`, sort = TRUE) |>
    slice_head(n = 20)
)

# Check actual NA and source-coded "NULL" values separately.
print(
  tenancy |>
    summarise(
      missing_lower_quartile =
        sum(is.na(`Lower Quartile Rent`)),
      
      null_lower_quartile =
        sum(`Lower Quartile Rent` == "NULL", na.rm = TRUE)
    )
)

# Observation:
# Lower Quartile Rent contains 803 "NULL" values and no
# actual NA values. "NULL" will be converted to NA and the
# column will then be converted to numeric.


# ============================================================
# 15. Compare missingness across main rent measures
# ============================================================

# Check whether Median, Geometric Mean, Upper Quartile, and
# Lower Quartile Rent are missing on the same records.
print(
  tenancy |>
    summarise(
      median_null =
        sum(`Median Rent` == "NULL", na.rm = TRUE),
      
      geometric_null =
        sum(`Geometric Mean Rent` == "NULL", na.rm = TRUE),
      
      upper_null =
        sum(`Upper Quartile Rent` == "NULL", na.rm = TRUE),
      
      lower_null =
        sum(`Lower Quartile Rent` == "NULL", na.rm = TRUE),
      
      all_four_null =
        sum(
          `Median Rent` == "NULL" &
            `Geometric Mean Rent` == "NULL" &
            `Upper Quartile Rent` == "NULL" &
            `Lower Quartile Rent` == "NULL"
        )
    )
)

# Check for negative rent values before converting the columns
# to numeric to identify impossible negative observations.
print(
  tenancy |>
    summarise(
      negative_median =
        sum(
          suppressWarnings(as.numeric(`Median Rent`)) < 0,
          na.rm = TRUE
        ),
      
      negative_geometric =
        sum(
          suppressWarnings(as.numeric(`Geometric Mean Rent`)) < 0,
          na.rm = TRUE
        ),
      
      negative_upper =
        sum(
          suppressWarnings(as.numeric(`Upper Quartile Rent`)) < 0,
          na.rm = TRUE
        ),
      
      negative_lower =
        sum(
          suppressWarnings(as.numeric(`Lower Quartile Rent`)) < 0,
          na.rm = TRUE
        )
    )
)

# Observation:
# All four main rent measures contain "NULL" on the same
# 803 records. These observations therefore have the main
# rent statistics jointly unavailable. No negative rent
# values were found. "NULL" will be converted to NA and
# no imputation will be performed.


# ============================================================
# 16. Inspect Log Std Dev Weekly Rent
# ============================================================

# Inspect the most frequent values to identify "NULL", zero,
# and the numeric distribution of the variable.
print(
  tenancy |>
    count(`Log Std Dev Weekly Rent`, sort = TRUE) |>
    slice_head(n = 20)
)

# Check how many "NULL" values occur and whether they coincide
# with records where the four main rent measures are missing.
print(
  tenancy |>
    summarise(
      log_sd_null =
        sum(`Log Std Dev Weekly Rent` == "NULL"),
      
      log_sd_and_all_rent_null =
        sum(
          `Log Std Dev Weekly Rent` == "NULL" &
            `Median Rent` == "NULL" &
            `Geometric Mean Rent` == "NULL" &
            `Upper Quartile Rent` == "NULL" &
            `Lower Quartile Rent` == "NULL"
        ),
      
      log_sd_null_but_rent_available =
        sum(
          `Log Std Dev Weekly Rent` == "NULL" &
            `Median Rent` != "NULL"
        )
    )
)

# Check for negative values and identify the minimum numeric
# value to confirm that zero is a valid observation.
print(
  tenancy |>
    summarise(
      negative_log_sd =
        sum(
          suppressWarnings(
            as.numeric(`Log Std Dev Weekly Rent`)
          ) < 0,
          na.rm = TRUE
        ),
      
      minimum_log_sd =
        min(
          suppressWarnings(
            as.numeric(`Log Std Dev Weekly Rent`)
          ),
          na.rm = TRUE
        )
    )
)

# Observation:
# Log Std Dev Weekly Rent contains 859 "NULL" values.
# Zero is a valid numeric value and no negative values were
# found. "NULL" will therefore be converted to NA, while
# genuine zero values will be retained. No imputation will
# be performed.


# ============================================================
# 17. Check for unexpected non-numeric rent values
# ============================================================

# Check whether any rent fields contain unexpected text values
# other than the known "NULL" source code before conversion.
print(
  tenancy |>
    summarise(
      median_bad =
        sum(
          is.na(
            suppressWarnings(as.numeric(`Median Rent`))
          ) &
            `Median Rent` != "NULL",
          na.rm = TRUE
        ),
      
      geometric_bad =
        sum(
          is.na(
            suppressWarnings(as.numeric(`Geometric Mean Rent`))
          ) &
            `Geometric Mean Rent` != "NULL",
          na.rm = TRUE
        ),
      
      upper_bad =
        sum(
          is.na(
            suppressWarnings(as.numeric(`Upper Quartile Rent`))
          ) &
            `Upper Quartile Rent` != "NULL",
          na.rm = TRUE
        ),
      
      lower_bad =
        sum(
          is.na(
            suppressWarnings(as.numeric(`Lower Quartile Rent`))
          ) &
            `Lower Quartile Rent` != "NULL",
          na.rm = TRUE
        ),
      
      log_sd_bad =
        sum(
          is.na(
            suppressWarnings(
              as.numeric(`Log Std Dev Weekly Rent`)
            )
          ) &
            `Log Std Dev Weekly Rent` != "NULL",
          na.rm = TRUE
        )
    )
)

# Observation:
# No unexpected non-numeric strings were found in any of the
# five rent-related variables. The only non-numeric source
# value requiring conversion is "NULL".


# ============================================================
# 18. Check uniqueness of reporting-unit combinations
# ============================================================

# Check whether each combination of TimeFrame, Location Id,
# Dwelling Type, and Number Of Beds occurs only once. This
# identifies duplicate observations at the expected reporting
# unit level.
print(
  tenancy |>
    count(
      TimeFrame,
      `Location Id`,
      `Dwelling Type`,
      `Number Of Beds`,
      name = "n"
    ) |>
    summarise(
      duplicate_combinations = sum(n > 1),
      maximum_repetitions = max(n)
    )
)

# Observation:
# Each combination occurs only once. No duplicate observations
# were identified at the expected reporting-unit level.


# ============================================================
# 19. Cleaning decisions
# ============================================================

# Based on the inspection:
#
# - TimeFrame is complete and structurally consistent.
#
# - Location Id contains consistent six-digit numeric IDs and
#   source-coded "-99" and "NULL" values. The special codes
#   contain substantive records, so they are retained rather
#   than removed or recoded without a documented definition.
#
# - Dwelling Type contains six valid categories and no missing
#   values, so it is retained unchanged.
#
# - Number Of Beds is retained as character because "ALL" and
#   "5+" are meaningful categorical values. Missing values are
#   retained and are not imputed.
#
# - Total Bonds, Active Bonds, and Closed Bonds contain no
#   missing or negative values and are retained as supplied.
#
# - The additive relationship Total Bonds =
#   Active Bonds + Closed Bonds does not generally hold, so
#   this relationship is not imposed during cleaning.
#
# - "NULL" in the five rent-related variables is converted
#   to NA, followed by conversion of those columns to numeric.
#
# - Genuine zero values in Log Std Dev Weekly Rent are retained.
#
# - Missing rent values are not imputed.
#
# - No unexpected non-numeric strings were found.
#
# - No duplicate reporting-unit combinations were identified.
#
# - The full cleaned dataset is preserved. The project-period
#   restriction is applied separately after cleaning.


# ============================================================
# 20. Apply cleaning decisions
# ============================================================

rent_cols <- c(
  "Median Rent",
  "Geometric Mean Rent",
  "Upper Quartile Rent",
  "Lower Quartile Rent",
  "Log Std Dev Weekly Rent"
)

tenancy_clean <- tenancy |>
  mutate(
    across(
      all_of(rent_cols),
      ~ na_if(.x, "NULL")
    )
  ) |>
  mutate(
    across(
      all_of(rent_cols),
      as.numeric
    )
  )


# ============================================================
# 21. Validate cleaned dataset
# ============================================================

# Check the cleaned data types and confirm that the rent
# variables have been converted from character to numeric.
glimpse(tenancy_clean)

# Check missing-value counts after cleaning to confirm that
# only the expected missing values were introduced.
print(
  colSums(is.na(tenancy_clean))
)

# Confirm that the number of rows and columns has not changed
# during cleaning.
print(
  dim(tenancy_clean)
)

# Recheck the reporting-unit key after cleaning to confirm
# that no duplicate combinations were introduced or removed.
duplicate_check <- tenancy_clean |>
  count(
    TimeFrame,
    `Location Id`,
    `Dwelling Type`,
    `Number Of Beds`,
    name = "n"
  ) |>
  summarise(
    duplicate_combinations = sum(n > 1),
    maximum_repetitions = max(n)
  )

print(duplicate_check)


# ============================================================
# 22. Save full cleaned dataset
# ============================================================

# Save the complete cleaned Tenancy dataset separately from
# the project-period subset so the full cleaned source remains
# available for reproducible analysis.
write_csv(
  tenancy_clean,
  "data/processed/tenancy_clean.csv"
)


# ============================================================
# 23. Create project-period dataset
# ============================================================

# Restrict the cleaned dataset to the period shared with the
# Airbnb analysis. The Tenancy source contains quarterly data,
# so the available periods within the project window are
# October 2025, January 2026, and April 2026.
tenancy_project <- tenancy_clean |>
  filter(
    TimeFrame >= as.Date("2025-10-01"),
    TimeFrame <= as.Date("2026-04-01")
  )

# Check the number of records and variables in the project
# subset to confirm that the filtering produced the expected
# analysis dataset.
print(
  dim(tenancy_project)
)

# Check the exact reporting periods included in the project
# subset to verify that the correct quarterly observations
# were retained.
print(
  unique(tenancy_project$TimeFrame)
)


# ============================================================
# 24. Save project-period dataset
# ============================================================

# Save the project-period dataset for use in the combined
# Airbnb and Tenancy analysis.
write_csv(
  tenancy_project,
  "data/processed/tenancy_christchurch_oct2025_jun2026_clean.csv"
)