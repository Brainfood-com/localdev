#!/bin/bash

# This script will look at the UID and GID specified in the
# environment, and adjust the target USER/GROUP to match.  This is
# meant to be used inside a container, when a volume mount is in
# use, and is shared with the HOST or other systems.

set -e

TARGET_USER="$1"
TARGET_GROUP="$2"
shift 2

if ! [[ $(getent passwd "$TARGET_USER") =~ ^([^:]+):([^:]*):([^:]*):([^:]*):([^:]*):([^:]*):(.*)$ ]]; then
	echo "Couldn't parse: getent passwd" 1>&2
	exit 1
fi
declare -A user=(
	[name]="${BASH_REMATCH[1]}"
	[password]="${BASH_REMATCH[2]}"
	[uid]="${BASH_REMATCH[3]}"
	[gid]="${BASH_REMATCH[4]}"
	[gecos]="${BASH_REMATCH[5]}"
	[home]="${BASH_REMATCH[6]}"
	[shell]="${BASH_REMATCH[7]}"
)

if ! [[ $(getent group "$TARGET_GROUP") =~ ^([^:]+):([^:]*):([^:]*):(.*)$ ]]; then
	echo "Couldn't parse: getent group" 1>&2
	exit 1
fi
declare -A group=(
	[name]="${BASH_REMATCH[1]}"
	[password]="${BASH_REMATCH[2]}"
	[id]="${BASH_REMATCH[3]}"
	[users]="${BASH_REMATCH[4]}"
)

if [[ $MAP_GID && $MAP_GID -ne 0 ]]; then
	[[ ${group[id]} -ne $MAP_GID ]] && groupmod -g $MAP_GID "$TARGET_GROUP"
fi
if [[ $MAP_UID && $MAP_UID -ne 0 ]]; then
	[[ ${user[uid]} -ne $MAP_UID ]] && usermod -u $MAP_UID "$TARGET_USER"
fi

find "${user[home]}" \
	'(' -not -user "$TARGET_USER" -a -not -group "$TARGET_GROUP" -exec chown "$TARGET_USER:$TARGET_GROUP" '{}' + ')' -o \
	'(' -not -user "$TARGET_USER" -exec chown "$TARGET_USER" '{}' + ')' -o \
	'(' -not -group "$TARGET_GROUP" -exec chgrp "$TARGET_GROUP" '{}' + ')' -o \
	-true

