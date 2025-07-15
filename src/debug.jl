function tfcurve(power::PowerSpec, csv::String; lr::Real=1e-2, epochs::Int=500, verbose::Bool=false)
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

    # 时域最大值点最为像两侧搜索的起点
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
    # 像右侧搜索维持递增的最大索引
    IMAX = idxsearch
    for i = idxsearch : 1 : COLS-1
        if fids[i] > fids[i+1]
            IMAX = i
            break
        end
    end

    println("起始频率为 $IMIN:$IMAX  $COLS")

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

    Δt = dt(power)
    t = x .* Δt
    T = N * dt(power)             # 持续拟合时间,电机加速时间
    F = getfreq(power, MAX, ROWS) # DC 电机最高频率
    p = fity(x, K, X₀, y₀) .* F   # 预测值
    fig = plot(t, p, label="predicted")
    plot!(t, y .* F, label="observed")
    return fig
end


function showspec(power::PowerSpec, csv::String)
    x  = read_dc_motor(csv)
    Xω = power(x)
    return heatmap(Xω)
end


function ftrend(power::PowerSpec, csv::String)
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

    # 时域最大值点最为像两侧搜索的起点
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
    println("起始频率为 $IMIN")
    println("最大频率为 $COLS")

    return plot(fids)
end
