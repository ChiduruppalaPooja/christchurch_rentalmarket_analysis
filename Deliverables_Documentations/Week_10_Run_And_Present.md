# Deliverable 6: Run and Present

## Before the Lab

Book the tutor slot at least the day before, confirm that Sahil, Pooja and Claudia can attend, and agree who leads this deliverable. Take turns leading as LEARN requires. These steps are not completed by the code.

## Run in RStudio

1. Open `christchurch_rentalmarket_analysis.Rproj` in the repository you share with the team.
2. Use **Session > Restart R** for a fresh session. No saved Global Environment is required.
3. In the **Console**, type this exact command and press Return:

```r
source("R/10_run_week10.R")
```

This runs tests, the corrected integration, SQLite, charts and saved-output checks. It uses the already prepared Airbnb/tenancy files, so it does not need an API key or download data. It overwrites the generated comparison outputs, not raw data.

If those prepared files are missing on a teammate's computer, follow the input setup in the design document and README. Git intentionally does not contain the large datasets or database. Use `renv::restore()` only for first-time package setup or when needed after a lockfile change.

## What to Show, in Order

| Open or run | Explanation |
|---|---|
| `Week_10_Change_Log.md` | Explain what changed and why, especially monthly-row weighting versus equal listing weighting. |
| `Week_10_Design_Principles.md` | Show inputs, outputs, steps, coding practices linked to the lectures and the explicit Codex disclosure. |
| `View(test_results)` | The small, hand-checkable tests include A = $100 repeated three times and B = $300. Correct equal-listing median: $200. |
| `View(fact_airbnb_listing_quarter)` | One row per listing and quarter. Point to `listing_median_nightly_price`, `price_observations` and `geography_status`. |
| `View(geography_review_summary)` | Explain that 36 conflicting listing-quarters are flagged, not silently assigned an area or deleted from the source. |
| `View(median_method_comparison)` | Show the old median, weighting-only median and final median separately. |
| `View(sanity_checks)` | Independent full-table checks pass; these are stronger evidence than saying the script ran without an error. |
| `View(sanity_example)` | For Central, calculate $253 - $537/7 = about $176.29 per night and compare expected versus saved values. |
| `View(row_counts)` | Seven tables are stored in SQLite. The build also verifies that an SQL join matches the R join. |
| `print(price_gap_plot)` | In Plots, click Zoom. Explain equal listing weighting, the selected ten areas and missing-price limitations. |
| `print(rental_count_plot)` | Compare eligible unique listings with active bonds, not a claimed exact long-term property count. |

Do not display `.Renviron` or any API key. Avoid showing raw credentials in Console history or screen-sharing a session that still contains a previously created `api_key` object.

## Brief Speaking Notes

"For Deliverable 6, we reviewed our pipeline against the coding-practices lectures. We made parameters visible, extracted reusable functions, added checks for input structure and join keys, and made database rebuilding safer.

"We also corrected a mismatch between our intention and our code. We wanted each Airbnb listing to contribute equally, but our old median pooled monthly observations. We now calculate one representative price per listing per quarter before calculating the area's median. The original monthly data are still preserved.

"Our sanity checks include a simple example we can calculate by hand and an independent recalculation of the saved results. We also flag uncertain geographic assignments rather than guessing. Codex helped implement and test the work, and our team is responsible for reviewing the design and explaining its limitations."

## Trello Evidence

Attach or link the change log and design document to the Deliverable 6 cards. Record implementation and local validation as completed; keep **team review**, **review of geographic exclusions**, **tutor booking**, **attendance confirmation** and **presentation rehearsal** pending until they actually happen. Do not mark a teammate's review complete on their behalf.
