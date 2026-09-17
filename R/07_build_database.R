# ============================================================
# DATA422 - Deliverable 5 (optional extension)
# Store the database-ready tables in SQLite
# ============================================================

library(tidyverse)
library(DBI)

if (!requireNamespace("RSQLite", quietly = TRUE)) {
  stop(
    paste(
      "Package RSQLite is required for this optional step.",
      "Run renv::install('RSQLite'), then run this script again."
    )
  )
}

database_ready_dir <- "data/processed/database_ready"
database_file <- "data/processed/christchurch_rental_market.sqlite"

table_names <- c(
  "dim_geography",
  "fact_airbnb_listing_month",
  "fact_airbnb_sa2_quarter",
  "fact_tenancy_detail",
  "fact_tenancy_sa2_quarter",
  "market_sa2_quarter"
)

table_files <- file.path(database_ready_dir, paste0(table_names, ".csv"))
missing_files <- table_files[!file.exists(table_files)]

if (length(missing_files) > 0) {
  stop(
    paste0(
      "Database-ready file(s) not found:\n- ",
      paste(missing_files, collapse = "\n- "),
      "\nRun R/06_integrate_rental_data.R first."
    )
  )
}

connection <- dbConnect(RSQLite::SQLite(), database_file)
on.exit(dbDisconnect(connection), add = TRUE)

for (index in seq_along(table_names)) {
  table_data <- read_csv(table_files[[index]], show_col_types = FALSE)

  dbWriteTable(
    connection,
    table_names[[index]],
    table_data,
    overwrite = TRUE,
    row.names = FALSE
  )
}

dbExecute(
  connection,
  paste(
    "CREATE INDEX IF NOT EXISTS idx_airbnb_listing_sa2_quarter",
    "ON fact_airbnb_listing_month (sa2_code, comparison_quarter)"
  )
)

dbExecute(
  connection,
  paste(
    "CREATE INDEX IF NOT EXISTS idx_tenancy_detail_sa2_quarter",
    "ON fact_tenancy_detail (sa2_code, comparison_quarter)"
  )
)

dbExecute(
  connection,
  paste(
    "CREATE UNIQUE INDEX IF NOT EXISTS idx_market_sa2_quarter",
    "ON market_sa2_quarter (sa2_code, comparison_quarter)"
  )
)

row_counts <- map_dfr(
  table_names,
  ~ tibble(
    table_name = .x,
    row_count = dbGetQuery(
      connection,
      paste0("SELECT COUNT(*) AS n FROM ", .x)
    )$n
  )
)

write_csv(row_counts, "output/tables/week9_database_row_counts.csv")

print(row_counts)
message("SQLite database created at: ", database_file)
