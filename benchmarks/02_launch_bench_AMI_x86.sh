#!/bin/bash

# x86
ami_id="${ami_id:-ami-0d6011f4d69dd33fe}"
launch_spec="launch_spec.json"

. ./02_launch_bench_AMI_core.sh
