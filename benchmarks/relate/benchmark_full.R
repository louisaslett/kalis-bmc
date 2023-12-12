library("kalis", lib.loc = "~/Rkalis/U8_AVX2")

CacheHaplotypes("lct_0.hap.gz")

map <- read.table("lct_0.map", header = TRUE)
pars <- Parameters(rho = CalcRho(diff(map[[3]]), s = 25000),mu = 1.25e-8, use.speidel = TRUE)

res <- microbenchmark::microbenchmark(
  fwd_and_bck = {
    Forward(fwd, pars, t = L(), nthreads = 0:48)
    Backward(bck, pars, t = 1L, nthreads = 0:48)
  },
  setup = {
    fwd <<- MakeForwardTable(pars)
    bck <<- MakeBackwardTable(pars)
  }, times=1L)
saveRDS(res, "test_kalis_time.rds")

# it may be a bit of a hassle for users that legend has to be legend.gz for kalis to read it in.
