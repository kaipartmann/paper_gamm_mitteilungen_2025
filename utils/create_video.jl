using VideoIO
using FileIO
using ProgressMeter

"""
    create_video(videoname, png_files; fps)

Create a MP4-video with the name `videoname` of all the png files in `png_files`.
Optionally specify the frames per second with the `fps` keyword-argument (default is 24).

# Arguments:
- `videoname::String`: The name of the video file to be created (should end with .mp4).
- `png_files::Vector{String}`: A vector of strings containing the paths to the png files to
    be included in the video.
- `fps::Int`: The frames per second for the video (default = `24`).

# Returns:
- `nothing`: No return value.
"""
function create_video(videoname::String, png_files::Vector{String}; fps::Int=24)

    # check if videoname has .mp4 extension
    _, ext = splitext(videoname)
    if ext !== ".mp4"
        msg = string("Invalid file extension! Should be .mp4, instead got: ", ext, "\n")
        throw(ArgumentError(msg))
    end

    # check if all files are valid
    for file in png_files
        if !isfile(file)
            msg = string("Invalid path! The file\n", file, "\ndoes not exist!\n")
            throw(ArgumentError(msg))
        end
    end

    # if video exists, delete!
    if isfile(videoname)
        rm(videoname)
        @info "Deleted existing video: $videoname"
    end

    # set encoding options to good defaults
    encoder_options = (crf=23, preset="medium")

    # progress logging
    @info "Encoding PNG-series to MP4-video:" videoname fps
    p = Progress(length(png_files); color=:normal, barlen=20)

    # write the video
    open_video_out(videoname, load(first(png_files));
        framerate=fps,
        encoder_options=encoder_options,
        target_pix_fmt=VideoIO.AV_PIX_FMT_YUV420P,
    ) do writer
        for file in png_files
            write(writer, load(file))
            next!(p)
        end
    end
    finish!(p)

    return nothing
end
