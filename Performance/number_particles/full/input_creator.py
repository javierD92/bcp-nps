import numpy as np
import os

def write_parameters_file(target_dir, overrides=None):
    """
    Writes parameters.in using a default dictionary updated by 'overrides'.
    """
    # 1. Master Dictionary of Defaults
    p = {
        'Lx': 512, 'Ly': 512,
        'dt_reduced': 0.01,
        't_total': 100,
        'M': 1.0, 'kappa': 1.0, 'tau': 0.35, 'u': 0.5,
        'mean_psi': 0.0,
        'R0': 1.7, 'epsilon': 10.0,
        'sigma': 1.0, 'affinity': 1.0, 'Reff': 1.7,
        'temperature': 0.05,
        'gamma_T': 1.0,
        'Pe': 0.0,
        'phip': 0.2,
        'init_custom': "false" 
    }

    # 2. Update with whatever the Sweeper wants to change
    if overrides:
        p.update(overrides)

    # 3. Derived Physical Calculations (Automatic based on updated p)
    #eta = p['gamma_T'] / (6.0 * np.pi * p['R0']) 

    eta = 0.03362761932879757

    p['gamma_T'] = 6.0 * np.pi * eta * p['R0']
    gamma_R = 8.0 * np.pi * eta * (p['R0']**3)
    Dr = p['temperature'] / gamma_R
    vact = p['Pe'] * Dr * 2 * p['R0']
    
    system_area = p['Lx'] * p['Ly']
    Np = int(p['phip'] * system_area / (np.pi * p['R0']**2))

    Lw = np.sqrt(p['kappa'] / p['tau'])
    tBM = Lw**2 / (p['M'] * p['tau'])
    tSw = (2 * p['R0']) / vact if vact > 0 else 1e9
    tref = min([(2 * p['R0']) / vact if vact > 0 else 1e9, tBM, 1.0/Dr])

    dt = tref * p['dt_reduced']
    total_steps = int(p['t_total'] * tBM / dt)

    # Noise strengtg 
    noise = np.sqrt( 0.25*p['M'] * p['temperature'] )

    # 4. Final Data Mapping for Fortran
    data = [
        (f"{p['Lx']} {p['Ly']}", "Lx, Ly"),
        (f"{Np}", "Np"),
        (f"{total_steps}", "total_steps"),
        ("10000", "save_interval"),
        ("1000", "stats interval"),
        (f"{dt}", "dt"),
        (f"{p['M']} {p['kappa']} {p['tau']} {p['u']}", "Field Params"),
        (f"{p['mean_psi']}", "mean psi"),
        (f"{p['sigma']} {p['affinity']}", "Coupling"),
        (f"{p['Reff']}", "Reff"),
        (f"{p['epsilon']} {p['R0']}", "WCA"),
        (f"{p['temperature']}", "temp"),
        (f"{p['gamma_T']:.6f} {gamma_R:.6f}", "Gammas"),
        (f"{vact}", "vact"),
        (f"{noise}", "noise strength"),
        (f"{p['init_custom']}", "custom initial condition")
    ]

    # Write to target folder
    with open(os.path.join(target_dir, "parameters.in"), 'w') as f:
        for val, comment in data:
            f.write(f"{val:<25} ! {comment}\n")

if __name__ == "__main__":
    # This runs ONLY when you type 'python input_creator.py'
    # It passes "." as the target_dir to create the file in your current folder
    write_parameters_file(target_dir=".", overrides=None)
    
    print("Success: 'parameters.in' has been generated in the current directory.")
