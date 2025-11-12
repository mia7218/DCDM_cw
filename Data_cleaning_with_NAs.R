
# Load necessary library
library(dplyr)
library(stringr)

# Read the checked data
checked_data <- read.csv("check_report_basedon_SOP.csv", header = TRUE, stringsAsFactors = FALSE)

# Define a function to replace invalid fields with NA based on check_result
clean_row <- function(row) {
  if (row["check_result"] == "") return(row)  # No issues, return as-is
  
  errors <- unlist(strsplit(row["check_result"], ";\\s*"))
  
  for (err in errors) {
    if (grepl("analysis_id", err)) row["analysis_id"] <- NA
    if (grepl("gene_accession_id", err)) row["gene_accession_id"] <- NA
    if (grepl("gene_symbol", err)) row["gene_symbol"] <- NA
    if (grepl("mouse_strain invalid value", err)) row["mouse_strain"] <- NA
    if (grepl("mouse_life_stage invalid value|mouse_life_stage length error", err)) row["mouse_life_stage"] <- NA
    if (grepl("parameter_id", err)) row["parameter_id"] <- NA
    if (grepl("parameter_name", err)) row["parameter_name"] <- NA
    if (grepl("pvalue out of range 0-1", err)) row["pvalue"] <- NA
  }
  
  return(row)
}

# Apply the cleaning function row-wise
clean_data <- as.data.frame(t(apply(checked_data, 1, clean_row)), stringsAsFactors = FALSE)

# Write cleaned data to CSV
write.csv(clean_data, "clean_data.csv", row.names = FALSE, quote = TRUE)

# Print summary
cat("Total rows in checked report:", nrow(checked_data), "\n")
cat("Rows retained (all):", nrow(clean_data), "\n")
cat("Invalid values replaced with NA. Clean data saved to 'clean_data.csv'\n")
