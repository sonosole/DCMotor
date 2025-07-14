# v = read_dc_motor("../data/2025630_2_NG/11383218.csv")
v = read_dc_motor("../data/2025630_1_NG/11299508.csv")
# v = read_dc_motor("../data/2025630_1_OK/113250862.csv") # 有问题的
# v = read_dc_motor("../data/2025630_1_OK/1134533.csv")
# v = read_dc_motor("../data/2025630_1_OK/113356526.csv")
v = read_dc_motor("../data/2025630_1_OK/113443396.csv")


@time Xω = power32(v)
ROWS, COLS = size(Xω)
ids = Vector{Float32}(undef, COLS)
for cindx ∈ argmax(Xω, dims=1)
    rowi,coli = Tuple(cindx)
    ids[coli] = rowi
end

N = length(ids)
MINI = N
for i = N : -1 : 2
    if ids[i] < ids[i-1]
        MINI = i
        break
    end
end

Xw = Xω[:,MINI:end]
plot(heatmap(log.(0.1 .+ Xω)),heatmap(log.(0.1 .+ Xω[:,MINI:end])))

MAX = ids[end]
ids ./= MAX

ỹ = ids[MINI:end]
N = length(ỹ)
x = collect(1:N) ./ N


k  = Info([8.0], keepsgrad=true)
x0 = Info([0.0], keepsgrad=true)

global K  =  k.data[1]
global X0 = x0.data[1]
global y0 = gety0(x, ỹ, K, X0)

xparms = Vector{Tuple{Char, Info}}()
push!(xparms, ('w', k))
push!(xparms, ('w', x0))
opt = Adam(xparms, lr=1.0e-2)

@time for e in 1:500
    p = 1f0 .- exp(-k .* (x .+ x0)) .- y0
    Y = MSELoss(p, ỹ)
    C = cost(Y)
    println("$e:", C)
    Mira.zerograds!(opt)
    Mira.backward(Y)
    Mira.update!(opt)
    global K  =  k.data[1]
    global X0 = x0.data[1]
    global y0 = gety0(x, ỹ, K, X0)
    if C < 0.006
        break
    end
end

println("  K=$K\n X0=$X0\n y0=$y0\n")

ypred = fity(x, K, X0, y0)

# 速度、扭矩
vel = ypred[2:end]
tor = diff(ypred)


# 测量时频脊线 vs 平滑时频脊线
p1 = plot(x, ỹ, linewidth=5, alpha=0.5, label="observed")
     plot!(x, ypred, label="fitted", ylims=(-0.1, 1.2))

p2 = plot(tor, vel, ylims=(0.0, 1.0), xlabel="torque", ylabel="speed")

p3 = heatmap( Xw , title="time-frequency", ticks=nothing)
plot(p3, p1, p2, layout=@layout[aa bb;cc])

