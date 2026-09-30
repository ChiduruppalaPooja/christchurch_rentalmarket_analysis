# Inputs: the seven saved database-ready CSV tables from file 06.
# Output: a transactional SQLite database and its table row-count summary.
library(tidyverse)
library(DBI)
source("R/pipeline_config.R", local = TRUE)
source("R/helpers/integration_helpers.R")

build_rental_database <- function(config) {
  if (!requireNamespace("RSQLite", quietly = TRUE)) {
    stop("RSQLite is required. Run renv::restore() before building the database.")
  }
  files <- file.path(config$table_dir, paste0(config$database_tables, ".csv"))
  if (!all(file.exists(files))) stop("Missing database-ready files. Run file 06 first.")

  tables <- setNames(lapply(files, function(path) {
    columns <- names(read_csv(path, n_max = 0, show_col_types = FALSE))
    text_columns <- intersect(c("id", "host_id", "sa2_code", "snapshot_date", "comparison_quarter"), columns)
    column_types <- do.call(cols, setNames(rep(list(col_character()), length(text_columns)), text_columns))
    data <- read_csv(path, col_types = column_types, show_col_types = FALSE)
    if (nrow(problems(data))) stop("CSV parsing problem in ", path)
    data
  }), config$database_tables)

  assert_unique_keys(tables$fact_airbnb_listing_quarter, c("id", "comparison_quarter"), "SQLite listing-quarter input")
  assert_unique_keys(tables$market_sa2_quarter, c("sa2_code", "comparison_quarter"), "SQLite market input")
  connection <- dbConnect(RSQLite::SQLite(), config$database_file)
  on.exit(dbDisconnect(connection), add = TRUE)

  # Failure rolls back the whole rebuild rather than leaving a partial database.
  result <- dbWithTransaction(connection, {
    purrr::iwalk(tables, ~ dbWriteTable(connection, .y, .x, overwrite = TRUE, row.names = FALSE))
    dbExecute(connection, "CREATE UNIQUE INDEX idx_listing_month ON fact_airbnb_listing_month (id, snapshot_date)")
    dbExecute(connection, "CREATE UNIQUE INDEX idx_listing_quarter ON fact_airbnb_listing_quarter (id, comparison_quarter)")
    dbExecute(connection, "CREATE UNIQUE INDEX idx_airbnb_quarter ON fact_airbnb_sa2_quarter (sa2_code, comparison_quarter)")
    dbExecute(connection, "CREATE UNIQUE INDEX idx_tenancy_quarter ON fact_tenancy_sa2_quarter (sa2_code, comparison_quarter)")
    dbExecute(connection, "CREATE UNIQUE INDEX idx_market_quarter ON market_sa2_quarter (sa2_code, comparison_quarter)")

    sql_join <- dbGetQuery(connection, paste(
      "SELECT a.sa2_code, a.comparison_quarter,",
      "a.median_airbnb_nightly_price - t.median_weekly_rent / 7.0 AS nightly_price_gap",
      "FROM fact_airbnb_sa2_quarter AS a INNER JOIN fact_tenancy_sa2_quarter AS t",
      "ON a.sa2_code = t.sa2_code AND a.comparison_quarter = t.comparison_quarter",
      "ORDER BY a.sa2_code, a.comparison_quarter"
    ))
    expected <- tables$market_sa2_quarter |>
      select(sa2_code, comparison_quarter, nightly_price_gap) |>
      arrange(sa2_code, comparison_quarter)
    if (!isTRUE(all.equal(as.data.frame(expected), sql_join, check.attributes = FALSE, tolerance = 1e-8))) {
      stop("SQL join differs from the saved R join. Database rebuild rolled back.")
    }
    if (!identical(dbGetQuery(connection, "PRAGMA integrity_check")[[1]], "ok")) stop("SQLite integrity check failed.")

    map_dfr(config$database_tables, function(name) {
      tibble(table_name = name,
             row_count = dbGetQuery(connection, paste("SELECT COUNT(*) AS n FROM", dbQuoteIdentifier(connection, name)))$n)
    })
  })
  write_csv(result, file.path(config$summary_dir, "week9_database_row_counts.csv"))
  message("SQLite built; SQL join agrees with R. Connection closed automatically on return.")
  result
}

row_counts <- build_rental_database(pipeline_config)
print(row_counts)
