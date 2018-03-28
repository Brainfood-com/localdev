FROM docker:stable-dind as src-docker

FROM docker/compose:1.20.0 as src-compose

FROM debian:stretch

COPY --from=src-compose /usr/local/bin/docker-compose /usr/local/bin/docker-compose
COPY --from=src-docker /usr/local/bin/docker /usr/local/bin/docker

RUN export DEBIAN_FRONTEND=noninteractive \
	&& apt-get update \
	&& apt-get install -y openssl wget libltdl7 python python-yaml gosu jq \
	&& apt-get clean \
	&& addgroup --gid 995 localgroup && adduser --uid 995 --disabled-password --ingroup localgroup --gecos '' localdev \
	&& find /var/cache/apt /var/lib/apt -type f -delete \
	&& true

COPY images/control/adjust-user /srv/localdev/scripts/adjust-user
COPY images/control/create_docker_networks /srv/localdev/scripts/create_docker_networks
COPY images/control/configure_docker_daemons /srv/localdev/scripts/configure_docker_daemons
COPY images/control/create_ssl_cert_key /srv/localdev/scripts/create_ssl_cert_key
COPY images/control/entrypoint /srv/localdev/scripts/entrypoint
COPY images/control/healthcheck /srv/localdev/scripts/healthcheck
COPY images/control/control /srv/localdev/scripts/control
COPY images/control/yaml2json /srv/localdev/scripts/yaml2json

ENTRYPOINT ["/srv/localdev/scripts/entrypoint"]
HEALTHCHECK --interval=15s CMD ["/srv/localdev/scripts/healthcheck"]

COPY images/control/run /srv/localdev/scripts/run
COPY image-scripts/ /srv/localdev/image-scripts/

