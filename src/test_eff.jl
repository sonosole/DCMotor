begin
    LR = 1E-3
    EPOCHS = 10000
    Coef = 40
    RPM, Nm, Fs, Nmax, y = read_dc_motor2("./data/motor3/data12.txt")
    Fmax = Coef * Nmax/60
    Fmin = 600
    @time calibrate(
        y,
        Nmax,
        Fmin,
        Fmax,
        Fs,
        RPM,
        Nm, lr=LR,epochs=EPOCHS)
    torque, speed, curr, idx = estimate(y, lr=LR,epochs=EPOCHS);
    p1 = plot(y)
    p2 = plot(torque, speed);plot!([Nm],[RPM], marker=3)
    plot(p1, p2, layout=(2,1))
end

begin
    LR = 1E-3
    EPOCHS = 10000
    Coef = 40
    RPM, Nm, Fs, Nmax, y = read_dc_motor2("d:/repos/DCMotor/data/motor3/data9.txt")
    Fmax = Coef * Nmax/60
    Fmin = 200
    power = PowerSpec(
            fs   = floor(Int, Fs),
            fmin = Fmin,
            fmax = Fmax,
            winlen = 4096,
            stride = 128,
            nffts = 4096*8,
            donorm = true,
            winfunc = nuttall,
            type = Vector{Float32})
    Xω = log.(1e-0 .+ power(y))

    @time x, yt, yf = debug(
        y,
        Nmax,
        Fmin,
        Fmax,
        Fs,
        RPM,
        Nm, lr=LR,epochs=EPOCHS)
    torque, speed, curr, idx = estimate(y, lr=LR,epochs=EPOCHS);
    p1 = plot(x,yt,label="true");plot!(x,yf,label="fitted",framestyle=:origin)
    p2 = heatmap(Xω)
    plot(p1, p2, layout=(2,1))
end



begin
    LR = 1E-3
    EPOCHS = 10000
    Coef = 40
    RPM, Nm, Fs, Nmax, y = read_dc_motor2("d:/repos/DCMotor/data/motor2/data2.txt")
    FT = Butterworth(4)
    LP = Highpass(150, fs=Fs)
    lpf = digitalfilter(LP, FT)
    tf  = convert(PolynomialRatio, lpf)
    current = Float32.(filtfilt(tf, y))
    trend = y - current
    raw, fil = time_freq_diff(y, 15, 1800)
    p1 = heatmap(log.(1e1 .+ raw),leg=false)
    p2 = heatmap(log.(1e1 .+ fil),leg=false)
    p3 = plot(y,framestyle=:origin);plot!(trend,label="trend")
    plot(p1, p2, p3, layout=(3,1), size=(1024,666))
end



for (root, dirs, files) in walkdir("./data/motor1/")
    println("Files in $root")
    for file ∈ files
        !isequal(".txt", last(splitext(file))) && continue
        fullpath = joinpath(root, file)
        LR = 1E-3
        EPOCHS = 10000
        Coef = 40
        try
        RPM, Nm, Fs, Nmax, y = read_dc_motor2(fullpath)
        Fmax = Coef * Nmax/60
        Fmin = 110
        @time calibrate(
            y,
            Nmax,
            Fmin,
            Fmax,
            Fs,
            RPM,
            Nm, lr=LR,epochs=EPOCHS)
        torque, speed, curr, idx = estimate(y, lr=LR,epochs=EPOCHS);
        p1 = plot(y)
        p2 = plot(torque, speed);plot!([Nm],[RPM], marker=3)
        plot(p1, p2, layout=(2,1))
        gui()
        catch
            plot(y);gui()
        end
        sleep(1)
    end
end



plot()

for (root, dirs, files) in walkdir("./data/motor1/")
    println("Files in $root")
    for file ∈ files
        !isequal(".txt", last(splitext(file))) && continue
        fullpath = joinpath(root, file)
        RPM, Nm, Fs, Nmax, y = read_dc_motor2(fullpath)
        torque, speed, curr, idx = estimate(y, lr=LR,epochs=EPOCHS);
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
        read_dc_motor(fullpath), lr=LR,epochs=EPOCHS);
        plot!(torque, speed, framestyle=:origin, color=:red, leg=nothing)
        gui()
    end
end


for (root, dirs, files) in walkdir("../data/2025630_2_NG/")
    println("Files in $root")
    for file ∈ files
        !isequal(".csv", last(splitext(file))) && continue
        fullpath = joinpath(root, file)
        @time torque, speed, curr, idx = estimate(
        read_dc_motor(fullpath), lr=LR,epochs=EPOCHS);
        plot!(torque, speed, framestyle=:origin, color=:cyan, leg=nothing)
        gui()
    end
end
