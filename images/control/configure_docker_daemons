#!/bin/bash

set -e

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
