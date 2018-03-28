#!/bin/bash

set -e

/srv/localdev/scripts/adjust-user localdev localgroup

if [[ $# -eq 0 ]]; then
	set -- sleep infinity
fi
exec "$@"
exit 1
