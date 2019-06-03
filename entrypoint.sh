#!/bin/bash
set -e

# echo "no" | avdmanager create avd -n phone -k "system-images;android-28;google_apis_playstore;x86_64" --device "5.4in FWVGA"

# mongod &
# sleep 10
# mongo piknship /dbscripts/piknshipusers.js
# sleep 5
# mongo marketing /dbscripts/marketingusers.js
# sleep 5
# mongod --shutdown
# sleep 10

chown -R "$WORKINGUSER" /dev/kvm

echo "root:${ROOT_PASSWORD}" | chpasswd

echo "${WORKINGUSER}:${WORKINGUSER_PASSWORD}" | chpasswd
supervisord -n
