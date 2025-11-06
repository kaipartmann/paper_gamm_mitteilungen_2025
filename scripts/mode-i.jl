# ==========================================================================================
# mode-i tension
# Author: Kai Partmann
# ==========================================================================================

using Peridynamics
using Printf

enable_mpi_progress_bars!()

include("../utils/code_backup.jl")
include("../utils/modes_plot.jl")
include("../utils/create_video.jl")

function job_mode_i(setup)
    # body model setup
    (; mat, l, ΔX, a, params, time, path) = setup
    pos, vol = uniform_box(l, l, 0.1l, ΔX)
    body = Body(mat, pos, vol)
    material!(body; params...)
    # initiate precrack
    δ = params.horizon
    point_set!(p -> p[1] ≤ -l/2+a && 0 ≤ p[2] ≤ 2δ, body, :set_a)
    point_set!(p -> p[1] ≤ -l/2+a && -2δ ≤ p[2] < 0, body, :set_b)
    precrack!(body, :set_a, :set_b)
    # initiate boundary conditions
    point_set!(p -> p[2] > l/2-ΔX, body, :set_top)
    point_set!(p -> p[2] < -l/2+ΔX, body, :set_bottom)
    velocity_bc!(t -> -50, body, :set_bottom, :y)
    velocity_bc!(t -> 50, body, :set_top, :y)
    # simulation settings
    vv = VelocityVerlet(; time)
    job = Job(body, vv; path)
    return job
end

rad(grad::Real) = grad * π / 180
magnitude(v::AbstractMatrix) = [sqrt(x^2 + y^2 + z^2) for (x, y, z) in eachcol(v)]

function simulation_mode_i(setup)

    #--- PRE-PROCESSING ---#
    # extract setup parameters
    (; path) = setup

    # directory setup
    @mpiroot rm(path; recursive=true, force=true)

    # code backup
    @mpiroot begin
        pdjl_src = joinpath(pkgdir(Peridynamics), "src")
        make_code_backup(path, @__FILE__, "utils", pdjl_src)
    end

    #--- SIMULATION ---#
    @mpiroot printstyled("--- MODE I TENSION ---\n", bold=true, color=:blue)
    @mpiroot printstyled("--SIMULATION--\n", color=:blue, bold=true)
    job = job_mode_i(setup)
    @mpitime submit(job)

end

function postprocessing_mode_i(setup)
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
        fig, ax, pos, qty = init_mode_plot(r0, ΔX)
        img_file = joinpath(dir_view_1, @sprintf("plot_%06d.png", id))
        save(img_file, fig; px_per_unit=1)
        pos[] = r[:position]
        qty[] = r[:damage]
        zoom!(ax.scene, cameracontrols(ax.scene), 1.1)
        save(img_file, fig; px_per_unit=2, update=false)
    end

    @mpiroot :wait begin
        @info "Creating the video of the crack propagation"
        img_files = readdir(dir_view_1; join=true, sort=true)
        create_video(joinpath(post_path, "mode1_view_1_dmg.mp4"), img_files; fps=60)
    end
    return nothing
end

function main()
    #-- general setup --#
    l, ΔX, a = 1.0, 1/100, 0.5
    params = (horizon=3.015ΔX, E=2.1e5, rho=8e-6, nu=0.25, Gc=2.7)
    time = 1.5e-4
    setup = (; l, ΔX, a, params, time)

    #-- material specific setup --#
    mat = BBMaterial()
    path = joinpath("out", "mode-i_BBMaterial")
    setup_bbmaterial = (; setup..., mat, path)

    mat = OSBMaterial()
    path = joinpath("out", "mode-i_OSBMaterial")
    setup_osbmaterial = (; setup..., mat, path)

    mat = CRMaterial(zem=ZEMSilling(Cs=10))
    path = joinpath("out", "mode-i_CRMaterial_ZEMSilling10")
    setup_crmaterial_zemsilling10 = (; setup..., mat, path)

    mat = CRMaterial(zem=ZEMSilling(Cs=100))
    path = joinpath("out", "mode-i_CRMaterial_ZEMSilling100")
    setup_crmaterial_zemsilling100 = (; setup..., mat, path)

    mat = CRMaterial(zem=ZEMWan())
    path = joinpath("out", "mode-i_CRMaterial_ZEMWan")
    setup_crmaterial_zemwan = (; setup..., mat, path)

    mat = RKCRMaterial()
    path = joinpath("out", "mode-i_RKCRMaterial")
    setup_rkcrmaterial = (; setup..., mat, path)

    #-- run the simulations --#
    simulation_mode_i(setup_bbmaterial)
    simulation_mode_i(setup_osbmaterial)
    simulation_mode_i(setup_crmaterial_zemsilling10)
    simulation_mode_i(setup_crmaterial_zemsilling100)
    simulation_mode_i(setup_crmaterial_zemwan)
    simulation_mode_i(setup_rkcrmaterial)

    #-- run the post-processing --#
    postprocessing_mode_i(setup_bbmaterial)
    postprocessing_mode_i(setup_osbmaterial)
    postprocessing_mode_i(setup_crmaterial_zemsilling10)
    postprocessing_mode_i(setup_crmaterial_zemsilling100)
    postprocessing_mode_i(setup_crmaterial_zemwan)
    postprocessing_mode_i(setup_rkcrmaterial)

    return nothing
end

##
main()
