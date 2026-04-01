import os
import sys
import glob
import re  # Added for regex
import numpy as np
import matplotlib.pyplot as plt
import plot_config as cfg

def get_info_text(folder):
    info_path = os.path.join(folder, 'sweep_info.txt')
    if not os.path.exists(info_path): return ""
    with open(info_path, 'r') as f:
        lines = [l.strip() for l in f if not l.startswith('#')]
        return " | ".join(lines)

def sort_by_timestep(file_list):
    """Sorts a list of file paths by the last integer found in the filename."""
    def extract_number(filepath):
        numbers = re.findall(r'\d+', os.path.basename(filepath))
        return int(numbers[-1]) if numbers else 0
    
    return sorted(file_list, key=extract_number)

def analyze_sweep(parent_dir):
    sim_folders = sorted(glob.glob(os.path.join(parent_dir, 'SIM_*')))
    
    for folder in sim_folders:
        LX, LY = cfg.get_params(folder)
        
        # Grab and sort files numerically by timestep
        p_files = sort_by_timestep(glob.glob(os.path.join(folder, 'particles_*.txt')))
        f_files = sort_by_timestep(glob.glob(os.path.join(folder, 'field_psi_*.txt')))
        
        if not p_files or not f_files: 
            print(f"Skipping {folder}: Files missing.")
            continue
        
        try:
            # Now p_files[-1] is guaranteed to be the highest timestep
            print(f"Processing latest: {p_files[-1]}")
            
            p_data = np.loadtxt(p_files[-1])
            f_data = np.loadtxt(f_files[-1])
            psi = cfg.reshape_field(f_data, LX, LY)

            fig, ax = plt.subplots(figsize=(8, 7))
            
            # 1. Plot Field
            im = ax.imshow(psi, extent=[0, LX, 0, LY], origin='lower',
                           cmap=cfg.CMAP, vmin=cfg.V_MIN, vmax=cfg.V_MAX)
            
            if not p_data.size == 0:
                # 2. Plot Particles (Scatter)
                ax.scatter(p_data[:, 0], p_data[:, 1], c=cfg.PARTICLE_COLOR,
                        edgecolors='black', s=20, zorder=3)

                # 3. Plot Orientations (Quiver Arrows)
                u, v = np.cos(p_data[:, 2]), np.sin(p_data[:, 2])
                ax.quiver(p_data[:, 0], p_data[:, 1], u, v, 
                        color=cfg.ARROW_COLOR, pivot='mid', 
                        scale=cfg.ARROW_SCALE, width=cfg.ARROW_WIDTH, zorder=4)

            info = get_info_text(folder)
            ax.set_title(f"Folder: {os.path.basename(folder)}\n{info}")
            plt.colorbar(im, ax=ax, label=r'Field $\psi$')

            save_name = f"snap_{os.path.basename(folder)}.png"
            plt.savefig(os.path.join(parent_dir, save_name), dpi=200, bbox_inches='tight')
            plt.close()
            print(f"Generated: {save_name}")

        except Exception as e:
            print(f"Error in {folder}: {e}")

if __name__ == "__main__":
    # Ensure a path is provided or default to current directory
    path = sys.argv[1] if len(sys.argv) > 1 else "."
    analyze_sweep(path)