#!/bin/bash

# Runs as login user for instance, e.g. ubuntu

exec 1>/var/tmp/$(basename $0).log

exec 2>&1

abort () {
  echo "ERROR: Failed with $1 executing '$2' @ line $3"
  exit $1
}

trap 'abort $? "$STEP" $LINENO' ERR

STEP="chmod SSH key"
chmod 400 ~/.ssh/id_rsa

PW=$1
shift

STEP="Set password"
sudo sed 's/"scalr_password": .*,/"scalr_password": "'$PW'",/' /etc/scalr-server/scalr-server-secrets.json > /var/tmp/scalr-server-secrets.json
sudo chmod 777 /var/tmp/scalr-server-secrets.json
sudo cp /var/tmp/scalr-server-secrets.json /etc/scalr-server/scalr-server-secrets.json

for ip in $*
do
  STEP="scp configs to ${ip}"
  scp -o StrictHostKeyChecking=no /var/tmp/scalr-server-secrets.json /var/tmp/scalr-server.rb ubuntu@$ip:/var/tmp
done
