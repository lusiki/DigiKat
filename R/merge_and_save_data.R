# Merge dta and filtered_data into one comprehensive dataframe
# Load the required libraries
library(readxl)
library(tidyverse)
library(stringi)

# Source the religious terms and filtering script
#source("R/religious_terms.R")
#source("R/load_merge_filter_religious.R")

# filtered_data is now available from the sourced script
# Now merge dta with filtered_data
# Assuming dta is already loaded in your workspace, or load it if needed

# Create a merged dataframe combining both datasets
# Add a source indicator column
dta_with_source <- dta |>
  mutate(data_source = "original_dta") |>
  select(everything())

filtered_with_source <- filtered_data |>
  mutate(data_source = "filtered_religious") |>
  select(everything())

# Merge the datasets - keep only common columns
common_cols <- intersect(names(dta_with_source), names(filtered_with_source))
merged_comprehensive <- bind_rows(
  dta_with_source |> 
    select(all_of(common_cols)),
  filtered_with_source |> 
    mutate(year = as.numeric(year)) |>
    select(all_of(common_cols))
)

cat("Original dta rows:", nrow(dta), "\n")
cat("Filtered religious data rows:", nrow(filtered_data), "\n")
cat("Merged comprehensive data rows:", nrow(merged_comprehensive), "\n")
cat("Merged data columns:", ncol(merged_comprehensive), "\n\n")

# Save to data folder as RDS (efficient binary format)
data_path <- "data/merged_comprehensive.rds"
saveRDS(merged_comprehensive, file = data_path)
cat("Saved to:", data_path, "\n")
cat("File size:", file.size(data_path) / (1024^2), "MB\n")

# Return the merged data
merged_comprehensive
