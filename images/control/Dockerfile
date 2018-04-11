FROM docker:stable-dind as src-docker

FROM docker/compose:1.20.0 as src-compose

FROM debian:stretch as localdev-base

RUN export DEBIAN_FRONTEND=noninteractive \
	&& apt-get update \
	&& apt-get install -y openssl wget libltdl7 python python-yaml gosu jq python-six \
	&& apt-get clean \
	&& find /var/cache/apt /var/lib/apt -type f -delete \
	&& true

FROM localdev-base as build-python

RUN export DEBIAN_FRONTEND=noninteractive \
	&& apt-get update \
	&& apt-get install -y python-pip git \
	&& apt-get clean \
	&& pip install 'git+https://github.com/deanrock/dockerpty.git#new-docker-library' docker \
	&& apt-get -y remove git python-pip \
	&& apt-get -y autoremove \
	&& find /var/cache/apt /var/lib/apt -type f -delete \
	&& true

FROM localdev-base

COPY --from=build-python /usr/local/lib/python2.7/ /usr/local/lib/python2.7/
COPY --from=src-compose /usr/local/bin/docker-compose /usr/local/bin/docker-compose
COPY --from=src-docker /usr/local/bin/docker /usr/local/bin/docker

RUN addgroup --gid 995 localgroup && adduser --uid 995 --disabled-password --ingroup localgroup --gecos '' localdev \
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

COPY images/control/exec-helper /srv/localdev/scripts/exec-helper
COPY images/control/run /srv/localdev/scripts/run
COPY image-scripts/ /srv/localdev/image-scripts/

