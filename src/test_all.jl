info = tvsf(power32, read_dc_motor("../data/2025630_1_OK/113443396.csv");verbose=true,lr=1e-2,epochs=800)
rpm  = 2250
Nm⁻¹ = 1.15
coef = TSCoef(info, rpm, Nm⁻¹)
lcoef = LineCoef(coef, info)
n, t  = drawtn(lcoef)

plot()

for (root, dirs, files) in walkdir("../data/2025630_1_OK/")
    println("Files in $root")
    for file ∈ files
        !isequal(".csv", last(splitext(file))) && continue
        fullpath = joinpath(root, file)
        # println(fullpath)
        infoxx = tvsf(power32, fullpath; verbose=false,lr=1e-2,epochs=800)
        nx,tx = drawtn(LineCoef(coef, infoxx))
        plot!(tx,nx, framestyle=:origin, color=:green)
        gui()
    end
end


for (root, dirs, files) in walkdir("../data/2025630_1_NG/")
    println("Files in $root")
    for file ∈ files
        !isequal(".csv", last(splitext(file))) && continue
        fullpath = joinpath(root, file)
        # println(fullpath)
        infoxx = tvsf(power32, fullpath; verbose=false,lr=1e-2,epochs=800)
        nx,tx = drawtn(LineCoef(coef, infoxx))
        plot!(tx,nx, framestyle=:origin, color=:red)
        gui()
    end
end


for (root, dirs, files) in walkdir("../data/2025630_2_NG/")
    println("Files in $root")
    for file ∈ files
        !isequal(".csv", last(splitext(file))) && continue
        fullpath = joinpath(root, file)
        # println(fullpath)
        infoxx = tvsf(power32, fullpath; verbose=false,lr=1e-2,epochs=800)
        nx,tx = drawtn(LineCoef(coef, infoxx))
        plot!(tx,nx, framestyle=:origin, color=:purple)
        gui()
    end
end


plot!(t, n, framestyle=:origin, linewidth=3, color=:black, alpha=0.5, xlims=(0, 1.2), leg=nothing)
xticks!(0:0.1:1.5)
yticks!(0:200:2400)
ylabel!("rmp")
xlabel!("N*m")
