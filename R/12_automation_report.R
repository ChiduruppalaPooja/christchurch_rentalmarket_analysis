# Read saved results only: reporting does not duplicate the cleaning pipeline.
library(tidyverse)
source("R/pipeline_config.R", local = TRUE)
automation_monthly_summary <- read_csv(file.path(pipeline_config$summary_dir, "week11_monthly_summary.csv"), show_col_types = FALSE)
tenancy_quarters <- read_csv(file.path(pipeline_config$table_dir, "fact_tenancy_sa2_quarter.csv"), show_col_types = FALSE)
airbnb_quarters <- read_csv(file.path(pipeline_config$table_dir, "fact_airbnb_sa2_quarter.csv"), show_col_types = FALSE)
automation_coverage <- automation_monthly_summary |>
  mutate(comparison_quarter = quarter_start(snapshot_date),
    tenancy_quarter_available = comparison_quarter %in% tenancy_quarters$comparison_quarter,
    interpretation = if_else(tenancy_quarter_available, "Area matches checked separately", "Airbnb-only: no matching tenancy quarter"))
write_csv(automation_coverage, file.path(pipeline_config$summary_dir, "week11_month_coverage.csv"))
if (nrow(automation_monthly_summary) != length(seq(pipeline_config$study_start, pipeline_config$study_end, by = "month"))) {
  stop("Monthly report does not contain every configured month.")
}
if (any(automation_monthly_summary$listings != automation_monthly_summary$priced_listings + automation_monthly_summary$missing_prices)) {
  stop("Monthly coverage counts do not reconcile.")
}
quarter_coverage <- automation_coverage |> group_by(comparison_quarter) |>
  summarise(airbnb_months = n(), full_three_months = n() == 3L,
    tenancy_available = all(tenancy_quarter_available), .groups = "drop")
write_csv(quarter_coverage, file.path(pipeline_config$summary_dir, "week11_quarter_coverage.csv"))
missing_rent <- automation_coverage |> filter(!tenancy_quarter_available)
table_lines <- c("| Month | Listings | Priced | Missing price | Median NZ$/night | Tenancy quarter available |",
                 "|---|---:|---:|---:|---:|---|")
for (i in seq_len(nrow(automation_coverage))) {
  x <- automation_coverage[i, ]
  table_lines <- c(table_lines, sprintf("| %s | %s | %s | %s | %s | %s |", format(x$snapshot_date, "%Y-%m"),
    x$listings, x$priced_listings, x$missing_prices,
    ifelse(is.na(x$median_nightly_price), "NA", sprintf("%.2f", x$median_nightly_price)), x$tenancy_quarter_available))
}
report <- c("# Deliverable 7: Automated Monthly Update", "", paste("Generated:", format(Sys.time(), tz = "UTC", usetz = TRUE)), "",
  "## What this run includes", "", paste("Period:", format(pipeline_config$study_start, "%B %Y"), "to", format(pipeline_config$study_end, "%B %Y")),
  "The existing team cleaning, SA2 2019 lookup, equal-listing aggregation and SQLite workflow are orchestrated by one root command.", "",
  "## Monthly evidence", "", table_lines, "", "## Coverage limitations", "",
  paste("Months without corresponding tenancy data:", if(nrow(missing_rent)) paste(format(missing_rent$snapshot_date, "%B %Y"), collapse = ", ") else "none"),
  "No older tenancy rent is relabelled as a newer quarter. The inner join excludes unmatched area-quarter keys and saves them for inspection.",
  "July-August represent two months of Q3, not a full July-September quarter. Do not present the new listing counts as a complete Q3 total.",
  "The monthly price plot describes each month's observed listings. Quarterly market medians still use one representative price per listing.",
  "Missing prices remain NA. Extreme prices are retained pending the team's existing review; the histogram view limit is not a cleaning threshold.", "",
  "## Validation", "", "Inspect tables/week11_automation_tests.csv, week10_fixture_tests.csv, week10_database_tests.csv and week10_sanity_checks.csv from this same run.",
  "Inspect tables/week11_stage_log.csv to see which stages ran or reused unchanged outputs.", "",
  "## Sources", "", "Inside Airbnb: https://insideairbnb.com/get-the-data/",
  "Exact new-month URLs and checksums: tables/week11_download_receipts.csv.",
  "Tenancy: the team's local raw source, with actual coverage measured from TimeFrame rather than inferred from its filename.",
  "Geography: Stats NZ SA2 2019, Koordinates layer 98970.")
writeLines(report, file.path(dirname(pipeline_config$summary_dir), "RUN_SUMMARY.md"))
print(automation_coverage)
