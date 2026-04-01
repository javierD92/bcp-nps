import os
import sys
import glob
import numpy as np
import matplotlib.pyplot as plt

def get_info_text(folder):
    """Reads the simulation parameters from sweep_info.txt for the plot title."""
    info_path = os.path.join(folder, 'sweep_info.txt')
    if not os.path.exists(info_path): return ""
    with open(info_path, 'r') as f:
        # Skip comments and join lines with a pipe separator
        lines = [l.strip() for l in f if l.strip() and not l.startswith('#')]
        return " | ".join(lines)

def analyze_stats(parent_dir):
    # Find all simulation folders
    sim_folders = sorted(glob.glob(os.path.join(parent_dir, 'SIM_*')))
    
    for folder in sim_folders:
        folder_name = os.path.basename(folder)
        energy_path = os.path.join(folder, 'free_energy.dat')
        stats_path = os.path.join(folder, 'stats.dat')

        # Check if files exist
        if not os.path.exists(energy_path) or not os.path.exists(stats_path):
            print(f"Skipping {folder_name}: Data files missing.")
            continue

        try:
            # 1. Load Data (skiprows=1 to skip the # Header)
            energy_data = np.loadtxt(energy_path)
            stats_data = np.loadtxt(stats_path)

            # Ensure data isn't empty (only header exists)
            if energy_data.size == 0 or stats_data.size == 0:
                print(f"Skipping {folder_name}: Files are empty.")
                continue

            # Handle case where file has only 1 row (numpy loads it as 1D array)
            if len(energy_data.shape) == 1: energy_data = energy_data.reshape(1, -1)
            if len(stats_data.shape) == 1: stats_data = stats_data.reshape(1, -1)

            steps_e = energy_data[:, 0]
            steps_s = stats_data[:, 0]

            # Create a 2-panel figure
            fig, (ax1, ax2) = plt.subplots(2, 1, figsize=(10, 8), sharex=True)

            # --- Panel 1: Energy Evolution ---
            # Columns: 0:Step, 1:Field, 2:PP, 3:Coupling, 4:Total
            ax1.plot(steps_e, energy_data[:, 4], 'k-',  lw=2, label='Total Energy')
            ax1.plot(steps_e, energy_data[:, 1], 'r--', lw=1, label='Field')
            ax1.plot(steps_e, energy_data[:, 2], 'b--', lw=1, label='Particle-Particle')
            ax1.plot(steps_e, energy_data[:, 3], 'g--', lw=1, label='Coupling')
            
            ax1.set_ylabel('Energy')
            # Add the info text to the title
            info = get_info_text(folder)
            ax1.set_title(f"Folder: {folder_name}\n{info}", fontsize=10)
            ax1.legend(loc='best', fontsize='small', ncol=2)
            ax1.grid(True, linestyle=':', alpha=0.6)

            # --- Panel 2: Domain Size Growth ---
            # Columns: 0:Step, 1:Domain_Size
            ax2.plot(steps_s, stats_data[:, 1], 'o-', color='purple', markersize=3, label='Domain Size')
            ax2.set_xlabel('Simulation Step')
            ax2.set_ylabel('Domain Size ($L$)')
            ax2.legend(loc='lower right')
            ax2.grid(True, linestyle=':', alpha=0.6)

            # Adjust layout and save
            plt.tight_layout()
            save_path = os.path.join(parent_dir, f"plot_stats_{folder_name}.png")
            plt.savefig(save_path, dpi=200, bbox_inches='tight')
            plt.close()
            print(f"Generated dashboard: {save_path}")

        except Exception as e:
            print(f"Error analyzing {folder_name}: {e}")

if __name__ == "__main__":
    path = sys.argv[1] if len(sys.argv) > 1 else "."
    analyze_stats(path)