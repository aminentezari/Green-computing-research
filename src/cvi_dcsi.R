library(dbscan)
library(pegas)
library(clusterCrit)

data <- read.csv("/Users/aminentezari/Desktop/R-projects/green-computing/Green-computing-research/data/10_7717_peerj_5665_dataYM2018_neuroblastoma.csv")
num_data <- data[, sapply(data, is.numeric)]
num_data <- scale(num_data)

download.file(
  "https://raw.githubusercontent.com/JanaGauss/dcsi/main/code/functions/separability_functions.R",
  destfile = "separability_functions.R"
)
source("separability_functions.R")

result <- hdbscan(num_data, minPts = 5)
mask <- result$cluster != 0
clean_df <- as.data.frame(apply(num_data[mask, ], 2, as.double))
char_labels <- paste0("C", result$cluster[mask])

s <- calc_sep_all(data = clean_df, labels = char_labels)
cat("DCSI:", s$value[s$measure == "DCSI"], "\n")