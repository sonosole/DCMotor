using AcousticFeatures

FMIN = 100
FMAX = 1100
power32 = PowerSpec(
            fs = 60240,
            fmin = FMIN,
            fmax = FMAX,
            winlen = 4096,
            stride = 128,
            nffts = 4096*4,
            donorm = true,
            winfunc = nuttall,
            type = Vector{Float32})
