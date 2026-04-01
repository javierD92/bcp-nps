# Hybrid Active Brownian Particles and Phase Field Simulation

Thi repository contains the source code and postprocessing tools for the simulation of active particles in a phase-separating binary mixture. The model integrates a Cahn-Hilliard (Model B) field with Active Brownian Particles (ABPs).

## Project Overview

The simulation handles the co-evolution of two distinct but coupled systems:
1. Phase Field $\psi$: A continuous field governed by Model B kinetics to simulate phase separation (spinodal decomposition).
2. Active Particles: Discrete agents following Langevin dynamics with self-propulsion and repulsive interactions.

## Installation and Compilation

### Prerequisites
* Fortran Compiler: any
* Python: any 
* Build System: GNU Make.

### Compilation

To build the executable `simulation.exe` just type

`>> make`

## Usage

* `parameters.in` is the input file read by `simulation.exe`. It contains all the necessary parameters to execute the program. 

* `input_creator.py` is a wrapper that can generate `parameters.in`. `input_creator.py` is *higher level* in the sense that it contains Physics-informed parameters such as Péclet number, concentration of particles and other reduced quantities. `parameters.in`, instead, contains only pure parameters needed for the simulation. 

* `sweeper.py` is a higher order wrapper which can sweep over two arrays to explore two variables (e.g. $Pe$ and $\phi_p$). It has the ability to overwrite the default values contained in `input_creator.py`. It creates a subfolder called `SIM_i_j` for each pair of variables and executes the simulation there. 
Note: `sweeper.py` produces a file `sweep_info.txt` with the name and value of the variables that are specific for each subfolder `SIM_i_j`. 

### Output 

Files produced by the program: 
- `*.txt` files contain the state of the system at a given time.
    1. `field_psi_*.txt`
    2. `particles_*.txt`
- `*.dat` contain statistical information
    1. `free_energy.dat`
    2. `stats.dat`
- 

 
### Statistical information

Every **stats interval** the program will calculate and save statistical information. Currently these are: 
* `free_energy.dat` contains the...
* `stats.dat` contains  

### Restart

The program produces a binary file called `checkpoint.bin` every **save_interval** number of steps (same as saving state). This file contains the current state of the system at the moment of saving. The program will automatically detect the presence of this file and enter into restart mode. It will continue from the point where the simulation was and run until  **total_steps** is reached.

Statistical information will be appended to existing files when using *restart mode*. 




## Analysis Tools

The Tools/ directory contains Python scripts for post-processing and visualization.

* Snapshots: python3 Tools/analyze_sweep.py generates 2D visualizations of the field and particle positions, including orientation vectors.
* Statistics: python3 Tools/analyze_stats.py processes stats.dat and free_energy.dat to produce dashboards showing energy minimization and domain growth.

## Data Output Structure

The code generates the following outputs for analysis:

| File | Description |
| :--- | :--- |
| field_psi_*.txt | 2D grid data of the phase field concentration. |
| particles_*.txt | Coordinates (x, y) and orientation angles of all particles. |
| free_energy.dat | Time-series of Field, Particle, and Coupling energy components. |
| stats.dat | Characteristic domain size measurements over time. |
| performance.txt | CPU time logs for benchmarking. |

## License

This project is licensed under the MIT License.

## Contact

Javier D. - [javierD92](https://github.com/javierD92)