function tvsf(power::PowerSpec, v::Vector{Float32}; lr::Real=1e-2, epochs::Int=5000, verbose::Bool=false)
    # 求功率谱
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

        if C < 1e-4 && e > 10
            break
        end
    end

    T = N * dt(power)             # 持续拟合时间,电机加速时间
    F = getfreq(power, MAX, ROWS) # DC 电机最高频率

    return TSInfo(y₀, K, T, F)
end
