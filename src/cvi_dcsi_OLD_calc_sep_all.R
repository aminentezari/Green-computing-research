# cvi_dcsi.R
library(dbscan)
library(pegas)
library(clusterCrit)

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

download.file(
  "https://raw.githubusercontent.com/JanaGauss/dcsi/main/code/functions/separability_functions.R",
  destfile = "separability_functions.R"
)
source("separability_functions.R")

result <- hdbscan(num_data, minPts = minPts_val)
mask <- result$cluster != 0
clean_df <- as.data.frame(apply(num_data[mask, ], 2, as.double))
char_labels <- paste0("C", result$cluster[mask])

s <- calc_sep_all(data = clean_df, labels = char_labels)
cat("DCSI:", s$value[s$measure == "DCSI"], "\n")