#!/bin/bash

# x86
ami_rhel_id="ami-032e5b6af8a711f30"
launch_spec="launch_spec.json"
arm=""

. ./00_create_base_AMI_core.sh > 00_create_base_AMI_x86.log 2>&1
