using Sockets

# 定义协议常量
const START = "<s>"
const FINAL = "<e>"
const ENCODING = UInt8
const HEAD = transcode(ENCODING, START) # 文件头编码
const TAIL = transcode(ENCODING, FINAL) # 文件尾编码
const lstart = length(START)            # 开始标记长度
const lfinal = length(FINAL)            # 结束标记长度


# 定义地址和端口
ipv4 = IPv4(127, 0, 0, 10)
port = 8000



"""
    putdata(sock::TCPSocket, data::Vector{Float32})

服务端返回格式：
"<s>"
nbytes  :: Int32             # 后续所有数值数据的比特数，不包括结束标志
torque  :: Vector{Float32}   # 转矩
speed   :: Vector{Float32}   # 转速
current :: Vector{Float32}   # 电流
indices :: Vector{Int32}     # 所取电流的实际索引
"<e>"
"""
function putdata(sock::TCPSocket, torque  :: Vector{Float32},
                                  speed   :: Vector{Float32},
                                  current :: Vector{Float32},
                                  indices :: Vector{Int32})
    try
        SIZE = Int32(sizeof(torque) +
                     sizeof(speed) +
                     sizeof(current) +
                     sizeof(indices))
        write(sock, HEAD)     # 发送起始标记
        write(sock, SIZE)     # 发送数据的字节长度
        write(sock, torque)   # 发送二进制数据
        write(sock, speed)    # 发送二进制数据
        write(sock, current)  # 发送二进制数据
        write(sock, indices)  # 发送二进制数据
        write(sock, TAIL)     # 发送结束标记
        return true
    catch err
        @error "发送数据失败" err
        return false
    end
end



"""
    getdata(sock::TCPSocket) -> y::Vector{UInt8}

客户端发来的格式：
"<s>"   :: String
nbytes  :: Int32           # 后续所有数值数据的比特数，不包括结束标志
flag    :: Int32           # 训练为1，测试为0
RPM     :: Float32         # 良品的标定转速，与标定扭矩相对应
Nm      :: Float32         # 良品的标定扭矩(不一定是堵转扭矩)
Fs      :: Float32         # 电流数据的采样率
Fmax    :: Float32         # 最大转速折算的频率，由良品定义，Fmax = c * 换向片数 * 极对数 * 每分钟转速/60
Fmin    :: Float32         # 频率下限, 用于计算时频脊线时候，排除低频干扰用
data    :: Vector{Float32} # 电流数据
"<e>"   :: String          # 数据结束标志
"""
function getdata(sock::TCPSocket)::Vector{UInt8}
    # 每次读取一个字节, 查找起始标记
    buffer = Vector{UInt8}()
    is_start_found = false
    while !is_start_found
        push!(buffer, read(sock, UInt8))
        lbuf = length(buffer)
        if lbuf ≥ lstart
            mark = String(buffer[lbuf+1-lstart : lbuf])
            if isequal(mark, START)
                is_start_found = true
                empty!(buffer)
            end
        end
    end

    # 读取数据的字节长度，必须是 4 的倍数
    databytes = read(sock, Int32)
    if !iszero(databytes % 4)
        @warn "数据长度 $databytes 不是4的整数倍"
        return Vector{UInt8}()
    end

    # 按字节数量读取数据
    data = read(sock, databytes)

    # 校验尾标志
    mark = String(read(sock, lfinal))
    if !isequal(mark, FINAL)
        @warn "结束标记不匹配（数据可能损坏）"
        return Vector{UInt8}()
    end

    return data
end


"""
    parsedata(data::Vector{UInt8}) -> y::Vector{UInt8}

flag    :: Int32           # 训练为1，测试为0
RPM     :: Float32         # 良品的标定转速，与标定扭矩相对应
Nm      :: Float32         # 良品的标定扭矩(不一定是堵转扭矩)
Fs      :: Float32         # 电流数据的采样率
Fmax    :: Float32         # 最大转速折算的频率，由良品定义，Fmax = c * 换向片数 * 极对数 * 每分钟转速/60
Fmin    :: Float32         # 频率下限
data    :: Vector{Float32} # 电流数据
"""
function parsedata(data::Vector{UInt8})
    if isempty(data)
        flag = one(Int32)
        RPM  = 0f0
        Nm   = 0f0
        Fs   = 0f0
        Fmax = 0f0
        Fmin = 0f0
        return flag,RPM,Nm,Fs,Fmax,Fmin, Vector{Float32}()
    end

    x = reinterpret(Float32, data)
    n = length(x)
    y = x[7:n]

    flag = first( reinterpret(Int32, x[1:1]) )
    RPM  = x[2]
    Nm   = x[3]
    Fs   = x[4]
    Fmax = x[5]
    Fmin = x[6]

    return flag,RPM,Nm,Fs,Fmax,Fmin, y
end



function fakedata()
    flag = rand(Bool) ? one(Int32) : zero(Int32)
    RPM  = trunc(3600rand(Float32),digits=0)
    Nm   = rand(Float32) + 0.1f0
    Fs   = trunc(10rand(Float32) + 60240f0, digits=0)
    Fmax = rand(2500f0 : 1f0 : 3000f0)
    Fmin = rand(100f0 : 1f0 : 110f0)
    y = randn(Float32, rand(3:8))
    return flag,RPM,Nm,Fs,Fmax,Fmin, y
end

