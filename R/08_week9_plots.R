# ============================================================
# DATA422 - Deliverable 5 presentation charts
# Run after R/06_integrate_rental_data.R. No API key is needed.
# ============================================================

library(tidyverse)
source("R/pipeline_config.R", local = TRUE)

summary_dir <- pipeline_config$summary_dir
figure_dir <- pipeline_config$figure_dir
chart_quarter <- pipeline_config$chart_quarter
study_quarters <- length(seq(pipeline_config$study_start, pipeline_config$study_end, by = "3 months"))
study_label <- paste(format(pipeline_config$study_start, "%B %Y"), format(pipeline_config$study_end, "%B %Y"), sep = "-")
quarter_end <- seq(chart_quarter, by = "3 months", length.out = 2)[[2]] - 1
quarter_label <- paste0(format(chart_quarter, "%B"), "-", format(quarter_end, "%B %Y"))
quarter_slug <- paste0(format(chart_quarter, "%Y"), "q", (as.integer(format(chart_quarter, "%m")) - 1L) %/% 3L + 1L)

chart_inputs <- file.path(
  summary_dir,
  c("week9_largest_price_gaps.csv", "week9_property_count_comparison.csv",
    "week9_api_match_summary.csv", "week10_method_metadata.csv")
)

if (!all(file.exists(chart_inputs))) {
  stop("Missing chart input. Run R/05_query_geography.R and R/06_integrate_rental_data.R first.")
}

api_summary <- read_csv(chart_inputs[[3]], show_col_types = FALSE)
if (nrow(api_summary) != 1L || !identical(as.character(api_summary$layer_id), pipeline_config$sa2_layer)) {
  stop("These charts require the SA2 2019 results from layer 98970. Re-run files 05 and 06.")
}
method_metadata <- read_csv(chart_inputs[[4]], show_col_types = FALSE)
if (nrow(method_metadata) != 1L || method_metadata$method != "equal_listing_quarter_v1") {
  stop("Run the corrected file 06 before plotting: equal listing weighting is required.")
}

gap_results <- read_csv(
  chart_inputs[[1]], col_types = cols(sa2_code = col_character()),
  show_col_types = FALSE
)
count_results <- read_csv(
  chart_inputs[[2]],
  col_types = cols(sa2_code = col_character(), comparison_quarter = col_date()),
  show_col_types = FALSE
)

if (anyDuplicated(gap_results$sa2_code) ||
    anyDuplicated(count_results[c("sa2_code", "comparison_quarter")])) {
  stop("Duplicate area keys found in chart inputs. Review file 06 outputs.")
}

# Plot 1 retains the existing ranking: median of the quarterly price gaps.
# It is not a distribution of individual listing prices.
price_gap_chart_data <- gap_results |>
  filter(is.finite(median_nightly_price_gap)) |>
  arrange(desc(median_nightly_price_gap), sa2_code) |>
  slice_head(n = pipeline_config$chart_top_n)

# Plot 2 uses one quarter, avoiding repeat counts across quarters.
# Only matched areas are eligible; select the ten with most Airbnb listings.
rental_count_chart_data <- count_results |>
  filter(comparison_quarter == chart_quarter) |>
  arrange(desc(airbnb_unique_listings), sa2_code) |>
  slice_head(n = pipeline_config$chart_top_n)

if (nrow(price_gap_chart_data) == 0L || nrow(rental_count_chart_data) == 0L) {
  stop("No records available for one or both charts.")
}
if (any(!is.finite(rental_count_chart_data$active_bonds)) ||
    any(!is.finite(rental_count_chart_data$airbnb_unique_listings)) ||
    any(rental_count_chart_data$active_bonds < 0) ||
    any(rental_count_chart_data$airbnb_unique_listings < 0)) {
  stop("The count chart contains missing or invalid counts. Review the source table.")
}

dir.create(figure_dir, recursive = TRUE, showWarnings = FALSE)
write_csv(price_gap_chart_data, file.path(summary_dir, "week9_plot_price_gaps_top10.csv"))
write_csv(rental_count_chart_data, file.path(summary_dir, paste0("week9_plot_counts_top10_", quarter_slug, ".csv")))

chart_theme <- theme_minimal(base_size = 14, base_family = "sans") +
  theme(
    plot.title = element_text(size = 22, face = "bold", colour = "#20262B"),
    plot.subtitle = element_text(size = 12, colour = "#47525A", margin = margin(b = 16)),
    plot.title.position = "plot",
    plot.caption.position = "plot",
    plot.caption = element_text(size = 10, hjust = 0, colour = "#47525A",
                                lineheight = 1.25, margin = margin(t = 16)),
    axis.title.y = element_blank(),
    axis.title.x = element_text(size = 12, margin = margin(t = 12)),
    axis.text.y = element_text(size = 12, colour = "#20262B"),
    axis.text.x = element_text(size = 11, colour = "#47525A"),
    panel.grid.major.y = element_blank(),
    panel.grid.minor = element_blank(),
    panel.grid.major.x = element_line(colour = "#E3E7E9", linewidth = 0.4),
    axis.line.x = element_line(colour = "#A3ABB0", linewidth = 0.4),
    legend.position = "top",
    legend.justification = "left",
    legend.title = element_blank(),
    plot.margin = margin(18, 32, 16, 16)
  )

