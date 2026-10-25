import subprocess
import csv

datasets = ["neuroblastoma", "brain_tumor", "colorectal", "sepsis", "heart_failure"]
minPts_values = [3, 5, 10, 15, 20]
cvi_scripts = {
    "DBCV":  "cvi_dbcv.R",
    "DCSI":  "cvi_dcsi.R",
    "CDbw":  "cvi_cdbw.R",
    "AUCC":  "cvi_aucc.R",
    "DISCO": "cvi_disco.R"
}

results = []

for dataset in datasets:
    for mp in minPts_values:
        for cvi_name, script in cvi_scripts.items():
            print(f"Running {cvi_name} | dataset: {dataset} | minPts: {mp}")
            cmd = f"Rscript {script} {dataset} {mp}"
            output = subprocess.run(
                ["python3", "code_carbon_on_external_script.py", cmd],
                capture_output=True, text=True
            )
            energy, co2, time_s = None, None, None
            for line in output.stdout.split("\n"):
                if "energy:" in line:
                    energy = float(line.split("energy:")[1].strip().split()[0])
                if "emissions:" in line:
                    co2 = float(line.split("emissions:")[1].strip().split()[0])
                if "execution time:" in line:
                    time_s = float(line.split("execution time:")[1].strip().split()[0])
            print(f"  energy: {energy} Wh | co2: {co2} g | time: {time_s}s")
            results.append({
                "dataset": dataset,
                "minPts": mp,
                "CVI": cvi_name,
                "energy_Wh": energy,
                "co2_grams": co2,
                "time_seconds": time_s
            })

out_path = "../results/codecarbon_results.csv"
with open(out_path, "w", newline="") as f:
    writer = csv.DictWriter(f, fieldnames=results[0].keys())
    writer.writeheader()
    writer.writerows(results)

print(f"\nDone! Results saved to {out_path}")
