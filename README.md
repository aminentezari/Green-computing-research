# Green-computing-research

Energy consumption, CO₂ emissions and execution time of five density-based
internal clustering validity indices — **DISCO, DBCV, DCSI, CDbw, AUCC** —
measured with [CodeCarbon](https://github.com/mlco2/codecarbon) on five
public biomedical datasets clustered with HDBSCAN.

Amin Entezari, Davide Chicco — Università di Milano-Bicocca

## Main findings

- Averaged over 525 runs, the indices differ about 2× (CDbw 0.74 mWh → DISCO 1.52 mWh per run).
- Cost depends on dataset size: DBCV and DISCO are the cheapest on ~170 patients but grow ~9× on 1000–1250 patients; CDbw and AUCC stay almost flat.
- AUCC agrees closely with DISCO (ρ = 0.92) and DBCV (ρ = 0.75); CDbw is cheap but disagrees with all other indices.
- Computing DCSI via `calc_sep_all()` (which evaluates ~20 measures) overstates its cost about 10×.

## Repository structure

```
data/      5 public biomedical datasets (CSV)
src/       cvi_*.R                            one script per index (args: dataset minPts)
           run_benchmark_codecarbon.R         driver: 21 configs x 5 CVIs x 5 replicates
           code_carbon_on_external_script.py  CodeCarbon wrapper around Rscript
           benchmark.R                        computes the CVI scores
           07_plots_codecarbon.R              figures and summary tables
results/   codecarbon_results_reps.csv        final energy measurements (525 runs)
           benchmark_results.csv              CVI scores
           summary_by_cvi.csv, summary_by_dataset.csv
           fig1-fig4 *.pdf                    figures
           codecarbon_results_preliminary.csv first run (DCSI via calc_sep_all)
```

## Reproduce

Requirements: R ≥ 4.5 and Python 3 with `codecarbon`.

```r
install.packages(c("dbscan", "discoCVI", "DBCVindex", "fpc", "pegas", "proxy",
                   "cccd", "igraph", "matrixcalc", "dplyr", "stringr", "ggplot2"))
remotes::install_github("pajaskowiak/clusterConfusion")
```

DCSI uses the authors' reference code (Gauss et al., arXiv:2310.12806).
Download it into `src/`:

```bash
cd src
curl -O https://raw.githubusercontent.com/JanaGauss/dcsi/main/code/functions/separability_functions.R
```

Run the benchmark and the plots:

```bash
cd src
Rscript run_benchmark_codecarbon.R
Rscript 07_plots_codecarbon.R
```

## Datasets

All datasets are public supplementary material of PLOS ONE and PeerJ
articles; please cite the original publications when reusing them.

## License

MIT
