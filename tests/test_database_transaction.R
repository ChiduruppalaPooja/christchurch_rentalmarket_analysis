# Run after file 07. Only temporary copies are deliberately damaged.
test_database_transaction <- function(config) {
  if (!exists("build_rental_database", mode = "function")) stop("Run file 07 before the database safety tests.")
  directory <- tempfile("rental-sqlite-tests-")
  dir.create(directory)
  on.exit(unlink(directory, recursive = TRUE), add = TRUE)
  test_config <- config
  test_config$table_dir <- file.path(directory, "tables")
  test_config$summary_dir <- directory
  test_config$database_file <- file.path(directory, "test.sqlite")
  dir.create(test_config$table_dir)
  inputs <- file.path(config$table_dir, paste0(config$database_tables, ".csv"))
  stopifnot(all(file.copy(inputs, test_config$table_dir)))
  build_rental_database(test_config)
  query_test_database <- function(sql) {
    db <- DBI::dbConnect(RSQLite::SQLite(), test_config$database_file)
    on.exit(DBI::dbDisconnect(db), add = TRUE)
    DBI::dbGetQuery(db, sql)
  }
  before <- query_test_database("SELECT * FROM market_sa2_quarter ORDER BY sa2_code, comparison_quarter")
  types <- query_test_database("SELECT typeof(id) AS id_type, typeof(sa2_code) AS area_type FROM fact_airbnb_listing_month LIMIT 1")
  stopifnot(types$id_type == "text", types$area_type == "text")

  path <- file.path(test_config$table_dir, "market_sa2_quarter.csv")
  broken <- readr::read_csv(path, show_col_types = FALSE)
  broken$nightly_price_gap[1] <- broken$nightly_price_gap[1] + 1
  readr::write_csv(broken, path)
  failure <- tryCatch({build_rental_database(test_config); "NO_ERROR"}, error = function(e) conditionMessage(e))
  stopifnot(grepl("SQL join differs", failure, fixed = TRUE))
  after <- query_test_database("SELECT * FROM market_sa2_quarter ORDER BY sa2_code, comparison_quarter")
  stopifnot(identical(before, after))

  test_config$table_dir <- file.path(directory, "missing-inputs")
  missing_failure <- tryCatch({build_rental_database(test_config); "NO_ERROR"}, error = function(e) conditionMessage(e))
  stopifnot(grepl("Missing database-ready", missing_failure, fixed = TRUE))
  stopifnot(identical(before, query_test_database("SELECT * FROM market_sa2_quarter ORDER BY sa2_code, comparison_quarter")))
  tibble::tibble(
    check = c("SQLite identifiers stored as text", "Incorrect SQL/R result rejected",
              "Failed rebuild rolls back to previous tables", "Missing input leaves database unchanged"),
    status = "PASS"
  )
}

database_test_results <- test_database_transaction(pipeline_config)
readr::write_csv(database_test_results, file.path(pipeline_config$summary_dir, "week10_database_tests.csv"))
print(database_test_results)
