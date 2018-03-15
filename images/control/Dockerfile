FROM docker:stable-dind

FROM debian:stretch

COPY --from=0 /usr/local/bin/docker /usr/local/bin/docker

COPY files /tmp/files
RUN ["/tmp/files/configure.sh"]

ENTRYPOINT ["/srv/localdev/scripts/entrypoint"]
HEALTHCHECK --interval=15s CMD ["/srv/localdev/scripts/healthcheck"]


