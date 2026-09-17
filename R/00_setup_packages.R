# ============================================================
# DATA422 - One-time package setup
# Run this after cloning or when the renv lockfile is updated.
# ============================================================

required_packages <- c(
  "tidyverse",
  "jsonlite",
  "DBI",
  "RSQLite"
)

renv::restore(prompt = FALSE)

missing_packages <- required_packages[
  !vapply(required_packages, requireNamespace, logical(1), quietly = TRUE)
]

if (length(missing_packages) > 0) {
  stop(
    "Package restore did not install: ",
    paste(missing_packages, collapse = ", ")
  )
}

message("Package restore complete. The project matches renv.lock.")
