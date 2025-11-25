# merge_files.R
# Simple script to read many small key-value files in "data/" and merge into one CSV.
# Requirements: install.packages("data.table")

library(data.table)

# ---- user settings ----
folder <- "data"          # folder containing the files
out_csv <- "merged_data.csv"
progress_mod <- 200       # print progress every 'progress_mod' files
# -----------------------

files <- list.files(folder, full.names = TRUE)
nfiles <- length(files)

cat("Found", nfiles, "files in", folder, "\n")

# Preallocate list for speed
res_list <- vector("list", nfiles)

read_one_to_row <- function(path) {
  # Try to read the file as two columns (key, value)
  dt <- tryCatch(
    fread(path, header = FALSE, sep = ",", fill = TRUE, col.names = c("key", "value")),
    error = function(e) return(NULL)
  )
  
  # If read failed or file empty, return NULL (will be skipped)
  if (is.null(dt) || nrow(dt) == 0) return(NULL)
  
  # remove rows without keys
  dt <- dt[!is.na(key) & key != ""]
  if (nrow(dt) == 0) return(NULL)
  
  # Convert all keys to lowercase
  dt[, key := tolower(key)]
  
  # If duplicate keys in one file, keep the first occurrence
  dt <- dt[!duplicated(key)]
  
  # Convert to a named list (key -> value) and then to a one-row data.table
  vals <- as.list(dt$value)
  names(vals) <- dt$key
  
  # Ensure returned object is a data.table with one row
  as.data.table(vals)
}

# Loop with progress printing
for (i in seq_len(nfiles)) {
  if (i %% progress_mod == 0 || i == nfiles) {
    cat(sprintf("Processing %d / %d (%.1f%%)\n", i, nfiles, 100 * i / nfiles))
  }
  res_list[[i]] <- read_one_to_row(files[i])
}


# Combine into one big data.table; missing columns filled with NA
big_dt <- rbindlist(res_list, fill = TRUE)

# Write to CSV
fwrite(big_dt, file = out_csv)
cat("Wrote merged table with", nrow(big_dt), "rows and", ncol(big_dt), "columns to", out_csv, "\n")