gap_plot_data <- price_gap_chart_data |>
  mutate(
    area = factor(sa2_name, levels = rev(sa2_name)),
    label = paste0(scales::dollar(median_nightly_price_gap, accuracy = 0.01),
                   "  (", quarters_compared, "/", study_quarters, " quarters)")
  )

price_gap_plot <- ggplot(gap_plot_data, aes(x = median_nightly_price_gap, y = area)) +
  geom_col(fill = "#167D8D", width = 0.65) +
  geom_vline(xintercept = 0, colour = "#A3ABB0", linewidth = 0.4) +
  geom_text(aes(label = label), hjust = -0.06, size = 3.8, colour = "#20262B") +
  scale_x_continuous(labels = scales::label_dollar(accuracy = 1),
                     breaks = scales::breaks_pretty(n = 5),
                     expand = expansion(mult = c(0, 0.38))) +
  labs(
    title = "Largest short-term vs long-term rental price gaps",
    subtitle = paste0("Top ", pipeline_config$chart_top_n, " matched SA2 areas | ", study_label,
                      " | SA2 2019\nMedian of quarterly gaps: equal-listing Airbnb nightly median - (tenancy weekly median / 7)"),
    x = "Median quarterly gap (NZ$ per night)",
    caption = paste(
      "Each listing contributes one within-quarter median. Ambiguous listing-quarter area assignments are excluded and recorded.",
      "Labels show quarters with a usable gap. Airbnb prices are missing for Dec 2025-Feb 2026; only available prices are used.",
      "Advertised Airbnb prices and bond rents describe different markets; the gap is not a profit or causal estimate.",
      "Sources: Inside Airbnb; MBIE Tenancy Services; Stats NZ. Only quarters with matching tenancy data contribute to gaps.", sep = "\n"
    )
  ) + chart_theme

count_plot_data <- rental_count_chart_data |>
  mutate(area = factor(sa2_name, levels = rev(sa2_name))) |>
  pivot_longer(c(airbnb_unique_listings, active_bonds), names_to = "series", values_to = "count") |>
  mutate(series = factor(series, levels = c("airbnb_unique_listings", "active_bonds"),
                         labels = c("Unique Airbnb listings", "Active tenancy bonds")))

rental_count_plot <- ggplot(count_plot_data, aes(x = count, y = area, fill = series)) +
  geom_col(position = position_dodge(width = 0.8), width = 0.7) +
  geom_text(aes(label = scales::comma(count, accuracy = 1)),
            position = position_dodge(width = 0.8), hjust = -0.15, size = 3.4,
            colour = "#20262B") +
  scale_fill_manual(values = c("Unique Airbnb listings" = "#167D8D", "Active tenancy bonds" = "#BC603D")) +
  scale_x_continuous(labels = scales::label_comma(accuracy = 1),
                     breaks = scales::breaks_pretty(n = 5),
                     expand = expansion(mult = c(0, 0.14))) +
  labs(
    title = "Airbnb listings and active tenancy bonds by area",
    subtitle = paste0(quarter_label, " | Top ", pipeline_config$chart_top_n,
                      " matched areas by eligible unique Airbnb listing count | SA2 2019"),
    x = "Count in the selected quarter",
    caption = paste(
      "Airbnb counts are distinct IDs with an unambiguous area in the quarter. Bonds use the ALL dwelling types / ALL bedrooms row.",
      "Active bonds are an administrative rental indicator, not a verified count of distinct properties. Counts are not added across quarters.",
      "Sources: Inside Airbnb; MBIE Tenancy Services; Stats NZ. Only matched areas are shown; this is a selected subset of Christchurch.", sep = "\n"
    )
  ) + chart_theme

ggsave(file.path(figure_dir, "week9_price_gaps_top10.png"), price_gap_plot,
       width = 14, height = 9, units = "in", dpi = 180, bg = "white")
ggsave(file.path(figure_dir, "week9_price_gaps_top10.pdf"), price_gap_plot,
       width = 14, height = 9, units = "in", device = "pdf", useDingbats = FALSE)
ggsave(file.path(figure_dir, paste0("week9_airbnb_vs_active_bonds_", quarter_slug, ".png")), rental_count_plot,
       width = 14, height = 9, units = "in", dpi = 180, bg = "white")
ggsave(file.path(figure_dir, paste0("week9_airbnb_vs_active_bonds_", quarter_slug, ".pdf")), rental_count_plot,
       width = 14, height = 9, units = "in", device = "pdf", useDingbats = FALSE)

# These named plots remain available in RStudio after sourcing the script.
if (interactive()) {
  print(price_gap_plot)
  print(rental_count_plot)
}
message("Saved both charts as PNG and PDF in ", figure_dir, ".")
message("To display a chart in RStudio, run print(price_gap_plot) or print(rental_count_plot).")
