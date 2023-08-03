#!/bin/bash

grep "(null)" /sys/devices/system/cpu/nohz_full
NOHZ=$?

# Initialise output
echo 'nohz,isa,unroll,numa,pinned,threads,speidel,N,deltaL,tm' > ~/results/Forward.csv
echo 'nohz,isa,unroll,numa,pinned,threads,speidel,N,deltaL,tm' > ~/results/Backward.csv

haps=('champs -N 0 0 100 -L 100000000 -M any -s 212 -i 1' 'champs -N 0 0 1000 -L 100000000 -M any -s 212 -i 1' 'champs -N 0 0 10000 -L 20000000 -M any -s 212 -i 1' 'champs -N 0 0 100000 -L 2000000 -M any -s 212 -i 1')
for h in "${haps[@]}"; do
  $h

  for UNROLL in {1,2,4,8,16,32,64}; do
    for ISA in {"AVX512","AVX2","NOASM"}; do
      RLIB="Rkalis/U${UNROLL}_$ISA"

      cat <<EOT > run.R
nohz <- ifelse($NOHZ == 1, TRUE, FALSE)
unroll <- $UNROLL
numa <- FALSE
isa <- "$ISA"
speidel <- FALSE
library("kalis", lib.loc = "$RLIB")

all.threads <- c(1,4,16,48,96)
all.pinned <- c(TRUE, FALSE)

EOT

      R -e "source('run.R'); source('Forward.R');"
      R -e "source('run.R'); source('Backward.R');"
    done
  done
done
