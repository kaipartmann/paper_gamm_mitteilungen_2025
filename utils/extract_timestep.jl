"""
    extract_timestep(log_file)

Extract the time step from the log file of a simulation.

# Arguments:
- `log_file::AbstractString`: The path to the log file.

# Returns:
- `Δt::Float64`: The time step extracted from the log file.
"""
function extract_timestep(log_file::AbstractString)
    log = read(log_file, String)
    time_step = match(r"time step size \.+ ([0-9.e+-]+)", log)
    @assert time_step !== nothing
    Δt::Float64 = parse(Float64, time_step.captures[1])
    return Δt
end
