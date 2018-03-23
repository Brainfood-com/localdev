#!/bin/bash

set -e

declare -a network_drivers=(
	overlay
	bridge
)

for network_name in "$@"; do
	if [[ -z $(docker network ls -q -f "name=^${network_name}$") ]]; then
		for network_driver  in "${network_drivers[@]}"; do
			if docker network create --attachable -d "${network_driver}" "${network_name}" 2>/dev/null; then
				break
			fi
		done
	fi
done
