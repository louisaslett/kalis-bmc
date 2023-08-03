#!/bin/bash

# R
sudo dnf -y install https://dl.fedoraproject.org/pub/epel/epel-release-latest-8.noarch.rpm
sudo dnf -y update
sudo dnf -y config-manager --set-enabled codeready-builder-for-rhel-8-rhui-rpms
sudo dnf -y update
sudo dnf -y install R
sudo dnf -y install R-littler

# System libraries
sudo dnf -y install hdf5-devel

# CLI tools
sudo dnf -y install htop nano wget perf screen git


# Champs (run in champs directory) / Python
wget https://www.dropbox.com/s/3ax8yec01itnh5d/champs-master.zip
unzip champs-master.zip
cd champs-master
sudo dnf -y install python3 python3-devel
sudo pip3 install wheel
sudo pip3 install --upgrade setuptools
sudo dnf -y install gsl gsl-devel
python3 setup.py sdist bdist_wheel # Ubuntu: sudo apt-get install python3-pip
if [[ ! -e /usr/include/xlocale.h ]]; then
  sudo ln -s /usr/include/locale.h /usr/include/xlocale.h
  sudo pip3 install Cython
  sudo pip3 install numpy
fi
pip3 install --user dist/champs-0.1.0.tar.gz
cd

# Run following to test:
#champs -N 0 0 100000 -L 1000000 -M any -s 212 -i 5

# Kalis deps
mkdir R
cat <<EOT >> .Rprofile
.libPaths(c("~/R", .libPaths()))
local({
  r <- getOption("repos")
  r["CRAN"] <- "https://www.stats.bris.ac.uk/R/"
  options(repos = r)
})
EOT
mkdir .R
cat <<EOT > .R/Makevars
CFLAGS+=-march=native -mtune=native -O3
EOT
R -e 'install.packages(c("Rcpp", "dplyr", "stringr", "glue", "rlang", "digest", "checkmate", "fastcluster", "lattice", "RColorBrewer", "lobstr"))'
R -e 'install.packages("hdf5r")'
R -e 'install.packages("testthat")'
R -e 'install.packages("microbenchmark")'
