import numpy as np
import os

# Field Visuals
V_MIN, V_MAX = -1.0, 1.0
CMAP = 'RdBu_r'

# Particle/Arrow Visuals
PARTICLE_COLOR = '#F0E442'
ARROW_COLOR = 'white'
ARROW_SCALE = 30
ARROW_WIDTH = 0.003

def reshape_field(data, lx, ly):
    if data.ndim == 1:
        return data.reshape((ly, lx))
    elif data.ndim == 2 and data.shape[1] == 3:
        return data[:, 2].reshape((ly, lx))
    return data

def get_params(path):
    param_file = os.path.join(path, "parameters.in")
    lx, ly = 128, 128
    if os.path.exists(param_file):
        try:
            with open(param_file, 'r') as f:
                for line in f:
                    line = line.split('!')[0].strip()
                    if not line: continue
                    parts = line.split()
                    if len(parts) >= 2:
                        return int(float(parts[0])), int(float(parts[1]))
        except Exception: pass
    return lx, ly