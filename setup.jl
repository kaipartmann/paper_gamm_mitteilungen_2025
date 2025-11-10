# Setup the Julia environment for the Peridynamics project
import Pkg
Pkg.activate(@__DIR__)

# Install packages specified inside the Project.toml
Pkg.instantiate()

# Install specific version of Peridynamics.jl
Pkg.add(Pkg.PackageSpec(name="Peridynamics", version="0.5.0"))
