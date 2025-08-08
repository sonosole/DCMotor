include("tcp.jl")


"""
    run_client(ip::IPv4, port::Int)

启动客户端，连接服务器并发送数据
"""
function run_client(ip::IPv4, port::Int)
    sock = connect(ip, port)
    try
        flag,RPM,Nm,Fs,Fmax,Fmin, y = fakedata()

        nbytes = Int32(6*4 + sizeof(y))
        write(sock, HEAD)
        write(sock, nbytes)
        write(sock, flag)
        write(sock, RPM)
        write(sock, Nm)
        write(sock, Fs)
        write(sock, Fmax)
        write(sock, Fmin)
        write(sock, y)
        write(sock, FINAL)

        println("------------")
        println("flag:$flag")
        println("RPM:$RPM")
        println("Nm:$Nm")
        println("Fs:$Fs")
        println("Fmax:$Fmax")
        println("Fmin:$Fmin")
    catch err
        println("意外断开")
    finally
        # close(sock)
    end
end


run_client(ipv4, port)
