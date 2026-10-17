# Final submission checks

Checked on 17 October 2026, using the final repository layout from main commit `cf0a2dc` and the staging corrections described below. This record concerns the implemented R pipeline and repository links; it is not a claim that every source observation is correct.

## Corrections

- Script `R/01_airbnb_prepare.R` now reads the June dataset before checking its column names. The corrected script was executed successfully in a fresh R process.
- `data/raw/listings.csv` and `data/processed/airbnb_christchurch_2026_06_clean.csv` were removed from Git tracking while retaining local copies. Raw inputs and generated R data remain covered by `.gitignore`.
- `output/tables/airbnb_numeric_summary.csv` was regenerated from its original October 2025-June 2026 inputs. Identifier fields `id` and `host_id` no longer appear as numeric measurements. It retains nine-month coverage; the separate automated summary covers eleven months.
- References to the removed documentation layout were replaced with the current `Docs/project/` and `Docs/deliverables/` paths. Setup instructions now explain the optional June file and the `AIRBNB_INPUT` restriction.

## Verification

| Check | Result |
|---|---|
| Fresh R execution of script 01 | Passed |
| Full `Rscript run_pipeline.R` | Passed |
| Repeat pipeline execution | Passed; unchanged stages reused and database rebuilt |
| Automation tests | 23 passed |
| Integration fixture tests | 22 passed |
| Database safety tests | 4 passed |
| Independent saved-output checks in the pipeline | 11 passed |
| Additional calculations from the source inputs | 13 passed |
| R syntax | All 23 source, configuration and test files parsed |
| Local Markdown links and heading anchors | Checked with no broken destinations |
| Raw/processed files in the proposed Git index | None; removed datasets still existed locally |

The additional calculations independently checked monthly counts and medians against raw Christchurch records, listing-quarter weighting, geographic exclusions, join keys, price-gap arithmetic, and the seven SQLite tables. The regenerated legacy numeric summary also retained the original nine-month price coverage.

## Reproduction and limits

Use [the automation guide](automation_guide.md) and [the local data guide](../../data/README.md) to set up the required inputs. Tests used R 4.5.2, the existing local package library, copied original datasets and the saved SA2 2019 lookup cache. The principal package versions were checked against `renv.lock` during the preceding main-branch audit; a fresh package installation on a different computer was not part of this check.

The July/August official-download path was also tested successfully during that audit; the download code was unchanged by these corrections. No new live Koordinates request was needed because the cache covered the input coordinates.

The tenancy source contains no Q3 2026 records, so its coverage warning is expected. The new Airbnb months appear in monthly results without inventing a matching tenancy comparison. Missing prices remain missing, and advertised Airbnb prices and tenancy bond rents describe different markets.

The historical KNIME archive still contains saved node tables. It was preserved as team deliverable evidence in this correction. The team should check whether a data-free export is needed before final submission. This is separate from the R pipeline input files removed from tracking.
