import os
import sys
import glob
import numpy as np
import matplotlib.pyplot as plt
import utils
import plot_functions

def get_info_text(folder):
    """Original descriptive title logic: Extracts text from sweep_info.txt"""
    info_path = os.path.join(folder, 'sweep_info.txt')
    if not os.path.exists(info_path): return ""
    with open(info_path, 'r') as f:
        lines = [l.strip() for l in f if not l.startswith('#')]
        return " | ".join(lines)

def analyze_sweep(parent_dir):
    config = utils.load_plot_config()
    sim_folders = sorted(glob.glob(os.path.join(parent_dir, 'SIM_*')))
    
    for folder in sim_folders:
        params = utils.get_simulation_params(folder)
        p_files = sorted(glob.glob(os.path.join(folder, 'particles_*.txt')), key=utils.natural_sort_key)
        f_files = sorted(glob.glob(os.path.join(folder, 'field_psi_*.txt')), key=utils.natural_sort_key)
        
        if not p_files or not f_files: continue
        
        try:
            fig, ax = plt.subplots(figsize=(8, 7))
            p_data = np.loadtxt(p_files[-1], ndmin=2)
            f_data = np.loadtxt(f_files[-1])
            
            # Use the master plotting logic from plot_functions.py
            im, _, _ = plot_functions.plot_simulation_state(ax, p_data, f_data, params, config)
            
            # CORRECT TITLE: Restoration of the original folder + sweep_info.txt format
            info = get_info_text(folder)
            ax.set_title(f"Folder: {os.path.basename(folder)}\n{info}")
            
            plt.colorbar(im, ax=ax, label=r'Field $\psi / \psi_{eq}$')
            
            save_name = f"snap_{os.path.basename(folder)}.png"
            plt.savefig(os.path.join(parent_dir, save_name), dpi=200, bbox_inches='tight')
            plt.close()
            print(f"Saved {save_name}")
            
        except Exception as e:
            print(f"Error in {folder}: {e}")

if __name__ == "__main__":
    path = sys.argv[1] if len(sys.argv) > 1 else "."
    analyze_sweep(path)