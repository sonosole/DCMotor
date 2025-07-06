for (root, dirs, files) in walkdir("../data/2025630_2_NG/")
    println("Files in $root")
    for file ∈ files
        !isequal(".csv", last(splitext(file))) && continue
        fullpath = joinpath(root, file)

        x = read_dc_motor(fullpath)
        xmaxi = argmax(x)
        xnew = x[xmaxi:end]
        @time Xw = power32(xnew)

        (maxval, index) = findmax(Xw, dims=1)
        ids = Vector{Int}(undef, length(index))
        for cindx in index
            rowi,coli= cindx.I
            ids[coli] = rowi
        end

        plot!(ids, leg=nothing, color=:red);gui()
    end
end

