# Reproducibility Repository for the GAMM-Mitteilungen Paper

[![DOI](https://zenodo.org/badge/1090997503.svg)](https://doi.org/10.5281/zenodo.17569850)

This repository contains all the scripts necessary to reproduce the results shown in the paper
*"Local continuum consistent peridynamics with bond-associated modeling and dynamic fracture"*,
which was submitted to GAMM-Mitteilungen.

## How to Run the Scripts

After installing julia, simply run the scripts with the number of threads your machine is capable of, here with 16 threads:
```
julia --project -t 16 scripts/btt.jl
julia --project -t 16 scripts/mode-i.jl
```
All simulation files are written to their respective `out` directories.
Additionally, plots and videos of the simulations are saved in the `post` folders of the simulations.

The images used in the paper can be extracted from the out directories with the `paper_images.sh` script.