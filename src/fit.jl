function tvsf(power::PowerSpec, csv::String; lr::Real=1e-2, epochs::Int=500, verbose::Bool=false)
    # 读取文件并求功率谱
    v  = read_dc_motor(csv)
    Xω = power(v)

    # 以最大值为时频图的脊线
    ROWS, COLS = size(Xω)
    fids = Vector{Float32}(undef, COLS)
    for cindx ∈ argmax(Xω, dims=1)
        rowi, coli = Tuple(cindx)
        fids[coli] = rowi
    end

    # 逆向保持单调递减的最小时间下标
    IMIN = COLS
    for i = COLS : -1 : 2
        if fids[i] < fids[i-1]
            IMIN = i
            break
        end
    end

    # 用最大值将频率坐标归一化到 [0,1] 范围内
    MAX = last(fids)
    fids .*= inv(MAX)

    # 只取单调的那部分频率
    y = fids[IMIN:COLS]

    # 使用归一化的时间坐标 [1/N, 1]
    N = length(y)
    x = collect(1:N) ./ N

    # 系数来自函数 y(x) = 1 - exp[k(x+x₀)] - y₀
    k  = Info([8.0], keepsgrad=true)
    x₀ = Info([0.0], keepsgrad=true)
    xparms = Vector{Tuple{Char, Info}}()
    push!(xparms, ('w', k))
    push!(xparms, ('w', x₀))
    opt = Adam(xparms; lr)

    # 初始化参数值
    K  = first( ᵈ(k)  )
    X₀ = first( ᵈ(x₀) )
    y₀ = gety0(x, y, K, X₀)

    for e ∈ 1:epochs
        ỹ = 1f0 .- exp(-k .* (x .+ x₀)) .- y₀
        L = MSELoss(ỹ, y, reduction="mean")
        C = cost(L)

        verbose && println("$e/$epochs: loss=", C)

        Mira.zerograds!(opt)
        Mira.backward(L)
        Mira.update!(opt)

        K  = first( ᵈ(k)  )
        X₀ = first( ᵈ(x₀) )
        y₀ = gety0(x, y, K, X₀)

        if C < 1e-4 && e > 10
            break
        end
    end

    T = N * dt(power)             # 持续拟合时间,电机加速时间
    F = getfreq(power, MAX, ROWS) # DC 电机最高频率
    return TSInfo(y₀, K, T, F)
end


struct TSInfo
    y₀ :: Real
    k  :: Real
    T  :: Real
    F  :: Real
    function TSInfo(y₀::Real, K::Real, T::Real, F::Real)
        new(y₀, K, T, F)
    end
end


# calibration via rmp and Nm⁻¹
struct TSCoef
    F2N :: Real
    GD2 :: Real
    function TSCoef(tsinfo::TSInfo, rmp::Real, Nm⁻¹::Real)
        y₀ = tsinfo.y₀
        k  = tsinfo.k
        T  = tsinfo.T
        F  = tsinfo.F
        F2N = rmp / F
        GD2 = Nm⁻¹ / ( (1-y₀)*k/T * rmp )
        new(F2N, GD2)
    end
end


struct LineCoef
    y₀ :: Real
    k  :: Real
    T  :: Real
    N  :: Real
    Q  :: Real
    function LineCoef(coef::TSCoef, info::TSInfo)
        y₀ = info.y₀
        k  = info.k
        T  = info.T
        N  = info.F * coef.F2N
        Q  = coef.GD2
        new(y₀, k, T, N, Q)
    end
end


function drawtn(LC::LineCoef)
    y₀ = LC.y₀
    k  = LC.k
    T  = LC.T
    Q  = LC.Q
    N  = floor(Int, LC.N)
    torque = Vector{Float32}(undef, N+1)
    for n = 0:N
        torque[n+1] = Q * k * N / T * (1 - y₀ - n/N)
    end
    return 0:N, torque
end


