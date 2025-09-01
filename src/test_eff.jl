begin
    LR = 1E-3
    EPOCHS = 10000
    Coef = 40
    RPM, Nm, Fs, Nmax, y = read_dc_motor2("d:/repos/DCMotor/data/motor3/data12.txt")
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
    RPM, Nm, Fs, Nmax, y = read_dc_motor2("d:/repos/DCMotor/data/motor1/data5.txt")
    Fmax = 4000
    Fmin = 0
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
    EPS = 1E-1
    X1 = power(y[2:end])
    X2 = power(diff(y))
    X3 = X1 .* X2
    plot(
    heatmap(log.(EPS .+ X1)),
    heatmap(log.(EPS .+ X2)),
    heatmap(log.(EPS .+ X3)),
    plot(y,framestyle=:origin),layout=(4,1))
end




begin
    RPM, Nm, Fs, Nmax, y = read_dc_motor2("d:/repos/DCMotor/data/motor3/data9.txt")
    plot(plot(y),plot(diff(y)),layout=(2,1))
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



for (root, dirs, files) in walkdir("d:/repos/DCMotor/data/motor3/")
    println("Files in $root")
    plot()
    LR = 1E-3
    EPOCHS = 25000
    Coef = 40
    RPM, Nm, Fs, Nmax, y = read_dc_motor2("d:/repos/DCMotor/data/motor3/data1.txt")
    Fmax = 3000
    Fmin = 600
    @time calibrate(
        y,
        Nmax,
        Fmin,
        Fmax,
        Fs,
        RPM,
        Nm, lr=LR,epochs=EPOCHS)
    plot!([Nm],[RPM], marker=3)

    for file ∈ files
        !isequal(".txt", last(splitext(file))) && continue
        fullpath = joinpath(root, file)
        try
            RPM, Nm, Fs, Nmax, y = read_dc_motor2(fullpath)
            torque, speed, curr, idx = estimate(y, lr=LR,epochs=EPOCHS);
            plot!(torque, speed, leg=false)
            gui()
        catch
        end
    end
end




# 脊线图的一致性测试
begin
    plts = []
    LR = 2E-3
    EPOCHS = 250000
    Fmax = 4000
    Fmin = 300
    plot()
    for (root, dirs, files) in walkdir("d:/repos/DCMotor/data/motor1/")
        println("Files in $root")
        for file ∈ files
            !isequal(".txt", last(splitext(file))) && continue
            fullpath = joinpath(root, file)
            RPM, Nm, Fs, Nmax, y = read_dc_motor2(fullpath)
            @time x, yobs, yfitted = debug(
                y, Nmax, Fmin, Fmax, Fs, RPM, Nm, lr=LR,epochs=EPOCHS)
            # plot!(x, yobs, leg=nothing);
            plot!(x, yfitted, leg=nothing);gui()
            # push!(plts, p)
        end
    end
    # plot(plts...)
end





function TocToc.getxyetc(i::Vector{D}) where D <: Real
    power = PowerSpec(
            fs   = floor(Int, TocToc.RATE),
            fmin = TocToc.FMIN,
            fmax = TocToc.FMAX,
            winlen = 4096,
            stride = 128,
            nffts = 4096*8,
            donorm = true,
            winfunc = nuttall,
            type = Vector{D})
    
    # 滤波电流信号
    ft = Butterworth(4)
    lp = Lowpass(TocToc.FMIN, fs=TocToc.RATE)
    df = digitalfilter(lp, ft)
    fparams = convert(PolynomialRatio, df)
    trend = D.(filtfilt(fparams, i))
    ihigh = i - trend
    Li    = length(trend)

    Iτω = power(ihigh)# + power(diff(i))

    # 以最大值为时频图的脊线,ROWS对应频率轴,COLS对应时间轴
    ROWS, COLS = size(Iτω)
    fids = Vector{D}(undef, COLS)
    for cindx ∈ argmax(Iτω, dims=1)
        rowi, coli = Tuple(cindx)
        fids[coli] = rowi
    end

    ratio = argmax(trend) / Li
    IMIN  = max(floor(Int, 1.2*ratio * COLS), 1)

    # 用最大值将频率坐标归一化到 [0,1] 范围内
    MAX = last(fids)
    fids .*= inv(MAX)

    # 只取单调的那部分频率
    y = fids[IMIN:COLS]

    # 使用归一化的时间坐标 [1/N, 1]
    N = length(y)
    x = Vector{D}(undef, N)
    N⁻¹ = D(1 / N)
    for n = 1 : N
        x[n] = n * N⁻¹
    end

    T = N * TocToc.dt(power)             # 持续拟合时间,电机加速时间
    F = TocToc.getfreq(power, MAX, ROWS) # 最高频率,以 Hz 为单位
    S = power.stride
    return x, y, T, F, S, IMIN, COLS
end

