# 07_plots_codecarbon.R
# Figures + summary table for the paper, from the replicate benchmark
# Input : results/codecarbon_results_reps.csv, results/benchmark_results.csv
# Output: results/fig1_energy_avg.pdf, fig2_energy_vs_size.pdf,
#         fig3_energy_heatmap.pdf, fig4_score_correlation.pdf,
#         results/summary_by_cvi.csv, results/summary_by_dataset.csv

library(ggplot2)
library(dplyr)

results_path <- "/Users/aminentezari/Desktop/R-projects/green-computing/Green-computing-research/results/"

# CO2 is recomputed from energy with one fixed grid intensity, because
# CodeCarbon's own intensity lookup was not consistent across runs.
GRID_G_PER_WH <- 0.3307   # = 330.7 g CO2-eq per kWh

sizes <- data.frame(
  dataset = c("neuroblastoma", "brain_tumor", "heart_failure", "colorectal", "sepsis"),
  n       = c(169, 173, 425, 999, 1257)
)
cvi_order <- c("CDbw", "AUCC", "DCSI", "DBCV", "DISCO")
pal <- c(CDbw = "#1b9e77", AUCC = "#7570b3", DCSI = "#d95f02",
         DBCV = "#e7298a", DISCO = "#66a61e")

cc <- read.csv(paste0(results_path, "codecarbon_results_reps.csv"))
cc <- left_join(cc, sizes, by = "dataset")
cc$energy_mWh <- cc$energy_Wh * 1000
cc$co2_mg     <- cc$energy_Wh * GRID_G_PER_WH * 1000
cc$CVI        <- factor(cc$CVI, levels = cvi_order)
cc$dataset    <- factor(cc$dataset, levels = sizes$dataset,
                        labels = paste0(sizes$dataset, " (n=", sizes$n, ")"))

se <- function(x) sd(x) / sqrt(length(x))

# ---- Summary tables ---------------------------------------------------------
# (standard errors are computed BEFORE the means overwrite the column names)
by_cvi <- cc %>%
  group_by(CVI) %>%
  summarise(runs       = n(),
            energy_se  = se(energy_mWh),
            time_se    = se(time_seconds),
            co2_mg     = mean(co2_mg),
            time_s     = mean(time_seconds),
            energy_mWh = mean(energy_mWh),
            .groups = "drop") %>%
  mutate(rel_to_CDbw = energy_mWh / energy_mWh[CVI == "CDbw"])
print(by_cvi)
write.csv(by_cvi, paste0(results_path, "summary_by_cvi.csv"), row.names = FALSE)

by_ds_se <- cc %>%
  group_by(dataset, n, CVI) %>%
  summarise(se_e   = se(energy_mWh),
            time_s = mean(time_seconds),
            mean_e = mean(energy_mWh),
            .groups = "drop")
write.csv(by_ds_se, paste0(results_path, "summary_by_dataset.csv"), row.names = FALSE)

# ---- Fig 1: mean energy per CVI --------------------------------------------
p1 <- ggplot(by_cvi, aes(x = CVI, y = energy_mWh, fill = CVI)) +
  geom_col(width = 0.65) +
  geom_errorbar(aes(ymin = energy_mWh - energy_se, ymax = energy_mWh + energy_se),
                width = 0.2) +
  scale_fill_manual(values = pal) +
  labs(x = NULL, y = "Energy per run (mWh)") +
  theme_bw(base_size = 11) +
  theme(legend.position = "none")
ggsave(paste0(results_path, "fig1_energy_avg.pdf"), p1, width = 5, height = 3.5)

# ---- Fig 2: energy vs dataset size (the key interaction) -------------------
p2 <- ggplot(by_ds_se, aes(x = n, y = mean_e, colour = CVI, group = CVI)) +
  geom_line(linewidth = 0.8) +
  geom_point(size = 2) +
  geom_errorbar(aes(ymin = mean_e - se_e, ymax = mean_e + se_e), width = 25) +
  scale_colour_manual(values = pal) +
  scale_x_continuous(breaks = c(170, 425, 999, 1257)) +
  labs(x = "Dataset size (number of patients)", y = "Energy per run (mWh)", colour = "CVI") +
  theme_bw(base_size = 11)
ggsave(paste0(results_path, "fig2_energy_vs_size.pdf"), p2, width = 6, height = 3.8)

# ---- Fig 3: heatmap dataset x CVI ------------------------------------------
p3 <- ggplot(by_ds_se, aes(x = CVI, y = dataset, fill = mean_e)) +
  geom_tile(colour = "white") +
  geom_text(aes(label = sprintf("%.2f", mean_e)), size = 3.3) +
  scale_fill_gradient(low = "white", high = "firebrick", name = "mWh") +
  labs(x = NULL, y = NULL) +
  theme_bw(base_size = 11)
ggsave(paste0(results_path, "fig3_energy_heatmap.pdf"), p3, width = 6.2, height = 3.5)

# ---- Fig 4: agreement between CVI scores (Spearman) ------------------------
bm <- read.csv(paste0(results_path, "benchmark_results.csv"))
cm <- cor(bm[, cvi_order], method = "spearman")
cm_long <- as.data.frame(as.table(cm))
names(cm_long) <- c("CVI_a", "CVI_b", "rho")
p4 <- ggplot(cm_long, aes(x = CVI_a, y = CVI_b, fill = rho)) +
  geom_tile(colour = "white") +
  geom_text(aes(label = sprintf("%.2f", rho)), size = 3.3) +
  scale_fill_gradient2(low = "#2166ac", mid = "white", high = "#b2182b",
                       midpoint = 0, limits = c(-1, 1), name = expression(rho)) +
  labs(x = NULL, y = NULL) +
  theme_bw(base_size = 11)
ggsave(paste0(results_path, "fig4_score_correlation.pdf"), p4, width = 5, height = 4)

cat("Done: 4 figures + 2 summary tables saved to results/\n")
