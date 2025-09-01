function read_dc_motor(path::String)
    x = Float32[]
    for (i,line) ∈ enumerate(readlines(path))
        if i==6
            # 读取第六行的 CSV 数据
            rec = split(line, ",")[1:end-1]
            append!(x, parse.(Float32, rec))
        end
    end
    return x
end


function read_dc_motor2(path::String)
    x = Float32[]
    for v in eachline(path)
        push!(x, parse(Float32,v))
    end
    RPM  = x[1]
    Nm   = x[2]
    Fs   = x[3]
    Nmax = x[4]
    y    = x[5:end]
    return RPM, Nm, Fs, Nmax, y
end

