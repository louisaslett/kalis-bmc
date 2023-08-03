library("microbenchmark")

cores <- parallel::detectCores(logical = FALSE)

CacheHaplotypes("msprime_haps_1.h5", transpose = TRUE)

hapmap <- read.table("map_1.txt", header = TRUE)
map <- diff(hapmap[,2])
map <- c(map, map[1])
rho <- CalcRho(map)

pars <- Parameters(rho, use.speidel = speidel)

fwd <- MakeForwardTable(pars)

gc()

bench.it <- function() {
  ResetTable(fwd)

  Forward(fwd, pars, 2, nthreads = 0:(cores-1))

  res <- microbenchmark(Forward(fwd, pars, fwd$l+deltaL, nthreads = th), times = 3L)

  pinned <- ifelse(pinned, "TRUE", "FALSE")
  for(tm in res$time) {
    system(glue::glue("echo '{nohz},\"{isa}\",{unroll},{numa},{pinned},{threads},{speidel},{N()},{deltaL},{tm}' >> ~/results/Forward.csv"))
  }
  median(res$time)
}

# Go!
for(threads in all.threads) {
  for(pinned in all.pinned) {
    if(pinned & threads<cores) {
      th <- 1:threads
    } else if(pinned & threads==cores) {
      th <- 0:(cores-1)
    } else {
      th <- threads
    }

    last.t <- this.t <- NA
    for(deltaL in c(1,2,4)) {
      last.t <- this.t
      this.t <- log(bench.it()) - log(deltaL)
    }
    # While the speedup is more than 1% from previous settings
    while(deltaL*2*3+2 < L() && last.t - this.t > log(1.01)) {
      print(c(deltaL, (exp(last.t - this.t)-1)*100))
      deltaL <- deltaL*2
      last.t <- this.t
      this.t <- log(bench.it()) - log(deltaL)
    }
  }
}
print(L())
print(N())
