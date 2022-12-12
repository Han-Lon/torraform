#!/bin/bash
DEBIAN_FRONTEND=noninteractive apt-get update -y && \
  DEBIAN_FRONTEND=noninteractive apt-get -o "Dpkg::Options::=--force-confold" dist-upgrade -y

mkdir /tmp/ssm

# SSM Agent installation file is arch specific, get arm64 url from here -> https://docs.aws.amazon.com/systems-manager/latest/userguide/agent-install-deb.html
wget -O /tmp/ssm/amazon-ssm-agent.deb https://s3.amazonaws.com/ec2-downloads-windows/SSMAgent/latest/debian_amd64/amazon-ssm-agent.deb

dpkg -i /tmp/ssm/amazon-ssm-agent.deb
systemctl enable amazon-ssm-agent