import argparse
from pathlib import Path
import sys

# Import the logic from your existing script
try:
    from txt_to_vtk import convert, extract_time_and_key
    from get_params import get_params
except ImportError:
    print("Error: Ensure txt_to_vtk_loop_angles.py and get_params.py are in this folder.")
    sys.exit(1)

def process_parent_folder(parent_path, dx, dy):
    parent_dir = Path(parent_path)
    
    # Find all subfolders matching the SIM_*_* pattern
    sim_folders = sorted(list(parent_dir.glob("SIM_*_*")))

    if not sim_folders:
        print(f"No folders matching 'SIM_*_*' found in {parent_dir}")
        return

    print(f"Found {len(sim_folders)} simulation folders.")

    for sim_dir in sim_folders:
        print(f"\n--- Processing: {sim_dir.name} ---")
        
        # 1. Get params automatically for this specific subfolder
        lx, ly, tau, u, dt = get_params(str(sim_dir))
        
        # 2. Map the files inside this subfolder
        pol_map = {}
        colls_map = {}

        for f in sim_dir.glob("field_psi_*.txt"):
            t_int, t_key = extract_time_and_key(f)
            if t_key: pol_map[t_key] = (t_int, f)

        for f in sim_dir.glob("particles_*.txt"):
            t_int, t_key = extract_time_and_key(f)
            if t_key: colls_map[t_key] = (t_int, f)

        common_keys = sorted(set(pol_map) & set(colls_map), key=lambda k: pol_map[k][0])

        if not common_keys:
            print(f"   No valid file pairs in {sim_dir.name}. Skipping.")
            continue

        # 3. Run conversion for every timestep
        for i, key in enumerate(common_keys, 1):
            print(f"   [{i}/{len(common_keys)}] t = {key}", end='\r')
            convert(
                pol_map[key][1], 
                colls_map[key][1], 
                key, 
                lx, ly, dx, dy, 
                sim_dir
            )
        print(f"\n   Finished {sim_dir.name}")

if __name__ == "__main__":
    parser = argparse.ArgumentParser(description="Batch convert SIM_*_* folders to VTK")
    parser.add_argument("parent_dir", type=str, help="Folder containing the SIM_*_* subfolders")
    parser.add_argument("--dx", type=float, default=1.0)
    parser.add_argument("--dy", type=float, default=1.0)

    args = parser.parse_args()
    process_parent_folder(args.parent_dir, args.dx, args.dy)