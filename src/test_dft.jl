Fs   = 16_000
FMIN = 500
FMAX = 4000


power32 = PowerSpec(
            fs   = Fs,
            fmin = 0,
            fmax = Fs/2,
            winlen = 4096,
            stride = 32,
            nffts = 4096,
            dilation = 1,
            donorm = true,
            winfunc = nuttall,
            type = Vector{Float32})


power64 = NDFT{Float64}(
            fs   = Fs,
            fmin = FMIN,
            fmax = Fs/2,
            winlen = 4096,
            stride = 32,
            ndfts = 4096*4,
            dilation = 1,
            donorm = true,
            winfunc = nuttall,
            type = Vector{Float64})


data64 = chirp(5, Fs, FMIN, FMAX);
data32 = Float32.(data64)
@time feat32 = power32(data32)
@time feat64 = power64(data64)
h1=heatmap(log.(1e-2 .+ feat32))
h2=heatmap(log.(1e-2 .+ feat64))
plot(h1,h2,layout=(1,2))
