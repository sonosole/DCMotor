include("tcp.jl")


"""
    run_client(ip::IPv4, port::Int)

启动客户端，连接服务器并发送数据
"""
function run_client(ip::IPv4, port::Int)
    sock = connect(ip, port)
    try
        # 生成伪数据发送到客户端
        flag,RPM,Nm,Fs,Nmax,Nmin,Coef, y = fakedata()
        nbytes = Int32(7*4 + sizeof(y))
        write(sock, HEAD)
        write(sock, nbytes)
        write(sock, flag)
        write(sock, RPM)
        write(sock, Nm)
        write(sock, Fs)
        write(sock, Nmax)
        write(sock, Nmin)
        write(sock, Coef)
        write(sock, y)
        write(sock, TAIL)

        println("sending $nbytes bytes")
        println("flag:$flag")
        println("RPM:$RPM")
        println("Nm:$Nm")
        println("Fs:$Fs")
        println("Fmax:$(Coef * Nmax / 60f0)")
        println("Fmin:$(Coef * Nmin / 60f0)")
    catch err
        println("意外断开")
    finally
        close(sock)
    end
end


run_client(ipv4, port)
