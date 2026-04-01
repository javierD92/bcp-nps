import os
import shutil
import numpy as np
import subprocess  # New import for running commands

from input_creator import write_parameters_file

# --- 1. CONFIGURATION ---
RUN_SIMS = False  # Set to True to actually launch simulation.exe
                  # Set to False for a "Dry Run" (folder/file creation only)
BATCH = True

tag = 'gam_'

# Target any keys defined in the 'p' dictionary in input_creator.py
var1_key = "u"           
var2_key = "Pe"         

data_vec1 = [ 0.25, 0.33 , 0.5 ]
data_vec2 = np.logspace( np.log10( 8.0 ), np.log10( 15.0 ) , 30 )

# Since everything is in the same folder, use './'
executable = "./simulation.exe" 

def run_sweep():
    # 1. Validation: Ensure the binary exists before doing anything
    if not os.path.exists(executable):
        print(f"Error: '{executable}' not found in the current directory.")
        print("Make sure you have compiled your Fortran code first.")
        return

    print(f"Starting sweep: {var1_key} vs {var2_key}")

    for i, val1 in enumerate(data_vec1):
        for j, val2 in enumerate(data_vec2):
            

            gammaAB = val1
            u = 0.165 / gammaAB


            Pe = val2
            
            # Create folder SIM_i_j
            folder = f"SIM_{i}_{j}"
            os.makedirs(folder, exist_ok=True)

            # Create the override instructions
            overrides = {
                var1_key: u,
                var2_key: val2
            }
            
            # 2. Write the parameters.in into the subfolder
            write_parameters_file(folder, overrides=overrides)
            
            # 3. Copy the binary from the current folder into the subfolder
            shutil.copy(executable, folder)
            shutil.copy('script.sh', folder)
#            shutil.copy("checkpoint.bin", folder+'/equilibrated.bin')

            # 4. Record what this simulation is for easy reference
            with open(os.path.join(folder, "sweep_info.txt"), "w") as f:
                f.write("# Non-default parameters for this simulation\n")
                for key, value in overrides.items():
                    f.write(f"{key}: {value}\n")

            print(f"  -> Created {folder}")

            # --- START EXECUTION IN BACKGROUND ---
            print(f"Launching {folder} in background...")
            
            if RUN_SIMS:
                print(f"  -> Launching {folder} in background...")
                log_path = os.path.join(folder, "output.log")
                with open(log_path, "w") as f_log:
                    # Using Popen for background execution
                    subprocess.Popen(["./simulation.exe"], 
                                     cwd=folder, 
                                     stdout=f_log, 
                                     stderr=f_log)
            elif BATCH:
                os.system(f'cd {folder} && sbatch --job-name={tag}{i}_{j} script.sh')
            else:
                print(f"  -> {folder} prepared (Dry Run).")
            print(f"Finished {folder}.")

    print(f"\nSuccess. {len(data_vec1)*len(data_vec2)} simulation folders prepared.")

if __name__ == "__main__":
    run_sweep()
