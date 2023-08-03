#!/bin/bash

# Run 01_benchmark_setup.sh as if going to do testing and standard benchmarking, but then skip to this:

sudo dnf -y install screen
R -e "install.packages('testthat')"
mkdir results

unzip dev-kalis.zip
rm -rf __MACOSX
R CMD build --no-build-vignettes dev-kalis

UNROLL=8
ISA2="AVX512=1"
R -e "install.packages('kalis_0.91.1.tar.gz', configure.vars = 'UNROLL=$UNROLL $ISA2', INSTALL_opts='--install-tests')"

champs -N 0 0 200000 -L 3000000 -M any -s 212 -i 1
R -e "library(kalis); CacheHaplotypes('msprime_haps_1.h5', transpose = TRUE); N(); L();"

# Run inside screen (exec sh stops screen exiting when done)
screen -dm bash -c 'Rscript iterator.R; exec sh'
