# z = read_dc_motor("../data/2025630_1_OK/113250862.csv")
# z = read_dc_motor("../data/2025630_1_OK/1134533.csv")
# heatmap(power32(z))

x = read_dc_motor("../data/2025630_1_OK/1134533.csv")
xmaxi = argmax(x)
xnew = x[xmaxi:end]
@time Xw = power32(xnew)

(maxval, index) = findmax(Xw, dims=1)
ids = Vector{Int}(undef, length(index))
for cindx in index
    rowi,coli= cindx.I
    ids[coli] = rowi
end

N = length(ids)
t = collect(1:N) .* one(1.0f0)

csp = CubicSpline(t, ids)

plot(t, ids, linewidth=8, alpha=0.7)

inp = t[1:9:end]
out = csp[i]
plot!(inp, out)
