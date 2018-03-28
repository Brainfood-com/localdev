#!/bin/bash

set -e

if [[ $# -eq 0 ]]; then
	set -- nginx -g 'daemon off;'
fi
exec "$@"
exit 1
