include("tcp.jl")



"""
    run_server(server_ip, server_port::Int)

启动服务器，监听端口并处理客户端连接
"""
function run_server(ip::IPv4, port::Int)
    # 创建一个服务器
    server = listen(ip, port)
    println("正在监听 $ip : $port")
    
    try
        while true
            sock = accept(server)
            println("与客户端建立连接: ", isopen(sock))
            @async begin
                while isopen(sock)
                    uint8 = getdata(sock)
                    flag,RPM,Nm,Fs,Fmax,Fmin, y = parsedata(uint8)

                    println("------------")
                    println("flag:$flag")
                    println("RPM:$RPM")
                    println("Nm:$Nm")
                    println("Fs:$Fs")
                    println("Fmax:$Fmax")
                    println("Fmin:$Fmin")
                    sleep(4)
                    if !isempty(y)
                        putdata(sock, one(UInt32), 
                                    ones(Float32, 500),
                                    2ones(Float32, 500),
                                    3ones(Float32, 500),
                                    UInt32.(1:500))
                    else
                        putdata(sock, zero(UInt32), 
                                    Float32[],
                                    Float32[],
                                    Float32[],
                                    UInt32[])
                    end
                end
            end
        end
    catch err
        println("服务器意外关闭")
    finally
        close(server)
    end
end


run_server(ipv4, port)

