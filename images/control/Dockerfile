FROM docker:stable-dind as src-docker

FROM docker/compose:1.20.0 as src-compose

FROM debian:stretch

COPY --from=src-compose /usr/local/bin/docker-compose /usr/local/bin/docker-compose
COPY --from=src-docker /usr/local/bin/docker /usr/local/bin/docker

RUN export DEBIAN_FRONTEND=noninteractive \
	&& apt-get update \
	&& apt-get install -y openssl wget libltdl7 \
	&& apt-get clean \
	&& find /var/cache/apt /var/lib/apt -type f -delete \
	&& true

COPY create_docker_networks.sh /srv/localdev/scripts/create_docker_networks
COPY configure_docker_daemons.sh /srv/localdev/scripts/configure_docker_daemons
COPY create_ssl_cert_key.sh /srv/localdev/scripts/create_ssl_cert_key
COPY entrypoint.sh /srv/localdev/scripts/entrypoint
COPY healthcheck.sh /srv/localdev/scripts/healthcheck

ENTRYPOINT ["/srv/localdev/scripts/entrypoint"]
HEALTHCHECK --interval=15s CMD ["/srv/localdev/scripts/healthcheck"]


