#!/bin/bash

echo -n "Identifying AMI block device and increasing to 50GB: "
block_dev=$(aws --region $region ec2 describe-images --image-ids $ami_id | jq -c '.Images[0].BlockDeviceMappings | .[0].Ebs.VolumeSize = 50')
echo "done\n"

echo -n "Requesting spot instance: "
spot_req=$(aws --region $region ec2 request-spot-instances --launch-specification "`cat $launch_spec | jq -c --arg jq_key_name $key_name --arg jq_vpc_subnet_id $vpc_subnet_id --arg jq_sec_group $sec_group --arg jq_ami_id $ami_id --argjson jq_block_dev $block_dev '. + {KeyName: $jq_key_name, SubnetId: $jq_vpc_subnet_id, SecurityGroupIds: [$jq_sec_group], ImageId: $jq_ami_id, BlockDeviceMappings: $jq_block_dev}'`")
spot_req_id=$(echo $spot_req | jq '.SpotInstanceRequests[0].SpotInstanceRequestId')
echo "request placed ($spot_req_id)\n"

echo -n "Checking for request fulfillment:"
false; while [ $? -ne 0 ] || [ "$instance_id" = "null" ]; do
  echo -n .; sleep 2
  instance_id=$(aws --region $region ec2 describe-spot-instance-requests --filters "Name=spot-instance-request-id,Values=$spot_req_id" | jq -r '.SpotInstanceRequests[0].InstanceId')
done
echo " success ($instance_id)\n"

unset ip_addr
echo -n "Fetching instance IP address:"
false; while [ $? -ne 0 ] || [ "$ip_addr" = "null" ]; do
  echo -n .; sleep 2
  ip_addr=$(aws --region $region ec2 describe-instances --filters "Name=instance-id,Values=$instance_id" | jq -r '.Reservations[0].Instances[0].PublicIpAddress')
done
echo " $ip_addr\n"

echo "Attempting instance setup ..."
while ! ssh -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no -i $key_path ec2-user@$ip_addr < 00_AMI_setup.sh > 00_AMI_setup.out 2> 00_AMI_setup.err; do echo -n .; sleep 10; done
echo "Successful install\n"

echo -n "Snapshotting benchmarking AMI: "
ami_id=$(aws --region $region ec2 create-image --instance-id $instance_id --name "Kalis benchmark RHEL 8$arm (chkpt 7de1672f0787f68e363db5109569ac33aa13bb30)" | jq -r '.ImageId')
echo " success ($ami_id)\n"

echo -n "Waiting for snapshot to complete:"
while ami_state=$(aws --region $region ec2 describe-images --image-ids $ami_id | jq -r '.Images[0].State') && [ "$ami_state" != "available" ]; do echo -n .; sleep 2; done
echo " snapshot done\n"

echo "Terminating instance"
aws --region $region ec2 terminate-instances --instance-ids $instance_id


# It is best to supervise the install, testing and benchmarking, so login:
ssh -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no -i $key_path ec2-user@$ip_addr
# and continue to run on the server in this order:
# bench_01_install_kalis.sh
# bench_02_test_kalis.sh
# bench_03_benchmarks.sh

# Then exit and download all the test and benchmark results:
# scp -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no -i $key_path -r ec2-user@$ip_addr:~/results .

# To make an AMI for this git checkpoint:
# aws --region $region ec2 create-image --instance-id $instance_id --name "Kalis benchmark image RHEL 8 (ARM at chkpt 7de1672f0787f68e363db5109569ac33aa13bb30)"
# aws --region $region ec2 create-image --instance-id $instance_id --name "Kalis benchmark image RHEL 8 (x86 at chkpt 7de1672f0787f68e363db5109569ac33aa13bb30)"

# Once complete, don't forget to terminate the instance!
# aws --region $region ec2 terminate-instances --instance-ids $instance_id
