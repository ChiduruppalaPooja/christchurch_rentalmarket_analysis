# ============================================================
# DATA422 - Deliverable 5
# Add Stats NZ SA2 2019 codes to the cleaned Airbnb data
# ============================================================

library(tidyverse)
library(jsonlite)
source("R/pipeline_config.R")
source("R/helpers/integration_helpers.R")

# Tenancy Services documents that the bond data use SA2-2019 definitions.
koordinates_layer_id <- pipeline_config$sa2_layer
koordinates_url <- paste0(
  "https://datafinder.stats.govt.nz/services/query/v1/vector.json"
)

airbnb_candidates <- c(
  "data/processed/airbnb_christchurch_combined.csv",
  "data/processed/airbnb_christchurch_oct2025_jun2026_clean.csv"
)

airbnb_input <- Sys.getenv("AIRBNB_INPUT")

if (airbnb_input == "") {
  available_airbnb_inputs <-
    airbnb_candidates[file.exists(airbnb_candidates)]

  airbnb_input <- if (length(available_airbnb_inputs) > 0) {
    available_airbnb_inputs[[1]]
  } else {
    airbnb_candidates[[1]]
  }
}

airbnb_output <- "data/processed/airbnb_christchurch_with_sa2.csv"

lookup_cache <-
  "data/processed/airbnb_sa2_2019_lookup_cache.csv"

match_summary_output <-
  "output/tables/week9_api_match_summary.csv"

unmatched_output <-
  "output/tables/week9_unmatched_coordinates.csv"

if (!file.exists(airbnb_input)) {
  stop(
    paste0(
      "Airbnb input not found: ", airbnb_input, "\n",
      "Place the finalized combined Airbnb file in data/processed, ",
      "or set AIRBNB_INPUT to an alternative cleaned file."
    )
  )
}

dir.create("data/processed", recursive = TRUE, showWarnings = FALSE)
dir.create("output/tables", recursive = TRUE, showWarnings = FALSE)

airbnb <- read_csv(
  airbnb_input,
  col_types = cols(
    id = col_character(),
    host_id = col_character()
  ),
  show_col_types = FALSE
)

required_columns <- c("latitude", "longitude")
missing_columns <- setdiff(required_columns, names(airbnb))

if (length(missing_columns) > 0) {
  stop(
    "Airbnb input is missing: ",
    paste(missing_columns, collapse = ", ")
  )
}
if (nrow(problems(airbnb))) stop("Airbnb input has CSV parsing problems.")
if (any(!is.na(airbnb$latitude) & (!is.finite(airbnb$latitude) | abs(airbnb$latitude) > 90)) ||
    any(!is.na(airbnb$longitude) & (!is.finite(airbnb$longitude) | abs(airbnb$longitude) > 180))) {
  stop("Airbnb coordinates contain invalid latitude/longitude values.")
}

# The API is queried once per unique coordinate rather than once per row.
# Repeated listing locations across monthly snapshots therefore reuse a result.
coordinates <- airbnb |>
  filter(!is.na(latitude), !is.na(longitude)) |>
  transmute(
    latitude = as.numeric(latitude),
    longitude = as.numeric(longitude),
    coordinate_key = sprintf("%.6f|%.6f", latitude, longitude)
  ) |>
  distinct(coordinate_key, .keep_all = TRUE)

if (nrow(coordinates) == 0) {
  stop("No valid latitude/longitude pairs were found in the Airbnb input.")
}

empty_cache <- tibble(
  coordinate_key = character(),
  latitude = double(),
  longitude = double(),
  sa2_code = character(),
  sa2_name = character(),
  api_status = character()
)

cache <- if (file.exists(lookup_cache)) {
  read_csv(
    lookup_cache,
    col_types = cols(
      coordinate_key = col_character(),
      latitude = col_double(),
      longitude = col_double(),
      sa2_code = col_character(),
      sa2_name = col_character(),
      api_status = col_character()
    ),
    show_col_types = FALSE
  ) |>
    # Failed requests are deliberately retried on the next run.
    filter(api_status != "request_failed_after_3_attempts")
} else {
  empty_cache
}

coordinates_to_query <- coordinates |>
  anti_join(cache, by = "coordinate_key")
assert_unique_keys(cache, "coordinate_key", "SA2 cache")

if (nrow(coordinates_to_query) > 0 && Sys.getenv("KOORDINATES_API_KEY") == "") {
  stop("Uncached coordinates need KOORDINATES_API_KEY in your local .Renviron. Restart RStudio after setting it.")
}

