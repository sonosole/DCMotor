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

