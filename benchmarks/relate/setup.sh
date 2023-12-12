#!/bin/bash

# Setup machine for benchmarking relate
# Assumes on the same AMI as used to test kalis in the parent directory
sudo yum install cmake vim-common
sudo yum update libarchive

# Get relate
git clone https://github.com/MyersGroup/relate.git
cd relate/build
cmake ..
make
