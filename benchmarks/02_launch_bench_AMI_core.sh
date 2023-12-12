#!/bin/bash

echo -n "Requesting spot instance: "
spot_req=$(aws --region $region ec2 request-spot-instances --launch-specification "`cat $launch_spec | jq -c --arg jq_key_name $key_name --arg jq_vpc_subnet_id $vpc_subnet_id --arg jq_sec_group $sec_group --arg jq_ami_id $ami_id '. + {KeyName: $jq_key_name, SubnetId: $jq_vpc_subnet_id, SecurityGroupIds: [$jq_sec_group], ImageId: $jq_ami_id}'`")
spot_req_id=$(echo $spot_req | jq '.SpotInstanceRequests[0].SpotInstanceRequestId')
echo "request placed ($spot_req_id)\n"

echo -n "Checking for request fulfillment:"
while instance_id=$(aws --region $region ec2 describe-spot-instance-requests --filters "Name=spot-instance-request-id,Values=$spot_req_id" | jq -r '.SpotInstanceRequests[0].InstanceId') && [ "$instance_id" = "null" ]; do echo -n .; sleep 2; done
echo " success ($instance_id)\n"

echo -n "Fetching instance IP address:"
while ip_addr=$(aws --region $region ec2 describe-instances --filters "Name=instance-id,Values=$instance_id" | jq -r '.Reservations[0].Instances[0].PublicIpAddress') && [ "$ip_addr" = "null" ]; do echo -n .; sleep 2; done
echo " $ip_addr\n"

echo "It is best to supervise the benchmarking, so login:"
echo "    ssh -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no -i $key_path ec2-user@$ip_addr"
echo "Once complete, don't forget to terminate the instance!"
echo "    aws --region $region ec2 terminate-instances --instance-ids $instance_id"
