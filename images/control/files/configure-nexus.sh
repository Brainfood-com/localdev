#!/bin/bash

set -e

NEXUS_USER=admin
NEXUS_PASSWORD=admin123
NEXUS_URL=http://nexus:8081

_onexit() {
	if [[ $? -ne 0 ]]; then
		echo "There was an error configuring nexus!" 1>&2
	fi
}

trap _onexit EXIT

_info() {
	echo "$@" 1>&2
}

_wget() {
	wget -qO /dev/null \
		--keep-session-cookies \
		--save-cookies /tmp/cookies \
		--load-cookies /tmp/cookies \
		--header 'X-Nexus-UI: True' \
		"$@"
}

_post_value() {
	echo -n "$1" | base64 | sed 's/=/%3D/g'
}

_post_form() {
	_wget --header 'Content-Type: application/x-www-form-urlencoded; charset=UTF-8' "$@"
}

_post_json() {
	_wget --header 'Content-Type: application/json' "$@"
}

_info "Logging in to nexus."
_post_form $NEXUS_URL/service/rapture/session --post-data "username=$(_post_value "$NEXUS_USER")&password=$(_post_value "$NEXUS_PASSWORD")"

_info "Enabling Docker Realm"
_post_json $NEXUS_URL/service/extdirect --post-file /dev/stdin << _EOF_
{
	"action":"coreui_RealmSettings",
	"method":"update",
	"data":[
		{
			"realms":["DockerToken","NexusAuthenticatingRealm","NexusAuthorizingRealm"]
		}
	],
	"type":"rpc",
	"tid":65
}
_EOF_

_info "Creating repository: docker-hosted"
_post_json $NEXUS_URL/service/extdirect --post-file /dev/stdin << _EOF_
{
	"action":"coreui_Repository",
	"method":"create",
	"data":[
		{
			"attributes":{
				"docker":{
					"httpPort":8082,
					"forceBasicAuth":false,
					"v1Enabled":true
				},
				"storage":{
					"blobStoreName":"default",
					"strictContentTypeValidation":true,
					"writePolicy":"ALLOW"
				}
			},
			"name":"docker-hosted",
			"format":"",
			"type":"",
			"url":"",
			"online":true,
			"checkbox-1383-inputEl":true,
			"checkbox-1386-inputEl":false,
			"recipe":"docker-hosted"
		}
	],
	"type":"rpc",
	"tid":33
}
_EOF_

_info "Creating repository: docker-proxy"
_post_json $NEXUS_URL/service/extdirect --post-file /dev/stdin << _EOF_
{
	"action":"coreui_Repository",
	"method":"create",
	"data":[
		{
			"attributes":{
				"docker":{
					"forceBasicAuth":false,
					"v1Enabled":true
				},
				"proxy":{
					"remoteUrl":"https://registry-1.docker.io",
					"contentMaxAge":1440,
					"metadataMaxAge":1440
				},
				"dockerProxy":{"indexType":"REGISTRY"},
				"httpclient":{
					"blocked":false,
					"autoBlock":true,
					"connection":{"useTrustStore":false}},
					"storage":{
						"blobStoreName":"default",
						"strictContentTypeValidation":true
					},
					"negativeCache":{
					"enabled":true,
					"timeToLive":1440
				}
			},
			"name":"docker-proxy",
			"format":"",
			"type":"",
			"url":"",
			"online":true,
			"checkbox-1256-inputEl":false,
			"checkbox-1259-inputEl":false,
			"authEnabled":false,
			"httpRequestSettings":false,
			"recipe":"docker-proxy"
		}
	],
	"type":"rpc",
	"tid":13
}
_EOF_

_info "Creating repository: docker-group"
_post_json $NEXUS_URL/service/extdirect --post-file /dev/stdin << _EOF_
{
	"action":"coreui_Repository",
	"method":"create",
	"data":[
		{
			"attributes":{
				"docker":{
					"httpPort":8083,
					"forceBasicAuth":false,
					"v1Enabled":true
				},
				"storage":{
					"blobStoreName":"default",
					"strictContentTypeValidation":true
				},
				"group":{
					"memberNames":["docker-hosted", "docker-proxy"]
				}
			},
			"name":"docker-group",
			"format":"",
			"type":"",
			"url":"",
			"online":true,
			"checkbox-1332-inputEl":true,
			"checkbox-1335-inputEl":false,
			"recipe":"docker-group"
		}
	],
	"type":"rpc",
	"tid":23
}
_EOF_
