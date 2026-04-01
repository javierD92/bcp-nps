import os 
def get_params(path):
    param_file = os.path.join(path, "parameters.in")
    lx, ly = 128, 128 
    tau, u, dt = 0.35, 0.5, 0.001 
    
    if os.path.exists(param_file):
        try:
            with open(param_file, 'r') as f:
                lines = f.readlines()
                lx_ly = lines[0].split('!')[0].split()
                lx, ly = int(float(lx_ly[0])), int(float(lx_ly[1]))
                
                for line in lines:
                    val_part = line.split('!')[0].strip()
                    comment_part = line.split('!')[-1].lower() if '!' in line else ""
                    if "dt" in comment_part:
                        dt = float(val_part)
                    if "field params" in comment_part:
                        parts = val_part.split()
                        tau = float(parts[2])
                        u = float(parts[3])
                print(f"Params Inferred: Grid={lx}x{ly}, dt={dt}, tau={tau}, u={u}")
        except Exception as e:
            print(f"Warning: Error parsing params ({e}). Using defaults.")
    return lx, ly, tau, u, dt
