struct NDFT{D}
    dilation :: Int        # 降采样因子
    stride   :: Int        # 分帧参数-帧移
    ndfts    :: Int        # 傅立叶变换点数
    winlen   :: Int        # 加窗的长度
    window   :: Array{D}   # 窗函数数值表示
    freq :: StepRangeLen
    wmat :: Matrix{Complex{D}}
    function NDFT{D}(;
        fs       :: Real = 16000,
        fmin     :: Real = 0,
        fmax     :: Real = fs>>1,
        winlen   :: Int = 256,
        dilation :: Int = 1,
        stride   :: Int = winlen>>1,
        ndfts    :: Int = winlen,
        winfunc  :: Function = hanning,
        donorm   :: Bool = false,
        type     :: DataType = Vector{Float32}) where D

        @assert 0 ≤ fmin < fmax ≤ fs/2 begin
            "0 ≤ fmin < fmax ≤ fs/2, but got 0 ≤ $fmin < $fmax ≤ $(fs/2)"
        end
        
        N = ndfts
        T = winlen
        w = exp(- im * D(2 * π / N))

        #: (idx-1)/(ndfts-1) = (f - 0)/(fs - 0)
        KMIN = floor(Int, (ndfts-1) * fmin / fs + 1)
        KMAX = floor(Int, (ndfts-1) * fmax / fs + 1)

        K = KMAX - KMIN  + 1
        k = reshape(D.(KMIN : KMAX), K, 1)   # index range of frequency
        t = reshape(D.(0 : T - 1),   1, T)   # index range of time

        wmat = w .^ (k * t)                  # tranformation matrix
        freq = range(fmin, fmax, K)
        window = winfunc(winlen, type)
        if donorm
            coeff = sqrt(sum(window .^ 2))
            window .*= inv(coeff)
        end
        return new{D}(dilation,stride,ndfts,winlen,window, freq, wmat)
    end
end


function Base.show(io::IO, ::MIME"text/plain", D::NDFT{T}) where T
    f = D.freq
    print(io, "NDFT{$T} $f")
end


function (P::NDFT{T})(data::Vector{T}) where T
    w = P.wmat
    x = AcousticFeatures.split4fft(data, P.window, P.dilation, P.stride, P.winlen)
    y = abs2.(w * x)
    return y
end


# AcousticFeatures.split4fft(data, power64.window, power64.dilation, power64.stride, power64.winlen)

