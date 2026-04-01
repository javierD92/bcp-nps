import numpy as np
import matplotlib.pyplot as plt
import glob
import sys
import os
import re
import utils
import plot_functions

# --- 1. Load Data ---
data_path = sys.argv[1] if len(sys.argv) > 1 and sys.argv[1] != "--save" else "."
save_frames = "--save" in sys.argv

params = utils.get_simulation_params(data_path)
config = utils.load_plot_config()

LX, LY = params['lx'], params['ly']
DT, RADIUS = params['dt'], params['reff']
PSI_EQ = np.sqrt(params['tau'] / params['u'])

p_files = sorted(glob.glob(os.path.join(data_path, 'particles_*.txt')), key=utils.natural_sort_key)
f_files = sorted(glob.glob(os.path.join(data_path, 'field_psi_*.txt')), key=utils.natural_sort_key)

if not p_files or not f_files:
    print(f"No files found in {data_path}"); sys.exit(1)

# --- 2. Setup ---
if save_frames: plt.ioff()
else: plt.ion()

fig, ax = plt.subplots(figsize=(8, 7))
p_init = np.loadtxt(p_files[0], ndmin=2)
f_init = np.loadtxt(f_files[0])

# Framework call for initialization
im, pc, qvr = plot_functions.plot_simulation_state(ax, p_init, f_init, params, config)

ax.set_title(f"Reff: {RADIUS} | {os.path.basename(os.path.abspath(data_path))}")
plt.colorbar(im, ax=ax, label=r'Field $\psi / \psi_{eq}$')

# --- 3. Loop ---
for i, (pf, ff) in enumerate(zip(p_files, f_files)):
    try:
        p_curr = np.loadtxt(pf, ndmin=2)
        f_curr = np.loadtxt(ff)
    except: continue
    
    # In-place updates for performance
    im.set_array(utils.reshape_field(f_curr, LX, LY) / PSI_EQ)
    
    if pc: pc.remove()
    if p_curr.size > 0:
        pc = plot_functions.get_particle_collection(p_curr, RADIUS, config)
        ax.add_collection(pc)
        qvr.set_visible(True)
        qvr.set_offsets(p_curr[:, :2])
        qvr.set_UVC(np.cos(p_curr[:, 2]), np.sin(p_curr[:, 2]))
    else:
        qvr.set_visible(False)

    try:
        step = int(re.findall(r'\d+', os.path.basename(pf))[0])
        ax.set_xlabel(f"Step: {step} | Time: {step * DT:.2f}")
    except: pass
    
    if save_frames:
        plt.savefig(os.path.join(data_path, f"snap_{i:04d}.png"), dpi=150)
    else:
        plt.draw()
        plt.pause(0.01)