# 06_benchmark.R
# Full benchmark: all datasets x all minPts x all CVIs + plots

library(dbscan)
library(DBCVindex)
library(fpc)
library(clusterConfusion)
library(discoCVI)
library(pegas)
library(clusterCrit)
library(ggplot2)
library(tidyr)
library(dplyr)

# Download DCSI functions (once)
download.file(
  "https://raw.githubusercontent.com/JanaGauss/dcsi/main/code/functions/separability_functions.R",
  destfile = "separability_functions.R"
)

# Dataset paths
datasets <- list(
  neuroblastoma = "/Users/aminentezari/Desktop/R-projects/green-computing/Green-computing-research/data/10_7717_peerj_5665_dataYM2018_neuroblastoma.csv",
  brain_tumor   = "/Users/aminentezari/Desktop/R-projects/green-computing/Green-computing-research/data/dataset_Belgrade2021_pediatric_brain_tumor_plos_one_0259095_cleaned.csv",
  colorectal    = "/Users/aminentezari/Desktop/R-projects/green-computing/Green-computing-research/data/dataset_Taipei2018_colorectal_cancer_EHRs_plos_one_0200893_final_cleaned.csv",
  sepsis        = "/Users/aminentezari/Desktop/R-projects/green-computing/Green-computing-research/data/journal.pone.0148699_S1_Text_Sepsis_SIRS_EDITED.csv",
  heart_failure = "/Users/aminentezari/Desktop/R-projects/green-computing/Green-computing-research/data/journal.pone.0158570_S2File_depression_heart_failure.csv"
)

minPts_values <- c(3, 5, 10, 15, 20)
results <- data.frame()

for (ds_name in names(datasets)) {
  cat("Dataset:", ds_name, "\n")
  raw <- read.csv(datasets[[ds_name]])
  num_data <- raw[, sapply(raw, is.numeric)]
  num_data <- num_data[, colSums(is.na(num_data)) == 0]
  num_data <- num_data[complete.cases(num_data), ]
  num_data <- scale(num_data)
  num_data <- num_data[, apply(num_data, 2, function(x) !any(is.nan(x) | is.infinite(x)))]
  
  for (mp in minPts_values) {
    cat("  minPts =", mp, "\n")
    res <- hdbscan(num_data, minPts = mp)
    n_clusters <- max(res$cluster)
    n_noise <- sum(res$cluster == 0)
    
    if (n_clusters < 2) {
      cat("  Skipping: fewer than 2 clusters\n")
      next
    }
    
    # DBCV
    dbcv_val <- as.numeric(tryCatch(dbcv_index(num_data, res$cluster), error = function(e) NA))[1]
    
    # DCSI
    mask <- res$cluster != 0
    clean_df <- as.data.frame(apply(num_data[mask, ], 2, as.double))
    char_labels <- paste0("C", res$cluster[mask])
    dcsi_val <- as.numeric(tryCatch({
      source("separability_functions.R")
      s <- calc_sep_all(data = clean_df, labels = char_labels)
      s$value[s$measure == "DCSI"]
    }, error = function(e) {
      cat("    DCSI error:", e$message, "\n")
      NA
    }))[1]
    
    # CDbw
    cdbw_val <- as.numeric(tryCatch(cdbw(num_data, res$cluster)$cdbw, error = function(e) NA))[1]
    
    # AUCC
    aucc_val <- as.numeric(tryCatch(aucc(res$cluster, dataset = as.data.frame(num_data)), error = function(e) NA))[1]
    
    # DISCO
    disco_val <- as.numeric(tryCatch(disco_score(num_data, res$cluster), error = function(e) NA))[1]
    
    results <- rbind(results, data.frame(
      dataset    = ds_name,
      minPts     = mp,
      n_clusters = n_clusters,
      n_noise    = n_noise,
      DBCV       = dbcv_val,
      DCSI       = dcsi_val,
      CDbw       = cdbw_val,
      AUCC       = aucc_val,
      DISCO      = disco_val
    ))
  }
}

# Save results
write.csv(results,
          "/Users/aminentezari/Desktop/R-projects/green-computing/Green-computing-research/results/benchmark_results.csv",
          row.names = FALSE)
print(results)

# ── Plots ──────────────────────────────────────────────────────────────────────

results_long <- results %>%
  pivot_longer(cols = c(DBCV, DCSI, CDbw, AUCC, DISCO),
               names_to = "CVI", values_to = "score")

# Plot 1: CVI scores by minPts for each dataset
p1 <- ggplot(results_long, aes(x = factor(minPts), y = score, color = CVI, group = CVI)) +
  geom_line() +
  geom_point() +
  facet_wrap(~ dataset, scales = "free_y") +
  labs(title = "CVI Scores vs minPts by Dataset",
       x = "minPts", y = "Score") +
  theme_bw()

ggsave("/Users/aminentezari/Desktop/R-projects/green-computing/Green-computing-research/results/plot_cvi_vs_minpts.pdf",
       p1, width = 12, height = 8)

# Plot 2: Heatmap (minPts = 5 only)
results_mp5 <- results %>% filter(minPts == 5)
results_mp5_long <- results_mp5 %>%
  pivot_longer(cols = c(DBCV, DCSI, CDbw, AUCC, DISCO),
               names_to = "CVI", values_to = "score")

p2 <- ggplot(results_mp5_long, aes(x = CVI, y = dataset, fill = score)) +
  geom_tile(color = "white") +
  geom_text(aes(label = round(score, 3)), size = 3) +
  scale_fill_gradient(low = "white", high = "steelblue") +
  labs(title = "CVI Scores Heatmap (minPts = 5)",
       x = "CVI", y = "Dataset") +
  theme_bw()

ggsave("/Users/aminentezari/Desktop/R-projects/green-computing/Green-computing-research/results/plot_heatmap_mp5.pdf",
       p2, width = 8, height = 5)

# Plot 3: Number of clusters
p3 <- ggplot(results, aes(x = factor(minPts), y = n_clusters, fill = dataset)) +
  geom_bar(stat = "identity", position = "dodge") +
  labs(title = "Number of Clusters Found by HDBSCAN",
       x = "minPts", y = "Number of Clusters") +
  theme_bw()

ggsave("/Users/aminentezari/Desktop/R-projects/green-computing/Green-computing-research/results/plot_n_clusters.pdf",
       p3, width = 10, height = 5)

cat("\nDone! Results and plots saved to results/\n")