begin
    Coef = 40
    Nmax = 3000
    Fmax = Coef * Nmax/60
    Fmin = 110
    Fs   = 60240
    RPM  = 2000
    Nm   = 1.0
    
    @time calibrate(
        read_dc_motor("../data/2025630_1_OK/113443396.csv"),
        Nmax,
        Fmin,
        Fmax,
        Fs,
        RPM,
        Nm, lr=1e-2,epochs=10000)
end

plot()

for (root, dirs, files) in walkdir("../data/2025630_1_OK/")
    println("Files in $root")
    for file ∈ files
        !isequal(".csv", last(splitext(file))) && continue
        fullpath = joinpath(root, file)
        torque, speed, curr, idx = estimate(
        read_dc_motor(fullpath), lr=1e-2,epochs=10000);
        plot!(torque, speed, framestyle=:origin, color=:green, leg=nothing)
        gui()
    end
end


for (root, dirs, files) in walkdir("../data/2025630_1_NG/")
    println("Files in $root")
    for file ∈ files
        !isequal(".csv", last(splitext(file))) && continue
        fullpath = joinpath(root, file)
        torque, speed, curr, idx = estimate(
        read_dc_motor(fullpath), lr=1e-2,epochs=10000);
        plot!(torque, speed, framestyle=:origin, color=:red, leg=nothing)
        gui()
    end
end


for (root, dirs, files) in walkdir("../data/2025630_2_NG/")
    println("Files in $root")
    for file ∈ files
        !isequal(".csv", last(splitext(file))) && continue
        fullpath = joinpath(root, file)
        torque, speed, curr, idx = estimate(
        read_dc_motor(fullpath), lr=1e-2,epochs=10000);
        plot!(torque, speed, framestyle=:origin, color=:cyan, leg=nothing)
        gui()
    end
end

let
    @time torque, speed, curr, idx = estimate(
        read_dc_motor("../data/2025630_1_OK/113443396.csv"), lr=1e-2,epochs=10000);
    plot!(torque, speed, framestyle=:origin, color=:black, leg=nothing)
    plot!([Nm], [RPM], marker=2)
    ylabel!("rmp")
    xlabel!("N*m")
    xticks!(0:0.2:3.6)
end
