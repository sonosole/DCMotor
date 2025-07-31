# v = read_dc_motor("../data/2025630_2_NG/11383218.csv")
v = read_dc_motor("../data/2025630_1_NG/11299508.csv")
# v = read_dc_motor("../data/2025630_1_OK/113250862.csv") # 有问题的
# v = read_dc_motor("../data/2025630_1_OK/1134533.csv")
# v = read_dc_motor("../data/2025630_1_OK/113356526.csv")
v = read_dc_motor("../data/2025630_1_OK/113443396.csv")

using Lasso, DSP
begin
      xi = read_dc_motor("../data/2025630_1_OK/113443396.csv")
      LP = Lowpass(FMIN, fs=RATE);
      FT = Butterworth(4);
      lpf = digitalfilter(LP, FT);
      tf  = convert(PolynomialRatio, lpf);
      xo  = filtfilt(tf, xi);
      yo  = Lasso.fit(FusedLasso, xi, 100).β
      plot(xi, linewidth=1)
      plot(xo, linewidth=1)
      plot!(yo, linewidth=1)
end
