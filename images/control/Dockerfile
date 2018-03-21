FROM docker:stable-dind as src-docker

FROM docker/compose:1.20.0 as src-compose

FROM debian:stretch

COPY --from=src-compose /usr/local/bin/docker-compose /usr/local/bin/docker-compose
COPY --from=src-docker /usr/local/bin/docker /usr/local/bin/docker

COPY files /tmp/files
RUN ["/tmp/files/configure.sh"]

ENTRYPOINT ["/srv/localdev/scripts/entrypoint"]
HEALTHCHECK --interval=15s CMD ["/srv/localdev/scripts/healthcheck"]


