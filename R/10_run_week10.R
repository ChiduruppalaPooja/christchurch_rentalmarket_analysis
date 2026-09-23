# Rebuild Deliverable 6 from already prepared inputs; no network or API call.
# Open christchurch_rentalmarket_analysis.Rproj, then source this file.
if (!file.exists("christchurch_rentalmarket_analysis.Rproj")) {
  stop("Open the project .Rproj file first. Do not change directories inside scripts.")
}
source("tests/test_integration.R")
dir.create("output/tables", recursive = TRUE, showWarnings = FALSE)
readr::write_csv(test_results, "output/tables/week10_fixture_tests.csv")
source("R/06_integrate_rental_data.R")
source("R/07_build_database.R")
source("tests/test_database_transaction.R")
source("R/08_week9_plots.R")
source("R/09_validate_pipeline.R")
message("Deliverable 6 rebuilt. Inspect test_results, sanity_checks, sanity_example, and the two plots.")
