FROM sonatype/nexus3

COPY healthcheck /srv/localdev/scripts/healthcheck
HEALTHCHECK --interval=15s CMD ["/srv/localdev/scripts/healthcheck"]
