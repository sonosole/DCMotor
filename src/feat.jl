using AcousticFeatures
using CubicSplines
using Mira, Plots
using Wavelets

FMIN = 100
FMAX = 1100
RATE = 60240
power32 = PowerSpec(
            fs = RATE,
            fmin = FMIN,
            fmax = FMAX,
            winlen = 4096,
            stride = 128,
            nffts = 4096*8,
            donorm = true,
            winfunc = nuttall,
            type = Vector{Float32})


"""
观测值 xᵢ, yᵢ
    y₀ = 1 - ∑ᵢ( exp(-k * (xᵢ+x₀)) + yᵢ )
"""
function gety0(x::Vector{T}, y::Vector, k::Real, x₀::Real) where T
    l = one(T)
    N = T(length(x))
    y₀ = l - sum(@. exp(-k * (x + x₀)) + y) / N
    return clamp01(y₀)
end


"""
    y(x) = 1 - exp[-k * (xᵢ+x₀)] - y₀
"""
function fity(x::Vector{T}, k::Real, x₀::Real, y₀::Real) where T
    l = one(T)
    y = @. l - exp(-k * (x + x₀)) - y₀
    return y
end


function fminfmax(P::PowerSpec)
    fs   = P.fs
    IMIN = P.fminidx
    IMAX = P.fmaxidx
    NFFT = P.nffts
    fmin = floor(Int, (IMIN - 1)/(NFFT - 1) * fs)
    fmax =  ceil(Int, (IMAX - 1)/(NFFT - 1) * fs)
    return fmin, fmax
end


function dt(P::PowerSpec)
    F = P.fs
    S = P.stride
    seconds = S / F
    return seconds
end


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
    rspeed(f::Real, k::Int, p::Int) -> rpm::Real
- `f`: frequency
- `k`: 换向器片数
- `p`: 极对数
- `rpm`: 每分钟转速
"""
function rspeed(f::Real, k::Int, p::Int)
    c = iseven(k) ? 1 : 2
    n = 60 * f / (c * k * p)
    return n
end


function clamp01(x::T) where T
    EPS = T(1e-9)
    ONE = one(T)
    return clamp(x, EPS, ONE - EPS)
end
