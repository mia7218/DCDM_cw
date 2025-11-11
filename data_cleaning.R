# Load necessary library
library(dplyr)

# 读取已经检查过的文件
checked_data <- read.csv("check_data_basedon_SOP.csv", 
                         header = TRUE, stringsAsFactors = FALSE)

# 过滤掉有问题的行（check_result 不为空的行）
clean_data <- checked_data %>%
  filter(check_result == "")

# 输出清理后的 CSV
write.csv(clean_data, "clean_data.csv", row.names = FALSE, quote = TRUE)

# 打印统计信息
cat("Total rows in checked report:", nrow(checked_data), "\n")
cat("Rows without any issues (kept):", nrow(clean_data), "\n")
cat("Clean data saved to 'clean_data.csv'\n")
