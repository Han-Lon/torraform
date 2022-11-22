#!/bin/bash
apt-get update -y && \
apt-get upgrade -y

apt-get install apt-transport-https gnupg -y

DEBIAN_VERSION=`lsb_release -c | awk '{print $2}'`

echo "deb     [signed-by=/usr/share/keyrings/tor-archive-keyring.gpg] https://deb.torproject.org/torproject.org $DEBIAN_VERSION main" | tee -a /etc/apt/sources.list.d/tor.list
echo "deb-src [signed-by=/usr/share/keyrings/tor-archive-keyring.gpg] https://deb.torproject.org/torproject.org $DEBIAN_VERSION main" | tee -a /etc/apt/sources.list.d/tor.list

wget -qO- https://deb.torproject.org/torproject.org/A3C4F0F979CAA22CDBA8F512EE8CBC9E886DDD89.asc | gpg --dearmor | tee /usr/share/keyrings/tor-archive-keyring.gpg >/dev/null

apt-get update -y
apt-get install tor deb.torproject.org-keyring obfs4proxy -y

# Great command for getting Tor service logs -> journalctl -e -u tor@default

RANDOM_FOLDERNAME=`echo $RANDOM | md5sum | head -c 10`
mkdir -p /var/lib/tor/$RANDOM_FOLDERNAME/
chown -R debian-tor /var/lib/tor/$RANDOM_FOLDERNAME/
chmod 700 /var/lib/tor/$RANDOM_FOLDERNAME/
echo "HiddenServiceDir /var/lib/tor/$RANDOM_FOLDERNAME/" | tee -a /etc/tor/torrc
echo "HiddenServicePort 80 127.0.0.1:80" | tee -a /etc/tor/torrc