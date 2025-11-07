# Setup the Julia environment for the Peridynamics project
import Pkg
Pkg.activate(@__DIR__)

# Install Peridynamics package specified inside the Project.toml
Pkg.instantiate()

# Install specific version of Peridynamics from GitHub
Pkg.add(Pkg.PackageSpec(name="Peridynamics", rev="rkc_enhancements"))

# Resolve any dependency issues if necessary
Pkg.resolve()
