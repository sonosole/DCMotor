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
        Nm, lr=2e-3,epochs=10000)
end

plot()

for (root, dirs, files) in walkdir("../data/2025630_1_OK/")
    println("Files in $root")
    for file ∈ files
        !isequal(".csv", last(splitext(file))) && continue
        fullpath = joinpath(root, file)
        torque, speed, curr, idx = estimate(
        read_dc_motor(fullpath), lr=2e-3,epochs=10000);
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
        read_dc_motor(fullpath), lr=2e-3,epochs=10000);
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
        read_dc_motor(fullpath), lr=2e-3,epochs=10000);
        plot!(torque, speed, framestyle=:origin, color=:cyan, leg=nothing)
        gui()
    end
end

let
    @time torque, speed, curr, idx = estimate(
        read_dc_motor("../data/2025630_1_OK/113443396.csv"), lr=2e-3,epochs=10000);
    plot!(torque, speed, framestyle=:origin, color=:black, leg=nothing)
    plot!([Nm], [RPM], marker=2)
    ylabel!("rmp")
    xlabel!("N*m")
    xticks!(0:0.1:3.4)
    xaxis!(rotation=45)
end

let
    COUNT = 1
    while true
        println(COUNT)
        COUNT += 1
        sleep(1)
        try
            if rand() > 0.5
                torque, speed, curr, idx = estimate(
                read_dc_motor("../data/2025630_1_OK/113443396.csv"), lr=2e-3,epochs=10000);
            else
                torque, speed, curr, idx = estimate(
                randn(Float32, 60240), lr=2e-3,epochs=10000);
            end
        catch err
            println("bad happened")
        end
    end
end
