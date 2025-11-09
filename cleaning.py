import pandas as pd
import glob
import os

# Input and output directories
input_folder = "/users/<k number>/Group4/data"
output_folder = "/users/<k number>/Group4/cleaned_csv"
os.makedirs(output_folder, exist_ok=True)

# Get all CSV files in the input directory
csv_files = glob.glob(os.path.join(input_folder, "*.csv"))

for file in csv_files:
    try:
        df = pd.read_csv(file)
        
        # === Data Cleaning Steps ===
        # Drop rows with missing values
        df = df.dropna()
        # Remove duplicate rows
        df = df.drop_duplicates()
        # Strip whitespace from column names
        df.columns = df.columns.str.strip()
        # Keep only rows where p-value < 0.05
        
        
        # === Save the cleaned file ===
        out_file = os.path.join(output_folder, os.path.basename(file))
        df.to_csv(out_file, index=False)
    
    except Exception as e:
        print(f"Error processing {file}: {e}")
