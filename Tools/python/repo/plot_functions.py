import numpy as np
from matplotlib.patches import Circle
from matplotlib.collections import PatchCollection
import utils

def plot_simulation_state(ax, p_data, f_data, params, config):
    """Initializes the plot. Returns (im, pc, qvr)."""
    LX, LY = params['lx'], params['ly']
    RADIUS = params['reff']
    PSI_EQ = np.sqrt(params['tau'] / params['u'])
    
    # 1. Field
    psi = utils.reshape_field(f_data, LX, LY) / PSI_EQ
    im = ax.imshow(psi, extent=[0, LX, 0, LY], origin='lower',
                   cmap=config['field']['cmap'], 
                   vmin=config['field']['v_min'], 
                   vmax=config['field']['v_max'],
                   interpolation='bilinear')
    
    # 2. Particles
    pc = None
    if p_data is not None and p_data.size > 0:
        pc = get_particle_collection(p_data, RADIUS, config)
        ax.add_collection(pc)

    # 3. Arrows (Fixed scaling behavior)
    x = p_data[:, 0] if p_data.size > 0 else []
    y = p_data[:, 1] if p_data.size > 0 else []
    u = np.cos(p_data[:, 2]) if p_data.size > 0 else []
    v = np.sin(p_data[:, 2]) if p_data.size > 0 else []
    
    qvr = ax.quiver(x, y, u, v, **config['quiver'])
    
    return im, pc, qvr

def get_particle_collection(p_data, radius, config):
    """Generates the circles for the particles."""
    patches = [Circle((x, y), radius) for x, y in p_data[:, :2]]
    return PatchCollection(patches, 
                           facecolor=config['particles']['c'],
                           edgecolor=config['particles']['edgecolors'],
                           zorder=config['particles']['zorder'])