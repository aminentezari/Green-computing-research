library(dbscan)
library(DBCVindex)

data <- read.csv("/Users/aminentezari/Desktop/R-projects/green-computing/Green-computing-research/data/10_7717_peerj_5665_dataYM2018_neuroblastoma.csv")
num_data <- data[, sapply(data, is.numeric)]
num_data <- scale(num_data)

result <- hdbscan(num_data, minPts = 5)
score <- dbcv_index(num_data, result$cluster)
cat("DBCV:", score, "\n")