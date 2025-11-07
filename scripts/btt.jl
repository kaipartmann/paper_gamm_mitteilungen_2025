# ==========================================================================================
# boundary tension test
# Author: Kai Partmann
# ==========================================================================================
include("../setup.jl")

using Peridynamics
using DelimitedFiles
using GLMakie, Printf
using Statistics: mean

enable_mpi_progress_bars!()

include("../utils/btt_plot.jl")
include("../utils/create_video.jl")
include("../utils/extract_timestep.jl")
include("../utils/code_backup.jl")

function job_btt(setup)
    (; lx, ly, lz, ΔX, params, mat, a, σ0, time, safety_factor, path, freq, fields) = setup
    pos, vol = uniform_box(lx, ly, lz, ΔX)
    body = Body(mat, pos, vol)
    material!(body; params...)
    δ = params.horizon
    point_set!(p -> p[1] ≤ -lx/2+a && 0 ≤ p[2] ≤ 2δ, body, :set_a)
    point_set!(p -> p[1] ≤ -lx/2+a && -2δ ≤ p[2] < 0, body, :set_b)
    precrack!(body, :set_a, :set_b)
    point_set!(p -> p[2] > ly/2-ΔX, body, :set_top)
    point_set!(p -> p[2] < -ly/2+ΔX, body, :set_bottom)
    point_set!(p -> p[2] > ly/2-3ΔX, body, :nf_set_top)
    point_set!(p -> p[2] < -ly/2+3ΔX, body, :nf_set_bottom)
    no_failure!(body, :nf_set_top)
    no_failure!(body, :nf_set_bottom)
    b0 = σ0 / ΔX
    forcedensity_bc!(t -> -b0, body, :set_bottom, :y)
    forcedensity_bc!(t -> b0, body, :set_top, :y)
    vv = VelocityVerlet(; time, safety_factor)
    job = Job(body, vv; path, freq, fields)
    return job
end

rad(grad::Real) = grad * π / 180
magnitude(v::AbstractMatrix) = [sqrt(x^2 + y^2 + z^2) for (x, y, z) in eachcol(v)]

function simulation_btt(setup)

    #--- PRE-PROCESSING ---#
    # extract setup parameters
    (; npy, path) = setup

    # directory setup
    @mpiroot rm(path; recursive=true, force=true)

    # code backup
    @mpiroot begin
        pdjl_src = joinpath(pkgdir(Peridynamics), "src")
        make_code_backup(path, @__FILE__, "utils", pdjl_src)
    end

    #--- SIMULATION ---#
    @mpiroot printstyled("--- BTT FRACTURE WITH NPY=$(npy) ---\n", bold=true, color=:blue)
    @mpiroot printstyled("--SIMULATION--\n", color=:blue, bold=true)
    job = job_btt(setup)
    try
        @mpitime submit(job)
    catch e
        @mpiroot println("\n\nSimulation failed:\n")
        @mpiroot Base.showerror(stderr, e)
    end

end

function postprocessing_btt(setup)
    #--- POST-PROCESSING ---#
    @mpiroot printstyled("--POSTPROCESSING--\n", color=:blue, bold=true)

    # extract setup parameters
    (; ΔX, path) = setup

    # directory setup
    post_path = joinpath(path, "post")
    vtk_path = joinpath(path, "vtk")
    dir_view_1 = joinpath(post_path, "view_1")
    @mpiroot rm(post_path; recursive=true, force=true)
    @mpiroot :wait mkpath(dir_view_1)

    serial = Threads.nthreads() > 1 ? true : false
    @mpitime process_each_export(vtk_path; serial) do r0, r, id
        # img output for video
        fig, ax, pos, qty = init_btt_plot(r0, ΔX)
        img_file = joinpath(dir_view_1, @sprintf("plot_%06d.png", id))
        save(img_file, fig; px_per_unit=1)
        pos[] = r[:position]
        qty[] = r[:damage]
        zoom!(ax.scene, cameracontrols(ax.scene), 0.66)
        translate_cam!(ax.scene, cameracontrols(ax.scene), Vec3f(0.015,-0.005,0))
        save(img_file, fig; px_per_unit=2, update=false)
    end

    @mpiroot :wait begin
        @info "Creating the video of the crack propagation"
        img_files = readdir(dir_view_1; join=true, sort=true)
        create_video(joinpath(post_path, "btt_view_1_dmg.mp4"), img_files; fps=60)
    end

    return nothing
end

function main()
    #-- general setup --#
    lx = 0.1
    ly = 0.04
    lz = 0.1 * ly
    npy = 50
    ΔX = ly / npy
    params = (horizon=3.015ΔX, rho=2440, E=72e9, nu=0.25, Gc=150)
    a = 0.5 * lx
    time = 1.5e-4
    safety_factor = 0.7
    freq = 10
    fields = (:damage, :displacement,)
    σ0 = 17e6 # Pa
    setup = (; lx, ly, lz, npy, ΔX, params, a, σ0, time, safety_factor, freq, fields)

    #-- material specific setup --#
    mat = BBMaterial{EnergySurfaceCorrection}()
    path = joinpath("out", "btt_BBMaterial")
    setup_bbmaterial = (; setup..., mat, path)

    mat = CRMaterial(zem=ZEMSilling())
    path = joinpath("out", "btt_CRMaterial-ZEMSilling")
    setup_crmaterial_silling = (; setup..., mat, path)

    mat = CRMaterial(zem=ZEMWan())
    path = joinpath("out", "btt_CRMaterial-ZEMWan")
    setup_crmaterial_wan = (; setup..., mat, path)

    mat = RKCRMaterial(kernel=const_one_kernel, regfactor=1e-6)
    path = joinpath("out", "btt_RKCRMaterial")
    setup_rkcrmaterial = (; setup..., mat, path)

    #-- run the simulations --#
    simulation_btt(setup_bbmaterial)
    simulation_btt(setup_crmaterial_silling)
    simulation_btt(setup_crmaterial_wan)
    simulation_btt(setup_rkcrmaterial)

    #-- run the post-processing --#
    postprocessing_btt(setup_bbmaterial)
    postprocessing_btt(setup_crmaterial_silling)
    postprocessing_btt(setup_crmaterial_wan)
    postprocessing_btt(setup_rkcrmaterial)

    return nothing
end

##
main()
