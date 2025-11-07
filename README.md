# Reproducibility Repository for the GAMM-Mitteilungen Paper

This repository contains all the scripts necessary to reproduce the results shown in the paper
*"Local continuum consistent peridynamics with bond-associated modeling and dynamic fracture"*,
which was submitted to GAMM-Mitteilungen.

## How to Run the Scripts

First, install Julia and then install all required packages by running the following command in the root directory of the repository:
```
julia -e'import Pkg; Pkg.activate("."); Pkg.instantiate()'
```
Then, run the scripts with the number of threads your machine is capable of, here with 16 threads:
```
julia --project -t 16 scripts/btt.jl
julia --project -t 16 scripts/mode-i.jl
```
All simulation files are written to their respective `out` directories.
Additionally, plots and videos of the simulations are saved in the `post` folders of the simulations.