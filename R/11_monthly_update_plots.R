# Airbnb-only monthly plots include months with no corresponding tenancy quarter.
library(tidyverse)
source("R/pipeline_config.R", local = TRUE)
source("R/helpers/integration_helpers.R", local = TRUE)

monthly_data <- read_csv(pipeline_config$cleaned_airbnb,
  col_types = cols(id = col_character(), host_id = col_character(), price = col_double()), show_col_types = FALSE) |>
  mutate(snapshot_date = as.Date(paste0(gsub("_", "-", month_year), "-01")))
assert_unique_keys(monthly_data, c("id", "snapshot_date"), "Monthly chart data")
monthly_summary <- monthly_data |>
  group_by(snapshot_date) |>
  summarise(listings = n_distinct(id), priced_listings = sum(!is.na(price)),
    missing_prices = sum(is.na(price)), median_nightly_price = median_or_na(price), .groups = "drop") |>
  arrange(snapshot_date)
write_csv(monthly_summary, file.path(pipeline_config$summary_dir, "week11_monthly_summary.csv"))
new_month_start <- as.Date("2026-07-01")
month_breaks <- monthly_summary$snapshot_date
monthly_theme <- theme_minimal(base_size = 13) + theme(
  panel.grid.minor = element_blank(), plot.title = element_text(face = "bold", size = 20),
  plot.subtitle = element_text(size = 12, margin = margin(b = 12)),
  plot.caption = element_text(hjust = 0, size = 10, margin = margin(t = 14)),
  plot.margin = margin(18, 22, 16, 18), legend.position = "none")

monthly_price_plot <- ggplot(monthly_summary, aes(snapshot_date, median_nightly_price)) +
  geom_line(colour = "#167D8D", linewidth = 1, na.rm = TRUE) +
  geom_point(aes(colour = snapshot_date >= new_month_start), size = 3, na.rm = TRUE) +
  scale_colour_manual(values = c("FALSE" = "#167D8D", "TRUE" = "#BC603D")) +
  scale_x_date(breaks = month_breaks, date_labels = "%b\n%Y") +
  scale_y_continuous(labels = scales::label_dollar(), limits = c(0, NA), expand = expansion(mult = c(0, .12))) +
  labs(title = "Christchurch Airbnb prices by monthly snapshot",
    subtitle = "One observation per listing within each month | July and August highlighted",
    x = NULL, y = "Median advertised price (NZ$ per night)",
    caption = "Dec 2025-Feb 2026 have no observed prices: gaps are missing data, not zero prices.\nMonthly medians describe changing sets of listings, not a constant-property price index. Source: Inside Airbnb.") + monthly_theme

monthly_count_plot <- ggplot(monthly_summary, aes(snapshot_date, listings)) +
  geom_col(aes(fill = snapshot_date >= new_month_start), width = 21) +
  geom_text(aes(label = scales::comma(listings)), vjust = -.5, size = 3.5) +
  scale_fill_manual(values = c("FALSE" = "#167D8D", "TRUE" = "#BC603D")) +
  scale_x_date(breaks = month_breaks, date_labels = "%b\n%Y") +
  scale_y_continuous(labels = scales::label_comma(), expand = expansion(mult = c(0, .12))) +
  labs(title = "Christchurch Airbnb listings in each snapshot", subtitle = "Distinct listing IDs per month | July and August highlighted",
    x = NULL, y = "Unique listings",
    caption = "The same property may legitimately appear in several months. Monthly counts must not be added to count unique properties.\nSource: Inside Airbnb, Christchurch City records only.") + monthly_theme

new_price_data <- monthly_data |> filter(snapshot_date >= new_month_start, !is.na(price))
if (!nrow(new_price_data)) stop("No observed prices in the new months; a price distribution cannot be drawn.")
display_limit <- as.numeric(quantile(new_price_data$price, .99, na.rm = TRUE))
distribution_coverage <- new_price_data |> group_by(month_year) |>
  summarise(observed_prices = n(), above_display_limit = sum(price > display_limit), .groups = "drop")
write_csv(distribution_coverage, file.path(pipeline_config$summary_dir, "week11_histogram_display_coverage.csv"))
price_distribution_plot <- ggplot(new_price_data, aes(price)) +
  geom_histogram(binwidth = 25, boundary = 0, fill = "#167D8D", colour = "white") +
  facet_wrap(~month_year, nrow = 1) + coord_cartesian(xlim = c(0, display_limit)) +
  scale_x_continuous(labels = scales::label_dollar()) +
  labs(title = "Advertised nightly prices in the new Airbnb snapshots", subtitle = "Christchurch City | July and August 2026 | NZ$25 histogram bins",
    x = "Advertised price (NZ$ per night)", y = "Listings",
    caption = paste0("View zoomed to the pooled 99th percentile ($", round(display_limit), "); ", sum(new_price_data$price > display_limit),
      " higher prices remain in the data and all summaries.\nMissing prices are excluded from the histogram, not filled with zero. Source: Inside Airbnb.")) + monthly_theme

plots <- list(week11_monthly_prices = monthly_price_plot, week11_monthly_listing_counts = monthly_count_plot,
              week11_new_month_price_distribution = price_distribution_plot)
for (name in names(plots)) {
  ggsave(file.path(pipeline_config$figure_dir, paste0(name, ".png")), plots[[name]], width = 14, height = 7, dpi = 160, bg = "white")
  ggsave(file.path(pipeline_config$figure_dir, paste0(name, ".pdf")), plots[[name]], width = 14, height = 7, device = "pdf", useDingbats = FALSE)
}
