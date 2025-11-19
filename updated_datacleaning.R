library(dplyr)  # Load dplyr package

input_file <- "merged_data.csv"   # Input file name
output_file <- "clean_data.csv"   # Output file name

valid_strains <- c("C57BL", "B6J", "C3H", "129SV")  # Valid mouse strains
valid_life_stages <- c("E12.5","E15.5","E18.5","E9.5","Early adult","Late adult","Middle aged adult")  # Valid life stages

data <- read.csv(input_file, header = TRUE, stringsAsFactors = FALSE)  # Read CSV

# Format gene_symbol: capitalize first letter, lowercase the rest
if ("gene_symbol" %in% names(data)) {          
  gs <- trimws(data$gene_symbol)               # Trim whitespace
  gs[!is.na(gs) & gs != ""] <- paste0(         # Format non-empty values
    toupper(substr(gs[!is.na(gs) & gs != ""], 1, 1)),  # First letter uppercase
    tolower(substr(gs[!is.na(gs) & gs != ""], 2, nchar(gs[!is.na(gs) & gs != ""])))  # Rest lowercase
  )
  data$gene_symbol <- gs                       # Write back
}

# Convert parameter_id to uppercase and trim whitespace
if ("parameter_id" %in% names(data)) {
  data$parameter_id <- toupper(trimws(as.character(data$parameter_id)))
}

# Function to fix gene_accession_id
fix_gene_accession_id <- function(gid) {
  if (is.na(gid) || gid == "") return(gid)           # Return if empty
  gid_trim <- trimws(as.character(gid))              # Trim whitespace
  parts <- strsplit(gid_trim, ":", fixed = TRUE)[[1]] # Split prefix/suffix
  if (length(parts) >= 2) {                          # If has prefix
    prefix <- parts[1]
    suffix <- paste(parts[-1], collapse = ":")       # Rejoin suffix
    if (tolower(prefix) == "mgi") {                  # If prefix mgi
      return(paste0("MGI:", trimws(suffix)))         # Normalize to MGI
    } else {
      return(gid_trim)                               # Otherwise unchanged
    }
  }
  return(gid_trim)
}

gene_acc_idx <- which(grepl("gene", names(data), ignore.case = TRUE) &  # Locate gene_accession column
                        grepl("accession", names(data), ignore.case = TRUE))
if (length(gene_acc_idx) == 1) {                     # Only proceed if one column found
  gene_acc_col <- names(data)[gene_acc_idx]
  data[[gene_acc_col]] <- sapply(data[[gene_acc_col]], fix_gene_accession_id, USE.NAMES = FALSE)  # Apply fix
} else {
  gene_acc_col <- NA
}

# Fix pvalue columns
p_col_pattern <- "(^p[_\\.]?value$|pvalue|^pval$|^p\\.value$)"  # Pattern for p-value column names
p_cols <- grep(p_col_pattern, names(data), ignore.case = TRUE, value = TRUE)  # Find p-value columns
fix_count_total <- 0L       # Counter for total fixes
fix_examples <- list()      # Store examples

if (length(p_cols) > 0) {
  for (pcol in p_cols) {                        # For each p-value column
    vec <- as.character(data[[pcol]])           # Convert to character
    fixed_vec <- vector("character", length(vec))
    fix_count <- 0L
    for (i in seq_along(vec)) {                 # Check each value
      v <- vec[i]
      if (is.na(v) || trimws(v) == "") {        # Skip empty
        fixed_vec[i] <- v
        next
      }
      v2 <- trimws(as.character(v))             # Trim whitespace
      v2 <- gsub("\u2212|\u2013|\u2014", "-", v2, perl = TRUE)  # Normalize special minus signs
      v2 <- gsub(",", "", v2, fixed = TRUE)     # Remove thousand separators
      v2 <- gsub("^\\(|\\)$", "", v2)           # Remove parentheses
      numeric_value <- suppressWarnings(as.numeric(v2))  # Try numeric conversion
      if (!is.na(numeric_value)) {              
        if (numeric_value <= 0 || numeric_value > 1) {    # Out-of-range
          fixed_vec[i] <- "NA"
          fix_count <- fix_count + 1L
          if (length(fix_examples) < 10) fix_examples[[length(fix_examples) + 1]] <- list(col = pcol, row = i, old = v, new = "NA")
          next
        }
        fixed_vec[i] <- format(numeric_value, scientific = FALSE, trim = TRUE)  # Save non-scientific format
      } else {
        fixed_vec[i] <- v2                   # Keep original if not numeric
      }
    }
    data[[pcol]] <- fixed_vec                 # Write back
    fix_count_total <- fix_count_total + fix_count
  }
}

