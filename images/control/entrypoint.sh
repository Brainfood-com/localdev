#!/bin/bash

set -e

declare -a compose_files=(
	/srv/localdev/images/nexus3/docker-compose.yml
	/srv/localdev/subs/nginx-proxy/docker-compose.yml
)
declare -a docker_networks=(
	localdev_default
	nginx
)

/srv/localdev/scripts/adjust-user localdev localgroup
/srv/localdev/scripts/configure_docker_daemons
/srv/localdev/scripts/create_ssl_cert_key registry.local
/srv/localdev/scripts/create_ssl_cert_key registry-mirror.local

/srv/localdev/scripts/create_docker_networks "${docker_networks[@]}"
docker-compose -f /srv/localdev/images/squid/docker-compose.yml build
docker-compose -f /srv/localdev/images/squid/docker-compose.yml up -d

export http_proxy=http://http-proxy:3128

for compose_file in "${compose_files[@]}"; do
	: docker-compose -f "$compose_file" pull
done
for compose_file in "${compose_files[@]}"; do
	docker-compose -f "$compose_file" build
done

for compose_file in "${compose_files[@]}"; do
	docker-compose -f "$compose_file" up -d
done

if [[ $# -eq 0 ]]; then
	set -- sleep infinity
fi
exec "$@"
exit 1
