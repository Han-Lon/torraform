#!/bin/bash
dnf update -y && \
  dnf upgrade -y

dnf install epel-release -y

cat <<EOF >> /etc/yum.repos.d/Tor.repo
[tor]
name=Tor for Enterprise Linux \$releasever - \$basearch
baseurl=https://rpm.torproject.org/centos/\$releasever/\$basearch
enabled=1
gpgcheck=1
gpgkey=https://rpm.torproject.org/centos/public_gpg.key
cost=100
EOF

dnf install tor -y

RANDOM_FOLDERNAME=`echo $RANDOM | md5sum | head -c 10`
mkdir -p /var/lib/tor/$RANDOM_FOLDERNAME/
chown -R toranon /var/lib/tor/$RANDOM_FOLDERNAME/
chmod 700 /var/lib/tor/$RANDOM_FOLDERNAME/
echo "HiddenServiceDir /var/lib/tor/$RANDOM_FOLDERNAME/" | tee -a /etc/tor/torrc
echo "HiddenServicePort 80 127.0.0.1:80" | tee -a /etc/tor/torrc

systemctl restart tor