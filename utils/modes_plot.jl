using GLMakie

function init_mode_plot(r0, ΔX)
    markersize = 0.6 * ΔX
    colormap = cgrad([RGBf(0.231373, 0.298039, 0.752941),
                      RGBf(0.8, 0.8, 0.8),
                      RGBf(0.705882, 0.0156863, 0.14902)])
    pos = Observable(r0[:position])
    qty = Observable(r0[:damage])
    colorrange = (0.0, 1.0)
    fig = Figure(size=(600, 600), figure_padding=5)
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
