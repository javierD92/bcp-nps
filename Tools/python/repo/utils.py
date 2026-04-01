import os
import numpy as np
import re
import yaml

def get_simulation_params(path):
    """Parses parameters.in and extracts grid, dt, and Reff."""
    param_file = os.path.join(path, "parameters.in")
    params = {}
    
    try:
        with open(param_file, 'r') as f:
            lines = f.readlines()
            # Line 1: Lx, Ly
            lx_ly = lines[0].split('!')[0].split()
            params["lx"], params["ly"] = int(float(lx_ly[0])), int(float(lx_ly[1]))
            
            for line in lines:
                val_part = line.split('!')[0].strip()
                comment_part = line.split('!')[-1].lower() if '!' in line else ""
                
                if "dt" in comment_part:
                    params["dt"] = float(val_part)
                if "field params" in comment_part:
                    parts = val_part.split()
                    params["tau"] = float(parts[2])
                    params["u"] = float(parts[3])
                if "reff" in comment_part:
                    params["reff"] = float(val_part)
    except Exception as e:
        print(f"Error parsing parameters.in: {e}")
        # Critical defaults if parsing fails
        params.update({"lx": 128, "ly": 128, "dt": 0.001, "tau": 0.35, "u": 0.5, "reff": 1.0})
        
    return params

def load_plot_config(config_path="plot_config.yaml"):
    """Loads purely aesthetic settings from YAML."""
    if not os.path.exists(config_path):
        return {
            "field": {"cmap": "RdBu_r", "v_min": -1.1, "v_max": 1.1},
            "particles": {"c": "#F0E442", "edgecolors": "black", "zorder": 3},
            "quiver": {"color": "white", "scale": 60, "width": 0.003}
        }
    with open(config_path, 'r') as f:
        return yaml.safe_load(f)

def reshape_field(data, lx, ly):
    """Standardized field reshaping"""
    if data.ndim == 1: return data.reshape((ly, lx))
    elif data.ndim == 2 and data.shape[1] == 3: return data[:, 2].reshape((ly, lx))
    return data

def natural_sort_key(s):
    """Natural sorting for file sequences"""
    return [int(text) if text.isdigit() else text.lower() for text in re.split('([0-9]+)', s)]