#!/bin/bash

# Runs as root via sudo

exec 1>/var/tmp/$(basename $0).log

exec 2>&1

abort () {
  echo "ERROR: Failed with $1 executing '$2' @ line $3"
  exit $1
}

trap 'abort $? "$STEP" $LINENO' ERR

HOST=$1

STEP="Create Analytics Database"
sudo /opt/scalr-server/embedded/bin/mysql -h $HOST -u scalr -p$(sudo sed -n "/mysql/,+2p" /var/tmp/scalr-server-secrets.json | tail -1 | sed 's/.*: "\(.*\)",/\1/') scalr << !
CREATE DATABASE analytics;
!
