# module

using AcousticFeatures
using Mira
using Plots

# 约束到 (ϵ, 1-ϵ)
function clamp01(x::T) where T
    EPS = T(1e-9)
    ONE = one(T)
    return clamp(x, EPS, ONE - EPS)
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
function gety0(x::Vector{T}, y::Vector{T}, k::Real, x₀::Real) where T
    l = one(T)
    N = T(length(x))
    y₀ = l - sum(@. exp(-k * (x + x₀)) + y) / N
    return clamp01(y₀)
end


global FMIN::Int  = 100
global FMAX::Real = 1100
global RATE::Real = 60240

function set_fmin_fmax_fs!(fmin, fmax, fs)
    global FMIN = fmin
    global FMAX = fmax
    global RATE = floor(Int, fs)
    return nothing
end


global F2N::Real
global GD2::Real

function getxyTF(v::Vector{D}) where D <: Real
    global FMIN
    global FMAX
    global RATE
    power = PowerSpec(
            fs = RATE,
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
    ratio = argmax(v) / length(v)
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
    F = getfreq(power, MAX, ROWS) # 最高频率,  以 Hz 为单位

    return x, y, T, F
end



function train(x::Vector{T}, y::Vector{T}; epochs::Int=500, lr=1e-2, verbose=false) where T <: Real
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
        y₀ = gety0(x, y, K, X₀)
    end
    return K, X₀, y₀
end


function calibrate(v::Vector{D}, fmax::Real, fs::Real, RPM::Real, Nm::Real; verbose=false) where D
    set_fmin_fmax_fs!(100, fmax, fs)
    x, y, T, F = getxyTF(v)
    k, x₀, y₀  = train(x, y, verbose=false)
    global F2N = RPM / F
    global GD2 = Nm * T / ( k * RPM * (1-y₀) )
    return nothing
end


function estimate(v::Vector{D}, fmax::Real, fs::Real; verbose=false) where D
    set_fmin_fmax_fs!(100, fmax, fs)
    x, y, T, F = getxyTF(v)
    k, x₀, y₀  = train(x, y, verbose=false)
    global F2N
    global GD2
    L = length(x)
    Q = GD2
    N = floor(Int, F * F2N) # 最大转速
    torque = Vector{D}(undef, N+1)
    speed  = Vector{D}(undef, N+1)
    eleci  = Vector{D}(undef, N+1)
    k⁻¹ = inv(k)
    println(1 - y₀)
    println(x₀)
    for n = 0 : N
        C = 1 - y₀ - (n+1) / N
        speed[n+1] = n
        torque[n+1] = k * Q * N / T * C
        if C>0
        eleci[n+1] = L * (- x₀ - k⁻¹ * log(C))
        else
            eleci[n+1] = 0
        end
    end
    return torque, speed, eleci
end


# end



