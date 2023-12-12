#! /bin/bash


# from working directory, eg: /workspaces/relate/ 

# if relate hasn't been compiled yet, instal using the following
#cd build
#cmake ..
#make
#cd ..

# make a benchmark directory in the working directory eg: /workspaces/relate/ 
mkdir benchmark
cd benchmark

# Move lct_1.map, lct.hap.gz , lct.legend, lct.sample to the benchmark directory

# ADD TWO HAPLOTYPES to DATASET (one sample) 
# which will be used for benchmarking kalis against relate
###########################################################

# note, we could add multiple haplotypes here, with all 1s if we want to benchmark
# against multithreaded kalis -- of course this will make relate run proportionally slower

gunzip lct.hap.gz 
mv lct.hap lct_1.hap
mv lct.legend lct_1.legend
gzip < lct_1.legend > lct_1.legend.gz
mv lct.sample lct_1.sample

sed -i "s/.$/1/" lct_1.hap # replace last haplotype with vector of 1s
sed -i "14597s/.$/0/" lct_1.hap # introduce a single zero in middle of haplotype
gzip lct_1.hap

# the resulting lct_1.hap.gz , lct_1.legend.gz, lct_1.sample , and lct_1.map
# files are to be fed to kalis where we take N() to be the only recipient

# Convert lct_1 files to hap/samples format 
../bin/RelateFileFormats \
    --mode ConvertFromHapLegendSample \
    --haps lct_1.hap \
    --sample lct_1.samples \
    -i lct_1

# MAKE CONTROL DATASET lct_0
# lct_0 is meant to be fed to relate and not to kalis.
# the last haplotype has all 0s rather than all 1s
###########################################################
cp lct_1.hap lct_0.hap
cp lct_1.samples lct_0.samples
cp lct_1.map lct_0.map
sed -i "s/.$/0/" lct_0.hap # replace last haplotype with vector of 0s
sed -i "1s/.$/1/" lct_0.hap # make first var of last hap a 1
sed -i "29193s/.$/1/" lct_0.hap # make last var of last hap a 1


######################################################################
# CHUNK EACH DATASET (lct_0 and lct_1) 
# the following ensures relate will only 
# stop at two target loci, one at each end of the chunk
######################################################################

# PREP lct_0
####################################
# convert data to a chunk
../bin/Relate \
    --mode "MakeChunks" \
    --haps lct_0.hap \
    --sample lct_0.samples \
    --map lct_0.map \
    -o lct_0

# optional: have a look at parameters file we're going to overwrite
# od -i lct_0/parameters_c0.bin 

# Take the first two numbers, set the third to two and then append 0 and the last number
for i in 5008 29193 2 0 29193
do 
printf "0: %.8x" $i | sed -E 's/0: (..)(..)(..)(..)/0: \4\3\2\1/' | xxd -r -p >> temp_file.bin
done

# Overwrite parameters_c0.bin 
mv temp_file.bin lct_0/parameters_c0.bin 


# PREP lct_1
####################################
# convert data to a chunk
../bin/Relate \
    --mode "MakeChunks" \
    --haps lct_1.hap \
    --sample lct_1.samples \
    --map lct_1.map \
    -o lct_1

# optional: have a look at parameters file we're going to overwrite
# od -i lct_1/parameters_c0.bin 

# Take the first two numbers, set the third to two and then append 0 and the last number
for i in 5008 29193 2 0 29193
do 
printf "0: %.8x" $i | sed -E 's/0: (..)(..)(..)(..)/0: \4\3\2\1/' | xxd -r -p >> temp_file.bin
done

# Overwrite parameters_c0.bin 
mv temp_file.bin lct_1/parameters_c0.bin 


######################################################################
# BENCHMARK EACH DATASET, lct_0 and lct_1 so that 
# relate only stops at two target loci, one at each end of the chunk
######################################################################

# below I use chrt with the goal to prevent context switching, 
# but it's unclear if it's helpful/needed,
# it looks like it adds to the runtime by a few seconds.

test0() {
#sudo /usr/bin/chrt -f 99 
../bin/Relate \
    --mode Paint \
    --chunk_index 0 \
    -o lct_0
}

test1() {
#sudo /usr/bin/chrt -f 99 
../bin/Relate \
    --mode Paint \
    --chunk_index 0 \
    -o lct_1
}


# Get baseline timing
time test0

# Get timing where the only difference is now we have to visit
# all sites for the Nth haplotype
time test1

# take difference of the above two timings for many replicates
# to obtain a time estimate we can compare to kalis