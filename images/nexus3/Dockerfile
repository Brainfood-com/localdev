FROM nginx as nginx

COPY nginx-files /tmp/files
RUN ["/tmp/files/configure.sh"]

ENTRYPOINT ["/srv/localdev/scripts/entrypoint"]
HEALTHCHECK --interval=15s CMD ["/srv/localdev/scripts/healthcheck"]

FROM sonatype/nexus3

COPY healthcheck.py /srv/localdev/scripts/healthcheck
HEALTHCHECK --interval=15s CMD ["/srv/localdev/scripts/healthcheck"]
