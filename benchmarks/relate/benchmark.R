# To make spiked recombination map
# map <- data.table::fread("lct.map")
#
# map[[3]][-1] <- map[[3]][-1] + 1e3
# map[[3]][nrow(map)] <- map[[3]][nrow(map)] + 1e3
#
# map[[2]][-nrow(map)] <- 1e6*diff(map[[3]])/diff(map[[1]])
# map[[2]][nrow(map)] <- map[[2]][nrow(map)-1]
# head(map)
# plot(map[[3]])
# data.table::fwrite(map,"lct_1.map",quote=FALSE,sep=" ")



library("kalis", lib.loc = "~/Rkalis/U8_AVX2")

#system2("gzip","lct_1.legend")
CacheHaplotypes("lct_1.hap.gz")

# verify that the Nth haplotype
table(QueryCache(hap.idx = N())==1)

map <- read.table("lct_1.map", header = TRUE)
pars <- Parameters(rho = CalcRho(diff(map[[3]]), s = 25000),mu = 1.25e-8, use.speidel = TRUE)

fwd <- MakeForwardTable(pars,from_recipient = N(),to_recipient = N())
bck <- MakeBackwardTable(pars,from_recipient = N(),to_recipient = N())

# only 1 thread can be used here because we're effectively only adding a single haplotype
# but if we added multiple haplotypes of all 1s to the dataset, we could use multithreading here,
# but that would also multiply the time need for our relate benchmarks,
# so for now just sticking with the 1 thread example here.

res <- microbenchmark::microbenchmark(
  fwd_and_bck = {
    Forward(fwd, pars, t = L(), nthreads = 1L)
    Backward(bck, pars, t = 1L, nthreads = 1L)
  },
  setup = {
    fwd <<- MakeForwardTable(pars,from_recipient = N(),to_recipient = N())
    bck <<- MakeBackwardTable(pars,from_recipient = N(),to_recipient = N())
  }, times=20L)
saveRDS(res, "test_kalis_time.rds")

# it may be a bit of a hassle for users that legend has to be legend.gz for kalis to read it in.
