#!/bin/bash

# x86
ami_id="${ami_id:-ami-00bc99e45eadad7c3}"
launch_spec="launch_spec.json"

. ./01_create_bench_AMI_core.sh
