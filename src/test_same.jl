info = tvsf(power32, "../data/2025630_1_OK/113443396.csv";verbose=true,lr=1e-2,epochs=800)
rpm  = 2250
Nm⁻¹ = 1.15
coef = TSCoef(info, rpm, Nm⁻¹)
lcoef = LineCoef(coef, info)
n, t  = drawtn(lcoef)
plot(t, n, framestyle=:origin, linewidth=3, color=:black, alpha=0.5, xlims=(0, 1.5), leg=nothing)



for (root, dirs, files) in walkdir("../data/2025630_2_NG/")
    println("Files in $root")
    for file ∈ files
        !isequal(".csv", last(splitext(file))) && continue
        fullpath = joinpath(root, file)
        println(fullpath)
        sleep(1)
        infoxx = tvsf(power32, fullpath; verbose=false,lr=1e-2,epochs=800)
        nx,tx = drawtn(LineCoef(coef, infoxx))
        plot!(tx,nx, framestyle=:origin, color=:purple)
        gui()
    end
end

