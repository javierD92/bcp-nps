import os
import sys
import glob
import re
# Import the function from the other file
from droplet_cluster_analysis import run_droplet_analysis

def get_sort_key(folder_name):
    match = re.search(r'SIM_(\d+)_(\d+)', folder_name)
    if match:
        return (int(match.group(1)), int(match.group(2)))
    return (0, 0)

def process_all_simulations(parent_dir, threshold=0.0, min_size=1):
    # Find all simulation folders
    sim_folders = glob.glob(os.path.join(parent_dir, 'SIM_*'))
    sim_folders.sort(key=lambda x: get_sort_key(os.path.basename(x)))
    
    if not sim_folders:
        print(f"No SIM_* folders found in {parent_dir}")
        return

    print(f"Found {len(sim_folders)} folders. starting batch analysis...")

    for folder in sim_folders:
        folder_name = os.path.basename(folder)
        try:
            print(f"Processing: {folder_name}...", end="\r")
            # Call the imported function
            run_droplet_analysis(folder, threshold=threshold, min_size=min_size)
        except Exception as e:
            print(f"\nError in {folder_name}: {e}")

    print(f"\nBatch processing complete for {parent_dir}")

if __name__ == "__main__":
    # Usage: python batch_analyze.py /path/to/sims [threshold] [min_size]
    path = sys.argv[1] if len(sys.argv) > 1 else "."
    thresh = float(sys.argv[2]) if len(sys.argv) > 2 else 0.0
    size_limit = int(sys.argv[3]) if len(sys.argv) > 3 else 1
    
    process_all_simulations(path, threshold=thresh, min_size=size_limit)