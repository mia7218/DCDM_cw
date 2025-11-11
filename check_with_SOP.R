# Load necessary library
library(dplyr)

# Define valid values
valid_strains <- c("C57BL", "B6J", "C3H", "129SV")
valid_life_stages <- c("E12.5","E15.5","E18.5","E9.5",
                       "Early adult","Late adult","Middle aged adult")

# Read CSV data
data <- read.csv("merged_data.csv", header = TRUE, stringsAsFactors = FALSE)

# Define a function to check each row
check_row <- function(row) {
  errors <- c()
  
  # String length checks
  if(nchar(row["analysis_id"]) != 15) errors <- c(errors, "analysis_id length error")
  if(nchar(row["gene_accession_id"]) < 9 | nchar(row["gene_accession_id"]) > 11) errors <- c(errors, "gene_accession_id length error")
  if(nchar(row["gene_symbol"]) < 1 | nchar(row["gene_symbol"]) > 13) errors <- c(errors, "gene_symbol length error")
  if(nchar(row["mouse_strain"]) < 3 | nchar(row["mouse_strain"]) > 5) errors <- c(errors, "mouse_strain length error")
  if(nchar(row["mouse_life_stage"]) < 4 | nchar(row["mouse_life_stage"]) > 17) errors <- c(errors, "mouse_life_stage length error")
  if(nchar(row["parameter_id"]) < 15 | nchar(row["parameter_id"]) > 20) errors <- c(errors, "parameter_id length error")
  if(nchar(row["parameter_name"]) < 2 | nchar(row["parameter_name"]) > 74) errors <- c(errors, "parameter_name length error")
  
  # Enum value checks
  if(!(row["mouse_strain"] %in% valid_strains)) errors <- c(errors, "mouse_strain invalid value")
  if(!(row["mouse_life_stage"] %in% valid_life_stages)) errors <- c(errors, "mouse_life_stage invalid value")
  
  # pvalue check
  pval <- suppressWarnings(as.numeric(row["pvalue"]))
  if(is.na(pval)) {
    errors <- c(errors, "pvalue not numeric")
  } else if(pval < 0 | pval > 1) {
    errors <- c(errors, "pvalue out of range 0-1")
  }
  
  return(paste(errors, collapse = "; "))
}

# Apply the check function to each row
data$check_result <- apply(data, 1, check_row)

# Output a CSV report
write.csv(data, "check_report_basedon_SOP.csv", row.names = FALSE, quote = TRUE)

# Print summary
cat("Total rows:", nrow(data), "\n")
cat("Rows with issues:", sum(data$check_result != ""), "\n")
cat("Detailed issues are saved in check_report_basedon_SOP.csv\n")
