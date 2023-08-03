#!/bin/bash

mkdir -p ~/results

# Get specific commit for benchmarking (this is the commit used in the paper, specyfing it here for reproducibility)
git clone -n https://github.com/louisaslett/kalis.git
cd kalis
git checkout 7de1672f0787f68e363db5109569ac33aa13bb30
# One tiny fix for ARM (this was bug fixed in latest repo commits, just not this one)
sed -i '93s/.*/#define KALIS_STORE_INT_VEC(X, Y) vst1q_s32((int32_t*) \&(X), Y)/' src/StencilVec.h
cd ..

R CMD build --no-build-vignettes kalis
kalis=$(ls kalis*.tar.gz)

# Prep compile flags
cat <<EOT > .R/Makevars
CFLAGS=-march=native -mtune=native -O3 -Wall -Wextra -Werror -pedantic
EOT

if [[ `uname -m` == "aarch64" ]]; then
  archs=("NOASM" "NEON")
else
  archs=("NOASM" "AVX2" "AVX512")
fi

# Compile kalis for all targets of interest
for ISA in "${archs[@]}"; do
  for UNROLL in {1,2,4,8,16,32,64}; do
    RLIB="Rkalis/U${UNROLL}_$ISA"
    ISA2="$ISA=1"
    mkdir -p $RLIB

    R -e "install.packages('$kalis', configure.vars = 'UNROLL=$UNROLL $ISA2', lib = '$RLIB', INSTALL_opts='--install-tests')"
  done
done
rm -rf Rkalis/U64_NOASM
