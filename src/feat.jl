using AcousticFeatures
using CubicSplines
using Mira, Plots


FMIN = 100
FMAX = 1100
power32 = PowerSpec(
            fs = 60240,
            fmin = FMIN,
            fmax = FMAX,
            winlen = 4096,
            stride = 128,
            nffts = 4096*8,
            donorm = true,
            winfunc = nuttall,
            type = Vector{Float32})

function gety0(x::Vector{T}, ỹ::Vector, k::Real, x0::Real) where T
    l = one(T)
    N = T(length(x))
    return l - sum(@. exp(-k * (x + X0)) + ỹ) / N
end


function fitted(x::Vector{T}, k::Real, x0::Real, y0::Real) where T
    l = one(T)
    return @. l - exp(-k * (x + X0)) - y0
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


# (i-1)/(N-1) = (f-fmin)/(fmax-fmin)
function freq(P::PowerSpec, i::Int, N::Int)
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

