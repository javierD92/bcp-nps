import os
import sys
import glob
import re
import numpy as np
import matplotlib.pyplot as plt

def get_sort_key(folder_name):
    """
    Extracts integers from folder name SIM_i_j for correct numeric sorting.
    Returns (i, j) as a tuple of integers.
    """
    # Look for patterns like SIM_1_2 or SIM_10_5
    match = re.search(r'SIM_(\d+)_(\d+)', folder_name)
    if match:
        return (int(match.group(1)), int(match.group(2)))
    return (0, 0) # Fallback

def get_summary_plots(parent_dir):
    # Find all simulation folders
    sim_folders = glob.glob(os.path.join(parent_dir, 'SIM_*'))
    
    # Sort folders by the numeric values of i and j
    sim_folders.sort(key=lambda x: get_sort_key(os.path.basename(x)))
    
    if not sim_folders:
        print("No SIM_* folders found.")
        return

    # Setup Figures
    fig_e, ax_e = plt.subplots(figsize=(10, 6))
    fig_d, ax_d = plt.subplots(figsize=(10, 6))

    # Colormap for distinct lines
    colors = plt.cm.turbo(np.linspace(0, 1, len(sim_folders)))

    for i, folder in enumerate(sim_folders):
        folder_name = os.path.basename(folder)
        energy_path = os.path.join(folder, 'free_energy.dat')
        stats_path = os.path.join(folder, 'stats.dat')

        if not os.path.exists(energy_path) or not os.path.exists(stats_path):
            continue

        try:
            energy_data = np.loadtxt(energy_path)
            stats_data = np.loadtxt(stats_path)

            if energy_data.size == 0 or stats_data.size == 0:
                continue

            if len(energy_data.shape) == 1: energy_data = energy_data.reshape(1, -1)
            if len(stats_data.shape) == 1: stats_data = stats_data.reshape(1, -1)

            # --- Plot 1: Total Energy (Linear) ---
            ax_e.plot(energy_data[:, 0], energy_data[:, 4], 
                      color=colors[i], label=folder_name, alpha=0.8)

            # --- Plot 2: Domain Size (Log-Log) ---
            ax_d.loglog(stats_data[:, 0], stats_data[:, 1], 
                        '-', color=colors[i], label=folder_name, alpha=0.8)

        except Exception as e:
            print(f"Error processing {folder_name}: {e}")

    # Finalize Energy Plot
    ax_e.set_title("Total Energy Evolution (All Simulations)")
    ax_e.set_xlabel("Simulation Step")
    ax_e.set_ylabel("Total Free Energy")
    ax_e.grid(True, which="both", ls=":", alpha=0.5)
    ax_e.legend(loc='center left', bbox_to_anchor=(1, 0.5), fontsize='x-small', ncol=2 if len(sim_folders) > 15 else 1)
    fig_e.savefig(os.path.join(parent_dir, "summary_total_energy.png"), dpi=200, bbox_inches='tight')

    # Finalize Domain Size Plot
    ax_d.set_title("Domain Size Growth (Log-Log Scale)")
    ax_d.set_xlabel("Simulation Step (log)")
    ax_d.set_ylabel("Domain Size $L$ (log)")
    ax_d.grid(True, which="both", ls=":", alpha=0.5)
    ax_d.legend(loc='center left', bbox_to_anchor=(1, 0.5), fontsize='x-small', ncol=2 if len(sim_folders) > 15 else 1)
    fig_d.savefig(os.path.join(parent_dir, "summary_domain_growth.png"), dpi=200, bbox_inches='tight')

    print(f"Summary plots generated for {len(sim_folders)} folders.")
    plt.close('all')

if __name__ == "__main__":
    path = sys.argv[1] if len(sys.argv) > 1 else "."
    get_summary_plots(path)