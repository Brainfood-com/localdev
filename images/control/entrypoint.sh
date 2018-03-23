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
declare -a network_drivers=(
	overlay
	bridge
)

configure_docker_node() {
	declare type="$1" address="$2" master=
	shift 2
	if [[ $# -gt 0 ]]; then
		master="$1"
		shift
	fi

	declare swarm_status="$(docker -H "$address" info -f '{{if eq .Swarm.NodeID ""}}needs-swarm{{else if eq .Swarm.ControlAvailable true}}control=true{{else}}control=false{{range .Swarm.RemoteManagers}} {{.Addr}}{{end}}{{end}}' 2>/dev/null)"

	case "$type:$swarm_status" in
		(master:needs-swarm)
			docker -H "$address" swarm init
			;;
		(master:control=true)
			;;

		(manager:needs-swarm)
			declare JOIN_TOKEN=$(docker -H "$master" swarm join-token manager -q)
			docker -H "$address" swarm join --token "$JOIN_TOKEN" "$master"
			;;
		(manager:control=true)
			;;

		(slave:needs-swarm)
			declare JOIN_TOKEN=$(docker -H "$master" swarm join-token worker -q)
			docker -H "$address" swarm join --token "$JOIN_TOKEN" "$master"
			;;
		(slave:control=false\ *)
			set -- $swarm_status
			shift
			# TODO: validate remote managers match
			;;

		(*)
			exit 1
			;;
	esac
}

configure_docker_daemons() {
	declare master_addresses=($(getent hosts docker-master | cut -f 1 -d ' '))
	declare slave_addresses=($(getent hosts docker-slave | cut -f 1 -d ' '))

	[[ ${#master_addresses[*]} -gt 0 ]] || return 0
	configure_docker_node master "${master_addresses[0]}"
	declare address
	for address in "${master_addresses[@]:1}"; do
		configure_docker_node manager "$address" "${master_addresses[0]}"
	done
	for address in "${slave_addresses[@]}"; do
		configure_docker_node slave "$address" "${master_addresses[0]}"
	done
}

configure_docker_daemons
/srv/localdev/scripts/create_ssl_cert_key registry.local
/srv/localdev/scripts/create_ssl_cert_key registry-mirror.local

for network_name in "${docker_networks[@]}"; do
	if [[ -z $(docker network ls -q -f "name=^${network_name}$") ]]; then
		for network_driver  in "${network_drivers[@]}"; do
			if docker network create --attachable -d "${network_driver}" "${network_name}" 2>/dev/null; then
				break
			fi
		done
	fi
done
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