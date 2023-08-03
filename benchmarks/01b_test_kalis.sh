#!/bin/bash

pids=()
for pkg in ~/Rkalis/*/ ; do
  echo "print('${pkg}'); .libPaths(c('${pkg}', .libPaths())); testthat::test_package('kalis', reporter = testthat::LocationReporter);" | NOT_CRAN=true r -p > ${pkg%?}.res &
  pids+=($!)
done

for pid in ${pids[*]}; do
  wait $pid
done

# When finished
mkdir -p ~/results/tests
mv ~/Rkalis/*.res ~/results/tests
