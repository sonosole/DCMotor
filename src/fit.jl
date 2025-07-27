function tvsf(power::PowerSpec, csv::String; lr::Real=1e-2, epochs::Int=500, verbose::Bool=false)
    # 读取文件并求功率谱
    v  = read_dc_motor(csv)
    Xω = power(v)

    # 以最大值为时频图的脊线,ROWS对应频率轴,COLS对应时间轴
    ROWS, COLS = size(Xω)
    fids = Vector{Float32}(undef, COLS)
    for cindx ∈ argmax(Xω, dims=1)
        rowi, coli = Tuple(cindx)
        fids[coli] = rowi
    end

    # 时域最大值点,作为向左侧搜索的起点
    ratio = argmax(v) / length(v)
    idxsearch = max(floor(Int, ratio * COLS), 1)
    
    # 向左侧搜维持递减的最小索引
    IMIN = idxsearch
    for i = idxsearch : -1 : 2
        if fids[i-1] > fids[i]
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
    end

    T = N * dt(power)             # 持续拟合时间,电机加速时间
    F = getfreq(power, MAX, ROWS) # DC 电机最高频率

    # 转速为零时候x取值
    zerospeedx = -log(1f0 - y₀) / K - X₀
    # 转速为零时的x取值，对应的，在时频图的时间开始索引
    INITidx = IMIN + zerospeedx * N
    # 时频图的比例折算成电流采样的开始索引
    # Lv = length(v)
    # tidx = (INITidx - 1) / (COLS - 1) * (Lv - 1) + 1
    # println("zero_speed_x = ", zero_speed_x*N)
    return TSInfo(y₀, K, T, F)#, v[tidx : Lv]
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


# calibration via rpm and Nm
struct TSCoef
    F2N :: Real
    GD2 :: Real
    function TSCoef(tsinfo::TSInfo, rpm::Real, Nm::Real)
        y₀ = tsinfo.y₀
        k  = tsinfo.k
        T  = tsinfo.T
        F  = tsinfo.F
        F2N = rpm / F
        GD2 = Nm * T / ( k * rpm * (1-y₀) )
        new(F2N, GD2)
    end
end


# n-T 曲线线性资料
# https://www.nidec-group.cn/technology/motor/basic/00213
# https://journals.nwpu.edu.cn/xbgydxxb/FileUp/HTML/20160620.htm
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
        torque[n+1] = k * Q * N / T * (1 - y₀ - n/N)
    end
    return 0:N, torque
end


