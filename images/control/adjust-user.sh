#!/bin/bash

# This script will look at the UID and GID specified in the
# environment, and adjust the target USER/GROUP to match.  This is
# meant to be used inside a container, when a volume mount is in
# use, and is shared with the HOST or other systems.

set -e

TARGET_USER="$1"
TARGET_GROUP="$2"
shift 2

target_home="$(getent passwd "$TARGET_USER" | cut -f 6 -d :)"

if [[ $MAP_GID && $MAP_GID -ne 0 ]]; then
	groupmod -g $MAP_GID "$TARGET_GROUP"
fi
if [[ $MAP_UID && $MAP_UID -ne 0 ]]; then
	usermod -u $MAP_UID "$TARGET_USER"
fi

find "$target_home" \
	'(' -not -user "$TARGET_USER" -a -not -group "$TARGET_GROUP" -exec chown "$TARGET_USER:$TARGET_GROUP" '{}' + ')' -o \
	'(' -not -user "$TARGET_USER" -exec chown "$TARGET_USER" '{}' + ')' -o \
	'(' -not -group "$TARGET_GROUP" -exec chgrp "$TARGET_GROUP" '{}' + ')' -o \
	-true