query_one_coordinate <- function(coordinate_key, latitude, longitude) {
  # Keep the credential out of Global Environment and routine warning messages.
  api_key <- Sys.getenv("KOORDINATES_API_KEY")
  query_url <- paste0(
    koordinates_url,
    "?key=", utils::URLencode(api_key, reserved = TRUE),
    "&layer=", koordinates_layer_id,
    "&x=", format(longitude, scientific = FALSE, trim = TRUE),
    "&y=", format(latitude, scientific = FALSE, trim = TRUE),
    "&max_results=1",
    "&radius=0",
    "&geometry=false",
    "&with_field_names=true"
  )

  for (attempt in seq_len(3)) {
    result <- tryCatch(
      {
        response <- suppressWarnings(jsonlite::fromJSON(
          query_url,
          simplifyVector = FALSE
        ))

        features <- response$vectorQuery$layers[[koordinates_layer_id]]$features

        if (length(features) == 0) {
          tibble(
            coordinate_key = coordinate_key,
            latitude = latitude,
            longitude = longitude,
            sa2_code = NA_character_,
            sa2_name = NA_character_,
            api_status = "no_polygon_match"
          )
        } else {
          properties <- features[[1]]$properties

          tibble(
            coordinate_key = coordinate_key,
            latitude = latitude,
            longitude = longitude,
            sa2_code = as.character(properties$SA22019_V1_00),
            sa2_name = as.character(properties$SA22019_V1_00_NAME),
            api_status = "matched"
          )
        }
      },
      error = function(error) NULL
    )

    if (!is.null(result)) {
      return(result)
    }

    Sys.sleep(2^(attempt - 1))
  }

  tibble(
    coordinate_key = coordinate_key,
    latitude = latitude,
    longitude = longitude,
    sa2_code = NA_character_,
    sa2_name = NA_character_,
    api_status = "request_failed_after_3_attempts"
  )
}

query_batch <- function(batch) {
  row_numbers <- seq_len(nrow(batch))
  workers <- suppressWarnings(
    as.integer(Sys.getenv("KOORDINATES_WORKERS", unset = "4"))
  )

  if (is.na(workers) || workers < 1) {
    workers <- 1L
  }

  workers <- min(workers, 4L)

  query_row <- function(row_number) {
    query_one_coordinate(
      coordinate_key = batch$coordinate_key[[row_number]],
      latitude = batch$latitude[[row_number]],
      longitude = batch$longitude[[row_number]]
    )
  }

  if (.Platform$OS.type != "windows" && workers > 1) {
    bind_rows(
      parallel::mclapply(
        row_numbers,
        query_row,
        mc.cores = workers
      )
    )
  } else {
    bind_rows(lapply(row_numbers, query_row))
  }
}

if (nrow(coordinates_to_query) > 0) {
  # Test one request before starting thousands of requests.
  first_result <- query_batch(slice_head(coordinates_to_query, n = 1))

  if (first_result$api_status[[1]] != "matched") {
    stop(
      paste(
        "The test query did not return an SA2 polygon.",
        "Check the API key, layer ID, coordinates, and internet connection",
        "before starting the full run."
      )
    )
  }

  cache <- bind_rows(cache, first_result) |>
    distinct(coordinate_key, .keep_all = TRUE)

  write_csv(cache, lookup_cache)

  coordinates_to_query <- coordinates_to_query |>
    anti_join(cache, by = "coordinate_key")

  batch_size <- 100L

  while (nrow(coordinates_to_query) > 0) {
    batch <- slice_head(coordinates_to_query, n = batch_size)
    batch_result <- query_batch(batch)

    cache <- bind_rows(cache, batch_result) |>
      distinct(coordinate_key, .keep_all = TRUE)

    # This checkpoint makes the script resumable after interruption.
    write_csv(cache, lookup_cache)

    coordinates_to_query <- coordinates_to_query |>
      anti_join(cache, by = "coordinate_key")

    message(
      "Coordinates remaining: ",
      format(nrow(coordinates_to_query), big.mark = ",")
    )
  }
}

airbnb_with_sa2 <- airbnb |>
  mutate(
    latitude = as.numeric(latitude),
    longitude = as.numeric(longitude),
    coordinate_key = if_else(
      !is.na(latitude) & !is.na(longitude),
      sprintf("%.6f|%.6f", latitude, longitude),
      NA_character_
    )
  ) |>
  left_join(
    cache |>
      select(coordinate_key, sa2_code, sa2_name),
    by = "coordinate_key",
    relationship = "many-to-one"
  ) |>
  select(-coordinate_key)

write_csv(airbnb_with_sa2, airbnb_output)

match_summary <- airbnb_with_sa2 |>
  summarise(
    layer_id = koordinates_layer_id,
    total_airbnb_rows = n(),
    rows_with_coordinates = sum(!is.na(latitude) & !is.na(longitude)),
    rows_matched_to_sa2 = sum(!is.na(sa2_code)),
    rows_unmatched_to_sa2 = sum(is.na(sa2_code)),
    match_percent = round(mean(!is.na(sa2_code)) * 100, 2),
    unique_sa2_codes = n_distinct(sa2_code, na.rm = TRUE)
  )

unmatched_coordinates <- airbnb_with_sa2 |>
  filter(is.na(sa2_code)) |>
  count(latitude, longitude, name = "airbnb_rows") |>
  arrange(desc(airbnb_rows))

write_csv(match_summary, match_summary_output)
write_csv(unmatched_coordinates, unmatched_output)

print(match_summary)
message("Saved enriched Airbnb data to: ", airbnb_output)
