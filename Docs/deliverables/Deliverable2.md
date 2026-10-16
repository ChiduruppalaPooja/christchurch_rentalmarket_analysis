# Deliverable 2 — Inside Airbnb Dataset Exploration and KNIME Workflow

## 1. Purpose

The purpose of this deliverable was to explore Airbnb listing data for New Zealand, understand the dataset structure, perform basic data preparation in KNIME, and create visualisations to investigate listing prices and guest-review activity. The analysis also aimed to identify highly reviewed listings nationally and determine how many of those listings were located in Christchurch City.

## 2. Dataset Source

The dataset was obtained from [Inside Airbnb — Get the Data](https://insideairbnb.com/get-the-data/), which publishes publicly available Airbnb listing data for research and analysis.

- **Dataset:** `listings.csv`
- **Geographic coverage:** New Zealand
- **Reported snapshot date:** 19 June 2026 — verify against the original downloaded file or download record.
- **Format:** CSV
- **Storage:** The raw dataset was stored locally because of its file size and was not committed to the GitHub repository.

Inside Airbnb provides different listing files. Its `listings.csv` file contains summary information and metrics intended for visualisation, while `listings.csv.gz` contains detailed listing data. The file used for this analysis should be identified by its actual filename and download record.

Each row represents an Airbnb listing in the downloaded snapshot. The data describes listings at the time of collection; it should not be interpreted as a continuously updated record of current availability or pricing.

## 3. Dataset Structure and Column Definitions

The dataset contains listing identifiers, host details, geographic information, pricing, availability, and review-related variables. The following descriptions explain the fields used in the downloaded dataset. Data types shown here are conceptual and should be checked against the types assigned when the CSV is imported into KNIME.

| Field                            | Description                                                                          | Conceptual data type         |
| -------------------------------- | ------------------------------------------------------------------------------------ | ---------------------------- |
| `id`                             | Unique identifier for an Airbnb listing                                              | Integer or identifier        |
| `name`                           | Title or name of the listing                                                         | Text                         |
| `host_id`                        | Identifier for the host                                                              | Integer or identifier        |
| `host_name`                      | Name of the host                                                                     | Text                         |
| `neighbourhood_group`            | Broader geographic grouping recorded for the listing                                 | Text/category                |
| `neighbourhood`                  | Neighbourhood or local area recorded for the listing                                 | Text/category                |
| `latitude`                       | Latitude coordinate of the listing                                                   | Numeric                      |
| `longitude`                      | Longitude coordinate of the listing                                                  | Numeric                      |
| `room_type`                      | Accommodation type, such as an entire home/apartment or private room                 | Text/category                |
| `price`                          | Listed nightly price; confirm the currency and representation in the downloaded file | Numeric                      |
| `minimum_nights`                 | Minimum number of nights required for a booking                                      | Integer                      |
| `number_of_reviews`              | Total number of reviews recorded for the listing                                     | Integer                      |
| `last_review`                    | Date of the most recent review recorded for the listing                              | Date, or text before parsing |
| `reviews_per_month`              | Average monthly review rate reported for the listing                                 | Numeric                      |
| `calculated_host_listings_count` | Number of listings attributed to the host by this calculated field                   | Integer                      |
| `availability_365`               | Number of days available for booking within the 365-day availability window          | Integer                      |
| `number_of_reviews_ltm`          | Number of reviews received in the last twelve months                                 | Integer                      |
| `license`                        | Licence or registration information, where supplied                                  | Text                         |

The actual observed minimums, maximums, missing-value counts, and category frequencies should be calculated from the downloaded CSV. They should not be treated as permanent properties of the dataset because they can change between snapshots.

## 4. Data Quality and Missing Values

The initial inspection identified missing values in review-related fields and the `license` field. The exact number and distribution of missing values should be confirmed from the imported data.

Missing values require field-specific treatment:

- **`last_review`:** A missing date may indicate that no review date is recorded. It should not automatically be interpreted as a recent or old review.
- **`reviews_per_month`:** A missing value should be retained or treated according to the analytical requirement. It should not automatically be replaced with zero.
- **`license`:** The missingness should be inspected to determine whether individual entries or the entire column are unavailable.
- **`price`:** Missing prices should be handled explicitly before plotting price distributions.
- **`neighbourhood_group`:** Listings without a usable geographic grouping may not be classifiable for the national-versus-Christchurch comparison.

The treatment of missing values should preserve listings that remain valid for other analyses wherever possible. Removing a row because one field is missing can also remove useful information from unrelated analyses.

## 5. KNIME Data Preparation

The data preparation workflow was developed in KNIME. The documented approach used the **Missing Value (Cleaning)** node and its **Treatment by Column** configuration.

The following table records the intended treatment and the checks required before the decisions are considered final.

| Field or field group                   | Treatment to document                                                                                         | Reason                                                                   |
| -------------------------------------- | ------------------------------------------------------------------------------------------------------------- | ------------------------------------------------------------------------ |
| `id`, `host_id`                        | Retain valid identifiers; check for missing or duplicate IDs                                                  | Required to identify listings and avoid counting duplicate records       |
| `name`, `host_name`                    | Retain unless a specific analysis requires otherwise                                                          | Descriptive information                                                  |
| `neighbourhood_group`, `neighbourhood` | Inspect missing values and category values before deciding whether to remove rows                             | Required for geographic filtering and comparisons                        |
| `latitude`, `longitude`                | Retain valid coordinates; inspect missing or implausible values if mapping is required                        | Supports geographic analysis                                             |
| `room_type`                            | Retain valid categories and inspect missing values                                                            | Supports listing-type comparisons                                        |
| `price`                                | Exclude missing or invalid prices from price calculations and plots, if this was the implemented workflow     | A missing price cannot contribute to a price distribution                |
| `minimum_nights`                       | Retain and inspect invalid or missing values if relevant                                                      | Describes booking restrictions                                           |
| `number_of_reviews`                    | Retain valid numeric values; verify whether any values are missing                                            | Used to identify highly reviewed listings                                |
| `last_review`                          | Parse as a date and preserve missing dates as missing unless a documented analysis-specific filter is applied | Needed to calculate elapsed time since the last review                   |
| `reviews_per_month`                    | Retain missing values unless the relevant analysis requires a complete value                                  | Missing monthly review rates should not automatically be treated as zero |
| `calculated_host_listings_count`       | Retain and check missing values if the field is used                                                          | Describes host listing counts                                            |
| `availability_365`                     | Retain valid values and check that they fall within the expected range                                        | Describes availability                                                   |
| `number_of_reviews_ltm`                | Retain valid numeric values and check missingness                                                             | Describes recent review activity                                         |
| `license`                              | Inspect missingness and usefulness before deciding whether to retain the field                                | May not be needed for the planned visualisations                         |

**Important:** This table describes a defensible treatment strategy, not proof that every decision was implemented in the existing KNIME workflow. The final documentation must match the actual node configuration and output. In particular, any statement that a row was removed should be supported by the workflow and, where possible, by before-and-after row counts.

## 6. Analysis and Visualisations

The analysis was intended to address the following questions.

### 6.1 Price distribution

Compare the distribution of nightly listing prices across New Zealand with the distribution for Christchurch City. The comparison should use the same price units and clearly identify the geographic groups.

The analysis should document how missing or invalid prices were handled. Because listing prices can be highly skewed, unusually high values should be inspected rather than removed automatically.

### 6.2 Time since the last review

Calculate the number of days between the snapshot date and each listing's `last_review` date:

`days_since_last_review = snapshot_date - last_review`

The snapshot date must be verified before the calculation is finalised. Both dates should be parsed as dates, and the calculation should use consistent date units.

Listings with no recorded `last_review` date cannot be assigned a valid elapsed-time value using this calculation. They should be identified separately rather than silently assigned zero days or removed without explanation.

Plot the distribution of elapsed days for listings with valid review dates and document how missing dates were handled.

### 6.3 Highly reviewed listings

Use `number_of_reviews` to identify listings in the highest-review group, defined by the assignment as the top 10% of listings. Document the method used to calculate the 90th-percentile threshold and how ties at the threshold were handled.

Then count how many listings in this group are located in Christchurch City. The geographic filter must use the actual category values in `neighbourhood_group` or the appropriate verified geographic field.

The final documentation should include the calculated threshold and Christchurch count only after these results have been obtained from the workflow.

##

## 7. Limitations

The dataset represents a snapshot of Airbnb listings rather than a complete record of every booking or guest interaction. Prices and availability may change after collection. Missing review dates limit the calculation of elapsed time since the last review, and unusually high prices may affect the visual appearance of price distributions.

The observed data ranges, missing-value counts, final row counts, percentile threshold, and Christchurch result must be reported from the actual downloaded file and completed workflow. They should not be inferred from field descriptions alone.

## 8. Source

Inside Airbnb. *Get the Data*. [https://insideairbnb.com/get-the-data/](https://insideairbnb.com/get-the-data/)

The downloaded CSV and its snapshot date should be retained as the reference for the specific observations analysed.
