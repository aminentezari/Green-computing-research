#
# Code snippet written by Davide Chicco <davidechicco@davidechicco.it> on 25th March 2026
# Tested on Linux Xubuntu 24.04.4 LTS with Python 3.11.9
#
import subprocess
import sys
import time  # <-- Added for timing

# --- Upgrade pip ---
bash_command = sys.executable + " -m pip install --upgrade pip"
print("bash_command:\n", bash_command)
result = subprocess.run(bash_command, shell=True, capture_output=True, text=True)

# --- Ensure CodeCarbon is installed ---
libraries = ["codecarbon"]

for lib in libraries:
    try:
        __import__(lib)
        print(f"{lib} is already installed.")
    except ImportError:
        print(f"{lib} not found. Installing...")
        subprocess.check_call([sys.executable, "-m", "pip", "install", lib])

print("output:\t", result.stdout)
if result.stderr:
    print("errors:\t", result.stderr)

input_str = ""
# Check if an argument was provided
if len(sys.argv) > 1:
    # Read the first argument (excluding the script name)
    input_arg = sys.argv[1]
    # Cast to string (redundant, since it's already a string)
    input_str = str(input_arg)
    print(f"Input argument as string: {input_str}")
else:
    print("No input argument provided.")

# --- Import after install ---
from codecarbon import EmissionsTracker
import shlex

# =========================
# Run your software code
# =========================
tracker = EmissionsTracker(
    log_level="error",
    save_to_file=False
)
tracker.start()

# --- Measure execution time ---
start_time = time.time()

this_command = input_str
args = shlex.split(this_command)
subprocess.run(this_command, shell=True)

end_time = time.time()
execution_time = end_time - start_time

emissions = tracker.stop() * 1000
energy_wh = tracker._total_energy.kWh * 1000

print(f"\n~ : ~ consumption measured through CodeCarbon ~ : ~")
print(f"external script energy: {energy_wh:.20f} Wh")
print(f"external script emissions: {emissions:.20f} CO\u2082eq grams")
print(f"external script execution time: {execution_time:.20f} seconds")
print(f"~ : ~ : ~ : ~ : ~ : ~ : ~")
