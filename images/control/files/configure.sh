#!/bin/bash

set -e

declare -a scripts=(
	entrypoint
	healthcheck
)
export DEBIAN_FRONTEND=noninteractive

apt-get update
apt-get install -y openssl wget libltdl7 haproxy

mkdir -p /srv/localdev/scripts
for script in "${scripts[@]}"; do
	cp -a "/tmp/files/$script.sh" "/srv/localdev/scripts/$script"
done

rm /tmp/files -rf

apt-get clean
find /var/cache/apt /var/lib/apt -type f -delete
