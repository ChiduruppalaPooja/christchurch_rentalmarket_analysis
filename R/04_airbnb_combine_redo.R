# DATA422 - Airbnb Christchurch Rental Market Analysis
# Deliverable 3: Combine October 2025 - June 2026


library(tidyverse)


#===============================
#read all the datasets
#==============================

files = c(
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

listings <- map(files, read_csv)

#=============================
#inspect
#============================

# before merging inspect all the datasets

map(listings, glimpse)


# manual inspecting revealed the following

# price - NA values in some files
#last_review - NA values in some files
#reviews_per_month - NA values  in some files        
#license - NA in all files
#price missing from 2 files completely
# same file column names in all files
# at the moment dataset has all of the neighbourhood groups


#==============================================
#filter on christchurch city first before combining
#=================================================

listings_chch <- map(listings, ~filter(.x, neighbourhood_group == "Christchurch City"))


map(listings_chch, glimpse)


# manual inspecting revealed the following


# same file column names in all files
# at the moment dataset has only Christchurch data


#===================================================
# add the month year column
#===================================================

# the new column uses the file name string extracted from the file names and used the notation yyyy-mm under regular expression

listings_chch <- map2(listings_chch, files, ~ mutate(.x, month_year = str_extract(basename(.y), "\\d{4}_\\d{2}") ))

map(listings_chch, glimpse)



#=====================================================
# now that it is filtered and new column is added, merge it
#===========================================================

listings_chch_combined <- bind_rows(listings_chch)


print(dim(listings_chch_combined))

#====================================================
# verify dimensions if everything is rightly merged
#=====================================================

map_int(listings_chch, nrow)
sum(map_int(listings_chch, nrow))
nrow(listings_chch_combined)

print("Verify the combined resultant number of rows is the sum of all rows")
print(sum(map_int(listings_chch, nrow)) == nrow(listings_chch_combined))


#========================================================================================================
# writing back the processed data file but not pushing it onto github and only creating it again if there is no existing file
#=========================================================================================================
output_file <- "data/processed/airbnb_christchurch_combined.csv"

if (!file.exists(output_file)) {
  write_csv(listings_chch_combined, output_file)
}

glimpse(listings_chch_combined)

#^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^

# manual inspecting revealed the following

# price - NA values 
#last_review - NA values 
#reviews_per_month - NA values      
#license - NA in all 
#^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^



#====================================================
#summary statistics
#====================================================

print(summary(listings_chch_combined))


#^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^

# summary statistics mentioned some of the columns here have NA values as well
#^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^



#====================================================
#checking missing values
#====================================================

print("Missing values or NA's")
print(colSums(is.na(listings_chch_combined)))

#^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^

# Output confirms the following:
# Column                  Missing/NA values
# host_name               1
# price                   10667
# minimum_nights          37
# last_review             2627
# reviews_per_month       2627
# license                 28795
#^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^


#====================================================
# inspecting columns with NA
#====================================================


#====================================================
# 1. host_name
#====================================================

print(listings_chch_combined |> filter(is.na(host_name)))


#^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^

#host_name has 1 missing value. The remaining fields for this listing are populated, so the missingness appears isolated to the host-name field. We should not infer or fabricate the host name. Whether to retain the row depends on whether host_name is required for the planned analysis.

#^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^

#====================================================
# 2. prices
#====================================================

print(listings_chch_combined |> group_by(month_year) |> summarise( total_records = n(),
                                                                    missing_price = sum(is.na(price)),
                                                                    non_missing_price = sum(!is.na(price)),
                                                                    missing_percentage = mean(is.na(price)) * 100))


#^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
# December 2025 through February 2026 have zero observed prices. That's fundamentally different from ordinary missing observations.

# It strongly suggests a source/data-collection issue affecting those monthly files, rather than 9,427 individual listings independently failing to provide a price.

# Also notice that October, November, March–June all have roughly 5–8% missingness, while December–February are exactly 100% missing.


# So we can document this as a systematic missingness pattern, not ordinary row-level missing data.

# We should not fill those values, because we don't have evidence for what the prices should be.
#^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^



#====================================================
# 3. minimum_nights
#====================================================

print(
  listings_chch_combined |>
    filter(is.na(minimum_nights)),
  n = Inf,
  width = Inf
)




#^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
#there appear to be two patterns:
  
# 1. January–February: minimum_nights missing alongside the systematic missing price.
# 2. March–June: isolated minimum_nights missingness, while other listing information—including price—is available.
#^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^


#====================================================
# 4. last_review
#====================================================

print(listings_chch_combined |> group_by(month_year) |> summarise( total_records = n(),
                                                                   missing_price = sum(is.na(last_review)),
                                                                   non_missing_price = sum(!is.na(last_review)),
                                                                   missing_percentage = mean(is.na(last_review)) * 100))


#^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^

#^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
