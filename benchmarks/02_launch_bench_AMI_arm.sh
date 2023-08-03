#!/bin/bash

# ARM
ami_id="${ami_id:-ami-04beb6daa91595c38}"
launch_spec="launch_spec_arm.json"

. ./02_launch_bench_AMI_core.sh
