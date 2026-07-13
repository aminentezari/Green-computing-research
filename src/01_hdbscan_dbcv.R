install.packages("dbscan")
library(dbscan)
data <- read.csv("/Users/aminentezari/Desktop/R-projects/green-computing/Green-computing-research/data/10_7717_peerj_5665_dataYM2018_neuroblastoma.csv")

# Keep only numeric columns and scale
num_data <- data[, sapply(data, is.numeric)]
num_data <- scale(num_data)

# Run HDBSCAN
result <- hdbscan(num_data, minPts = 5)
print(result$cluster)
table(result$cluster)  # 0 = noise points

#we try with diffrent min poits in order
for (mp in c(3, 5, 10, 15, 20)) {
  res <- hdbscan(num_data, minPts = mp)
  cat("minPts =", mp, "| clusters:", max(res$cluster), "| noise:", sum(res$cluster == 0), "\n")
}

install.packages("DBCVindex")
library(DBCVindex)

result <- hdbscan(num_data, minPts = 5)
score <- dbcv_index(num_data, result$cluster)
print(score)

for (mp in c(3, 5, 10)) {
  res <- hdbscan(num_data, minPts = mp)
  if (max(res$cluster) > 0) {  # skip if no clusters found
    score <- dbcv_index(num_data, res$cluster)
    cat("minPts =", mp, "| clusters:", max(res$cluster), "| DBCV:", round(score, 4), "\n")
  } else {
    cat("minPts =", mp, "| no clusters found\n")
  }
}