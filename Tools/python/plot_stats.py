import numpy as np
import matplotlib.pyplot as plt
import os
import sys

# --- Path Handling ---
data_path = sys.argv[1] if len(sys.argv) > 1 else "."
energy_file = os.path.join(data_path, 'free_energy.dat')
stats_file = os.path.join(data_path, 'stats.dat')

# Check if files exist
for f in [energy_file, stats_file]:
    if not os.path.exists(f):
        print(f"Error: '{f}' not found.")
        sys.exit(1)

# --- Load Data ---
try:
    # Load Energy Data
    e_data = np.loadtxt(energy_file)
    e_step = e_data[:, 0]
    e_field, e_pp, e_coupling, e_total = e_data[:, 1], e_data[:, 2], e_data[:, 3], e_data[:, 4]

    # Load Stats Data (Domain Size)
    s_data = np.loadtxt(stats_file)
    s_step = s_data[:, 0]
    domain_size = s_data[:, 1]
except Exception as e:
    print(f"Error reading data files: {e}")
    sys.exit(1)

# --- Palette & Styling ---
colors = {
    'field':    '#E69F00', # Orange
    'pp':       '#56B4E9', # Sky Blue
    'coupling': '#009E73', # Bluish Green
    'total':    '#000000', # Black
    'domain':   '#CC79A7'  # Reddish Purple
}

fig, (ax1, ax2) = plt.subplots(1, 2, figsize=(14, 6))

# --- Plot 1: Energy Evolution ---
ax1.plot(e_step, e_field, label='Field', color=colors['field'], lw=2)
ax1.plot(e_step, e_pp, label='WCA (PP)', color=colors['pp'], ls='--', lw=2)
ax1.plot(e_step, e_coupling, label='Coupling', color=colors['coupling'], ls=':', lw=2.5)
ax1.plot(e_step, e_total, label='Total', color=colors['total'], ls='-.', lw=1.5)

ax1.set_title("Energy Components")
ax1.set_xlabel("Step")
ax1.set_ylabel("Energy")
ax1.grid(True, alpha=0.2)
ax1.legend(loc='best', frameon=True)

# --- Plot 2: Domain Size (Log-Log) ---
# Filter zeros for log-log plot stability
valid = (s_step > 0) & (domain_size > 0)
t_val = s_step[valid]
R_val = domain_size[valid]

ax2.loglog(t_val, R_val, color=colors['domain'], lw=3, label='Domain Size $R(t)$')

# Add Theoretical LSW Slope (t^1/3) for reference
if len(t_val) > 0:
    # Anchor the theoretical line to the 10th data point or middle to avoid transient noise
    idx = min(10, len(t_val)-1) 
    ref_growth = R_val[idx] * (t_val / t_val[idx])**(1/3)
    ax2.loglog(t_val, ref_growth, color='gray', ls='--', alpha=0.6, label='LSW Theory ($t^{1/3}$)')

ax2.set_title("Domain Growth (Log-Log)")
ax2.set_xlabel("Step (log)")
ax2.set_ylabel("Size (log)")
ax2.grid(True, which="both", alpha=0.2)
ax2.legend(loc='best', frameon=True)



plt.tight_layout()

# --- Save ---
save_name = os.path.join(data_path, 'combined_analysis.png')
plt.savefig(save_name, dpi=300, bbox_inches='tight')
print(f"Saved combined plot to: {save_name}")

plt.show()