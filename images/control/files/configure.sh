#!/bin/bash

set -e

declare -a scripts=(
	entrypoint
	healthcheck
)
export DEBIAN_FRONTEND=noninteractive

apt-get update
apt-get install -y apt-transport-https gnupg openssl wget libltdl7 haproxy
cp -a /tmp/files/docker-sources.list /etc/apt/sources.list.d
apt-key add /tmp/files/docker-key.gpg 

apt-get update

docker_ce_url=$(apt-get install -dy --print-uris -qq docker-ce | sed -n "s/^'\\(.*docker-ce_.*\\)' .*/\\1/p")
wget -O /tmp/docker-ce.deb "$docker_ce_url"

dpkg-deb --fsys-tarfile /tmp/docker-ce.deb | tar xf - -C / ./usr/bin/docker

mkdir -p /srv/localdev/scripts
for script in "${scripts[@]}"; do
	cp -a "/tmp/files/$script.sh" "/srv/localdev/scripts/$script"
done

rm /tmp/files /tmp/docker-ce.deb -rf

apt-get clean
find /var/cache/apt /var/lib/apt -type f -delete
