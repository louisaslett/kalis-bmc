#!/bin/bash

# ARM
ami_rhel_id="ami-06345a742b1bdc61c"
launch_spec="launch_spec_arm.json"
arm=" ARM"

. ./00_create_base_AMI_core.sh > 00_create_base_AMI_arm.log 2>&1
