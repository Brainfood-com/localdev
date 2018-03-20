#!/bin/bash

set -e

declare -a scripts=(
	entrypoint
	healthcheck
)

if [[ $NGINX_UPGRADE ]]; then
	export DEBIAN_FRONTEND=noninteractive

	apt-get update
	apt-get install -y nginx
fi

mkdir -p /etc/nginx/conf.d
cp /tmp/files/nginx-docker.conf /etc/nginx/conf.d/nginx-docker.conf

mkdir -p /srv/localdev/scripts
for script in "${scripts[@]}"; do
	cp -a "/tmp/files/$script.sh" "/srv/localdev/scripts/$script"
done

rm /tmp/files -rf

apt-get clean
find /var/cache/apt /var/lib/apt -type f -delete
