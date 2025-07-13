# v = read_dc_motor("../data/2025630_2_NG/11383218.csv")
# v = read_dc_motor("../data/2025630_1_NG/11299508.csv")
# v = read_dc_motor("../data/2025630_1_OK/113250862.csv") # 有问题的
# v = read_dc_motor("../data/2025630_1_OK/1134533.csv")
v = read_dc_motor("../data/2025630_1_OK/113356526.csv")
v = (read_dc_motor("../data/2025630_1_OK/113443396.csv"))


@time Xω = power32(v)
ROWS, COLS = size(Xω)
(maxval, index) = findmax(Xω, dims=1)
ids = Vector{Float32}(undef, COLS)
for cindx ∈ index
    rowi,coli= cindx.I
    ids[coli] = rowi
end

N = length(ids)
MINI = Inf
for i = N : -1 : 2
    if ids[i] < ids[i-1]
        MINI = i
        break
    end
end

# Xw = Xω[:,MINI:end]
# plot(heatmap(Xw),heatmap(Xω[:,MINI:end]))

MAX = ids[end]
ids ./= MAX

ỹ = ids[MINI:end]
N = length(ỹ)
t = collect(1:N) ./ N


k  = Info([10.], keepsgrad=true)
x0 = Info([0.1], keepsgrad=true)

global K  =  k.data[1]
global X0 = x0.data[1]
global y0 = 1/N * sum(2f0 ./ (1f0 .+ exp(-K .* (t .+ X0))) .- ỹ) - 1f0

xparms = Vector{Tuple{Char, Info}}()
push!(xparms, ('w', k))
push!(xparms, ('w', x0))

opt = Adam(xparms, lr=1.0e-3)

@time for e in 1:800
    p = 2f0 ./ (1f0 .+ exp(-k .* (t .+ x0))) .- 1.0f0 .- y0
    Y = MSELoss(p, ỹ)
    C = cost(Y)
    println("$e:", C)
    Mira.zerograds!(opt)
    Mira.backward(Y)
    Mira.update!(opt)
    global K  =  k.data[1]
    global X0 = x0.data[1]
    global Y0 = 1/N * sum(2f0 ./ (1f0 .+ exp(-K .* (t .+ X0))) .- ỹ) - 1f0
    if C < 0.006
        break
    end
end

println("  K=$K\n X0=$X0\n y0=$y0\n")

ypred = pre.(t, K, X0, y0)

vel = ypred[2:end]
tor = diff(ypred)

p1 = plot(t, ỹ, linewidth=5, alpha=0.5, label="observed")
plot!(t, ypred, label="$K", ylims=(0.0, 1.0))
p2 = plot(tor, vel, ylims=(0.0, 1.0), xlabel="torque", ylabel="speed")

p3 = heatmap( power32(v) )
plot(p1, p3, p2, layout=@layout[aa bb;cc])

vel = ỹ[2:end]
tor = diff(ỹ)
plot(vel,tor)

# t = 0 : 0.02 : 5;y = @. (1 - exp(-t/0.3));plot(t, y)

