
tfcurve(power32, "../data/2025630_1_OK/113356526.csv";epochs=800, verbose=true, lr=1e-2)

tfcurve(power32, "../data/2025630_1_OK/11349250.csv";verbose=false)
showspec(power32, "../data/2025630_1_OK/11349250.csv")

tfcurve(power32, "../data/2025630_1_OK/113421276.csv";verbose=false)
showspec(power32, "../data/2025630_1_OK/113421276.csv")

tfcurve(power32, "../data/2025630_1_OK/113250862.csv";verbose=false)
showspec(power32, "../data/2025630_1_OK/113250862.csv")



showspec(power32, "../data/2025630_1_OK/113421276.csv")

ftrend(power32, "../data/2025630_1_OK/113421276.csv")


let FMIN = 0,
    FMAX = 1200,
    RATE = 60240,
    power = PowerSpec(
            fs = RATE,
            fmin = FMIN,
            fmax = FMAX,
            winlen = 4096,
            stride = 128,
            nffts = 4096*8,
            donorm = true,
            winfunc = nuttall,
            type = Vector{Float32})
    x  = read_dc_motor("../data/2025630_1_OK/113443396.csv");
    Lx = length(x)
    Xw = log10.(1.0 .+ power(x))
    FBINS, TIMESTEPS = size(Xw)
    oldticks = collect(range(1, FBINS, 6))
    newticks = collect(range(FMIN, FMAX, 6))
    hm = heatmap(Xw, yticks=(oldticks,newticks),
                     ylabel="frequency (Hz)",
                     xlabel="time step index",
                     legend=nothing)

    oldticks = trunc(collect(range(1, Lx, 5)),digits=2)
    newticks = trunc(collect(range(0, Lx/RATE, 5)),digits=2)
    px = plot(x, xticks=(oldticks,newticks),
                 ylabel="current (A)",
                 xlabel="time (s)",
                 legend=nothing,
                 framestyle=:origin,
                 xlims=(first(oldticks),last(oldticks)))
    plot(hm, px, layout= @layout [a{0.7h}; b{0.3h}])
end




let FMIN = 100,
    FMAX = 1200,
    RATE = 60240,
    power = PowerSpec(
            fs = RATE,
            fmin = FMIN,
            fmax = FMAX,
            winlen = 4096,
            stride = 128,
            nffts = 4096*8,
            donorm = true,
            winfunc = nuttall,
            type = Vector{Float32})
    x  = read_dc_motor("../data/2025630_1_OK/113443396.csv");
    Lx = length(x)
    Xw = power(x)
    FBINS, TIMESTEPS = size(Xw)
    oldticks = collect(range(1, FBINS, 6))
    newticks = collect(range(FMIN, FMAX, 6))
    hm = heatmap(Xw, yticks=(oldticks,newticks),
                     ylabel="frequency (Hz)",
                     xlabel="time step index",
                     legend=nothing)

    oldticks = trunc(collect(range(1, Lx, 5)),digits=2)
    newticks = trunc(collect(range(0, Lx/RATE, 5)),digits=2)
    px = plot(x, xticks=(oldticks,newticks),
                 ylabel="current (A)",
                 xlabel="time (s)",
                 legend=nothing,
                 framestyle=:origin,
                 xlims=(first(oldticks),last(oldticks)))
    plot(hm, px, layout= @layout [a{0.7h}; b{0.3h}])
end

