#!/bin/bash

set -e
cn="$1"
shift

if ! [[ -e /srv/localdev/ssl/certs/$cn/ca.crt ]]; then
	mkdir -p /srv/localdev/ssl/certs/$cn
	mkdir -p /srv/localdev/ssl/keys/$cn
	openssl req -x509 -nodes -days 365 -newkey rsa:2048 \
		-subj "/C=US/ST=Texas/L=Dallas/O=local-dev/CN=$cn" \
		-keyout /srv/localdev/ssl/keys/$cn/ca.key.new \
		-out /srv/localdev/ssl/certs/$cn/ca.crt.new
	mv /srv/localdev/ssl/keys/$cn/ca.key.new /srv/localdev/ssl/keys/$cn/ca.key
	mv /srv/localdev/ssl/certs/$cn/ca.crt.new /srv/localdev/ssl/certs/$cn/ca.crt
fi
