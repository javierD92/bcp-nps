import numpy as np
from scipy import ndimage
from skimage import measure
import matplotlib.pyplot as plt
import os
import re
from matplotlib.colors import ListedColormap

def get_pbc_centroid(coords, L):
    """Calculates centroid of points on a periodic domain of size L."""
    theta = (coords / L) * 2 * np.pi
    xi = np.mean(np.cos(theta))
    zeta = np.mean(np.sin(theta))
    mean_theta = np.arctan2(-zeta, -xi) + np.pi
    return (L * mean_theta) / (2 * np.pi)

def get_droplet_labels(psi_field, threshold=0.0):
    """Labels droplets using 8-connectivity and stitches across Periodic Boundaries."""
    binary_mask = (psi_field < threshold).astype(int)
    s = np.ones((3,3))
    labels, _ = ndimage.label(binary_mask, structure=s)
    
    rows, cols = binary_mask.shape
    for j in range(cols):
        if binary_mask[0, j] and binary_mask[-1, j]:
            labels[labels == labels[-1, j]] = labels[0, j]
    for i in range(rows):
        if binary_mask[i, 0] and binary_mask[i, -1]:
            labels[labels == labels[i, -1]] = labels[i, 0]

    unique_labels = np.unique(labels)
    relabeled = np.zeros_like(labels)
    new_id = 1
    for old_id in unique_labels:
        if old_id == 0: continue
        relabeled[labels == old_id] = new_id
        new_id += 1
    return relabeled

def run_droplet_analysis(input_folder, threshold=0.0, min_size=1):
    # 1. Collect and sort files (same as before)
    files = [f for f in os.listdir(input_folder) if f.startswith("field_psi_") and f.endswith(".txt")]
    if not files:
        print(f"No valid files found in {input_folder}")
        return
        
    files.sort(key=lambda f: int(re.findall(r'\d+', f)[0]))
    aggregate_areas = []

    print(f"Analyzing {input_folder} | Threshold: {threshold} | Min Size: {min_size}")

    # --- 2. Main Processing Loop ---
    for idx, file in enumerate(files):
        time_val = re.findall(r'\d+', file)[0]
        raw_data = np.loadtxt(os.path.join(input_folder, file))
        
        grid_size = int(np.sqrt(raw_data.shape[0]))
        psi = np.reshape(raw_data[:, 2], (grid_size, grid_size))
        
        labeled_field = get_droplet_labels(psi, threshold=threshold)
        
        # ADDED: perimeter is now included in the properties
        props = measure.regionprops(labeled_field)
        
        frame_stats = []
        for p in props:
            if p.area <= min_size:
                continue
                
            cy = get_pbc_centroid(p.coords[:, 0], grid_size)
            cx = get_pbc_centroid(p.coords[:, 1], grid_size)
            
            # MODIFIED: Extract p.perimeter
            # p.perimeter uses a 4-connectivity boundary tracing
            frame_stats.append([p.area, p.perimeter, cy, cx])
            aggregate_areas.append(p.area)
        
        # UPDATED: Save per-frame CSV with the perimeter column
        csv_name = f"droplet_stats_t{time_val}.csv"
        np.savetxt(os.path.join(input_folder, csv_name), frame_stats, 
                   delimiter=',', 
                   header="area,perimeter,centroid_y,centroid_x", # Added perimeter to header
                   comments='')

        # --- 3. Visualization ---
        if idx == len(files) - 1:
            plt.figure(figsize=(12, 12))
            num_ids = labeled_field.max()
            np.random.seed(42)
            colors = np.random.rand(num_ids + 1, 3)
            colors[0] = [0, 0, 0] 
            
            for p in props:
                if p.area <= min_size:
                    colors[p.label] = [0, 0, 0]
            
            plt.imshow(labeled_field, cmap=ListedColormap(colors), interpolation='nearest')

            # UPDATED: Unpack 4 values instead of 3
            for area, perimeter, cy, cx in frame_stats:
                # Labeling with area; you could change this to str(int(perimeter)) if preferred
                plt.text(cx, cy, f"A:{int(area)}\nP:{int(perimeter)}", color='white', fontsize=6,
                         ha='center', va='center', fontweight='bold',
                         bbox=dict(facecolor='black', alpha=0.5, lw=0, pad=0.1))

            plt.title(f"Filtered Analysis (Area > {min_size}) | Time: {time_val}")
            plt.axis('off')
            plt.savefig(os.path.join(input_folder, "final_frame_filtered.png"), dpi=300)
            plt.close()

    # --- 4. Plot Aggregate Size Distribution ---
    if aggregate_areas:
        plt.figure(figsize=(10, 6))
        plt.hist(aggregate_areas, bins=100, color='teal', edgecolor='white')
        plt.yscale('log')
        plt.title(f"Aggregate Size Distribution (Area > {min_size})")
        plt.xlabel("Area (pixels)")
        plt.ylabel("Frequency (Log Scale)")
        plt.grid(True, which="both", ls="-", alpha=0.2)
        plt.savefig(os.path.join(input_folder, "aggregate_distribution_filtered.png"))
        plt.close()

    print(f"Analysis complete. Files saved in {input_folder}")


import argparse

if __name__ == "__main__":
    # Create the parser
    parser = argparse.ArgumentParser(
        description="Analyze droplet statistics from simulation data with PBC stitching."
    )

    # Add arguments
    parser.add_argument(
        "target_dir", 
        type=str, 
        help="Path to the directory containing the simulation .txt files"
    )
    parser.add_argument(
        "--threshold", 
        type=float, 
        default=0.0, 
        help="Threshold value for droplet identification (default: 0.0)"
    )
    parser.add_argument(
        "--min_size", 
        type=int, 
        default=1, 
        help="Minimum area size to include a droplet (default: 1)"
    )

    # Parse the arguments from the command line
    args = parser.parse_args()

    # Run the analysis using the parsed arguments
    run_droplet_analysis(
        input_folder=args.target_dir, 
        threshold=args.threshold, 
        min_size=args.min_size
    )