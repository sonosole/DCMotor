info = tvsf(power32, "../data/2025630_1_OK/113443396.csv";verbose=false,lr=1e-2,epochs=800)
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
        println(fullpath)
        infoxx = tvsf(power32, fullpath; verbose=false,lr=1e-2,epochs=800)
        nx,tx = drawtn(LineCoef(coef, infoxx))
        plot!(tx.*nx.*0.095, color=:green, leg=nothing)
        gui()
    end
end
plot!(t.*n.*0.095, line=:dashdot, color=:green, alpha=0.5, leg=nothing)


for (root, dirs, files) in walkdir("../data/2025630_1_NG/")
    println("Files in $root")
    for file ∈ files
        !isequal(".csv", last(splitext(file))) && continue
        fullpath = joinpath(root, file)
        println(fullpath)
        infoxx = tvsf(power32, fullpath; verbose=false,lr=1e-2,epochs=800)
        nx,tx = drawtn(LineCoef(coef, infoxx))
        plot!(tx.*nx.*0.095, color=:red, leg=nothing)
        gui()
    end
end


for (root, dirs, files) in walkdir("../data/2025630_2_NG/")
    println("Files in $root")
    for file ∈ files
        !isequal(".csv", last(splitext(file))) && continue
        fullpath = joinpath(root, file)
        println(fullpath)
        infoxx = tvsf(power32, fullpath; verbose=false,lr=1e-2,epochs=800)
        nx,tx = drawtn(LineCoef(coef, infoxx))
        plot!(tx.*nx.*0.095, color=:cyan, leg=nothing)
        gui()
    end
end

ylabel!("efficient %")
yticks!(0:5:70)
