#!/bin/bash
apt-get update -y && \
apt-get updgrade -y

mkdir /tmp/ssm
cd /tmp/ssm

# SSM Agent installation file is arch specific, get arm64 url from here -> https://docs.aws.amazon.com/systems-manager/latest/userguide/agent-install-deb.html
wget https://s3.amazonaws.com/ec2-downloads-windows/SSMAgent/latest/debian_amd64/amazon-ssm-agent.deb

dpkg -i amazon-ssm-agent.deb
systemctl enable amazon-ssm-agent