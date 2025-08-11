# module

using AcousticFeatures
using Mira
using Plots
using DSP

# 约束到 (ϵ, 1-ϵ)
function clamp01(x::T) where T
    ϵ = T(1e-19)
    l = one(T)
    return clamp(x, ϵ, l - ϵ)
end

# 时间分辨率
function dt(P::PowerSpec)
    F = P.fs
    S = P.stride
    seconds = S / F
    return seconds
end

# 按比例跟偏置计算等效频率
# (i-1)/(N-1) = (f-fmin)/(fmax-fmin)
# f = (i-1)/(N-1) * (fmax-fmin) + fmin
function getfreq(P::PowerSpec, i::Real, N::Real)
    fs   = P.fs
    IMIN = P.fminidx
    IMAX = P.fmaxidx
    NFFT = P.nffts
    fmin = floor(Int, (IMIN - 1)/(NFFT - 1) * fs)
    fmax =  ceil(Int, (IMAX - 1)/(NFFT - 1) * fs)
    return (i-1)/(N-1) * (fmax-fmin) + fmin
end


"""
观测值 xᵢ, yᵢ
    y₀ = 1 - ∑ᵢ( exp(-k * (xᵢ+x₀)) + yᵢ )
"""
function gety₀(x::Vector{T}, y::Vector{T}, k::Real, x₀::Real) where T
    l = one(T)
    N = T(length(x))
    y₀ = l - sum(@. exp(-k * (x + x₀)) + y) / N
    # return clamp01(y₀)
    return y₀
end


global FMIN::Real = 100
global FMAX::Real = 1100
global RATE::Real = 60240
global F2N::Real
global GD2::Real


function set_fmin_fmax_fs!(fmin, fmax, fs)
    global RATE = floor(Int, fs)
    global FMAX = min(2fmax, RATE/2) # 故意放大范围
    global FMIN = fmin               # 范围不放大，保守
    return nothing
end

function setfmax!(fmax)
    coef = 1.2f0 # 适当地放大搜索范围
    global FMAX = min(coef*fmax, RATE/2)
    return nothing
end



function getxyetc(v::Vector{D}) where D <: Real
    global FMIN
    global FMAX
    global RATE
    power = PowerSpec(
            fs   = floor(Int, RATE),
            fmin = FMIN,
            fmax = FMAX,
            winlen = 4096,
            stride = 128,
            nffts = 4096*8,
            donorm = true,
            winfunc = nuttall,
            type = Vector{D})
    Xω = power(v)
    # 以最大值为时频图的脊线,ROWS对应频率轴,COLS对应时间轴
    ROWS, COLS = size(Xω)
    fids = Vector{D}(undef, COLS)
    for cindx ∈ argmax(Xω, dims=1)
        rowi, coli = Tuple(cindx)
        fids[coli] = rowi
    end

    # 时域最大值点,作为向左侧搜索的起点
    Lv = length(v)
    ratio = argmax(v) / Lv
    idxsearch = max(floor(Int, ratio * COLS), 1)

    # 向左侧搜维持频率递减的最小索引
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
    x = Vector{D}(undef, N)
    N⁻¹ = D(1 / N)
    for n = 1 : N
        @inbounds x[n] = n * N⁻¹
    end

    T = N * dt(power)             # 持续拟合时间,电机加速时间
    F = getfreq(power, MAX, ROWS) # 最高频率,以 Hz 为单位
    S = power.stride
    return x, y, T, F, S, IMIN, COLS
end



function train(x::Vector{T}, y::Vector{T}; epochs::Int=15000, lr=1e-2, verbose=false) where T <: Real
    k  = Info(T[8.0], keepsgrad=true, type=Array{T})
    x₀ = Info(T[0.0], keepsgrad=true, type=Array{T})

    xparms = Vector{Tuple{Char, Info}}()
    push!(xparms, ('w', k))
    push!(xparms, ('w', x₀))

    opt = Adam(xparms; lr)

    # 初始化参数值
    K  = one(T)
    X₀ = zero(T)
    y₀ = zero(T)

    l = one(T)
    for e ∈ 1:epochs
        ỹ = l .- exp(-k .* (x .+ x₀)) .- y₀
        L = MSELoss(ỹ, y, reduction="mean")
        C = cost(L)

        verbose && println("$e/$epochs: loss=", C)

        Mira.zerograds!(opt)
        Mira.backward(L)
        Mira.update!(opt)

        K  = first( ᵈ(k)  )
        X₀ = first( ᵈ(x₀) )
        y₀ = gety₀(x, y, K, X₀)
    end
    return K, X₀, y₀
end


function calibrate(v::Vector{D}, Nmax::Real,
                                 Fmin::Real,
                                 Fmax::Real,
                                   Fs::Real, 
                                  RPM::Real, 
                                   Nm::Real; verbose::Bool=false) where D
    set_fmin_fmax_fs!(Fmin, Fmax, Fs)
    x, y, T, F, S, IMIN, COLS = getxyetc(v)
    k, x₀, y₀ = train(x, y; verbose)
    N  = Nmax
    τₒₖ = Nm
    nₒₖ = RPM
    global GD2 = τₒₖ * T / ( k * N * (1 - y₀ - nₒₖ/N) )
    global F2N = N / F
    setfmax!(F)
    return nothing
end



# 应该从起点开始对齐，终点对齐就会取到横坐标Inf的点
function estimate(v::Vector{D}, fs::Real; verbose::Bool=false) where D
    x, y, T, F, S, IMIN, COLS = getxyetc(v)
    k, x₀, y₀ = train(x, y; verbose)
    Lx = length(x)
    Lv = length(v)
    l = one(D)
    o = zero(D)
    
    # 转速为零时候x取值
    zerospeedx = -log(l - y₀) / k - x₀
    # 转速为零时的 x 取值，对应的，在时频图的时间开始索引
    tinit = IMIN + zerospeedx * Lx
    # 时频图的比例折算成电流采样的开始索引
    vinit = (tinit - 1) / (COLS - 1) * (Lv - 1) + 1

    global F2N
    global GD2
    global FMIN
    global RATE
    
    Q = GD2
    N = F * F2N
    k⁻¹  = inv(k)
    nmax = N * (1 - y₀)
    τmax = k * Q * N * (1 - y₀) / T
    nspan  = range(0, nmax, 1000)
    nbins  = length(nspan)
    torque = Vector{D}(undef, nbins)
    speed  = Vector{D}(undef, nbins)
    eleci  = Vector{D}(undef, nbins)
    
    for (i, n) ∈ enumerate(nspan)
        C = max(o, l - y₀ - n / N)
        println(C)
        speed[i] = n
        torque[i] = k * Q * N / T * C
        eleci[i] = Lx * S * (- x₀ - k⁻¹ * log(C))
    end
    eleci[nbins] = eleci[nbins-1]
    irange = floor.(Int, eleci .+ vinit)
    FT = Butterworth(4)
    LP = Lowpass(FMIN, fs=RATE)
    lpf = digitalfilter(LP, FT)
    tf  = convert(PolynomialRatio, lpf)
    return torque, speed, filtfilt(tf, v)[irange], irange
end



# end



    
      