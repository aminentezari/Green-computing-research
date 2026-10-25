library(dbscan)
library(discoCVI)

args <- commandArgs(trailingOnly = TRUE)
dataset_name <- args[1]
minPts_val   <- as.integer(args[2])

data_path <- "/Users/aminentezari/Desktop/R-projects/green-computing/Green-computing-research/data/"
dataset_files <- list(
  neuroblastoma = "10_7717_peerj_5665_dataYM2018_neuroblastoma.csv",
  brain_tumor   = "dataset_Belgrade2021_pediatric_brain_tumor_plos_one_0259095_cleaned.csv",
  colorectal    = "dataset_Taipei2018_colorectal_cancer_EHRs_plos_one_0200893_final_cleaned.csv",
  sepsis        = "journal.pone.0148699_S1_Text_Sepsis_SIRS_EDITED.csv",
  heart_failure = "journal.pone.0158570_S2File_depression_heart_failure.csv"
)

data <- read.csv(paste0(data_path, dataset_files[[dataset_name]]))
num_data <- data[, sapply(data, is.numeric)]
num_data <- num_data[, colSums(is.na(num_data)) == 0]
num_data <- num_data[complete.cases(num_data), ]
num_data <- scale(num_data)
num_data <- num_data[, apply(num_data, 2, function(x) !any(is.nan(x) | is.infinite(x)))]

result <- hdbscan(num_data, minPts = minPts_val)
score <- disco_score(num_data, result$cluster)
cat("DISCO:", score, "\n")