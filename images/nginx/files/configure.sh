#!/bin/bash

set -e

declare -a scripts=(
	entrypoint
	healthcheck
)

mkdir -p /srv/localdev/scripts
for script in "${scripts[@]}"; do
	cp -a "/tmp/files/$script.sh" "/srv/localdev/scripts/$script"
done

rm /tmp/files -rf
