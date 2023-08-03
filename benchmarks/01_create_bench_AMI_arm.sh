#!/bin/bash

# ARM
ami_id="${ami_id:-ami-07afba18f36ec6711}"
launch_spec="launch_spec_arm.json"

. ./01_create_bench_AMI_core.sh
