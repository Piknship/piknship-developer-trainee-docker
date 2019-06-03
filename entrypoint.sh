#!/bin/bash
set -e

chown -R "$WORKINGUSER" /dev/kvm

echo "root:${ROOT_PASSWORD}" | chpasswd

echo "${WORKINGUSER}:${WORKINGUSER_PASSWORD}" | chpasswd
supervisord -n
