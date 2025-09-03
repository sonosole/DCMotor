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
    EPOCHS = 25000
    Fmax = 4000
    Fmin = 400
    plot()
    for (root, dirs, files) in walkdir("d:/repos/DCMotor/data/motor1/")
        println("Files in $root")
        for file ∈ files
            !isequal(".txt", last(splitext(file))) && continue
            fullpath = joinpath(root, file)
            RPM, Nm, Fs, Nmax, y = read_dc_motor2(fullpath)
            x, yobs, yfitted = debug(
                y, Nmax, Fmin, Fmax, Fs, RPM, Nm, lr=LR,epochs=EPOCHS)
            plot(x, yobs, leg=nothing,framestyle=:origin);
            plot!(x, yfitted, leg=nothing);gui()
            sleep(1)
            # push!(plts, p)
        end
    end
    # plot(plts...)
end


function TocToc.debug(i::Vector{D}, Nmax::Real,
                             Fmin::Real,
                             Fmax::Real,
                             Fs::Real,
                             RPM::Real,
                             Nm::Real;
                             lr::Real=1e-3,
                             epochs::Int=25000,
                             verbose::Bool=false) where D
    TocToc.set_fmin_fmax_fs!(Fmin, Fmax, Fs)
    x, y, T, F, S, IMIN, COLS = getxyetc(i)
    k, x₀, y₀ = TocToc.train(x, y; verbose, epochs, lr)
    println("$k,$x₀,$y₀")
    return x, y, TocToc.fity(x, k, x₀, y₀)
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



f(x::Real, k::Real) = 1 - exp(-k*x)

function testy(x::Vector{T},
               y::Vector{T};
               lr::Real=1e-3,
               epochs::Int=25000,
               verbose::Bool=false) where T <: Real
    k    = T(8.0)
    ∂k   = zero(T)
    ∇¹k = zero(T)
    ∇²k = zero(T)

    x₀    = zero(T)
    ∂x₀   = zero(T)
    ∇¹x₀ = zero(T)
    ∇²x₀ = zero(T)

    y₀  = zero(T)
    N⁻¹ = inv(length(y))
    l   = one(T)
    ϵ   = 1e-8
    b₁  = 0.9
    b₂  = 0.999
    b₁ᵗ = b₁
    b₂ᵗ = b₂

    for e ∈ 1:epochs
        X = x .+ x₀
        E = exp.(-k .* X)
        ỹ = (l - y₀) .- E
        Y = ỹ - y
        L = sum(Y .* Y) * N⁻¹

        verbose && println("$e/$epochs: loss=", L)

        ∂k   = sum(@. Y * X * E)
        ∇¹k = b₁ * ∇¹k + (l-b₁) * ∂k
        ∇²k = b₂ * ∇²k + (l-b₂) * ∂k * ∂k

        ∂x₀   = k * sum(@. Y * E)
        ∇¹x₀ = b₁ * ∇¹x₀ + (l-b₁) * ∂x₀
        ∇²x₀ = b₂ * ∇²x₀ + (l-b₂) * ∂x₀ * ∂x₀

        μ   = - sqrt(l-b₂ᵗ) / (l-b₁ᵗ) * lr
        k  += μ * ∇¹k  / sqrt(∇²k  + ϵ)
        x₀ += μ * ∇¹x₀ / sqrt(∇²x₀ + ϵ)
        y₀  = gety₀(x, y, k, x₀)

        b₁ᵗ *= b₁
        b₂ᵗ *= b₂
    end
    return k, x₀, y₀
end

function fity(x::Vector{T}, k::Real, x₀::Real, y₀::Real) where T
    l = one(T)
    y = @. l - exp(-k * (x + x₀)) - y₀
    return y
end

function gety₀(x::Vector{T}, y::Vector{T}, k::Real, x₀::Real) where T
    l  = one(T)
    N  = T(length(x))
    y₀ = l - sum(@. exp(-k * (x + x₀)) + y) / N
    return y₀
end


begin
    x = collect(0.01:1e-2:1)
    n = length(x)
    y = f.(x, 9)
    plot(x,y,marker=2)
    k,x0,y0=testy(collect(range(0,1,n)),y)
    plot!(x,fity(x, k,x0,y0),framestyle=:origin)
end


