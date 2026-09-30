# Deliverable 7: one command from the project root: Rscript run_pipeline.R
# In RStudio: source("run_pipeline.R"); results <- run_pipeline()
source("R/helpers/automation_helpers.R")

run_pipeline <- function(end_month = NULL, force = FALSE) {
  if (!file.exists("christchurch_rentalmarket_analysis.Rproj")) stop("Run from the project root (the folder containing the .Rproj file).")
  settings_env <- new.env(parent = baseenv())
  sys.source("config/automation.R", envir = settings_env)
  settings <- settings_env$automation_settings
  if (!is.null(end_month)) settings$end_month <- end_month
  start <- month_date(settings$start_month)
  end <- month_date(settings$end_month)
  inputs <- monthly_input_paths(start, end, settings$raw_dir)
  required_packages <- c("tidyverse", "jsonlite", "DBI", "RSQLite")
  missing <- required_packages[!vapply(required_packages, requireNamespace, logical(1), quietly = TRUE)]
  if (length(missing)) stop("Run renv::restore() before the pipeline. Missing packages: ", paste(missing, collapse = ", "))
  if (nzchar(Sys.getenv("AIRBNB_INPUT"))) stop("Unset AIRBNB_INPUT before the automated run; configuration chooses its input explicitly.")

  period <- paste(settings$start_month, settings$end_month, sep = "_to_")
  processed <- file.path(settings$processed_dir, period)
  output <- file.path(settings$output_dir, period)
  summary_dir <- file.path(output, "tables")
  figure_dir <- file.path(output, "figures")
  dir.create(processed, recursive = TRUE, showWarnings = FALSE)
  dir.create(summary_dir, recursive = TRUE, showWarnings = FALSE)
  dir.create(figure_dir, recursive = TRUE, showWarnings = FALSE)
  dir.create(file.path(output, "logs"), recursive = TRUE, showWarnings = FALSE)
  log_path <- file.path(output, "logs", paste0(format(Sys.time(), "%Y%m%d_%H%M%S"), ".log"))
  log_connection <- file(log_path, open = "wt")
  sink(log_connection, split = TRUE)
  sink(log_connection, type = "message")
  on.exit({sink(type = "message"); sink(); close(log_connection)}, add = TRUE)
  message("Pipeline started: ", format(Sys.time()), " | period ", period)
  saveRDS(list(status = "RUNNING", started = Sys.time()), file.path(output, "run_status.rds"))
  completed <- FALSE
  on.exit({if (!completed) saveRDS(list(status = "FAILED", log = log_path), file.path(output, "run_status.rds"))}, add = TRUE)

  downloads <- download_new_months(settings, start, end)
  if (!is.null(downloads)) readr::write_csv(downloads, file.path(summary_dir, "week11_download_receipts.csv"))
  file_fingerprints(c(inputs, settings$tenancy_raw))
  if (anyDuplicated(unname(tools::md5sum(inputs)))) stop("Two monthly inputs are byte-identical. Confirm the months before proceeding.")

  overrides <- list(study_start = start, study_end = end, raw_dir = settings$raw_dir,
    cleaned_airbnb = file.path(processed, "airbnb_clean.csv"),
    airbnb_input = file.path(processed, "airbnb_with_sa2.csv"),
    tenancy_raw = settings$tenancy_raw, tenancy_full = file.path(processed, "tenancy_full.csv"),
    tenancy_input = file.path(processed, "tenancy_study.csv"),
    geography_cache = settings$geography_cache,
    table_dir = file.path(processed, "database_ready"), quality_dir = file.path(processed, "quality"),
    summary_dir = summary_dir, figure_dir = figure_dir,
    database_file = file.path(processed, "christchurch_rental_market.sqlite"))
  old_options <- options(rental.pipeline.overrides = overrides)
  on.exit(options(old_options), add = TRUE)
  env <- new.env(parent = globalenv())
  source("R/pipeline_config.R", local = env)
  config <- env$pipeline_config
  state_dir <- file.path(processed, "stage_state")
  stages <- list()
  stage <- function(name, inputs, outputs, scripts, force_run = FALSE) {
    result <- run_cached_stage(name, inputs, outputs, scripts, config, state_dir, env, force || force_run)
    stages[[length(stages) + 1L]] <<- result
    readr::write_csv(do.call(rbind, stages), file.path(summary_dir, "week11_stage_log.csv"))
  }

  # Reuse the existing team scripts in dependency order.
  stage("01_airbnb_cleaning", inputs, config$cleaned_airbnb, "R/02_airbnb_combine.R")
  stage("02_tenancy_cleaning", config$tenancy_raw, c(config$tenancy_full, config$tenancy_input), "R/03_tenancy_prepare.R")
  stage("03_summaries", config$cleaned_airbnb,
        file.path(summary_dir, paste0("airbnb_", c("missing_values", "numeric_summary", "categorical_summary", "room_type_summary", "neighbourhood_summary", "snapshot_summary"), ".csv")),
        "R/04_airbnb_summary.R")
  # File 05 can start from an empty cache; once created the cache is also checked.
  stage("04_geography", c(config$cleaned_airbnb, if (file.exists(config$geography_cache)) config$geography_cache),
        c(config$airbnb_input, config$geography_cache, file.path(summary_dir, c("week9_api_match_summary.csv", "week9_unmatched_coordinates.csv"))),
        "R/05_query_geography.R")
  stage("05_integration", c(config$airbnb_input, config$tenancy_input),
        c(file.path(config$table_dir, paste0(config$database_tables, ".csv")),
          file.path(summary_dir, c("week9_largest_price_gaps.csv", "week9_property_count_comparison.csv", "week10_method_metadata.csv",
            "week9_christchurch_central_median.csv", "week9_airbnb_price_coverage_by_month.csv", "week9_unmatched_airbnb_keys.csv", "week9_join_quality.csv",
            "week9_airbnb_price_coverage_by_quarter.csv", "week9_unmatched_tenancy_keys.csv", "week10_geography_review_summary.csv", "week10_median_method_comparison.csv")),
          file.path(config$quality_dir, c("listing_quarter_geography_review.csv", "central_listing_prices.csv"))),
        "R/06_integrate_rental_data.R")
  stage("06_database", file.path(config$table_dir, paste0(config$database_tables, ".csv")),
        c(config$database_file, file.path(summary_dir, "week9_database_row_counts.csv")), "R/07_build_database.R", force_run = TRUE)

  # Historical comparison charts use the latest genuinely matched quarter.
  market <- readr::read_csv(file.path(config$table_dir, "market_sa2_quarter.csv"), show_col_types = FALSE)
  if (!nrow(market)) stop("No area-quarter comparisons are available; check tenancy coverage and geography.")
  overrides$chart_quarter <- max(as.Date(market$comparison_quarter))
  options(rental.pipeline.overrides = overrides)
  source("R/pipeline_config.R", local = env)
  config <- env$pipeline_config
  quarter_slug <- paste0(format(config$chart_quarter, "%Y"), "q", (as.integer(format(config$chart_quarter, "%m")) - 1L) %/% 3L + 1L)
  stage("07_plots", c(config$cleaned_airbnb, file.path(config$table_dir, "market_sa2_quarter.csv"),
                      file.path(summary_dir, c("week9_largest_price_gaps.csv", "week9_property_count_comparison.csv", "week9_api_match_summary.csv", "week10_method_metadata.csv"))),
        c(file.path(figure_dir, as.vector(outer(c("week9_price_gaps_top10", paste0("week9_airbnb_vs_active_bonds_", quarter_slug), "week11_monthly_prices", "week11_monthly_listing_counts", "week11_new_month_price_distribution"), c(".png", ".pdf"), paste0))),
          file.path(summary_dir, c("week11_monthly_summary.csv", "week11_histogram_display_coverage.csv", "week9_plot_price_gaps_top10.csv", paste0("week9_plot_counts_top10_", quarter_slug, ".csv")))),
        c("R/08_week9_plots.R", "R/11_monthly_update_plots.R"))

  # Tests run every time, even when expensive transformation stages are reused.
  source("tests/test_automation.R", local = env)
  readr::write_csv(env$automation_test_results, file.path(summary_dir, "week11_automation_tests.csv"))
  source("tests/test_integration.R", local = env)
  readr::write_csv(env$test_results, file.path(summary_dir, "week10_fixture_tests.csv"))
  source("tests/test_database_transaction.R", local = env)
  source("R/09_validate_pipeline.R", local = env)
  source("R/12_automation_report.R", local = env)
  completed <- TRUE
  saveRDS(list(status = "SUCCESS", finished = Sys.time(), period = period, log = log_path), file.path(output, "run_status.rds"))
  cat("\nSUCCESS: updated outputs are in ", output, "\n", sep = "")
  invisible(list(output_dir = output, processed_dir = processed,
    monthly_summary = env$automation_monthly_summary, coverage = env$automation_coverage,
    stage_log = do.call(rbind, stages), sanity_checks = env$sanity_checks, sanity_example = env$sanity_example))
}

if (sys.nframe() == 0L) {
  arguments <- commandArgs(trailingOnly = TRUE)
  if ("--help" %in% arguments) {
    cat("Usage: Rscript run_pipeline.R [--end-month=YYYY-MM] [--force]\n")
  } else {
    unknown <- arguments[!grepl("^--end-month=", arguments) & arguments != "--force"]
    if (length(unknown)) stop("Unknown argument: ", paste(unknown, collapse = ", "))
    end_arg <- arguments[grepl("^--end-month=", arguments)]
    if (length(end_arg) > 1L) stop("Provide --end-month only once.")
    run_pipeline(if (length(end_arg)) sub("^--end-month=", "", end_arg) else NULL, force = "--force" %in% arguments)
  }
}
