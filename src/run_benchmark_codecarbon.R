# run_benchmark_codecarbon.R  (v2: replicates + skip invalid configs)

setwd("/Users/aminentezari/Desktop/R-projects/green-computing/Green-computing-research/src")

datasets      <- c("neuroblastoma", "brain_tumor", "colorectal", "sepsis", "heart_failure")
minPts_values <- c(3, 5, 10, 15, 20)
cvi_scripts   <- c(DBCV = "cvi_dbcv.R", DCSI = "cvi_dcsi.R", CDbw = "cvi_cdbw.R",
                   AUCC = "cvi_aucc.R", DISCO = "cvi_disco.R")
N_REPS <- 5

# configurations where HDBSCAN found < 2 clusters -> no CVI to measure
skip <- c("neuroblastoma_15", "neuroblastoma_20", "brain_tumor_20", "heart_failure_20")

out_path <- "../results/codecarbon_results_reps.csv"
write.csv(data.frame(rep = integer(), dataset = character(), minPts = integer(),
                     CVI = character(), energy_Wh = numeric(), co2_grams = numeric(),
                     time_seconds = numeric()),
          out_path, row.names = FALSE)

# pull the number after a label like "energy:" from the wrapper output
get_value <- function(lines, label) {
  hit <- grep(label, lines, fixed = TRUE, value = TRUE)
  if (length(hit) == 0) return(NA)
  as.numeric(strsplit(trimws(sub(paste0(".*", label), "", hit[1])), " ")[[1]][1])
}

for (rep in 1:N_REPS) {
  for (dataset in datasets) {
    for (mp in minPts_values) {
      if (paste0(dataset, "_", mp) %in% skip) next
      for (cvi_name in names(cvi_scripts)) {
        cat("rep", rep, "|", cvi_name, "|", dataset, "| minPts", mp, "\n")
        cmd <- paste("Rscript", cvi_scripts[[cvi_name]], dataset, mp)
        out <- system2("python3",
                       args = c("code_carbon_on_external_script.py", shQuote(cmd)),
                       stdout = TRUE, stderr = FALSE)
        row <- data.frame(rep = rep, dataset = dataset, minPts = mp, CVI = cvi_name,
                          energy_Wh    = get_value(out, "energy:"),
                          co2_grams    = get_value(out, "emissions:"),
                          time_seconds = get_value(out, "execution time:"))
        # append row by row so progress is saved if it stops
        write.table(row, out_path, sep = ",", append = TRUE,
                    col.names = FALSE, row.names = FALSE)
      }
    }
  }
}

cat("Done ->", out_path, "\n")