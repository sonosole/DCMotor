
info = tvsf(power32, "../data/2025630_1_OK/113356526.csv";verbose=true,lr=1e-2)

rpm  = 2250
Nm = 1.15
coef = TSCoef(info, rpm, Nm)
lcoef = LineCoef(coef, info)
n,t = drawtn(lcoef)
plot(t,n, framestyle=:origin, label="ok")

# good
infoxx = tvsf(power32, "../data/2025630_1_OK/113443396.csv";verbose=true,lr=1e-2)
nx,tx = drawtn(LineCoef(coef, infoxx))
plot!(tx,nx, framestyle=:origin, label="ok")


# ng
infoyy = tvsf(power32, "../data/2025630_2_NG/11383218.csv";verbose=true,lr=1e-2)
ny,ty = drawtn(LineCoef(coef, infoyy))
plot!(ty,ny, framestyle=:origin, label="ng")

# ng
infozz = tvsf(power32, "../data/2025630_1_NG/11299508.csv";verbose=true,lr=1e-2)
nz,tz = drawtn(LineCoef(coef, infozz))
plot!(tz,nz, framestyle=:origin, label="ng", xlabel="torque (N/m)", ylabel="speed (rpm)")


gui()

begin
    Coef = 40
    Nmax = 3000
    Fmax = Coef * Nmax/60
    Fmin = 110
    Fs   = 60240
    RPM  = 2000
    Nm   = 1.0
    
    calibrate(
        read_dc_motor("../data/2025630_1_OK/113443396.csv"),
        Nmax,
        Fmin,
        Fmax,
        Fs,
        RPM,
        Nm)
    end
    

begin
torque, speed, v, f,_ = estimate(
    read_dc_motor("../data/2025630_1_OK/113334731.csv"), 
    Fs);

plot(torque, speed, ylabel="rpm", xlabel="Nm", label="speed", framestyle=:origin)
plot!([Nm], [RPM], marker=5)
plot!(twinx(), torque, v, ylabel="I (A)", color=:red, label="current", marker=2)
# plot!(twinx(), torque, f, ylabel="I (A)", color=:cyan, label="current", marker=2)
title!("ok")
end

torque, speed, v = estimate(
    read_dc_motor("../data/2025630_2_NG/11383552.csv"), 
    1100, 60240)

plot(torque, speed, ylabel="rpm", xlabel="Nm", label="speed", framestyle=:origin)
plot!(twinx(), torque, v, ylabel="I (A)", color=:red, label="current")
title!("ng")





torque, speed, v = estimate2(
    read_dc_motor("../data/2025630_1_OK/113334731.csv"), 
    1100, 60240)

plot(torque, speed, ylabel="rpm", xlabel="Nm", label="speed", framestyle=:origin)
plot!(twinx(), torque, v, ylabel="I (A)", color=:red, label="current")

torque, speed, v = estimate2(
    read_dc_motor("../data/2025630_1_OK/113413188.csv"), 
    1100, 60240)

plot!(torque, speed, ylabel="rpm", xlabel="Nm", label="speed", framestyle=:origin)
plot!(twinx(), torque, v, ylabel="I (A)", color=:red, label="current")


