# Small orchestration helpers; sourcing this file does not run the pipeline.
month_date <- function(month) {
  if (length(month) != 1L || is.na(month) || !grepl("^[0-9]{4}-(0[1-9]|1[0-2])$", month)) {
    stop("Month must use YYYY-MM, for example 2026-08.")
  }
  as.Date(paste0(month, "-01"))
}

monthly_input_paths <- function(start, end, raw_dir) {
  if (end < start) stop("End month precedes start month.")
  file.path(raw_dir, paste0("listings_", format(seq(start, end, by = "month"), "%Y_%m"), ".csv"))
}

validate_source_manifest <- function(manifest) {
  if (!all(c("month", "scrape_date", "url") %in% names(manifest))) stop("Source manifest lacks required columns.")
  if (!nrow(manifest) || anyNA(manifest) || anyDuplicated(manifest$month)) stop("Source manifest has missing or duplicate months.")
  invisible(lapply(manifest$month, month_date))
  dates <- as.Date(manifest$scrape_date, format = "%Y-%m-%d")
  if (anyNA(dates) || any(format(dates, "%Y-%m") != manifest$month)) stop("Scrape date does not match its month.")
  expected <- paste0("https://data.insideairbnb.com/new-zealand/", manifest$scrape_date,
                     "/visualisations/listings.csv")
  if (any(manifest$url != expected)) stop("Only official New Zealand summary listings.csv URLs are allowed.")
  invisible(manifest)
}

validate_download <- function(path) {
  header <- readr::read_csv(path, n_max = 10, col_types = readr::cols(.default = readr::col_character()),
                            show_col_types = FALSE, progress = FALSE)
  required <- c("id", "host_id", "neighbourhood_group", "neighbourhood", "latitude", "longitude", "price", "room_type")
  if (!nrow(header) || !all(required %in% names(header)) || nrow(readr::problems(header))) {
    stop("Download is not a readable summary listings CSV: ", basename(path))
  }
  invisible(TRUE)
}

download_new_months <- function(settings, start, end) {
  manifest <- read.csv(settings$sources_file, colClasses = "character", check.names = FALSE)
  validate_source_manifest(manifest)
  manifest <- manifest[manifest$month >= format(start, "%Y-%m") & manifest$month <= format(end, "%Y-%m"), ]
  dir.create(settings$raw_dir, recursive = TRUE, showWarnings = FALSE)
  receipts <- list()
  for (i in seq_len(nrow(manifest))) {
    row <- manifest[i, ]
    destination <- file.path(settings$raw_dir, paste0("listings_", gsub("-", "_", row$month), ".csv"))
    receipt_path <- paste0(destination, ".source.rds")
    action <- "local_file"
    if (!file.exists(destination)) {
      temporary <- tempfile("download-", tmpdir = settings$raw_dir, fileext = ".csv")
      old_timeout <- getOption("timeout")
      options(timeout = max(180, old_timeout))
      tryCatch({
        status <- utils::download.file(row$url, temporary, method = "libcurl", mode = "wb", quiet = TRUE)
        if (status != 0L) stop("Download failed for ", row$month)
        validate_download(temporary)
        if (!file.rename(temporary, destination)) stop("Could not move validated download into data/raw.")
      }, finally = {
        options(timeout = old_timeout)
        if (file.exists(temporary)) unlink(temporary)
      })
      action <- "downloaded_official"
      saveRDS(list(url = row$url, md5 = unname(tools::md5sum(destination)),
                   downloaded_at = format(Sys.time(), tz = "UTC", usetz = TRUE)), receipt_path)
    }
    validate_download(destination)
    md5 <- unname(tools::md5sum(destination))
    receipt <- if (file.exists(receipt_path)) readRDS(receipt_path) else NULL
    verified <- !is.null(receipt) && identical(receipt$url, row$url) && identical(receipt$md5, md5)
    receipts[[length(receipts) + 1L]] <- data.frame(
      month = row$month, scrape_date = row$scrape_date, source_url = row$url,
      local_file = destination, md5 = md5, action = action,
      provenance = if (verified) "official_download_checksum_verified" else "pre_existing_local_file_not_download_verified"
    )
    message("Input ", row$month, ": ", action)
  }
  do.call(rbind, receipts)
}

file_fingerprints <- function(paths) {
  paths <- sort(unique(paths))
  if (!length(paths) || !all(file.exists(paths))) stop("Required pipeline file is missing: ", paste(paths[!file.exists(paths)], collapse = ", "))
  stats::setNames(unname(tools::md5sum(paths)), paths)
}

stage_is_current <- function(state, signature, outputs) {
  !is.null(state) && identical(state$signature, signature) && all(file.exists(outputs)) &&
    identical(state$outputs, file_fingerprints(outputs))
}

run_cached_stage <- function(name, inputs, outputs, scripts, config, state_dir, env, force = FALSE) {
  dir.create(state_dir, recursive = TRUE, showWarnings = FALSE)
  state_file <- file.path(state_dir, paste0(name, ".rds"))
  dependencies <- unique(c(scripts, "R/pipeline_config.R", "R/helpers/integration_helpers.R",
                           "R/helpers/automation_helpers.R", "run_pipeline.R", "renv.lock"))
  signature <- function() list(inputs = file_fingerprints(inputs), code = file_fingerprints(dependencies), config = config,
                               packages = vapply(c("dplyr", "readr", "ggplot2", "DBI", "RSQLite"),
                                                 function(p) as.character(utils::packageVersion(p)), character(1)))
  current_signature <- signature()
  state <- if (file.exists(state_file)) tryCatch(readRDS(state_file), error = function(e) NULL) else NULL
  began <- Sys.time()
  if (!force && stage_is_current(state, current_signature, outputs)) {
    status <- "reused"
    message("REUSE ", name, " (inputs, code, settings and saved outputs unchanged)")
  } else {
    message("RUN   ", name)
    for (script in scripts) source(script, local = env)
    if (!all(file.exists(outputs))) stop("Stage did not create all expected outputs: ", name)
    # Capture post-run cache fingerprints because geography adds successful lookups.
    saveRDS(list(signature = signature(), outputs = file_fingerprints(outputs)), state_file)
    status <- "ran"
  }
  data.frame(stage = name, status = status, seconds = round(as.numeric(difftime(Sys.time(), began, units = "secs")), 2))
}