# Row validation function
check_row <- function(row, gene_acc_col_name = NA) {
  errors <- c()
  for (col in names(row)) {                    # Check empty cells
    val <- row[[col]]
    if (is.na(val) || (is.character(val) && val == "")) {
      errors <- c(errors, paste0(col, " is NA or empty"))
    }
  }
  if (!is.na(row["analysis_id"]) && row["analysis_id"] != "" && nchar(row["analysis_id"]) != 15) {
    errors <- c(errors, "analysis_id length error")
  }
  if (!is.na(gene_acc_col_name) && !is.na(row[gene_acc_col_name]) && row[gene_acc_col_name] != "") {
    gval <- as.character(row[gene_acc_col_name])
    if (nchar(gval) < 9 || nchar(gval) > 11) {
      errors <- c(errors, paste0(gene_acc_col_name, " length error"))
    }
    if (!grepl("^MGI:\\s*\\d+$", gval)) {
      errors <- c(errors, paste0(gene_acc_col_name, " format error (expected 'MGI:digits')"))
    }
  }
  if (!is.na(row["gene_symbol"]) && row["gene_symbol"] != "" && (nchar(row["gene_symbol"]) < 1 || nchar(row["gene_symbol"]) > 13)) {
    errors <- c(errors, "gene_symbol length error")
  }
  if (!is.na(row["mouse_strain"]) && row["mouse_strain"] != "" && (nchar(row["mouse_strain"]) < 3 || nchar(row["mouse_strain"]) > 5)) {
    errors <- c(errors, "mouse_strain length error")
  }
  if (!is.na(row["mouse_life_stage"]) && row["mouse_life_stage"] != "" && (nchar(row["mouse_life_stage"]) < 4 || nchar(row["mouse_life_stage"]) > 17)) {
    errors <- c(errors, "mouse_life_stage length error")
  }
  if (!is.na(row["parameter_id"]) && row["parameter_id"] != "" && (nchar(row["parameter_id"]) < 15 || nchar(row["parameter_id"]) > 20)) {
    errors <- c(errors, "parameter_id length error")
  }
  if (!is.na(row["parameter_name"]) && row["parameter_name"] != "" && (nchar(row["parameter_name"]) < 2 || nchar(row["parameter_name"]) > 74)) {
    errors <- c(errors, "parameter_name length error")
  }
  if (!is.na(row["mouse_strain"]) && row["mouse_strain"] != "" && !(row["mouse_strain"] %in% valid_strains)) {
    errors <- c(errors, "mouse_strain invalid value")
  }
  if (!is.na(row["mouse_life_stage"]) && row["mouse_life_stage"] != "" && !(row["mouse_life_stage"] %in% valid_life_stages)) {
    errors <- c(errors, "mouse_life_stage invalid value")
  }
  
  pcol_names <- names(row)[grepl(p_col_pattern, names(row), ignore.case = TRUE)]  # Locate p-value columns
  if (length(pcol_names) > 0) {
    for (pcol in pcol_names) {
      val <- row[pcol]
      if (is.na(val) || trimws(val) == "" || toupper(trimws(val)) == "NA") {
        next
      }
      pval <- suppressWarnings(as.numeric(val))
      if (is.na(pval)) {
        errors <- c(errors, paste0(pcol, " not numeric"))
      } else if (pval <= 0 || pval > 1) {
        errors <- c(errors, paste0(pcol, " out of range 0-1"))
      }
    }
  }
  return(paste(errors, collapse = "; "))  # Return all errors
}

# Run validation for each row
if (!is.na(gene_acc_col)) {
  check_result <- apply(data, 1, function(r) check_row(as.list(r), gene_acc_col_name = gene_acc_col))
} else {
  check_result <- apply(data, 1, function(r) check_row(as.list(r), gene_acc_col_name = NA))
}

# Replace blank cells with "NA"
for (col in names(data)) {
  vec <- as.character(data[[col]])
  is_blank <- trimws(vec) == ""   # Detect blanks
  vec[is_blank] <- "NA"           # Replace with NA string
  data[[col]] <- vec
}

# Save cleaned CSV without quotes
write.csv(data, output_file, row.names = FALSE, quote = FALSE)

# Print summary
cat("Total rows:", nrow(data), "\n")
cat("Rows with issues:", sum(check_result != ""), "\n")
if (!is.na(gene_acc_col)) {
  cat("gene_accession fix applied to column:", gene_acc_col, "\n")
} else {
  cat("gene_accession fix was NOT applied (column not found).\n")
}
cat("Total pvalue negative/format/out-of-range replaced:", fix_count_total, "\n")
if (length(fix_examples) > 0) {
  cat("Examples of fixes (up to 10):\n")
  for (ex in fix_examples) {
    cat(sprintf("  col %s row %d: '%s' -> '%s'\n", ex$col, ex$row, ex$old, ex$new))
  }
}
cat("Clean data saved in", output_file, "\n")
