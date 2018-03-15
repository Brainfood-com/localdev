ARG from
FROM ${from}

COPY healthcheck.sh /srv/localdev/scripts/healthcheck
HEALTHCHECK --interval=15s CMD ["/srv/localdev/scripts/healthcheck"]
