#!/bin/bash
INSTALL_ONIONSHARE=${INSTALL_ONIONSHARE}
SSH_HARDENING=${SSH_HARDENING}
DEBIAN_FRONTEND=noninteractive apt-get update -y && \
  DEBIAN_FRONTEND=noninteractive apt-get -o "Dpkg::Options::=--force-confold" dist-upgrade -y

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

if [ $INSTALL_ONIONSHARE = "false" ]
then
  echo "INSTALL_ONIONSHARE flag set as false, setting up Tor hidden service manually"
  echo "HiddenServiceDir /var/lib/tor/$RANDOM_FOLDERNAME/" | tee -a /etc/tor/torrc
  echo "HiddenServicePort 80 127.0.0.1:80" | tee -a /etc/tor/torrc
fi

service tor restart

if [ $INSTALL_ONIONSHARE = "true" ]
then
  echo "INSTALL_ONIONSHARE flag set as true, installing Onionshare"
  DEBIAN_FRONTEND=noninteractive apt-get install python3-pip -y
  yes | pip3 install onionshare-cli
  ln -s /usr/local/bin/onionshare-cli /usr/local/bin/onionshare
fi

if [ $SSH_HARDENING = "true" ]
then
  echo "SSH_HARDENING flag set, executing basic SSH hardening measures"
  sed -i 's/#PubkeyAuthentication yes/PubkeyAuthentication yes/g' /etc/ssh/sshd_config
  sed -i 's/UsePAM yes/UsePAM no/g' /etc/ssh/sshd_config
  sed -i 's/PasswordAuthentication yes/PasswordAuthentication no/g' /etc/ssh/sshd_config
  sed -i 's/#AuthorizedKeysFile/AuthorizedKeysFile/g' /etc/ssh/sshd_config
  useradd -m -s /bin/bash -g admin terraformer
  usermod -a -G sudo terraformer
  sed -i 's/terraformer:!/terraformer:*/g' /etc/shadow
  sed -i 's/admin:*/admin:!/g' /etc/shadow
  mkdir -p /home/terraformer/.ssh
  chmod 1600 /home/terraformer/.ssh
  cp /home/admin/.ssh/authorized_keys /home/terraformer/.ssh/
  # Going to have to get fancy with adding sudoer commands to /etc/sudoers.d/ for passwordless sudo access
  systemctl reload ssh
fi