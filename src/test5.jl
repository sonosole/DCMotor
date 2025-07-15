for (root, dirs, files) in walkdir("../data/2025630_1_OK/")
    println("Files in $root")
    for file ∈ files
        !isequal(".csv", last(splitext(file))) && continue
        fullpath = joinpath(root, file)
        tfcurve(power32, fullpath; epochs=800, verbose=false, lr=1e-2)
        sleep(1)
        title!(file);gui()
    end
end

