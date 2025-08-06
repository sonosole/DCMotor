using Sockets

# 定义协议常量
const START = "<s>"
const FINAL = "<e>"
const ENCODING = UInt8

const lstart = length(START) # 开始标记长度
const lfinal = length(FINAL) # 结束标记长度


# 定义地址和端口
ipv4 = IPv4(127, 0, 0, 10)
port = 8000



"""
    putdata(sock::TCPSocket, data::Vector{Float32})

服务端返回格式
"<s>" + 
nbytes::Int32 + 
torque::Vector{Float32} + 
speed::Vector{Float32} + 
current::Vector{Float32} + 
indices::Vector{Int32} + 
"<e>"
"""
function putdata(sock::TCPSocket, torque::Vector{Float32},
                                  speed::Vector{Float32},
                                  current::Vector{Float32},
                                  indices::Vector{Int32})
    try
        HEAD = transcode(ENCODING, START)
        TAIL = transcode(ENCODING, FINAL)
        SIZE = UInt32(sizeof(torque) +
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
    getdata(sock::TCPSocket) -> y::Vector{Float32}

客户端发送格式：
"<s>" + 
nbytes::Int32 + 
train_or_test::Int32 + 
RPM::Float32 + 
Nm::Float32 + 
Fs::Float32 + 
Fmax::Float32 + 
Fmin::Float32 + 
data::Vector{Float32} + 
"<e>"
"""
function getdata(sock::TCPSocket)::Vector{UInt8}
    buffer = Vector{UInt8}()
    is_start_found = false

    # 每次读取一个字节, 查找起始标记
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
    databytes = read(sock, UInt32)
    if !iszero(databytes % 4)
        @warn "数据长度 $databytes 不是4的倍数"
        return UInt8[]
    end

    # 按字节数量读取数据
    data = read(sock, databytes)

    # 校验尾标志
    mark = String(read(sock, lfinal))
    if !isequal(mark, FINAL)
        @warn "结束标记不匹配（数据可能损坏）"
        return UInt8[]
    end

    return data
end



function parsedata(data::Vector{UInt8})



end
