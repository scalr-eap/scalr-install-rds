#!/bin/bash

# Runs as root via sudo

exec 1>/var/tmp/$(basename $0).log

exec 2>&1

abort () {
  echo "ERROR: Failed with $1 executing '$2' @ line $3"
  exit $1
}

trap 'abort $? "$STEP" $LINENO' ERR

STEP="cp /var/tmp/scalr-server-secrets.json /etc/scalr-server"
cp /var/tmp/scalr-server-secrets.json /etc/scalr-server
STEP="chmod 400 /etc/scalr-server/scalr-server-secrets.json"
chmod 400 /etc/scalr-server/scalr-server-secrets.json

STEP="cp /var/tmp/scalr-server.rb /etc/scalr-server"
cp /var/tmp/scalr-server.rb /etc/scalr-server

STEP="chmod 644 /etc/scalr-server/scalr-server.rb"
chmod 644 /etc/scalr-server/scalr-server.rb

STEP="scalr-server-ctl reconfigure"
scalr-server-ctl reconfigure
