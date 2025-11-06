using GLMakie, Printf

function init_btt_plot(r0, ΔX)
    markersize = 0.6 * ΔX
    colormap = cgrad([RGBf(0.231373, 0.298039, 0.752941),
                      RGBf(0.8, 0.8, 0.8),
                      RGBf(0.705882, 0.0156863, 0.14902)])
    pos = Observable(r0[:position])
    qty = Observable(r0[:damage])
    colorrange = (0.0, 1.0)
    fig = Figure(size=(800, 500), figure_padding=5)
    ax = LScene(fig[1, 1]; show_axis=false)
    cam3d_cad!(ax.scene)
    cam3d_cad!(fig.scene)
    ms = meshscatter!(ax, pos; color=qty, markersize, colormap, colorrange)
    Colorbar(fig[1,2], ms; label="damage", height=120, tellheight=false)
    colgap!(fig.layout, 0)
    rotate_cam!(ax.scene, 0, rad(225), 0)
    rotate_cam!(ax.scene, rad(-65), 0, 0)
    rotate_cam!(ax.scene, 0, rad(40), 0)
    rotate_cam!(ax.scene, 0, 0, rad(-15))
    return fig, ax, pos, qty
end

function compare_ctvelocity(setups, E, rho, smp, filename)
    (; smp_pos, smp_vel) = smp
    function extract_data(setup)
        name = split(basename(setup.path), "_")[end]
        data_path = joinpath(setup.path, "post", "ctpx_over_time.txt")
        data, _ = readdlm(data_path, ',', Float64; header=true)
        return (; data, name)
    end
    function smooth(a, smp)
        return [mean(a[max(1, i-smp):min(end, i+smp)]) for i in eachindex(a)]
    end
    data = [extract_data(setup) for setup in setups]
    cl = Makie.wong_colors()
    linewidth = 3
    fig = Figure(size=(1100, 600), figure_padding=5)
    title = "Crack tip velocity"
    xlabel = "Time [s]"
    ylabel = "Velocity [m/s]"
    ax = Axis(fig[1, 1]; title, xlabel, ylabel)
    hlines!(ax, 0.5 * sqrt(E / rho); color=:black, linestyle=:dash, linewidth,
            label="Half wave speed: 1/2√(E/ρ)")
    for (i, dd) in enumerate(data)
        times = dd.data[:, 1]
        position = dd.data[:, 2]
        sposition = smooth(position, smp_pos)
        velocity = zeros(length(sposition))
        for i in 2:lastindex(sposition)
            velocity[i] = (sposition[i] - sposition[i-1]) / (times[i] - times[i-1])
        end
        svelocity = smooth(velocity, smp_vel)
        lines!(ax, times, svelocity; color=cl[i], linewidth, label=dd.name)
    end
    axislegend(ax; position=:lt)
    display(fig)
    save(filename, fig; px_per_unit=4)
    return nothing
end
