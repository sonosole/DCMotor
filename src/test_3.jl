
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





calibrate(
    read_dc_motor("../data/2025630_1_OK/113443396.csv"),
    1100,
    60240,
    2250,
    1.15)



torque, speed, eleci = estimate(read_dc_motor("../data/2025630_1_OK/113443396.csv"), 1100, 60240)
