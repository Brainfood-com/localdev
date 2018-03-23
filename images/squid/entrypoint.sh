#!/bin/bash

set -e

{
	[[ $SQUID_maximum_object_size ]] && echo "maximum_object_size ${SQUID_maximum_object_size}"
	echo "cache_dir aufs /var/spool/squid $SQUID_cache_dir_size 16 256"

	# Enable faster shutdown
	echo "shutdown_lifetime 3 seconds"

	# Configure network access
	#ip addr show scope global | sed -n 's/.* inet \([^ ]*\) .*/acl localnet src \1/p'
	ip route show scope link | sed -n 's/^\([^ ]*\) .*/acl localnet src \1/p'
	echo "http_access allow localnet"

	echo "include /etc/squid/squid.conf"

	if [[ -d /etc/squid/squid.conf.d ]]; then
		if [[ $(find /etc/squid/squid.conf.d/ -name '*.conf' | wc -l) -gt 0 ]]; then
			echo "include /etc/squid/squid.conf.d/*.conf"
		fi
	fi
} > /etc/squid/auto-squid.conf

/usr/sbin/squid -z

[[ $# -eq 0 ]] && set -- /usr/sbin/squid -NYCd 1 -f /etc/squid/auto-squid.conf

exec "$@"
exit 1
