# Deliverable 7: Automated Monthly Update

Generated: 2026-09-30 16:55:55 UTC

## What this run includes

Period: October 2025 to August 2026
The existing team cleaning, SA2 2019 lookup, equal-listing aggregation and SQLite workflow are orchestrated by one root command.

## Monthly evidence

| Month | Listings | Priced | Missing price | Median NZ$/night | Tenancy quarter available |
|---|---:|---:|---:|---:|---|
| 2025-10 | 2991 | 2821 | 170 | 155.00 | TRUE |
| 2025-11 | 3047 | 2835 | 212 | 166.00 | TRUE |
| 2025-12 | 3180 | 0 | 3180 | NA | TRUE |
| 2026-01 | 3057 | 0 | 3057 | NA | TRUE |
| 2026-02 | 3190 | 0 | 3190 | NA | TRUE |
| 2026-03 | 3227 | 3059 | 168 | 237.00 | TRUE |
| 2026-04 | 3273 | 3069 | 204 | 229.00 | TRUE |
| 2026-05 | 3361 | 3149 | 212 | 215.00 | TRUE |
| 2026-06 | 3469 | 3195 | 274 | 214.00 | TRUE |
| 2026-07 | 3488 | 3173 | 315 | 227.00 | FALSE |
| 2026-08 | 3513 | 3177 | 336 | 224.00 | FALSE |

## Coverage limitations

Months without corresponding tenancy data: July 2026, August 2026
No older tenancy rent is relabelled as a newer quarter. The inner join excludes unmatched area-quarter keys and saves them for inspection.
July-August represent two months of Q3, not a full July-September quarter. Do not present the new listing counts as a complete Q3 total.
The monthly price plot describes each month's observed listings. Quarterly market medians still use one representative price per listing.
Missing prices remain NA. Extreme prices are retained pending the team's existing review; the histogram view limit is not a cleaning threshold.

## Validation

Inspect tables/week11_automation_tests.csv, week10_fixture_tests.csv, week10_database_tests.csv and week10_sanity_checks.csv from this same run.
Inspect tables/week11_stage_log.csv to see which stages ran or reused unchanged outputs.

## Sources

Inside Airbnb: https://insideairbnb.com/get-the-data/
Exact new-month URLs and checksums: tables/week11_download_receipts.csv.
Tenancy: the team's local raw source, with actual coverage measured from TimeFrame rather than inferred from its filename.
Geography: Stats NZ SA2 2019, Koordinates layer 98970.
