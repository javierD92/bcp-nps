import numpy as np
import pyvista as pv
from pathlib import Path
import argparse
import re
import sys
from get_params import get_params

def extract_time_and_key(fname):
    m = re.search(r"(\d+)", fname.name)
    if not m:
        return None, None
    return int(m.group(1)), m.group(1)

def convert(pol_file, colls_file, time_key, Nx, Ny, dx, dy, output_dir):
    # ======================
    # Field (psi) - Transposed
    # ======================
    psi_raw = np.loadtxt(pol_file, delimiter=None)

    if psi_raw.ndim == 1:
        psi = psi_raw
    elif psi_raw.ndim == 2 and psi_raw.shape[1] == 3:
        psi = psi_raw[:, 2]
    else:
        raise ValueError(f"Unexpected shape {psi_raw.shape} in {pol_file}")

    if psi.size != Nx * Ny:
        raise ValueError(f"Size {psi.size} != {Nx}x{Ny} in {pol_file}")

    # Reshape and Transpose to match physical x,y coordinates
    psi = psi.reshape((Ny, Nx), order="F")

    grid = pv.ImageData(
        dimensions=(Nx, Ny, 1),
        spacing=(dx, dy, 1.0),
        origin=(0.0, 0.0, 0.0),
    )

    grid.point_data["psi"] = psi.ravel(order="F")
    grid.save(output_dir / f"psi_{time_key}.vti")

    # ======================
    # Particles + orientation
    # ======================
    data = np.loadtxt(colls_file)
    if data.shape[1] < 3:
        raise ValueError(f"{colls_file} must contain x y phi columns")

    x, y, phi = data[:, 0] - 1.0, data[:, 1] - 1.0, data[:, 2]
    points = np.column_stack((x, y, np.zeros_like(x)))

    poly = pv.PolyData(points)
    poly.point_data["phi"] = phi
    poly.point_data["n"] = np.column_stack((np.cos(phi), np.sin(phi), np.zeros_like(phi)))

    poly.save(output_dir / f"colls_{time_key}.vtp")

def main():
    parser = argparse.ArgumentParser(description="Convert simulation TXT to VTK")
    parser.add_argument("input_dir", type=str, help="Path to the simulation folder")
    parser.add_argument("--Nx", type=int, help="Override Grid X")
    parser.add_argument("--Ny", type=int, help="Override Grid Y")
    parser.add_argument("--dx", type=float, default=1.0)
    parser.add_argument("--dy", type=float, default=1.0)
    args = parser.parse_args()

    indir = Path(args.input_dir)
    
    # 1. Get parameters from the folder
    lx_auto, ly_auto, tau, u, dt = get_params(str(indir))
    
    # 2. Use command line args if provided, otherwise use auto-detected
    Nx = args.Nx if args.Nx else lx_auto
    Ny = args.Ny if args.Ny else ly_auto

    print(f"Using Grid: {Nx}x{Ny} (dt={dt})")

    pol_map = {extract_time_and_key(f)[1]: (extract_time_and_key(f)[0], f) 
               for f in indir.glob("field_psi_*.txt") if extract_time_and_key(f)[1]}
    
    colls_map = {extract_time_and_key(f)[1]: (extract_time_and_key(f)[0], f) 
                 for f in indir.glob("particles_*.txt") if extract_time_and_key(f)[1]}

    common_keys = sorted(set(pol_map) & set(colls_map), key=lambda k: pol_map[k][0])

    if not common_keys:
        print("No matching files found.")
        return

    for i, key in enumerate(common_keys, 1):
        print(f"[{i}/{len(common_keys)}] Processing t = {key}", end='\r')
        convert(pol_map[key][1], colls_map[key][1], key, Nx, Ny, args.dx, args.dy, indir)
    
    print("\nDone.")

if __name__ == "__main__":
    main()