using Sockets

# 定义服务器监听的地址和端口
server_ip = IPv4(127, 0, 0, 1)
server_port = 1718

# 创建一个TCP监听器
server = listen(server_ip, server_port)
println("Server is listening on $(server_ip):$(server_port)")


try
    while true
        # 等待客户端连接
        serversocket = accept(server)
        println("serversocket connected: $(serversocket)")
        try
            while isopen(serversocket)
                # 读取客户端发送的 100MB 数据
                # tic = time()
                # pm = read(serversocket, 2)
                # u8 = read(serversocket, 1024 * 1024 * 100)
                # toc = time()
                readuntil(serversocket, 'm', keep = false)

                dts = toc - tic
                x32 = reinterpret(Float32, u8)
                bandwidth = 100 / dts  # 计算带宽，单位为Mbps
                println("Bandwidth: $bandwidth Mbps in $dts s with mean=", sum(x32)/length(x32))
            end
        catch err
            println("Error handling serversocket: $err")
        finally
            close(serversocket)
            println("serversocket disconnected.")
        end
    end
catch e
    println("Server error: $e")
finally
    close(server)
end
