system(glue::glue("echo 'table,l,tm' > ~/results/Iterator.csv"))

library(kalis)

nt <- as.integer(0:(48-1))

CacheHaplotypes("msprime_haps_1.h5", transpose = TRUE)

hapmap <- read.table("map_1.txt", header = TRUE)
map <- diff(hapmap[,2])
map <- c(map, map[1])
rho <- CalcRho(map)

pars <- Parameters(rho, use.speidel = TRUE)

fwd <- MakeForwardTable(pars, from_recipient = 1, to_recipient = 10000)
bck <- MakeBackwardTable(pars, from_recipient = 1, to_recipient = 10000)

Iter <- ForwardIterator(pars, 7, from_recipient = 1, to_recipient = 10000)

start.time <- proc.time()[3]

for(t in L():1){
  Iter(fwd, pars, t, nthreads = nt)
  system(glue::glue("echo '\"Forward\",{t},{proc.time()[3]-start.time}' >> ~/results/Iterator.csv"))
  Backward(bck, pars, t, nthreads = nt)
  system(glue::glue("echo '\"Backward\",{t},{proc.time()[3]-start.time}' >> ~/results/Iterator.csv"))
}
